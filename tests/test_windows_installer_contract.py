#!/usr/bin/env python3
"""Static stop-ship checks for the native Windows bootstrap boundary."""

from __future__ import annotations

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "scripts" / "install-vb-cli.ps1"
CI = ROOT / ".github" / "workflows" / "ci.yml"


class WindowsInstallerContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.installer = INSTALLER.read_text(encoding="utf-8")
        cls.ci = CI.read_text(encoding="utf-8")

    def test_release_selection_and_manifest_are_exact(self):
        self.assertIn("Join-Path -Path $repositoryRoot -ChildPath '.vb-version'", self.installer)
        self.assertIn('"vb-windows-$assetArchitecture.exe"', self.installer)
        self.assertIn("expected exactly one checksum entry", self.installer)
        self.assertIn("Get-FileHash -LiteralPath $downloadFile -Algorithm SHA256", self.installer)
        self.assertIn("downloaded binary version mismatch", self.installer)

    def test_download_is_streamed_bounded_and_https_only(self):
        self.assertIn("[Net.Http.HttpCompletionOption]::ResponseHeadersRead", self.installer)
        self.assertIn("Copy-BoundedStream", self.installer)
        self.assertIn("$total -gt $MaximumBytes", self.installer)
        self.assertIn("$cancellation.Token", self.installer)
        self.assertIn("[IO.FileMode]::CreateNew", self.installer)
        self.assertIn("refusing redirect to non-HTTPS URL", self.installer)
        self.assertNotIn("Invoke-WebRequest", self.installer)
        self.assertNotIn("Start-BitsTransfer", self.installer)

    def test_destination_and_activation_are_fail_closed(self):
        self.assertIn("[IO.FileAttributes]::ReparsePoint", self.installer)
        self.assertIn("same-directory staged binary checksum mismatch", self.installer)
        self.assertLess(
            self.installer.index("$targetHash = (Get-FileHash"),
            self.installer.index("$currentVersion = Get-BinaryVersion"),
        )
        self.assertIn("post-install binary checksum mismatch", self.installer)
        self.assertIn("staging bytes changed before activation", self.installer)
        self.assertIn("$stream.Flush($true)", self.installer)
        self.assertIn("[IO.File]::Replace($Stage, $Target, $null, $true)", self.installer)
        self.assertIn("[IO.File]::Move($Stage, $Target)", self.installer)
        self.assertNotIn("-Verb RunAs", self.installer)
        self.assertNotIn("Start-Process", self.installer)

    def test_native_ci_executes_fault_injection_suite(self):
        self.assertIn("runs-on: windows-2025", self.ci)
        self.assertIn("Build the exact Windows CLI candidate", self.ci)
        self.assertIn("./tests/test-install-vb-cli.ps1 -Candidate .state/bin/vb.exe", self.ci)
        self.assertIn("shell: powershell", self.ci)


if __name__ == "__main__":
    unittest.main()
