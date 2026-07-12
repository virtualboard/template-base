#!/usr/bin/env python3
"""Synchronize the canonical work-on skill into every runtime package.

The procedural ``SKILL.md`` has no runtime-specific rewrite: Claude and Codex
must receive identical guardrails. Runtime packaging deltas are explicit in
``RUNTIME_FILES``; Claude includes the optional configuration reference while
Codex exposes only the skill entrypoint.
"""

from __future__ import annotations

import argparse
import json
import os
import stat
import tempfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = REPO_ROOT / "skills" / "work-on"
RUNTIME_ROOTS = {
    "claude": REPO_ROOT / "plugins" / "claude" / "virtualboard" / "skills" / "work-on",
    "codex": REPO_ROOT / "plugins" / "codex" / "virtualboard" / "skills" / "work-on",
}
RUNTIME_FILES = {
    "claude": ("SKILL.md", "config.md"),
    "codex": ("SKILL.md",),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group()
    action.add_argument("--check", action="store_true", help="verify generated copies (default)")
    action.add_argument("--write", action="store_true", help="refresh generated copies")
    parser.add_argument("--json", action="store_true", help="emit machine-readable output")
    return parser.parse_args()


def read_regular(path: Path) -> bytes:
    try:
        info = path.lstat()
    except FileNotFoundError as exc:
        raise ValueError(f"missing canonical work-on source: {path}") from exc
    if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode):
        raise ValueError(f"work-on source must be a regular non-linked file: {path}")
    return path.read_bytes()


def assert_safe_target(path: Path, *, allow_missing_leaf: bool) -> None:
    try:
        relative = path.relative_to(REPO_ROOT)
    except ValueError as exc:
        raise ValueError(f"refusing to manage path outside repository: {path}") from exc

    cursor = REPO_ROOT
    for part in relative.parts[:-1]:
        cursor /= part
        if not cursor.exists():
            continue
        info = cursor.lstat()
        if stat.S_ISLNK(info.st_mode) or not stat.S_ISDIR(info.st_mode):
            raise ValueError(f"unsafe generated-skill parent component: {cursor}")

    try:
        info = path.lstat()
    except FileNotFoundError:
        if allow_missing_leaf:
            return
        raise ValueError(f"missing generated work-on file: {path}")
    if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode):
        raise ValueError(f"generated work-on path must be a regular non-linked file: {path}")


def expected_files() -> dict[str, dict[Path, bytes]]:
    canonical = {
        name: read_regular(SOURCE_ROOT / name)
        for name in sorted({item for names in RUNTIME_FILES.values() for item in names})
    }
    return {
        runtime: {Path(name): canonical[name] for name in names}
        for runtime, names in RUNTIME_FILES.items()
    }


def actual_files(runtime: str) -> dict[Path, bytes]:
    root = RUNTIME_ROOTS[runtime]
    if not root.exists():
        return {}
    if root.is_symlink() or not root.is_dir():
        raise ValueError(f"runtime work-on root is linked or not a directory: {root}")
    actual: dict[Path, bytes] = {}
    for path in sorted(root.rglob("*")):
        info = path.lstat()
        if stat.S_ISLNK(info.st_mode):
            raise ValueError(f"linked generated work-on entry is forbidden: {path}")
        if stat.S_ISDIR(info.st_mode):
            continue
        if not stat.S_ISREG(info.st_mode):
            raise ValueError(f"non-regular generated work-on entry is forbidden: {path}")
        actual[path.relative_to(root)] = path.read_bytes()
    return actual


def diff_runtime(runtime: str, expected: dict[Path, bytes]) -> list[str]:
    actual = actual_files(runtime)
    errors: list[str] = []
    for path in sorted(expected.keys() - actual.keys()):
        errors.append(f"{runtime}: missing generated work-on file: {path}")
    for path in sorted(actual.keys() - expected.keys()):
        errors.append(f"{runtime}: stale generated work-on file: {path}")
    for path in sorted(expected.keys() & actual.keys()):
        if expected[path] != actual[path]:
            errors.append(f"{runtime}: out-of-date generated work-on file: {path}")
    return errors


def write_atomic(path: Path, content: bytes) -> None:
    assert_safe_target(path, allow_missing_leaf=True)
    path.parent.mkdir(parents=True, exist_ok=True)
    assert_safe_target(path, allow_missing_leaf=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary_path = Path(temporary)
    try:
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        assert_safe_target(path, allow_missing_leaf=True)
        os.replace(temporary_path, path)
    finally:
        temporary_path.unlink(missing_ok=True)


def write_runtime(runtime: str, expected: dict[Path, bytes]) -> None:
    root = RUNTIME_ROOTS[runtime]
    actual = actual_files(runtime)
    for stale in sorted(actual.keys() - expected.keys()):
        target = root / stale
        assert_safe_target(target, allow_missing_leaf=False)
        target.unlink()
    for relative, content in expected.items():
        write_atomic(root / relative, content)


def main() -> int:
    args = parse_args()
    errors: list[str] = []
    try:
        expected = expected_files()
        if args.write:
            for runtime in sorted(expected):
                write_runtime(runtime, expected[runtime])
        for runtime in sorted(expected):
            errors.extend(diff_runtime(runtime, expected[runtime]))
    except (OSError, UnicodeError, ValueError) as exc:
        errors.append(str(exc))

    result = {
        "success": not errors,
        "mode": "write" if args.write else "check",
        "runtimeFiles": {name: list(files) for name, files in RUNTIME_FILES.items()},
        "errors": errors,
    }
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    elif errors:
        for error in errors:
            print(f"ERROR: {error}", file=os.sys.stderr)
    else:
        action = "Synchronized" if args.write else "Verified"
        print(f"{action} canonical work-on skill for Claude and Codex")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
