---
name: change
description: "Front of funnel: classify Tamanho/Trilha and create an OpenSpec change (proposal + tasks; on Full: design + coach product-review + the-fool pre-mortem) — the entry point before /implement"
category: workflow
argument-hint: "<idea or change-id>"
---

Entry point of the workflow (FASE 1–2): turn an idea into a ready-to-implement OpenSpec change.
**Do NOT write production code here** — this command produces a spec, never branches or implements.
Follow the repo's `CLAUDE.md` for conventions and output language (PT-BR).

1. **Derive the change-id** from `$ARGUMENTS`: if it is already a kebab-case id, use it; if it is free
   text, derive one (e.g., "endpoint de status do atleta" -> `add-status-endpoint`) and confirm with the user.
2. **Classify size and track** using the criteria in `openspec/config.yaml` / the playbook:
   - **Size** XS->XL (effort + risk + surface area).
   - **Track:** start Fast; escalate to **Full** if it touches more than one repo, changes an API
     contract or DB schema, has design uncertainty, or carries security/multi-tenancy risk.
   - State the size, the track, and the one-line reason.
2b. **Decomposition (architecture lens)** — if Size ≥ M, decide **keep as one change vs split into smaller
   ones** before writing artifacts (skip for XS/S; they are already atomic):
   - **Cut where coupling is minimal** — the shared infra/foundation is the natural seam.
   - **Isolate risk into its own change** — destructive operations, a data gap, or design uncertainty.
   - **Walking skeleton** — the foundation ships with its first action (a foundation alone delivers no value).
   - **Incremental value** — each split change must be independently mergeable and useful.
   - Weigh the **ceremony cost** (N× proposal/PR/QA/done) against the isolation gained.
   - **Anti-patterns (do NOT split like this):** trivially small pieces; "one PR per file"; foundation with
     no action.
   - Output: a recommendation (keep / split) and, if splitting, the change list with **sequence + dependencies**;
     confirm with the user before creating the artifacts.
3. **Create the change** via the project's OpenSpec propose flow (`/opsx:propose <change-id>`, or
   `openspec new change` + artifacts). That flow applies `config.yaml`, so the proposal is generated
   with the `**Tamanho · Trilha**` line and minimal scope. Produce `proposal.md` + `tasks.md`; on
   **Full track** also `design.md` (and `specs/` when capabilities change).
4. **Full track — reviews before handoff:**
   - **Product (`product-reviewer`):** review the proposal through the coach lens — does it optimize the
     coach (treinador) routine and preserve coach-in-the-loop? Verdict Go/Refine/Reconsider; fold into the proposal.
   - **Assumptions:** surface the spec's hidden assumptions and validate them with the user; record the
     unresolved ones in the proposal's "Open Questions & Assumptions" section.
   - **Pre-mortem (cross-model, `/codex:adversarial-review`):** if the `codex` plugin is installed, run an
     adversarial pass over the design ("how does this approach fail? what does it assume?") — an independent
     model family, outside the Claude quota. Fold the findings into "Riscos e mitigações". (This replaces the
     never-implemented `the-fool`; the DoR check stays with `spec-reviewer` in `/implement init`.)
5. **Hand off** — report the change path and the next commands:
   `/implement init <change-id>` -> `/implement run <change-id>` (add `--step` on Full) -> `/qa` -> `/pr <change-id>` -> `/done <change-id>`.
