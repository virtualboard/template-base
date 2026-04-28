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

---

## Optional: Generate Branded HTML Report

If the user appends `--html`, says "as HTML"/"branded HTML", or sets
`format: html`, also produce an HTML rendering. **Additive** — the Markdown
report is always written first.

1. Load `templates/reports/html/ux-wireframe.html`. The comment block at the top of
   that file lists every placeholder this command must compute, with the same
   names used in the Markdown report.
2. Inline `{INCLUDE: _partials/<name>.html}` directives by reading and
   pasting the referenced files; iterate until no `{INCLUDE:` markers remain.
3. Substitute `{BRAND_LOGO_DATAURI}` with the contents of
   `templates/reports/html/_partials/astucia-logo.b64.txt`, **stripping leading
   and trailing whitespace** (the file may end in a newline that must not
   appear inside `src="…"`).
4. Substitute `{BRAND_NAME}` (default `Astucia`) and `{BRAND_TAGLINE}`
   (default `AI Development Studio`) unless the user provided overrides.
5. Substitute the cross-cutting placeholders (`REPORT_TITLE`,
   `REPORT_TITLE_HTML`, `REPORT_SUBTITLE`, `EYEBROW`, `GENERATED_DATE`,
   `GENERATED_DATETIME`, `AUTHOR_AGENT`, `CLASSIFICATION`, `PROJECT_NAME`,
   `NAV_LINKS`, `FOOTER_PRIMARY_LINE`, `FOOTER_SECONDARY_LINE`,
   `FOOTER_NOTE_BLOCK`, `EXTRA_SCRIPTS`).
6. Substitute the per-template scalar placeholders:
   `SCREEN_NAME`, `FIDELITY`, `DEVICE`, `OVERVIEW_HTML`, `WIREFRAME_HTML`, `INTERACTION_NOTES_HTML`, `ACCESSIBILITY_NOTES_HTML`, `OPEN_QUESTIONS_HTML`.
7. Expand each `{#NAME}…{/NAME}` list block once per item using the
   per-template list placeholders: `HERO_META_CELLS`, `ANNOTATIONS`, `USER_FLOWS`, `STATES`. The per-item field names are
   documented in the template's top comment.
8. For each list, set the matching `LIST_EMPTY_<NAME>` scalar to `""` if the
   list has items, or to a small italic note (e.g.
   `<p class="empty-note">No items.</p>`) if the list is empty.
9. Write the rendered HTML next to the Markdown:
   `.virtualboard/design/wireframes/WF-{feature}.html`.
10. **Verify before reporting completion.** Search the rendered output for any
    literal `{` — there must be none. Resolve leftovers (or substitute the
    empty string for known-optional slots) before continuing.
11. In your final reply, list **both** file paths.

A filled-in reference example lives at
`templates/reports/examples/ux-wireframe.example.html`.
