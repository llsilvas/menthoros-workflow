---
name: implement
description: "Start a change (create the branch) or implement ONE task with TDD — detects backend (Spring) or frontend (Vite)"
category: workflow
argument-hint: "init <change-id>  |  <change-id> <task-id>"
---

Detect the stack from the cwd: **backend** if `pom.xml`/`mvnw` exist; **frontend** if `package.json` (Vite) exists.
The repo's `CLAUDE.md` is the canonical source of rules — follow it, including the output language (it mandates PT-BR for responses, comments and commits). Two modes:

## Mode A — `init <change-id>` (prepare the branch)

Do not implement anything. Follow the "Diretrizes de Git" in the root `CLAUDE.md` (pattern `feature/<change-id>`):

1. Resolve `<change-id>` (the OpenSpec spec name): validate via `openspec show <change-id>` or
   `menthoros-product/openspec/changes/<change-id>/`. If omitted, list the active changes and ask the user to pick.
2. Clean tree: if there are uncommitted changes, STOP and warn.
3. `git checkout develop && git pull origin develop && git checkout -b feature/<change-id>`
   (if the branch already exists, `checkout` it instead).
4. Report the branch and the base commit.

## Mode B — `<change-id> <task-id>` (implement ONE task with TDD)

1. Read the repo's `CLAUDE.md` and the OpenSpec change.
2. One task at a time, in scope.
3. **TDD red -> green -> refactor:**
   - **Backend:** write the test first (JUnit 5 / Mockito / AssertJ; `springboot-tdd` skill); validate `./mvnw clean test`.
   - **Frontend:** write the test first (Vitest + Testing Library); validate `npm run lint && npm run build && npm run test:run`.
   - Tasks with no testable behavior may skip the test — justify it.
4. Mark the task `[x]` in `tasks.md` and report files/validation/follow-ups.

The branch must already exist (Mode A). Never `--no-verify` / `@SuppressWarnings` / casts to bypass.
