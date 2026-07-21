#!/usr/bin/env python3
"""Guard the Cursor and OpenCode payloads installed into application repos."""

from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CURSOR = ROOT / "docs" / ".cursor" / "rules" / "virtualboard.mdc"
OPENCODE = ROOT / "docs" / ".opencode" / "skill" / "virtualboard" / "SKILL.md"


class IntegrationPayloadTests(unittest.TestCase):
    def test_payloads_preserve_contract_safety_boundaries(self):
        for path in (CURSOR, OPENCODE):
            text = path.read_text(encoding="utf-8")
            with self.subTest(path=path.relative_to(ROOT)):
                self.assertIn(".state/bin/vb", text)
                self.assertIn("untrusted", text.lower())
                self.assertIn("explicit authorization", text.lower())
                self.assertIn("review", text)
                self.assertIn("feat/FTR-####-slug", text)
                self.assertIn("remote claim", text.lower())
                self.assertIn("shared-workspace", text.lower())
                self.assertNotIn("vb upgrade", text)
                self.assertNotIn("sudo vb", text)
                self.assertNotIn("find another feature", text.lower())

    def test_cursor_payload_initializes_cli_before_use(self):
        text = CURSOR.read_text(encoding="utf-8")
        assignment = text.index('VB="$VB_ROOT/.state/bin/vb"')
        invocation = text.index('"$VB" --root "$VB_ROOT" validate')
        self.assertLess(assignment, invocation)

    def test_payloads_keep_aggregate_index_central_and_claims_durable(self):
        for path in (CURSOR, OPENCODE):
            text = path.read_text(encoding="utf-8").lower()
            with self.subTest(path=path.relative_to(ROOT)):
                self.assertIn("do not generate", text)
                self.assertIn("main/integration", text)
                self.assertIn("ci checks", text)
                self.assertRegex(text, r"claim\s+commit")
                self.assertIn("implementation_owner", text)
                self.assertIn("exact", text)
                self.assertIn("token", text)
                self.assertIn("--token-only", text)
                self.assertIn("distinct", text)
                self.assertIn("implementation_owner", text)
                self.assertNotIn("regenerate `features/index.md`", text)
                self.assertNotIn("regenerated index", text)

    def test_opencode_payload_version_matches_template(self):
        text = OPENCODE.read_text(encoding="utf-8")
        match = re.search(r"^\s{2}version:\s*(\S+)\s*$", text, re.MULTILINE)
        self.assertIsNotNone(match)
        self.assertEqual((ROOT / "version.txt").read_text().strip(), match.group(1))


if __name__ == "__main__":
    unittest.main()
