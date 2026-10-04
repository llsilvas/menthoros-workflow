# menthoros-workflow

Claude Code plugin with the Menthoros OpenSpec-first development workflow. **Context-aware**: the commands
and the quality gate detect whether the cwd is backend (Spring, `pom.xml`) or frontend (Vite, `package.json`).

> Tooling language vs output language: the plugin is in **English** (portable tooling), but the work it
> produces (commits, code comments, responses) follows each repo's `CLAUDE.md`, which mandates **PT-BR**.

## Contents
- **Commands:** `/change` (classify + **decompose** keep-vs-split when Size ≥ M), `/implement` (`init` → DoR + plan, `<id> <task>` TDD, `run [--step]` autopilot), `/qa` (Claude reviewers + **cross-model Codex pass, DeepSeek fallback**), `/pr` (opens a PR — no local merge), `/done` (post-merge: archive + SPRINTS + cleanup).
- **Subagents:** `spec-reviewer` (Definition-of-Ready gate, used in `/implement init`), `product-reviewer` (coach-centered product lens, in `/change`), `code-reviewer`, `security-reviewer`, `clean-code-reviewer` (SOLID/patterns), `frontend-reviewer`.

> **Model strategy — tiered review (reliability × cost).** Code review has asymmetric cost (a bug that slips
> through costs far more than the review), so the model tier follows task type × consequence, not a global dial.
> **Current state (2026-09-18):** all 6 subagents run on **Sonnet** — the Haiku tier planned below drifted
> back to Sonnet across a few version-bump commits without a decision record; treat the split below as the
> *target*, not the live config, until it's re-applied.
> - **Haiku — loop / checklist (cheap), target:** `frontend-reviewer`, `spec-reviewer`, `clean-code-reviewer`.
> - **Sonnet — judgment / consequence:** `security-reviewer` (authz / tenant isolation / OWASP),
>   `code-reviewer` (N+1, multi-tenancy, JPA) and `product-reviewer` (value / coach lens, in `/change`).
>   Never Opus — Sonnet is the ceiling here.
> - **Codex — cross-model at the gate:** an independent pass in `/qa` and `/implement init`
>   (`/codex:review`, plus `/codex:adversarial-review` on Full/high-risk) — runs on the OpenAI account,
>   **outside the Claude budget**. Claude+Codex agreement is the strong signal.
> - **DeepSeek — Codex fallback:** `scripts/deepseek-review.sh review|adversarial` — only runs when
>   Codex/`codex exec` is unreachable, so the gate always has a second model. Needs `DEEPSEEK_API_KEY`
>   (see `.env.example`). Same verification discipline as Codex: verdict + word cap, check findings against
>   the code before accepting. Planned next: also run it in parallel with the loop/checklist reviewers for
>   a few cycles to validate quality before actually moving `frontend-reviewer`/`spec-reviewer`/
>   `clean-code-reviewer` off Claude.
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

Covers the `git-guard` block/allow matrix (commit on develop, force-push, reset --hard, --no-verify; vs. merge --no-ff, feature commits, non-git), the `qa-gate` decision logic (skip when `src/` unchanged; backend vs frontend detection; failure -> exit 2) using stubbed `mvnw`/`npm`, `deepseek-review.sh` argument/preflight validation, and `tests/validate-manifests.py` — a **regression guard for the exact 1.8.2 failure**: when `hooks.json` isn't wrapped in a top-level `"hooks"` key (or `plugin.json`/`marketplace.json` versions drift apart), the plugin fails to load and `/implement`/`/qa`/`/pr`/`/done` silently fall through to any globally-installed skill of the same name (e.g. `mattpocock/skills`' generic `implement`/`qa`) instead of erroring. Wired into CI.

## Migration note
When installing the plugin, remove the duplicated `.claude/` files in each repo so the hooks do not run
twice: `commands/{implement,qa,ship}.md`, `agents/*`, `hooks/{git-guard,qa-gate}.sh` and the `"hooks"`
block in `.claude/settings.json` (keep `enabledPlugins`, `mcpServers`, `permissions`).
