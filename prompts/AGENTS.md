# Agent Commands & Actions System

This directory contains specialized commands and actions that agents should recognize and execute. Commands are organized by agent role for efficiency and clarity.

---

## 📋 Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Available Agent Commands](#available-agent-commands)
- [Command File Structure](#command-file-structure)
- [Adding New Commands](#adding-new-commands)

---

## Overview

The agent commands system provides standardized workflows for common project management and development tasks. Each agent role has a dedicated command file containing only the commands relevant to that role.

**Benefits:**
- **Efficiency**: Agents only load relevant commands for their role
- **Clarity**: Clear separation of responsibilities
- **Maintainability**: Easy to update individual agent behaviors
- **Scalability**: Simple to add new commands or agent types

---

## How It Works

1. **Agent adopts a role** - AI reads agent file from `agents/` directory (e.g., `agents/pm.md`)
2. **Agent checks for commands** - Agent file directs them to read `prompts/agents/{role}.md` for specific commands
3. **Agent executes commands** - Agent follows the workflow defined in their command file

---

## Available Agent Commands

| Agent Role | Command File | Description |
|------------|--------------|-------------|
| **Project Manager** | [`prompts/agents/pm.md`](agents/pm.md) | Sprint planning, progress reports, coordination |
| **Architect** | [`prompts/agents/architect.md`](agents/architect.md) | Architecture reports, technical standards *(coming soon)* |
| **QA Engineer** | [`prompts/agents/qa.md`](agents/qa.md) | Test coverage reports, quality gates *(coming soon)* |
| **DevOps Engineer** | [`prompts/agents/devops.md`](agents/devops.md) | Deployment readiness reports *(coming soon)* |
| **Frontend Developer** | [`prompts/agents/frontend_dev.md`](agents/frontend_dev.md) | Frontend-specific workflows *(coming soon)* |
| **Backend Developer** | [`prompts/agents/backend_dev.md`](agents/backend_dev.md) | Backend-specific workflows *(coming soon)* |
| **Fullstack Developer** | [`prompts/agents/fullstack_dev.md`](agents/fullstack_dev.md) | Full-stack workflows *(coming soon)* |
| **Security Engineer** | [`prompts/agents/security.md`](agents/security.md) | Security reviews, threat modeling *(coming soon)* |
| **Data Engineer** | [`prompts/agents/data_engineer.md`](agents/data_engineer.md) | Data pipeline workflows *(coming soon)* |
| **UX/Product Designer** | [`prompts/agents/ux_designer.md`](agents/ux_designer.md) | Design systems, user research *(coming soon)* |

---

## Command File Structure

Each agent command file (`prompts/agents/{role}.md`) follows this structure:

```markdown
# {Agent Role} Commands

## Command Name (TRIGGER_CODE)

**Trigger Phrases:**
- "Full command phrase"
- "SHORT_CODE"
- "Alternative phrase"

**Action:**
When the {Role} agent receives this command, it should:

1. **Step 1**: Description
   - Details
   - Sub-steps

2. **Step 2**: Description
   - Details

3. **Output**: What to produce
   - File path conventions
   - Format requirements
```

---

## Adding New Commands

To add a new command for any agent:

1. **Open the agent's command file**: `prompts/agents/{role}.md`
2. **Add a new section** with:
   - Clear command name and trigger code
   - List of trigger phrases (including short codes)
   - Step-by-step action workflow
   - Output specifications (file paths, formats)
   - Prerequisites or dependencies

3. **Update the agent file**: Ensure `agents/{role}.md` references the command file
4. **Test the command**: Verify trigger phrases work as expected
5. **Document examples**: Add usage examples if complex

---

## Notes for Agents

### Command Display Requirement (CRITICAL)
**When you load your agent role and read your command file, you MUST:**
1. Parse all available commands from your command file
2. Display a summary list to the user showing:
   - Command name
   - Primary trigger phrase(s)
   - Brief description (one line)

**Example format:**
```
📋 Available Commands for [Agent Role]:
• GPP (Generate Project Progress Report) - Create comprehensive project status reports
• [Command 2] - Description
• [Command 3] - Description
```

This ensures users are always aware of what commands you can execute.

### Command Execution
When executing commands:
- **Always confirm** what command you're executing
- **Be thorough** - don't skip steps in the workflow
- **Be accurate** - verify facts, don't assume
- **Be actionable** - provide concrete next steps
- **Be consistent** - follow templates exactly
- **Update documentation** - suggest improvements when you find better workflows

---

## Integration with Agent System

This command system integrates with the main agent system defined in:
- `agents/AGENTS.md` - Agent role selection and identity adoption
- `agents/{role}.md` - Individual agent role definitions and workflows
- `.virtualboard/` - Feature tracking and project management

Agents should:
1. First adopt their role by reading `agents/{role}.md`
2. Then check `prompts/agents/{role}.md` for specific commands
3. Execute commands following the defined workflows

---

**Last Updated:** 2025-10-09
**Maintainer:** Project Team
