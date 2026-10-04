---
name: implement
description: "Start a change (init), implement ONE task with TDD, or run ALL tasks autonomously — detects backend (Spring) or frontend (Vite)"
category: workflow
argument-hint: "init <change-id>  |  run <change-id> [--step]  |  <change-id> <task-id>"
---

Detect the stack from the cwd: **backend** if `pom.xml`/`mvnw` exist; **frontend** if `package.json` (Vite) exists.
The repo's `CLAUDE.md` is the canonical source of rules — follow it, including the output language (it mandates PT-BR for responses, comments and commits). Three modes, chosen by the first token of the arguments.

## Mode A — `init <change-id>` (prepare the branch)

Do not implement anything. Follow the "Diretrizes de Git" in the root `CLAUDE.md` (pattern `<tipo>/<change-id>`,
where `<tipo>` is the Conventional Commits type — `feat`/`fix`/`refactor`/`test`/`docs`/`chore` — that
dominates this change's scope; read `proposal.md`'s "What Changes" to decide, and ask the user if it's
genuinely ambiguous):

1. Resolve `<change-id>` (the OpenSpec spec name): validate via `openspec show <change-id>` or
   `menthoros-product/openspec/changes/<change-id>/`. If omitted, list the active changes and ask the user to pick.
2. **Definition of Ready:** run the `spec-reviewer` over the change. In parallel, run an independent
   cross-model pass with **Codex** over the spec (outside the Claude quota) — it challenges the proposal's
   assumptions, tradeoffs and design choices instead of just checking DoR boxes. Consolidate both: a gap
   flagged by **both** Claude and Codex is a strong signal (raise its priority); where they diverge,
   investigate before dismissing. If either verdict is **NOT READY** / surfaces a Critical gap, STOP and
   report the gaps — do not open a branch for an unready spec.

   **The Codex pass is mandatory on every track, Fast included.** It used to be optional on Fast, and the
   record killed that: on `add-coach-settings-page` (XS · Fast) it caught a **blocker** — an acceptance
   criterion describing a flow that the previously-merged change had made unreachable, because the layout
   gate returns before the `Outlet`. Two Claude reviewers and the author had missed it. Across this
   workstream Codex has rejected the DoR every time it ran, always with a real finding. Size is a poor
   proxy for "the spec is right": a small change built on top of a fresh one is exactly where stale
   assumptions hide.

   **Fast track still skips the rest** — no `design.md` required, no reviewer battery. Only the Codex pass
   and the testable-acceptance-criteria check are non-negotiable.

   **Invocation:** `/codex:adversarial-review` when the plugin command is reachable; otherwise
   `codex exec` with the spec paths. Ask for a verdict and a word cap — unbounded prompts make it echo
   file contents instead of reviewing. Always verify a finding against the code before accepting it: one
   claim per review has been wrong so far, and accepting it would have written a false rationale into the
   repo permanently.

   **Codex unreachable — DeepSeek fallback.** If Codex is not reachable at all (CLI missing/unauthenticated),
   run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/deepseek-review.sh" adversarial --base develop --cwd <repo>`
   instead of skipping the pass — needs `DEEPSEEK_API_KEY` in the environment or a `.env` above the repo.
   Same verification discipline as the Codex pass: verdict + word cap, check every finding against the code.
3. Clean tree: if there are uncommitted changes, STOP and warn.
4. `git checkout develop && git pull origin develop && git checkout -b <tipo>/<change-id>`
   (if a branch already exists for this `<change-id>` — check `git branch --list '*/<change-id>'` — `checkout`
   it instead, regardless of which `<tipo>` it was created with).
5. **Kanban do `menthoros-brain`:** move o card `<change-id>` de **🔴 A Fazer** para **🏃 Fazendo** em
   `menthoros-brain/10-Product/Kanban - Menthoros.md` — repo irmão dentro do workspace (remote
   `llsilvas/menthoros-brain.git`, branch `master`; não confundir com `/Volumes/MenthorosVault`, o share
   SMB do homelab com o mesmo conteúdo mas sem histórico git). Commit por path explícito (ver regra de
   sessão paralela do `CLAUDE.md` raiz — este repo de notas tem o mesmo risco do `menthoros-product`:
   todas as sessões na mesma branch, sem worktree). Kanban plugin do Obsidian — cada card é um
   `- [ ] \`change-id\` ...` + linha de descrição indentada; mover é cortar o bloco inteiro de uma seção
   `##` para a outra, preservando o texto. Se o repo não estiver clonado, avisar e seguir sem bloquear o
   resto do fluxo.
