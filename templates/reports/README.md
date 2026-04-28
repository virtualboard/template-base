# Branded HTML Report Templates

This directory holds the HTML templates VirtualBoard agent commands use to produce
branded HTML reports alongside their Markdown output. The visual identity is the
**Astucia AI™** dark theme (palette `#0A0A0A` / `#22C55E`) used in `reports/`.

## Directory layout

```
templates/reports/
├── README.md                       # this file
├── html/
│   ├── _partials/
│   │   ├── head.html               # <!doctype>, <head>, full <style>
│   │   ├── topnav.html             # Sticky brand bar
│   │   ├── footer.html             # Branded footer
│   │   ├── back-to-top.html        # Floating button + scroll script
│   │   └── astucia-logo.b64.txt    # JPEG data URI (single source of truth)
│   ├── _base/
│   │   └── report.html             # Skeleton that {{INCLUDE}}s the partials
│   └── <role>-<slug>.html          # One template per report-generating command
└── examples/
    └── <slug>.example.html         # Filled-in samples for visual reference
```

## Placeholder syntax

Templates use a tiny Mustache-style convention. The agent does the substitution —
no runtime, no build step, no dependency.

| Form | Meaning |
|---|---|
| `{{NAME}}` | Replace with a scalar value |
| `{{#LIST}} … {{/LIST}}` | Repeat the inner block once per item; replace inner `{{FIELD}}` per item |
| `{{INCLUDE: _partials/file.html}}` | Inline the contents of another template file |

### Naming rules

- Placeholder names are **uppercase with underscores** (e.g., `{{KPI_TOTAL}}`,
  `{{#TOP_RISKS}}`). This makes them visually distinct from JSX `{}` and
  CSS `{}` so they're collision-safe inside `<style>` and `<script>` blocks.
- An empty list block (`{{#LIST}}…{{/LIST}}` with zero items) renders as nothing.
- An optional scalar with no value renders as the empty string (the agent should
  never leave a literal `{{NAME}}` in the output — see verification below).

## Brand parameterization

Every template uses three brand placeholders so downstream forks can re-skin
without forking the templates:

| Placeholder | Default | Where to override |
|---|---|---|
| `{{BRAND_NAME}}` | `Astucia` | Agent invocation arg / `vb` config |
| `{{BRAND_TAGLINE}}` | `AI Development Studio` | Agent invocation arg / `vb` config |
| `{{BRAND_LOGO_DATAURI}}` | contents of `_partials/astucia-logo.b64.txt` | Path override or inline data URI |

The default values match the existing `reports/` files exactly.

## Cross-cutting placeholders

These are available in every template via `_base/report.html`:

| Placeholder | Description |
|---|---|
| `{{REPORT_TITLE}}` | Plain text — used in `<title>` |
| `{{REPORT_TITLE_HTML}}` | May contain `<span class="green">…</span>` accent slice |
| `{{REPORT_SUBTITLE}}` | Hero lead paragraph (HTML allowed) |
| `{{EYEBROW}}` | Pill text above H1 (e.g. `● Architectural Review · Rev 3`) |
| `{{GENERATED_DATE}}` / `{{GENERATED_DATETIME}}` | `YYYY-MM-DD` / `YYYY-MM-DD HH:MM` |
| `{{AUTHOR_AGENT}}` | E.g. `PM Agent`, `Principal Systems Architect` |
| `{{CLASSIFICATION}}` | E.g. `Internal · Advisory` |
| `{{PROJECT_NAME}}` | Default `VirtualBoard` |
| `{{HERO_META_CELLS}}` | Repeat block — each item: `{LABEL, VALUE}` |
| `{{NAV_LINKS}}` | Anchor list (`<a href="#summary">Summary</a>` …) |
| `{{MAIN_CONTENT}}` | Big slot for the report body — agent emits sections, KPI grids, etc. |
| `{{MATURITY_BAND}}` | Optional block — empty string to omit |
| `{{FOOTER_PRIMARY_LINE}}` | Top line of the footer |
| `{{FOOTER_SECONDARY_LINE}}` | Smaller line below |
| `{{FOOTER_NOTE_BLOCK}}` | Optional `<p>…</p>` for revision-history-style notes |
| `{{EXTRA_SCRIPTS}}` | Optional `<script>` block for table filtering, charts, etc. |

Per-template files extend this with their own placeholders (KPIs, repeating
blocks, narrative slots) — see the comment header at the top of each
`html/<role>-<slug>.html`.

## How an agent renders a template

1. Detect HTML opt-in (`--html` flag, "as HTML" / "branded HTML" suffix, or
   `format: html` in a structured invocation).
2. Read the template file at `templates/reports/html/<role>-<slug>.html`.
3. Resolve every `{{INCLUDE: _partials/<name>.html}}` directive by inlining the
   referenced file. Do this iteratively until no `{{INCLUDE:` markers remain.
4. Substitute `{{BRAND_LOGO_DATAURI}}` with the contents of
   `_partials/astucia-logo.b64.txt`, stripping leading and trailing whitespace.
   (Preserve the data URI bytes exactly — do not re-wrap, re-encode, or insert
   internal line breaks. The file may have a trailing newline added by
   editors/pre-commit hooks; that newline must not appear inside `src="…"`.)
5. Substitute `{{BRAND_NAME}}` and `{{BRAND_TAGLINE}}` with their defaults
   (`Astucia` / `AI Development Studio`) unless the user provided overrides.
6. Substitute every other scalar `{{PLACEHOLDER}}` with the value computed for
   the Markdown report.
7. Expand every `{{#LIST}}…{{/LIST}}` block once per item, substituting the
   inner per-item placeholders.
8. Write the result next to the Markdown file, swapping the `.md` extension for
   `.html`.
9. **Verify**: search the output for any literal `{{` — there should be none.
   If any remain, resolve them (or replace with empty string for known-optional
   slots) before reporting completion.
10. In your final reply, list both the `.md` and `.html` paths.

## JSON-escape rules for inline scripts

Some templates (e.g. the architecture report's filterable risk table) embed a
JSON array inside an inline `<script>` like:

```html
<script>
const RISKS = {{RISKS_JSON}};
</script>
```

When substituting `{{RISKS_JSON}}` you must:

- Emit valid JSON (use `JSON.stringify` or equivalent — never hand-roll).
- Escape any `</` sequence inside string values as `<\/` to prevent the parser
  from prematurely closing the `<script>` tag.
- Do not wrap the value in quotes — the placeholder sits where a JSON
  expression goes, so the substitution is the literal `[…]` array text.

## Adding a new report template

1. Pick a slug: `<role>-<short-name>.html` (e.g., `qa-test-plan.html`).
2. Start by copying `_base/report.html` and writing per-template placeholders
   into `{{MAIN_CONTENT}}`.
3. Add a comment block at the top listing every placeholder the agent must
   compute, so the agent prompt can reference it.
4. Author a filled-in `examples/<slug>.example.html` if it's a high-traffic
   template — this doubles as the visual regression target.
5. Update the relevant `prompts/agents/<role>/*.md` command file with the
   "Optional: Generate Branded HTML Report" block referencing the new template.

## Verification

After rendering, manually open the HTML alongside
`reports/virtualboard-architecture-review-rev3.html` and confirm:

- Identical color palette (look at the green accent and severity chips).
- Logo renders in topnav and footer.
- Sticky topnav blurs over content as you scroll.
- KPI grid wraps cleanly at 800 / 1200 / 1600 px.
- No literal `{{` strings anywhere in the document.

When in doubt, the file `reports/virtualboard-architecture-review-rev3.html` is
the authoritative visual reference.
