# Generate Full Feature (GFF)

**Trigger Phrases:**
- "Generate Full Feature"
- "GFF"
- "Create full-stack feature"
- "Scaffold feature"
- "New feature end-to-end"

**Action:**
When the Fullstack Developer agent receives this command, it should:

## 1. Analyze Feature Spec
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
