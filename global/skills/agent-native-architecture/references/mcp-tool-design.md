# MCP Tool Design Guide: Prompt-Native Principles

## Core Concept

"Whatever a user can do, the agent should be able to do."

Tools should function as foundational capabilities rather than decision-making workflows. The agent's intelligence—guided by the system prompt—determines how to combine these primitives.

## Key Principles

### Primitives Over Workflows

Tools should enable actions without encoding business logic.

**Anti-pattern: Workflow Tool**
```python
async def process_feedback(feedback: str):
    """Categorize, prioritize, store, and notify about feedback."""
    category = categorize(feedback)
    priority = calculate_priority(feedback)
    await store_feedback(feedback, category, priority)
    if priority > 3:
        await send_notification(feedback)
    return {"status": "processed"}
```

**Pattern: Primitive Tools**
```python
async def store_item(collection: str, data: dict):
    """Store an item in a collection."""
    # Just stores, no categorization logic

async def send_message(channel: str, content: str):
    """Send a message to a channel."""
    # Just sends, no priority logic
```

Let the agent decide when and how to combine them based on the system prompt.

### Naming Conventions

Tool names should describe capabilities, not use cases.

| Bad (Use Case) | Good (Capability) |
|----------------|-------------------|
| `create_feedback_summary` | `write_file` |
| `send_notification` | `send_message` |
| `update_dashboard` | `write_file` |
| `categorize_feedback` | (remove - agent does this) |

### Simple Inputs

Inputs should accept data only, not decisions.

**Anti-pattern:**
```python
async def write_content(
    path: str,
    content: str,
    format: Literal["html", "json", "markdown"],  # Decision embedded
    should_minify: bool  # Decision embedded
):
```

**Pattern:**
```python
async def write_file(path: str, content: str):
    """Write content to a file. Agent decides format based on path extension."""
```

### Rich Outputs

Return sufficient information for verification and decision-making.

**Anti-pattern:**
```python
async def delete_item(id: str):
    await db.delete(id)
    return {"success": True}
```

**Pattern:**
```python
async def delete_item(id: str):
    existed = await db.exists(id)
    if existed:
        await db.delete(id)
    remaining = await db.count()
    return {
        "existed": existed,
        "deleted": existed,
        "remaining_count": remaining,
        "message": f"Deleted item {id}" if existed else f"Item {id} not found"
    }
```

## Structural Organization

Organize tools into categories:

```python
# Read Operations
async def read_file(path: str) -> dict:
    """Read a file's contents."""

async def list_files(directory: str) -> dict:
    """List files in a directory."""

async def query_items(collection: str, filter: dict = None) -> dict:
    """Query items from a collection."""

# Write Operations
async def write_file(path: str, content: str) -> dict:
    """Write content to a file."""

async def store_item(collection: str, data: dict) -> dict:
    """Store an item in a collection."""

async def delete_item(collection: str, id: str) -> dict:
    """Delete an item from a collection."""

# External Operations
async def send_message(channel: str, content: str) -> dict:
    """Send a message to an external channel."""

async def fetch_url(url: str) -> dict:
    """Fetch content from a URL."""
```

## Response Format Template

```python
async def example_tool(param: str) -> dict:
    try:
        # ... operation ...
        return {
            "success": True,
            "data": result_data,
            "message": "Human-readable description of what happened"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "message": f"Failed to perform operation: {e}"
        }
```

## Practical Example: Feedback Server

### Primitive Tools

```python
async def store_feedback(content: str, metadata: dict = None) -> dict:
    """Store feedback with optional metadata."""
    id = generate_id()
    await db.insert("feedback", {
        "id": id,
        "content": content,
        "metadata": metadata or {},
        "created_at": now()
    })
    return {
        "success": True,
        "id": id,
        "message": f"Stored feedback with id {id}"
    }

async def list_feedback(limit: int = 50, filter: dict = None) -> dict:
    """List feedback items with optional filtering."""
    items = await db.query("feedback", filter, limit=limit)
    return {
        "success": True,
        "items": items,
        "count": len(items),
        "message": f"Found {len(items)} feedback items"
    }

async def update_feedback(id: str, updates: dict) -> dict:
    """Update a feedback item."""
    existed = await db.exists("feedback", id)
    if not existed:
        return {"success": False, "error": f"Feedback {id} not found"}
    await db.update("feedback", id, updates)
    return {
        "success": True,
        "id": id,
        "message": f"Updated feedback {id}"
    }
```

### Decision-Making in System Prompt

```markdown
## Feedback Processing

When feedback arrives:
1. Assess importance (1-5 scale based on impact, urgency, actionability)
2. Store with your assessment in metadata
3. If importance >= 4, send a message to #alerts channel
4. If feedback mentions a bug, also store in bugs collection
5. Update the public site weekly with aggregated insights
```

## Design Checklist

- [ ] Tools are CRUD operations, not workflows
- [ ] Tool names describe capabilities, not use cases
- [ ] Inputs are data, not decisions
- [ ] Outputs include verification info
- [ ] Business logic lives in system prompt
- [ ] No hardcoded categorization or prioritization
- [ ] Errors are descriptive and actionable
- [ ] Tool descriptions focus on what it does, not when to use it
