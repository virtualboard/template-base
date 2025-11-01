# Generate Accessibility Audit (GAA)

**Trigger Phrases:**
- "Generate Accessibility Audit"
- "GAA"
- "Accessibility check"
- "A11y audit"

**Action:**
When the Frontend Developer agent receives this command, it should:

## 1. Identify Target
- Specific component/page to audit
- Framework and tech stack
- Existing accessibility tooling
- Target WCAG compliance level (A, AA, AAA)

### 2. Run Automated Testing
Perform automated checks using available tools:

**axe-core (Recommended):**
```bash
# Install
npm install --save-dev @axe-core/cli

# Run audit
npx axe https://localhost:3000/component --tags wcag2a,wcag2aa
```

**pa11y:**
```bash
# Install
npm install --save-dev pa11y

# Run audit
npx pa11y http://localhost:3000/component --standard WCAG2AA
```

**Lighthouse:**
```bash
# Run Lighthouse accessibility audit
npx lighthouse http://localhost:3000 --only-categories=accessibility --output=json --output-path=./accessibility-report.json
```

### 3. Manual Testing Checklist
Create a manual testing checklist covering:

**Keyboard Navigation:**
- [ ] All interactive elements accessible via Tab
- [ ] Tab order is logical
- [ ] Focus indicators visible
- [ ] No keyboard traps
- [ ] Skip links present for navigation
- [ ] Escape key closes modals/dropdowns

**Screen Reader Testing:**
- [ ] All images have alt text
- [ ] Headings in logical order (h1-h6)
- [ ] Form labels properly associated
- [ ] ARIA labels for icon buttons
- [ ] Announcements for dynamic content
- [ ] Table headers properly marked

**Color & Contrast:**
- [ ] Text contrast ratio ≥ 4.5:1 (normal text)
- [ ] Large text contrast ratio ≥ 3:1
- [ ] UI component contrast ratio ≥ 3:1
- [ ] Information not conveyed by color alone
- [ ] Focus indicators have sufficient contrast

**Semantic HTML:**
- [ ] Proper heading hierarchy
- [ ] Landmarks (header, nav, main, footer)
- [ ] Lists use ul/ol/li
- [ ] Buttons vs links used appropriately
- [ ] Form inputs have labels

**Dynamic Content:**
- [ ] ARIA live regions for updates
- [ ] Loading states announced
- [ ] Error messages associated with fields
- [ ] Modal focus management
- [ ] Route changes announced

### 4. Generate Audit Report
Create comprehensive report using this template:

```markdown
# Accessibility Audit Report

**Component/Page:** [Name]
**Date:** [Date]
**Auditor:** Claude Frontend Developer Agent
**WCAG Level Target:** [A/AA/AAA]

## Executive Summary
- **Total Issues:** [Number]
- **Critical:** [Number]
- **Serious:** [Number]
- **Moderate:** [Number]
- **Minor:** [Number]

## Automated Test Results

### axe-core Results
- **Violations:** [Number]
- **Passes:** [Number]

### pa11y Results
- **Errors:** [Number]
- **Warnings:** [Number]

### Lighthouse Score
- **Accessibility Score:** [0-100]

## Detailed Findings

### Critical Issues (Must Fix)
1. **[Issue Title]**
   - **Impact:** [Description]
   - **WCAG Criteria:** [e.g., 1.4.3 Contrast (Minimum)]
   - **Location:** [Component/Line]
   - **Current State:** [What's wrong]
   - **Remediation:**
     ```typescript
     // Before
     <button>❌</button>

     // After
     <button aria-label="Close dialog">❌</button>
     ```
   - **Priority:** Critical
   - **Effort:** [Low/Medium/High]

### Serious Issues
[Same format as Critical]

### Moderate Issues
[Same format as Critical]

### Minor Issues
[Same format as Critical]

## Manual Testing Results

### Keyboard Navigation
- [✅/❌] Tab order
- [✅/❌] Focus visibility
- [✅/❌] No traps
- **Notes:** [Details]

### Screen Reader (NVDA/JAWS/VoiceOver)
- [✅/❌] Content readable
- [✅/❌] Images described
- [✅/❌] Forms usable
- **Notes:** [Details]

### Color & Contrast
- [✅/❌] Sufficient contrast
- [✅/❌] No color-only information
- **Notes:** [Details]

## Recommendations

### Quick Wins (< 1 hour)
1. [Action item]
2. [Action item]

### Short-term (1-4 hours)
1. [Action item]
2. [Action item]

### Long-term (> 4 hours)
1. [Action item]
2. [Action item]

## Testing Tools Used
- axe-core v[version]
- pa11y v[version]
- Lighthouse v[version]
- Manual testing with [Screen reader name]

## Compliance Status
- **WCAG 2.1 Level A:** [Pass/Fail] ([X]% compliant)
- **WCAG 2.1 Level AA:** [Pass/Fail] ([X]% compliant)
- **WCAG 2.1 Level AAA:** [Pass/Fail] ([X]% compliant)

## Next Steps
1. [Priority action]
2. [Priority action]
3. Schedule follow-up audit after fixes
```

### 5. Create Testing Integration
Add automated accessibility tests to the project:

**React Testing Library + jest-axe:**
```typescript
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import { ComponentName } from './ComponentName';

expect.extend(toHaveNoViolations);

describe('ComponentName - Accessibility', () => {
  it('should have no accessibility violations', async () => {
    const { container } = render(<ComponentName />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should support keyboard navigation', () => {
    const { getByRole } = render(<ComponentName />);
    const button = getByRole('button');
    button.focus();
    expect(button).toHaveFocus();
  });

  it('should have proper ARIA labels', () => {
    const { getByLabelText } = render(<ComponentName />);
    expect(getByLabelText('Descriptive label')).toBeInTheDocument();
  });
});
```

**Cypress Accessibility Tests:**
```typescript
describe('Component Accessibility', () => {
  beforeEach(() => {
    cy.visit('/component');
    cy.injectAxe();
  });

  it('has no detectable a11y violations', () => {
    cy.checkA11y();
  });

  it('supports keyboard navigation', () => {
    cy.get('body').tab();
    cy.focused().should('have.attr', 'data-testid', 'first-focusable');
  });
});
```

### 6. Announce Completion
- Provide summary of issues found (count by severity)
- Share report file location
- Highlight critical issues requiring immediate attention
- Provide estimated effort for remediation
- Suggest next steps and testing schedule
