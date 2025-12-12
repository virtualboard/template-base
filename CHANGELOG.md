# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-12-12

### Added
- **GBAT (Generate Browser Automation Tests)** command for QA Engineer agent (`prompts/agents/qa/GBAT.md`)
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
- **GBG (Generate Backlog Grooming)** command for Project Manager agent (`prompts/agents/pm/GBG.md`)
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
- Feature specification template (`templates/spec.md`) with comprehensive sections for problem statement, requirements, acceptance criteria, and implementation notes.
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
