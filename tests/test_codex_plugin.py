#!/usr/bin/env python3
"""Validate the repo-local Codex plugin without modifying user configuration."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLUGIN = ROOT / "plugins" / "codex" / "virtualboard"
MANIFEST = PLUGIN / ".codex-plugin" / "plugin.json"


class CodexPluginTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        cls.contract = json.loads((ROOT / "virtualboard.json").read_text(encoding="utf-8"))

    def test_manifest_identity_and_version_match_repository(self):
        self.assertEqual("virtualboard", self.manifest["name"])
        self.assertEqual(
            (ROOT / "version.txt").read_text(encoding="utf-8").strip(),
            self.manifest["version"],
        )
        self.assertEqual("MIT", self.manifest["license"])
        self.assertEqual("./skills/", self.manifest["skills"])

    def test_claude_only_component_fields_are_absent(self):
        self.assertFalse({"agents", "commands"} & set(self.manifest))

    def test_declared_skills_are_present_and_valid(self):
        skill_files = sorted((PLUGIN / "skills").glob("*/SKILL.md"))
        expected = self.contract["pluginExpectations"]["codex"]["skills"]
        self.assertEqual(expected, len(skill_files))
        names = []
        for skill_file in skill_files:
            text = skill_file.read_text(encoding="utf-8")
            match = re.match(r"---\n.*?^name:\s*([a-z][a-z0-9-]*)\s*$.*?^---$", text, re.DOTALL | re.MULTILINE)
            self.assertIsNotNone(match, f"invalid skill frontmatter: {skill_file}")
            names.append(match.group(1))
        self.assertEqual(len(names), len(set(names)))

    def test_interface_starter_prompts_are_bounded(self):
        prompts = self.manifest["interface"]["defaultPrompt"]
        self.assertIsInstance(prompts, list)
        self.assertLessEqual(len(prompts), 3)
        self.assertTrue(all(isinstance(prompt, str) and len(prompt) <= 128 for prompt in prompts))

    def test_work_on_skill_preserves_critical_lifecycle_order(self):
        skill = (PLUGIN / "skills" / "work-on" / "SKILL.md").read_text(encoding="utf-8")
        canonical = (ROOT / "skills" / "work-on" / "SKILL.md").read_text(encoding="utf-8")

        def position(pattern: str, start: int = 0) -> int:
            match = re.search(pattern, skill[start:], re.MULTILINE)
            self.assertIsNotNone(match, f"missing lifecycle instruction: {pattern}")
            assert match is not None
            return start + match.start()

        self.assertEqual(canonical, skill)
        self.assertIn('VB="$VB_ROOT/.state/bin/vb"', skill)
        self.assertIn("`AGENT_ID`", skill)
        self.assertNotIn("`VIRTUALBOARD_AGENT_ID`", skill)
        lock = skill.index("Acquire the source-workspace lock")
        branch = skill.index("Derive the immutable slug")
        worktree_root = skill.index('WORKTREE_APP_ROOT="$(git -C "$WORKTREE_DIR"')
        worktree_lock = skill.index(
            'WORKTREE_LOCK_TOKEN=$("$VB" --root "$WORKTREE_VB_ROOT"'
        )
        claim = skill.index('move "$FEATURE_ID" in-progress')
        validation = skill.index('"$VB" --root "$WORKTREE_VB_ROOT" validate', claim)
        claim_commit = position(r"create\s+a\s+dedicated\s+claim", validation)
        implementation = position(r"before\s+reading\s+or\s+changing", claim_commit)
        self.assertLess(lock, branch)
        self.assertLess(branch, worktree_root)
        self.assertLess(worktree_root, worktree_lock)
        self.assertLess(worktree_lock, claim)
        self.assertLess(claim, validation)
        self.assertLess(validation, claim_commit)
        self.assertLess(claim_commit, implementation)
        self.assertIn(
            'lock "$FEATURE_ID" --release --token "$WORKTREE_LOCK_TOKEN"',
            skill,
        )
        self.assertIn(
            'lock "$FEATURE_ID" --release --token "$SOURCE_LOCK_TOKEN"',
            skill,
        )
        self.assertNotIn('"$VB" --root "$WORKTREE_VB_ROOT" index', skill)
        self.assertIn("--token-only", skill)
        self.assertNotIn("python3 -c", skill)
        self.assertIn("no silent\n   solo-review fallback", skill)


if __name__ == "__main__":
    unittest.main()
