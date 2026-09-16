#!/usr/bin/env bash
# Guardrail PreToolUse(Bash): blocks git operations forbidden by the root CLAUDE.md. Universal (backend/frontend).
set -uo pipefail
input="$(cat)"
cmd="$(printf '%s' "$input" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception: print("")')"
case "$cmd" in *git*) ;; *) exit 0 ;; esac
block(){ echo "[git-guard] BLOCKED: $1" >&2; exit 2; }

# O hook roda como processo separado, com o cwd fixo da sessão (repo primário) — não o do
# comando que está sendo interceptado. Comandos no padrão "cd <dir> && git ..." (a forma usual
# de operar num repo secundário do workspace) apontavam para o repo errado sem isso: git-guard
# checava a branch do repo primário, não do alvo real do comando. Extrai o primeiro "cd <dir>"
# antes de "&&"/";" (se houver) e resolve a branch/repo a partir dele.
target_dir="$(printf '%s' "$cmd" | python3 -c 'import re,sys
cmd = sys.stdin.read()
m = re.match(r"\s*cd\s+([^\n;&]+?)\s*(?:&&|;)", cmd)
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
# menthoros-product (specs) e menthoros-workflow (este plugin) trabalham direto em master, por
# decisão do CLAUDE.md da raiz — não têm develop nem feature branch. Só neles o commit em master passa.
repo="$(basename "$repo_toplevel")"
master_only_repo=0
case "$repo" in menthoros-product|menthoros-workflow) master_only_repo=1 ;; esac
if printf '%s' "$cmd" | grep -qE 'git +commit'; then
  { [ "$branch" = develop ] || [ "$branch" = main ] || { [ "$branch" = master ] && [ "$master_only_repo" = 0 ]; }; } \
    && block "direct commit on '$branch' is not allowed — use feature/<change-id>."
fi

# local integration into a protected branch is not allowed — use a Pull Request (/pr)
if printf '%s' "$cmd" | grep -qE 'git +merge'; then
  { [ "$branch" = develop ] || [ "$branch" = main ] || [ "$branch" = master ]; } \
    && block "local merge into '$branch' is not allowed — integrate via Pull Request (/pr)."
fi
if printf '%s' "$cmd" | grep -qE 'checkout +(develop|main|master)' && printf '%s' "$cmd" | grep -qE 'git +merge'; then
  block "local integration into a protected branch is not allowed — use a Pull Request (/pr)."
fi
exit 0
