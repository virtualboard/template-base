---
name: virtualboard
description: Feature specification and workflow management system for multi-agent AI collaboration with structured Markdown-first approach to software development lifecycle
license: MIT
compatibility: opencode
metadata:
  version: 1.0.0
  category: workflow
  audience: all-agents
---

# Virtual Board

VirtualBoard is a feature specification and workflow management system designed for multi-agent AI collaboration. It provides a structured, Markdown-first approach to managing software development features through their complete lifecycle using specialized AI agent roles.

## Critical First Step: Agent Role Adoption

**BEFORE starting ANY task, you MUST:**

1. **Check for agent directories** in this order (first found takes precedence):
   ```bash
   # Check for agents directory
   ls -la agents/ 2>/dev/null || ls -la .virtualboard/agents/ 2>/dev/null
   ```

2. **If agent directories exist:**
   - Read `agents/AGENTS.md` to understand the agent system
   - **Analyze the current task** to determine the appropriate agent role
   - Read the specific role file (e.g., `agents/frontend_dev.md`)
   - **Announce your adopted role** (e.g., "I am working as a Frontend Developer agent")
   - Follow that agent's specific workflow throughout the task

3. **Available Agent Roles:**
   - `agents/pm.md` → Sprint planning, progress tracking, backlog grooming
   - `agents/architect.md` → Architecture design, technical decisions
   - `agents/backend_dev.md` → APIs, databases, server-side logic
   - `agents/frontend_dev.md` → UI components, client-side interactions
   - `agents/fullstack_dev.md` → End-to-end features
   - `agents/qa.md` → Testing, quality assurance, browser automation
   - `agents/devops_engineer.md` → CI/CD, deployment, infrastructure
   - `agents/security_compliance_engineer.md` → Security reviews, threat modeling
   - `agents/data_analytics_engineer.md` → Data pipelines, analytics
   - `agents/ux_product_designer.md` → User journeys, wireframes

## Feature Lifecycle

Features move through these states:
```
backlog → in-progress → review → done
              ↓
           blocked (when waiting on dependencies)
```

Each feature is a Markdown file in `features/{status}/` with:
- YAML frontmatter containing metadata (id, status, owner, priority, etc.)
- Structured sections (Summary, Requirements, Acceptance Criteria, etc.)
- Implementation notes and links

## Critical Rules

### When Moving Features Between Folders

**YOU MUST UPDATE THE FRONTMATTER:**

```yaml
status: in-progress  # MUST match destination folder name
owner: backend_dev   # MUST update when claiming/releasing ownership
updated: 2025-12-29  # MUST update to today's date (YYYY-MM-DD)
```

**Failure to update frontmatter will cause validation errors!**

### Immutable Fields

**NEVER change these fields:**
- `id` - Feature identifier (e.g., FTR-0001)
- `created` - Original creation date
- Filename must match the id

## Using Virtual Board

### Check CLI Availability

```bash
# Check if VirtualBoard CLI is installed
command -v vb &> /dev/null && echo "CLI available" || echo "Use scripts"
```

### Common Operations

**Create New Feature (as PM agent):**
```bash
# Using CLI
vb new "Feature Title" label1 label2

# Using scripts
./scripts/ftr-new.sh "Feature Title" label1 label2
```

**Move Feature Between States:**
```bash
# Using CLI (recommended)
vb move FTR-0001 in-progress --owner backend_dev

# Using scripts
./scripts/ftr-move.sh FTR-0001 in-progress backend_dev
```

**IMPORTANT:** After moving, manually verify frontmatter is updated!

**Validate All Features:**
```bash
# Using CLI
vb validate

# Using scripts
./scripts/ftr-validate.sh
```

**Generate Feature Index:**
```bash
# Using CLI
vb index

# Using scripts
./scripts/ftr-index.sh
```

### Workflow Example

1. **Check for work:**
   ```bash
   cat features/INDEX.md
   ```

2. **Adopt appropriate agent role:**
   ```bash
   cat agents/AGENTS.md
   cat agents/backend_dev.md  # Read specific role file
   ```

3. **Claim a feature:**
   ```bash
   vb move FTR-0001 in-progress --owner backend_dev
   # Then edit features/in-progress/FTR-0001-feature-name.md
   # Update frontmatter: status, owner, updated
   ```

