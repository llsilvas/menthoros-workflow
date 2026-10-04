#!/usr/bin/env bash
# Cross-model review via DeepSeek API — fallback for /codex:review and
# /codex:adversarial-review when the Codex CLI/plugin is unreachable.
#
# Usage:
#   deepseek-review.sh review      [--base <ref>] [--cwd <dir>] [--max-words <n>]
#   deepseek-review.sh adversarial [--base <ref>] [--cwd <dir>] [--max-words <n>]
#
# Reads DEEPSEEK_API_KEY from the environment, or from a .env file found by
# walking up from --cwd (or the current directory). Prints the model's
# response to stdout; diagnostics go to stderr. Exit code reflects the HTTP
# call only — the review verdict is in the printed text, same as Codex.
set -uo pipefail

mode="${1:-}"
shift || true
case "$mode" in
  review|adversarial) ;;
  *) echo "usage: deepseek-review.sh <review|adversarial> [--base <ref>] [--cwd <dir>] [--max-words <n>]" >&2; exit 64 ;;
esac

base="develop"
cwd="."
max_words=350
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="$2"; shift 2 ;;
    --cwd) cwd="$2"; shift 2 ;;
    --max-words) max_words="$2"; shift 2 ;;
    *) echo "[deepseek-review] unknown arg: $1" >&2; exit 64 ;;
  esac
done

cd "$cwd" || { echo "[deepseek-review] cwd not found: $cwd" >&2; exit 66; }

if [ -z "${DEEPSEEK_API_KEY:-}" ]; then
  dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/.env" ]; then
      key="$(grep -m1 '^DEEPSEEK_API_KEY=' "$dir/.env" | cut -d= -f2-)"
      [ -n "$key" ] && DEEPSEEK_API_KEY="$key"
      break
    fi
    dir="$(dirname "$dir")"
  done
fi
if [ -z "${DEEPSEEK_API_KEY:-}" ]; then
  echo "[deepseek-review] DEEPSEEK_API_KEY not set and no .env found above $cwd" >&2
  exit 69
fi

diff="$(git diff "${base}...HEAD" 2>/dev/null)"
if [ -z "$diff" ]; then
  diff="$(git diff 2>/dev/null)"
fi
if [ -z "$diff" ]; then
  echo "[deepseek-review] no diff found against '$base' or in the working tree" >&2
  exit 0
fi

if [ "$mode" = review ]; then
  instructions="You are a second-opinion code reviewer, independent of the primary (Claude) reviewers. \
Review the diff below for defects: correctness bugs, security issues, multi-tenancy leaks, missed \
edge cases. Report ONLY real, verifiable findings — do not restate the diff. Output a prioritized \
list (Critical / Important / Minor) with file:line and a one-line fix, then end with an explicit \
verdict line: 'VERDICT: <one sentence>'. Hard cap: ${max_words} words total."
else
  instructions="You are an adversarial reviewer running a pre-mortem on the change below, independent \
of the primary (Claude) author. Challenge the approach and design choices, not style: what does it \
assume that might be false? How does this fail in production? What edge case or interaction was \
missed? Do not restate the diff. Output your challenges as a short list, then end with an explicit \
verdict line: 'VERDICT: READY' or 'VERDICT: NOT READY — <why>'. Hard cap: ${max_words} words total."
fi

payload="$(python3 - "$instructions" "$diff" <<'PY'
import json, sys
instructions, diff = sys.argv[1], sys.argv[2]
print(json.dumps({
    "model": "deepseek-chat",
    "messages": [
        {"role": "system", "content": instructions},
        {"role": "user", "content": diff[:60000]},
    ],
    "temperature": 0.2,
    "max_tokens": 1200,
}))
PY
)"

response="$(curl -sS --max-time 90 https://api.deepseek.com/chat/completions \
  -H "Authorization: Bearer ${DEEPSEEK_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$payload")"

content="$(printf '%s' "$response" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d["choices"][0]["message"]["content"])
except Exception as e:
    err = None
    try:
        err = json.loads(sys.stdin.read())
    except Exception:
        pass
    print(f"[deepseek-review] could not parse response: {e}", file=sys.stderr)
    sys.exit(1)
')"
status=$?
if [ $status -ne 0 ]; then
  echo "[deepseek-review] raw response: $response" >&2
  exit 1
fi

printf '%s\n' "$content"
