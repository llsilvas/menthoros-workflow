---
name: done
description: "Post-merge: archive the OpenSpec change, update SPRINTS, clean up the branch"
category: workflow
argument-hint: "<change-id>"
---

Run AFTER the change's PR has been merged into `develop`. Closes the OpenSpec loop.

1. Find the branch (`git branch --list '*/<change-id>'` locally, or `gh pr list --head` search if already
   deleted locally) and confirm the PR is merged — `gh pr view <branch> --json state -q .state` returns
   `MERGED`. If not, STOP.
2. In `menthoros-product`: update `tasks.md` (implemented vs deferred), then archive the change:
   `openspec archive <change-id>` (or move to `changes/archive/YYYY-MM/YYYY-MM-DD-<change-id>/`).
3. Update the change's line in `openspec/SPRINTS.md` (mark done / move).
4. Clean up locally: `git checkout develop && git pull origin develop && git branch -d <branch>`.
5. Report what was archived and the SPRINTS update.

Output language per the repo `CLAUDE.md` (PT-BR).
