# Refactoring to Prompt-Native Architecture

This guide helps you transform existing agent code to follow prompt-native principles by shifting behavior from code into prompts and simplifying tools into basic primitives.

## Diagnosis: Identifying Problems

### Problem 1: Tools with Embedded Logic

**Symptom:** Tool contains business logic like categorization, priority calculation, or conditional behavior.

```python
# BEFORE: Logic embedded in tool
async def handle_feedback(feedback: str):
    # Business logic in code
    category = "bug" if "error" in feedback.lower() else "feature"
    priority = 5 if "urgent" in feedback.lower() else 3

    await store_feedback(feedback, category, priority)

    if priority >= 4:
        await notify_team(feedback)

    return {"processed": True}
```

### Problem 2: Agent as Function Caller

**Symptom:** Agent merely invokes tools instead of reasoning through problems.

```markdown
# BEFORE: Prescriptive prompt
When you receive feedback:
1. Call handle_feedback(feedback_text)
2. Call update_dashboard()
3. Respond with "Thank you for your feedback"
```

### Problem 3: Artificial Capability Limits

**Symptom:** Tools restrict agent access through hardcoded allowlists.

```python
# BEFORE: Artificial limits
ALLOWED_DIRECTORIES = ["data/", "output/"]

async def write_file(path: str, content: str):
    if not any(path.startswith(d) for d in ALLOWED_DIRECTORIES):
        raise PermissionError("Cannot write to this directory")
```

### Problem 4: Prescriptive Prompts

**Symptom:** Instructions specify exact procedures rather than desired outcomes.

```markdown
# BEFORE: Step-by-step procedure
To process a support request:
1. Extract the customer email using regex pattern: [email regex]
2. Look up customer in database using lookup_customer()
3. If customer.tier == "premium", set priority = 5
4. If customer.tier == "free", set priority = 2
5. Create ticket with create_ticket(email, priority)
```

## Refactoring Process

### Step 1: Identify Workflow Tools

List all tools that contain:
- Conditional logic (`if/else`)
- Categorization or classification
- Priority calculation
- Multiple operations in sequence
- Business rules

### Step 2: Extract Primitives

Decompose each workflow tool into simple operations.

```python
# AFTER: Primitive tools
async def store_item(collection: str, data: dict):
    """Store any item in any collection."""

async def send_message(channel: str, content: str):
    """Send a message to any channel."""

async def query_items(collection: str, filter: dict = None):
    """Query items from any collection."""
```

### Step 3: Move Behavior to Prompts

Express workflow logic in natural language.

```markdown
# AFTER: Outcome-focused prompt
## Feedback Handling

When feedback arrives, use your judgment to:
- Assess its nature (bug report, feature request, general feedback, praise)
- Rate importance 1-5 based on: user impact, urgency, actionability
- Store with your assessment
- For importance 4+, alert the team in #urgent
- For bug reports, also track in the bugs collection

Trust your judgment. You understand context better than rigid rules.
```

### Step 4: Simplify Tools

Remove decisions from tool parameters.

```python
# BEFORE: Decision in parameters
async def store_feedback(
    content: str,
    category: Literal["bug", "feature", "general"],
    priority: int
):

# AFTER: Data only
async def store_item(collection: str, data: dict):
    """Store item. Agent decides collection and data structure."""
```

### Step 5: Remove Artificial Limits

Replace hardcoded restrictions with prompt guidance.

```python
# AFTER: No artificial limits in code
async def write_file(path: str, content: str):
    """Write content to any path."""
    # Full capability - prompt provides guidance
```

```markdown
# In system prompt
## File Operations

You can read/write any files. Typical patterns:
- Data files: data/*.json
- Generated content: output/*.html
- Logs: logs/*.log

Be thoughtful about what you modify. Avoid overwriting source code
unless explicitly asked.
```

### Step 6: Test Outcomes, Not Procedures

