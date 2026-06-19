---
name: done
description: "Post-merge: archive the OpenSpec change, update SPRINTS, clean up the branch"
category: workflow
argument-hint: "<change-id>"
---

Run AFTER the change's PR has been merged into `develop`. Closes the OpenSpec loop.

1. Confirm the PR is merged — `gh pr view feature/<change-id> --json state -q .state` returns `MERGED`. If not, STOP.
2. In `menthoros-product`: update `tasks.md` (implemented vs deferred), then archive the change:
   `openspec archive <change-id>` (or move to `changes/archive/YYYY-MM/YYYY-MM-DD-<change-id>/`).
3. Update the change's line in `openspec/SPRINTS.md` (mark done / move).
4. Clean up locally: `git checkout develop && git pull origin develop && git branch -d feature/<change-id>`.
5. Report what was archived and the SPRINTS update.

Output language per the repo `CLAUDE.md` (PT-BR).
