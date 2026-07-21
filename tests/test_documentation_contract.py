#!/usr/bin/env python3
"""Check local documentation links and known contract-drift regressions."""

from __future__ import annotations

import re
import unittest
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlparse


ROOT = Path(__file__).resolve().parents[1]
MARKDOWN_LINK = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")


class LinkParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links: list[str] = []

    def handle_starttag(self, tag, attrs):
        attributes = dict(attrs)
        if tag in {"a", "link"} and "href" in attributes:
            self.links.append(attributes["href"])
        if tag in {"img", "script"} and "src" in attributes:
            self.links.append(attributes["src"])


def local_target(source: Path, raw: str) -> Path | None:
    raw = raw.strip().strip("<>")
    if not raw or raw.startswith("#") or any(token in raw for token in ("{{", "}}", "*")):
        return None
    parsed = urlparse(raw)
    if parsed.scheme or parsed.netloc:
        return None
    path = unquote(parsed.path)
    if not path:
        return None
    if path.startswith("/"):
        return ROOT / path.lstrip("/")
    return source.parent / path


class DocumentationContractTests(unittest.TestCase):
    def test_markdown_local_links_resolve(self):
        failures = []
        for source in sorted(ROOT.rglob("*.md")):
            if ".git" in source.parts or "templates/reports/examples" in str(source):
                continue
            text = source.read_text(encoding="utf-8")
            text = re.sub(r"^```.*?^```\s*$", "", text, flags=re.DOTALL | re.MULTILINE)
            for raw in MARKDOWN_LINK.findall(text):
                target = local_target(source, raw)
                if target is not None and not target.exists():
                    failures.append(f"{source.relative_to(ROOT)} -> {raw}")
        self.assertEqual([], failures, "broken Markdown links:\n" + "\n".join(failures))

    def test_generated_html_local_links_resolve(self):
        failures = []
        sources = list((ROOT / "docs").glob("*.html"))
        sources.extend((ROOT / "templates" / "reports" / "examples").glob("*.html"))
        for source in sorted(sources):
            parser = LinkParser()
            parser.feed(source.read_text(encoding="utf-8"))
            for raw in parser.links:
                target = local_target(source, raw)
                if target is not None and not target.exists():
                    failures.append(f"{source.relative_to(ROOT)} -> {raw}")
        self.assertEqual([], failures, "broken HTML links:\n" + "\n".join(failures))

    def test_report_examples_cover_templates_without_placeholders(self):
        templates = {
            path.stem for path in (ROOT / "templates" / "reports" / "html").glob("*.html")
        }
        examples = {
            path.name.removesuffix(".example.html")
            for path in (ROOT / "templates" / "reports" / "examples").glob("*.example.html")
        }
        self.assertEqual(templates, examples)
        unresolved = []
        for path in (ROOT / "templates" / "reports" / "examples").glob("*.example.html"):
            if "{{" in path.read_text(encoding="utf-8"):
                unresolved.append(str(path.relative_to(ROOT)))
        self.assertEqual([], unresolved)

    def test_historical_self_audit_examples_are_labeled(self):
        for name in (
            "architect-architecture-report.example.html",
            "security-audit.example.html",
        ):
            text = (
                ROOT / "templates" / "reports" / "examples" / name
            ).read_text(encoding="utf-8")
            self.assertIn("Historical sample data:", text, name)
            self.assertIn("do not describe the current release", text, name)

    def test_known_stale_instructions_do_not_return(self):
        files = [
            path
            for path in ROOT.rglob("*.md")
            if ".git" not in path.parts
            and ".state" not in path.parts
            and path.name != "CHANGELOG.md"  # historical releases retain old syntax
            and "templates/reports/examples" not in str(path)
            and "features/" not in str(path)  # feature prose is untrusted data
        ]
        files.append(ROOT / "templates" / "rules.yml")
        forbidden = {
            "Never end your session": "unbounded queue consumption",
            "never end your session": "unbounded queue consumption",
            "vb list": "unsupported CLI command",
            "vb show": "unsupported CLI command",
            "--complexity H": "invalid update syntax/value",
            'vb new "User Authentication" --labels': "unsupported label flag",
            "reports/virtualboard-architecture-review-rev3.html": "missing visual reference",
            "Please select another feature": "unsafe task substitution",
            "find another feature": "unsafe task substitution",
        }
        failures = []
        for path in files:
            text = path.read_text(encoding="utf-8")
            for needle, reason in forbidden.items():
                if needle in text:
                    failures.append(f"{path.relative_to(ROOT)}: {reason}: {needle}")
        self.assertEqual([], failures, "stale documentation:\n" + "\n".join(failures))

    def test_pull_request_templates_do_not_drift(self):
        repository_template = ROOT / ".github" / "pull_request_template.md"
        distributed_template = ROOT / "templates" / "pr-template.md"
        self.assertEqual(
            repository_template.read_text(encoding="utf-8"),
            distributed_template.read_text(encoding="utf-8"),
        )

    def test_generated_docs_keep_index_and_windows_boundaries_honest(self):
        overview = (ROOT / "docs" / "index.html").read_text(encoding="utf-8")
        features = (ROOT / "docs" / "features.html").read_text(encoding="utf-8")
        workflow = (ROOT / "docs" / "workflow.html").read_text(encoding="utf-8")
        self.assertIn("Git Bash or WSL", overview)
        self.assertIn("does not generate or commit", features)
        self.assertIn("Main/integration", features)
        self.assertIn("exact-token release", features)
        self.assertIn("centrally after integration on main", workflow)

    def test_feature_workflows_never_commit_the_shared_aggregate_index(self):
        workflow_sources = (
            ROOT / "AGENTS.md",
            ROOT / "agents" / "RULES.md",
            ROOT / "skills" / "work-on" / "SKILL.md",
            ROOT / "docs" / ".cursor" / "rules" / "virtualboard.mdc",
            ROOT / "docs" / ".opencode" / "skill" / "virtualboard" / "SKILL.md",
            ROOT / "prompts" / "agents" / "pm" / "PM-Generate_Backlog_Grooming.md",
        )
        obsolete = (
            "regenerate `features/index.md`",
            "regenerated index",
            "moved spec and `features/index.md` together",
            "index lifecycle changes with the implementation",
        )
        for path in workflow_sources:
            text = path.read_text(encoding="utf-8").lower()
            with self.subTest(path=path.relative_to(ROOT)):
                self.assertIn("main", text)
                for phrase in obsolete:
                    self.assertNotIn(phrase, text)

    def test_command_prompts_do_not_hardcode_installed_layout(self):
        failures = []
        for path in (ROOT / "prompts" / "agents").rglob("*.md"):
            for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                if ".virtualboard/" in line and ".virtualboard/virtualboard.json" not in line:
                    failures.append(f"{path.relative_to(ROOT)}:{line_number}: {line.strip()}")
        self.assertEqual([], failures, "hardcoded installed-layout paths:\n" + "\n".join(failures))

    def test_documented_feature_mutations_pass_explicit_actor(self):
        roots = [
            ROOT / "README.md",
            ROOT / "AGENTS.md",
            ROOT / "CLAUDE.md",
            ROOT / "agents",
            ROOT / "prompts",
            ROOT / "skills",
            ROOT / "docs" / ".cursor",
            ROOT / "docs" / ".opencode",
        ]
        files: list[Path] = []
        for root in roots:
            files.extend(root.rglob("*.md") if root.is_dir() else [root])
        mutation = re.compile(
            r'"\$VB"\s+--root\s+"\$[A-Z_]+".*\b'
            r'(?:new|move|update|delete|migrate|lock|template\s+apply)\b'
        )
        failures = []
        for path in sorted(set(files)):
            for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                if mutation.search(line) and "--actor" not in line:
                    failures.append(
                        f"{path.relative_to(ROOT)}:{line_number}: {line.strip()}"
                    )
                if (
                    '"$VB"' in line
                    and " validate --fix" in line
                    and "--actor" not in line
                ):
                    failures.append(
                        f"{path.relative_to(ROOT)}:{line_number}: {line.strip()}"
                    )
        self.assertEqual(
            [], failures, "feature mutation examples without --actor:\n" + "\n".join(failures)
        )


if __name__ == "__main__":
    unittest.main()
