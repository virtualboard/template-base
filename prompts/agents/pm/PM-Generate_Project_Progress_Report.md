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