4. **Work on implementation:**
   - Update feature file's Implementation Notes section
   - Link commits and PRs in the Links section
   - Reference feature ID (FTR-####) in all commits

5. **Move to review when complete:**
   ```bash
   vb move FTR-0001 review
   # Update frontmatter: status, updated
   ```

6. QA validates and moves to done

## Agent Commands System

Each agent role has specialized commands for common tasks. Commands are triggered by specific phrases and produce structured outputs.

**Check Available Commands:**
```bash
cat prompts/agents/{role}/README.md
```

**Example Commands:**
- `GPP` (PM) → Generate Project Progress Report
- `GAD` (Architect) → Generate Architecture Decision
- `GTP` (QA) → Generate Test Plan
- `GBAT` (QA) → Generate Browser Automation Tests (Playwright)
- `GAE` (Backend) → Generate API Endpoint

## Directory Structure

```
features/
├── backlog/         # Unassigned features
├── in-progress/     # Features being developed
├── blocked/         # Features waiting on dependencies
├── review/          # Features ready for review
├── done/            # Completed features
└── INDEX.md         # Auto-generated (don't edit manually)

agents/              # Agent role definitions
├── AGENTS.md        # Role selection guide
├── RULES.md         # Shared rules
└── [role].md        # Individual role files

prompts/             # Agent commands
├── AGENTS.md        # Command system overview
├── agents/          # Role-specific commands
│   ├── pm/
│   ├── architect/
│   ├── backend_dev/
│   ├── frontend_dev/
│   ├── qa/
│   └── [other roles]/
└── common/          # Shared templates

scripts/             # Automation scripts
├── ftr-new.sh
├── ftr-move.sh
├── ftr-validate.sh
├── ftr-index.sh
└── install-vb-cli.sh

templates/           # Templates for features and PRs
├── feature.md
├── pr-template.md
└── rules.yml

schemas/             # Validation schemas
└── frontmatter.schema.json
```

## Validation Rules

The system enforces:
- Frontmatter must match JSON schema
- File location MUST match frontmatter `status` field
- No circular dependencies
- Dependencies must be resolved before moving to in-progress
- One owner per feature (no conflicts)

**Always validate before committing:**
```bash
vb validate || ./scripts/ftr-validate.sh
```

## Best Practices

### DO
- ✅ Always read agent files before starting work
- ✅ Always update frontmatter when moving files (status, owner, updated)
- ✅ Always validate before committing
- ✅ Use the CLI (`vb`) when available
- ✅ Follow the agent's specific workflow for your adopted role
- ✅ Reference feature IDs (FTR-####) in all commits and PRs
- ✅ Link PRs and commits in feature's Links section

### DON'T
- ❌ Never edit INDEX.md manually (it's auto-generated)
- ❌ Never change feature ID or filename (immutable)
- ❌ Never skip frontmatter updates when moving files
- ❌ Never assume agent behavior (always read the role file)
- ❌ Never work on features owned by other agents

## When to Use This Skill

Use VirtualBoard when:
- Working in a repository with `features/` or `.virtualboard/` directories
- You see references to feature IDs like FTR-0001
- The user mentions agent roles (PM, architect, backend dev, etc.)
- You need to create or manage feature specifications
- You're collaborating with other AI agents on a project
- The user asks you to adopt a specific agent role

## Troubleshooting

**"Feature already owned"**
→ Another agent is working on it, find another feature in backlog

**"Circular dependency"**
→ Dependencies form a loop, human must resolve

**"Invalid transition"**
→ Not allowed to move to that status, check `agents/RULES.md`

**"Location mismatch"**
→ File location doesn't match frontmatter status field

**Scripts permission denied**
→ Run `chmod +x scripts/*.sh`

## Quick Start for New Users

If this is your first time in a VirtualBoard repository:

```bash
# 1. Check if CLI is installed
command -v vb

# 2. If not, install it (optional but recommended)
./scripts/install-vb-cli.sh

# 3. Read the agent system overview
cat agents/AGENTS.md

# 4. Check available work
cat features/INDEX.md

# 5. Adopt appropriate agent role based on task
cat agents/backend_dev.md  # Example

# 6. Start working!
```

## QA Agent Special: Browser Automation Testing

The QA agent has a powerful **GBAT** command for comprehensive browser testing:

**Usage:** `GBAT for FTR-0042`

**What it does:**
1. Generate test cases in markdown
2. Generate Playwright automation scripts with Page Object Model
3. Execute tests across browsers (Chrome, Firefox, Safari)
4. Generate detailed reports (markdown/HTML)

See `prompts/agents/qa/examples/GBAT-example.md` for complete walkthrough.

## Integration

VirtualBoard has zero dependencies (pure bash scripts) and integrates with:
- Claude Code (via `.claude/CLAUDE.md` and plugins)
- Cursor IDE (via `.cursor/rules/virtualboard.mdc`)
- OpenCode (via this SKILL.md)
- Any CI/CD pipeline (validation scripts)

## Resources

- Feature template: `templates/feature.md`
- Agent rules: `agents/RULES.md`
- Schema validation: `schemas/frontmatter.schema.json`
- Session handoff template: `prompts/common/session-handoff.md`

---

**Remember:** Always start by adopting the appropriate agent role for your task. This is not optional—it's fundamental to how VirtualBoard works!
