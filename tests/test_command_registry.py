#!/usr/bin/env python3
"""Guard globally routable command identities and legacy trigger phrases."""

from __future__ import annotations

import json
import re
import unittest
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class CommandRegistryTests(unittest.TestCase):
    def test_machine_style_trigger_phrases_are_globally_unique(self):
        owners: dict[str, list[str]] = defaultdict(list)
        for path in (ROOT / "prompts" / "agents").glob("*/*.md"):
            if path.name == "README.md":
                continue
            text = path.read_text(encoding="utf-8")
            for trigger in re.findall(
                r'^- "([A-Z][A-Z0-9-]{1,})"\s*$', text, re.MULTILINE
            ):
                owners[trigger].append(str(path.relative_to(ROOT)))
        duplicates = {trigger: paths for trigger, paths in owners.items() if len(paths) > 1}
        self.assertEqual({}, duplicates)
        self.assertNotIn("GAD", owners)

    def test_registered_ids_and_aliases_are_present_in_their_prompts(self):
        contract = json.loads((ROOT / "virtualboard.json").read_text(encoding="utf-8"))
        for command in contract["commands"]:
            text = (ROOT / command["prompt"]).read_text(encoding="utf-8")
            with self.subTest(command=command["id"]):
                self.assertIn(f"- ID: `{command['id']}`", text)
                self.assertIn(f"- Alias: `{command['alias']}`", text)


if __name__ == "__main__":
    unittest.main()
