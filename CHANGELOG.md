# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.0] - 2026-04-28

### Added
- **Branded HTML report templates** — every report-generating agent command can now optionally produce an Astucia AI™ branded HTML companion file alongside the Markdown report. Opt-in via `--html` (or "as HTML" / "branded HTML" / `format: html`); Markdown remains the default and is always written first.
- **`templates/reports/`** directory with 21 templates covering 17 required (`R`) report commands plus 4 optional (`S+R`) commands. Includes a foundation of partials (`_partials/head.html`, `topnav.html`, `footer.html`, `back-to-top.html`, `astucia-logo.b64.txt`), a base skeleton (`_base/report.html`), an author guide (`templates/reports/README.md`), and a filled-in reference example for every template under `templates/reports/examples/`.
- **Per-template HTML files** (`templates/reports/html/`):
  - PM: `pm-progress-report.html` (GPP), `pm-backlog-grooming.html` (GBG)
  - Architect: `architect-architecture-report.html` (GAR), `architect-tech-debt.html` (GTD), `architect-adr.html` (GAD, optional)
  - QA: `qa-test-plan.html` (GTP), `qa-test-coverage.html` (GTCR), `qa-bug-report.html` (GBR), `qa-browser-test-summary.html` (GBAT, optional, wraps Playwright reporter)
  - Security: `security-audit.html` (GSA), `security-review.html` (GSR), `security-threat-model.html` (GTM)
  - DevOps: `devops-deployment-readiness.html` (GDRR), `devops-incident-report.html` (GIR), `devops-deployment-checklist.html` (GDC, optional)
  - Data Engineer: `data-quality-report.html` (GDQ), `data-erd.html` (ERD), `data-pipeline-doc.html` (GDP, optional)
  - UX Designer: `ux-user-journey.html` (GUJ), `ux-wireframe.html` (GWF), `ux-design-system.html` (GDS)
- **Mustache-style placeholder syntax** for template substitution — `{{NAME}}` for scalars, `{{#LIST}}…{{/LIST}}` for repeated blocks, `{{INCLUDE: _partials/<name>.html}}` for partial inlining. No runtime, no build step, no new dependency — agents do plain text substitution.
- **Brand parameterization** via `{{BRAND_NAME}}`, `{{BRAND_TAGLINE}}`, `{{BRAND_LOGO_DATAURI}}` placeholders (defaulted to Astucia values) so downstream forks can re-skin without forking the templates.

### Changed
- **All 21 report-generating agent command files** updated with an "Optional: Generate Branded HTML Report" section enumerating per-template scalar and list placeholders, the render workflow, and the verification step (grep for `{{` in output).
- **All 8 role README files** (`pm`, `architect`, `qa`, `security`, `devops`, `data_engineer`, `ux_designer`) updated with a one-line note on the `--html` opt-in.
- Bumped version from 0.6.0 to 0.7.0 across `version.txt`, `.claude-plugin/plugin.json`, and `.claude-plugin/marketplace.json`.

## [0.6.0] - 2026-04-11

### Added
- **`scripts/install-vb-cli.sh --ensure-latest`** — non-interactive bootstrap mode for agents and CI. Installs the CLI when missing, compares the installed version to the latest GitHub release, runs `vb upgrade` when outdated (with `sudo vb upgrade` as a fallback), and exits cleanly when already on the latest release. Also adds `--yes`/`-y` for non-interactive fresh installs.

### Changed
- **The `vb` CLI is now required** for all feature workflow operations. Agents and CI must run `./scripts/install-vb-cli.sh --ensure-latest` before invoking any `vb` command — no shell-script fallbacks remain.
- Documentation (`CLAUDE.md`, `AGENTS.md`, `README.md`, `.claude-plugin/README.md`, `skills/work-on/SKILL.md`, `docs/.opencode/skill/virtualboard/SKILL.md`, `templates/specs/README.md`, `prompts/agents/pm/PM-Generate_Backlog_Grooming.md`, `docs/workflow.html`, `docs/features.html`, `docs/index.html`) updated to reflect the CLI-required model and the `--ensure-latest` bootstrap pattern.
- Bumped version from 0.5.1 to 0.6.0 across `version.txt`, `.claude-plugin/plugin.json`, and `.claude-plugin/marketplace.json`.

### Removed
- `scripts/ftr-new.sh`, `scripts/ftr-move.sh`, `scripts/ftr-validate.sh`, `scripts/ftr-index.sh` — replaced by `vb new`, `vb move`, `vb validate`, `vb index`. `scripts/install-vb-cli.sh` and `scripts/worktree-setup.sh` remain as the installer bootstrap and `/work-on` skill helper respectively.

## [0.5.1] - 2026-02-26

### Changed
- **Worktree path structure now includes repository name** to prevent feature ID collisions across projects. Path changed from `$WORKTREE_BASE/FTR-XXXX` to `$WORKTREE_BASE/<repo-name>/FTR-XXXX` (e.g., `/tmp/virtualboard-worktrees/my-project/FTR-0042`).
- Updated `scripts/worktree-setup.sh` to detect repository name from git root directory
- Updated `/work-on` skill documentation (`skills/work-on/SKILL.md`, `skills/work-on/config.md`) with new path structure

