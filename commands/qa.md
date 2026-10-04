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
**outside the Claude token budget**. **This pass is mandatory, not conditional on the plugin** — if the
`/codex:*` command is not reachable, fall back to `codex exec` with the diff commands in the prompt.

- **Always at the gate:** `/codex:review` over the same diff — a second opinion on defects.
- **Full track / high-risk** (security, multi-tenant, destructive migration, architecture): also
  `/codex:adversarial-review` — challenges the approach/design/assumptions (the pre-mortem pass; replaces the
  never-implemented `the-fool`).
- Prefer `--background` for anything larger than ~1–2 files.
- **Cap the word count and ask for an explicit verdict.** Unbounded prompts make Codex echo file contents
  instead of reviewing — it has burned a full run doing that.
- **Verify every finding against the code before accepting it.** Codex has been wrong at least once per
  workstream (severity inflated, or the stated mechanism simply false), and a wrong rationale accepted at
  face value gets written into the repo as a permanent comment.

**Convergence rule:** a finding where **Claude and Codex agree is a strong signal** (raise its priority); where
they diverge, investigate before dismissing. This is the cheap reliability lever while the deeper Claude tiers
(Sonnet/Opus) are constrained by quota.

**Codex unreachable — DeepSeek fallback.** If neither `/codex:*` nor `codex exec` is reachable (CLI not
installed, not authenticated, or errors out), do NOT silently skip the cross-model pass — run
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/deepseek-review.sh" review --base develop --cwd <repo>` (add
`adversarial` instead of `review` for the Full-track/high-risk case) instead. It needs `DEEPSEEK_API_KEY` in
the environment or a `.env` above the repo. Same discipline as Codex: cap the words (the script already
does, `--max-words` to change it), never accept a finding without checking it against the code, and treat
Claude+DeepSeek agreement as a strong signal exactly like Claude+Codex. This keeps a second model in the
gate at all times — Codex first, DeepSeek only when Codex is down, never both by default (cost/latency).

(Also reinforce with the native `/review` and `/security-review` if installed.)

Consolidate a prioritized report (Critical / Important / Minor) with `file:line`, merging the Claude and Codex
findings (dedupe; flag cross-model agreement). Do NOT merge (that is `/pr`).
Approve only if everything is green and there is no Critical finding. Follow the repo's `CLAUDE.md` for conventions and output language (PT-BR).
