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

### Meeting Notes Index

If the session involved meetings or references meeting content, check the **Meeting Notes Index** at:
`/mnt/i/My Drive/NP-brain-backup/Projects/Slabstack/Meeting Notes/00 - Meeting Notes Index.md`

- If new meeting notes were created during this session, add them to the index under the appropriate category
- Meeting notes live in `Projects/Slabstack/Meeting Notes/` and follow the naming convention: `YYYY-MM-DD Meeting Title.md`
- Each meeting note should have YAML frontmatter with: `date`, `time`, `timezone`, `type: meeting-notes`, `category`, `source`, and `tags`
- When searching for context about past discussions, scan this index first — it covers meetings from Dec 2025 onward

If the I: drive is not accessible, remind me to run:
`sudo mkdir -p /mnt/i && sudo mount -t drvfs I: /mnt/i`

## 4. Obsidian Note Linking

If any Obsidian notes were created or modified during this session:

1. Identify all new or changed notes in the vault
2. For each note, search the vault for related content using relevant keywords — topic names, feature areas, Shortcut story IDs (e.g. SC-XXXX), meeting dates, or shared terminology
3. Add bidirectional wiki-links using alias syntax: `[[Note Title|natural display text]]` — never bare note titles
4. Ensure each note has a `## Related Notes` or `## Related Artifacts` section at the bottom containing these links
5. Inline-link prominent feature or topic mentions within the note body (max one link per target per note, so the same target isn't linked repeatedly)
6. For any note you link *to*, check if it should reciprocate with a link back to the current note — add it if missing

Example alias syntax: `[[2026-02-19 Meeting Action Items|the automation design meeting]]` or `[[SC-9684 Project Config Required|the project config story]]`

## 5. Push to GitHub

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
