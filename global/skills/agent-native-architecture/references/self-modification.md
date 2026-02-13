# Self-Modification for Agents

Self-modification enables agents to evolve their own code, prompts, and behavior autonomously. This represents the logical extension of "whatever the developer can do, the agent can do."

## Why Self-Modification?

Traditional software is static—it requires human intervention for every change. Self-modifying agents can:

- **Fix bugs independently**: Detect errors and patch them without human intervention
- **Expand capabilities**: Implement new features based on user requests
- **Refine behavior**: Adjust prompts and judgment based on feedback
- **Self-deploy**: Manage code pushes, builds, and restarts

## Primary Capabilities

### 1. Code Modification

The agent can read, edit, and write its own source code.

**Required primitives:**
- `read_file(path)` - Read any file
- `write_file(path, content)` - Write any file
- `list_files(directory)` - Explore codebase
- `run_command(cmd)` - Execute builds, tests

**Example flow:**
```
User: "Add a /status command that shows uptime"
↓
Agent:
1. Reads existing command handlers
2. Writes new status_command.py
3. Updates command registry
4. Runs tests
5. Commits changes
6. Requests restart approval
```

### 2. Prompt Evolution

The agent can edit its own system prompts.

**Use cases:**
- Adding guidance based on repeated mistakes
- Documenting new capabilities
- Refining judgment criteria
- Removing outdated instructions

**Example:**
```
Feedback: "You keep forgetting to check inventory before promising delivery"
↓
Agent adds to prompt:
## Order Fulfillment
Before confirming any order, always:
1. Check current inventory levels
2. Verify supplier lead times if stock is low
3. Only promise dates you can actually meet
```

### 3. Infrastructure Control

The agent can manage its own deployment.

**Capabilities:**
- Pull updates from remote
- Merge branches
- Restart safely
- Rollback on failure

**Example restart flow:**
```
Agent:
1. git add . && git commit -m "Add status command"
2. Run build/tests
3. If success: request restart approval
4. After restart: verify health
5. If unhealthy: auto-rollback
```

### 4. Content Generation

The agent can create and maintain external artifacts.

**Examples:**
- Public websites
- Documentation
- Dashboards
- Data exports

## Critical Safety Guardrails

### Approval Gates

Never apply code changes immediately. Always:

```python
async def propose_code_change(file: str, content: str):
    """Propose a change for human approval."""
    change_id = store_pending_change(file, content)
    await notify_admin(
        f"Proposed change to {file}\n"
        f"Review: /approve {change_id} or /reject {change_id}"
    )
    return {"status": "pending_approval", "change_id": change_id}

async def apply_approved_change(change_id: str):
    """Apply a previously approved change."""
    if not is_approved(change_id):
        return {"error": "Not approved"}
    change = get_pending_change(change_id)
    write_file(change.file, change.content)
    mark_applied(change_id)
    return {"status": "applied"}
```

### Pre-Change Commits

Always commit current state before modifications:

```bash
# Before any code change
git add -A
git commit -m "checkpoint: before applying change {change_id}"
```

This enables recovery if changes break the system.

### Build Verification

Never restart with broken code:

```python
async def safe_restart():
    # Run build
    result = await run_command("npm run build")
    if result.exit_code != 0:
        return {"error": "Build failed", "output": result.stderr}

    # Run tests
    result = await run_command("npm test")
    if result.exit_code != 0:
        return {"error": "Tests failed", "output": result.stderr}

    # Only restart if everything passes
    await request_restart_approval()
```

### Health Checks

Verify system state after restart:

```python
async def verify_health():
    checks = {
        "uptime": get_uptime() > 30,  # Running for 30+ seconds
        "build_valid": await run_command("npm run build").exit_code == 0,
        "git_clean": "nothing to commit" in await run_command("git status"),
        "api_responding": await ping_api() == 200
    }

    if not all(checks.values()):
        await auto_rollback()
        return {"healthy": False, "checks": checks}

    return {"healthy": True, "checks": checks}
```

### Automatic Rollback

If health checks fail after restart:

```python
async def auto_rollback():
    # Find last known good commit
    last_good = await get_last_healthy_commit()

    # Reset to it
    await run_command(f"git reset --hard {last_good}")
    await run_command("npm run build")

    # Restart with known-good code
    await restart_process()

    # Alert admin
    await notify_admin("Auto-rollback triggered. Review recent changes.")
```

## Git-Based Architecture

Git provides the foundation for self-modification:

### Version History

Every change is tracked:
```bash
git log --oneline
abc123 Add status command
def456 Update feedback prompt
ghi789 Fix timezone handling
```

### Branching for Safety

```
main (production)
├── instance/prod (this agent's branch)
└── proposal/new-feature (pending changes)
```

### Multi-Instance Model

Multiple agents can share code while maintaining instance-specific config:

```
main
├── instance/alpha
│   └── config specific to alpha
├── instance/beta
│   └── config specific to beta
└── instance/gamma
    └── config specific to gamma
```

Sync operations:
```bash
# Pull shared improvements
git fetch origin main
git merge origin/main

# Propose improvement to shared
git checkout -b proposal/improvement
git push origin proposal/improvement
# Create PR: main ← proposal/improvement
```

## When to Use Self-Modification

### Recommended For

- **Long-running autonomous systems**: Agents that operate for weeks/months benefit from self-improvement
- **Feedback-adaptive agents**: Systems that should learn from user corrections
- **Internal tools**: Lower risk tolerance, faster iteration cycles
- **Rapid prototyping**: When requirements are evolving quickly

### Not Recommended For

- **Simple single-task agents**: Overhead not justified
- **Regulated environments**: Audit requirements may conflict with autonomous changes
- **High-security contexts**: Attack surface too large
- **Short-lived agents**: No benefit from evolution

## Essential Toolset

### File Operations MCP Server

```typescript
// Core file tools
read_file(path: string): string
write_file(path: string, content: string): void
list_files(directory: string): string[]
delete_file(path: string): void

// Approval workflow
propose_change(file: string, content: string): ChangeId
list_pending_changes(): Change[]
apply_change(change_id: string): void
reject_change(change_id: string): void
```

### Git Operations MCP Server

```typescript
// Status
git_status(): StatusInfo
git_log(count: number): Commit[]
git_diff(ref?: string): string

// Changes
git_add(files: string[]): void
git_commit(message: string): CommitId
git_push(): void

// Sync
git_pull(): void
git_fetch(): void
git_merge(branch: string): MergeResult

// Safety
git_rollback(commit: string): void
git_stash(): void
git_stash_pop(): void
```

### Process Control MCP Server

```typescript
// Restart flow
request_restart(): ApprovalId
restart_now(): void  // Only after approval

// Health
get_uptime(): number
health_check(): HealthStatus
get_last_healthy_commit(): CommitId

// Recovery
trigger_rollback(): void
```

## Implementation Checklist

- [ ] File read/write tools available
- [ ] Git operations available
- [ ] Approval gates implemented
- [ ] Pre-change commits automatic
- [ ] Build verification before restart
- [ ] Health checks after restart
- [ ] Automatic rollback on failure
- [ ] Admin notifications configured
- [ ] System prompt documents self-modification guidelines
- [ ] Testing covers modification scenarios
