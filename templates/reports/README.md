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

Templates use a small Mustache-style convention rendered by `vb report render`.
The agent supplies a JSON data file; the CLI resolves includes, validates values,
and escapes them for their HTML, attribute, CSS, or JavaScript context.

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
- Every referenced scalar must be supplied, including optional slots: use `""`
  or `null` for empty text and `[]` for an empty list. Missing values are errors.

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
| `{{REPORT_TITLE_HTML}}` | Plain text, or an explicitly trusted HTML fragment |
| `{{REPORT_SUBTITLE}}` | Hero lead paragraph (text or explicitly trusted HTML) |
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

## Render a report

Write a JSON object with uppercase placeholder names. Lists contain objects;
item fields override parent fields. Keep numbers and booleans as native JSON
values. Supply `RISKS_JSON` and `FINDINGS_JSON` as JSON arrays or objects, not
serialized strings: the renderer serializes and escapes inline script data.
Duplicate keys, invalid list shapes, and missing referenced fields are errors.

```json
{
  "REPORT_TITLE": "Weekly progress",
  "REPORT_TITLE_HTML": {"html": "Weekly <span class=\"green\">progress</span>"},
  "HERO_META_CELLS": [{"LABEL": "Owner", "VALUE": "Team"}],
  "IN_PROGRESS": [],
  "KPI_TOTAL": 0
}
```

This illustrates the value types; a full template needs its remaining fields.
The complete [progress example](examples/pm-progress-report.data.json) is runnable:

```bash
vb report render --template pm-progress-report.html \
  --data .virtualboard/templates/reports/examples/pm-progress-report.data.json \
  --output .virtualboard/reports/progress.html --allow-html
```

`--template` is relative to `.virtualboard/templates/reports/html`; override the
catalog with `--template-dir PATH`. Includes are relative to that directory and
cannot escape it, including through symlinks. Cycles, excessive nesting, and
oversized input/output are rejected. HTML comments documenting placeholders are
omitted. Rendering does not add a timestamp: supply dates in the data for
reproducible output.

Strings are always escaped, including fields named `*_HTML`. To include reviewed
markup, annotate that value as `{"html":"<p>Reviewed content</p>"}` and pass
`--allow-html`. This permits active HTML, so only annotate fragments you intend
to execute/display as markup. Templates themselves are trusted source files.
Default brand text and the base64 raster logo are loaded automatically; branding
fields may be overridden. SVG and non-image data URLs are refused as logos.

`--dry-run` validates and reports the planned output without creating files.
`--json` returns the output path, byte count, and dry-run flag. Existing output
requires `--force`; failed rendering preserves the previous report. Do not use
a template or data file as the output destination.

Keep the Markdown report as the primary deliverable, derive both formats from
the same findings, and list both paths in the final reply. Inspect generated HTML
before sharing; rendering validates structure and escaping, not the truth of
its findings.

## Adding a new report template

1. Pick a slug: `<role>-<short-name>.html` (e.g., `qa-test-plan.html`).
2. Start by copying `_base/report.html` and writing per-template placeholders
   into `{{MAIN_CONTENT}}`.
3. Add a comment block at the top listing every placeholder the agent must
   compute, so the agent prompt can reference it.
4. Author `examples/<slug>.data.json` with representative populated lists.
   Render it with the CLI and inspect the result as a visual regression target.
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
