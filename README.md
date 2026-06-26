# menthoros-workflow

Claude Code plugin with the Menthoros OpenSpec-first development workflow. **Context-aware**: the commands
and the quality gate detect whether the cwd is backend (Spring, `pom.xml`) or frontend (Vite, `package.json`).

> Tooling language vs output language: the plugin is in **English** (portable tooling), but the work it
> produces (commits, code comments, responses) follows each repo's `CLAUDE.md`, which mandates **PT-BR**.

## Contents
- **Commands:** `/change` (classify + **decompose** keep-vs-split when Size ≥ M), `/implement` (`init` → DoR + plan, `<id> <task>` TDD, `run [--step]` autopilot), `/qa` (Claude reviewers + **cross-model Codex pass**), `/pr` (opens a PR — no local merge), `/done` (post-merge: archive + SPRINTS + cleanup).
- **Subagents:** `spec-reviewer` (Definition-of-Ready gate, used in `/implement init`), `product-reviewer` (coach-centered product lens, in `/change`), `code-reviewer`, `security-reviewer`, `clean-code-reviewer` (SOLID/patterns), `frontend-reviewer`.

> **Model strategy — tiered review (reliability × cost).** Code review has asymmetric cost (a bug that slips
> through costs far more than the review), so the model tier follows task type × consequence, not a global dial:
> - **Cheap & frequent in the loop:** all reviewers currently run on **Haiku** (Sonnet is paused while the quota
>   is constrained). Catches the obvious early.
> - **Strong & rare at the gate:** an independent **cross-model Codex pass** in `/qa` (`/codex:review`, plus
>   `/codex:adversarial-review` on Full/high-risk) — runs on the OpenAI account, **outside the Claude budget**.
>   Claude+Codex agreement is the strong signal.
> - **Target matrix (re-enable when the Sonnet quota returns):** keep `spec-reviewer` + `frontend-reviewer`
>   (loop) on **Haiku**; raise `code-reviewer`, `clean-code-reviewer`, `product-reviewer` to **Sonnet**; raise
>   `security-reviewer` to **Sonnet/Opus** (highest consequence — never Haiku at the gate).
>
> Hooks cost nothing (local shell).
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
