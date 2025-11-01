# Backend Developer Commands

This file defines specialized commands and actions for the Backend Developer agent role.

## ⚠️ IMPORTANT: Command Display Requirement

**When you adopt the Backend Developer agent role and load this command file, you MUST immediately display a summary of available commands to the user.**

**Format:**
```
📋 Available Backend Developer Commands:
• GAE (Generate API Endpoint) - Scaffold REST/GraphQL endpoint with validation - See [backend_dev/GAE.md](GAE.md)
• GDM (Generate Database Migration) - Create database migration file - See [backend_dev/GDM.md](GDM.md)
• GAD (Generate API Documentation) - Auto-generate OpenAPI/Swagger docs - See [backend_dev/GAD.md](GAD.md)
```

This ensures users know what commands are available to them.

---

## Available Commands

### ✅ Generate API Endpoint (GAE)

**Location:** [backend_dev/GAE.md](GAE.md)

**Description:** Scaffold REST/GraphQL endpoint with validation

**Trigger Phrases:**
- "Generate API Endpoint"
- "GAE"
- "Create API endpoint"
- "Create endpoint"
- "New API route"

When you receive this command, read the full instructions in [backend_dev/GAE.md](GAE.md).

---

### 🚧 Generate Database Migration (GDM)

**Location:** [backend_dev/GDM.md](GDM.md)

**Description:** Create database migration file

**Trigger Phrases:**
- "Generate Database Migration"
- "GDM"
- "Create migration"
- "Database migration"

**Status:** Coming soon - See [backend_dev/GDM.md](GDM.md) for placeholder

---

### 🚧 Generate API Documentation (GAD)

**Location:** [backend_dev/GAD.md](GAD.md)

**Description:** Auto-generate OpenAPI/Swagger docs

**Note:** This is Backend Developer's GAD (Generate API Documentation). For Architecture Decision Records, see Architect's GAD command.

**Trigger Phrases:**
- "Generate API Documentation"
- "GAD"
- "Document API"
- "Create API docs"

**Status:** Coming soon - See [backend_dev/GAD.md](GAD.md) for placeholder

---

## Command Execution Guidelines

When executing Backend commands:
- **Confirm the command** - State which command you're executing
- **Be thorough** - Include proper error handling and validation
- **Be accurate** - Test API endpoints and data flows
- **Be actionable** - Provide specific optimizations or fixes
- **Follow patterns** - Maintain consistency with existing backend architecture

---

**Last Updated:** 2025-10-09
**Role:** Backend Developer
