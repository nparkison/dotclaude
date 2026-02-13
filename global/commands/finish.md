---
description: End-of-session wrap-up - review code, update Linear, update Obsidian, push to GitHub
---

# Session Wrap-Up

Perform the following end-of-session tasks:

## 1. Code Review & Improvements

Review any code written during this session:
- Identify files that were created or modified
- Add clarifying comments where logic isn't self-evident
- Implement any quick/easy improvements you notice (but don't over-engineer)
- Fix any obvious issues like missing error handling at system boundaries

## 2. Update Linear

Update the Linear workspace with session progress:
- Mark completed issues as "Done" if fully finished
- Add comments to relevant issues summarizing what was accomplished
- Update issue status if work is in progress but not complete
- Create new issues for any follow-up work identified during the session

## 3. Update Obsidian Documentation

Update notes in the Obsidian vault at `/mnt/i/My Drive/NP-brain-backup`:
- Create or update project-specific notes with what was accomplished
- Document any important decisions made
- Note any technical learnings or gotchas discovered
- Add any TODOs or follow-up items

If the I: drive is not accessible, remind me to run:
`sudo mkdir -p /mnt/i && sudo mount -t drvfs I: /mnt/i`

## 4. Push to GitHub

Commit and push changes:
- Run `git status` to review changes
- Stage relevant files
- Create a meaningful commit message summarizing the work
- Push to the current branch

---

Before executing, summarize what you plan to do for each step and ask for confirmation if there are any ambiguities about:
- Which Linear issues to update
- What Obsidian notes to create/modify
- What should be included in the commit
