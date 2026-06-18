import json, sys, os, re
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = d.get("tool_input", {}) or {}
path = ti.get("file_path", "") or ""
content = ti.get("content") or ti.get("new_string") or ""
if not content and isinstance(ti.get("edits"), list):
    content = " ".join(str(e.get("new_string", "")) for e in ti["edits"])

# only Flyway migrations
is_migration = ("db/migration/" in path) or bool(re.search(r'(^|/)V\d.*__.*\.sql$', path))
if not is_migration:
    sys.exit(0)

# destructive DDL per CLAUDE.md gate: DROP TABLE / TRUNCATE / DROP COLUMN
if re.search(r'DROP\s+TABLE|TRUNCATE\b|DROP\s+COLUMN', content, re.I):
    if os.environ.get("MENTHOROS_ALLOW_DESTRUCTIVE_MIGRATION") == "1":
        sys.stderr.write("[migration-guard] AVISO: migration destrutiva permitida via override.\n")
        sys.exit(0)
    sys.stderr.write(
        "[migration-guard] BLOQUEADO: DDL destrutivo (DROP TABLE / TRUNCATE / DROP COLUMN) "
        "em migration exige confirmacao explicita (CLAUDE.md). Revise; se intencional: "
        "export MENTHOROS_ALLOW_DESTRUCTIVE_MIGRATION=1.\n")
    sys.exit(2)
sys.exit(0)