## [0.5.0] - 2026-02-04

### Changed
- **Renamed all 31 agent command files** to collision-free, descriptive names using `{AgentName}-{Command_Name}.md` pattern (e.g., `GPP.md` → `PM-Generate_Project_Progress_Report.md`). Short trigger codes (GPP, GAD, etc.) remain valid aliases.
- Updated `.claude-plugin/plugin.json` with all 31 new command file paths
- Updated all 10 agent `README.md` files (`pm`, `architect`, `backend_dev`, `frontend_dev`, `fullstack_dev`, `qa`, `devops`, `security`, `data_engineer`, `ux_designer`) with new file references
- Updated cross-reference in `BackendDeveloper-Generate_API_Documentation.md` to reference new Architect command name
- Removed GAD disambiguation note from `backend_dev/README.md` (collision resolved by unique filenames)
- Updated documentation across `AGENTS.md`, `README.md`, `CLAUDE.md`, `prompts/AGENTS.md`, `agents/RULES.md`, and `.claude-plugin/README.md` with new naming pattern and file paths
- Bumped version from 0.4.0 to 0.5.0

## [0.4.0] - 2026-01-14

### Added
- **`/work-on` skill** for Claude Code plugin (`skills/work-on/SKILL.md`)
  - Work on VirtualBoard features in isolated git worktrees
  - Automatic branch creation with naming convention `feature/FTR-XXXX/feature-slug`
  - Resume support for existing branches with progress detection
  - Configurable session modes: interactive, semi-autonomous, autonomous
  - Automatic commit footer: `FTR-XXXX implemented using the @virtualboard /work-on skill`
  - Post-push actions: push only, create PR, or full cleanup
  - Configuration via environment variables or command-line options
- **`scripts/worktree-setup.sh`** helper script for git worktree management
  - Creates and manages git worktrees for feature development
  - Detects existing branches (local and remote)
  - Reports worktree status including commits ahead and uncommitted changes
- **Skills directory** (`skills/`) for Claude Code plugin auto-discovery
  - `skills/work-on/SKILL.md` - Main skill definition
  - `skills/work-on/config.md` - Configuration reference documentation

### Changed
- Updated documentation (README.md, CLAUDE.md, AGENTS.md) with `/work-on` skill usage
- Updated HTML documentation with new skill information
- Bumped version from 0.3.0 to 0.4.0

## [0.3.0] - 2025-12-16

### Added
- **System specification catalog** in `templates/specs/` with eight reusable templates (tech stack, local development, hosting & infrastructure, CI/CD pipeline, database schema, caching & performance, security & compliance, observability & incident response).
- `schemas/system-spec.schema.json` describing the shared frontmatter contract for those templates.
- Validation support in `scripts/ftr-validate.sh` so `vb validate` now checks system specs alongside feature files.

### Changed
- Updated `README.md`, `AGENTS.md`, and `templates/specs/README.md` with guidance on using and validating the new templates.
- Refreshed docs (`docs/index.html`, `docs/features.html`, `docs/workflow.html`) to highlight the specs catalog and schematized validation.
- Bumped version from 0.2.0 to 0.3.0.

## [0.2.0] - 2025-12-12

### Added
- **GBAT (Generate Browser Automation Tests)** command for QA Engineer agent (`prompts/agents/qa/QA-Generate_Browser_Automation_Tests.md`)
  - Comprehensive 4-phase browser automation testing workflow using Playwright
  - Phase 1: Test case generation in markdown format (`.virtualboard/docs/browser-test-cases/`)
  - Phase 2: Playwright automation script generation with Page Object Model pattern
  - Phase 3: Test execution across multiple browsers (Chrome, Firefox, Safari)
  - Phase 4: Detailed test execution reports in markdown and HTML formats
  - Support for test directories, browser selection, and report customization via user prompts
  - Integration with Page Object Model for maintainable test automation
  - Accessibility testing integration in browser test cases
  - Cross-browser compatibility validation
  - Screenshot and video capture for failed tests
  - Playwright trace generation for debugging
  - Test utilities and helper functions generation
  - Comprehensive example documentation with real-world scenarios
- **CLAUDE.md** file providing comprehensive repository guidance for Claude Code
  - Agent-first design pattern documentation
  - Feature lifecycle and workflow overview
  - Complete directory structure explanation
  - Common commands for both Virtual Board CLI and shell scripts
  - Integration points for Cursor IDE and Claude Code plugin
  - Troubleshooting guide and quick reference
- Examples directory for QA commands (`prompts/agents/qa/examples/`)
  - `GBAT-example.md` - Complete walkthrough of GBAT command with sample inputs/outputs
  - `README.md` - Guide for using and contributing examples

