# Fullstack Developer Commands

This file defines specialized commands and actions for the Fullstack Developer agent role.

## ⚠️ IMPORTANT: Command Display Requirement

**When you adopt the Fullstack Developer agent role and load this command file, you MUST immediately display a summary of available commands to the user.**

**Format:**
```
📋 Available Fullstack Developer Commands:
• GFF (Generate Full Feature) - Scaffold complete feature (UI + API + DB)
• GIC (Generate Integration Config) - Set up frontend-backend integration
• GETE (Generate End-to-End Test) - Create E2E test for user flow
```

This ensures users know what commands are available to them.

---

## Generate Full Feature (GFF)

**Trigger Phrases:**
- "Generate Full Feature"
- "GFF"
- "Create full-stack feature"
- "Scaffold feature"
- "New feature end-to-end"

**Action:**
When the Fullstack Developer agent receives this command, it should:

### 1. Analyze Feature Spec
- Read feature from `.virtualboard/features/`
- Identify frontend components needed
- Identify backend endpoints needed
- Identify database schema changes
- Map data flow from UI → API → DB

### 2. Generate Backend Layer
- Create database migrations
- Generate API endpoints with validation
- Create service/business logic layer
- Add backend tests

### 3. Generate Frontend Layer
- Create UI components
- Set up API client/hooks
- Add form validation
- Create component tests

### 4. Create Integration Points
- Configure API base URL
- Set up authentication headers
- Add error handling
- Configure loading states

### 5. Generate E2E Test
- Create test covering full user flow
- Test: UI interaction → API call → DB update → UI update

### 6. Document Feature
- Update API documentation
- Add component usage examples
- Document environment variables needed

### 7. Announce Completion
- List all files created (categorized by layer)
- Provide setup instructions
- Show example usage/demo code

---

## Generate Integration Config (GIC)

**Trigger Phrases:**
- "Generate Integration Config"
- "GIC"
- "Set up integration"
- "Configure API integration"

**Action:**
[To be defined - coming soon]

---

## Generate End-to-End Test (GETE)

**Trigger Phrases:**
- "Generate End-to-End Test"
- "GETE"
- "Create E2E test"
- "E2E test"

**Action:**
[To be defined - coming soon]

---

## Command Execution Guidelines

When executing Fullstack commands:
- **Confirm the command** - State which command you're executing
- **Be thorough** - Cover both frontend and backend aspects
- **Be accurate** - Test entire data flow from UI to database
- **Be actionable** - Provide specific integration improvements
- **Follow patterns** - Maintain consistency across the stack

---

**Last Updated:** 2025-10-09
**Role:** Fullstack Developer
