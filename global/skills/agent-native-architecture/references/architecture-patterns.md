# Architectural Patterns for Prompt-Native Agent Systems

This document outlines key patterns for building agents where behavior is defined through prompts rather than code.

## 1. Event-Driven Agent Architecture

Agents operate as long-running processes responding to events like messages or webhooks. The system prompt defines decision-making logic, while tools serve as primitives for input/output operations.

### Example: Discord Feedback Bot

```
Event: Incoming Discord message
↓
Agent Turn:
  1. Acknowledge feedback
  2. Ask clarifying questions if needed
  3. Persist data to storage
  4. Update public dashboard
↓
Response sent to user
```

The key insight: incoming messages trigger agent turns that reason about appropriate responses rather than executing predetermined workflows.

## 2. Two-Layer Git Architecture

This pattern separates shared code (tracked in GitHub) from instance-specific data (stored locally).

### Structure

```
repository/
├── src/              # Tracked - shared code
├── prompts/          # Tracked - system prompts
├── web/              # Tracked - web interface
├── data/             # .gitignore - instance data
├── .env              # .gitignore - secrets
└── logs/             # .gitignore - runtime logs
```

### Benefits

- Enables self-modifying agents by keeping source code version-controlled
- Instance-specific data never pollutes the repository
- Automatic rollback through git history
- Secrets remain local and secure

## 3. Multi-Instance Branching

Multiple agent instances share core code through a main branch while maintaining separate instance branches.

### Branch Structure

```
main (shared core)
├── instance/alpha
├── instance/beta
└── instance/gamma
```

### Workflow

- Core improvements merge downward from `main` to instance branches
- Instance-specific configurations remain isolated on their branches
- Sync tools enable pulling updates: `git pull origin main`
- Proposing improvements back: create PR from instance to main

### Sync Operations

```bash
# Pull shared improvements
git fetch origin main
git merge origin/main

# Propose instance improvement to shared
git checkout -b proposal/feature-name
git push origin proposal/feature-name
# Create PR main ← proposal/feature-name
```

## 4. Site as Agent Output

Rather than specialized site-building tools, agents use basic file operations to generate and maintain websites.

### Approach

```
Agent receives: "Update the homepage to reflect new features"
↓
Agent uses: write_file("web/index.html", generated_content)
↓
Git commit triggers: automatic deployment via CI/CD
```

### Key Points

- The prompt teaches the agent to structure content appropriately
- No specialized "build_page" or "update_nav" tools needed
- Git commits trigger automatic deployments
- The site becomes a natural output of agent decision-making

### Example Prompt Section

```markdown
## Website Management

You maintain a public website at web/. When updating:
- Edit HTML files directly with write_file
- Preserve existing styles in styles.css
- Test links before committing
- Commit with descriptive messages

The site auto-deploys on push to main.
```

## 5. Approval Gates Pattern

Dangerous operations are separated into "propose" and "apply" phases.

### Classification

| Change Type | Approval Required |
|-------------|-------------------|
| Agent code changes | Yes |
| Dependency updates | Yes |
| System prompt edits | Yes |
| Data operations | No |
| Generated content | No |
| Log entries | No |

### Implementation

```python
# Propose phase
async def propose_change(file_path: str, content: str):
    change_id = store_pending_change(file_path, content)
    await notify_admin(f"Proposed change {change_id} to {file_path}")
    return {"status": "pending", "change_id": change_id}

# Apply phase (requires human approval)
async def apply_change(change_id: str):
    if not is_approved(change_id):
        return {"error": "Not yet approved"}
    change = get_pending_change(change_id)
    write_file(change.path, change.content)
    return {"status": "applied"}
```

## Design Questions for Your Architecture

When evaluating or designing an agent architecture, consider:

1. **Event Source**: What triggers agent activity? (Messages, webhooks, cron, manual)
2. **State Management**: Where does persistent state live? (Files, database, external service)
3. **Code Mutability**: Can the agent modify its own code? If yes, what approval gates exist?
4. **Deployment Model**: How do changes go live? (Manual, git push, CI/CD)
5. **Instance Isolation**: Single instance or multi-tenant? How is data separated?
6. **Recovery Strategy**: How does the system handle failures? (Rollback, retry, alert)
