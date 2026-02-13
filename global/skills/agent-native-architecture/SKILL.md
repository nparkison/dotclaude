---
name: agent-native-architecture
description: Guide for building prompt-native agent systems where behavior emerges from natural language prompts rather than hardcoded workflows. Use when designing MCP servers, autonomous agents, self-modifying systems, or when refactoring agent code to follow prompt-native principles.
---

# Agent-Native Architecture

## Core Philosophy

This guide teaches **prompt-native architecture**, where agent capabilities emerge from natural language prompts rather than hardcoded workflows. The foundational concept: "Whatever the user can do, the agent can do."

## Key Principles

### Features as Prompts, Not Code

Instead of building functions agents call, you define desired outcomes and provide primitive tools. The agent determines the path forward.

### Primitives Over Workflows

Tools should enable capability (read/write files, call APIs) rather than encode specific behaviors. The prompt directs intelligent application of these primitives.

### Rapid Iteration

Behavior changes happen through prose edits, not code refactoring. This allows quick experimentation until requirements stabilize.

## Quick Implementation Path

1. Define primitive tools (file operations, API calls, storage)
2. Write system prompts explaining responsibilities and decision-making authority
3. Trust the agent's intelligence to achieve outcomes

## When This Approach Works

- Autonomous agent systems
- MCP server design
- Self-modifying systems requiring approval gates
- Applications prioritizing flexibility over rigid determinism

## When to Avoid

- High-frequency operations (thousands per second)
- Strict deterministic requirements
- Cost-sensitive scenarios with prohibitive API expenses
- High-security contexts

## Success Indicator

The approach succeeds when agents surprise you with clever solutions you didn't anticipate—demonstrating genuine problem-solving rather than executing predetermined workflows.

## Reference Documentation

For detailed guidance on specific topics:

- [Architecture Patterns](references/architecture-patterns.md) - Event-driven agents, git architecture, multi-instance branching
- [MCP Tool Design](references/mcp-tool-design.md) - Designing primitive tools for prompt-native systems
- [Refactoring Guide](references/refactoring-to-prompt-native.md) - Converting existing agent code to prompt-native patterns
- [Self-Modification](references/self-modification.md) - Enabling agents to evolve their own code and behavior
- [System Prompt Design](references/system-prompt-design.md) - Writing effective prompts that define agent behavior
