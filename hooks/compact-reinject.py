#!/usr/bin/env python3
"""Re-inject critical rules after context compaction.

When the conversation compacts, important rules from CLAUDE.md and memory files
get lost. This hook echoes your most-violated rules back into context so Claude
doesn't "forget" them mid-session.

HOW IT WORKS:
  Hook event: PostCompact (or UserPromptSubmit if your version doesn't have PostCompact)
  Output: plain text printed to stdout, which Claude sees as injected context

HOW TO CUSTOMIZE:
  Edit the print() block below. Replace the example rules with YOUR rules.
  Keep the format — numbered list, bold rule name, plain-English description.
  Aim for 4–6 rules: the ones you've had to correct most often.

SETUP (.claude/settings.json):
  {
    "hooks": {
      "PostCompact": [
        { "matcher": "", "hooks": [{ "type": "command", "command": "python3 /path/to/compact-reinject.py" }] }
      ]
    }
  }
"""
import sys

# ── CUSTOMIZE THESE ────────────────────────────────────────────────────────────
# Replace the examples below with your own rules.
# Format: numbered list, one rule per block, clear name + explanation.
# ──────────────────────────────────────────────────────────────────────────────

print("""
=== CRITICAL RULES (re-injected after compaction) ===

1. NO CLAUDE ATTRIBUTION: Never include "Co-Authored-By: Claude" or
   "Generated with Claude Code" in commit messages. If a pre-commit hook
   is configured to enforce this, attempts will be blocked automatically.

2. DRAFT-BEFORE-CREATE: Never create items in shared external systems
   (issue trackers, project management tools, code review platforms,
   chat tools) without first presenting a draft to the user and receiving
   explicit approval. Draft → Review → Approve → Create. No exceptions.

3. DELEGATION-FIRST: Act as an orchestrating manager, not an individual
   contributor. For any non-trivial task, spawn sub-agents rather than
   doing the work directly. Prefer parallel execution when tasks are
   independent. Use appropriate model sizes per your CLAUDE.md policy.

4. GIT CONVENTIONS: Follow the commit style established in this repo
   (conventional commits, imperative mood, etc.). Use SSH remotes.
   Never skip pre-commit hooks or add --no-verify unless explicitly asked.

5. [YOUR RULE HERE]: Describe the behavior you want Claude to maintain.
   Be specific about what triggers the rule and what the correct action is.
   Example: "When user says 'note this', write to the knowledge base, not
   to auto-memory."
""")

sys.exit(0)
