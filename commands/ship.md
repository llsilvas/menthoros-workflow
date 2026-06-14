---
name: ship
description: "Close the change: validate, merge --no-ff into develop, archive OpenSpec and update SPRINTS"
category: workflow
argument-hint: "<change-id>"
---

Finalize the change `$ARGUMENTS`. Detect the stack from the cwd for validation.

**Preconditions:** `tasks.md` items `[x]`; suite green (`./mvnw clean test` on backend;
`npm run lint && build && test:run` on frontend); `/qa` with no Critical finding.

Follow the "Diretrizes de Git" in the root `CLAUDE.md`. **Operations on `develop` require explicit user confirmation:**

1. `git push -u origin feature/<change-id>` (if not pushed yet)
2. `git checkout develop && git pull origin develop`
3. `git merge feature/<change-id> --no-ff -m "Merge branch 'feature/<change-id>'"`
4. `git push origin develop`
5. `git branch -d feature/<change-id>`

Then close the OpenSpec loop (in `menthoros-product`): update `tasks.md`, `openspec archive <change-id>`,
and update the change's line in `openspec/SPRINTS.md`.

Never `--no-verify`, never `--force` on `develop`, never mix changes. Report merge/archive/SPRINTS.
Output language follows the repo's `CLAUDE.md` (PT-BR for commits/messages).
