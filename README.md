# menthoros-workflow

Claude Code plugin with the Menthoros OpenSpec-first development workflow. **Context-aware**: the commands
and the quality gate detect whether the cwd is backend (Spring, `pom.xml`) or frontend (Vite, `package.json`).

> Tooling language vs output language: the plugin is in **English** (portable tooling), but the work it
> produces (commits, code comments, responses) follows each repo's `CLAUDE.md`, which mandates **PT-BR**.

## Contents
- **Commands:** `/change`, `/implement` (`init` → DoR + plan, `<id> <task>` TDD, `run [--step]` autopilot), `/qa`, `/pr` (opens a PR — no local merge), `/done` (post-merge: archive + SPRINTS + cleanup).
- **Subagents:** `spec-reviewer` (Definition-of-Ready gate, used in `/implement init`), `product-reviewer` (coach-centered product lens, in `/change`), `code-reviewer`, `security-reviewer`, `clean-code-reviewer` (SOLID/patterns), `frontend-reviewer`.
- **Hooks:** `git-guard` (PreToolUse/Bash — blocks commit on develop, force-push, reset --hard, --no-verify, and local merge into a protected branch), `migration-guard` (PreToolUse/Edit·Write — blocks destructive Flyway DDL: DROP TABLE / TRUNCATE / DROP COLUMN; override with `MENTHOROS_ALLOW_DESTRUCTIVE_MIGRATION=1`), `qa-gate` (Stop — runs the stack's tests when `src/` changes).

## Install (Claude Code CLI)
```bash
# local marketplace (immediate use)
/plugin marketplace add /path/to/menthoros-workflow
# or via a GitHub repo:  /plugin marketplace add <owner>/menthoros-workflow
/plugin install menthoros-workflow
```

## Tests

The hooks are the plugin's value — so they have a dependency-free regression suite (bash + git + python3):

```bash
bash tests/run.sh   # exit 0 = all green
```

Covers the `git-guard` block/allow matrix (commit on develop, force-push, reset --hard, --no-verify; vs. merge --no-ff, feature commits, non-git) and the `qa-gate` decision logic (skip when `src/` unchanged; backend vs frontend detection; failure -> exit 2) using stubbed `mvnw`/`npm`. Wire it into CI.

## Migration note
When installing the plugin, remove the duplicated `.claude/` files in each repo so the hooks do not run
twice: `commands/{implement,qa,ship}.md`, `agents/*`, `hooks/{git-guard,qa-gate}.sh` and the `"hooks"`
block in `.claude/settings.json` (keep `enabledPlugins`, `mcpServers`, `permissions`).
