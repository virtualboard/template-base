# Project Manager Commands

This file defines specialized commands and actions for the Project Manager agent role.

## ⚠️ IMPORTANT: Command Display Requirement

**When you adopt the PM agent role and load this command file, you MUST immediately display a summary of available commands to the user.**

**Format:**
```
📋 Available PM Commands:
• GPP (Generate Project Progress Report) - Create comprehensive project status reports - See [pm/GPP.md](GPP.md)
• GBG (Generate Backlog Grooming) - Perform comprehensive backlog refinement session - See [pm/GBG.md](GBG.md)
```

This ensures users know what commands are available to them.

---

## Available Commands

### ✅ Generate Project Progress Report (GPP)

**Location:** [pm/GPP.md](GPP.md)

**Description:** Create comprehensive project status reports

**Trigger Phrases:**
- "Generate Project Progress Report"
- "GPP"
- "Create progress report"
- "Project status report"

When you receive this command, read the full instructions in [pm/GPP.md](GPP.md).

---

### ✅ Generate Backlog Grooming (GBG)

**Location:** [pm/GBG.md](GBG.md)

**Description:** Perform comprehensive backlog refinement session

**Trigger Phrases:**
- "Generate Backlog Grooming"
- "GBG"
- "Groom backlog"
- "Backlog grooming session"
- "Refine backlog"
- "Backlog refinement"

When you receive this command, read the full instructions in [pm/GBG.md](GBG.md).

**What it does:**
- Assesses implementation status of all backlog features
- Interactively checks with user for next steps on each feature
- Analyzes relevance and identifies obsolete features
- Validates spec quality and dependency health
- Recommends prioritization changes
- Generates comprehensive grooming report with actionable insights

---

## Command Execution Guidelines

When executing PM commands:
- **Confirm the command** - State which command you're executing
- **Be thorough** - Don't skip steps in the workflow
- **Be accurate** - Verify facts from actual feature files, don't assume
- **Be actionable** - Provide specific next steps with FTR numbers
- **Follow templates** - Use the exact report structure provided
- **Update dates** - Always use current date in YYYY-MM-DD format

---

## Future PM Commands

### Planned
- **Generate Sprint Plan (GSP)** - Create sprint planning documents
- **Generate Velocity Report (GVR)** - Track team velocity and capacity
- **Generate Blocker Analysis (GBA)** - Analyze and track blockers
- **Generate Release Notes (GRN)** - Compile release notes from completed features
- **Generate Risk Assessment (GRA)** - Assess project risks and mitigation strategies

---

**Last Updated:** 2025-10-09
**Role:** Project Manager
