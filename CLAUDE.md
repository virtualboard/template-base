# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VirtualBoard is a feature specification and workflow management system designed for multi-agent AI collaboration. It provides a structured, Markdown-first approach to managing software development features through their complete lifecycle using specialized AI agent roles.

## Core Architecture

### Agent-First Design

**CRITICAL FIRST STEP**: Before starting ANY task, you MUST:

1. **Check for agent directories** in this order:
   - `agents/` (primary agent role definitions)
   - `.virtualboard/agents/` (project-specific overrides if present)

2. **Analyze the task** and adopt the appropriate agent role:
   - Read `agents/AGENTS.md` for role selection guidelines
   - Read the specific role file (e.g., `agents/frontend_dev.md`)
   - **Announce your adopted role** (e.g., "I am working as a Frontend Developer agent")
   - Follow that agent's specific workflow throughout the task

3. **Load agent-specific commands**:
   - Check `prompts/agents/{role}/README.md` for available commands
   - Display available commands to the user
   - Execute commands following defined workflows

### Agent Roles and Responsibilities

| Role | File | Use For |
|------|------|---------|
| Project Manager | `agents/pm.md` | Sprint planning, progress tracking, backlog grooming |
| System Architect | `agents/architect.md` | Architecture design, technical decisions, technical debt |
| Backend Developer | `agents/backend_dev.md` | APIs, databases, server-side logic |
| Frontend Developer | `agents/frontend_dev.md` | UI components, client-side interactions |
| Fullstack Developer | `agents/fullstack_dev.md` | End-to-end features spanning frontend and backend |
| QA Engineer | `agents/qa.md` | Testing, quality assurance, test plans, browser automation |
| DevOps Engineer | `agents/devops_engineer.md` | CI/CD, deployment, infrastructure, monitoring |
| Security Engineer | `agents/security_compliance_engineer.md` | Security reviews, threat modeling, compliance |
| Data Engineer | `agents/data_analytics_engineer.md` | Data pipelines, analytics, metrics |
| UX Designer | `agents/ux_product_designer.md` | User journeys, wireframes, design systems |

### Feature Lifecycle

Features move through these states:
```
backlog → in-progress → review → done
              ↓
           blocked (when waiting on dependencies)
```

Each feature is a Markdown file in `features/{status}/` with:
- Frontmatter containing metadata (id, status, owner, priority, etc.)
- Structured sections (Summary, Requirements, Acceptance Criteria, etc.)
- Implementation notes and links

**CRITICAL RULE**: When moving a feature file between folders, you MUST:
- Update frontmatter `status` field to match destination folder
- Update frontmatter `updated` field to today's date (YYYY-MM-DD)
- Update frontmatter `owner` field when claiming or releasing ownership

### Directory Structure

```
features/
├── backlog/         # Unassigned features awaiting work
├── in-progress/     # Features currently being developed
├── blocked/         # Features waiting on external dependencies
├── review/          # Features ready for review
├── done/            # Completed features
└── INDEX.md         # Auto-generated index (don't edit manually)

agents/              # Agent role definitions and identity prompts
├── AGENTS.md        # Role selection guide
├── RULES.md         # Shared rules of engagement
├── pm.md            # Project Manager role
├── architect.md     # System Architect role
└── [other role files]

prompts/             # Agent commands and specialized actions
├── AGENTS.md        # Command system overview
├── agents/          # Role-specific command files
│   ├── pm/          # PM commands (GPP, GBG, etc.)
│   ├── architect/   # Architect commands (GAD, GAR, GTD)
│   ├── backend_dev/ # Backend commands (GAD, GAE, GDM)
│   ├── frontend_dev/# Frontend commands (GAA, GC, GCS)
│   ├── qa/          # QA commands (GTP, GBR, GTCR, GBAT)
│   └── [other role command directories]
└── common/          # Shared templates

scripts/             # Automation scripts
├── ftr-new.sh       # Create new feature
├── ftr-move.sh      # Move feature between states
├── ftr-validate.sh  # Validate all features
├── ftr-index.sh     # Generate features/INDEX.md
└── install-vb-cli.sh# Install Virtual Board CLI tool

templates/           # Templates for features and PRs
├── spec.md          # Feature spec template
├── pr-template.md   # Pull request template
└── rules.yml        # Agent rules configuration

schemas/             # Validation schemas
└── frontmatter.schema.json  # Frontmatter validation
```

