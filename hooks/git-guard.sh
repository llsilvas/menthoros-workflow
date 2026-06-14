#!/usr/bin/env bash
# Guardrail PreToolUse(Bash): bloqueia operacoes git vetadas pelo CLAUDE.md raiz. Universal (back/front).
set -uo pipefail
input="$(cat)"
cmd="$(printf '%s' "$input" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception: print("")')"
case "$cmd" in *git*) ;; *) exit 0 ;; esac
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
block(){ echo "[git-guard] BLOQUEADO: $1" >&2; exit 2; }
printf '%s' "$cmd" | grep -qE -- '--no-verify' && block "uso de --no-verify nao e permitido."
if printf '%s' "$cmd" | grep -qE 'git +push' && printf '%s' "$cmd" | grep -qE -- '(--force|-f)([ =]|$)'; then
  { printf '%s' "$cmd" | grep -qE '(develop|main|master)' || [ "$branch" = develop ] || [ "$branch" = main ] || [ "$branch" = master ]; } \
    && block "force-push em branch protegida exige confirmacao explicita."
fi
printf '%s' "$cmd" | grep -qE 'git +reset +--hard' && block "git reset --hard exige confirmacao explicita."
if printf '%s' "$cmd" | grep -qE 'git +commit'; then
  { [ "$branch" = develop ] || [ "$branch" = main ] || [ "$branch" = master ]; } \
    && block "commit direto em '$branch' nao e permitido — use feature/<change-id>."
fi
exit 0
