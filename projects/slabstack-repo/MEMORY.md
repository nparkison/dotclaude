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

## Slabstack Repo Conventions
- **Design docs / planning artifacts** go in `product-planning/` at repo root — NOT `docs/plans/`. The `docs/` directory does not exist and should not be created.

## Completed Projects
- **Gemini Migration Docs (2026-02-09):** Created 5 docs in Obsidian vault `Projects/Gemini Migration/` — Gem system prompt, complete profile, AI frameworks, professional context, and README. For use with Gemini Gems + NotebookLM ("Nik's Master AI Notebook").

## Path & File Delivery Preferences
- **When Nik asks for a directory/file path:** Always provide it in **Windows File Explorer format** (e.g., `\\wsl$\Ubuntu\home\npark\...` or `I:\My Drive\...`) so he can copy-paste it directly.
- **Also open it:** Run `explorer.exe` via Bash to open File Explorer to that exact location automatically.
- WSL paths map: `/home/npark/...` → `\\wsl$\Ubuntu\home\npark\...`, `/mnt/i/...` → `I:\...`

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
  - **Action items → Google Tasks** via `action_item_tasks.py` (enriched by Ollama)
  - **Do NOT move to OneDrive/Projects** — see session note for reasons
  - Domain `tuckedapp.com` is on Cloudflare (nameservers: graham/lily.ns.cloudflare.com)
- **Ollama** — runs on **Windows** (desktop app), NOT in WSL
  - WSL accesses it via localhost forwarding at `http://localhost:11434`
  - Model: `qwen2.5:7b` (stored at `C:\Users\npark\.ollama\models\`)
  - Already in Windows startup apps (`shell:startup`)
  - WSL `ollama.service` exists but must stay **disabled** (not needed)
  - If Ollama is down, meeting notes pipeline falls back to verbatim (no enrichment, nothing breaks)
  - **GPU situation:** Laptop has Intel integrated graphics only (no discrete GPU). eGPU is AMD RX 6700 XT but NOT supported by Ollama on Windows (requires RX 6800+). **Ollama runs CPU-only in all scenarios.**
  - **Model choice (tested 2026-02-21):** Tested qwen3:4b and qwen3:1.7b as replacements. qwen3:4b was slower on CPU (73s vs 29s) due to thinking architecture and had unreliable field names. qwen3:1.7b was fast but misclassified items. **Sticking with qwen2.5:7b** — best balance of speed and reliability for this structured JSON task.
