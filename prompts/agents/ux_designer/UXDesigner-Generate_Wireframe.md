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

If the user requests `--html`, "as HTML"/"branded HTML", or `format: html`,
write the Markdown deliverable first, then render an additional HTML report.

1. Read `templates/reports/html/ux-wireframe.html`. Its comment header lists the
   scalar fields and list-item shapes. Use the same findings and measurements
   as the Markdown report; do not invent values for unknown results.
2. Write a companion JSON data file with uppercase field names, native numbers,
   and arrays of objects for lists. Include every referenced field; use `""`,
   `null`, or `[]` for explicitly empty values. The default brand and raster logo
   are provided by the renderer.
3. Run the deterministic renderer:

   ```bash
   vb report render --template ux-wireframe.html \
     --data REPORT_DATA.json --output REPORT.html
   ```

   Replace the example paths with paths beside the Markdown deliverable, using
   the same basename for `.md`, `.json`, and `.html`. Includes and repeated
   blocks are resolved by the CLI; do not manually substitute template text.
4. Strings are escaped, including `*_HTML` fields. Annotate reviewed markup as
   `{"html":"<p>Reviewed content</p>"}` and add `--allow-html` only when those
   fragments are intended as markup. Supply `*_JSON` fields as native JSON
   values; the renderer safely serializes them in inline scripts.
5. Validate with `--dry-run` if useful, then inspect the generated HTML. Existing
   output requires `--force`; a rendering error must preserve earlier output.
   If the installed CLI lacks `report render`, report that limitation instead
   of claiming an HTML artifact was produced.
6. List the Markdown and HTML paths in the final reply, with the companion JSON
   path so the report can be reproduced.

See `templates/reports/README.md` for the input contract and the runnable
`templates/reports/examples/pm-progress-report.data.json` for a complete example.
