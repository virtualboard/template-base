# System Architect Commands

This file defines specialized commands and actions for the System Architect agent role.

## ⚠️ IMPORTANT: Command Display Requirement

**When you adopt the Architect agent role and load this command file, you MUST immediately display a summary of available commands to the user.**

**Format:**
```
📋 Available Architect Commands:
• GAD (Generate Architecture Decision) - Document architectural decisions with ADR format - See [architect/GAD.md](GAD.md)
• GAR (Generate Architecture Report) - Create architecture analysis reports - See [architect/GAR.md](GAR.md)
• GTD (Generate Technical Debt Report) - Analyze and prioritize technical debt - See [architect/GTD.md](GTD.md)
```

This ensures users know what commands are available to them.

---

## Available Commands

### ✅ Generate Architecture Decision (GAD)

**Location:** [architect/GAD.md](GAD.md)

**Description:** Document architectural decisions with ADR format

**Trigger Phrases:**
- "Generate Architecture Decision"
- "GAD"
- "Document architecture decision"
- "Create ADR"
- "Architecture Decision Record"

When you receive this command, read the full instructions in [architect/GAD.md](GAD.md).

---

### ✅ Generate Architecture Report (GAR)

**Location:** [architect/GAR.md](GAR.md)

**Description:** Create architecture analysis reports

**Trigger Phrases:**
- "Generate Architecture Report"
- "GAR"
- "Create architecture report"
- "Architecture analysis"

When you receive this command, read the full instructions in [architect/GAR.md](GAR.md).

---

### ✅ Generate Technical Debt Report (GTD)

**Location:** [architect/GTD.md](GTD.md)

**Description:** Analyze and prioritize technical debt

**Trigger Phrases:**
- "Generate Technical Debt Report"
- "GTD"
- "Analyze technical debt"
- "Technical debt analysis"

When you receive this command, read the full instructions in [architect/GTD.md](GTD.md).

---

## Command Execution Guidelines

When executing Architect commands:
- **Confirm the command** - State which command you're executing
- **Be thorough** - Don't skip steps in the workflow
- **Be accurate** - Verify facts from actual code and documentation
- **Be actionable** - Provide specific technical recommendations
- **Follow standards** - Align with project architectural patterns

---

**Last Updated:** 2025-10-09
**Role:** System Architect