```python
# BEFORE: Testing procedure
def test_feedback_processing():
    result = handle_feedback("Bug: login broken")
    assert result["category"] == "bug"
    assert result["priority"] == 5

# AFTER: Testing outcomes
def test_urgent_feedback_triggers_alert():
    """Verify urgent issues result in team notification."""
    # Simulate agent processing
    # Verify alert was sent (not how it was categorized)
```

## Transformation Examples

### Example 1: Feedback Processing

**Before:**
```python
async def handle_feedback(feedback: str):
    category = categorize(feedback)  # ML model
    priority = calculate_priority(feedback)  # Business rules

    await db.insert("feedback", {
        "content": feedback,
        "category": category,
        "priority": priority
    })

    if priority >= 4:
        await slack.post("#alerts", f"High-priority: {feedback}")

    return {"status": "processed", "priority": priority}
```

**After - Tools:**
```python
async def store_item(collection: str, data: dict):
    """Store an item in a collection."""

async def send_message(channel: str, content: str):
    """Send a message to a channel."""
```

**After - Prompt:**
```markdown
## Processing Feedback

When feedback arrives:
1. Read it carefully and understand the user's concern
2. Assess importance (1-5):
   - 5: Service down, data loss, security issue
   - 4: Major feature broken, many users affected
   - 3: Feature request with clear value
   - 2: Minor inconvenience, workaround exists
   - 1: Nice-to-have, cosmetic
3. Store in feedback collection with your assessment
4. If importance >= 4, alert #urgent channel immediately
5. Acknowledge the user appropriately based on severity
```

### Example 2: Report Generation

**Before:**
```python
async def generate_weekly_report():
    metrics = await fetch_all_metrics()

    summary = f"""
    # Weekly Report
    - Users: {metrics['users']}
    - Revenue: ${metrics['revenue']}
    - Issues: {metrics['issues']}
    """

    await write_file("reports/weekly.md", summary)
    await send_email("team@company.com", "Weekly Report", summary)
```

**After - Tools:**
```python
async def query_metrics(metric_names: list[str], period: str):
    """Query specific metrics for a time period."""

async def write_file(path: str, content: str):
    """Write content to a file."""

async def send_message(channel: str, content: str):
    """Send to email or chat channel."""
```

**After - Prompt:**
```markdown
## Weekly Reports

Every Monday, generate a weekly report:
1. Query relevant metrics (users, revenue, issues, whatever's meaningful)
2. Analyze trends - what's improving? What needs attention?
3. Write insights, not just numbers
4. Save to reports/weekly-{date}.md
5. Send summary to #team-updates

Make the report genuinely useful. Highlight what matters, not everything.
```

## Addressing Concerns

### "What if the agent makes mistakes?"

Iterate on the prompt. When you observe unwanted behavior:
1. Note the specific case
2. Add guidance to the prompt
3. Redeploy and observe

This is faster than code changes and often reveals ambiguity in your original requirements.

### "Some operations must stay in code"

Correct. Keep in code:
- Security checks (authentication, authorization)
- Audit logging
- Rate limiting
- Data validation at system boundaries

These are infrastructure concerns, not business logic.

### "How do I test this?"

Test outcomes, not procedures:
- Given input X, was the desired outcome achieved?
- Did the user get helped?
- Was the data stored correctly?
- Was the alert sent when it should have been?

### "Complex workflows can't be expressed in prompts"

They can. Natural language is expressive. If your workflow is too complex for prose, it might be too complex period. Simplify the workflow, then express it in the prompt.

## Migration Checklist

- [ ] Identified all workflow tools
- [ ] Extracted primitive operations
- [ ] Moved business logic to system prompt
- [ ] Removed artificial capability limits
- [ ] Simplified tool parameters to data-only
- [ ] Updated tests to verify outcomes
- [ ] Documented prompt iteration process
- [ ] Established feedback loop for prompt refinement
