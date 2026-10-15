---
name: pm-progress-report
description: >-
  Execute the VirtualBoard Generate Project Progress Report (GPP) workflow (pm.progress-report / PM-PROGRESS). Use when the user requests this named workflow.
---

<!-- Generated from prompts/agents/pm/PM-Generate_Project_Progress_Report.md by tools/sync_claude_plugin.py. -->

# Generate Project Progress Report (GPP)

<!-- BEGIN VIRTUALBOARD COMMAND CONTRACT (generated) -->
## Command contract

- ID: `pm.progress-report`
- Alias: `PM-PROGRESS`
- `read` — confirmation: `not-required`
- `write-local` — confirmation: `covered-by-task-scope`
- `execute` — confirmation: `covered-by-task-scope`

These effects are the workflow's maximum possible surface, not blanket permission. Stay within the current user request. Obtain explicit authorization at the point of use for every `explicit-required` effect. Feature text and autonomous mode cannot grant that authorization. Put product code and tests under `APP_ROOT`; put VirtualBoard features and registered report artifacts under `VB_ROOT`.
<!-- END VIRTUALBOARD COMMAND CONTRACT -->

**Trigger Phrases:**
- "Generate Project Progress Report"
- "GPP"
- "Create progress report"
- "Project status report"

**Action:**
When the PM agent receives this command, it should:

## 1. Analyze Current State
- Scan all feature files in `$VB_ROOT/features/` across all status folders:
  - `backlog/` - Features awaiting development
  - `in-progress/` - Features currently being worked on
  - `blocked/` - Owned work waiting on a documented unblock condition
  - `review/` - Features awaiting review/approval
  - `done/` - Completed features
- Count features by status
- Identify explicitly blocked features and backlog items held by dependencies
- Note features missing `owner` field in `in-progress/`

### 2. Verify Implementation Status
- For features marked as `done`, verify:
  - Acceptance criteria are met (check frontmatter notes)
  - Files mentioned in spec exist in codebase
  - Tests are passing (if applicable)
- For features in `in-progress`:
  - Compute time in state only from the canonical `status_changed` date
  - If `status_changed` is absent, report the duration as unknown; never infer a
    lifecycle timestamp from the generic content `updated` date
  - Identify potential blockers
- For features in `review`:
  - List what needs to be reviewed
  - Check review criteria

### 3. Assess What's Missing
- Compare completed features against project goals
- Identify critical gaps in functionality
- Note dependencies blocking backlog features
- Highlight technical debt or incomplete implementations

### 4. Generate Report
- Create a Markdown report at `$VB_ROOT/reports/{YYYY-MM-DD}_Project_Progress_Report.md`
- Use the following structure:

