# VirtualBoard Claude Code Plugin

A comprehensive Feature Spec Workflow system for Claude Code that enables multi-agent collaboration with specialized roles, feature lifecycle management, and powerful agent commands.

## Overview

VirtualBoard transforms how you manage features and collaborate with AI agents in your projects. It provides:

- **10 specialized AI agent roles** (PM, Architect, Backend/Frontend/Fullstack Dev, QA, DevOps, Security, Data Engineer, UX Designer)
- **29+ agent commands** for common development tasks
- **Feature lifecycle management** (backlog → in-progress → review → done)
- **Markdown-first workflow** for easy version control and collaboration
- **Built-in validation** and automation scripts

## Features

### Multi-Agent System

Each agent role comes with:
- **Specialized prompts** defining role responsibilities and workflows
- **Custom commands** tailored to that role's tasks
- **Clear rules of engagement** for collaboration

**Available Agents:**
- **Project Manager** - Sprint planning, progress reports, backlog grooming
- **System Architect** - Architecture decisions, reviews, technical debt tracking
- **Backend Developer** - API endpoints, database migrations, documentation
- **Frontend Developer** - Components, accessibility, Storybook stories
- **Fullstack Developer** - Full features, integration contracts, E2E tests
- **QA Engineer** - Test plans, bug reports, coverage analysis
- **DevOps Engineer** - Deployment checklists, incident response, readiness checks
- **Security Engineer** - Security audits, threat models, reviews
- **Data Engineer** - Data pipelines, metrics dashboards, data quality, ERDs
- **UX/Product Designer** - User journeys, wireframes, design systems

### Feature Lifecycle Management

Features move through a clear lifecycle:

```
backlog → in-progress → review → done
              ↓
           blocked (when dependencies aren't met)
```

Each feature is a Markdown file with:
- Structured frontmatter (validated against JSON schema)
- Problem statement and requirements
- Acceptance criteria
- Implementation notes and links
- Owner tracking

### Agent Commands

29+ specialized commands across all roles:

**Project Manager Commands:**
- `GPP` - Generate Project Progress Report
- `GBG` - Generate Backlog Grooming Report

**Architect Commands:**
- `GAD` - Generate Architecture Diagram
- `GAR` - Generate Architecture Review
- `GTD` - Generate Technical Debt Analysis

**Backend Developer Commands:**
- `GAD` - Generate API Documentation
- `GAE` - Generate API Endpoint
- `GDM` - Generate Data Migration

**Frontend Developer Commands:**
- `GAA` - Generate Accessibility Audit
- `GC` - Generate Component
- `GCS` - Generate Component Storybook

**Fullstack Developer Commands:**
- `GFF` - Generate Full Feature
- `GIC` - Generate Integration Contract
- `GETE` - Generate End-to-End Test

**QA Engineer Commands:**
- `GBR` - Generate Bug Report
- `GTCR` - Generate Test Coverage Report
- `GTP` - Generate Test Plan

**DevOps Commands:**
- `GDC` - Generate Deployment Checklist
- `GDRR` - Generate Deployment Readiness Report
- `GIR` - Generate Incident Report

**Security Commands:**
- `GSA` - Generate Security Audit
- `GSR` - Generate Security Review
- `GTM` - Generate Threat Model

**Data Engineer Commands:**
- `GDP` - Generate Data Pipeline
- `GMD` - Generate Metrics Dashboard
- `GDQ` - Generate Data Quality Report
- `ERD` - Generate Entity Relationship Diagram

**UX Designer Commands:**
- `GDS` - Generate Design System Component
- `GUJ` - Generate User Journey Map
- `GWF` - Generate Wireframe

## Installation

### From GitHub (Recommended)

1. Clone or install the plugin:
   ```bash
   claude plugin marketplace add virtualboard/template-base
   claude plugin install virtualboard
   ```

### Manual Installation

1. Clone the repository to your plugins directory
2. Run validation:
   ```bash
   claude plugin validate
   ```

## Usage

### Quick Start

1. **Initialize VirtualBoard in your project:**
   ```bash
   # Copy the VirtualBoard structure to your project
   cp -r /path/to/template-base/{features,agents,prompts,scripts,templates,schemas} .virtualboard
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x scripts/*.sh
   ```

3. **Start using agents:**
   ```bash
   # In Claude Code, agents will automatically detect the VirtualBoard structure
   # Just ask Claude to adopt a role:
   "Adopt the Project Manager agent role and review the backlog"
   ```

### Working with Features

**Create a new feature:**
```bash
./scripts/ftr-new.sh "User Authentication" security backend
```

**Move feature to in-progress:**
```bash
./scripts/ftr-move.sh FTR-0001 in-progress fullstack_dev
```

**Validate all features:**
```bash
./scripts/ftr-validate.sh
```

**Generate feature index:**
```bash
./scripts/ftr-index.sh
```

### Using Agent Commands

When working with an agent, you can trigger specialized commands:

```
# As Project Manager
"GPP - Generate project progress report"

# As Backend Developer
"GAE - Create a new API endpoint for user registration"

# As Frontend Developer
"GC - Generate a UserProfile component"
```

Each command follows a structured workflow and produces standardized output.

## Directory Structure

