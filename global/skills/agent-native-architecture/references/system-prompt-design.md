# System Prompts for Prompt-Native Agents

In prompt-native architecture, the system prompt is where features live. It defines behavior, judgment criteria, and decision-making without encoding them in code.

## Core Principles

### Features Live in Prompts

Rather than coding functions, organize each capability as a distinct system prompt section.

**Code approach:**
```python
def categorize_feedback(text):
    if "bug" in text.lower():
        return "bug"
    elif "feature" in text.lower():
        return "feature"
    return "general"
```

**Prompt approach:**
```markdown
## Feedback Categorization

When feedback arrives, determine its nature:
- **Bug report**: User describes something broken or not working as expected
- **Feature request**: User wants new capability or enhancement
- **General feedback**: Opinions, praise, or unclear items

Use context and judgment—don't rely on keyword matching.
```

### Structure Your Prompt

A well-designed prompt includes:

1. **Identity**: Who is this agent?
2. **Core Behavior**: What does it always do?
3. **Feature Sections**: Specific capabilities
4. **Tool Guidance**: How to use available tools
5. **Tone Direction**: Communication style
6. **Boundaries**: What it should not do

### Guide, Don't Micromanage

Provide objectives and judgment frameworks rather than rigid procedures.

**Micromanaging (avoid):**
```markdown
When you receive a message:
1. Check if it contains the word "urgent"
2. If yes, set priority to 5
3. If no, check if it contains "bug"
4. If yes, set priority to 4
5. Otherwise, set priority to 2
6. Store with store_item("feedback", {...})
7. If priority >= 4, call send_message("#alerts", ...)
```

**Guiding (prefer):**
```markdown
## Handling Incoming Messages

Assess each message's importance based on:
- **Impact**: How many users affected? How severely?
- **Urgency**: Is something currently broken?
- **Actionability**: Can we do something about it?

High-importance items (4-5) should trigger an alert. Use your judgment—
you understand context better than rigid rules.
```

### Judgment Criteria Over Hard Rules

Replace rigid rules with flexible criteria.

**Hard rules (brittle):**
```markdown
Priority Rules:
- Contains "urgent" → Priority 5
- Contains "bug" → Priority 4
- Contains "feature" → Priority 3
- Everything else → Priority 2
```

**Judgment criteria (robust):**
```markdown
## Importance Assessment (1-5 scale)

Consider:
- **5 - Critical**: Service down, data loss, security issue, exec request
- **4 - High**: Major feature broken, paying customer blocked
- **3 - Medium**: Clear feature request, reproducible bug with workaround
- **2 - Low**: Nice-to-have, cosmetic issue, vague feedback
- **1 - Minimal**: Spam, duplicate, already addressed

Context matters. A "minor" bug affecting your largest customer is not minor.
```

### Leverage Context Windows

The agent has access to conversation history. Use this:

```markdown
## Conversation Awareness

You maintain context across messages. When a user follows up:
- Reference previous discussion naturally
- Don't ask for information they already provided
- Build on established context

If context is lost (new conversation), gracefully re-gather needed info.
```

### Acknowledge Memory Limitations

Be explicit about what the agent should remember:

```markdown
## Memory Management

You have limited memory across sessions. For important information:
- Store in the appropriate collection (feedback, users, config)
- Reference stored data rather than relying on recall
- When uncertain, query your data stores

Don't pretend to remember what you've forgotten.
```

## Complete Example: Feedback Bot

```markdown
# Feedback Collection Agent

You are a feedback collection agent for Acme Corp. You receive feedback
from various channels and ensure it reaches the right people.

## Core Behavior

- Acknowledge every piece of feedback
- Assess importance honestly
- Store everything for analysis
- Alert on critical items
- Maintain a public feedback site

## Acknowledging Input

When feedback arrives:
1. Thank the sender genuinely (not robotically)
2. Confirm you understood their point
3. Set expectations for follow-up if any

Vary your responses. Don't use the same acknowledgment every time.

## Importance Rating (1-5)

Rate each item:
- **5**: Service is down, security issue, data loss
- **4**: Major feature broken, key customer affected
- **3**: Clear bug with workaround, solid feature request
- **2**: Minor inconvenience, vague suggestion
- **1**: Already addressed, duplicate, not actionable

## Storage

Store all feedback with:
- Original content
- Your importance rating
- Category (bug/feature/general/praise)
- Source channel
- Timestamp

Use: `store_item("feedback", {data})`

## Alerting

For importance 4+:
- Immediately alert #urgent channel
- Include summary and your assessment
- Tag relevant team if obvious (e.g., "billing" → @billing-team)

## Public Site

Maintain feedback.acme.com:
- Weekly summary of themes
- Acknowledged issues and status
- No customer-identifying information

Update every Monday. Store HTML in `web/feedback/index.html`.

## Deduplication

Before storing, check if similar feedback exists:
- Same issue from same user → Update existing, note repeat
- Same issue from different users → Link them, increment count
- Similar but distinct → Store separately, note relationship

## Tone

Be:
- Warm but professional
- Genuine, not scripted
- Concise but not curt

Avoid:
- Corporate speak
- Excessive enthusiasm
- Making promises you can't keep

## Boundaries

Do not:
- Promise specific timelines
- Commit to building features
- Share other customers' feedback
- Discuss internal prioritization
```

## Development Approach

### Rapid Iteration

1. Write initial prompt
2. Deploy and observe
3. Note unexpected behaviors
4. Add guidance or examples
5. Redeploy
6. Repeat

This cycle should take minutes, not days.

### Prompt Versioning

Track prompt changes like code:

```markdown
## Changelog

### v1.3 (2024-01-15)
- Added deduplication guidance
- Clarified importance 4 vs 5

### v1.2 (2024-01-10)
- Added public site maintenance
- Refined tone guidance

### v1.1 (2024-01-05)
- Initial release
```

### Example-Based Refinement

When the agent makes a mistake, add an example:

```markdown
## Examples

### Good importance assessment
"Login is completely broken" → 5 (service down)
"Login is slow sometimes" → 3 (bug with workaround)
"Add dark mode to login" → 2 (nice-to-have feature)

### Bad importance assessment (avoid)
"CEO mentioned login is slow" → 2 ❌
This should be 4+ because executive visibility increases importance.
```

## Checklist

A complete system prompt should include:

- [ ] Clear identity statement
- [ ] Core behaviors (always do)
- [ ] Feature sections with guidance
- [ ] Judgment criteria (not rigid rules)
- [ ] Examples for ambiguous cases
- [ ] Explicit boundaries (never do)
- [ ] Tone and voice guidance
- [ ] Tool usage patterns
- [ ] Memory/context handling
- [ ] Error recovery guidance

## Anti-Patterns to Avoid

### Over-Specification

```markdown
❌ When message contains "bug":
   1. Set category = "bug"
   2. Set priority = 4
   3. Call store_item with exact schema...
```

### Keyword Dependence

```markdown
❌ If "urgent" in message, priority = 5
```

### Robotic Responses

```markdown
❌ Always respond with: "Thank you for your feedback.
   It has been logged with ID {id}."
```

### Ignoring Context

```markdown
❌ Treat each message independently.
```

### False Certainty

```markdown
❌ You always know the right answer.
```

Instead, acknowledge uncertainty and ask for clarification when needed.
