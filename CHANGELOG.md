# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2025-11-01
### Added
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
