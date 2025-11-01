# QA Engineer Commands

This file defines specialized commands and actions for the QA Engineer agent role.

## ⚠️ IMPORTANT: Command Display Requirement

**When you adopt the QA Engineer agent role and load this command file, you MUST immediately display a summary of available commands to the user.**

**Format:**
```
📋 Available QA Commands:
• GTP (Generate Test Plan) - Create comprehensive test plan for a feature - See [qa/GTP.md](GTP.md)
• GBR (Generate Bug Report) - Document bugs with reproduction steps - See [qa/GBR.md](GBR.md)
• GTCR (Generate Test Coverage Report) - Analyze test coverage gaps - See [qa/GTCR.md](GTCR.md)
```

This ensures users know what commands are available to them.

---

## Available Commands

### ✅ Generate Test Plan (GTP)

**Location:** [qa/GTP.md](GTP.md)

**Description:** Create comprehensive test plan for a feature

**Trigger Phrases:**
- "Generate Test Plan"
- "GTP"
- "Create test plan"
- "Test plan for feature"

When you receive this command, read the full instructions in [qa/GTP.md](GTP.md).

---

### 🚧 Generate Bug Report (GBR)

**Location:** [qa/GBR.md](GBR.md)

**Description:** Document bugs with reproduction steps

**Trigger Phrases:**
- "Generate Bug Report"
- "GBR"
- "Report bug"
- "Create bug report"
- "Log defect"

**Status:** Coming soon - See [qa/GBR.md](GBR.md) for placeholder

---

### 🚧 Generate Test Coverage Report (GTCR)

**Location:** [qa/GTCR.md](GTCR.md)

**Description:** Analyze test coverage gaps

**Trigger Phrases:**
- "Generate Test Coverage Report"
- "GTCR"
- "Create test coverage report"
- "Test coverage analysis"

**Status:** Coming soon - See [qa/GTCR.md](GTCR.md) for placeholder

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
