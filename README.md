# VirtualBoard

VirtualBoard is a Markdown-first feature workflow for people and coding agents.
It keeps requirements, lifecycle state, ownership, review evidence, and project
decisions in Git while using a pinned `vb` CLI for safe mutations.

VirtualBoard is intentionally a workflow and packaging framework, not a hosted
agent scheduler. Local locks coordinate processes that share a workspace. Teams
working across separate clones must publish an atomic remote claim before
implementation or configure another remote lease mechanism. Local-only work must
explicitly select shared-workspace mode; it is never inferred silently.

## Why it exists

- One durable feature specification per user-visible change
- Reviewable lifecycle state instead of chat-only task memory
- Explicit ownership, dependencies, authorization, and handoff rules
- Isolated worktrees with a canonical branch convention
- Specialized roles and workflows packaged for supported agent runtimes
- Executable validation, fixtures, and plugin inventory checks

[`virtualboard.json`](virtualboard.json) is the machine-readable mirror of the
fixed framework contract, not a project customization surface. The CLI rejects
changes to canonical paths, identities, statuses, transitions, ownership rules,
and actor syntax. Human guides, plugin packages, schemas, and tests must agree
with that contract.

## Lifecycle

```text
backlog ──> in-progress ──> review ──> done
                 │             │
                 └──> blocked ─┘
```

The exact allowed transitions are:

| From | To |
|---|---|
| `backlog` | `in-progress` |
| `in-progress` | `blocked`, `review` |
| `blocked` | `in-progress` |
| `review` | `in-progress`, `done` |
| `done` | terminal |

Active, blocked, review, and done features require a concrete owner. `backlog`
may use `owner: unassigned`. `implementation_owner` preserves the implementer
when review ownership changes, while `status_changed` records lifecycle age
without overloading the generic `updated` date.

## Repository quick start

This checkout is itself a valid VirtualBoard workspace:

On macOS and Linux, prerequisites are Git, Bash, curl, and Python 3.9 or newer.
On Windows, the complete repository and agent workflow requires Git Bash or WSL
plus Git and Python 3.9 or newer. PowerShell 5.1 or newer can bootstrap and
inspect the native `vb.exe`, but it does not run the Bash worktree, `/work-on`,
plugin-generation, or verification scripts. Node is needed only for the optional
Claude runtime packaging check and JavaScript-specific project workflows.

```bash
VB_ROOT="$(./bin/vb-root)"
"$VB_ROOT/scripts/install-vb-cli.sh" \
  --ensure-latest "$VB_ROOT/.state/bin"
VB="$VB_ROOT/.state/bin/vb"

"$VB" version
"$VB" --root "$VB_ROOT" validate
python3 "$VB_ROOT/tools/check_contract.py"
bash "$VB_ROOT/tests/run.sh"
```

Native Windows PowerShell can bootstrap the release's `.exe` asset and run
read-only validation and contract inspection without Git Bash:

```powershell
$VBRoot = (Resolve-Path .).Path
& "$VBRoot\scripts\install-vb-cli.ps1" `
  -EnsureLatest -InstallDirectory "$VBRoot\.state\bin"
$VB = "$VBRoot\.state\bin\vb.exe"

