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
4. Clean up locally, **without checkout** (the main directory is already on `develop`, and the `git-guard`
   blocks branch switches there). First `cd` out of the change's worktree — to the main directory — if the
   session is in it. Then:
   - `git -C <principal> pull --ff-only origin develop`
   - `git -C <principal> worktree remove <worktree-path>` (path from `git worktree list`; skip if the
     branch never had a worktree). If it refuses (uncommitted or untracked files), STOP and report them —
     never `--force`: they may be work that did not make it into the PR.
   - `git -C <principal> branch -d <branch>`. If `-d` refuses (a squash merge does not leave the branch
     "merged" for git), the PR was already confirmed `MERGED` in step 1: ask the user before `-D`
     (confirmation gate in the root `CLAUDE.md`).
5. Report what was archived and the SPRINTS update.

Output language per the repo `CLAUDE.md` (PT-BR).
