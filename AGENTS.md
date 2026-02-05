# Feature Spec Workflow (Markdown‑first): Strategy & Operating Guide

> A lightweight, automation‑ready system that lets multiple agents work concurrently on different features without stepping on each other.

---

## 1) Purpose & Outcomes

**Goal:** Standardize how features are proposed, specified, implemented, reviewed, and archived using Markdown files so that humans and AI agents (e.g., Cursor) can collaborate deterministically.

**Outcomes:**

- Clear single source of truth per feature
- Predictable lifecycle (backlog → in‑progress → review → done)
- Minimal merge conflicts; high parallelism across features
- Automation hooks for validation, indexing, and guardrails

**Implementation:** The system uses pure bash scripts for all automation, eliminating Node.js/npm dependencies and providing universal compatibility across Unix-like systems.

**CLI Tool Integration:** The system first checks for the `vb` (Virtual Board) CLI tool. If available, agents should use `vb` commands for task management. If not found, agents should fall back to the shell scripts in `.virtualboard/scripts/` or use plain bash commands according to the strategy definition.

---

## 2) Scope & Definitions

- **Feature (FTR):** A discrete change delivering user-visible value. Tracked as one Markdown file.
- **Spec:** The Markdown file describing problem, requirements, acceptance criteria, and implementation notes.
- **System Spec:** Cross-cutting blueprint (tech stack, CI/CD, security, etc.) that informs multiple features. Templates are in `/templates/specs/`; copy to `/specs/` for your project.
- **Owner:** The current human/agent responsible for a feature's next state transition.
- **Agent:** Any automated actor (e.g., Cursor, CI bot) executing rules defined here.
- **FTR ID:** Stable identifier `FTR-####` (e.g., `FTR-0123`).
- **Status:** One of `backlog | in-progress | review | done` (mirrored by the folder location).

---

## 3) Core Principles

1. **Markdown-first:** Everything important lives in Markdown; easy to diff, parse, and index.
2. **One file per feature:** A feature has exactly one spec that moves through folders; no forks/copies.
3. **Folder = status:** The folder location is the source of truth for status; frontmatter mirrors it.
4. **Deterministic conventions:** Names, frontmatter schema, and transitions are strict to enable agents.
5. **Automation-ready:** Simple rules that are trivially validated by CI and followed by agents.
6. **Human override:** Humans can always intervene; bots must defer to owners and locks.

---

## 4) Repository Layout