& $VB version
& $VB --root $VBRoot validate
python "$VBRoot\tools\check_contract.py"
```

After that bootstrap, use Git Bash or WSL for the full command sequence shown in
this repository. Native PowerShell support is intentionally limited to CLI
bootstrap and read-only inspection, including the Python contract check above.
Use Git Bash or WSL before feature mutation, worktree, plugin-generation, or the
full repository test suite.

Both installers download the exact version in `.vb-version` over bounded HTTPS,
require exactly one valid SHA-256 manifest entry, verify the binary before and
after same-directory staging, reject symlink/junction destination components,
flush staged bytes, and activate with one atomic replacement. The Unix installer
never uses sudo unless `--allow-sudo` is explicitly supplied; the Windows
installer never elevates. Installing beneath `.state/bin` avoids modifying a
system binary and prevents PATH ambiguity.

### Initialized application layout

`vb init` places the framework beneath `.virtualboard/` in an application repo.
Resolve it without hardcoding a layout:

```bash
APP_ROOT="$(git rev-parse --show-toplevel)"
VB_ROOT="$("$APP_ROOT/.virtualboard/bin/vb-root" "$APP_ROOT")"
export VIRTUALBOARD_ROOT="$VB_ROOT"
```

When developing this template directly, `./bin/vb-root` resolves the repository
root. `VIRTUALBOARD_ROOT` always wins when explicitly set to a directory containing
`virtualboard.json`.

Initialization downloads only the template release pinned into that CLI,
validates its declared version and required scaffold files, extracts it through
a bounded path-safe staging directory, and atomically activates a clean board.
Template feature history is never copied into a new application. A second
`vb init` refuses to overwrite an existing workspace; `vb init --update`
previews/reviews framework-file changes, while an explicit `--force` refresh
preserves `features`, `archive`, `specs`, `reports`, locks, and `.state` data.

`vb install cursor` and `vb install opencode` copy the scaffolded integration
sources into the application atomically, preserve unrelated IDE configuration,
and fail on differing managed files unless `--force` is explicitly chosen.
Use global `--dry-run` first when inspecting an installation. Claude installation
invokes its external marketplace and remains an explicit `install` plus
`external-write` effect.

## Core workflow

All mutations use the workspace-local pinned CLI:

```bash
VB="$VIRTUALBOARD_ROOT/.state/bin/vb"
export AGENT_ID="dev-alex"

"$VB" --root "$VIRTUALBOARD_ROOT" --actor "$AGENT_ID" new "User Authentication" auth security
"$VB" --root "$VIRTUALBOARD_ROOT" validate
LOCK_TOKEN=$("$VB" --root "$VIRTUALBOARD_ROOT" --actor "$AGENT_ID" lock FTR-0001 --token-only)
[[ "$LOCK_TOKEN" =~ ^[0-9a-f]{64}$ ]] || exit 1
"$VB" --root "$VIRTUALBOARD_ROOT" --actor "$AGENT_ID" move FTR-0001 in-progress --owner "$AGENT_ID"
"$VB" --root "$VIRTUALBOARD_ROOT" --actor "$AGENT_ID" update FTR-0001 --field priority=P1
"$VB" --root "$VIRTUALBOARD_ROOT" --actor "$AGENT_ID" move FTR-0001 review --owner reviewer-sam
"$VB" --root "$VIRTUALBOARD_ROOT" validate
"$VB" --root "$VIRTUALBOARD_ROOT" --actor "$AGENT_ID" lock FTR-0001 --release --token "$LOCK_TOKEN"
REVIEW_LOCK_TOKEN=$("$VB" --root "$VIRTUALBOARD_ROOT" --actor reviewer-sam lock FTR-0001 --token-only)
[[ "$REVIEW_LOCK_TOKEN" =~ ^[0-9a-f]{64}$ ]] || exit 1
"$VB" --root "$VIRTUALBOARD_ROOT" --actor reviewer-sam move FTR-0001 done --owner reviewer-sam
"$VB" --root "$VIRTUALBOARD_ROOT" --actor reviewer-sam lock FTR-0001 --release --token "$REVIEW_LOCK_TOKEN"