6. **Plan (refine `tasks.md` against the real code):** read `design.md` + `tasks.md` + the actual repo;
   refine the change's `tasks.md` into a concrete execution plan — real sequence/dependencies + a
   `verify:` line per task (how to know it worked). Keep `tasks.md` as the single source (no separate plan file).
7. Report the branch, the base commit, and that the plan is ready for `run`.

## Mode B — `<change-id> <task-id>` (implement ONE task with TDD)

1. Read the repo's `CLAUDE.md` and the OpenSpec change.
2. One task at a time, in scope.
3. Follow the repo Standards (controller/DTO/service/multi-tenancy on backend; hooks/tokens/generated-client on frontend).
4. **TDD red -> green -> refactor:**
   - **Backend:** write the test first (JUnit 5 / Mockito / AssertJ; `springboot-tdd` skill); validate `./mvnw clean test`.
   - **Frontend:** write the test first (Vitest + Testing Library); validate `npm run lint && npm run build && npm run test:run`.
   - Tasks with no testable behavior may skip the test — justify it.
5. Mark the task `[x]` in `tasks.md` and report files/validation/follow-ups.

The branch must already exist (Mode A). Never `--no-verify` / `@SuppressWarnings` / casts to bypass.

## Mode C — `run <change-id> [--step]` (autonomous: stack and execute all remaining tasks in sequence)

Work the change's `tasks.md` top to bottom, autonomously, on the already-created branch — but stop the moment something can't be resolved safely.

1. **Precondition:** a branch matching `*/<change-id>` must exist (Mode A) — check with
   `git branch --list '*/<change-id>'`. If not, STOP and tell the user to run `/implement init <change-id>`.
2. Read `tasks.md` and build an ordered queue of the **unchecked** (`[ ]`) tasks. Mirror the queue with TodoWrite so progress is visible.
3. For each task, in order:
   - **If it needs a human decision** — a product/scope call, an external dependency to confirm, anything phrased "decidir/confirmar", branch creation, or a destructive op — **PAUSE and ask**. Never guess.
   - Otherwise implement it with the **Mode B TDD flow** and the repo Standards.
   - Validate with the stack gate (backend `./mvnw clean test`; frontend `npm run lint && npm run build && npm run test:run`). **If it fails and you cannot fix the root cause within scope, STOP** — leave the task `[ ]`, report, and do not move to the next task.
   - On success: mark the task `[x]` in `tasks.md` and **commit per logical section** (Conventional Commits in PT-BR, on the change's branch) as a checkpoint.
4. When the queue is done, run the **quality gate** (`/qa`): delegate `code-reviewer` + `security-reviewer` (backend) or `frontend-reviewer` (frontend), plus `clean-code-reviewer`, in parallel; consolidate a prioritized report.
5. **STOP before shipping.** Do NOT merge or push to `develop`. Report the final status (tasks done/blocked, QA findings) and tell the user to run `/pr <change-id>` (explicit confirmation required; the git-guard hook blocks direct writes to `develop` anyway).

**Supervision — `--step`:** when called as `run <change-id> --step`, **pause for the user's confirmation at the end of each logical section** (right after its checkpoint commit) before starting the next — supervised autopilot. Without `--step`, run the whole queue and stop only on the semantic gates above (test failure, human-decision task, pre-ship). This is per **section**, never per task — per-task confirmation would just be Mode B with extra steps.

Recommended supervision by track (see the playbook): **Full track (M/L/XL) -> use `--step`**; **Fast track (XS/S) -> plain `run`**. Start with `--step` on a new flow and drop it once the autopilot has proven reliable.

Boundaries: one change's scope only; never mix changes; never `--no-verify`; never auto-merge/auto-ship. Prefer pausing over guessing.
