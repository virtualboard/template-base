# QA Engineer Commands

This file defines specialized commands and actions for the QA Engineer agent role.

## ⚠️ IMPORTANT: Command Display Requirement

**When you adopt the QA Engineer agent role and load this command file, you MUST immediately display a summary of available commands to the user.**

**Format:**
```
📋 Available QA Commands:
• GTP (Generate Test Plan) - Create comprehensive test plan for a feature - See [qa/QA-Generate_Test_Plan.md](QA-Generate_Test_Plan.md)
• GBR (Generate Bug Report) - Document bugs with reproduction steps - See [qa/QA-Generate_Bug_Report.md](QA-Generate_Bug_Report.md)
• GTCR (Generate Test Coverage Report) - Analyze test coverage gaps - See [qa/QA-Generate_Test_Coverage_Report.md](QA-Generate_Test_Coverage_Report.md)
• GBAT (Generate Browser Automation Tests) - Create Playwright browser tests with full automation - See [qa/QA-Generate_Browser_Automation_Tests.md](QA-Generate_Browser_Automation_Tests.md)
```

This ensures users know what commands are available to them.

---

## Available Commands

### ✅ Generate Test Plan (GTP)

**Location:** [qa/QA-Generate_Test_Plan.md](QA-Generate_Test_Plan.md)

**Description:** Create comprehensive test plan for a feature

**Trigger Phrases:**
- "Generate Test Plan"
- "GTP"
- "Create test plan"
- "Test plan for feature"

When you receive this command, read the full instructions in [qa/QA-Generate_Test_Plan.md](QA-Generate_Test_Plan.md).

---

### ✅ Generate Bug Report (GBR)

**Location:** [qa/QA-Generate_Bug_Report.md](QA-Generate_Bug_Report.md)

**Description:** Document bugs with reproduction steps

**Trigger Phrases:**
- "Generate Bug Report"
- "GBR"
- "Report bug"
- "Create bug report"
- "Log defect"

When you receive this command, read the full instructions in [qa/QA-Generate_Bug_Report.md](QA-Generate_Bug_Report.md).

---

### ✅ Generate Test Coverage Report (GTCR)

**Location:** [qa/QA-Generate_Test_Coverage_Report.md](QA-Generate_Test_Coverage_Report.md)

**Description:** Analyze test coverage gaps

**Trigger Phrases:**
- "Generate Test Coverage Report"
- "GTCR"
- "Create test coverage report"
- "Test coverage analysis"

When you receive this command, read the full instructions in [qa/QA-Generate_Test_Coverage_Report.md](QA-Generate_Test_Coverage_Report.md).

---

### ✅ Generate Browser Automation Tests (GBAT)

**Location:** [qa/QA-Generate_Browser_Automation_Tests.md](QA-Generate_Browser_Automation_Tests.md)

**Description:** Create Playwright browser tests with full automation workflow (test case generation, automation scripts, execution, and reporting)

**Trigger Phrases:**
- "Generate Browser Automation Tests"
- "GBAT"
- "Create Playwright tests"
- "Generate UI automation tests"
- "Create browser test cases"
- "Playwright test automation"

When you receive this command, read the full instructions in [qa/QA-Generate_Browser_Automation_Tests.md](QA-Generate_Browser_Automation_Tests.md).

**Note:** This is a multi-phase command that handles:
1. Test case documentation generation
2. Playwright automation script creation
3. Test execution across browsers
4. Comprehensive reporting

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
