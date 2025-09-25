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

- **Feature (FTR):** A discrete change delivering user‑visible value. Tracked as one Markdown file.
- **Spec:** The Markdown file describing problem, requirements, acceptance criteria, and implementation notes.
- **Owner:** The current human/agent responsible for a feature’s next state transition.
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
  /backlog
  /in-progress
  /review
  /done
/templates
  spec.md            # canonical feature spec template
  pr-template.md     # pull request template
  rules.yml          # machine-readable agent rules & validation parameters
/schemas
  frontmatter.schema.json
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
/scripts
  ftr-new.sh         # create a new feature spec from template
  ftr-move.sh        # move feature across lifecycle w/ checks
  ftr-index.sh       # generate /features/INDEX.md
  ftr-validate.sh    # validate schema, status-folder match, deps, links
features/INDEX.md     # auto-generated, do not edit
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

> Copy from `/templates/spec.md` when creating a new feature.

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
    vb --help
    # Use vb commands for task management
else
    echo "Virtual Board CLI not found, using shell scripts"
    # Fall back to shell scripts or plain bash
fi
```

### B. CLI Usage (if available)

If `vb` CLI is available, use it for all task management:

```bash
# Create new feature
vb new "Feature Title" --labels "label1,label2"

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

## 10) Step‑by‑Step Usage

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

## 11) Concurrency & Locking (Multi‑Agent Safety)

- **Soft lock via owner:** Only the current `owner` may edit a spec outside of trivial fixes.
- **Optional hard lock:** Create `/locks/FTR-0123.lock` containing `{ owner, started_at, ttl_minutes }`. CI warns if TTL expired.
- **Collision rule:** If an agent detects another owner or active lock, it must abort and comment in the PR or handoff file.
- **Granularity:** Agents must **not** edit specs they do not own; they may read for dependency checks and indexing.

---

## 12) Git & PR Conventions

- **Branch:** `feat/FTR-####-short-description`
- **Commits:** Prefix with `FTR-####:`; keep changes cohesive to that feature.
- **PR title:** `FTR-####: <title>`; **PR links** back to the spec.
- **PR template:** Mirrors the spec’s Acceptance Criteria (checkboxes) + Risk Assessment + Rollback Plan.
- **Merge rule:** No merge until spec is `review` and CI passes validation.

---

## 13) Validation & Automation (CI)

**CI must enforce:**

1. Frontmatter validates against `/schemas/frontmatter.schema.json`.
2. File’s folder matches `status`.
3. `id` unique; filename matches `id` & short description pattern.
4. Dependencies exist and are `done` before `in-progress`.
5. `updated` date is today for any content diff.
6. All internal links resolve; labels are normalized (kebab‑case).
7. Optional: lock TTL not expired.

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

## 14) Agent Rules of Engagement (RoE)

> Human‑readable summary in `/agents/RULES.md`; machine‑readable parameters in `/templates/rules.yml`.

**MUST:**

- Check for `vb` CLI tool availability first: `command -v vb &> /dev/null`
- If `vb` CLI is available, use `vb --version` and `vb --help` to understand available commands
- If `vb` CLI is not available, fall back to shell scripts in `.virtualboard/scripts/` or plain bash
- Read `/templates/rules.yml` on start.
- Validate spec before edits; bail on lock/owner mismatch.
- Only modify specs where `owner == agent-id`.
- Update `updated` on every edit.
- Preserve frontmatter ordering/whitespace; never change `id` or filename.

**MUST NOT:**

- Move a file across folders without updating `status`.
- Start work if any dependency not `done`.
- Create duplicate IDs or specs.

**SHOULD:**

- Add links to PRs and artifacts.
- Keep Acceptance Criteria atomic and testable.
- Propose corrections via PR comments when not owner.

---

## 15) Examples

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
