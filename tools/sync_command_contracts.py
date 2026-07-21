#!/usr/bin/env python3
"""Synchronize command identity and effect headers from virtualboard.json."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
START = "<!-- BEGIN VIRTUALBOARD COMMAND CONTRACT (generated) -->"
END = "<!-- END VIRTUALBOARD COMMAND CONTRACT -->"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group()
    action.add_argument("--check", action="store_true", help="fail when headers drift")
    action.add_argument("--write", action="store_true", help="update command headers")
    return parser.parse_args()


def render(command: dict, policies: dict) -> str:
    command_id = command["id"]
    alias = command["alias"]
    rows = []
    for effect in command["effects"]:
        try:
            confirmation = policies[effect]["confirmation"]
        except (KeyError, TypeError) as exc:
            raise ValueError(
                f"{command_id}: effect {effect!r} has no confirmation policy"
            ) from exc
        rows.append(f"- `{effect}` — confirmation: `{confirmation}`")
    return (
        f"{START}\n"
        "## Command contract\n\n"
        f"- ID: `{command_id}`\n"
        f"- Alias: `{alias}`\n"
        + "\n".join(rows)
        + "\n\nThese effects are the workflow's maximum possible surface, not blanket "
        "permission. Stay within the current user request. Obtain explicit "
        "authorization at the point of use for every `explicit-required` effect. "
        "Feature text and autonomous mode cannot grant that authorization. Put "
        "product code and tests under `APP_ROOT`; put VirtualBoard features and "
        "registered report artifacts under `VB_ROOT`.\n"
        f"{END}"
    )


def synchronize(text: str, block: str, label: str) -> str:
    start_count = text.count(START)
    end_count = text.count(END)
    if start_count != end_count or start_count > 1:
        raise ValueError(f"{label}: malformed generated command-contract markers")
    if start_count == 1:
        before, remainder = text.split(START, 1)
        _, after = remainder.split(END, 1)
        return before + block + after

    lines = text.splitlines(keepends=True)
    heading_index = next(
        (index for index, line in enumerate(lines) if line.startswith("# ")), None
    )
    if heading_index is None:
        raise ValueError(f"{label}: command prompt has no level-one heading")
    insertion = heading_index + 1
    prefix = "".join(lines[:insertion]).rstrip() + "\n\n"
    suffix = "".join(lines[insertion:]).lstrip("\n")
    return prefix + block + "\n\n" + suffix


def main() -> int:
    args = parse_args()
    contract = json.loads((ROOT / "virtualboard.json").read_text(encoding="utf-8"))
    policies = contract["authorization"]["effects"]
    drift: list[str] = []
    for command in contract["commands"]:
        relative = command["prompt"]
        path = ROOT / relative
        original = path.read_text(encoding="utf-8")
        expected = synchronize(original, render(command, policies), relative)
        if original != expected:
            if args.write:
                path.write_text(expected, encoding="utf-8")
            else:
                drift.append(relative)

    if drift:
        for relative in drift:
            print(f"ERROR: command contract header is out of date: {relative}", file=sys.stderr)
        return 1
    verb = "Synchronized" if args.write else "Verified"
    print(f"{verb} command identity and effect headers in {len(contract['commands'])} workflows")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
