#!/usr/bin/env python3
"""Validate the template's public workflow fixture against its schemas/charters."""
import json
import re
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
contract = json.loads((root / "schemas/workflow-contract.json").read_text())
schema = json.loads((root / "schemas/frontmatter.schema.json").read_text())
assert contract["format_version"] == 1
statuses = contract["statuses"]
assert len(statuses) == len(set(statuses)) and statuses
assert schema["properties"]["status"]["enum"] == statuses
assert schema["properties"]["id"]["pattern"] == contract["feature_id_pattern"]
assert set(contract["transitions"]) == set(statuses)
for origin, targets in contract["transitions"].items():
    assert len(targets) == len(set(targets)) and set(targets) <= set(statuses)
assert contract["terminal_statuses"] == [s for s in statuses if not contract["transitions"][s]]
roles = sorted(p.stem for p in (root / "agents").glob("*.md") if p.stem not in {"AGENTS", "RULES", "README"})
assert contract["roles"]["keys"] == roles
for role in roles:
    assert re.fullmatch(schema["properties"]["role"]["pattern"], role)
for case in contract["roles"]["selection_cases"]:
    assert case["status"] in statuses and case["want"] in roles
required = contract["doctor"]["dispatch_capabilities"]
assert required and len(set(required)) == len(required)
assert set(required) <= set(contract["doctor"]["vb_capabilities"])
for tool in ("vb", "hvb"):
    assert contract[tool]["commands"] and contract[tool]["global_flags"]
    codes = contract[tool]["exit_codes"]
    assert len(codes) == len(set(codes.values())) and codes["success"] == 0
# Check synchronization and refusal without changing any contributor checkout.
with tempfile.TemporaryDirectory() as temporary:
    repository = Path(temporary) / "consumer"
    repository.mkdir()
    (repository / "go.mod").write_text("module example.com/contract-test\n")
    script = root / "scripts/sync-workflow-contract.sh"
    subprocess.run(["bash", str(script), str(repository)], check=True)
    subprocess.run(["bash", str(script), "--check", str(repository)], check=True)
    fixture = repository / "testdata/workflow-contract.json"
    changed = fixture.read_bytes() + b" "
    fixture.write_bytes(changed)
    result = subprocess.run(["bash", str(script), "--check", str(repository)], capture_output=True)
    assert result.returncode != 0 and fixture.read_bytes() == changed
print("workflow contract: template schema/roles, interfaces, sync, and drift refusal passed")
