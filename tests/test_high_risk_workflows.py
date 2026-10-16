#!/usr/bin/env python3
"""Regression guards for workflows that can mutate services or data."""

from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class HighRiskWorkflowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        contract = json.loads((ROOT / "virtualboard.json").read_text(encoding="utf-8"))
        cls.commands = {command["id"]: command for command in contract["commands"]}

    def prompt(self, command_id: str) -> str:
        return (ROOT / self.commands[command_id]["prompt"]).read_text(encoding="utf-8")

    def assert_effects(self, command_id: str, expected: set[str]) -> None:
        actual = set(self.commands[command_id]["effects"])
        self.assertTrue(expected <= actual, f"{command_id} omits {sorted(expected - actual)}")

    def test_browser_automation_is_target_and_effect_aware(self):
        command_id = "qa.browser-automation"
        self.assert_effects(
            command_id,
            {"external-write", "production-sensitive", "destructive"},
        )
        text = self.prompt(command_id)
        for evidence in (
            "loopback development application",
            "read-only smoke suite",
            "state-changing production scenarios",
            "disposable target",
        ):
            self.assertIn(evidence, text)

    def test_e2e_reset_is_allowlisted_and_never_production(self):
        command_id = "fullstack.end-to-end-test"
        self.assert_effects(
            command_id,
            {"external-write", "production-sensitive", "destructive"},
        )
        text = self.prompt(command_id)
        for evidence in (
            "There is no production override",
            "ALLOW_TEST_DB_RESET",
            "TEST_DB_ALLOWLIST",
            "assertDisposableTestDatabase();",
        ):
            self.assertIn(evidence, text)
        self.assertIn("actions/checkout@v4", text)
        self.assertIn("actions/upload-artifact@v4", text)
        self.assertNotIn("actions/checkout@v3", text)

    def test_migration_generation_does_not_claim_deployment_safety(self):
        command_id = "backend.database-migration"
        self.assert_effects(command_id, {"production-sensitive", "destructive"})
        text = self.prompt(command_id)
        self.assertIn("default scope is to generate and review migration files", text)
        self.assertIn("No production-safety claim is made here", text)
        self.assertNotIn("This migration is safe to run in production", text)

    def test_contract_publication_is_an_explicit_external_write(self):
        command_id = "fullstack.integration-contract"
        self.assert_effects(command_id, {"external-write"})
        text = self.prompt(command_id)
        self.assertIn("Publication Safety Boundary", text)
        self.assertIn("npx --no-install pact-broker publish", text)
        self.assertIn("publish_pact:", text)
        self.assertIn("default: false", text)
        self.assertIn(
            "if: ${{ github.event_name == 'workflow_dispatch' && inputs.publish_pact == true }}",
            text,
        )
        self.assertIn("actions/checkout@v4", text)
        self.assertNotIn("actions/checkout@v3", text)

    def test_backlog_grooming_never_promotes_code_search_evidence(self):
        text = self.prompt("pm.backlog-grooming")
        self.assertIn("Backlog grooming never advances code-discovered work", text)
        self.assertIn("Do not transition backlog features during this command", text)
        self.assertNotIn("Advanced to REVIEW through canonical transitions", text)
        self.assertNotIn("move to future/icebox category", text)

    def test_progress_metrics_require_provenance_or_unavailable(self):
        text = self.prompt("pm.progress-report")
        self.assertIn("Metric Provenance Rules", text)
        self.assertIn("Unavailable — not tracked", text)
        self.assertIn("insufficient event history", text)
        self.assertNotIn("Story Points Committed: XX", text)
        template = (ROOT / "templates/reports/html/pm-progress-report.html").read_text(
            encoding="utf-8"
        )
        self.assertIn("METRIC_PROVENANCE_HTML", template)

    def test_diagram_templates_describe_the_sanitizer_they_use(self):
        for relative in (
            "templates/reports/html/data-erd.html",
            "templates/reports/html/security-threat-model.html",
            "templates/reports/html/ux-wireframe.html",
        ):
            text = (ROOT / relative).read_text(encoding="utf-8")
            lowered = text.lower()
            with self.subTest(template=relative):
                self.assertIn("raw svg and image tags", lowered)
                self.assertNotIn("Inline SVG / Mermaid render", text)


if __name__ == "__main__":
    unittest.main()
