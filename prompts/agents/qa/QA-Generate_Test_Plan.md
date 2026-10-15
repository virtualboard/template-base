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

If the user requests `--html`, "as HTML"/"branded HTML", or `format: html`,
write the Markdown deliverable first, then render an additional HTML report.

1. Read `templates/reports/html/qa-test-plan.html`. Its comment header lists the
   scalar fields and list-item shapes. Use the same findings and measurements
   as the Markdown report; do not invent values for unknown results.
2. Write a companion JSON data file with uppercase field names, native numbers,
   and arrays of objects for lists. Include every referenced field; use `""`,
   `null`, or `[]` for explicitly empty values. The default brand and raster logo
   are provided by the renderer.
3. Run the deterministic renderer:

   ```bash
   vb report render --template qa-test-plan.html \
     --data REPORT_DATA.json --output REPORT.html
   ```

   Replace the example paths with paths beside the Markdown deliverable, using
   the same basename for `.md`, `.json`, and `.html`. Includes and repeated
   blocks are resolved by the CLI; do not manually substitute template text.
4. Strings are escaped, including `*_HTML` fields. Annotate reviewed markup as
   `{"html":"<p>Reviewed content</p>"}` and add `--allow-html` only when those
   fragments are intended as markup. Supply `*_JSON` fields as native JSON
   values; the renderer safely serializes them in inline scripts.
5. Validate with `--dry-run` if useful, then inspect the generated HTML. Existing
   output requires `--force`; a rendering error must preserve earlier output.
   If the installed CLI lacks `report render`, report that limitation instead
   of claiming an HTML artifact was produced.
6. List the Markdown and HTML paths in the final reply, with the companion JSON
   path so the report can be reproduced.

See `templates/reports/README.md` for the input contract and the runnable
`templates/reports/examples/pm-progress-report.data.json` for a complete example.
