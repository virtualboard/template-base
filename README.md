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

# Explicitly publish the branch and open a draft PR
/work-on FTR-0042 --create-pr
```

The skill:
- Creates a git worktree with branch `feature/FTR-XXXX/feature-slug`
- Detects and resumes existing work on the branch
- Runs the implementation session in the selected worktree
- Commits with footer: `FTR-XXXX implemented using the @virtualboard /work-on skill`
- Keeps work local by default; publishing requires an explicit option or saved preference

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

All workflow operations run through the `vb` CLI — a single static binary with no runtime dependencies (no Node.js, npm, or Python). This approach provides:

- **Zero runtime dependencies**: A single binary for macOS/Linux on amd64/arm64
- **Universal compatibility**: Works on any Unix-like system
- **Consistent behavior**: One canonical implementation of validation, moves, indexing, and locks
- **CI/CD friendly**: Install once, then invoke `vb` commands directly

**CLI Tool Requirement:** The `vb` CLI is required. Install it before any board operation with `./scripts/install-vb-cli.sh --ensure-latest`. A project's `.vb-version` selects an exact release; without one, the installer resolves the latest release tag once and downloads that immutable tag. It verifies the matching SHA-256 checksum and stages the binary beside its destination before replacement. System-wide installation requires the explicit `--allow-sudo` option. There are no shell-script fallbacks for feature operations.

## Feature template sizes

`vb new "Feature title"` uses the full planning template. For a small, bounded
change, use `vb new "Small fix" --template light`. The compact template keeps a
summary, testable acceptance criteria, implementation notes, verification evidence,
and links. Both sizes share the schema and lifecycle; choose the full template
when data, rollout, security, or UI planning needs dedicated sections.

For review, record the implementation commit, commands run, their actual results,
and the criteria demonstrated. Explain checks that could not be run.

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

Each template includes frontmatter compatible with `schemas/system-spec.schema.json`, so `vb validate` enforces required metadata just like feature specs. See `templates/specs/README.md` for usage tips.

## Quick Start

1. **Install the Virtual Board CLI (required):**
   ```bash
   # Install to /usr/local/bin (explicitly permits sudo)
   ./scripts/install-vb-cli.sh --allow-sudo

   # Or install to current directory:
   ./scripts/install-vb-cli.sh --local

   # For help:
   ./scripts/install-vb-cli.sh --help
   ```

   The installer detects your OS and architecture, resolves either the project's pinned version or the latest release tag, verifies its checksum, and replaces the installed binary atomically. Add `--allow-sudo` when the chosen install directory requires elevated privileges; otherwise use `--local` or a user-writable path.

   > **Note:** Agents should run `./scripts/install-vb-cli.sh --ensure-latest` at the start of a task. With `.vb-version`, it installs that exact version; without a pin, it installs the latest release resolved for that invocation.

2. **Verify the installation:**
   ```bash
   vb version
   vb help
   ```

3. **Initialize a VirtualBoard workspace:**
   ```bash
   vb init                                              # New workspace
   vb init --update                                     # Update to the template release paired with this CLI
   vb init --update --files agents/pm.md,templates/feature.md
   ```

4. **Core commands:**
   ```bash
   vb new "Feature Title" label1 label2                 # Create a new feature
   vb move FTR-0001 in-progress --owner fullstack_dev   # Move + claim
   vb validate                                          # Validate features + specs
   vb index                                             # Regenerate features/INDEX.md
   ```

   **IMPORTANT**: `vb move` updates frontmatter (`status`, `updated`, `owner`) automatically — do not edit these fields by hand when transitioning a feature.

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
│   │   ├── pm/              # PM commands (PM-Generate_*.md)
│   │   ├── architect/       # Architect commands (Architect-Generate_*.md)
│   │   ├── backend_dev/     # Backend commands (BackendDeveloper-Generate_*.md)
│   │   ├── frontend_dev/    # Frontend commands (FrontendDeveloper-Generate_*.md)
│   │   ├── fullstack_dev/   # Fullstack commands (FullstackDeveloper-Generate_*.md)
│   │   ├── data_engineer/   # Data Engineer commands (DataEngineer-Generate_*.md)
│   │   ├── devops/          # DevOps commands (DevOps-Generate_*.md)
│   │   ├── security/        # Security commands (Security-Generate_*.md)
│   │   ├── qa/              # QA commands (QA-Generate_*.md)
│   │   └── ux_designer/     # UX Designer commands (UXDesigner-Generate_*.md)
│   └── common/              # Common templates and utilities
│       └── session-handoff.md # Session handoff template
├── scripts/                 # Bootstrap + helper scripts
│   ├── install-vb-cli.sh    # Bootstrap installer for the `vb` CLI
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

1. **Ensure the selected `vb` CLI is installed (required):**
   ```bash
   ./scripts/install-vb-cli.sh --ensure-latest
   vb version
   vb help
   ```
   `--ensure-latest` installs the exact version in `.vb-version`, or resolves the latest release tag when no pin is present. Pass `--allow-sudo` explicitly for system-wide installation.

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
| **Project Manager** | `prompts/agents/pm/` | PM-Generate_Project_Progress_Report (GPP), PM-Generate_Backlog_Grooming (GBG) |
| **Architect** | `prompts/agents/architect/` | Architect-Generate_Architecture_Decision (GAD), Architect-Generate_Architecture_Report (GAR), Architect-Generate_Technical_Debt_Report (GTD) |
| **Backend Developer** | `prompts/agents/backend_dev/` | BackendDeveloper-Generate_API_Documentation (GAD), BackendDeveloper-Generate_API_Endpoint (GAE), BackendDeveloper-Generate_Database_Migration (GDM) |
| **Frontend Developer** | `prompts/agents/frontend_dev/` | FrontendDeveloper-Generate_Accessibility_Audit (GAA), FrontendDeveloper-Generate_Component (GC), FrontendDeveloper-Generate_Component_Story (GCS) |
| **Fullstack Developer** | `prompts/agents/fullstack_dev/` | FullstackDeveloper-Generate_Full_Feature (GFF), FullstackDeveloper-Generate_Integration_Contract (GIC), FullstackDeveloper-Generate_End_to_End_Test (GETE) |
| **Data Engineer** | `prompts/agents/data_engineer/` | DataEngineer-Generate_Data_Pipeline (GDP), DataEngineer-Generate_Metrics_Dashboard (GMD), DataEngineer-Generate_Data_Quality_Check (GDQ), DataEngineer-Generate_Entity_Relationship_Diagram (ERD) |
| **DevOps Engineer** | `prompts/agents/devops/` | DevOps-Generate_Deployment_Checklist (GDC), DevOps-Generate_Deployment_Readiness_Report (GDRR), DevOps-Generate_Incident_Report (GIR) |
| **Security Engineer** | `prompts/agents/security/` | Security-Generate_Security_Audit (GSA), Security-Generate_Security_Review (GSR), Security-Generate_Threat_Model (GTM) |
| **QA Engineer** | `prompts/agents/qa/` | QA-Generate_Bug_Report (GBR), QA-Generate_Test_Coverage_Report (GTCR), QA-Generate_Test_Plan (GTP), QA-Generate_Browser_Automation_Tests (GBAT) |
| **UX Designer** | `prompts/agents/ux_designer/` | UXDesigner-Generate_Design_System_Component (GDS), UXDesigner-Generate_User_Journey (GUJ), UXDesigner-Generate_Wireframe (GWF) |

### Using Agent Commands

When adopting an agent role:

1. **Read your role's README:** Check `prompts/agents/{role}/README.md` for available commands
2. **Display available commands:** Agents should show users what commands they can execute
3. **Execute commands:** Follow the detailed workflow in each command file (e.g., `prompts/agents/pm/PM-Generate_Project_Progress_Report.md`)
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
- name: Install Virtual Board CLI
  run: |
    ./scripts/install-vb-cli.sh --ensure-latest --local
    export PATH="$PWD:$PATH"
    vb version

- name: Validate Features
  run: vb validate

- name: Generate Index
  run: vb index
```