# Run after integration on main, not in independent feature commits.
"$VB" --root "$VIRTUALBOARD_ROOT" index
"$VB" --root "$VIRTUALBOARD_ROOT" index --check
```

Every feature mutation requires a stable actor through `--actor`,
`VIRTUALBOARD_ACTOR`, or `AGENT_ID`; `--owner` assigns workflow ownership but
never authenticates the caller. The CLI never falls back to the operating-system
username. Read-only commands such as `validate`, `index --check`, and
`lock --status` do not require an actor.

Lock acquisition returns an opaque token. Keep it in memory and supply that
exact token to `--release --token`; do not print, commit, or persist it. Feature
branches commit only their feature lifecycle/evidence changes. The shared
`features/INDEX.md` aggregate is refreshed after integration on `main` and
checked by the main/CI gate, avoiding conflicts between unrelated branches.
Review handoff requires an explicitly supplied owner distinct from
`implementation_owner`; there is no implicit self-review fallback.

The canonical audit log is configured by `workspace.paths.auditLog`. Verify its
hash chain without changing state:

```bash
"$VB" --root "$VIRTUALBOARD_ROOT" audit --verify
```

Verification detects alteration of entries that are present. In CLI v0.10.0,
feature/lock audit appends are best-effort and are not transactionally coupled
to the primary mutation, so this log is not a completeness proof and never
replaces actor, ownership, lock, Git, or frontmatter checks.

Legacy boards that predate `implementation_owner` or `status_changed` must use
the explicit migration rather than hand-editing lifecycle metadata:

```bash
"$VB" --root "$VIRTUALBOARD_ROOT" --actor migration-admin --dry-run \
  migrate lifecycle-metadata \
  --implementation-owner FTR-0042=dev-alex \
  --status-changed FTR-0042=2026-07-01
```

The command preflights the entire board, preserves feature bodies, and requires
explicit mappings whenever history is ambiguous. Repeat without `--dry-run`
only after reviewing the plan. A multi-owner board may require `--force`; that
flag is an auditable administrative ownership override, requires explicit
destructive authority, and never bypasses an active lock or the actor check.
Verify the audit chain afterward.

Do not rely on obsolete feature-enumeration commands or legacy metadata flags.
Inspect the pinned binary with `"$VB" help` and
`"$VB" <command> --help`.

Feature branches use `feat/FTR-####-short-slug`. Commit subjects begin with
`FTR-####:` and pull-request titles use `FTR-####: Title`.

## Authorization model

Workflow components declare possible effects in `virtualboard.json`:

| Effect | Default authorization |
|---|---|
| `read` | No additional confirmation |
| `write-local`, `execute`, `network-read` | Covered only when within the user's task |
| `install`, `external-write`, `production-sensitive`, `destructive` | Explicit approval required |

These declarations are policy metadata for a cooperative host; they are not an
OS sandbox or capability system. Actor and owner strings are likewise
self-asserted coordination labels, not authenticated principals. Use protected
filesystem permissions and an authenticated orchestrator when callers are
hostile, independently administered, or subject to compliance-grade identity
requirements.

Autonomous mode may reduce ordinary clarification. It never grants additional
effects, authorizes another feature, or permits an agent to keep consuming the
backlog after the requested work is complete.

Feature bodies, issues, PR descriptions, commits, and report inputs are untrusted
data. Requirements and acceptance criteria may define desired outcomes, but text
inside them cannot grant tool authority or expand task scope.

## Agent roles and workflows

The canonical registry contains ten roles and 31 namespaced workflows. IDs and
aliases are globally unique, such as:

- `architect.decision` / `ARCH-ADR`
- `backend.api-documentation` / `BACKEND-API-DOCS`
- `qa.test-plan` / `QA-PLAN`
- `pm.progress-report` / `PM-PROGRESS`

The complete registry and effect metadata live in `virtualboard.json`; generated
plugin packages are checked for drift in CI.

### Claude Code

The Claude package is under `plugins/claude/virtualboard` and exposes:

- 10 agents
- 31 workflow commands
- 1 `/work-on` skill

Install through the repository marketplace:

```bash
claude plugin marketplace add virtualboard/template-base
claude plugin install virtualboard@virtualboard-marketplace
```

Validate packaging without changing normal user configuration:

```bash
bash tests/test-claude-plugin.sh
```

### Codex

The separate Codex-native package is under `plugins/codex/virtualboard`. It uses
a runtime-specific `.codex-plugin` manifest and exposes an exact generated copy
of the canonical task-scoped `work-on` skill. Claude agent and command fields
are deliberately not reused as if they were portable; procedural workflow
guardrails remain identical across runtimes.