```
/features
  /backlog           # features not yet started
  /blocked           # features blocked by dependencies or external factors
  /in-progress       # features currently being worked on
  /review            # features awaiting review/approval
  /done              # completed features
  INDEX.md           # auto-generated, do not edit
/templates
  feature.md         # canonical feature spec template
  pr-template.md     # pull request template
  rules.yml          # machine-readable agent rules & validation parameters
  /specs             # system specification templates
    README.md        # catalog of system blueprint templates
    tech-stack.md    # languages, runtimes, integrations
    local-development.md
    hosting-and-infrastructure.md
    ci-cd-pipeline.md
    database-schema.md
    caching-and-performance.md
    security-and-compliance.md
    observability-and-incident-response.md
/specs               # project-specific system specifications
                     # (copy templates here for your project)
/agents
  AGENTS.md          # catalog of agent prompts and responsibilities
  RULES.md           # human-readable rules of engagement for agents
  pm.md              # project manager prompt
  architect.md       # system architect prompt
  ux_product_designer.md # UX/product designer prompt
  backend_dev.md     # backend developer prompt
  frontend_dev.md    # frontend developer prompt
  fullstack_dev.md   # fullstack developer prompt
  devops_engineer.md # DevOps & reliability engineer prompt
  security_compliance_engineer.md # security & compliance engineer prompt
  data_analytics_engineer.md # data & analytics engineer prompt
  qa.md              # QA engineer prompt
/prompts
  AGENTS.md          # catalog of agent commands system (commands overview)
  /agents            # agent-specific command files organized by role
    /pm              # Project Manager commands
      README.md      # PM command catalog
      PM-Generate_Project_Progress_Report.md
      PM-Generate_Backlog_Grooming.md
    /architect       # Architect commands
      README.md      # Architect command catalog
      Architect-Generate_Architecture_Decision.md
      Architect-Generate_Architecture_Report.md
      Architect-Generate_Technical_Debt_Report.md
    /backend_dev     # Backend Developer commands
      README.md      # Backend command catalog
      BackendDeveloper-Generate_API_Documentation.md
      BackendDeveloper-Generate_API_Endpoint.md
      BackendDeveloper-Generate_Database_Migration.md
    /frontend_dev    # Frontend Developer commands
      README.md      # Frontend command catalog
      FrontendDeveloper-Generate_Accessibility_Audit.md
      FrontendDeveloper-Generate_Component.md
      FrontendDeveloper-Generate_Component_Story.md
    /fullstack_dev   # Fullstack Developer commands
      README.md      # Fullstack command catalog
      FullstackDeveloper-Generate_Full_Feature.md
      FullstackDeveloper-Generate_Integration_Contract.md
      FullstackDeveloper-Generate_End_to_End_Test.md
    /data_engineer   # Data Engineer commands
      README.md      # Data Engineer command catalog
      DataEngineer-Generate_Data_Pipeline.md
      DataEngineer-Generate_Metrics_Dashboard.md
      DataEngineer-Generate_Data_Quality_Check.md
      DataEngineer-Generate_Entity_Relationship_Diagram.md
    /devops          # DevOps Engineer commands
      README.md      # DevOps command catalog
      DevOps-Generate_Deployment_Checklist.md
      DevOps-Generate_Deployment_Readiness_Report.md
      DevOps-Generate_Incident_Report.md
    /security        # Security Engineer commands
      README.md      # Security command catalog
      Security-Generate_Security_Audit.md
      Security-Generate_Security_Review.md
      Security-Generate_Threat_Model.md
    /qa              # QA Engineer commands
      README.md      # QA command catalog
      QA-Generate_Bug_Report.md
      QA-Generate_Test_Coverage_Report.md
      QA-Generate_Test_Plan.md
      QA-Generate_Browser_Automation_Tests.md
    /ux_designer     # UX Designer commands
      README.md      # UX Designer command catalog
      UXDesigner-Generate_Design_System_Component.md
      UXDesigner-Generate_User_Journey.md
      UXDesigner-Generate_Wireframe.md
  /common            # common prompt templates and utilities
    session-handoff.md
/scripts
  ftr-new.sh         # create a new feature spec from template
  ftr-move.sh        # move feature across lifecycle w/ checks
  ftr-index.sh       # generate /features/INDEX.md
  ftr-validate.sh    # validate schema, status-folder match, deps, links
  install-vb-cli.sh  # install Virtual Board CLI tool
  worktree-setup.sh  # git worktree setup for /work-on skill
/skills              # Claude Code plugin skills
  /work-on           # /work-on skill for feature development
    SKILL.md         # skill definition
    config.md        # configuration reference
/schemas
  frontmatter.schema.json # frontmatter validation schema
  system-spec.schema.json # system blueprint schema
/reports             # where vb creates reports
AGENTS.md            # this file - feature spec workflow guide
CHANGELOG.md         # project changelog
README.md            # project README
version.txt          # version tracking
```

> **Optional**: `/locks` for ephemeral lock files (see §10), `/archive` for long‑term storage of `done` after N days.

---

## 5) Naming Conventions

**File:** `FTR-####-short-description.md`

- `####` is a zero‑padded integer (e.g., `0001`).
- `short-description` is kebab‑case, ≤ 6 words (e.g., `search-bar`, `user-authentication`).

**Branch:** `feat/FTR-####-short-description`

**Commit prefix:** `FTR-####:` (e.g., `FTR-0123: implement password reset flow`).

---

## 6) Frontmatter Schema

Every spec starts with YAML frontmatter (machine‑parsable):

