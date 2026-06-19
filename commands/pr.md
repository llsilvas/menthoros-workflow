---
name: pr
description: "Open the integration Pull Request for the change (no local merge) — CI + branch protection integrate develop"
category: workflow
argument-hint: "<change-id>"
---

Open the integration PR for the change `$ARGUMENTS`. **Never merge `develop` locally** — `develop` is
integrated only via a merged PR on the remote (CI green + branch protection).

**Preconditions:** `tasks.md` items `[x]`; local suite green (`./mvnw clean test` / `npm run lint && build && test:run`); `/qa` with no Critical finding.

1. Push the branch: `git push -u origin feature/<change-id>`.
2. Open the PR (GitHub CLI):
   ```
   gh pr create --base develop --head feature/<change-id> \
     --title "<change-id>: <resumo>" \
     --body "<resumo + critérios de aceite atendidos + validação executada + link da spec OpenSpec>"
   ```
   (GitLab: `glab mr create --target-branch develop`.)
3. Report the PR URL. **Do NOT merge here.** The platform integrates after **CI is green** and the PR is
   **approved** (self-approval is fine solo). Optional auto-merge: `gh pr merge --auto --squash` (ou `--merge`).
4. Archiving + SPRINTS happen AFTER the merge — run `/done <change-id>` once the PR is merged.

Never `--no-verify`, never push to `develop`/`main` directly, never mix changes. Output language per the repo `CLAUDE.md` (PT-BR).
