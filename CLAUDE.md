# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VirtualBoard is a Markdown-first feature specification and workflow management system for multi-agent AI collaboration. It manages software development features through their lifecycle using specialized AI agent roles. Built entirely with bash scripts — zero dependencies (no Node.js/npm required except for Playwright tests).

## Agent-First Design (CRITICAL)

Before starting ANY task, you MUST:

1. Read `agents/AGENTS.md` for role selection guidelines
2. Determine the appropriate agent role based on task type (see table in `agents/AGENTS.md`)
3. Read the specific role file (e.g., `agents/frontend_dev.md`)
4. Announce your adopted role (e.g., "I am working as a Frontend Developer agent")
5. Load agent commands from `prompts/agents/{role}/README.md`
6. Follow `agents/RULES.md` for shared guardrails

Agent role files live in `agents/`. Agent command definitions live in `prompts/agents/{role}/`. Command files use the naming pattern `{AgentName}-{Command_Name}.md` (e.g., `PM-Generate_Project_Progress_Report.md`). Each command also has a short trigger code alias (e.g., `GPP`, `GAD`, `GTP`, `GBAT`) and produces output in `.virtualboard/` subdirectories (reports/, architecture/, testing/, etc.).

## Feature Lifecycle

```
backlog → in-progress → review → done
              ↓
           blocked
```

Features are Markdown files in `features/{status}/` with YAML frontmatter. The `done → any` transition is forbidden.

**CRITICAL**: When moving a feature file between folders, you MUST update ALL THREE frontmatter fields:
- `status` — must match the destination folder name
- `updated` — set to today's date (YYYY-MM-DD)
- `owner` — set when claiming, clear when releasing

### Frontmatter Schema

Required fields: `id` (FTR-XXXX pattern), `title`, `status`, `created`, `updated`. Optional: `owner`, `priority` (P0-P3), `complexity` (XS/S/M/L/XL), `labels` (kebab-case array), `dependencies` (FTR-XXXX array), `epic` (EP-XXXX), `risk_notes`. See `schemas/frontmatter.schema.json` for full validation.

Dependencies must be `done` before a feature can move to `in-progress`. No circular dependencies allowed.

## Commands

Check for CLI first: `command -v vb &> /dev/null`

### VirtualBoard CLI (`vb`) — preferred

```bash
vb new "Feature Title" label1 label2    # Create feature in backlog
vb move FTR-0001 in-progress --owner fullstack_dev  # Move + claim
vb validate                              # Validate all features + specs
vb index                                 # Regenerate features/INDEX.md
vb list                                  # List features
vb show FTR-0001                         # Show feature details
vb init                                  # Initialize workspace
vb init --update                         # Update to latest template
vb upgrade                               # Upgrade CLI
```

### Shell Scripts (fallback)

```bash
chmod +x scripts/*.sh                    # First-time setup
./scripts/ftr-new.sh "Title" label1      # Create feature
./scripts/ftr-move.sh FTR-0001 in-progress fullstack_dev  # Move feature
./scripts/ftr-validate.sh                # Validate features
./scripts/ftr-index.sh                   # Generate INDEX.md
./scripts/install-vb-cli.sh              # Install CLI
./scripts/worktree-setup.sh <id> <slug>  # Setup git worktree
```

**Always run validation before committing:** `vb validate || ./scripts/ftr-validate.sh`

## Key Files

| File | Purpose |
|------|---------|
| `agents/AGENTS.md` | Role selection guide with task-type-to-role mapping |
| `agents/RULES.md` | Universal agent guardrails and state transition rules |
| `agents/{role}.md` | Individual agent identity and workflow definitions |
| `prompts/agents/{role}/README.md` | Agent-specific commands and trigger codes |
| `prompts/common/session-handoff.md` | Template for session handoffs between agents |
| `templates/feature.md` | Feature spec template (copied by `ftr-new.sh`) |
| `templates/pr-template.md` | PR template |
| `schemas/frontmatter.schema.json` | Feature frontmatter JSON Schema validation |
| `schemas/system-spec.schema.json` | System spec frontmatter validation |
| `features/INDEX.md` | Auto-generated — never edit manually |
| `docs/DESIGN_SYSTEM.md` | Web design system (colors, typography, components) |

## System Specifications

`templates/specs/` contains reusable system blueprint templates (tech-stack, database-schema, ci-cd-pipeline, etc.). Copy to `specs/` for your project. These are validated against `schemas/system-spec.schema.json` with required fields: `spec_type`, `title`, `status` (draft/approved/deprecated), `last_updated`, `applicability`.

## `/work-on` Skill

Claude Code skill for feature development in isolated git worktrees:

```bash
/work-on FTR-0042                    # Interactive mode
/work-on FTR-0042 --autonomous       # No clarifying questions
/work-on FTR-0042 --create-pr        # Create draft PR after push
/work-on FTR-0042 --cleanup          # Remove worktree after push+PR
```

Creates branch `feature/FTR-XXXX/<feature-slug>`. Commit footer: `FTR-XXXX implemented using the @virtualboard /work-on skill`. Config via env vars: `VIRTUALBOARD_WORKTREE_PATH`, `VIRTUALBOARD_BASE_BRANCH`, `VIRTUALBOARD_POST_PUSH`, `VIRTUALBOARD_SESSION_MODE`.

## Immutable Rules

- Never change a feature's `id` or filename
- Never edit `features/INDEX.md` manually
- Never move a file without updating frontmatter `status`, `owner`, and `updated`
- Only one agent can own a feature at a time
- Reference feature IDs (FTR-####) in all commits and PRs
