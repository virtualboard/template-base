# VirtualBoard Feature Spec Workflow

This directory contains the complete implementation of the Feature Spec Workflow system for managing features with multiple AI agents.

## Claude Code Plugin

VirtualBoard is now available as a Claude Code plugin! Install it directly in Claude Code:

```bash
claude plugin marketplace add virtualboard/template-base
claude plugin install virtualboard
```

Or use the plugin marketplace. See [.claude-plugin/README.md](.claude-plugin/README.md) for full plugin documentation.

### `/work-on` Skill

The plugin includes a `/work-on` skill for working on features in isolated git worktrees:

```bash
# Basic usage - work on a feature interactively
/work-on FTR-0042

# Autonomous mode (no clarifying questions)
/work-on FTR-0042 --autonomous

# Custom worktree location
/work-on FTR-0042 --worktree-path ~/worktrees

# Branch from develop instead of main
/work-on FTR-0042 --base-branch develop

# Create PR after pushing
/work-on FTR-0042 --create-pr
```

The skill:
- Creates a git worktree with branch `feature/FTR-XXXX/feature-slug`
- Detects and resumes existing work on the branch
- Spawns a new Claude Code session in the worktree
- Commits with footer: `FTR-XXXX implemented using the @virtualboard /work-on skill`
- Pushes the branch (and optionally creates a PR)

See `skills/work-on/config.md` for configuration options.

## Cursor IDE Integration

