# Branded HTML Report Templates

VirtualBoard can render an HTML companion next to a Markdown report. Rendering is
performed by `tools/render_report.py`; agents must not implement their own text
substitution. The renderer uses only the Python 3 standard library and provides
strict placeholder checking, allowlisted markup, atomic writes, safe partial
resolution, URL-scheme validation, and context-specific attribute types.

## Directory layout

```text
templates/reports/
├── README.md
├── html/
│   ├── _partials/
│   ├── _base/report.html
│   └── <role>-<report>.html
└── examples/
    └── <role>-<report>.example.html
```

The 21 files directly under `html/` are supported report templates. Partials and
the base skeleton are implementation details used by the renderer.

## Template syntax

| Form | Meaning |
|---|---|
| `{{NAME}}` | Escaped scalar, explicitly trusted HTML, or serialized JSON |
| `{{#LIST}} … {{/LIST}}` | Repeat the block for typed list items |
| `{{INCLUDE: _partials/file.html}}` | Inline a partial beneath the template root |

Placeholder names must be uppercase with underscores. Missing placeholders and
lists are errors; optional values must be supplied explicitly as an empty string
or empty list. This prevents incomplete reports from appearing successful.

## Typed render data

Render data is a JSON object with seven optional sections:

```json
{
  "scalars": {
    "REPORT_TITLE": "Quarterly <review>",
    "PROJECT_NAME": "Example"
  },
  "html": {
    "REPORT_TITLE_HTML": "Quarterly <span class=\"green\">Review</span>",
    "EXECUTIVE_SUMMARY_HTML": "<p>Trusted, authored markup.</p>"
  },
  "json": {
    "RISKS_JSON": []
  },
  "urls": {
    "PLAYWRIGHT_REPORT_URL": "./html/index.html"
  },
  "numbers": {
    "MATURITY_PERCENT": 72
  },
  "tokens": {
    "SEVERITY": "high"
  },
  "lists": {
    "HERO_META_CELLS": [
      {
        "scalars": {
          "LABEL": "Generated",
          "VALUE": "2026-07-10"
        }
      }
    ]
  }
}
```

`scalars` are HTML-escaped, including quote characters, and are for ordinary text
and non-sensitive attributes. Object and array values are rejected there.

`html` is accepted only for placeholders ending in `_HTML`, `LIST_EMPTY_*`, and a
small renderer allowlist such as `REPORT_TITLE_HTML` and `NAV_LINKS`. Fragments are
parsed and normalized through a conservative element/attribute allowlist. Scripts,
event handlers, inline styles, unsafe links, comments, declarations, unknown tags,
and malformed nesting are rejected. Keep untrusted prose in escaped scalar fields.

`json` is accepted only for placeholders ending in `_JSON`. Values are serialized
by the renderer, and `</` is escaped so data cannot terminate an inline script.
Client-side consumers must still treat every field as text: build nodes with DOM
APIs and assign untrusted values through `textContent`; never concatenate JSON
values into `innerHTML`, `outerHTML`, `insertAdjacentHTML`, or `document.write`.

`urls` is mandatory for placeholders used in `href` or `src`. Only relative URLs,
`http`, `https`, and strictly validated base64 image data URLs are accepted;
protocol-relative and executable schemes are rejected. `numbers` is mandatory for
placeholders inside inline styles, and percent values are range-checked. `tokens`
is mandatory for dynamic `class` and `data-*` values and accepts only identifier
tokens. Supplying one name in multiple typed sections is an error.

Each list item uses the same typed `scalars`/`html`/`json`/`urls`/`numbers`/
`tokens`/`lists` structure. A flat, untyped list item is intentionally invalid.

Do not rely on hand-maintained placeholder comments. Print the executable
manifest for a template before building data:

```bash
python3 tools/render_report.py --template qa-browser-test-summary --describe
```

## Rendering

Run from the VirtualBoard workspace root:

```bash
python3 tools/render_report.py \
  --template pm-progress-report \
  --data /tmp/pm-progress-report.json \
  --output reports/2026-07-10_Project_Progress_Report.html
```

For an installed `.virtualboard` workspace, invoke the renderer through the
resolved workspace root:

```bash
python3 "$VIRTUALBOARD_ROOT/tools/render_report.py" \
  --template pm-progress-report \
  --data /tmp/pm-progress-report.json \
  --output "$VIRTUALBOARD_ROOT/reports/2026-07-10_Project_Progress_Report.html"
```

The Markdown report remains the primary artifact and must be written first. HTML
generation is opt-in through `--html`, “as HTML,” “branded HTML,” or a structured
`format: html` request.

Brand defaults come from the renderer and `_partials/astucia-logo.b64.txt`:

- `BRAND_NAME`: `Astucia`
- `BRAND_TAGLINE`: `AI Development Studio`
- `BRAND_LOGO_DATAURI`: the checked-in data URI

Override the logo through `urls` when required. Brand text remains in `scalars`.

## Security contract

- Feature specs and other project-authored content are untrusted input.
- Use `scalars` for untrusted prose. Use the typed URL, number, token, and JSON
  sections only for their corresponding data types.
- The `html` section is still a presentation feature, not an authority boundary;
  the sanitizer rejects active content and unsafe attributes. `EXTRA_SCRIPTS` is
  not an approved placeholder.
- Include paths must remain below `templates/reports/html`; absolute paths and
  `..` traversal are rejected.
- Unknown input keys, invalid placeholder names, missing values, include cycles,
  and unresolved placeholders fail rendering.
- Output is written atomically so a failed render cannot leave a partial report.

## Adding or changing a template

1. Add or update `html/<role>-<report>.html`.
2. Document its scalar, HTML, JSON, and list placeholders in the header comment.
3. Add a filled example only when it provides useful visual reference.
4. Update the owning workflow prompt to invoke the shared renderer.
5. Run the renderer contract suite:

   ```bash
   python3 -m unittest -v tests/test_report_renderer.py
   ```

The test suite renders every supported template with strict placeholder handling,
checks scalar escaping, rejects accidental raw HTML, protects inline JSON, and
rejects include traversal. JSON-driven widgets additionally receive hostile markup
fixtures and must contain no HTML execution sink. A template is not supported until
this suite passes.

## Visual verification

Automated rendering is required, but layout changes still need a browser check at
mobile and desktop widths. Use the matching file in `templates/reports/examples/`
as an illustrative visual reference. Examples are checked for unresolved
placeholders, broken local resources, and one-to-one template coverage, but the
strict renderer tests—not the hand-filled examples—are the executable contract.
There is no separate ignored report that acts as an undocumented source of truth.
