# Frontend Developer Commands

This file defines specialized commands and actions for the Frontend Developer agent role.

## ⚠️ IMPORTANT: Command Display Requirement

**When you adopt the Frontend Developer agent role and load this command file, you MUST immediately display a summary of available commands to the user.**

**Format:**
```
📋 Available Frontend Developer Commands:
• GC (Generate Component) - Scaffold a new React/Vue/Angular component with tests
• GCS (Generate Component Story) - Create Storybook story for a component
• GAA (Generate Accessibility Audit) - Check component for a11y compliance
```

This ensures users know what commands are available to them.

---

## Generate Component (GC)

**Trigger Phrases:**
- "Generate Component"
- "GC"
- "Create component"
- "Scaffold component"
- "New component"

**Action:**
When the Frontend Developer agent receives this command, it should:

### 1. Gather Requirements
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

---

## Generate Component Story (GCS)

**Trigger Phrases:**
- "Generate Component Story"
- "GCS"
- "Create Storybook story"
- "Add story"

**Action:**
[To be defined - coming soon]

---

## Generate Accessibility Audit (GAA)

**Trigger Phrases:**
- "Generate Accessibility Audit"
- "GAA"
- "Accessibility check"
- "A11y audit"

**Action:**
[To be defined - coming soon]

---

## Command Execution Guidelines

When executing Frontend commands:
- **Confirm the command** - State which command you're executing
- **Be thorough** - Follow accessibility and responsive design standards
- **Be accurate** - Test in multiple browsers/devices when applicable
- **Be actionable** - Provide specific UI/UX improvements
- **Follow design system** - Maintain consistency with project standards

---

**Last Updated:** 2025-10-09
**Role:** Frontend Developer
