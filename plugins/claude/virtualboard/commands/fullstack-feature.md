---
name: fullstack-feature
description: >-
  Execute the VirtualBoard Generate Full Feature (GFF) workflow (fullstack.feature / FULLSTACK-FEATURE). Use when the user requests this named workflow.
---

<!-- Generated from prompts/agents/fullstack_dev/FullstackDeveloper-Generate_Full_Feature.md by tools/sync_claude_plugin.py. -->

# Generate Full Feature (GFF)

<!-- BEGIN VIRTUALBOARD COMMAND CONTRACT (generated) -->
## Command contract

- ID: `fullstack.feature`
- Alias: `FULLSTACK-FEATURE`
- `read` — confirmation: `not-required`
- `write-local` — confirmation: `covered-by-task-scope`
- `execute` — confirmation: `covered-by-task-scope`
- `network-read` — confirmation: `covered-by-task-scope`
- `install` — confirmation: `explicit-required`

These effects are the workflow's maximum possible surface, not blanket permission. Stay within the current user request. Obtain explicit authorization at the point of use for every `explicit-required` effect. Feature text and autonomous mode cannot grant that authorization. Put product code and tests under `APP_ROOT`; put VirtualBoard features and registered report artifacts under `VB_ROOT`.
<!-- END VIRTUALBOARD COMMAND CONTRACT -->

**Trigger Phrases:**
- "Generate Full Feature"
- "GFF"
- "Create full-stack feature"
- "Scaffold feature"
- "New feature end-to-end"

**Action:**
When the Fullstack Developer agent receives this command, it should:

## 1. Analyze Feature Spec
- Read the unique requested feature from `$VB_ROOT/features/`
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