## Troubleshooting

**Common Issues:**

1. **"Feature already owned"** - Another agent is working on it
2. **"Circular dependency"** - Dependencies form a loop
3. **"Invalid transition"** - Not allowed to move to that status
4. **"Dependency not done"** - Required dependencies aren't complete

**Solutions:**

- Check `/features/INDEX.md` for available features
- Run `vb validate` to check frontmatter, dependencies, and folder/status alignment
- Review the agent rules in `/agents/RULES.md`
- Ensure the CLI is properly installed: `vb version`
- To install or enforce the selected release, rerun `./scripts/install-vb-cli.sh --ensure-latest`; it preserves `.vb-version` and verifies the downloaded binary.

## Contributing

When adding new features or modifying the system:

1. Follow the existing patterns
2. Update documentation as needed
3. Run `vb validate` before committing
4. Regenerate the feature index with `vb index`

## Virtual Board CLI

All workflow operations use the [Virtual Board CLI (`vb`)](https://github.com/virtualboard/vb-cli). The CLI provides:

- **Streamlined interface**: Single entry point for all feature workflow operations
- **Schema-backed validation**: Enforces frontmatter, dependencies, and folder/status alignment
- **Lifecycle safety**: Validated moves, ownership claims, and locks
- **Consistent experience**: One canonical implementation across local dev and CI

See the [Quick Start](#quick-start) section above for installation instructions and basic usage.

### Additional CLI Commands

```bash
# Initialize workspace (first time setup)
vb init

# Update workspace to the template release paired with this CLI
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

## Shared workflow contract

`schemas/workflow-contract.json` pins lifecycle order/transitions, terminal states,
role selection examples, CLI commands/flags/exit codes, and doctor capabilities.
Each Go repository checks in the same bytes at `testdata/workflow-contract.json`;
its tests compare the fixture with actual command registration and domain logic.
The contract records hvb's local lifecycle refusals as usage exit 64 and vb's as
transition exit 3; forwarded vb errors retain their documented codes.

After an intentional interface change, update the canonical fixture and all
consumers together:

```bash
python3 tests/workflow-contract.py
bash scripts/sync-workflow-contract.sh ../vb-cli ../herdr-virtualboard
bash scripts/sync-workflow-contract.sh --check ../vb-cli ../herdr-virtualboard
```

The template CI checks schema/role consistency, sync drift refusal, and safe
worktree setup. Consumer tests and real-binary integration must pass before the
matching versions are released. See `herdr-virtualboard/docs/testing.md` for the
50-transition integration matrix.

Releases are immutable tags matching `version.txt`. Release `vb-cli` first;
the template release workflow verifies that `.vb-version` already exists as a
published CLI release, reruns the template contracts, and attaches a versioned
source archive with `checksums.txt`. Release `herdr-virtualboard` after both
exact refs are available.
