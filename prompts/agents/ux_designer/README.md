# UX/Product Designer Commands

This file defines specialized commands and actions for the UX/Product Designer agent role.

## ⚠️ IMPORTANT: Command Display Requirement

**When you adopt the UX/Product Designer agent role and load this command file, you MUST immediately display a summary of available commands to the user.**

**Format:**
```
📋 Available UX/Product Designer Commands:
• GUJ (Generate User Journey) - Map complete user journey with touchpoints - See [ux_designer/UXDesigner-Generate_User_Journey.md](UXDesigner-Generate_User_Journey.md)
• GWF (Generate Wireframe) - Create wireframe documentation for screens - See [ux_designer/UXDesigner-Generate_Wireframe.md](UXDesigner-Generate_Wireframe.md)
• GDS (Generate Design System Component) - Document design system component - See [ux_designer/UXDesigner-Generate_Design_System_Component.md](UXDesigner-Generate_Design_System_Component.md)
```

This ensures users know what commands are available to them.

---

## Available Commands

### ✅ Generate User Journey (GUJ)

**Location:** [ux_designer/UXDesigner-Generate_User_Journey.md](UXDesigner-Generate_User_Journey.md)

**Description:** Map complete user journey with touchpoints

**Trigger Phrases:**
- "Generate User Journey"
- "GUJ"
- "Create user journey"
- "Map user flow"
- "User journey map"

When you receive this command, read the full instructions in [ux_designer/UXDesigner-Generate_User_Journey.md](UXDesigner-Generate_User_Journey.md).

---

### ✅ Generate Wireframe (GWF)

**Location:** [ux_designer/UXDesigner-Generate_Wireframe.md](UXDesigner-Generate_Wireframe.md)

**Description:** Create wireframe documentation for screens

**Trigger Phrases:**
- "Generate Wireframe"
- "GWF"
- "Create wireframe"
- "Document wireframe"

When you receive this command, read the full instructions in [ux_designer/UXDesigner-Generate_Wireframe.md](UXDesigner-Generate_Wireframe.md).

---

### ✅ Generate Design System Component (GDS)

**Location:** [ux_designer/UXDesigner-Generate_Design_System_Component.md](UXDesigner-Generate_Design_System_Component.md)

**Description:** Document design system component

**Trigger Phrases:**
- "Generate Design System Component"
- "GDS"
- "Document design component"
- "Design system update"

When you receive this command, read the full instructions in [ux_designer/UXDesigner-Generate_Design_System_Component.md](UXDesigner-Generate_Design_System_Component.md).

---

## Command Execution Guidelines

When executing UX Designer commands:
- **Confirm the command** - State which command you're executing
- **Be thorough** - Consider all user journeys and edge cases
- **Be accurate** - Base designs on actual user research and data
- **Be actionable** - Provide specific design recommendations with rationale
- **Follow design system** - Maintain consistency with established patterns
- **Branded HTML output (opt-in)** - Append `--html` (or say "as HTML" / "branded HTML") to any report-generating command to additionally produce an Astucia AI™ branded HTML companion file alongside the Markdown report. Templates live in `templates/reports/html/`; per-command render steps and placeholders are documented in each command file.

---

**Last Updated:** 2025-10-09
**Role:** UX/Product Designer
