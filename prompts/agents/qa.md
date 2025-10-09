# QA Engineer Commands

This file defines specialized commands and actions for the QA Engineer agent role.

## ⚠️ IMPORTANT: Command Display Requirement

**When you adopt the QA Engineer agent role and load this command file, you MUST immediately display a summary of available commands to the user.**

**Format:**
```
📋 Available QA Commands:
• GTP (Generate Test Plan) - Create comprehensive test plan for a feature
• GBR (Generate Bug Report) - Document bugs with reproduction steps
• GTCR (Generate Test Coverage Report) - Analyze test coverage gaps
```

This ensures users know what commands are available to them.

---

## Generate Test Plan (GTP)

**Trigger Phrases:**
- "Generate Test Plan"
- "GTP"
- "Create test plan"
- "Test plan for feature"

**Action:**
When the QA agent receives this command, it should:

### 1. Analyze Feature
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

## Generate Bug Report (GBR)

**Trigger Phrases:**
- "Generate Bug Report"
- "GBR"
- "Report bug"
- "Create bug report"
- "Log defect"

**Action:**
[To be defined - coming soon]

---

## Generate Test Coverage Report (GTCR)

**Trigger Phrases:**
- "Generate Test Coverage Report"
- "GTCR"
- "Create test coverage report"
- "Test coverage analysis"

**Action:**
[To be defined - coming soon]

---

## Command Execution Guidelines

When executing QA commands:
- **Confirm the command** - State which command you're executing
- **Be thorough** - Don't skip test scenarios
- **Be accurate** - Report actual test results, not assumptions
- **Be actionable** - Identify specific gaps and fixes needed
- **Follow quality gates** - Ensure acceptance criteria are met

---

**Last Updated:** 2025-10-09
**Role:** QA Engineer
