# System Architect Commands

This file defines specialized commands and actions for the System Architect agent role.

## ⚠️ IMPORTANT: Command Display Requirement

**When you adopt the Architect agent role and load this command file, you MUST immediately display a summary of available commands to the user.**

**Format:**
```
📋 Available Architect Commands:
• GAD (Generate Architecture Decision) - Document architectural decisions with ADR format - See [architect/Architect-Generate_Architecture_Decision.md](Architect-Generate_Architecture_Decision.md)
• GAR (Generate Architecture Report) - Create architecture analysis reports - See [architect/Architect-Generate_Architecture_Report.md](Architect-Generate_Architecture_Report.md)
• GTD (Generate Technical Debt Report) - Analyze and prioritize technical debt - See [architect/Architect-Generate_Technical_Debt_Report.md](Architect-Generate_Technical_Debt_Report.md)
```

This ensures users know what commands are available to them.

---

## Available Commands

### ✅ Generate Architecture Decision (GAD)

**Location:** [architect/Architect-Generate_Architecture_Decision.md](Architect-Generate_Architecture_Decision.md)

**Description:** Document architectural decisions with ADR format

**Trigger Phrases:**
- "Generate Architecture Decision"
- "GAD"
- "Document architecture decision"
- "Create ADR"
- "Architecture Decision Record"

When you receive this command, read the full instructions in [architect/Architect-Generate_Architecture_Decision.md](Architect-Generate_Architecture_Decision.md).

---

### ✅ Generate Architecture Report (GAR)

**Location:** [architect/Architect-Generate_Architecture_Report.md](Architect-Generate_Architecture_Report.md)

**Description:** Create architecture analysis reports

**Trigger Phrases:**
- "Generate Architecture Report"
- "GAR"
- "Create architecture report"
- "Architecture analysis"

When you receive this command, read the full instructions in [architect/Architect-Generate_Architecture_Report.md](Architect-Generate_Architecture_Report.md).

---

### ✅ Generate Technical Debt Report (GTD)

**Location:** [architect/Architect-Generate_Technical_Debt_Report.md](Architect-Generate_Technical_Debt_Report.md)

**Description:** Analyze and prioritize technical debt

**Trigger Phrases:**
- "Generate Technical Debt Report"
- "GTD"
- "Analyze technical debt"
- "Technical debt analysis"

When you receive this command, read the full instructions in [architect/Architect-Generate_Technical_Debt_Report.md](Architect-Generate_Technical_Debt_Report.md).

---

## Command Execution Guidelines

When executing Architect commands:
- **Confirm the command** - State which command you're executing
- **Be thorough** - Don't skip steps in the workflow
- **Be accurate** - Verify facts from actual code and documentation
- **Be actionable** - Provide specific technical recommendations
- **Follow standards** - Align with project architectural patterns
- **Branded HTML output (opt-in)** - Append `--html` (or say "as HTML" / "branded HTML") to any report-generating command to additionally produce an Astucia AI™ branded HTML companion file alongside the Markdown report. Templates live in `templates/reports/html/`; per-command render steps and placeholders are documented in each command file.

---

**Last Updated:** 2025-10-09
**Role:** System Architect
