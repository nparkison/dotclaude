# Auto Memory

## User Identity
- **Name:** Nik (not Nolan). Last name Parkison. Email: nparkison@gmail.com
- **Family:** Wife Becca (32, RN, SAHM), twins Henry & Charlotte (April 2024), Jameson (Jan 21 2026, 26-week preemie), dogs Nelly & Willow (labs), cat Paul George
- **Location:** US East Coast (ET). Lake house on Clear Lake, IN.
- **Interests:** Basketball (Pacers), guns, fitness, outdoors/camping, beer, water/lake life, travel

## Key Lessons
- **Always proofread agent output** — Don't write deliverables from agent summaries alone. In the Gemini migration session (2026-02-09), I fabricated a "10AM-12PM secondary peak" that didn't exist in usage data, guessed an age bracket, and misclassified TS/React proficiency. Nik caught me not verifying.
- **Verify claims against source data** before including in any document.
- **Don't embellish** what the user says (e.g., "beer" → "craft beer / beer culture" was wrong).
- **Avoid time-sensitive absolute statements** (e.g., "kids under 2") — use birth dates instead.
- **NEVER present web research from sub-agents without verification** — (2026-02-17) Sub-agent returned 20+ URLs with fabricated quotes for AI PM job research. I reformatted and presented it to Nik without checking a single link. He used it in a conversation with his boss, then half the links were broken. **Mandatory process:** When a sub-agent returns URLs, quotes, or factual claims from web research, I MUST WebFetch/WebSearch to verify BEFORE presenting to Nik. Treat all sub-agent web research as unverified drafts, not deliverables. This is the #1 risk with delegation — polished output ≠ accurate output.

## Completed Projects
- **Gemini Migration Docs (2026-02-09):** Created 5 docs in Obsidian vault `Projects/Gemini Migration/` — Gem system prompt, complete profile, AI frameworks, professional context, and README. For use with Gemini Gems + NotebookLM ("Nik's Master AI Notebook").

## Tools & Preferences
- **AI stack:** Claude Code (primary), Gemini (Google ecosystem), Antigravity (coding agent), Perplexity (research)
- **Google Workspace:** 2TB Pro tier personal, Workspace for work. Power user.
- **Phone:** Pixel 8 Pro
- **Laptop:** Lenovo ThinkPad, 64 GB RAM, WSL2 (Ubuntu)
- See `Projects/Gemini Migration/02 - NotebookLM - Complete Profile.md` in Obsidian vault for comprehensive hardware/software details

## Personal Automation
- **Meeting notes pipeline** at `~/.local/share/gemini-sync/` — GitHub: [nparkison/meeting-notes-sync](https://github.com/nparkison/meeting-notes-sync) (private)
  - Gemini sync (rclone cron every 6h) + Read AI webhook receiver (FastAPI, real-time)
  - Permanent Cloudflare Tunnel: `hooks.tuckedapp.com` → localhost:8765
  - Output: Obsidian vault `Projects/Slabstack/Meeting Notes/`
  - **Do NOT move to OneDrive/Projects** — see session note for reasons
  - Domain `tuckedapp.com` is on Cloudflare (nameservers: graham/lily.ns.cloudflare.com)
