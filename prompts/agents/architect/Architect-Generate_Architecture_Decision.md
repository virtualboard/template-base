# Generate Architecture Decision (GAD)

**Trigger Phrases:**
- "Generate Architecture Decision"
- "GAD"
- "Document architecture decision"
- "Create ADR"
- "Architecture Decision Record"

**Action:**
When the Architect agent receives this command, it should:

## 1. Gather Context
- Identify the architectural decision that needs documentation
- Review relevant code, features, and system design
- Understand the problem/challenge being addressed
- Identify stakeholders affected by the decision

### 2. Analyze Options
- List at least 2-3 alternative approaches considered
- Document pros and cons for each option
- Consider: performance, scalability, maintainability, cost, complexity
- Note any constraints or requirements

### 3. Document Decision
- Create an ADR file at `.virtualboard/architecture/decisions/ADR-{NNNN}-{title-slug}.md`
- Use the following structure:

```markdown
# ADR-{NNNN}: {Decision Title}

**Status:** Proposed | Accepted | Deprecated | Superseded
**Date:** {YYYY-MM-DD}
**Deciders:** {List of people/roles involved}
**Technical Story:** {Link to related feature/issue if applicable}

---

## Context and Problem Statement

{Describe the context and problem statement, e.g., in free form using two to three sentences. You may want to articulate the problem in form of a question.}

## Decision Drivers

* {decision driver 1, e.g., a force, facing concern, …}
* {decision driver 2}
* {decision driver 3}
* …

## Considered Options

* {option 1}
* {option 2}
* {option 3}
* …

## Decision Outcome

**Chosen option:** "{option X}", because {justification. e.g., only option that meets key drivers, best trade-off, etc.}

### Positive Consequences

* {e.g., improvement of quality attribute satisfaction, follow-up decisions required, …}
* …

### Negative Consequences

* {e.g., compromising quality attribute, follow-up decisions required, …}
* …

## Pros and Cons of the Options

### {option 1}

* **Good**, because {argument a}
* **Good**, because {argument b}
* **Bad**, because {argument c}
* …

### {option 2}

* **Good**, because {argument a}
* **Good**, because {argument b}
* **Bad**, because {argument c}
* …

### {option 3}

* **Good**, because {argument a}
* **Good**, because {argument b}
* **Bad**, because {argument c}
* …

## Links

* {Link to related ADRs}
* {Link to relevant documentation}
* {Link to technical spike or POC}

---

**Last Updated:** {YYYY-MM-DD}
```

### 4. Create Directory if Needed
- Ensure `.virtualboard/architecture/decisions/` exists
- Use `mkdir -p` to create if necessary
- Maintain sequential numbering for ADRs

### 5. Announce Completion
- Inform the user that the ADR has been created
- Provide the file path
- Summarize the decision and its rationale

---

## Optional: Generate Branded HTML Report

If the user requests `--html`, "as HTML"/"branded HTML", or `format: html`,
write the Markdown deliverable first, then render an additional HTML report.

1. Read `templates/reports/html/architect-adr.html`. Its comment header lists the
   scalar fields and list-item shapes. Use the same findings and measurements
   as the Markdown report; do not invent values for unknown results.
2. Write a companion JSON data file with uppercase field names, native numbers,
   and arrays of objects for lists. Include every referenced field; use `""`,
   `null`, or `[]` for explicitly empty values. The default brand and raster logo
   are provided by the renderer.
3. Run the deterministic renderer:

   ```bash
   vb report render --template architect-adr.html \
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