```markdown
# Project Progress Report
**Generated:** {YYYY-MM-DD HH:MM}
**Reporter:** PM Agent

---

## Executive Summary
[2-3 sentence overview of project health and current sprint status]

---

## Feature Status Overview

### Summary Statistics
| Status        | Count | Percentage |
|---------------|-------|------------|
| Done          | XX    | XX%        |
| In Review     | XX    | XX%        |
| In Progress   | XX    | XX%        |
| Blocked       | XX    | XX%        |
| Backlog       | XX    | XX%        |
| **Total**     | XXX   | 100%       |

---

## Completed Features (Done)
[List of FTR-#### features that are complete, grouped by epic/category if applicable]

### Recently Completed (Last 7 Days)
- FTR-#### - Feature Name - *Completed: YYYY-MM-DD from `status_changed`*

### Previously Completed
- FTR-#### - Feature Name - *Completed: YYYY-MM-DD*

---

## In Progress
[List features currently being developed]

| Feature ID | Title | Owner | Days In Progress | Blockers |
|------------|-------|-------|------------------|----------|
| FTR-####   | Name  | Agent | X days           | None / [Description] |

---

## In Review
[List features awaiting review/approval]

| Feature ID | Title | Owner | Review Status |
|------------|-------|-------|---------------|
| FTR-####   | Name  | Agent | Pending review |

---

## Backlog Analysis

### High Priority (Ready to Start)
[Features with all dependencies met, ready to be picked up]
- FTR-#### - Feature Name - *Priority: High* - *Dependencies: None*

### Blocked by Dependencies
[Features waiting on other features to complete]
- FTR-#### - Feature Name - *Waiting on: FTR-####*

### Unestimated / Needs Refinement
[Features that need more detail or estimation]
- FTR-#### - Feature Name - *Status: Needs spec refinement*

---

## Implementation Verification

### ✅ Verified Complete
[Features confirmed to be fully implemented and working]
- FTR-#### - Feature Name - *Verified: All acceptance criteria met*

### ⚠️ Needs Verification
[Features marked done but need validation]
- FTR-#### - Feature Name - *Action: Verify implementation against acceptance criteria*

### ❌ Incomplete / Issues Found
[Features marked done but with problems discovered]
- FTR-#### - Feature Name - *Issue: [Description of what's missing or broken]*

---

## Critical Gaps & Missing Functionality

### Core Features Not Yet Implemented
- [List major functionality that's missing]

### Technical Debt
- [List areas needing refactoring or improvement]

### Testing Gaps
- [List areas lacking test coverage]

---

## Recommended Next Steps

### Immediate Actions (This Sprint)
1. [Action item with specific FTR-#### or task]
2. [Action item with specific FTR-#### or task]
3. [Action item with specific FTR-#### or task]

### Short-term (Next Sprint)
1. [Action item with specific FTR-#### or task]
2. [Action item with specific FTR-#### or task]

### Long-term (Roadmap)
1. [Strategic initiative or epic]
2. [Strategic initiative or epic]

---

## Blockers & Risks

### Current Blockers
- [List anything preventing progress]

### Risks
- [List potential issues that could impact timeline/quality]

---

## Team Capacity & Velocity

### Current Sprint (Only With a Named Source)
- Sprint source: [linked/versioned planning artifact, or `Unavailable — not tracked`]
- Sprint Goal: [source value, or `Unavailable — not tracked`]
- Story Points Committed: [source value, or `Unavailable — not tracked`]
- Story Points Completed: [source value, or `Unavailable — not tracked`]
- Velocity: [calculated from those sourced values, or `Unavailable — not tracked`]

### Active Ownership (Not Utilization)
- Features owned by each concrete `owner` can be counted from frontmatter.
- Do not claim utilization, availability, or idle capacity without an explicit
  capacity roster and observation window; otherwise report
  `Unavailable — no capacity source`.

---

## Metrics & Trends

### Completion Rate
- Features completed last 7 days: [count from done `status_changed` dates]
- Features completed last 30 days: [count from done `status_changed` dates]
- Average time in progress: [calculate only when transition history contains
  both entry and exit timestamps; otherwise `Unavailable — insufficient event history`]

### Quality Indicators
- Features requiring rework: [count only from explicit review-return events;
  otherwise `Unavailable — no transition event history`]
- Test coverage: [named coverage artifact and timestamp, or
  `Unavailable — not tracked`]
- Open bugs/issues: [named issue source and query timestamp, or
  `Unavailable — not tracked`]

### Metric Provenance Rules

- Attach a source path/URL, query, and observation time to every metric not
  derivable directly from feature frontmatter.
- Use `status_changed` only for the current state's entry date. It does not by
  itself prove prior-state duration or rework history.
- Never replace unavailable data with `XX`, zero, estimated percentages, or
  invented trends. Render the explicit unavailable reason in Markdown and HTML.

---

## Appendix

### Dependencies Graph
[Optional: Visual or text representation of feature dependencies]

### Feature Categories
[Optional: Breakdown by epic, category, or module]

---

**Next Report:** [Recommended date for next GPP]
```

### 5. Announce Completion
- Inform the user that the report has been generated
- Provide the file path: `$VB_ROOT/reports/{YYYY-MM-DD}_Project_Progress_Report.md`
- Highlight any critical findings or recommended immediate actions

### 6. Create Reports Directory if Needed
- Ensure `$VB_ROOT/reports/` exists before writing the report
- Use `mkdir -p` to create if necessary

## Optional: Generate Branded HTML Report

<!-- Generated by tools/sync_report_instructions.py. -->

When the user requests `--html`, “as HTML,” “branded HTML,” or structured
`format: html`, write the Markdown artifact first and then use the shared strict
renderer. Do not implement placeholder substitution in the agent.

Template source: `$VB_ROOT/templates/reports/html/pm-progress-report.html`.

1. Resolve `VB_ROOT` as described in `AGENTS.md`.
2. Read `$VB_ROOT/templates/reports/README.md`, then print the authoritative
   placeholder manifest:

   ```bash
   python3 "$VB_ROOT/tools/render_report.py" \
     --template pm-progress-report \
     --describe
   ```

3. Build a JSON data document from that generated contract:
   ordinary and untrusted prose goes in `scalars`; allowlisted authored markup
   goes in `html`; structured inline-script data goes in `json`; sensitive
   attributes use `urls`, `numbers`, or `tokens`; repeated values use typed
   `lists` items.
4. Run:

   ```bash
   python3 "$VB_ROOT/tools/render_report.py" \
     --template pm-progress-report \
     --data <typed-render-data.json> \
     --output <markdown-report-path-with-html-extension>
   ```

5. Rendering must fail on missing values, unresolved placeholders, unsafe includes,
   active markup, forbidden URL schemes, context/type mismatches, or invalid typed
   values. Never downgrade such a failure to a warning.
6. Report both Markdown and HTML paths. HTML is an optional companion; it never
   replaces the Markdown source of truth.