VirtualBoard includes a `.cursor/rules/virtualboard.mdc` file that enables automatic integration with [Cursor](https://cursor.sh/) IDE. This rule tells Cursor to use the VirtualBoard workflow and agent system.

### Option 1: Project-Level Installation (Recommended)

Copy the `.cursor` folder to your project root to enable VirtualBoard for that specific project:

```bash
# If you're using this template
cp -r .cursor /path/to/your/project/

# Or if you're cloning this repository
git clone https://github.com/virtualboard/template-base.git
cp -r template-base/.cursor /path/to/your/project/
```

### Option 2: Global Installation

To enable VirtualBoard across all your projects in Cursor, add the rule globally:

1. Open Cursor Settings (Cmd/Ctrl + ,)
2. Navigate to "Cursor Settings" → "Rules for AI"
3. Click "Edit in settings.json"
4. Add the VirtualBoard rule:

```json
{
  "cursor.rules": [
    {
      "description": "Virtualboard Task Tracker",
      "alwaysApply": true,
      "content": "You will use the Virtualboard strategy defined on @.virtualboard/AGENTS.md to keep track of tasks and progress\n\nWorkspace for the Virtualboard is the @.virtualboard/features folder"
    }
  ]
}
```

**Note:** Project-level rules (`.cursor/rules/`) take precedence over global rules. If you have both, the project-level rule will be used.

## OpenCode Integration

VirtualBoard agents can be easily integrated into [OpenCode](https://github.com/stackblitz/opencode), an open source AI coding tool.

To enable VirtualBoard agents in OpenCode:

1. **Copy agent files to OpenCode directory:**
   ```bash
   mkdir -p .opencode/agent && cp -Rf .virtualboard/agents .opencode/agent
   ```

2. **Reload OpenCode:**
   Restart your OpenCode session to load the agents.

3. **Use agents:**
   Once reloaded, the VirtualBoard agents (PM, Architect, Frontend Dev, Backend Dev, QA, etc.) will be available in OpenCode.

**What gets copied:**
- All agent role definitions (`agents/*.md`)
- Agent command system (`prompts/agents/`)
- Shared rules of engagement (`agents/RULES.md`)

**Benefits:**
- Native agent integration
- Quick access to specialized agent commands
- Consistent agent behavior
- No additional configuration needed

## Implementation

The system is built entirely with bash scripts, eliminating the need for Node.js or npm dependencies. This approach provides:

- **Zero dependencies**: No package.json or node_modules required
- **Universal compatibility**: Works on any Unix-like system with bash
- **Fast execution**: Direct shell commands without JavaScript runtime overhead
- **Easy maintenance**: Simple bash scripts that are easy to understand and modify
- **CI/CD friendly**: No build steps or dependency installation required

**CLI Tool Integration:** The system first checks for the `vb` (Virtual Board) CLI tool. If available, agents should use `vb` commands for task management. If not found, agents should fall back to the shell scripts in `.virtualboard/scripts/` or use plain bash commands according to the strategy definition.

## System Specification Templates

Beyond feature files, the template ships with a `/templates/specs` catalog of reusable system blueprints. Copy any Markdown file to your project's `/specs` directory to document foundational decisions before (or alongside) feature work:

- `tech-stack.md` – Languages, runtimes, frameworks, third-party services, and guiding principles.
- `local-development.md` – Environment setup, tooling, secrets, seeding, and troubleshooting checklists.
- `hosting-and-infrastructure.md` – Cloud/on-prem topology, networking, DR, and cost governance.
- `ci-cd-pipeline.md` – Build/test/deploy stages, gating, security checks, and ownership.
- `database-schema.md` – Authoritative data model, migrations, lifecycle, and performance considerations.
- `caching-and-performance.md` – Cache layers, SLIs/SLOs, invalidation strategy, and perf testing.
- `security-and-compliance.md` – Threat model, controls, logging/audit needs, and incident workflows.
- `observability-and-incident-response.md` – Telemetry coverage, alerting, runbooks, and postmortems.

Each template includes frontmatter compatible with `schemas/system-spec.schema.json`, so `vb validate` (or `./scripts/ftr-validate.sh`) enforces required metadata just like feature specs. See `templates/specs/README.md` for usage tips.

## Quick Start

### Option 1: Using Virtual Board CLI (Recommended)

1. **Install the Virtual Board CLI:**
   ```bash
   # Quick install (recommended):
   ./scripts/install-vb-cli.sh

   # Or install to current directory:
   ./scripts/install-vb-cli.sh --local

   # For help:
   ./scripts/install-vb-cli.sh --help
   ```

   The installer automatically:
   - Checks if `vb` is already installed and compares versions
   - If you already have the latest version, it will inform you and exit
   - If an older version is installed, it suggests using `vb upgrade` instead
   - Detects your OS (macOS/Linux) and architecture (amd64/arm64)
   - Downloads the appropriate binary from the latest GitHub release
   - Guides you through the installation with confirmation prompts

2. **Check CLI installation:**
   ```bash
   vb version
   vb help
   ```

3. **Initialize VirtualBoard workspace:**
   ```bash
   # Initialize a new VirtualBoard workspace
   vb init

   # Update existing workspace to latest template
   vb init --update

   # Update specific files only
   vb init --update --files agents/pm.md,templates/feature.md
   ```

4. **Use CLI commands:**
   ```bash
   # Create a new feature
   vb new "Feature Title" label1 label2

   # Move a feature through lifecycle
   vb move FTR-0001 in-progress --owner fullstack_dev

   # Validate all features
   vb validate

   # Generate feature index
   vb index
   ```

### Option 2: Using Shell Scripts (Fallback)

1. **Make scripts executable:**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Create a new feature:**
   ```bash
   ./scripts/ftr-new.sh "Feature Title" label1 label2
   ```

3. **Move a feature through lifecycle:**
   ```bash
   ./scripts/ftr-move.sh FTR-0001 in-progress frontend_dev
   ```
   **IMPORTANT**: When moving a feature, you MUST update the frontmatter:
   - Update `status` field to match the destination folder
   - Update `updated` field to today's date
   - Update `owner` field if claiming/releasing ownership

4. **Validate all features:**
   ```bash
   ./scripts/ftr-validate.sh
   ```

5. **Generate feature index:**
   ```bash
   ./scripts/ftr-index.sh
   ```

## Directory Structure

```
├── features/                 # Feature specifications
│   ├── backlog/             # Unassigned features
│   ├── in-progress/         # Features being worked on
│   ├── blocked/             # Features waiting on dependencies
│   ├── review/              # Features ready for review
│   ├── done/                # Completed features
│   └── INDEX.md             # Auto-generated feature index
├── templates/               # Templates and configuration
│   ├── feature.md           # Feature spec template
│   ├── pr-template.md       # Pull request template
│   ├── rules.yml            # Agent rules configuration
│   └── specs/               # System specification templates
│       ├── README.md        # Catalog + usage instructions
│       ├── tech-stack.md    # Tech stack blueprint
│       ├── local-development.md # Local dev environment spec
│       ├── hosting-and-infrastructure.md
│       ├── ci-cd-pipeline.md
│       ├── database-schema.md
│       ├── caching-and-performance.md
│       ├── security-and-compliance.md
│       └── observability-and-incident-response.md
├── specs/                   # Project-specific system specifications
│   └── (copy templates here for your project)
├── agents/                  # Agent documentation and role prompts
│   ├── AGENTS.md            # Catalog of agent system prompts
│   ├── RULES.md             # Shared rules of engagement
│   ├── pm.md                # Project manager prompt
│   ├── architect.md         # System architect prompt
│   ├── ux_product_designer.md # UX/product designer prompt
│   ├── backend_dev.md       # Backend engineer prompt
│   ├── frontend_dev.md      # Frontend engineer prompt
│   ├── fullstack_dev.md     # Fullstack engineer prompt
│   ├── devops_engineer.md   # DevOps & reliability prompt
│   ├── security_compliance_engineer.md # Security & compliance prompt
│   ├── data_analytics_engineer.md # Data & analytics prompt
│   └── qa.md                # QA engineer prompt
├── prompts/                 # Agent commands and specialized actions
│   ├── AGENTS.md            # Command system overview and catalog
│   ├── agents/              # Role-specific command files
│   │   ├── pm/              # Project Manager commands (GPP, etc.)
│   │   ├── architect/       # Architect commands (GAD, GAR, GTD)
│   │   ├── backend_dev/     # Backend commands (GAD, GAE, GDM)
│   │   ├── frontend_dev/    # Frontend commands (GAA, GC, GCS)
│   │   ├── fullstack_dev/   # Fullstack commands (GFF, GIC, GETE)
│   │   ├── data_engineer/   # Data Engineer commands (GDP, GMD, GDQ, ERD)
│   │   ├── devops/          # DevOps commands (GDC, GDRR, GIR)
│   │   ├── security/        # Security commands (GSA, GSR, GTM)
│   │   ├── qa/              # QA commands (GBR, GTCR, GTP)
│   │   └── ux_designer/     # UX Designer commands (GDS, GUJ, GWF)
│   └── common/              # Common templates and utilities
│       └── session-handoff.md # Session handoff template
├── scripts/                 # Automation scripts
│   ├── ftr-new.sh           # Create new feature
│   ├── ftr-move.sh          # Move feature between states
│   ├── ftr-validate.sh      # Validate features
│   ├── ftr-index.sh         # Generate feature index
│   ├── install-vb-cli.sh    # Install Virtual Board CLI tool
│   └── worktree-setup.sh    # Git worktree setup for /work-on skill
├── skills/                  # Claude Code plugin skills
│   └── work-on/             # /work-on skill for feature development
│       ├── SKILL.md         # Skill definition
│       └── config.md        # Configuration reference
└── schemas/                 # Schema definitions
    ├── frontmatter.schema.json     # Feature frontmatter validation schema
    └── system-spec.schema.json     # System specification frontmatter schema
```

## Sample Features

The system includes sample features in different states to demonstrate the workflow:

- **FTR-0001** (backlog): User Authentication - Ready to be claimed
- **FTR-0002** (in-progress): Dashboard Widgets - Being worked on by fullstack_dev
- **FTR-0003** (blocked): External API Integration - Waiting for API keys
- **FTR-0004** (review): Notification System - Ready for review
- **FTR-0005** (done): Basic Application Layout - Completed

## Agent Usage

AI agents should:

1. **Check for CLI tool first:**
   ```bash
   if command -v vb &> /dev/null; then
       echo "Virtual Board CLI found"
       vb version
       vb help
       # Use CLI commands for task management
   else
       echo "Virtual Board CLI not found, using shell scripts"
       # Fall back to shell scripts
   fi
   ```

2. **Adopt an agent role:** Read `/agents/AGENTS.md` to understand available roles, then read the specific role file (e.g., `/agents/pm.md`)
3. **Load agent commands:** Check `/prompts/agents/{role}/README.md` for specialized commands available to your role
4. **Read the agent rules:** `/agents/RULES.md`
5. **Check available work:** Look at `/features/INDEX.md`
6. **Claim a feature:** Move from `backlog` to `in-progress` with your agent ID
   - **CRITICAL**: Update frontmatter `status`, `owner`, and `updated` fields when moving
7. **Work on the feature:** Update implementation notes and links
8. **Hand off for review:** Move to `review` status when complete
   - **CRITICAL**: Update frontmatter `status` and `updated` fields when moving

## Agent Roster

The virtual team is defined in `agents/`:
- Project Manager (`agents/pm.md`)
- System Architect (`agents/architect.md`)
- UX/Product Designer (`agents/ux_product_designer.md`)
- Backend Developer (`agents/backend_dev.md`)
- Frontend Developer (`agents/frontend_dev.md`)
- Fullstack Developer (`agents/fullstack_dev.md`)
- DevOps & Reliability Engineer (`agents/devops_engineer.md`)
- Security & Compliance Engineer (`agents/security_compliance_engineer.md`)
- Data & Analytics Engineer (`agents/data_analytics_engineer.md`)
- QA Engineer (`agents/qa.md`)
- Shared Rules of Engagement (`agents/RULES.md`)

## Agent Commands System

Each agent role has access to specialized commands for common tasks. Commands are organized by role in the `prompts/agents/` directory.

### Available Command Sets

| Agent Role | Commands Directory | Key Commands |
|------------|-------------------|--------------|
| **Project Manager** | `prompts/agents/pm/` | GPP (Project Progress Report) |
| **Architect** | `prompts/agents/architect/` | GAD (Architecture Diagram), GAR (Architecture Review), GTD (Technical Debt) |
| **Backend Developer** | `prompts/agents/backend_dev/` | GAD (API Documentation), GAE (API Endpoint), GDM (Data Migration) |
| **Frontend Developer** | `prompts/agents/frontend_dev/` | GAA (Accessibility Audit), GC (Component), GCS (Component Storybook) |
| **Fullstack Developer** | `prompts/agents/fullstack_dev/` | GFF (Full Feature), GIC (Integration Contract), GETE (E2E Test) |
| **Data Engineer** | `prompts/agents/data_engineer/` | GDP (Data Pipeline), GMD (Metrics Dashboard), GDQ (Data Quality), ERD (Entity Relationship Diagram) |
| **DevOps Engineer** | `prompts/agents/devops/` | GDC (Deployment Checklist), GDRR (Deployment Readiness), GIR (Incident Response) |
| **Security Engineer** | `prompts/agents/security/` | GSA (Security Audit), GSR (Security Review), GTM (Threat Model) |
| **QA Engineer** | `prompts/agents/qa/` | GBR (Bug Report), GTCR (Test Coverage), GTP (Test Plan) |
| **UX Designer** | `prompts/agents/ux_designer/` | GDS (Design System), GUJ (User Journey), GWF (Wireframe) |

### Using Agent Commands

When adopting an agent role:

1. **Read your role's README:** Check `prompts/agents/{role}/README.md` for available commands
2. **Display available commands:** Agents should show users what commands they can execute
3. **Execute commands:** Follow the detailed workflow in each command file (e.g., `prompts/agents/pm/GPP.md`)
4. **Follow templates:** Use the exact report structure and file paths specified in each command

See `prompts/AGENTS.md` for complete documentation on the command system.

## Validation

The system enforces several validation rules:

- Frontmatter must match JSON schema
- File location must match frontmatter `status` field (CRITICAL)
- Frontmatter `status` field must be updated when moving files
- Frontmatter `updated` field must be updated when making changes
- Dependencies must be resolved before `in-progress`
- No circular dependencies allowed
- Ownership conflicts are prevented
- System specs in `/specs` must satisfy `schemas/system-spec.schema.json` (status, spec_type, applicability, last_updated)

## Integration with CI/CD

Add these steps to your CI pipeline:

```yaml
- name: Check for Virtual Board CLI
  run: |
    if command -v vb &> /dev/null; then
      echo "Virtual Board CLI found"
      vb version
    else
      echo "Virtual Board CLI not found, using shell scripts"
    fi

- name: Make Scripts Executable (if CLI not available)
  if: steps.cli-check.outcome == 'failure'
  run: chmod +x scripts/*.sh

- name: Validate Features
  run: |
    if command -v vb &> /dev/null; then
      vb validate
    else
      ./scripts/ftr-validate.sh
    fi

- name: Generate Index
  run: |
    if command -v vb &> /dev/null; then
      vb index
    else
      ./scripts/ftr-index.sh
    fi
```

## Troubleshooting

**Common Issues:**

1. **"Feature already owned"** - Another agent is working on it
2. **"Circular dependency"** - Dependencies form a loop
3. **"Invalid transition"** - Not allowed to move to that status
4. **"Dependency not done"** - Required dependencies aren't complete

**Solutions:**

- Check `/features/INDEX.md` for available features
- Use CLI or shell scripts to validate: `vb validate` or `./scripts/ftr-validate.sh`
- Review the agent rules in `/agents/RULES.md`
- Ensure CLI is properly installed: `vb version`
- To install or upgrade the CLI: `./scripts/install-vb-cli.sh` or `vb upgrade`

## Contributing

When adding new features or modifying the system:

1. Follow the existing patterns
2. Update documentation as needed
3. Test with CLI or shell scripts: `vb validate` or `./scripts/ftr-validate.sh`
4. Update the feature index: `vb index` or `./scripts/ftr-index.sh`

## Virtual Board CLI

For enhanced task management, we recommend using the [Virtual Board CLI (`vb`)](https://github.com/virtualboard/vb-cli). The CLI provides:

- **Streamlined interface**: Simplified commands for common operations
- **Better error handling**: More descriptive error messages and validation
- **Enhanced features**: Additional functionality beyond basic shell scripts
- **Consistent experience**: Standardized interface across different environments

See the [Quick Start](#quick-start) section above for installation instructions and basic usage.

### Additional CLI Commands

```bash
# Initialize workspace (first time setup)
vb init

# Update workspace to latest template
vb init --update

# Update specific template files
vb init --update --files agents/pm.md,templates/spec.md

# Auto-apply updates without prompting
vb init --update --yes

# Upgrade CLI to latest version
vb upgrade
# Or use sudo if installed to system directory:
sudo vb upgrade

# List available features
vb list

# Show feature details
vb show FTR-0001

# Delete a feature
vb delete FTR-0001

# Manage feature locks
vb lock FTR-0001
vb lock --release FTR-0001

# Update feature metadata
vb update FTR-0001 --priority P1 --complexity H
```
