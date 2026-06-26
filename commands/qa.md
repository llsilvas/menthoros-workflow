---
name: qa
description: "Quality gate: reviewers in parallel + validation — detects backend or frontend"
category: workflow
---

Detect the stack from the cwd and run the gate over the diff vs `develop`, in PARALLEL:

- **Backend** (`pom.xml`): delegate to the `code-reviewer`, `security-reviewer` and `clean-code-reviewer` subagents; run `./mvnw clean test`.
- **Frontend** (`package.json`): delegate to the `frontend-reviewer` and `clean-code-reviewer` subagents; run `npm run lint && npm run build && npm run test:run`.

### Cross-model layer (Codex) — reliability without spending the Claude quota

The Claude reviewers above run on **Haiku** (cheap). To catch the blind spots a single model family shares
(Claude reviewing Claude), add an **independent cross-model pass with Codex** — it runs on the OpenAI account,
**outside the Claude token budget** — when the `codex` plugin is installed:

- **Always at the gate:** `/codex:review` over the same diff — a second opinion on defects.
- **Full track / high-risk** (security, multi-tenant, destructive migration, architecture): also
  `/codex:adversarial-review` — challenges the approach/design/assumptions (the pre-mortem pass; replaces the
  never-implemented `the-fool`).
- Prefer `--background` for anything larger than ~1–2 files.

**Convergence rule:** a finding where **Claude and Codex agree is a strong signal** (raise its priority); where
they diverge, investigate before dismissing. This is the cheap reliability lever while the deeper Claude tiers
(Sonnet/Opus) are constrained by quota.

(Also reinforce with the native `/review` and `/security-review` if installed.)

Consolidate a prioritized report (Critical / Important / Minor) with `file:line`, merging the Claude and Codex
findings (dedupe; flag cross-model agreement). Do NOT merge (that is `/pr`).
Approve only if everything is green and there is no Critical finding. Follow the repo's `CLAUDE.md` for conventions and output language (PT-BR).