## Common Commands

### Feature Management

**Using Virtual Board CLI (if installed):**
```bash
# Check if CLI is available
vb version

# Initialize VirtualBoard workspace (first time setup)
vb init

# Update existing workspace to latest template
vb init --update

# Update specific files only
vb init --update --files agents/pm.md,templates/spec.md

# Auto-apply updates without prompting
vb init --update --yes

# Create new feature
vb new "Feature Title" label1 label2

# Move feature between states
vb move FTR-0001 in-progress --owner fullstack_dev

# Validate all features
vb validate

# Generate feature index
vb index

# Upgrade CLI
vb upgrade
```

**Using Shell Scripts (fallback):**
```bash
# Make scripts executable first
chmod +x scripts/*.sh

# Create new feature
./scripts/ftr-new.sh "Feature Title" label1 label2

# Move feature between states
./scripts/ftr-move.sh FTR-0001 in-progress fullstack_dev

# Validate all features
./scripts/ftr-validate.sh

# Generate feature index
./scripts/ftr-index.sh
```

### Agent Workflow

1. **Check for available work**: `cat features/INDEX.md`
2. **Adopt appropriate agent role**: Read `agents/AGENTS.md` and role-specific file
3. **Claim a feature**: Move from backlog to in-progress with ownership
4. **Work on implementation**: Update feature file with notes and links
5. **Move to review**: When complete, move to review status
6. **Complete**: QA agent validates and moves to done

## Agent Commands System

Each agent role has specialized commands for common tasks. Commands are triggered by specific phrases and follow structured workflows.

**Command Format:**
- Commands have short codes (e.g., `GPP`, `GAD`, `GTP`, `GBAT`)
- Each produces standardized output in designated locations
- Outputs are linked back to relevant feature specs

**Example Commands:**
- `GPP` (PM): Generate Project Progress Report → `.virtualboard/reports/`
- `GAD` (Architect): Generate Architecture Decision → `.virtualboard/architecture/`
- `GTP` (QA): Generate Test Plan → `.virtualboard/testing/`
- `GBAT` (QA): Generate Browser Automation Tests → Test cases, Playwright scripts, execution reports
- `GAE` (Backend): Generate API Endpoint → implementation code

When adopting a role, check `prompts/agents/{role}/README.md` for full command list.

## Key Workflows

### Creating and Working on a Feature

1. **Check for CLI availability**:
   ```bash
   command -v vb &> /dev/null && echo "CLI available" || echo "Use scripts"
   ```

2. **Create feature** (as PM agent):
   ```bash
   vb new "User Authentication" backend security
   # or
   ./scripts/ftr-new.sh "User Authentication" backend security
   ```

3. **Claim and start work** (as appropriate agent):
   ```bash
   vb move FTR-0001 in-progress backend_dev
   # CRITICAL: Update frontmatter status, owner, and updated fields
   ```

4. **Implement feature**: Update feature file with implementation notes

5. **Move to review**:
   ```bash
   vb move FTR-0001 review
   # CRITICAL: Update frontmatter status and updated fields
   ```

6. **QA validates** (as QA agent): Test and move to done or back to in-progress

### Multi-Agent Collaboration

- **Dependencies**: Use frontmatter `dependencies` field to link features
- **Ownership**: Only one agent can own a feature at a time
- **Communication**: Update feature file's Implementation Notes section
- **Handoffs**: Use `prompts/common/session-handoff.md` template

## QA Agent - Browser Automation Testing (GBAT)

The QA agent has a powerful **GBAT (Generate Browser Automation Tests)** command for comprehensive browser testing:

**Workflow:**
1. **Phase 1**: Generate test cases in markdown (`.virtualboard/docs/browser-test-cases/`)
2. **Phase 2**: Generate Playwright automation scripts with Page Object Model
3. **Phase 3**: Execute tests across specified browsers (Chrome, Firefox, Safari)
4. **Phase 4**: Generate detailed reports (markdown/HTML)

