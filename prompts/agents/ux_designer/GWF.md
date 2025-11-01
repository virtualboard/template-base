# Generate Wireframe (GWF)

**Trigger Phrases:**
- "Generate Wireframe"
- "GWF"
- "Create wireframe"
- "Document wireframe"

**Action:**
When the UX/Product Designer agent receives this command, it should:

## 1. Identify Screens
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
