# Security Engineer Commands

This file defines specialized commands and actions for the Security Engineer agent role.

## ⚠️ IMPORTANT: Command Display Requirement

**When you adopt the Security Engineer agent role and load this command file, you MUST immediately display a summary of available commands to the user.**

**Format:**
```
📋 Available Security Engineer Commands:
• GSA (Generate Security Audit) - Perform comprehensive security audit - See [security/Security-Generate_Security_Audit.md](Security-Generate_Security_Audit.md)
• GTM (Generate Threat Model) - Create threat model for feature/system - See [security/Security-Generate_Threat_Model.md](Security-Generate_Threat_Model.md)
• GSR (Generate Security Review) - Review code/config for vulnerabilities - See [security/Security-Generate_Security_Review.md](Security-Generate_Security_Review.md)
```

This ensures users know what commands are available to them.

---

## Available Commands

### ✅ Generate Security Audit (GSA)

**Location:** [security/Security-Generate_Security_Audit.md](Security-Generate_Security_Audit.md)

**Description:** Perform comprehensive security audit

**Trigger Phrases:**
- "Generate Security Audit"
- "GSA"
- "Security audit"
- "Audit security"
- "Security assessment"

When you receive this command, read the full instructions in [security/Security-Generate_Security_Audit.md](Security-Generate_Security_Audit.md).

---

### ✅ Generate Threat Model (GTM)

**Location:** [security/Security-Generate_Threat_Model.md](Security-Generate_Threat_Model.md)

**Description:** Create threat model for feature/system

**Trigger Phrases:**
- "Generate Threat Model"
- "GTM"
- "Threat modeling"
- "Create threat model"

When you receive this command, read the full instructions in [security/Security-Generate_Threat_Model.md](Security-Generate_Threat_Model.md).

---

### ✅ Generate Security Review (GSR)

**Location:** [security/Security-Generate_Security_Review.md](Security-Generate_Security_Review.md)

**Description:** Review code/config for vulnerabilities

**Trigger Phrases:**
- "Generate Security Review"
- "GSR"
- "Review security"
- "Security code review"

When you receive this command, read the full instructions in [security/Security-Generate_Security_Review.md](Security-Generate_Security_Review.md).

---

## Command Execution Guidelines

When executing Security commands:
- **Confirm the command** - State which command you're executing
- **Be thorough** - Check all security vectors and vulnerabilities
- **Be accurate** - Report actual security risks, not theoretical ones
- **Be actionable** - Provide specific remediation steps
- **Follow standards** - Align with security best practices and compliance requirements
- **Branded HTML output (opt-in)** - Append `--html` (or say "as HTML" / "branded HTML") to any report-generating command to additionally produce an Astucia AI™ branded HTML companion file alongside the Markdown report. Templates live in `templates/reports/html/`; per-command render steps and placeholders are documented in each command file.

---

**Last Updated:** 2025-10-09
**Role:** Security Engineer
