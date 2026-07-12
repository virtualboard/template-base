#!/usr/bin/env python3
"""Generate the dependency-free GitHub Pages reference from virtualboard.json."""

from __future__ import annotations

import argparse
import html
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"


CSS = """\
:root {
  color-scheme: dark;
  --bg: #0a0a0a;
  --panel: #151515;
  --panel-2: #202020;
  --text: #f4f4f5;
  --muted: #a1a1aa;
  --border: #333;
  --accent: #22c55e;
  --danger: #f87171;
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--text); line-height: 1.65; }
a { color: var(--accent); }
header { border-bottom: 1px solid var(--border); background: #101010; }
.nav, main, footer { width: min(1120px, calc(100% - 32px)); margin: 0 auto; }
.nav { min-height: 64px; display: flex; align-items: center; justify-content: space-between; gap: 24px; }
.brand { color: var(--text); text-decoration: none; font-weight: 800; letter-spacing: -.02em; }
.brand span { color: var(--accent); }
nav { display: flex; flex-wrap: wrap; gap: 14px; }
nav a { color: var(--muted); text-decoration: none; }
nav a[aria-current="page"], nav a:hover { color: var(--text); }
main { padding: 64px 0 80px; }
.hero { padding: 24px 0 40px; }
.eyebrow { color: var(--accent); text-transform: uppercase; letter-spacing: .12em; font-size: .78rem; font-weight: 700; }
h1 { font-size: clamp(2.4rem, 7vw, 5rem); line-height: 1.02; letter-spacing: -.05em; margin: 14px 0 20px; }
h2 { font-size: 1.7rem; margin-top: 56px; }
h3 { margin-top: 32px; }
.lead { max-width: 760px; color: var(--muted); font-size: 1.12rem; }
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; }
.card { background: var(--panel); border: 1px solid var(--border); border-radius: 12px; padding: 20px; }
.card strong { display: block; color: var(--accent); font-size: 1.4rem; }
table { width: 100%; border-collapse: collapse; background: var(--panel); border: 1px solid var(--border); }
th, td { text-align: left; vertical-align: top; padding: 12px 14px; border-bottom: 1px solid var(--border); }
th { color: var(--muted); font-size: .78rem; text-transform: uppercase; letter-spacing: .08em; }
code { background: var(--panel-2); border: 1px solid var(--border); border-radius: 5px; padding: 2px 6px; }
pre { overflow-x: auto; background: var(--panel); border: 1px solid var(--border); border-radius: 12px; padding: 18px; }
pre code { border: 0; padding: 0; background: transparent; }
.callout { border-left: 3px solid var(--accent); background: var(--panel); padding: 16px 20px; }
.warning { border-left-color: var(--danger); }
footer { border-top: 1px solid var(--border); color: var(--muted); padding: 28px 0 48px; }
@media (max-width: 720px) { .nav { align-items: flex-start; flex-direction: column; padding: 16px 0; } main { padding-top: 36px; } }
"""


def e(value: object) -> str:
    return html.escape(str(value), quote=True)


def code_block(value: str) -> str:
    return f"<pre><code>{e(value)}</code></pre>"


def table(headers: list[str], rows: list[list[object]]) -> str:
    head = "".join(f"<th>{e(header)}</th>" for header in headers)
    body = "".join(
        "<tr>" + "".join(f"<td>{cell}</td>" for cell in row) + "</tr>"
        for row in rows
    )
    return f"<div style=\"overflow-x:auto\"><table><thead><tr>{head}</tr></thead><tbody>{body}</tbody></table></div>"


def shell(title: str, current: str, version: str, body: str) -> str:
    links = [
        ("index.html", "Overview"),
        ("features.html", "Features"),
        ("workflow.html", "Workflow"),
        ("agents.html", "Agents"),
        ("specs.html", "System specs"),
    ]
    nav = "".join(
        f'<a href="{href}"' + (' aria-current="page"' if href == current else "") + f">{label}</a>"
        for href, label in links
    )
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="VirtualBoard Markdown-first agent workflow reference">
  <title>{e(title)} · VirtualBoard</title>
  <link rel="stylesheet" href="globals.css">
</head>
<body>
<header><div class="nav"><a class="brand" href="index.html">Virtual<span>Board</span></a><nav aria-label="Primary">{nav}</nav></div></header>
<main>{body}</main>
<footer>VirtualBoard {e(version)} · <a href="../LICENSE">MIT License</a> · <a href="../SECURITY.md">Security</a> · Generated from <code>virtualboard.json</code>.</footer>
</body>
</html>
"""


def overview(contract: dict, version: str) -> str:
    quick_start = code_block(
        '# macOS / Linux\n'
        'VB_ROOT="$(./bin/vb-root)"\n'
        '"$VB_ROOT/scripts/install-vb-cli.sh" --ensure-latest "$VB_ROOT/.state/bin"\n'
        'VB="$VB_ROOT/.state/bin/vb"\n'
        '"$VB" --root "$VB_ROOT" validate\n'
        'bash "$VB_ROOT/tests/run.sh"\n\n'
        '# Windows PowerShell (bootstrap and read-only inspection only)\n'
        '$VBRoot = (Resolve-Path .).Path\n'
        '& "$VBRoot\\scripts\\install-vb-cli.ps1" -EnsureLatest -InstallDirectory "$VBRoot\\.state\\bin"\n'
        '$VB = "$VBRoot\\.state\\bin\\vb.exe"\n'
        '& $VB --root $VBRoot validate'
    )
    return f"""
