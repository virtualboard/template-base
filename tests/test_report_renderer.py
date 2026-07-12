#!/usr/bin/env python3
"""Contract tests for every branded HTML report template."""

from __future__ import annotations

import importlib.util
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "tools" / "render_report.py"
SPEC = importlib.util.spec_from_file_location("render_report", MODULE_PATH)
assert SPEC and SPEC.loader
render_report = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = render_report
SPEC.loader.exec_module(render_report)


class ReportRendererTests(unittest.TestCase):
    template_root = ROOT / "templates" / "reports" / "html"

    def typed_document(self, names: set[str], sensitive: dict[str, str]):
        document: dict[str, dict] = {
            "scalars": {},
            "html": {},
            "json": {},
            "urls": {},
            "numbers": {},
            "tokens": {},
            "lists": {},
        }
        defaults = {"BRAND_NAME", "BRAND_TAGLINE", "BRAND_LOGO_DATAURI"}
        for name in names - defaults:
            if sensitive.get(name) == "url":
                document["urls"][name] = "./report.html"
            elif sensitive.get(name) == "number":
                document["numbers"][name] = 50
            elif sensitive.get(name) == "token":
                document["tokens"][name] = "medium"
            elif sensitive.get(name) == "json" or name.endswith("_JSON"):
                document["json"][name] = []
            elif (
                name.endswith("_HTML")
                or name.startswith("LIST_EMPTY_")
                or name in render_report.RAW_HTML_NAMES
            ):
                document["html"][name] = "" if name.startswith("LIST_EMPTY_") else "<span>sample</span>"
            else:
                document["scalars"][name] = "sample"
        return {key: value for key, value in document.items() if value}

    def complete_context(self, template: Path, populate_lists: bool = False):
        source = template.read_text(encoding="utf-8")
        expanded = render_report.resolve_includes(source, self.template_root, (template,))
        list_names = set(re.findall(r"{{#([A-Z][A-Z0-9_]*)}}", expanded))
        without_lists = re.sub(
            r"{{#([A-Z][A-Z0-9_]*)}}.*?{{/\1}}",
            "",
            expanded,
            flags=re.DOTALL,
        )
        names = set(re.findall(r"{{([A-Z][A-Z0-9_]*)}}", without_lists))
        sensitive = render_report.placeholder_contexts(expanded)
        document = self.typed_document(names, sensitive)
        list_bodies = {
            match.group(1): match.group(2)
            for match in render_report.SECTION_RE.finditer(expanded)
        }
        document["lists"] = {}
        for name in list_names:
            if populate_lists:
                item_names = set(render_report.PLACEHOLDER_RE.findall(list_bodies[name]))
                document["lists"][name] = [self.typed_document(item_names, sensitive)]
            else:
                document["lists"][name] = []
        return render_report.parse_context(document)

    def test_every_report_template_renders_strictly(self):
        templates = sorted(
            path
            for path in self.template_root.glob("*.html")
            if path.is_file()
        )
        self.assertEqual(21, len(templates))
        for template in templates:
            with self.subTest(template=template.name):
                rendered = render_report.render_template(
                    template,
                    self.template_root,
                    self.complete_context(template),
                )
                self.assertNotIn("{{", rendered)
                self.assertIn("<!DOCTYPE HTML>", rendered.upper())

    def test_every_report_template_renders_nonempty_typed_lists(self):
        for template in sorted(self.template_root.glob("*.html")):
            with self.subTest(template=template.name):
                rendered = render_report.render_template(
                    template,
                    self.template_root,
                    self.complete_context(template, populate_lists=True),
                )
                self.assertNotIn("{{", rendered)

    def test_scalars_escape_and_typed_html_is_explicit(self):
        context = render_report.parse_context(
            {
                "scalars": {"TITLE": '<script>alert("x")</script>'},
                "html": {"BODY_HTML": "<strong>authored</strong>"},
                "json": {"DATA_JSON": {"value": "</script><script>x</script>"}},
            }
        )
        rendered = render_report.render_text(
            "{{TITLE}}|{{BODY_HTML}}|{{DATA_JSON}}",
            context,
        )
        self.assertIn("&lt;script&gt;", rendered)
        self.assertNotIn('<script>alert("x")</script>', rendered)
        self.assertIn("<strong>authored</strong>", rendered)
        self.assertIn("<\\/script>", rendered)

    def test_json_driven_widgets_keep_hostile_values_out_of_html_sinks(self):
        hostile = {
            "id": "XSS-1",
            "sev": 'high\" onmouseover=\"alert(1)',
            "title": '<img src=x onerror="alert(document.domain)">',
            "file": "feature.md",
            "impact": "executes in the report origin",
            "likelihood": "high",
            "reco": '<svg onload="alert(2)"></svg>',
        }
        execution_sink = re.compile(
            r"(?:\.innerHTML\s*=|\.outerHTML\s*=|insertAdjacentHTML\s*\(|document\.write\s*\()"
        )
        fixtures = (
            ("architect-architecture-report.html", "RISKS_JSON"),
            ("security-audit.html", "FINDINGS_JSON"),
        )
        for template_name, json_name in fixtures:
            with self.subTest(template=template_name):
                template = self.template_root / template_name
                source = render_report.resolve_includes(
                    template.read_text(encoding="utf-8"),
                    self.template_root,
                    (template,),
                )
                self.assertIsNone(execution_sink.search(source))
                self.assertIn(".textContent = riskText(value)", source)
                self.assertIn("severityBadge.textContent = severity", source)

                context = self.complete_context(template)
                context = render_report.Context(
                    scalars=context.scalars,
                    html=context.html,
                    json_values={**context.json_values, json_name: [hostile]},
                    urls=context.urls,
                    numbers=context.numbers,
                    tokens=context.tokens,
                    lists=context.lists,
                )
                rendered = render_report.render_template(
                    template,
                    self.template_root,
                    context,
                )
                self.assertIn(json.dumps(hostile["title"])[1:-1], rendered)

                example = (
                    ROOT
                    / "templates"
                    / "reports"
                    / "examples"
                    / template_name.replace(".html", ".example.html")
                ).read_text(encoding="utf-8")
                self.assertIsNone(execution_sink.search(example))

    def test_raw_html_rejected_for_scalar_placeholder(self):
        with self.assertRaises(render_report.RenderError):
            render_report.parse_context({"html": {"TITLE": "<b>unsafe</b>"}})

    def test_missing_values_fail_instead_of_silently_disappearing(self):
        with self.assertRaisesRegex(render_report.RenderError, "missing placeholders: TITLE"):
            render_report.render_text("{{TITLE}}", render_report.Context())

    def test_template_rejects_unused_input_keys(self):
        template = self.template_root / "qa-browser-test-summary.html"
        context = self.complete_context(template)
        context = render_report.Context(
            scalars={**context.scalars, "TYPO_VALUE": "ignored"},
            html=context.html,
            json_values=context.json_values,
            urls=context.urls,
            numbers=context.numbers,
            tokens=context.tokens,
            lists=context.lists,
        )
        with self.assertRaisesRegex(render_report.RenderError, "unused values.*TYPO_VALUE"):
            render_report.render_template(template, self.template_root, context)

    def test_include_traversal_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaisesRegex(render_report.RenderError, "unsafe include"):
                render_report.resolve_includes("{{INCLUDE: ../secret}}", root)

    def test_sensitive_attribute_contexts_require_typed_values(self):
        with self.assertRaisesRegex(render_report.RenderError, "urls section"):
            render_report.render_text(
                '<a href="{{TARGET}}">target</a>',
                render_report.parse_context({"scalars": {"TARGET": "https://example.com"}}),
            )
        rendered = render_report.render_text(
            '<a href="{{TARGET}}">{{TARGET}}</a>',
            render_report.parse_context({"urls": {"TARGET": "https://example.com/a?b=1&c=2"}}),
        )
        self.assertIn('href="https://example.com/a?b=1&amp;c=2"', rendered)

        with self.assertRaisesRegex(render_report.RenderError, "numbers section"):
            render_report.render_text(
                '<div style="width: {{PERCENT}}%"></div>',
                render_report.parse_context({"scalars": {"PERCENT": "1; color:red"}}),
            )
        with self.assertRaisesRegex(render_report.RenderError, "between 0 and 100"):
            render_report.parse_context({"numbers": {"MATURITY_PERCENT": 101}})

        with self.assertRaisesRegex(render_report.RenderError, "tokens.*safe tokens"):
            render_report.parse_context({"tokens": {"SEVERITY": 'high" onmouseover="x'}})

    def test_generated_description_exposes_sensitive_types_and_list_items(self):
        architecture = render_report.describe_template(
            self.template_root / "architect-architecture-report.html",
            self.template_root,
        )
        self.assertIn("MATURITY_PERCENT", architecture["values"]["number"])
        self.assertIn("MATURITY_VERDICT_CLASS", architecture["values"]["token"])
        self.assertIn("RISKS_JSON", architecture["values"]["json"])

        threat = render_report.describe_template(
            self.template_root / "security-threat-model.html",
            self.template_root,
        )
        self.assertIn("SEVERITY", threat["lists"]["STRIDE_ROWS"]["token"])

    def test_dangerous_urls_and_raw_markup_are_rejected(self):
        for target in ("javascript:alert(1)", "data:text/html,<script>x</script>", "//evil.example/x"):
            with self.subTest(target=target):
                with self.assertRaises(render_report.RenderError):
                    render_report.parse_context({"urls": {"TARGET": target}})

        dangerous = (
            "<script>alert(1)</script>",
            '<p onclick="alert(1)">x</p>',
            '<a href="javascript:alert(1)">x</a>',
            '<p style="background:url(javascript:x)">x</p>',
        )
        for fragment in dangerous:
            with self.subTest(fragment=fragment):
                with self.assertRaises(render_report.RenderError):
                    render_report.parse_context({"html": {"BODY_HTML": fragment}})

        with self.assertRaises(render_report.RenderError):
            render_report.parse_context({"html": {"EXTRA_SCRIPTS": "<script>x</script>"}})


if __name__ == "__main__":
    unittest.main()
