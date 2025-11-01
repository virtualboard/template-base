# VirtualBoard Feature Spec Workflow

This directory contains the complete implementation of the Feature Spec Workflow system for managing features with multiple AI agents.

## Implementation

The system is built entirely with bash scripts, eliminating the need for Node.js or npm dependencies. This approach provides:

- **Zero dependencies**: No package.json or node_modules required
- **Universal compatibility**: Works on any Unix-like system with bash
- **Fast execution**: Direct shell commands without JavaScript runtime overhead
- **Easy maintenance**: Simple bash scripts that are easy to understand and modify
- **CI/CD friendly**: No build steps or dependency installation required

**CLI Tool Integration:** The system first checks for the `vb` (Virtual Board) CLI tool. If available, agents should use `vb` commands for task management. If not found, agents should fall back to the shell scripts in `.virtualboard/scripts/` or use plain bash commands according to the strategy definition.

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

3. **Use CLI commands:**
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
│   ├── spec.md              # Feature spec template
│   ├── pr-template.md       # Pull request template
│   └── rules.yml            # Agent rules configuration
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
└── scripts/                 # Automation scripts
    ├── ftr-new.sh           # Create new feature
    ├── ftr-move.sh          # Move feature between states
    ├── ftr-validate.sh      # Validate features
    ├── ftr-index.sh         # Generate feature index
    ├── install-vb-cli.sh     # Install Virtual Board CLI tool
    └── frontmatter.schema.json # Frontmatter validation schema
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

2. **Read the agent rules:** `/agents/RULES.md`
3. **Check available work:** Look at `/features/INDEX.md`
4. **Claim a feature:** Move from `backlog` to `in-progress` with your agent ID
   - **CRITICAL**: Update frontmatter `status`, `owner`, and `updated` fields when moving
5. **Work on the feature:** Update implementation notes and links
6. **Hand off for review:** Move to `review` status when complete
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

## Validation

The system enforces several validation rules:

- Frontmatter must match JSON schema
- File location must match frontmatter `status` field (CRITICAL)
- Frontmatter `status` field must be updated when moving files
- Frontmatter `updated` field must be updated when making changes
- Dependencies must be resolved before `in-progress`
- No circular dependencies allowed
- Ownership conflicts are prevented

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
# Upgrade to latest version
vb upgrade
# Or use sudo if installed to system directory:
sudo vb upgrade

# List available features
vb list

# Show feature details
vb show FTR-0001
```