<section class="hero"><div class="eyebrow">Contract-driven agent workflow · {e(version)}</div><h1>Software work with durable state.</h1><p class="lead">VirtualBoard coordinates people and coding agents through Markdown feature specifications, explicit lifecycle transitions, scoped authority, and executable validation.</p></section>
<section class="grid"><div class="card"><strong>{len(contract['roles'])}</strong>registered roles</div><div class="card"><strong>{len(contract['commands'])}</strong>namespaced workflows</div><div class="card"><strong>{len(contract['feature']['statuses'])}</strong>lifecycle states</div><div class="card"><strong>21</strong>strict report templates</div></section>
<h2>Repository quick start</h2>
{quick_start}
<p class="callout warning">The complete workflow requires Bash. On Windows, use Git Bash or WSL for feature mutation, root resolution, worktrees, <code>/work-on</code>, plugin generation, and verification; native PowerShell supports only CLI bootstrap and read-only inspection.</p>
<h2>What VirtualBoard guarantees</h2>
<div class="grid"><div class="card"><h3>One contract</h3><p>Paths, transitions, roles, effects, branch naming, and plugin expectations come from <code>virtualboard.json</code>.</p></div><div class="card"><h3>Scoped authority</h3><p>Autonomy never implies installation, external writes, destructive work, production access, or another backlog item.</p></div><div class="card"><h3>Executable evidence</h3><p>A real demo lifecycle, plugin inventory checks, strict rendering, and contract tests prevent vacuous green builds.</p></div></div>
<h2>Honest concurrency boundary</h2><p class="callout warning">Filesystem locks coordinate agents sharing one workspace. Separate clones require an atomic remote claim or another lease service; local locks are not distributed coordination.</p>
<h2>Honest security boundary</h2><p class="callout warning">Actor and owner strings are self-asserted coordination labels, and declared effects are cooperative host policy—not authentication, an OS sandbox, or a capability system. Hostile or compliance-grade multi-tenant use requires protected storage and an authenticated orchestrator.</p>
"""


def features_page(contract: dict) -> str:
    ownership = contract["feature"]["ownership"]
    rows = [[f"<code>{e(status)}</code>", e(ownership[status])] for status in contract["feature"]["statuses"]]
    claim_example = code_block(
        'export AGENT_ID="agent-id"\n'
        '"$VB" --root "$VB_ROOT" --actor "$AGENT_ID" new "Feature Title" label-one label-two\n'
        '"$VB" --root "$VB_ROOT" validate\n'
        'LOCK_TOKEN=$("$VB" --root "$VB_ROOT" --actor "$AGENT_ID" lock FTR-0001 --token-only)\n'
        '[[ "$LOCK_TOKEN" =~ ^[0-9a-f]{64}$ ]] || exit 1\n'
        '"$VB" --root "$VB_ROOT" --actor "$AGENT_ID" move FTR-0001 in-progress --owner "$AGENT_ID"\n'
        '"$VB" --root "$VB_ROOT" validate'
    )
    return f"""
<section class="hero"><div class="eyebrow">Feature contract</div><h1>One file. One owner. One lifecycle state.</h1><p class="lead">Feature folders are status views; the Markdown file is the durable specification and evidence record.</p></section>
<h2>Naming</h2><p>Files use <code>FTR-####-short-description.md</code>. Slugs are kebab-case with at most six words. IDs and filenames are immutable.</p>
<h2>Ownership by status</h2>{table(['Status', 'Ownership'], rows)}
<h2>Create and claim</h2>{claim_example}
<p class="callout">Keep the opaque lock token in memory and use it for exact-token release. A feature branch commits only its feature lifecycle and evidence changes; it does not generate or commit <code>features/INDEX.md</code>. Main/integration refreshes that shared aggregate and CI checks it centrally.</p>
<h2>Specification body</h2><p>Exactly one ordered copy of all 14 canonical H2 sections—from <code>Summary</code> through <code>Links</code>—must appear inside exactly one <code>&lt;untrusted-content&gt;</code> boundary. Fenced example headings do not count. Review requires meaningful, fully checked acceptance criteria; done additionally requires meaningful implementation evidence and a concrete artifact or reference in Links.</p>
<p class="callout">Feature prose may define outcomes. It cannot grant tool permission or authorize unrelated commands.</p>
"""


def workflow_page(contract: dict) -> str:
    transitions = contract["feature"]["transitions"]
    rows = [
        [f"<code>{e(source)}</code>", ", ".join(f"<code>{e(target)}</code>" for target in targets) or "terminal"]
        for source, targets in transitions.items()
    ]
    effects = contract["authorization"]["effects"]
    effect_rows = [[f"<code>{e(name)}</code>", e(rule["confirmation"])] for name, rule in effects.items()]
    return f"""