```
your-project/
├── features/                 # Feature specifications
│   ├── backlog/             # Unassigned features
│   ├── in-progress/         # Features being worked on
│   ├── blocked/             # Features waiting on dependencies
│   ├── review/              # Features ready for review
│   ├── done/                # Completed features
│   └── INDEX.md             # Auto-generated feature index
├── agents/                  # Agent role definitions
│   ├── pm.md
│   ├── architect.md
│   ├── backend_dev.md
│   ├── frontend_dev.md
│   ├── fullstack_dev.md
│   ├── qa.md
│   ├── devops_engineer.md
│   ├── security_compliance_engineer.md
│   ├── data_analytics_engineer.md
│   ├── ux_product_designer.md
│   ├── AGENTS.md            # Agent system overview
│   └── RULES.md             # Shared rules of engagement
├── prompts/                 # Agent commands
│   ├── agents/              # Role-specific commands
│   │   ├── pm/
│   │   ├── architect/
│   │   ├── backend_dev/
│   │   ├── frontend_dev/
│   │   ├── fullstack_dev/
│   │   ├── qa/
│   │   ├── devops/
│   │   ├── security/
│   │   ├── data_engineer/
│   │   └── ux_designer/
│   ├── common/              # Shared templates
│   └── AGENTS.md            # Commands overview
├── scripts/                 # Automation scripts
│   ├── ftr-new.sh
│   ├── ftr-move.sh
│   ├── ftr-validate.sh
│   ├── ftr-index.sh
│   └── install-vb-cli.sh
├── templates/               # Templates
│   ├── spec.md              # Feature spec template
│   ├── pr-template.md       # Pull request template
│   └── rules.yml            # Agent rules configuration
└── schemas/                 # Validation schemas
    └── frontmatter.schema.json
```

## Virtual Board CLI

For enhanced task management, install the [Virtual Board CLI](https://github.com/virtualboard/vb-cli):

```bash
./scripts/install-vb-cli.sh
```

The CLI provides streamlined commands:
```bash
vb new "Feature Title" label1 label2
vb move FTR-0001 in-progress --owner fullstack_dev
vb validate
vb index
vb upgrade
```

## Benefits

### For Teams
- **Clear responsibilities** - Each agent knows their role
- **Parallel work** - Multiple agents can work on different features simultaneously
- **Consistent workflow** - Standardized processes across all features
- **Automated validation** - Catch issues early with built-in validation

### For AI Collaboration
- **Deterministic** - Clear rules that AI agents can follow reliably
- **Context-aware** - Agents understand the full project structure
- **Specialized** - Each agent has focused expertise
- **Traceable** - All changes are tracked through feature files

### For Development
- **Markdown-first** - Easy to version control and review
- **Automation-ready** - Scripts for common operations
- **CI/CD friendly** - Validation hooks for continuous integration
- **Zero dependencies** - Pure bash scripts, no Node.js required

## Configuration

### Customizing Agent Roles

Edit agent files in `agents/` to customize:
- Role responsibilities
- Communication style
- Workflows and processes
- Tool preferences

### Adding New Commands

1. Create a new command file in `prompts/agents/{role}/`
2. Follow the command structure template
3. Update the role's README to list the new command
4. Test with validation scripts

### Modifying Feature Template

Edit `templates/spec.md` to customize:
- Frontmatter fields
- Section structure
- Acceptance criteria format
- Implementation notes

## Validation

The system includes comprehensive validation:

- **Schema validation** - Frontmatter must match JSON schema
- **Location validation** - File location must match status field
- **Dependency validation** - No circular dependencies
- **Ownership validation** - Prevent conflicts

Run validation:
```bash
# Using CLI
vb validate

# Using scripts
./scripts/ftr-validate.sh
```

## Integration

### CI/CD Integration

Add to your CI pipeline:

```yaml
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

### Pre-commit Hooks

Add to `.pre-commit-config.yaml`:

```yaml
- repo: local
  hooks:
    - id: validate-features
      name: Validate feature specs
      entry: ./scripts/ftr-validate.sh
      language: script
      pass_filenames: false
```

## Examples

### Sample Features Included

- **FTR-0001** (backlog) - User Authentication
- **FTR-0002** (in-progress) - Dashboard Widgets
- **FTR-0003** (blocked) - External API Integration
- **FTR-0004** (review) - Notification System
- **FTR-0005** (done) - Basic Application Layout

### Sample Workflows

**Sprint Planning Workflow:**
1. PM agent adopts role: "Adopt PM role"
2. Reviews backlog: "Show me available features"
3. Generates progress report: "GPP"
4. Grooms backlog: "GBG"

**Feature Development Workflow:**
1. Developer claims feature: `vb move FTR-0001 in-progress backend_dev`
2. Architect reviews design: "Adopt architect role and GAR for FTR-0001"
3. Backend dev implements: "Adopt backend_dev role and GAE for user login"
4. QA creates test plan: "Adopt qa role and GTP for FTR-0001"
5. Move to review: `vb move FTR-0001 review`

## Troubleshooting

### "Feature already owned"

- Another agent is working on it
- Check `/features/INDEX.md` for ownership

### "Circular dependency"

- Dependencies form a loop
- Review feature dependencies in frontmatter

### "Invalid transition"

- Not allowed to move to that status
- Check lifecycle rules in `agents/RULES.md`

### Scripts not executable

- Run: `chmod +x scripts/*.sh`

## Contributing

Contributions welcome! Please:
1. Follow existing patterns
2. Update documentation
3. Test with validation scripts
4. Update feature index

## License

MIT

## Support

- GitHub Issues: <https://github.com/virtualboard/template-base/issues>
- Documentation: See `/docs` directory
- Examples: See `/features` directory

## Version

Current version: 0.1.0

See CHANGELOG.md for version history.