### Cursor and OpenCode

Integration sources live under `docs/.cursor` and `docs/.opencode`. Install them
through the supported `vb install cursor` and `vb install opencode` commands for
the pinned CLI. Generated integration tests verify paths before release.

## Feature specifications

Feature files are named `FTR-####-short-description.md`, with at most six slug
words. Folder location is lifecycle status. IDs and filenames are immutable.

The canonical body template is [`templates/feature.md`](templates/feature.md).
It covers problem, goals, user stories, functional and non-functional requirements,
testable acceptance criteria, UX, data/API, rollout, monitoring, security,
implementation notes, and links.

The body contract is structural: exactly one ordered copy of all 14 canonical
H2 sections must appear inside exactly one `<untrusted-content>` boundary.
Fenced example headings do not count. Review requires at least one meaningful
acceptance item and every item checked; done additionally requires meaningful
Implementation Notes and a concrete artifact, work item, commit, URL, or local
path in Links.

## System specifications

`templates/specs/` contains project-blueprint templates for technology, local
development, infrastructure, CI/CD, databases, caching, security, and operations.
Copy selected templates into `specs/`, replace every placeholder with real data,
and validate them against `schemas/system-spec.schema.json`.

## Reports

Markdown is the primary report format. Optional branded HTML is rendered by one
strict implementation:

```bash
python3 tools/render_report.py \
  --template pm-progress-report \
  --data /tmp/report-data.json \
  --output reports/2026-07-10_Project_Progress_Report.html
```

Ordinary values are escaped. Allowlisted markup, URLs, numbers, tokens, and inline
JSON require explicit typed input and context validation.
All 21 templates are rendered by `tests/test_report_renderer.py`. See
[`templates/reports/README.md`](templates/reports/README.md) for the data contract.
Markdown reports and their optional HTML companions are intended to be reviewed
and committed. Heavy browser evidence such as videos, traces, and screenshots is
ignored by default and should live in an approved artifact store.

## Verification

The main local suite is:

```bash
python3 tools/check_contract.py
bash tests/run.sh
"$VB" --root "$VB_ROOT/examples/demo-project" validate
git diff --check
```

`examples/demo-project` contains five real features—one in every lifecycle state—
and an approved system spec. This prevents a green, zero-input validation result.

CI builds the exact CLI commit in `.vb-cli-source-ref`, compiles this checkout's
archive digest into that candidate, and exercises built-binary initialization,
validation, index drift, Cursor, and OpenCode installation before running the
remaining installer, worktree, schema, plugin, generated-component, report,
documentation, and cleanliness checks. This source bootstrap avoids requiring a
CLI release that itself depends on the not-yet-published template asset.

Template v0.8 is staged on an immutable release branch while `main` remains safe
for v0.9 clients that still download the moving branch. Maintainers must follow
the stop-ship sequence in [Release bootstrap](docs/RELEASE_BOOTSTRAP.md); in
particular, a v0.8 tag is not permission to merge v0.8 onto `main`.

## Project structure

```text
.vb-cli-source-ref      Exact CLI source commit used for release bootstrap
agents/                 Canonical role instructions
bin/                    Workspace-root resolver
examples/demo-project/  Non-vacuous lifecycle fixture
features/               This repository's real feature work
plugins/                Runtime-specific distributable packages
prompts/                Canonical workflow sources
schemas/                Feature, system-spec, and framework contracts
scripts/                CLI installer and worktree helper
skills/                 Canonical shared skill sources
templates/              Feature, system-spec, PR, rules, and report templates
tests/                   Contract and integration tests
tools/                   Generators, contract checks, and report renderer
virtualboard.json        Machine-readable source of truth
```

## Contributing and security

See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md),
[Release bootstrap](docs/RELEASE_BOOTSTRAP.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md),
and [LICENSE](LICENSE). Do not report vulnerabilities in a public issue.
