# Generate Project Progress Report (GPP)

**Trigger Phrases:**
- "Generate Project Progress Report"
- "GPP"
- "Create progress report"
- "Project status report"

**Action:**
When the PM agent receives this command, it should:

## 1. Analyze Current State
- Scan all feature files in `.virtualboard/features/` across all status folders:
  - `backlog/` - Features awaiting development
  - `in-progress/` - Features currently being worked on
  - `review/` - Features awaiting review/approval
  - `done/` - Completed features
- Count features by status
- Identify any blocked features (check dependencies)
- Note features missing `owner` field in `in-progress/`

### 2. Verify Implementation Status
- For features marked as `done`, verify:
  - Acceptance criteria are met (check frontmatter notes)
  - Files mentioned in spec exist in codebase
  - Tests are passing (if applicable)
- For features in `in-progress`:
  - Check how long they've been in progress (via `updated` date)
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
- Create a markdown report at `.virtualboard/reports/{YYYY-MM-DD}_Project_Progress_Report.md`
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
| Backlog       | XX    | XX%        |
| **Total**     | XXX   | 100%       |

---

## Completed Features (Done)
[List of FTR-#### features that are complete, grouped by epic/category if applicable]

### Recently Completed (Last 7 Days)
- FTR-#### - Feature Name - *Completed: YYYY-MM-DD*

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

### Current Sprint (If Applicable)
- Sprint Goal: [Description]
- Story Points Committed: XX
- Story Points Completed: XX
- Velocity: XX%

### Agent Utilization
- Features owned by specific agents
- Idle capacity (no active features)

---

## Metrics & Trends

### Completion Rate
- Features completed last 7 days: XX
- Features completed last 30 days: XX
- Average time in progress: X days

### Quality Indicators
- Features requiring rework: XX
- Test coverage: XX%
- Open bugs/issues: XX

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
- Provide the file path: `.virtualboard/reports/{YYYY-MM-DD}_Project_Progress_Report.md`
- Highlight any critical findings or recommended immediate actions

### 6. Create Reports Directory if Needed
- Ensure `.virtualboard/reports/` directory exists before writing the report
- Use `mkdir -p` to create if necessary

### 7. Optional — Generate Branded HTML Report

If the user appends `--html`, says "as HTML"/"branded HTML", or sets
`format: html`, also produce an HTML rendering. This is **additive** — the
Markdown report from steps 4–6 is always written first.

1. Load the template `templates/reports/html/pm-progress-report.html`. The
   comment block at the top of that file lists every placeholder this command
   must compute.
2. Resolve every `{{INCLUDE: _partials/<name>.html}}` directive by inlining the
   referenced file from `templates/reports/html/_partials/`. Iterate until no
   `{{INCLUDE:` markers remain.
3. Substitute `{{BRAND_LOGO_DATAURI}}` with the contents of
   `templates/reports/html/_partials/astucia-logo.b64.txt`, **stripping leading
   and trailing whitespace** (the file may end with a newline that must not
   appear inside `src="…"`).
4. Substitute `{{BRAND_NAME}}` (default `Astucia`) and `{{BRAND_TAGLINE}}`
   (default `AI Development Studio`) unless the user provided overrides.
5. Substitute every cross-cutting placeholder
   (`REPORT_TITLE`, `REPORT_TITLE_HTML`, `REPORT_SUBTITLE`, `EYEBROW`,
   `GENERATED_DATE`, `GENERATED_DATETIME`, `AUTHOR_AGENT`, `CLASSIFICATION`,
   `PROJECT_NAME`, `NAV_LINKS`, `FOOTER_PRIMARY_LINE`,
   `FOOTER_SECONDARY_LINE`, `FOOTER_NOTE_BLOCK`, `EXTRA_SCRIPTS`).
6. Substitute the per-template scalar placeholders using the same values you
   computed for the Markdown report:
   - `HEALTH_VERDICT` (`At risk` / `On track` / `Ahead`) and
     `HEALTH_VERDICT_CLASS` (`danger` / `ok` / empty)
   - `EXECUTIVE_SUMMARY_HTML` — 1–3 paragraph executive summary, HTML allowed
   - `KPI_TOTAL`, `KPI_DONE`, `KPI_REVIEW`, `KPI_IN_PROGRESS`, `KPI_BACKLOG`,
     `KPI_BLOCKED`
   - `PCT_DONE`, `PCT_REVIEW`, `PCT_IN_PROGRESS`, `PCT_BACKLOG` (integers,
     no `%` sign — the template adds it)
   - `SPRINT_GOAL`, `VELOCITY_PCT`, `POINTS_COMPLETED`, `POINTS_COMMITTED`,
     `COMPLETED_LAST_7`, `COMPLETED_LAST_30`, `AVG_DAYS_IN_PROGRESS`,
     `OPEN_BUGS`, `NEXT_REPORT_DATE` — substitute `—` for unknown values
7. Expand each `{{#LIST}}…{{/LIST}}` block once per item, substituting the
   inner per-item placeholders:
   - `HERO_META_CELLS` — `LABEL`, `VALUE`
   - `IN_PROGRESS` — `FTR_ID`, `TITLE`, `OWNER`, `DAYS_IN_PROGRESS`, `BLOCKERS`
   - `IN_REVIEW` — `FTR_ID`, `TITLE`, `OWNER`, `REVIEW_STATUS`
   - `RECENT_DONE` — `FTR_ID`, `TITLE`, `COMPLETED_DATE`
   - `NEXT_PRIORITIES` — `FTR_ID`, `TITLE`, `COMPLEXITY`
   - `BLOCKED_BY_DEPS` — `FTR_ID`, `TITLE`, `WAITING_ON`
   - `BLOCKERS` — `FTR_ID`, `REASON`
   - `IMMEDIATE_ACTIONS`, `SHORT_TERM`, `LONG_TERM` — `TITLE`, `DESC`
8. For each list, set the matching `LIST_EMPTY_<NAME>` scalar to `""` if the
   list has items, or to a short italic note (e.g., `<p class="empty-note">No
   features in review.</p>`) if the list is empty. Names:
   `LIST_EMPTY_IN_PROGRESS`, `LIST_EMPTY_IN_REVIEW`, `LIST_EMPTY_RECENT_DONE`,
   `LIST_EMPTY_NEXT_PRIORITIES`, `LIST_EMPTY_BLOCKERS`,
   `LIST_EMPTY_BLOCKED_BY_DEPS`, `LIST_EMPTY_IMMEDIATE_ACTIONS`,
   `LIST_EMPTY_SHORT_TERM`, `LIST_EMPTY_LONG_TERM`.
9. Write the rendered HTML next to the Markdown file:
   `.virtualboard/reports/{YYYY-MM-DD}_Project_Progress_Report.html`.
10. **Verify before reporting completion.** Search the rendered output for any
    literal `{{` — there must be none. Resolve any leftovers (or substitute the
    empty string for known-optional slots) before continuing.
11. In your final reply, list **both** file paths (the `.md` and the `.html`).

A filled-in reference example lives at
`templates/reports/examples/pm-progress-report.example.html` — open it
side-by-side with `reports/virtualboard-architecture-review-rev3.html` to
confirm visual parity.
