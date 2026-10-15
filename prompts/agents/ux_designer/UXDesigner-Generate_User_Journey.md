# Generate User Journey (GUJ)

**Trigger Phrases:**
- "Generate User Journey"
- "GUJ"
- "Create user journey"
- "Map user flow"
- "User journey map"

**Action:**
When the UX/Product Designer agent receives this command, it should:

## 1. Define Journey Scope
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

## Optional: Generate Branded HTML Report

If the user requests `--html`, "as HTML"/"branded HTML", or `format: html`,
write the Markdown deliverable first, then render an additional HTML report.

1. Read `templates/reports/html/ux-user-journey.html`. Its comment header lists the
   scalar fields and list-item shapes. Use the same findings and measurements
   as the Markdown report; do not invent values for unknown results.
2. Write a companion JSON data file with uppercase field names, native numbers,
   and arrays of objects for lists. Include every referenced field; use `""`,
   `null`, or `[]` for explicitly empty values. The default brand and raster logo
   are provided by the renderer.
3. Run the deterministic renderer:

   ```bash
   vb report render --template ux-user-journey.html \
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
