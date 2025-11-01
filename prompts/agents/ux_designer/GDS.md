# Generate Design System Component (GDS)

**Trigger Phrases:**
- "Generate Design System Component"
- "GDS"
- "Document design component"
- "Design system update"

**Action:**
When the UX/Product Designer agent receives this command, it should:

## 1. Analyze System Needs
- Review existing UI components
- Identify design patterns in use
- Determine brand requirements
- List component library needs

### 2. Define Design Foundations
- Typography scale and hierarchy
- Color palette and usage
- Spacing/sizing system
- Grid system and breakpoints
- Elevation/shadow system
- Border radius/styling
- Animation/transition standards

### 3. Create Design System Document
Create design system at `.virtualboard/design/systems/DS-{project-name}.md`:

```markdown
# Design System: {Project Name}

**Version:** 1.0.0
**Created:** {YYYY-MM-DD}
**Last Updated:** {YYYY-MM-DD}

---

## Brand Identity

### Brand Colors
```json
{
  "primary": {
    "50": "#e3f2fd",
    "100": "#bbdefb",
    "500": "#2196f3",
    "700": "#1976d2",
    "900": "#0d47a1"
  },
  "secondary": {
    "50": "#f3e5f5",
    "500": "#9c27b0",
    "900": "#4a148c"
  },
  "neutral": {
    "0": "#ffffff",
    "50": "#fafafa",
    "100": "#f5f5f5",
    "500": "#9e9e9e",
    "900": "#212121",
    "1000": "#000000"
  },
  "semantic": {
    "success": "#4caf50",
    "warning": "#ff9800",
    "error": "#f44336",
    "info": "#2196f3"
  }
}
```

### Color Usage
- **Primary:** Main CTAs, links, active states
- **Secondary:** Secondary actions, accents
- **Neutral:** Text, backgrounds, borders
- **Semantic:** Feedback, status indicators

---

## Typography

### Font Families
```css
--font-primary: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
--font-mono: 'JetBrains Mono', 'Courier New', monospace;
```

### Type Scale
```json
{
  "xs": "0.75rem",    /* 12px */
  "sm": "0.875rem",   /* 14px */
  "base": "1rem",     /* 16px */
  "lg": "1.125rem",   /* 18px */
  "xl": "1.25rem",    /* 20px */
  "2xl": "1.5rem",    /* 24px */
  "3xl": "1.875rem",  /* 30px */
  "4xl": "2.25rem",   /* 36px */
  "5xl": "3rem"       /* 48px */
}
```

### Font Weights
```css
--font-weight-regular: 400;
--font-weight-medium: 500;
--font-weight-semibold: 600;
--font-weight-bold: 700;
```

### Line Heights
```css
--leading-tight: 1.25;
--leading-normal: 1.5;
--leading-relaxed: 1.75;
```

### Text Styles
| Style | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| H1 | 3rem (48px) | 700 | 1.2 | Page titles |
| H2 | 2.25rem (36px) | 700 | 1.3 | Section headers |
| H3 | 1.875rem (30px) | 600 | 1.3 | Sub-sections |
| H4 | 1.5rem (24px) | 600 | 1.4 | Card titles |
| Body Large | 1.125rem (18px) | 400 | 1.6 | Intro text |
| Body | 1rem (16px) | 400 | 1.5 | Standard text |
| Body Small | 0.875rem (14px) | 400 | 1.5 | Secondary text |
| Caption | 0.75rem (12px) | 400 | 1.4 | Labels, metadata |

---

## Spacing System

### Base Unit
8px grid system

### Spacing Scale
```json
{
  "0": "0",
  "1": "0.25rem",  /* 4px */
  "2": "0.5rem",   /* 8px */
  "3": "0.75rem",  /* 12px */
  "4": "1rem",     /* 16px */
  "5": "1.25rem",  /* 20px */
  "6": "1.5rem",   /* 24px */
  "8": "2rem",     /* 32px */
  "10": "2.5rem",  /* 40px */
  "12": "3rem",    /* 48px */
  "16": "4rem",    /* 64px */
  "20": "5rem",    /* 80px */
  "24": "6rem"     /* 96px */
}
```

### Usage Guidelines
- Component padding: 4, 6, 8
- Element spacing: 2, 3, 4
- Section spacing: 8, 12, 16
- Layout margins: 12, 16, 20, 24

---

## Layout System

### Breakpoints
```json
{
  "xs": "0px",      /* Mobile portrait */
  "sm": "640px",    /* Mobile landscape */
  "md": "768px",    /* Tablet */
  "lg": "1024px",   /* Desktop */
  "xl": "1280px",   /* Large desktop */
  "2xl": "1536px"   /* Extra large */
}
```

### Container Widths
```css
--container-sm: 640px;
--container-md: 768px;
--container-lg: 1024px;
--container-xl: 1280px;
```

### Grid System
- 12-column grid
- Gutter: 24px (desktop), 16px (tablet), 12px (mobile)
- Margins: 80px (xl), 40px (lg), 24px (md), 16px (sm)

---

## Elevation System

### Shadow Scale
```css
--shadow-xs: 0 1px 2px 0 rgb(0 0 0 / 0.05);
--shadow-sm: 0 1px 3px 0 rgb(0 0 0 / 0.1);
--shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
--shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
--shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1);
--shadow-2xl: 0 25px 50px -12px rgb(0 0 0 / 0.25);
```

### Elevation Usage
- **xs:** Input borders, subtle dividers
- **sm:** Cards at rest
- **md:** Dropdowns, popovers
- **lg:** Modals, dialogs
- **xl:** Overlays
- **2xl:** Special emphasis

---

## Border System

### Radius
```json
{
  "none": "0",
  "sm": "0.125rem",   /* 2px */
  "base": "0.25rem",  /* 4px */
  "md": "0.375rem",   /* 6px */
  "lg": "0.5rem",     /* 8px */
  "xl": "0.75rem",    /* 12px */
  "2xl": "1rem",      /* 16px */
  "full": "9999px"
}
```

### Border Widths
```css
--border-width-thin: 1px;
--border-width-base: 2px;
--border-width-thick: 4px;
```

---

## Component Library

### Button

**Variants:**
- Primary (filled, high emphasis)
- Secondary (outlined, medium emphasis)
- Tertiary (text, low emphasis)

**Sizes:**
- Small: height 32px, padding 8px 16px, text sm
- Medium: height 40px, padding 10px 20px, text base
- Large: height 48px, padding 12px 24px, text lg

**States:**
- Default
- Hover (darken 10%)
- Active (darken 15%)
- Disabled (opacity 50%, not interactive)
- Loading (spinner, disabled state)

**Example:**
```jsx
<Button variant="primary" size="medium">
  Click Me
