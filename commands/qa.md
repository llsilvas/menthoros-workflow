---
name: qa
description: "Quality gate: reviewers in parallel + validation — detects backend or frontend"
category: workflow
---

Detect the stack from the cwd and run the gate over the diff vs `develop`, in PARALLEL:

- **Backend** (`pom.xml`): delegate to the `code-reviewer`, `security-reviewer` and `clean-code-reviewer` subagents; run `./mvnw clean test`.
- **Frontend** (`package.json`): delegate to the `frontend-reviewer` and `clean-code-reviewer` subagents; run `npm run lint && npm run build && npm run test:run`.

(Reinforce with the native `/review` and `/security-review` if installed.)

Consolidate a prioritized report (Critical / Important / Minor) with `file:line`. Do NOT merge (that is `/ship`).
Approve only if everything is green and there is no Critical finding. Follow the repo's `CLAUDE.md` for conventions and output language (PT-BR).