```yaml
id: FTR-0123
title: User Authentication
status: backlog # backlog | in-progress | review | done
owner: unassigned # set to human/agent handle when in-progress
priority: P2 # P0 | P1 | P2 | P3
complexity: M # XS | S | M | L | XL
created: 2025-09-16
updated: 2025-09-16
labels: [auth, frontend, security]
dependencies: [FTR-0101, FTR-0110]
epic: EP-0005
risk_notes: "Password policy and migration risk."
```

**JSON Schema (excerpt) for **``**:**

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["id", "title", "status", "created", "updated"],
  "properties": {
    "id": { "type": "string", "pattern": "^FTR-\\d{4}$" },
    "title": { "type": "string", "minLength": 3 },
    "status": { "type": "string", "enum": ["backlog", "in-progress", "review", "done"] },
    "owner": { "type": "string" },
    "priority": { "type": "string", "enum": ["P0", "P1", "P2", "P3"] },
    "complexity": { "type": "string", "enum": ["XS", "S", "M", "L", "XL"] },
    "created": { "type": "string", "format": "date" },
    "updated": { "type": "string", "format": "date" },
    "labels": { "type": "array", "items": { "type": "string" } },
    "dependencies": { "type": "array", "items": { "type": "string", "pattern": "^FTR-\\d{4}$" } },
    "epic": { "type": "string" },
    "risk_notes": { "type": "string" }
  },
  "additionalProperties": false
}
```

---

## 7) Spec Body Template (Markdown)

> Copy from `/templates/feature.md` when creating a new feature.

```markdown
# Feature Spec: <Title>

## Summary

One‑paragraph overview of the problem and the proposed change.

## Problem Statement

Who is impacted, what pain exists, why now.

## Goals & Non‑Goals

- Goals: …
- Non‑Goals: …

## User Stories

- As a <role>, I want <capability> so that <benefit>.

## Requirements

### Functional

- …

### Non‑Functional

- Performance, reliability, security, accessibility, i18n, privacy, compliance.

## Acceptance Criteria (Testable)

- [ ] …
- [ ] …

## UI/UX Notes

- Wireframes, component changes, empty states.

## Data & API

- Data model diffs, API endpoints (request/response), migrations.

## Rollout & Migration

- Feature flags, phased rollout, telemetry, rollback.

## Monitoring & Metrics

- KPIs, dashboards, alerts.

## Security & Compliance

- Threats, mitigations, PII handling, audit logging.

## Implementation Notes

- Libraries, patterns, risks, tech debt considerations.

## Open Questions

- …

## Links

- Related FTRs, tickets, PRs.
```

---

## 8) Lifecycle & State Transitions

**Allowed transitions:**

- `backlog → in-progress`
- `in-progress → review`
- `review → in-progress` (changes requested)
- `review → done`

**Folder moves (must match frontmatter **``**):**

- `/features/backlog/FTR-0123-*.md` ↔ status `backlog`
- `/features/in-progress/FTR-0123-*.md` ↔ status `in-progress`
- `/features/review/FTR-0123-*.md` ↔ status `review`
- `/features/done/FTR-0123-*.md` ↔ status `done`

**State rules:**

- A spec may exist in **exactly one** lifecycle folder.
- `id` and base filename are **immutable** after creation.
- `updated` must change on every content edit.
- Dependencies must be `done` before moving **into** `in-progress`.

---

## 9) CLI Tool Detection & Usage

### A. Check for Virtual Board CLI

Before using any automation, agents should first check if the `vb` CLI tool is available:

```bash
# Check if vb CLI is installed
if command -v vb &> /dev/null; then
    echo "Virtual Board CLI found"
    vb version
    vb help
    # Use vb commands for task management
else
    echo "Virtual Board CLI not found, using shell scripts"
    # Fall back to shell scripts or plain bash
fi
```

### B. CLI Usage (if available)

If `vb` CLI is available, use it for all task management:

```bash
# Check version and upgrade
vb version
vb upgrade  # Upgrade to latest version (use sudo if in system directory)

