#!/usr/bin/env python3
"""Keep claim, lease, and handoff invariants identical across runtimes."""

from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILLS = (
    ROOT / "skills" / "work-on" / "SKILL.md",
    ROOT / "plugins" / "codex" / "virtualboard" / "skills" / "work-on" / "SKILL.md",
    ROOT / "plugins" / "claude" / "virtualboard" / "skills" / "work-on" / "SKILL.md",
)


class WorkOnContractTests(unittest.TestCase):
    def _position(self, text: str, pattern: str, start: int = 0) -> int:
        match = re.search(pattern, text[start:], re.MULTILINE)
        self.assertIsNotNone(match, f"missing workflow invariant: {pattern}")
        assert match is not None
        return start + match.start()

    def test_runtime_skills_are_exact_canonical_copies(self):
        canonical = SKILLS[0].read_bytes()
        for path in SKILLS[1:]:
            with self.subTest(path=path.relative_to(ROOT)):
                self.assertEqual(canonical, path.read_bytes())

        self.assertEqual(
            (ROOT / "skills" / "work-on" / "config.md").read_bytes(),
            (
                ROOT
                / "plugins"
                / "claude"
                / "virtualboard"
                / "skills"
                / "work-on"
                / "config.md"
            ).read_bytes(),
        )

    def test_every_surface_commits_only_the_feature_claim_before_implementation(self):
        for path in SKILLS:
            text = path.read_text(encoding="utf-8")
            with self.subTest(path=path.relative_to(ROOT)):
                claim = text.index('move "$FEATURE_ID" in-progress')
                validation = text.index(
                    '"$VB" --root "$WORKTREE_VB_ROOT" validate', claim
                )
                commit = self._position(
                    text, r"create\s+a\s+dedicated\s+claim", validation
                )
                implementation = text.lower().index("implementation", commit)
                self.assertLess(claim, validation)
                self.assertLess(validation, commit)
                self.assertLess(commit, implementation)

    def test_feature_branches_never_generate_or_commit_the_aggregate_index(self):
        for path in SKILLS:
            text = path.read_text(encoding="utf-8")
            with self.subTest(path=path.relative_to(ROOT)):
                self.assertIn(
                    "Do not generate, stage, or commit `features/INDEX.md`", text
                )
                self.assertNotIn('"$VB" --root "$WORKTREE_VB_ROOT" index', text)
                self.assertIn("main/CI index gate", text)

    def test_every_work_on_surface_requires_a_predeclared_claim_mode(self):
        for path in SKILLS:
            text = path.read_text(encoding="utf-8").lower()
            with self.subTest(path=path.relative_to(ROOT)):
                self.assertIn("shared-workspace", text)
                self.assertIn("before", text[text.index("shared-workspace") :])
                self.assertIn("stop", text)

    def test_every_surface_bounds_feature_discovery_to_lifecycle_directories(self):
        for path in SKILLS:
            text = path.read_text(encoding="utf-8")
            with self.subTest(path=path.relative_to(ROOT)):
                self.assertIn(
                    "lifecycle_statuses=(backlog in-progress blocked review done)",
                    text,
                )
                self.assertIn(
                    'for candidate in "$status_dir"/"$FEATURE_ID"-*.md', text
                )
                self.assertIn('[ -L "$candidate" ] || [ ! -f "$candidate" ]', text)
                self.assertIn('[ -L "$status_dir" ] || [ ! -d "$status_dir" ]', text)
                self.assertIn("Duplicate feature match", text)
                self.assertIn(
                    'WORKTREE_FEATURE_PATH="$(resolve_feature_spec '
                    '"$WORKTREE_VB_ROOT")" || exit 1',
                    text,
                )
                self.assertNotIn(
                    'find "$VB_ROOT/features" -type f', text
                )

    def test_every_work_on_surface_rebinds_and_locks_the_worktree_root(self):
        for path in SKILLS:
            text = path.read_text(encoding="utf-8")
            with self.subTest(path=path.relative_to(ROOT)):
                self.assertIn('WORKTREE_APP_ROOT="$(git -C "$WORKTREE_DIR"', text)
                self.assertIn("WORKTREE_VB_ROOT", text)
                self.assertIn(
                    'SOURCE_LOCK_TOKEN=$("$VB" --root "$VB_ROOT"', text
                )
                self.assertIn(
                    'WORKTREE_LOCK_TOKEN=$("$VB" --root "$WORKTREE_VB_ROOT"',
                    text,
                )

    def test_every_lock_release_uses_the_exact_acquisition_token(self):
        for path in SKILLS:
            text = path.read_text(encoding="utf-8")
            with self.subTest(path=path.relative_to(ROOT)):
                self.assertIn("SOURCE_LOCK_TOKEN=", text)
                self.assertIn("WORKTREE_LOCK_TOKEN=", text)
                self.assertGreaterEqual(text.count("--token-only"), 2)
                self.assertGreaterEqual(text.count("^[0-9a-f]{64}$"), 2)
                self.assertNotIn("python3 -c", text)
                self.assertNotIn("--json lock", text)
                self.assertIn(
                    'lock "$FEATURE_ID" --release --token "$SOURCE_LOCK_TOKEN"',
                    text,
                )
                self.assertIn(
                    'lock "$FEATURE_ID" --release --token "$WORKTREE_LOCK_TOKEN"',
                    text,
                )
                release_commands = re.findall(
                    r'^.*lock "\$FEATURE_ID" --release.*$', text, re.MULTILINE
                )
                self.assertTrue(release_commands)
                self.assertTrue(
                    all(" --token " in command for command in release_commands),
                    release_commands,
                )

    def test_review_handoff_requires_a_distinct_explicit_reviewer(self):
        for path in SKILLS:
            text = path.read_text(encoding="utf-8")
            with self.subTest(path=path.relative_to(ROOT)):
                self.assertIn("explicitly supplied", text)
                self.assertIn("differs from the preserved", text)
                self.assertIn("no silent\n   solo-review fallback", text)
                self.assertNotIn("defaults to the\n  current actor", text)

    def test_canonical_skill_publishes_claim_non_destructively(self):
        text = SKILLS[0].read_text(encoding="utf-8")
        self.assertIn(
            'git push --porcelain -u origin "$BRANCH_NAME:$BRANCH_NAME"',
            text,
        )
        self.assertNotIn("git push --force", text)


if __name__ == "__main__":
    unittest.main()