**Usage:**
```
GBAT for FTR-0042
```

The command will:
- Ask for test directory (default: `./tests/browser`)
- Ask for browsers (default: `chromium`, options: `chromium`, `firefox`, `webkit`, `all`)
- Ask for base URL (default: `http://localhost:3000`)
- Ask for report format (default: `markdown`, options: `markdown`, `html`, `both`)

**Output:**
- Test case documentation
- Playwright configuration
- Page Object Models
- Test specifications
- Helper utilities
- Execution reports with screenshots and videos

See `prompts/agents/qa/examples/GBAT-example.md` for a complete walkthrough.

## Validation Rules

The system enforces these rules (via `scripts/ftr-validate.sh` or `vb validate`):

- Frontmatter must match JSON schema
- File location MUST match frontmatter `status` field
- No circular dependencies
- Dependencies must be resolved before moving to in-progress
- Ownership conflicts prevented (one owner per feature)

**Run validation before committing:**
```bash
vb validate || ./scripts/ftr-validate.sh
```

## Important Notes

### Critical Requirements

1. **Always read agent files before starting work** - Never assume agent behavior
2. **Always update frontmatter when moving files** - status, owner, and updated fields
3. **Always validate before committing** - Run validation scripts
4. **Never edit INDEX.md manually** - It's auto-generated
5. **Never change feature ID or filename** - These are immutable

### Best Practices

- Use the CLI (`vb`) when available for better error handling
- Follow the agent's specific workflow for your adopted role
- Keep feature files updated with current progress
- Link PRs, commits, and artifacts in the feature's Links section
- Reference feature IDs (FTR-####) in all commits and PRs

### Zero Dependencies Design

- Built entirely with bash scripts
- No Node.js or npm required (except for Playwright tests)
- Works on any Unix-like system
- CI/CD friendly with no build steps

## Integration Points

### Cursor IDE

The `.cursor/rules/virtualboard.mdc` file enables automatic VirtualBoard integration in Cursor IDE.

### Claude Code Plugin

VirtualBoard is available as a Claude Code plugin. Install via:
```bash
claude plugin marketplace add virtualboard/template-base
claude plugin install virtualboard
```

See `.claude-plugin/README.md` for plugin documentation.

### CI/CD

Add validation to your pipeline:
```yaml
- name: Validate Features
  run: |
    if command -v vb &> /dev/null; then
      vb validate
    else
      ./scripts/ftr-validate.sh
    fi
```

## Troubleshooting

**"Feature already owned"** → Another agent is working on it, find another feature

**"Circular dependency"** → Dependencies form a loop, human must resolve

**"Invalid transition"** → Not allowed to move to that status, check `agents/RULES.md`

**"Location mismatch"** → File location doesn't match frontmatter status field, fix one or the other

**Scripts permission denied** → Run `chmod +x scripts/*.sh`

**Playwright tests failing** → Check browser installation with `npx playwright install`

## Quick Reference

**First time setting up VirtualBoard?**
1. Install the VirtualBoard CLI: `./scripts/install-vb-cli.sh`
2. Initialize workspace: `vb init`
3. Read `agents/AGENTS.md` to understand agent system
4. Check `features/INDEX.md` for available work

**First time in this repo?**
1. Read `agents/AGENTS.md` to understand agent system
2. Check `features/INDEX.md` for available work
3. Adopt appropriate agent role
4. Follow agent-specific workflow

**Updating workspace template?**
1. Run `vb init --update` to update to latest template
2. Review changes before applying
3. Use `vb init --update --yes` for auto-apply
4. Use `vb init --update --files <files>` for selective updates

**Starting a task?**
1. Determine appropriate agent role from task type
2. Read `agents/{role}.md` for role definition
3. Announce your role
4. Check `prompts/agents/{role}/README.md` for commands
5. Follow role-specific workflow

**Working on a feature?**
1. Claim ownership by moving to in-progress (update frontmatter!)
2. Update feature file as you work
3. Move to review when complete (update frontmatter!)
4. Link all PRs and commits in feature file

**Running browser tests?**
1. Adopt QA agent role
2. Use `GBAT` command for comprehensive browser testing
3. Follow the 4-phase workflow
4. Review generated reports and fix issues
