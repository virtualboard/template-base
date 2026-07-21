#!/usr/bin/env python3
"""Keep the release gate aligned with supported installer platforms."""

from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "ci.yml"


class CIContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.text = WORKFLOW.read_text(encoding="utf-8")
        cls.workflows = {
            path.name: path.read_text(encoding="utf-8")
            for path in (ROOT / ".github" / "workflows").glob("*.yml")
        }

    def test_third_party_action_references_are_commit_pinned(self):
        references = []
        for text in self.workflows.values():
            references.extend(
                re.findall(r"^\s*-?\s*uses:\s*([^\s#]+)", text, re.MULTILINE)
            )
        self.assertTrue(references)
        for reference in references:
            with self.subTest(reference=reference):
                if reference.startswith("./"):
                    self.assertRegex(reference, r"^\./\.github/workflows/[a-z0-9-]+\.yml$")
                else:
                    self.assertRegex(reference, r"^[^@]+@[0-9a-f]{40}$")

    def test_exact_cli_source_candidate_is_concrete(self):
        source_ref = (ROOT / ".vb-cli-source-ref").read_text(encoding="utf-8").strip()
        self.assertRegex(source_ref, r"^[0-9a-f]{40}$")
        self.assertNotEqual(source_ref, "0" * 40, "replace the release-blocking CLI source placeholder")

    def test_installer_matrix_covers_every_advertised_os_architecture(self):
        for runner in (
            "ubuntu-24.04",
            "ubuntu-24.04-arm",
            "macos-15-intel",
            "macos-15",
        ):
            self.assertIn(f"- {runner}", self.text)
        self.assertIn("runs-on: windows-2025", self.text)
        self.assertIn("tests/test-install-vb-cli.ps1", self.text)
        self.assertIn("vb-windows", (ROOT / "scripts" / "install-vb-cli.ps1").read_text(encoding="utf-8"))

    def test_cleanliness_gate_includes_untracked_and_whitespace(self):
        self.assertIn("git diff --check", self.text)
        self.assertIn("git status --porcelain --untracked-files=all", self.text)

    def test_ci_builds_the_source_pinned_cli_without_a_release_bootstrap(self):
        self.assertIn(".vb-cli-source-ref", self.text)
        self.assertIn("repository: virtualboard/vb-cli", self.text)
        self.assertIn("scripts/build-vb-cli-candidate.sh", self.text)
        self.assertIn("scripts/release-smoke.sh", self.text)
        self.assertIn("internal/frameworkschema/frontmatter.schema.json", self.text)
        self.assertIn("internal/frameworkschema/system-spec.schema.json", self.text)
        self.assertNotIn("Install exact VirtualBoard CLI", self.text)
        self.assertNotIn("scripts/install-vb-cli.sh --ensure-latest", self.text)

    def test_ci_pins_exact_go_and_gates_moving_main(self):
        self.assertIn('GO_VERSION: "1.25.0"', self.text)
        self.assertIn("legacy-main-compatibility:", self.text)
        self.assertIn("d0d05d656c721ade944ad4dd61e1aa7d3ffb0f8a", self.text)
        self.assertIn("scripts/rehearse-v0.9-compatibility.sh", self.text)

    def test_claude_runtime_uses_verified_wrapper_and_native_tarballs(self):
        self.assertIn('CLAUDE_CODE_VERSION: "2.1.201"', self.text)
        self.assertRegex(self.text, r'CLAUDE_CODE_INTEGRITY: "sha512-[A-Za-z0-9+/]+={0,2}"')
        self.assertRegex(self.text, r'CLAUDE_CODE_LINUX_X64_INTEGRITY: "sha512-[A-Za-z0-9+/]+={0,2}"')
        self.assertIn('test "$WRAPPER_ACTUAL" = "$CLAUDE_CODE_INTEGRITY"', self.text)
        self.assertIn('test "$NATIVE_ACTUAL" = "$CLAUDE_CODE_LINUX_X64_INTEGRITY"', self.text)
        self.assertIn('npm install --global --omit=optional "$NATIVE" "$WRAPPER"', self.text)
        self.assertNotIn("npm install --global @anthropic-ai/claude-code@", self.text)

    def test_every_workflow_declares_default_permissions(self):
        for name, text in self.workflows.items():
            with self.subTest(workflow=name):
                self.assertRegex(text, r"(?m)^permissions:\s*\n\s+contents: read$")

    def test_release_uses_a_stable_asset_and_source_bound_draft(self):
        release = self.workflows["release.yml"]
        publisher = (ROOT / "scripts" / "publish_github_release.py").read_text(
            encoding="utf-8"
        )
        self.assertIn('ARCHIVE="template-base-${RELEASE_TAG}.zip"', release)
        self.assertIn("git archive --format=zip", release)
        self.assertIn("publisher-tool:", release)
        self.assertIn("python3 -m unittest tests/test_release_publisher.py -v", release)
        self.assertIn("release-publisher-${{ github.sha }}-${{ github.run_attempt }}", release)
        self.assertIn("python3 release-publisher/publish_github_release.py", release)
        self.assertIn('--source-sha "$GITHUB_SHA"', release)
        self.assertIn('--asset "dist/template-base-${RELEASE_TAG}.zip"', release)
        self.assertIn("virtualboard-release-draft:v1", publisher)
        self.assertIn('"draft": True', publisher)
        self.assertIn('{"draft": False}', publisher)
        self.assertIn("published release {self.tag} already exists", publisher)
        self.assertNotIn("delete_release", publisher)
        self.assertNotIn("softprops/action-gh-release", release)

    def test_release_reuses_the_complete_ci_gate(self):
        release = self.workflows["release.yml"]
        self.assertRegex(self.text, r"(?m)^  workflow_call:$")
        self.assertIn("  full-verification:", release)
        self.assertIn("    needs: preflight", release)
        self.assertIn("    uses: ./.github/workflows/ci.yml", release)

    def test_release_tag_must_resolve_to_main_or_exact_release_branch_head(self):
        release = self.workflows["release.yml"]
        self.assertIn('TAG_COMMIT=$(git rev-parse HEAD)', release)
        self.assertIn('test "$TAG_COMMIT" = "$GITHUB_SHA"', release)
        self.assertIn("refs/heads/main:refs/remotes/origin/main", release)
        self.assertIn("git merge-base --is-ancestor", release)
        self.assertIn('refs/heads/release/${RELEASE_TAG}', release)
        self.assertIn("exact head of release/${RELEASE_TAG}", release)

    def test_release_builds_exact_cli_source_and_smokes_exact_archive(self):
        release = self.workflows["release.yml"]
        self.assertIn(".vb-cli-source-ref", release)
        self.assertIn("scripts/build-vb-cli-candidate.sh", release)
        self.assertIn("scripts/release-smoke.sh", release)
        self.assertIn('ARCHIVE="dist/template-base-${RELEASE_TAG}.zip"', release)
        self.assertIn('GO_VERSION: "1.25.0"', release)

    def test_release_attests_before_publication(self):
        release = self.workflows["release.yml"]
        self.assertIn("actions/attest-build-provenance@", release)
        self.assertIn("attestations: write", release)
        self.assertIn("id-token: write", release)
        self.assertIn("needs: [attest, publisher-tool]", release)

    def test_release_write_credentials_are_isolated_to_publication(self):
        release = self.workflows["release.yml"]
        before_publish, publish = release.split("\n  publish:\n", 1)
        self.assertNotIn("contents: write", before_publish)
        self.assertIn("contents: write", publish)
        self.assertIn("environment: release", publish)
        self.assertNotIn("actions/checkout@", publish)
        self.assertNotIn("git archive", publish)
        self.assertNotIn("python3 tools/", publish)
        self.assertNotIn("bash tests/", publish)
        checkout_sections = release.split("uses: actions/checkout@")[1:]
        self.assertTrue(checkout_sections)
        for section in checkout_sections:
            self.assertIn("persist-credentials: false", section.split("\n      - name:", 1)[0])
        self.assertIn("actions/upload-artifact@", before_publish)
        self.assertIn("actions/download-artifact@", publish)


if __name__ == "__main__":
    unittest.main()
