#!/usr/bin/env python3
"""
Guards against the exact failure class that shipped in 1.8.2: a malformed
hooks.json (or a version drift between plugin.json/marketplace.json) makes
the plugin fail to load. When that happens, Claude Code falls through to any
globally-installed skill with the same name as a command (e.g. a generic
`implement`/`qa` skill from another package) — silently running the wrong
logic instead of erroring. This script is the regression guard for that.

Exit 0 = all checks pass. Exit 1 = a problem was found (message on stderr).
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors = []


def err(msg):
    errors.append(msg)


def load_json(path):
    try:
        return json.loads(path.read_text())
    except Exception as e:
        err(f"{path.relative_to(ROOT)}: invalid JSON ({e})")
        return None


# ---- hooks.json: must be wrapped in a top-level "hooks" key ----
hooks_path = ROOT / "hooks" / "hooks.json"
hooks_doc = load_json(hooks_path)
if hooks_doc is not None:
    if "hooks" not in hooks_doc or not isinstance(hooks_doc["hooks"], dict):
        err(f"{hooks_path.relative_to(ROOT)}: missing top-level \"hooks\" object "
            f"(events must be wrapped in {{\"hooks\": {{...}}}}, not placed at the root)")
    else:
        for event, entries in hooks_doc["hooks"].items():
            for entry in entries:
                for h in entry.get("hooks", []):
                    cmd = h.get("command", "")
                    m = re.search(r'"\$\{CLAUDE_PLUGIN_ROOT\}/([^"]+)"', cmd)
                    if m:
                        script = ROOT / m.group(1)
                        if not script.is_file():
                            err(f"hooks.json ({event}): referenced script does not exist: {m.group(1)}")

# ---- plugin.json: valid semver ----
plugin_path = ROOT / ".claude-plugin" / "plugin.json"
plugin_doc = load_json(plugin_path)
plugin_version = None
if plugin_doc is not None:
    plugin_version = plugin_doc.get("version")
    if not plugin_version or not re.fullmatch(r"\d+\.\d+\.\d+", plugin_version):
        err(f"{plugin_path.relative_to(ROOT)}: version missing or not semver: {plugin_version!r}")

# ---- marketplace.json: version must match plugin.json (catches silent drift) ----
market_path = ROOT / ".claude-plugin" / "marketplace.json"
market_doc = load_json(market_path)
if market_doc is not None and plugin_version is not None:
    plugins = market_doc.get("plugins", [])
    entry = next((p for p in plugins if p.get("name") == "menthoros-workflow"), None)
    if entry is None:
        err(f"{market_path.relative_to(ROOT)}: no entry for \"menthoros-workflow\" in plugins[]")
    elif entry.get("version") != plugin_version:
        err(f"{market_path.relative_to(ROOT)}: version {entry.get('version')!r} does not match "
            f"plugin.json's {plugin_version!r}")

if errors:
    for e in errors:
        print(f"[validate-manifests] {e}", file=sys.stderr)
    sys.exit(1)
print("[validate-manifests] ok")
sys.exit(0)