</Button>
```

---

### Input Fields

**Types:**
- Text input
- Text area
- Select dropdown
- Checkbox
- Radio button
- Toggle switch

**States:**
- Default
- Focused (border color primary-500)
- Error (border color error)
- Disabled (opacity 50%)
- Success (border color success)

**Specifications:**
- Height: 40px (base)
- Padding: 10px 12px
- Border: 1px solid neutral-300
- Border radius: md (6px)
- Font size: base (16px)

---

### Cards

**Variants:**
- Default (white background, shadow-sm)
- Outlined (border, no shadow)
- Elevated (shadow-md)

**Structure:**
```
+------------------------+
| Header (optional)      |
+------------------------+
| Body                   |
| - Main content         |
+------------------------+
| Footer (optional)      |
+------------------------+
```

**Padding:**
- Compact: 16px
- Default: 24px
- Spacious: 32px

---

### Navigation

**Primary Nav:**
- Height: 64px
- Background: primary-900 or white
- Logo: left aligned
- Menu items: right aligned
- Mobile: hamburger menu <768px

**Secondary Nav:**
- Height: 48px
- Background: neutral-50
- Tabs or breadcrumbs

---

### Modals/Dialogs

**Sizes:**
- Small: 400px max-width
- Medium: 600px max-width
- Large: 800px max-width
- Full: 95vw max-width

**Structure:**
- Backdrop: rgba(0,0,0,0.5)
- Container: white, shadow-2xl, rounded-xl
- Padding: 24px
- Close button: top-right

---

## Icons

### Icon Set
- Icon library: {Heroicons, Material Icons, etc.}
- Style: {Outlined, Filled, etc.}

### Sizes
```json
{
  "xs": "16px",
  "sm": "20px",
  "base": "24px",
  "lg": "32px",
  "xl": "48px"
}
```

### Icon Usage
- UI icons: base (24px)
- Button icons: sm (20px)
- Large features: lg (32px)

---

## Animation & Motion

### Duration
```css
--duration-fast: 150ms;
--duration-base: 200ms;
--duration-slow: 300ms;
--duration-slower: 500ms;
```

### Easing
```css
--ease-in: cubic-bezier(0.4, 0, 1, 1);
--ease-out: cubic-bezier(0, 0, 0.2, 1);
--ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
```

### Common Animations
- Hover effects: duration-fast
- Dropdowns/tooltips: duration-base
- Modals/drawers: duration-slow
- Page transitions: duration-slower

---

## Accessibility Guidelines

### Color Contrast
- Text on background: minimum 4.5:1 (WCAG AA)
- Large text (18px+): minimum 3:1
- UI components: minimum 3:1

### Focus States
- Visible focus ring: 2px solid primary-500
- Offset: 2px
- Never remove focus indicators

### Keyboard Navigation
- All interactive elements must be keyboard accessible
- Logical tab order
- Escape key closes modals/dropdowns

### Screen Readers
- Semantic HTML elements
- ARIA labels where needed
- Alt text for images
- Skip navigation links

---

## Design Tokens (CSS Variables)

```css
:root {
  /* Colors */
  --color-primary: #2196f3;
  --color-secondary: #9c27b0;
  --color-success: #4caf50;
  --color-error: #f44336;
  --color-text: #212121;
  --color-text-secondary: #757575;
  --color-bg: #ffffff;
  --color-bg-secondary: #f5f5f5;

  /* Typography */
  --font-primary: 'Inter', sans-serif;
  --font-size-base: 1rem;
  --font-weight-normal: 400;
  --font-weight-bold: 700;

  /* Spacing */
  --spacing-unit: 8px;
  --spacing-xs: calc(var(--spacing-unit) * 0.5);
  --spacing-sm: var(--spacing-unit);
  --spacing-md: calc(var(--spacing-unit) * 2);
  --spacing-lg: calc(var(--spacing-unit) * 3);
  --spacing-xl: calc(var(--spacing-unit) * 4);

  /* Borders */
  --border-radius: 6px;
  --border-width: 1px;
  --border-color: #e0e0e0;

  /* Shadows */
  --shadow-sm: 0 1px 3px rgba(0,0,0,0.1);
  --shadow-md: 0 4px 6px rgba(0,0,0,0.1);
  --shadow-lg: 0 10px 15px rgba(0,0,0,0.1);
}
```

---

## Implementation Notes

### Technology Stack
- CSS Framework: {Tailwind, CSS Modules, Styled Components, etc.}
- Component Library: {React, Vue, Angular, etc.}
- Design Tool: {Figma, Sketch, Adobe XD}

### File Structure
```
/design-system
  /tokens
    - colors.json
    - typography.json
    - spacing.json
  /components
    - Button.tsx
    - Input.tsx
    - Card.tsx
  /styles
    - global.css
    - variables.css
