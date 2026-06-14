#!/usr/bin/env bash
# Gate de qualidade (Stop), context-aware. Roda so se src/ mudou. Exit 2 em falha.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
if git diff --quiet -- src/ 2>/dev/null && git diff --cached --quiet -- src/ 2>/dev/null; then exit 0; fi
if [ -f pom.xml ] || [ -f mvnw ]; then
  echo "[qa-gate] backend: ./mvnw -q test" >&2
  ./mvnw -q test || { echo "[qa-gate] testes backend falharam" >&2; exit 2; }
elif [ -f package.json ]; then
  echo "[qa-gate] frontend: lint + build + test:run" >&2
  npm run -s lint  || { echo "[qa-gate] lint falhou" >&2; exit 2; }
  npm run -s build || { echo "[qa-gate] build falhou" >&2; exit 2; }
  npm run -s test:run --if-present || { echo "[qa-gate] testes unit falharam" >&2; exit 2; }
fi
exit 0
