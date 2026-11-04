#!/usr/bin/env bash
# Guardrail PreToolUse(Bash): blocks git operations forbidden by the root CLAUDE.md. Universal (backend/frontend).
set -uo pipefail
input="$(cat)"
cmd="$(printf '%s' "$input" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception: print("")')"
case "$cmd" in *git*) ;; *) exit 0 ;; esac
block(){ echo "[git-guard] BLOCKED: $1" >&2; exit 2; }
# O harness manda o cwd atual da sessão no JSON; o processo do hook pode não estar nele (ex.: depois de
# um `cd` para o worktree da change). Paths relativos e o repo default resolvem a partir dele.
hook_cwd="$(printf '%s' "$input" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("cwd") or "")
except Exception: print("")')"
[ -n "$hook_cwd" ] && [ -d "$hook_cwd" ] && cd "$hook_cwd"
# "git", com opções globais opcionais (-C <dir>, -c <k=v>, --no-pager...), seguido do subcomando
GIT_RE='git( +-[Cc] +[^ ]+| +--[^ ]+)* +'

# O hook roda como processo separado, com o cwd fixo da sessão (repo primário) — não o do
# comando que está sendo interceptado. Comandos no padrão "cd <dir> && git ..." (a forma usual
# de operar num repo secundário do workspace) apontavam para o repo errado sem isso: git-guard
# checava a branch do repo primário, não do alvo real do comando. Extrai o primeiro "cd <dir>"
# antes de "&&"/";" (se houver) e resolve a branch/repo a partir dele.
target_dir="$(printf '%s' "$cmd" | python3 -c 'import re,sys
cmd = sys.stdin.read()
m = re.match(r"\s*cd\s+([^\n;&]+?)\s*(?:&&|;)", cmd) or re.search(r"\bgit\s+-C\s+(\"[^\"]+\"|\x27[^\x27]+\x27|\S+)", cmd)
print(m.group(1).strip().strip("\x27\"") if m else "")')"
if [ -n "$target_dir" ] && [ -d "$target_dir" ]; then
  branch="$(git -C "$target_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
  repo_toplevel="$(git -C "$target_dir" rev-parse --show-toplevel 2>/dev/null || echo '')"
else
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
  repo_toplevel="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
fi
printf '%s' "$cmd" | grep -qE -- '--no-verify' && block "--no-verify is not allowed."
if printf '%s' "$cmd" | grep -qE 'git +push' && printf '%s' "$cmd" | grep -qE -- '(--force|-f)([ =]|$)'; then
  { printf '%s' "$cmd" | grep -qE '(develop|main|master)' || [ "$branch" = develop ] || [ "$branch" = main ] || [ "$branch" = master ]; } \
    && block "force-push to a protected branch requires explicit confirmation."
fi
printf '%s' "$cmd" | grep -qE 'git +reset +--hard' && block "git reset --hard requires explicit confirmation."
# menthoros-product (specs), menthoros-workflow (este plugin) e menthoros-brain (notas/kanban)
# trabalham direto em master, por decisão do CLAUDE.md da raiz — não têm develop nem feature
# branch. Só neles o commit em master passa.
repo="$(basename "$repo_toplevel")"
master_only_repo=0
case "$repo" in menthoros-product|menthoros-workflow|menthoros-brain) master_only_repo=1 ;; esac
if printf '%s' "$cmd" | grep -qE "${GIT_RE}commit"; then
  { [ "$branch" = develop ] || [ "$branch" = main ] || { [ "$branch" = master ] && [ "$master_only_repo" = 0 ]; }; } \
    && block "direct commit on '$branch' is not allowed — use feature/<change-id>."
fi

# local integration into a protected branch is not allowed — use a Pull Request (/pr)
if printf '%s' "$cmd" | grep -qE "${GIT_RE}merge"; then
  { [ "$branch" = develop ] || [ "$branch" = main ] || [ "$branch" = master ]; } \
    && block "local merge into '$branch' is not allowed — integrate via Pull Request (/pr)."
fi
if printf '%s' "$cmd" | grep -qE 'checkout +(develop|main|master)' && printf '%s' "$cmd" | grep -qE 'git +merge'; then
  block "local integration into a protected branch is not allowed — use a Pull Request (/pr)."
fi

# Troca de branch no worktree principal de repo com develop (backend/front). HEAD é do diretório,
# não da sessão: um checkout ali muda a branch de toda sessão que estiver no mesmo diretório
# (incidentes 2026-08-09 e 2026-11-04). Cada change roda no próprio worktree (/implement init).
# Saída: uma linha por segmento que troca de branch — "<SWITCH|REF>\x1f<ref>\x1f<dir do -C ou vazio>".
cd_dir="$(printf '%s' "$cmd" | python3 -c 'import re,sys
m = re.match(r"\s*cd\s+([^\n;&]+?)\s*(?:&&|;)", sys.stdin.read())
print(m.group(1).strip().strip("\x27\"") if m else "")')"
switches="$(printf '%s' "$cmd" | python3 -c 'import re,shlex,sys
for seg in re.split(r"&&|\|\||;|\|", sys.stdin.read()):
    try: t = shlex.split(seg)
    except ValueError: continue
    if "git" not in t: continue
    t = t[t.index("git") + 1:]
    d = ""
    while t:
        if t[0] in ("-C", "-c") and len(t) >= 2:
            if t[0] == "-C": d = t[1]
            t = t[2:]
        elif t[0] in ("--git-dir", "--work-tree", "--namespace") and len(t) >= 2: t = t[2:]
        elif t[0].startswith("--") or t[0] in ("-p", "-P"): t = t[1:]
        else: break
    if not t: continue
    if t[0] == "switch": print("SWITCH\x1f\x1f" + d); continue
    if t[0] != "checkout": continue
    args = t[1:]
    if "--" in args: continue
    if any(a == "--orphan" or (re.fullmatch(r"-[A-Za-z]+", a) and re.search("[bB]", a)) for a in args):
        print("SWITCH\x1f\x1f" + d); continue
    pos = [a for a in args if a == "-" or not a.startswith("-")]
    if pos: print("REF\x1f" + pos[0] + "\x1f" + d)')"
while IFS=$'\x1f' read -r kind ref seg_dir; do
  [ -n "$kind" ] || continue
  dir="${seg_dir:-$cd_dir}"
  g=(git); if [ -n "$dir" ]; then [ -d "$dir" ] || continue; g=(git -C "$dir"); fi
  git_dir="$("${g[@]}" rev-parse --path-format=absolute --git-dir 2>/dev/null || echo '')"
  common_dir="$("${g[@]}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || echo '')"
  [ -n "$git_dir" ] && [ "$git_dir" = "$common_dir" ] || continue
  { "${g[@]}" show-ref --verify --quiet refs/heads/develop || "${g[@]}" show-ref --verify --quiet refs/remotes/origin/develop; } || continue
  # ref que resolve como commit, ou nome de branch só remota (o checkout cria a local por DWIM)
  if [ "$kind" = SWITCH ] || [ "$ref" = "-" ] \
     || "${g[@]}" rev-parse --verify --quiet "$ref^{commit}" >/dev/null 2>&1 \
     || [ -n "$("${g[@]}" for-each-ref --count=1 "refs/remotes/*/$ref" 2>/dev/null)" ]; then
    block "troca de branch no diretório principal do repo — use um worktree por change (/implement init ou git worktree add)."
  fi
done <<< "$switches"
exit 0
