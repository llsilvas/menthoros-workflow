#!/usr/bin/env bash
# =============================================================================
# Test suite for menthoros-workflow hooks. Dependency-free: bash + git + python3.
# Run: bash tests/run.sh    (exit 0 = all green)
# =============================================================================
set -uo pipefail
HOOKS="$(cd "$(dirname "$0")/../hooks" && pwd)"
pass=0; fail=0
ok(){ printf "  ok   %s\n" "$1"; pass=$((pass+1)); }
ko(){ printf "  FAIL %s (exit %s, want %s)\n" "$1" "$2" "$3"; fail=$((fail+1)); }

newrepo(){ # echoes a fresh temp git repo path on branch $1
  local d; d="$(mktemp -d)"
  git -C "$d" init -q
  git -C "$d" config user.email t@t; git -C "$d" config user.name t
  git -C "$d" commit -q --allow-empty -m init
  git -C "$d" branch -m "$1"
  echo "$d"
}

# ---- git-guard: feed a command via stdin JSON, return exit code ----
guard(){ # $1=command $2=branch -> exit code
  local d; d="$(newrepo "$2")"
  local json; json="$(python3 -c 'import json,sys;print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$1")"
  ( cd "$d" && printf '%s' "$json" | bash "$HOOKS/git-guard.sh" >/dev/null 2>&1 )
  local rc=$?; rm -rf "$d"; echo $rc
}
gexpect(){ local got; got="$(guard "$2" "$3")"; [ "$got" = "$4" ] && ok "$1" || ko "$1" "$got" "$4"; }

echo "git-guard — must BLOCK (exit 2):"
gexpect "commit on develop"         "git commit -m x"                  develop   2
gexpect "commit on main"            "git commit -m x"                  main      2
gexpect "commit on master"         "git commit -m x"                  master    2
gexpect "force-push to develop"     "git push --force origin develop"  feature/x 2
gexpect "push -f to develop"        "git push -f origin develop"       feature/x 2
gexpect "force-push while on main"  "git push --force"                 main      2
gexpect "reset --hard"              "git reset --hard HEAD~1"          feature/x 2
gexpect "commit --no-verify"        "git commit -m x --no-verify"      feature/x 2

echo "git-guard — must ALLOW (exit 0):"
gexpect "status on develop"         "git status"                       develop   0
gexpect "merge --no-ff on develop"  "git merge feature/x --no-ff -m m" develop   0
gexpect "commit on feature"         "git commit -m x"                  feature/x 0
gexpect "push feature (no force)"   "git push -u origin feature/x"     feature/x 0
gexpect "non-git command"           "./mvnw clean test"                develop   0
gexpect "git log"                   "git log --oneline"                main      0

# ---- qa-gate: decision logic with stubbed mvnw/npm ----
qagate(){ # $1=projectdir -> exit code (PATH may be augmented by caller via $2)
  ( cd "$1" && CLAUDE_PROJECT_DIR="$1" PATH="${2:-$PATH}" bash "$HOOKS/qa-gate.sh" >/dev/null 2>&1 )
  echo $?
}
qexpect(){ [ "$2" = "$3" ] && ok "$1" || ko "$1" "$2" "$3"; }

echo "qa-gate — decision logic:"

# (a) no change in src/ -> exit 0 (skip)
d="$(newrepo main)"; mkdir -p "$d/src"; echo a > "$d/src/a"; git -C "$d" add .; git -C "$d" commit -q -m s
qexpect "skip when src unchanged" "$(qagate "$d")" 0; rm -rf "$d"

# (b) backend: pom.xml + changed src + mvnw stub
d="$(newrepo main)"; mkdir -p "$d/src"; echo a > "$d/src/a"; touch "$d/pom.xml"; git -C "$d" add .; git -C "$d" commit -q -m s
echo 'changed' >> "$d/src/a"   # unstaged change in src/
printf '#!/bin/sh\nexit 0\n' > "$d/mvnw"; chmod +x "$d/mvnw"
qexpect "backend tests pass -> 0" "$(qagate "$d")" 0
printf '#!/bin/sh\nexit 1\n' > "$d/mvnw"; chmod +x "$d/mvnw"
qexpect "backend tests fail -> 2" "$(qagate "$d")" 2; rm -rf "$d"

# (c) frontend: package.json + changed src + npm stub on PATH
d="$(newrepo main)"; mkdir -p "$d/src" "$d/bin"; echo a > "$d/src/a"; echo '{}' > "$d/package.json"; git -C "$d" add .; git -C "$d" commit -q -m s
echo 'changed' >> "$d/src/a"
printf '#!/bin/sh\nexit 0\n' > "$d/bin/npm"; chmod +x "$d/bin/npm"
qexpect "frontend checks pass -> 0" "$(qagate "$d" "$d/bin:$PATH")" 0
printf '#!/bin/sh\nexit 1\n' > "$d/bin/npm"; chmod +x "$d/bin/npm"
qexpect "frontend checks fail -> 2" "$(qagate "$d" "$d/bin:$PATH")" 2; rm -rf "$d"


# ---- migration-guard: destructive Flyway DDL on Edit|Write|MultiEdit ----
mguard(){ # $1=json $2=optional env assignment -> exit code
  if [ -n "${2:-}" ]; then
    printf '%s' "$1" | env "$2" bash "$HOOKS/migration-guard.sh" >/dev/null 2>&1
  else
    printf '%s' "$1" | bash "$HOOKS/migration-guard.sh" >/dev/null 2>&1
  fi
  echo $?
}
mwrite(){ python3 -c 'import json,sys;print(json.dumps({"tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "$1" "$2"; }
medit(){  python3 -c 'import json,sys;print(json.dumps({"tool_input":{"file_path":sys.argv[1],"new_string":sys.argv[2]}}))' "$1" "$2"; }
mmulti(){ python3 -c 'import json,sys;print(json.dumps({"tool_input":{"file_path":sys.argv[1],"edits":[{"new_string":sys.argv[2]}]}}))' "$1" "$2"; }
MIG="apps/menthoros-backend/src/main/resources/db/migration/V36__x.sql"

echo "migration-guard — must BLOCK (exit 2):"
qexpect "DROP TABLE (Write)"   "$(mguard "$(mwrite "$MIG" 'DROP TABLE tb_atleta;')")"       2
qexpect "TRUNCATE (Write)"     "$(mguard "$(mwrite "$MIG" 'TRUNCATE tb_treino;')")"         2
qexpect "DROP COLUMN (Edit)"   "$(mguard "$(medit  "$MIG" 'ALTER TABLE tb_x DROP COLUMN y;')")" 2
qexpect "destructive (MultiEdit)" "$(mguard "$(mmulti "$MIG" 'DROP TABLE z;')")"            2

echo "migration-guard — must ALLOW (exit 0):"
qexpect "CREATE TABLE migration"   "$(mguard "$(mwrite "$MIG" 'CREATE TABLE tb_new (id uuid);')")" 0
qexpect "DROP in non-migration"    "$(mguard "$(mwrite "src/Foo.java" 'DROP TABLE x;')")"   0
qexpect "destructive + override"   "$(mguard "$(mwrite "$MIG" 'DROP TABLE x;')" "MENTHOROS_ALLOW_DESTRUCTIVE_MIGRATION=1")" 0

echo
echo "==== $pass passed, $fail failed ===="
[ "$fail" -eq 0 ]