```

---

## Usage Examples

### Example 1: Primary Button
```jsx
<button
  className="bg-primary-500 text-white px-5 py-2.5 rounded-md
             hover:bg-primary-700 transition-colors duration-200"
>
  Get Started
</button>
```

### Example 2: Card Component
```jsx
<div className="bg-white rounded-lg shadow-md p-6">
  <h3 className="text-xl font-semibold mb-4">Card Title</h3>
  <p className="text-neutral-700">Card content goes here.</p>
</div>
```

### Example 3: Form Input
```jsx
<input
  type="text"
  className="w-full h-10 px-3 border border-neutral-300
             rounded-md focus:border-primary-500 focus:ring-2
             focus:ring-primary-200"
  placeholder="Enter text..."
/>
```

---

## Version History

### v1.0.0 - {YYYY-MM-DD}
- Initial design system release
- Core foundations defined
- Base component library

---

## Resources

- **Figma File:** {Link to design file}
- **Component Storybook:** {Link if available}
- **Design Guidelines:** {Link to detailed docs}
- **Brand Guidelines:** {Link to brand docs}

---

**Maintained by:** {Designer Name}
**Feedback:** {Contact or issue tracker}
```

### 4. Generate Design Tokens File
Create JSON tokens at `.virtualboard/design/systems/design-tokens.json`:

```json
{
  "color": {
    "primary": {
      "50": "#e3f2fd",
      "500": "#2196f3",
      "900": "#0d47a1"
    },
    "neutral": {
      "0": "#ffffff",
      "500": "#9e9e9e",
      "1000": "#000000"
    }
  },
  "spacing": {
    "xs": "4px",
    "sm": "8px",
    "md": "16px",
    "lg": "24px",
    "xl": "32px"
  },
  "typography": {
    "fontFamily": {
      "primary": "Inter, sans-serif",
      "mono": "JetBrains Mono, monospace"
    },
    "fontSize": {
      "xs": "12px",
      "sm": "14px",
      "base": "16px",
      "lg": "18px",
      "xl": "20px"
    }
  },
  "borderRadius": {
    "sm": "2px",
    "base": "4px",
    "md": "6px",
    "lg": "8px",
    "full": "9999px"
  },
  "shadow": {
    "sm": "0 1px 3px rgba(0,0,0,0.1)",
    "md": "0 4px 6px rgba(0,0,0,0.1)",
    "lg": "0 10px 15px rgba(0,0,0,0.1)"
  }
}
```

### 5. Announce Completion
- Provide design system document path
- Share design tokens file location
- List key design foundations established
- Link to design tool files (Figma/Sketch)
- Highlight component patterns defined
