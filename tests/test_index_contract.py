#!/usr/bin/env python3
"""Keep the shared feature index as a main/integration-only derived artifact."""

from __future__ import annotations

import os
import re
import subprocess
import unittest
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FEATURES = ROOT / "features"


def integration_index_gate_enabled() -> bool:
    policy = os.environ.get("VIRTUALBOARD_INDEX_POLICY", "auto")
    if policy == "check":
        return True
    if policy == "skip":
        return False
    if (
        os.environ.get("GITHUB_ACTIONS") == "true"
        and os.environ.get("GITHUB_EVENT_NAME") != "pull_request"
    ):
        return True
    if os.environ.get("GITHUB_REF") == "refs/heads/main":
        return True
    branch = subprocess.run(
        ["git", "branch", "--show-current"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    return branch.returncode == 0 and branch.stdout.strip() == "main"


class FeatureIndexTests(unittest.TestCase):
    def test_mandatory_gate_checks_root_only_on_the_integration_branch(self):
        runner = (ROOT / "tests" / "run.sh").read_text(encoding="utf-8")
        self.assertIn("VIRTUALBOARD_INDEX_POLICY", runner)
        self.assertIn("refs/heads/main", runner)
        self.assertIn("GITHUB_EVENT_NAME", runner)
        self.assertIn('"$VB" --root "$ROOT" index --check', runner)
        self.assertIn('"$VB" --root "$ROOT/examples/demo-project" index --check', runner)

    @unittest.skipUnless(
        integration_index_gate_enabled(),
        "the aggregate index is generated and checked on main/integration only",
    )
    def test_index_contains_every_feature_once_with_current_status(self):
        expected: dict[str, str] = {}
        for path in FEATURES.glob("*/FTR-*.md"):
            match = re.match(r"(FTR-[0-9]{4})-", path.name)
            self.assertIsNotNone(match, path)
            feature_id = match.group(1)
            self.assertNotIn(feature_id, expected, f"duplicate feature ID {feature_id}")
            expected[feature_id] = path.parent.name

        text = (FEATURES / "INDEX.md").read_text(encoding="utf-8")
        rows = re.findall(r"^\| (FTR-[0-9]{4}) \|.*?\| ([a-z-]+) \|", text, re.MULTILINE)
        counts = Counter(feature_id for feature_id, _ in rows)
        self.assertTrue(all(count == 1 for count in counts.values()), counts)
        actual = dict(rows)
        self.assertEqual(expected, actual)
        self.assertIn(f"**Total**: {len(expected)} features", text)


if __name__ == "__main__":
    unittest.main()
