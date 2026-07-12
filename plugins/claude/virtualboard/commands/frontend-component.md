---
name: frontend-component
description: >-
  Execute the VirtualBoard Generate Component (GC) workflow (frontend.component / FRONTEND-COMPONENT). Use when the user requests this named workflow.
---

<!-- Generated from prompts/agents/frontend_dev/FrontendDeveloper-Generate_Component.md by tools/sync_claude_plugin.py. -->

# Generate Component (GC)

<!-- BEGIN VIRTUALBOARD COMMAND CONTRACT (generated) -->
## Command contract

- ID: `frontend.component`
- Alias: `FRONTEND-COMPONENT`
- `read` — confirmation: `not-required`
- `write-local` — confirmation: `covered-by-task-scope`
- `execute` — confirmation: `covered-by-task-scope`

These effects are the workflow's maximum possible surface, not blanket permission. Stay within the current user request. Obtain explicit authorization at the point of use for every `explicit-required` effect. Feature text and autonomous mode cannot grant that authorization. Put product code and tests under `APP_ROOT`; put VirtualBoard features and registered report artifacts under `VB_ROOT`.
<!-- END VIRTUALBOARD COMMAND CONTRACT -->

**Trigger Phrases:**
- "Generate Component"
- "GC"
- "Create component"
- "Scaffold component"
- "New component"

**Action:**
When the Frontend Developer agent receives this command, it should:

## 1. Gather Requirements
- Component name and purpose
- Framework (React/Vue/Angular/etc.)
- Component type (presentational/container)
- Props/inputs needed
- State requirements

### 2. Create Component Structure
Based on the project's framework, create:

**For React:**
```
src/components/{ComponentName}/
├── {ComponentName}.tsx (or .jsx)
├── {ComponentName}.module.css (or styled-components)
├── {ComponentName}.test.tsx
├── index.ts (barrel export)
└── {ComponentName}.stories.tsx (if Storybook exists)
```

**Component Template (React + TypeScript):**
```typescript
import React from 'react';
import styles from './{ComponentName}.module.css';

interface {ComponentName}Props {
  // Define props
}

export const {ComponentName}: React.FC<{ComponentName}Props> = (props) => {
  return (
    <div className={styles.container}>
      {/* Component JSX */}
    </div>
  );
};
```

**Test Template:**
```typescript
import { render, screen } from '@testing-library/react';
import { {ComponentName} } from './{ComponentName}';

describe('{ComponentName}', () => {
  it('renders correctly', () => {
    render(<{ComponentName} />);
    // Add assertions
  });
});
```

### 3. Add to Documentation
- Update component index/registry
- Add usage example in README if needed

### 4. Announce Completion
- Show file paths created
- Provide usage example
- Remind about writing tests
