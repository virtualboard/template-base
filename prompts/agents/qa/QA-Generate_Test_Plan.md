# Generate Test Plan (GTP)

**Trigger Phrases:**
- "Generate Test Plan"
- "GTP"
- "Create test plan"
- "Test plan for feature"

**Action:**
When the QA agent receives this command, it should:

## 1. Analyze Feature
- Read the feature spec from `.virtualboard/features/`
- Identify all acceptance criteria
- Review user stories and edge cases
- Check dependencies and integration points

### 2. Identify Test Scenarios
- Map each acceptance criterion to test scenarios
- Include positive, negative, and edge case tests
- Consider: functional, integration, performance, security, accessibility
- Identify data requirements

### 3. Create Test Plan
- Create test plan at `.virtualboard/testing/plans/TP-{FTR-####}-{feature-name}.md`
- Use the following structure:

```markdown
# Test Plan: {Feature Name}
**Feature ID:** FTR-####
**Created:** {YYYY-MM-DD}
**Tester:** {Agent/Person}
**Status:** Draft | In Progress | Completed

---

## Feature Overview
{Brief description of the feature being tested}

## Test Objectives
- {Objective 1}
- {Objective 2}
- {Objective 3}

## Scope

### In Scope
- {What will be tested}
- {Component 1}
- {Component 2}

### Out of Scope
- {What will NOT be tested}
- {Excluded items}

---

## Test Strategy

### Testing Types
- [ ] Unit Testing
- [ ] Integration Testing
- [ ] End-to-End Testing
- [ ] Performance Testing
- [ ] Security Testing
- [ ] Accessibility Testing
- [ ] Cross-browser Testing (if applicable)

### Test Environment
- **Environment:** {dev/staging/production}
- **Test Data:** {Data requirements}
- **Tools:** {Testing tools/frameworks}

---

## Test Scenarios

### Scenario 1: {Scenario Name}
**Priority:** High | Medium | Low
**Type:** Functional | Integration | Performance | Security

**Preconditions:**
- {Condition 1}
- {Condition 2}

**Test Steps:**
1. {Step 1}
2. {Step 2}
3. {Step 3}

**Expected Result:**
- {Expected outcome}

**Acceptance Criteria Covered:**
- AC-1: {Criteria description}

---

### Scenario 2: {Scenario Name}
{Repeat structure}

---

## Edge Cases & Negative Tests

### EC-1: {Edge Case Name}
**Description:** {What edge case is being tested}
**Steps:** {How to test}
**Expected:** {Expected behavior}

---

## Test Data Requirements
- {Data type 1}: {Description}
- {Data type 2}: {Description}

## Dependencies
- {Dependency 1}
- {Dependency 2}

## Risks & Mitigation
- **Risk:** {Risk description}
  - **Mitigation:** {How to mitigate}

---

## Test Execution Checklist
- [ ] All test scenarios executed
- [ ] All bugs logged
- [ ] Regression tests passed
- [ ] Performance benchmarks met
- [ ] Security checks completed
- [ ] Accessibility validated
- [ ] Documentation updated

## Sign-off Criteria
- [ ] All high-priority tests passed
- [ ] No critical/blocker bugs open
- [ ] Acceptance criteria met
- [ ] Stakeholder approval received

---

**Last Updated:** {YYYY-MM-DD}
```

### 4. Create Directory if Needed
- Ensure `.virtualboard/testing/plans/` exists
- Use `mkdir -p` to create if necessary

### 5. Announce Completion
- Inform the user that the test plan has been created
- Provide the file path
- Highlight key test scenarios and coverage areas

---

## Optional: Generate Branded HTML Report

If the user appends `--html`, says "as HTML"/"branded HTML", or sets
`format: html`, also produce an HTML rendering. **Additive** — the Markdown
report is always written first.

1. Load `templates/reports/html/qa-test-plan.html`. The comment block at the top of
   that file lists every placeholder this command must compute, with the same
   names used in the Markdown report.
2. Inline `{INCLUDE: _partials/<name>.html}` directives by reading and
   pasting the referenced files; iterate until no `{INCLUDE:` markers remain.
3. Substitute `{BRAND_LOGO_DATAURI}` with the contents of
   `templates/reports/html/_partials/astucia-logo.b64.txt`, **stripping leading
   and trailing whitespace** (the file may end in a newline that must not
   appear inside `src="…"`).
4. Substitute `{BRAND_NAME}` (default `Astucia`) and `{BRAND_TAGLINE}`
   (default `AI Development Studio`) unless the user provided overrides.
5. Substitute the cross-cutting placeholders (`REPORT_TITLE`,
   `REPORT_TITLE_HTML`, `REPORT_SUBTITLE`, `EYEBROW`, `GENERATED_DATE`,
   `GENERATED_DATETIME`, `AUTHOR_AGENT`, `CLASSIFICATION`, `PROJECT_NAME`,
   `NAV_LINKS`, `FOOTER_PRIMARY_LINE`, `FOOTER_SECONDARY_LINE`,
   `FOOTER_NOTE_BLOCK`, `EXTRA_SCRIPTS`).
6. Substitute the per-template scalar placeholders:
   `FTR_ID`, `FEATURE_TITLE`, `PLAN_OBJECTIVE_HTML`, `SCOPE_IN_HTML`, `SCOPE_OUT_HTML`, `EXIT_CRITERIA_HTML`, `KPI_TOTAL_CASES`, `KPI_CRITICAL`, `KPI_HIGH`, `KPI_MEDIUM`, `KPI_LOW`, `KPI_AUTOMATED_PCT`, `ENVIRONMENT_HTML`, `ROLES_HTML`, `SCHEDULE_HTML`, `RISK_AREAS_HTML`.
7. Expand each `{#NAME}…{/NAME}` list block once per item using the
   per-template list placeholders: `HERO_META_CELLS`, `TEST_CASES`, `ACCEPTANCE_CRITERIA`, `ASSUMPTIONS`, `DEPENDENCIES`. The per-item field names are
   documented in the template's top comment.
8. For each list, set the matching `LIST_EMPTY_<NAME>` scalar to `""` if the
   list has items, or to a small italic note (e.g.
   `<p class="empty-note">No items.</p>`) if the list is empty.
9. Write the rendered HTML next to the Markdown:
   `.virtualboard/testing/plans/TP-{FTR-####}-{name}.html`.
10. **Verify before reporting completion.** Search the rendered output for any
    literal `{` — there must be none. Resolve leftovers (or substitute the
    empty string for known-optional slots) before continuing.
11. In your final reply, list **both** file paths.

A filled-in reference example lives at
`templates/reports/examples/qa-test-plan.example.html`.
