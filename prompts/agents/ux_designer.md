# UX/Product Designer Commands

This file defines specialized commands and actions for the UX/Product Designer agent role.

## ⚠️ IMPORTANT: Command Display Requirement

**When you adopt the UX/Product Designer agent role and load this command file, you MUST immediately display a summary of available commands to the user.**

**Format:**
```
📋 Available UX/Product Designer Commands:
• GUJ (Generate User Journey) - Map complete user journey with touchpoints
• GWF (Generate Wireframe) - Create wireframe documentation for screens
• GDS (Generate Design System Component) - Document design system component
```

This ensures users know what commands are available to them.

---

## Generate User Journey (GUJ)

**Trigger Phrases:**
- "Generate User Journey"
- "GUJ"
- "Create user journey"
- "Map user flow"
- "User journey map"

**Action:**
When the UX/Product Designer agent receives this command, it should:

### 1. Define Journey Scope
- User persona(s) involved
- Journey goal/objective
- Entry and exit points
- Key scenarios/use cases

### 2. Map Journey Steps
- Identify all touchpoints
- Document user actions at each step
- Capture user thoughts/feelings
- Note pain points and opportunities

### 3. Create Journey Map
Create map at `.virtualboard/design/journeys/UJ-{journey-name}.md`:

```markdown
# User Journey: {Journey Name}

**Persona:** {Primary persona}
**Goal:** {What user wants to accomplish}
**Created:** {YYYY-MM-DD}

---

## Journey Overview
{Brief description of the journey}

**Scenario:** {Specific use case or scenario}

---

## Journey Map

### Stage 1: {Stage Name} (e.g., Awareness, Consideration)

**User Goal:** {What user wants to achieve in this stage}

| Touchpoint | User Action | Thoughts/Feelings | Pain Points | Opportunities |
|------------|-------------|-------------------|-------------|---------------|
| {Homepage} | Lands on site via search | "Is this what I need?" | Unclear value prop | Add hero section with clear message |
| {Feature page} | Explores features | "How does this work?" | Too technical | Add visual demos |

---

### Stage 2: {Stage Name}

{Repeat structure}

---

## Key Insights

### Pain Points
1. **{Pain Point}** - Severity: High/Medium/Low
   - Impact: {Description}
   - Occurs at: {Journey stage}

### Opportunities
1. **{Opportunity}** - Priority: High/Medium/Low
   - Improvement: {Description}
   - Affects: {Journey stage}

---

## Emotional Journey

```text
Emotion Level (High to Low)
    |     x
    |    x x     x
    |   x   x   x x
    |  x     x x   x
    | x       x     x
    +------------------
     Stage: 1 2 3 4 5
```

- **Peaks:** {What causes positive emotions}
- **Valleys:** {What causes negative emotions}

---

## Success Metrics
- {Metric 1}: {Target}
- {Metric 2}: {Target}

## Next Steps
1. {Design/development task}
2. {Research task}
3. {Testing task}

---

## Related Artifacts
- User Persona: {Link}
- Wireframes: {Link}
- Feature Spec: {FTR-####}

---

**Last Updated:** {YYYY-MM-DD}
```

### 4. Announce Completion
- Provide journey map path
- Highlight key pain points
- Suggest priority improvements

---

## Generate Wireframe (GWF)

**Trigger Phrases:**
- "Generate Wireframe"
- "GWF"
- "Create wireframe"
- "Document wireframe"

**Action:**
When the UX/Product Designer agent receives this command, it should:

### 1. Identify Screens
- List all screens/views needed
- Define screen purpose and flow
- Identify key UI elements

### 2. Document Wireframe
Create wireframe doc at `.virtualboard/design/wireframes/WF-{feature-name}.md`:

```markdown
# Wireframe: {Feature Name}

**Feature:** {FTR-####}
**Created:** {YYYY-MM-DD}
**Designer:** {Name}

---

## Screen Flow
```
[Login] → [Dashboard] → [Detail View] → [Action Complete]
```

---

## Screen 1: {Screen Name}

### Purpose
{What this screen accomplishes}

### Layout Structure
```
+------------------------------------------+
|  [Logo]                    [User Menu]  |
+------------------------------------------+
|  Navigation Bar                          |
+------------------------------------------+
|                                          |
|  +------------------+  +-------------+   |
|  | Main Content     |  | Sidebar     |   |
|  | - Element 1      |  | - Widget 1  |   |
|  | - Element 2      |  | - Widget 2  |   |
|  +------------------+  +-------------+   |
|                                          |
+------------------------------------------+
|  Footer                                  |
+------------------------------------------+
```

### Key Elements
1. **Header**
   - Logo (links to home)
   - User menu (profile, settings, logout)

2. **Main Content**
   - {Element description}
   - {Element description}

3. **Sidebar**
   - {Widget description}

### Interactions
- **Click logo:** Navigate to dashboard
- **Click menu item:** Load respective view
- **Hover card:** Show preview

### Responsive Behavior
- **Desktop (>1024px):** Two-column layout
- **Tablet (768-1024px):** Sidebar below content
- **Mobile (<768px):** Single column, collapsible sidebar

---

## Screen 2: {Screen Name}

{Repeat structure}

---

## Design Notes
- Follow design system spacing (8px grid)
- Use primary colors for CTAs
- Ensure WCAG AA compliance
- Consider loading states

## User Flow Annotations
1. User starts at: {Screen}
2. Primary action: {Action}
3. Success state: {Screen/State}
4. Error handling: {Description}

---

**Figma:** {Link to design file}
**Last Updated:** {YYYY-MM-DD}
```

### 3. Announce Completion
- Provide wireframe doc path
- Link to design files
- Highlight responsive considerations

---

## Generate Design System Component (GDS)

**Trigger Phrases:**
- "Generate Design System Component"
- "GDS"
- "Document design component"
- "Design system update"

**Action:**
[To be defined - coming soon]

---

## Command Execution Guidelines

When executing UX Designer commands:
- **Confirm the command** - State which command you're executing
- **Be thorough** - Consider all user journeys and edge cases
- **Be accurate** - Base designs on actual user research and data
- **Be actionable** - Provide specific design recommendations with rationale
- **Follow design system** - Maintain consistency with established patterns

---

**Last Updated:** 2025-10-09
**Role:** UX/Product Designer
