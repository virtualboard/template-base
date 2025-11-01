# Generate Component (GC)

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
