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

If the user appends `--html`, says "as HTML"/"branded HTML", or sets
`format: html`, also produce an HTML rendering. **Additive** — the Markdown
report is always written first.

1. Load `templates/reports/html/ux-user-journey.html`. The comment block at the top of
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
   `PERSONA`, `GOAL`, `SCENARIO_HTML`, `KPI_STEPS`, `KPI_PAIN_POINTS`, `KPI_OPPORTUNITIES`, `KPI_SUCCESS_RATE`, `PERSONA_DETAIL_HTML`, `PROBLEM_STATEMENT_HTML`, `SUCCESS_DEFINITION_HTML`, `NEXT_STEPS_HTML`.
7. Expand each `{#NAME}…{/NAME}` list block once per item using the
   per-template list placeholders: `HERO_META_CELLS`, `STEPS`, `INSIGHTS`. The per-item field names are
   documented in the template's top comment.
8. For each list, set the matching `LIST_EMPTY_<NAME>` scalar to `""` if the
   list has items, or to a small italic note (e.g.
   `<p class="empty-note">No items.</p>`) if the list is empty.
9. Write the rendered HTML next to the Markdown:
   `.virtualboard/design/journeys/UJ-{name}.html`.
10. **Verify before reporting completion.** Search the rendered output for any
    literal `{` — there must be none. Resolve leftovers (or substitute the
    empty string for known-optional slots) before continuing.
11. In your final reply, list **both** file paths.

A filled-in reference example lives at
`templates/reports/examples/ux-user-journey.example.html`.