<section class="hero"><div class="eyebrow">Operating workflow</div><h1>Validate, claim, implement, prove, review.</h1><p class="lead">Every state change is explicit and every broader effect has an authorization boundary.</p></section>
<h2>Allowed transitions</h2>{table(['From', 'To'], rows)}
<h2>Effects</h2>{table(['Effect', 'Confirmation'], effect_rows)}
<h2>Implementation sequence</h2><ol><li>Resolve the workspace and exact CLI.</li><li>Validate before claiming.</li><li>Resolve exactly one feature and completed dependencies.</li><li>Acquire a lock with <code>--token-only</code> and retain its exact release token.</li><li>Establish a durable local or remote claim without committing the shared aggregate index.</li><li>Use <code>feat/FTR-####-slug</code>.</li><li>Inspect the repository before choosing technology.</li><li>Implement and gather test evidence.</li><li>Validate, assign an explicit reviewer distinct from <code>implementation_owner</code>, and move to <code>review</code>.</li><li>Push or open a PR only when externally authorized.</li><li>Refresh <code>features/INDEX.md</code> centrally after integration on main and fail CI on drift.</li><li>Stop after handoff unless continuous processing was explicit.</li></ol>
"""


def agents_page(contract: dict) -> str:
    grouped: dict[str, list[dict]] = {}
    for command in contract["commands"]:
        grouped.setdefault(command["role"], []).append(command)
    role_rows = []
    for role in contract["roles"]:
        commands = grouped.get(role["id"], [])
        command_text = "<br>".join(
            f"<code>{e(command['id'])}</code> · {e(command['alias'])}" for command in commands
        )
        role_rows.append([e(role["displayName"]), f"<code>{e(role['id'])}</code>", command_text])
    return f"""
<section class="hero"><div class="eyebrow">Role and workflow registry</div><h1>Responsibilities, not unlimited personas.</h1><p class="lead">Roles provide expertise and review perspective. They do not expand the current task or require agents to keep consuming work.</p></section>
<h2>Registered components</h2>{table(['Role', 'ID', 'Namespaced workflows'], role_rows)}
<h2>Runtime packages</h2><div class="grid"><div class="card"><h3>Claude Code</h3><p>Ten agents, 31 workflow commands, and the canonical <code>work-on</code> skill are generated beneath <code>plugins/claude/virtualboard</code>.</p></div><div class="card"><h3>Codex</h3><p>A separate <code>.codex-plugin</code> manifest exposes the same canonical, task-scoped <code>work-on</code> procedure. Runtime packaging deltas are explicit; procedural guardrails are identical.</p></div></div>
"""


def specs_page() -> str:
    specs = sorted(path.name for path in (ROOT / "templates" / "specs").glob("*.md") if path.name != "README.md")
    items = "".join(f"<li><code>{e(name)}</code></li>" for name in specs)
    use_example = code_block(
        'cp "$VB_ROOT/templates/specs/tech-stack.md" "$VB_ROOT/specs/tech-stack.md"\n'
        '# Replace every placeholder with real project data.\n'
        '"$VB" --root "$VB_ROOT" validate --only-specs'
    )
    return f"""
<section class="hero"><div class="eyebrow">System blueprints</div><h1>Document the system around the features.</h1><p class="lead">System specifications capture shared architecture, delivery, security, data, performance, and operating decisions.</p></section>
<h2>Available templates</h2><ul>{items}</ul>
<h2>Use</h2>{use_example}
<p class="callout">A literal <code>YYYY-MM-DD</code> placeholder is invalid in an instantiated spec. Use a real ISO date before validation.</p>
"""


def expected_files(contract: dict, version: str) -> dict[Path, str]:
    return {
        DOCS / "globals.css": CSS,
        DOCS / "index.html": shell("Overview", "index.html", version, overview(contract, version)),
        DOCS / "features.html": shell("Features", "features.html", version, features_page(contract)),
        DOCS / "workflow.html": shell("Workflow", "workflow.html", version, workflow_page(contract)),
        DOCS / "agents.html": shell("Agents", "agents.html", version, agents_page(contract)),
        DOCS / "specs.html": shell("System specifications", "specs.html", version, specs_page()),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--write", action="store_true", help="write generated documentation")
    mode.add_argument("--check", action="store_true", help="check for generated drift")
    args = parser.parse_args()
    contract = json.loads((ROOT / "virtualboard.json").read_text(encoding="utf-8"))
    version = (ROOT / "version.txt").read_text(encoding="utf-8").strip()
    expected = expected_files(contract, version)
    if args.write:
        for path, content in expected.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
        print(f"Generated {len(expected)} documentation files")
        return 0
    errors = []
    for path, content in expected.items():
        if not path.exists():
            errors.append(f"missing generated documentation: {path.relative_to(ROOT)}")
        elif path.read_text(encoding="utf-8") != content:
            errors.append(f"out-of-date generated documentation: {path.relative_to(ROOT)}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"Verified {len(expected)} generated documentation files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