# Create new feature
vb new "Feature Title" label1 label2

# Move feature through lifecycle
vb move FTR-0001 in-progress --owner agent-cursor-1

# Validate features
vb validate

# Generate index
vb index
```

### C. Fallback to Shell Scripts

If `vb` CLI is not available, use the shell scripts:

```bash
# Make scripts executable
chmod +x .virtualboard/scripts/*.sh

# Use shell scripts
./.virtualboard/scripts/ftr-new.sh "Feature Title" label1 label2
./.virtualboard/scripts/ftr-move.sh FTR-0001 in-progress agent-cursor-1
./.virtualboard/scripts/ftr-validate.sh
./.virtualboard/scripts/ftr-index.sh
```

---

## 10) Agent Commands & Prompts System

The `/prompts/` directory contains specialized commands and workflows for each agent role. This system provides:

- **Standardized commands** with clear trigger phrases
- **Detailed workflows** for common tasks
- **Report templates** for consistent output
- **File path conventions** for generated artifacts

### Directory Organization

```
/prompts
  AGENTS.md                    # Commands system overview
  /agents
    /{role}/                   # Each agent has their own directory
      README.md                # Command catalog for that role
      {AgentName}-{Command_Name}.md  # Individual command workflows
  /common
    session-handoff.md         # Common templates
```

### Command File Structure

Each command file (e.g., `prompts/agents/pm/PM-Generate_Project_Progress_Report.md`) contains:

1. **Trigger Phrases** - Keywords that activate the command
2. **Description** - What the command does
3. **Workflow** - Step-by-step instructions
4. **Output Format** - Required structure and file paths
5. **Prerequisites** - Dependencies or required context

### Available Command Categories

| Category | Description | Examples |
|----------|-------------|----------|
| **Reports** | Generate status and analysis reports | GPP (Progress), GTCR (Test Coverage) |
| **Documentation** | Create technical documentation | GAD (API Docs), GTD (Tech Debt) |
| **Architecture** | Design and review system architecture | GAD (Architecture Diagram), GAR (Architecture Review) |
| **Testing** | Test planning and coverage | GTP (Test Plan), GETE (E2E Tests) |
| **Security** | Security analysis and threat modeling | GSA (Security Audit), GTM (Threat Model) |
| **Development** | Code generation and scaffolding | GFF (Full Feature), GC (Component) |
| **Data** | Data modeling and pipelines | ERD (Data Model), GDP (Data Pipeline) |
| **DevOps** | Deployment and operations | GDC (Deployment Checklist), GIR (Incident Response) |
| **Design** | UX and visual design | GWF (Wireframe), GDS (Design System) |

### Using Commands

1. **Agent adopts role** - Reads `agents/{role}.md`
2. **Loads command catalog** - Reads `prompts/agents/{role}/README.md`
3. **Displays available commands** - Shows user what's available
4. **User triggers command** - Via trigger phrase (e.g., "GPP")
5. **Agent executes workflow** - Follows `prompts/agents/{role}/{AgentName}-{Command_Name}.md`
6. **Generates output** - Creates report/artifact at specified path

See `/prompts/AGENTS.md` for complete documentation.

---

## 11) Step‑by‑Step Usage

### A. Create a New Feature

1. **Check for CLI tool first:**
   ```bash
   if command -v vb &> /dev/null; then
       vb new "User Authentication" --labels "auth,frontend"
   else
       chmod +x .virtualboard/scripts/*.sh
       ./.virtualboard/scripts/ftr-new.sh "User Authentication" auth frontend
   fi
   ```

2. Script/CLI assigns next ID, creates `/features/backlog/FTR-####-user-authentication.md` from template.
3. Fill frontmatter (status=`backlog`, owner=`unassigned`).
4. Complete minimal sections: Summary, Problem, Goals, Acceptance Criteria.

### B. Start Work on a Feature

1. **Check dependencies and move feature:**
   ```bash
   if command -v vb &> /dev/null; then
       vb move FTR-0001 in-progress --owner agent-cursor-1
   else
       ./.virtualboard/scripts/ftr-move.sh FTR-0001 in-progress agent-cursor-1
   fi
   ```

2. Ensure dependencies are `done` (validation enforces this).
3. Create branch `feat/FTR-####-short-description`.
4. Implement against Acceptance Criteria; update spec `Implementation Notes` and `Links` with PRs.

### C. Send for Review

1. **Move to review status:**
   ```bash
   if command -v vb &> /dev/null; then
       vb move FTR-0001 review
   else
       ./.virtualboard/scripts/ftr-move.sh FTR-0001 review
   fi
   ```

2. Open PR using `/templates/pr-template.md`; link spec and reference `FTR-####` in title.
3. Reviewer checks spec completeness and tests; may push doc edits or request changes.

### D. Close as Done

1. Reviewer approves PR; merge code.
2. **Move to done status:**
   ```bash
   if command -v vb &> /dev/null; then
       vb move FTR-0001 done
   else
       ./.virtualboard/scripts/ftr-move.sh FTR-0001 done
   fi
   ```

3. Link merged PR and release notes in `Links` section.
4. Optional: Auto‑archive after N days to `/archive/YYYY/`.

---

## 12) Concurrency & Locking (Multi‑Agent Safety)

- **Soft lock via owner:** Only the current `owner` may edit a spec outside of trivial fixes.
- **Optional hard lock:** Create `/locks/FTR-0123.lock` containing `{ owner, started_at, ttl_minutes }`. CI warns if TTL expired.
- **Collision rule:** If an agent detects another owner or active lock, it must abort and comment in the PR or handoff file.
- **Granularity:** Agents must **not** edit specs they do not own; they may read for dependency checks and indexing.

---

## 13) Git & PR Conventions

- **Branch:** `feat/FTR-####-short-description`
- **Commits:** Prefix with `FTR-####:`; keep changes cohesive to that feature.
- **PR title:** `FTR-####: <title>`; **PR links** back to the spec.
- **PR template:** Mirrors the spec’s Acceptance Criteria (checkboxes) + Risk Assessment + Rollback Plan.
- **Merge rule:** No merge until spec is `review` and CI passes validation.

---

## 14) Validation & Automation (CI)

**CI must enforce:**

1. Frontmatter validates against `/schemas/frontmatter.schema.json`.
2. File’s folder matches `status`.
3. `id` unique; filename matches `id` & short description pattern.
4. Dependencies exist and are `done` before `in-progress`.
5. `updated` date is today for any content diff.
6. All internal links resolve; labels are normalized (kebab‑case).
7. Optional: lock TTL not expired.
8. System specs in `/specs` validate against `/schemas/system-spec.schema.json`.

**Index Generation:**

- `scripts/ftr-index.sh` creates `/features/INDEX.md` containing a table: ID, Title, Status, Owner, Priority, Complexity, Labels, Updated, Links.
- Run on every push to `main`.

**Linting:**

- `markdownlint` and `prettier` for prose consistency (optional, requires Node.js if used).

**Bash Script Benefits:**

- Zero external dependencies beyond standard Unix tools
- Fast execution without JavaScript runtime overhead
- Universal compatibility across all Unix-like systems
- Easy to understand and modify for custom requirements

---

## 15) Agent Rules of Engagement (RoE)

> Human‑readable summary in `/agents/RULES.md`; machine‑readable parameters in `/templates/rules.yml`.

### A. Agent-Specific Commands & Actions

**IMPORTANT:** Before starting any task, agents must check for role-specific commands and actions defined in the `/prompts/agents/{role}/` directory.

Each agent role has:
- **README.md** - Catalog of available commands for that role
- **Command files** (e.g., `PM-Generate_Project_Progress_Report.md`, `Architect-Generate_Architecture_Decision.md`) - Detailed workflow for each command
- **Special trigger phrases** that activate specific workflows
- **Structured report templates** for consistent outputs
- **Output file conventions** for generated reports and documentation

**When to check `/prompts/agents/{role}/`:**
1. **At session start** - Read `README.md` to review available commands for your role
2. **Display available commands** - Show users what commands you can execute
3. **When user requests a command** - Check for matching trigger phrases (e.g., "GPP", "GAD")
4. **Before executing** - Read the full command file for step-by-step workflow
5. **When generating documentation** - Follow established templates and conventions

**Example commands by role:**
- **Project Manager (PM)**: `GPP` → Generate Project Progress Report at `reports/{YYYY-MM-DD}_Project_Progress_Report.md`
- **Architect**: `GAD` → Generate Architecture Diagram, `GAR` → Generate Architecture Review, `GTD` → Generate Technical Debt Report
- **Data Engineer**: `ERD` → Entity Relationship Diagram, `GDP` → Generate Data Pipeline
- **Fullstack Dev**: `GFF` → Generate Full Feature, `GIC` → Generate Integration Contract
- **Frontend Dev**: `GC` → Generate Component, `GAA` → Generate Accessibility Audit
- **Backend Dev**: `GAE` → Generate API Endpoint, `GDM` → Generate Data Migration
- **DevOps**: `GDC` → Generate Deployment Checklist, `GIR` → Generate Incident Response
- **Security**: `GSA` → Generate Security Audit, `GTM` → Generate Threat Model
- **QA**: `GTP` → Generate Test Plan, `GTCR` → Generate Test Coverage Report
- **UX Designer**: `GWF` → Generate Wireframe, `GUJ` → Generate User Journey

**How to use:**
1. Read `/prompts/agents/{role}/README.md` to understand available commands
2. Display command summary to the user when adopting role
3. Identify if the user's request matches a defined command/trigger phrase
4. Read the full command file (e.g., `/prompts/agents/pm/PM-Generate_Project_Progress_Report.md`) for detailed workflow
5. Follow the exact workflow specified in the command file
6. Use the provided templates for consistent output format
7. Save reports to the specified file path conventions

### B. General Agent Rules

**MUST:**

- **Check `/prompts/agents/{role}/README.md` first** when adopting an agent role
- **Display available commands** to user when starting a session
- Check for `vb` CLI tool availability first: `command -v vb &> /dev/null`
- If `vb` CLI is available, use `vb version` and `vb help` to understand available commands
- If `vb` CLI is not available, fall back to shell scripts in `scripts/` or plain bash
- Read `/templates/rules.yml` on start.
- Validate spec before edits; bail on lock/owner mismatch.
- Only modify specs where `owner == agent-id`.
- Update `updated` on every edit.
- Preserve frontmatter ordering/whitespace; never change `id` or filename.

**MUST NOT:**

- Move a file across folders without updating `status`.
- Start work if any dependency not `done`.
- Create duplicate IDs or specs.
- Ignore commands defined in `/prompts/agents/{role}/` for your role.

**SHOULD:**

- Add links to PRs and artifacts.
- Keep Acceptance Criteria atomic and testable.
- Propose corrections via PR comments when not owner.
- Include the following comment on the commit message: "Planned using the @virtualboard task management strategy"
- Follow report templates exactly as defined in command files under `/prompts/agents/{role}/`

---

## 16) Examples

### Example Spec Header (in-progress)

```yaml
id: FTR-0123
title: User Authentication
status: in-progress
owner: agent-42
priority: P1
complexity: M
created: 2025-09-16
updated: 2025-09-16
labels: [auth, frontend, security]
dependencies: [FTR-0101]
epic: EP-0005
risk_notes: "Password reset flows and session fixation risks"
```

### Example `features/INDEX.md` (excerpt)

```markdown
| ID       | Title               | Status | Owner    | P   | C   | Labels         | Updated    |
| -------- | ------------------- | ------ | -------- | --- | --- | -------------- | ---------- |
| FTR-0101 | Auth Infrastructure | done   | dev-alex | P1  | M   | auth, security | 2025-09-10 |
| FTR-0123 | User Authentication | in-pro |
```
