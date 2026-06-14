#!/usr/bin/env bash
# Quality gate (Stop), context-aware. Runs only if src/ changed. Exit 2 on failure.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
if git diff --quiet -- src/ 2>/dev/null && git diff --cached --quiet -- src/ 2>/dev/null; then exit 0; fi
if [ -f pom.xml ] || [ -f mvnw ]; then
  echo "[qa-gate] backend: ./mvnw -q test" >&2
  ./mvnw -q test || { echo "[qa-gate] backend tests failed" >&2; exit 2; }
elif [ -f package.json ]; then
  echo "[qa-gate] frontend: lint + build + test:run" >&2
  npm run -s lint  || { echo "[qa-gate] lint failed" >&2; exit 2; }
  npm run -s build || { echo "[qa-gate] build failed" >&2; exit 2; }
  npm run -s test:run --if-present || { echo "[qa-gate] unit tests failed" >&2; exit 2; }
fi
exit 0