### Changed
- Updated `prompts/agents/qa/README.md` to include GBAT command with detailed description
- Updated `prompts/AGENTS.md` to reflect browser automation testing capability
- Updated `.claude-plugin/README.md` to include GBAT in QA commands list (30+ commands total)
- Updated `.claude-plugin/plugin.json` to register GBAT command
- Bumped version from 0.1.1 to 0.2.0

### Documentation
- Added comprehensive Playwright test automation workflow documentation
- Documented four-phase testing approach (generate, automate, execute, report)
- Included Page Object Model pattern examples
- Added test data management and selector strategy documentation
- Documented integration with existing QA commands (GTP, GBR, GTCR)

## [0.1.1] - 2025-12-03

### Added
- **Cursor IDE Integration** documentation in README.md
  - Project-level installation instructions for `.cursor` folder
  - Global installation instructions with Cursor Settings configuration
  - Documentation for `.cursor/rules/virtualboard.mdc` file
- **Cursor IDE Integration** section in `docs/index.html`
  - Visual two-column grid layout for installation options
  - Step-by-step instructions for both project-level and global setup
  - Highlighted notes about rule precedence

### Changed
- Updated README.md with comprehensive Cursor IDE integration guide
- Updated `docs/index.html` with Cursor integration section

## [0.1.0] - 2025-11-04

### Added
- **GBG (Generate Backlog Grooming)** command for Project Manager agent (`prompts/agents/pm/PM-Generate_Backlog_Grooming.md`)
  - Comprehensive backlog refinement session with interactive decision-making
  - Implementation status assessment (fully/partially/not implemented)
  - Automated relevance analysis based on codebase evolution
  - Spec quality validation and dependency hygiene checks
  - Prioritization recommendations with quick wins identification
  - Comprehensive grooming report generation with health scoring
  - Interactive prompts for user decisions on each backlog feature
  - Support for splitting features and moving completed work to review/done

### Changed
- Updated `prompts/agents/pm/README.md` to include GBG command
- Updated `prompts/AGENTS.md` to reflect backlog grooming capability
- Updated `docs/agents.html` to display GBG command in PM section
- Bumped version from 0.0.1 to 0.1.0

## [0.0.1] - 2025-11-01

### Initial Release
- VirtualBoard markdown-first feature workflow system for managing features with multiple AI agents.
- Lifecycle-managed feature directories: `backlog/`, `blocked/`, `in-progress/`, `review/`, and `done/`.
- Auto-generated feature index (`features/INDEX.md`) tracking all features across lifecycle stages.
- Feature specification template (`templates/feature.md`) with comprehensive sections for problem statement, requirements, acceptance criteria, and implementation notes.
- Pull request template (`templates/pr-template.md`) aligned with feature spec workflow.
- Machine-readable agent rules configuration (`templates/rules.yml`) for validation parameters, state transitions, and dependencies.
- Frontmatter JSON Schema validation (`schemas/frontmatter.schema.json`) for feature metadata consistency.
- Bash automation scripts in `scripts/`:
  - `ftr-new.sh` - Create new feature specifications from template
  - `ftr-move.sh` - Move features across lifecycle with validation checks
  - `ftr-validate.sh` - Validate feature specs, frontmatter, dependencies, and folder-status alignment
  - `ftr-index.sh` - Generate comprehensive feature index
  - `install-vb-cli.sh` - Automated installer for Virtual Board CLI tool with OS/architecture detection
- Comprehensive agent documentation system:
  - `agents/AGENTS.md` - Catalog of agent prompts and responsibilities
  - `agents/RULES.md` - Human-readable rules of engagement for agents
  - Role-specific agent prompts: Project Manager, System Architect, UX/Product Designer, Backend Developer, Frontend Developer, Fullstack Developer, DevOps Engineer, Security & Compliance Engineer, Data & Analytics Engineer, and QA Engineer
- Agent prompt system in `prompts/`:
  - `prompts/AGENTS.md` - Agent catalog (mirrors agents/AGENTS.md)
  - Agent-specific prompt files in `prompts/agents/` for consistent role definitions
  - Common prompt utilities in `prompts/common/` including session handoff templates
- Virtual Board CLI tool integration with automatic fallback to bash scripts.
- Repository structure documentation:
  - `README.md` - Quick start guide, directory structure, and usage instructions
  - `AGENTS.md` - Complete feature spec workflow strategy and operating guide
  - `version.txt` - Version tracking
- GitHub Pages documentation in `docs/`:
  - HTML documentation for features, agents, workflow, and index pages
  - Responsive documentation site for easy reference
- Reports directory (`reports/`) for Virtual Board CLI generated reports.
- Validation system enforcing:
  - Frontmatter schema compliance
  - Folder-status alignment
  - Dependency resolution checks
  - Circular dependency detection
  - Ownership conflict prevention
- State transition rules with allowed transitions between lifecycle stages.
- Dependency management requiring completed dependencies before moving to `in-progress`.
- Feature naming conventions with FTR-#### identifiers and kebab-case descriptions.
- Git workflow conventions with feature branches, commit prefixes, and PR templates.
