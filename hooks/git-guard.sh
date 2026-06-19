#!/usr/bin/env bash
# Guardrail PreToolUse(Bash): blocks git operations forbidden by the root CLAUDE.md. Universal (backend/frontend).
set -uo pipefail
input="$(cat)"
cmd="$(printf '%s' "$input" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception: print("")')"
case "$cmd" in *git*) ;; *) exit 0 ;; esac
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
block(){ echo "[git-guard] BLOCKED: $1" >&2; exit 2; }
printf '%s' "$cmd" | grep -qE -- '--no-verify' && block "--no-verify is not allowed."
if printf '%s' "$cmd" | grep -qE 'git +push' && printf '%s' "$cmd" | grep -qE -- '(--force|-f)([ =]|$)'; then
  { printf '%s' "$cmd" | grep -qE '(develop|main|master)' || [ "$branch" = develop ] || [ "$branch" = main ] || [ "$branch" = master ]; } \
    && block "force-push to a protected branch requires explicit confirmation."
fi
printf '%s' "$cmd" | grep -qE 'git +reset +--hard' && block "git reset --hard requires explicit confirmation."
if printf '%s' "$cmd" | grep -qE 'git +commit'; then
  { [ "$branch" = develop ] || [ "$branch" = main ] || [ "$branch" = master ]; } \
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
