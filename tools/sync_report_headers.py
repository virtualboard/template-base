#!/usr/bin/env python3
"""Replace hand-maintained report placeholder lists with executable discovery."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TEMPLATES = ROOT / "templates" / "reports" / "html"
MARKER = "  Placeholder contract (generated at runtime):"


def expected_text(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("<!--\n") or "-->" not in text:
        raise ValueError(f"{path}: expected a leading template comment")
    comment, body = text.split("-->", 1)
    lines = comment.splitlines()
    cutoff = next(
        (
            index
            for index, line in enumerate(lines)
            if line.strip().startswith(("Cross-cutting placeholders", "Per-template"))
            or line == MARKER
        ),
        None,
    )
    if cutoff is None:
        raise ValueError(f"{path}: leading comment has no placeholder-contract section")
    retained = lines[:cutoff]
    while retained and not retained[-1].strip():
        retained.pop()
    template_id = path.stem
    generated = [
        "",
        MARKER,
        f"    python3 tools/render_report.py --template {template_id} --describe",
        "  This command is authoritative for scalar, HTML, JSON, URL, number,",
        "  token, defaulted, and per-list item values.",
    ]
    return "\n".join([*retained, *generated, "-->"]) + body


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--check", action="store_true")
    args = parser.parse_args()

    templates = sorted(path for path in TEMPLATES.glob("*.html") if path.is_file())
    if len(templates) != 21:
        print(f"ERROR: expected 21 report templates, found {len(templates)}", file=sys.stderr)
        return 1
    drift: list[str] = []
    for path in templates:
        try:
            expected = expected_text(path)
        except ValueError as exc:
            print(f"ERROR: {exc}", file=sys.stderr)
            return 1
        actual = path.read_text(encoding="utf-8")
        if actual != expected:
            if args.write:
                path.write_text(expected, encoding="utf-8")
            else:
                drift.append(path.name)
    if drift:
        for name in drift:
            print(f"ERROR: report template header is out of date: {name}", file=sys.stderr)
        return 1
    print(("Synchronized" if args.write else "Verified") + f" {len(templates)} report headers")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
