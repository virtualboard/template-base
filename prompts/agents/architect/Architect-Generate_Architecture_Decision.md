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

If the user appends `--html`, says "as HTML"/"branded HTML", or sets
`format: html`, also produce an HTML rendering. **Additive** — the Markdown
report is always written first.

1. Load `templates/reports/html/architect-adr.html`. The comment block at the top of
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
   `ADR_NUMBER`, `ADR_TITLE`, `ADR_STATUS`, `ADR_STATUS_CLASS`, `DECISION_DATE`, `DECIDERS`, `SUPERSEDES`, `SUPERSEDED_BY`, `CONTEXT_HTML`, `DECISION_HTML`, `CONSEQUENCES_HTML`, `REFERENCES_HTML`.
7. Expand each `{#NAME}…{/NAME}` list block once per item using the
   per-template list placeholders: `HERO_META_CELLS`, `ALTERNATIVES`, `RELATED_ADRS`. The per-item field names are
   documented in the template's top comment.
8. For each list, set the matching `LIST_EMPTY_<NAME>` scalar to `""` if the
   list has items, or to a small italic note (e.g.
   `<p class="empty-note">No items.</p>`) if the list is empty.
9. Write the rendered HTML next to the Markdown:
   `.virtualboard/architecture/decisions/ADR-{NNNN}-{slug}.html`.
10. **Verify before reporting completion.** Search the rendered output for any
    literal `{` — there must be none. Resolve leftovers (or substitute the
    empty string for known-optional slots) before continuing.
11. In your final reply, list **both** file paths.

A filled-in reference example lives at
`templates/reports/examples/architect-adr.example.html`.
