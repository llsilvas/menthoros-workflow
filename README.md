# menthoros-workflow

Claude Code plugin with the Menthoros OpenSpec-first development workflow. **Context-aware**: the commands
and the quality gate detect whether the cwd is backend (Spring, `pom.xml`) or frontend (Vite, `package.json`).

> Tooling language vs output language: the plugin is in **English** (portable tooling), but the work it
> produces (commits, code comments, responses) follows each repo's `CLAUDE.md`, which mandates **PT-BR**.

## Contents
- **Commands:** `/implement` (branch init + TDD task), `/qa` (reviewers + validation), `/ship` (merge --no-ff + archive + SPRINTS).
- **Subagents:** `code-reviewer`, `security-reviewer` (backend), `frontend-reviewer`.
- **Hooks:** `git-guard` (PreToolUse — blocks commit on develop, force-push, reset --hard, --no-verify), `qa-gate` (Stop — runs the stack's tests when `src/` changes).

## Install (Claude Code CLI)
```bash
# local marketplace (immediate use)
/plugin marketplace add /path/to/menthoros-workflow
# or via a GitHub repo:  /plugin marketplace add <owner>/menthoros-workflow
/plugin install menthoros-workflow
```

## Migration note
When installing the plugin, remove the duplicated `.claude/` files in each repo so the hooks do not run
twice: `commands/{implement,qa,ship}.md`, `agents/*`, `hooks/{git-guard,qa-gate}.sh` and the `"hooks"`
block in `.claude/settings.json` (keep `enabledPlugins`, `mcpServers`, `permissions`).
