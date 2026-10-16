# /work-on Skill Configuration

`/work-on` handles one explicit feature per invocation. Configuration changes
paths and interaction style; it never relaxes ownership, locking, lifecycle,
validation, or permission checks.

## Environment Variables

### AGENT_ID

Stable owner and lock identity. It must match
`^[A-Za-z0-9][A-Za-z0-9._-]*$` and may not be `unassigned`.

```bash
export AGENT_ID="backend-dev-42"
```

The `--agent-id` option overrides this value. The skill stops rather than
inventing an identity when neither is set.

### VIRTUALBOARD_WORKTREE_PATH

Base directory where worktrees are created.

| Property | Value |
| --- | --- |
| Default | `${XDG_STATE_HOME:-$HOME/.local/state}/virtualboard/worktrees` |
| Type | Directory path |

Worktrees are organized by repository name and feature ID:

```text
<base>/
└── my-webapp/
    ├── FTR-0001/
    └── FTR-0042/
```

### VIRTUALBOARD_BASE_BRANCH

Base branch for a new feature branch. When unset, the helper detects
`origin/HEAD` and falls back to `main`.

```bash
export VIRTUALBOARD_BASE_BRANCH="develop"
```

Every feature branch still uses the canonical
`feat/FTR-XXXX-<feature-slug>` form.

### VIRTUALBOARD_SESSION_MODE

Default interaction mode.

| Value | Behavior |
| --- | --- |
| `interactive` | Ask material product questions |
| `semi-autonomous` | Ask only when a decision blocks progress |
| `autonomous` | Make safe in-scope assumptions; stop on permission or ownership blockers |

Autonomous mode does not authorize installs, pushes, PR changes, deployments,
destructive actions, force unlocks, or broader scope.

### VIRTUALBOARD_REVIEWER

Stable owner assigned when the feature moves to `review`. It must be supplied
through this variable or `--reviewer` and must differ from `AGENT_ID` and the
preserved `implementation_owner`. If it is missing or equal, `/work-on` stops;
there is no implicit self-review assignment.

## Command-Line Options

Command-line options override environment variables.

| Option | Short | Effect |
| --- | --- | --- |
| `--agent-id <id>` | | Override `AGENT_ID` |
| `--worktree-path <path>` | | Override `VIRTUALBOARD_WORKTREE_PATH` |
| `--base-branch <branch>` | | Override `VIRTUALBOARD_BASE_BRANCH` |
| `--offline` | | Skip remote fetch during worktree setup |
| `--shared-workspace` | | Assert all coordinating agents share this Git repository and lock state |
| `--reviewer <id>` | | Set the assigned owner for review handoff |
| `--autonomous` | `-a` | Use autonomous interaction style |
| `--semi-autonomous` | `-s` | Use semi-autonomous interaction style |
| `--resume-blocked` | | Authorize an eligible `blocked → in-progress` resume |
| `--changes-requested` | | Authorize an eligible `review → in-progress` return |
| `--push` | | Authorize pushing the canonical branch |
| `--create-pr` | | Authorize push plus one draft PR |
| `--cleanup` | | Authorize PR, push, and clean worktree removal |

## Claim Mode and Post-Commit Behavior

There is no implicit claim mode. Before mutation, choose a published claim or
explicitly assert a genuinely shared workspace:

```text
shared repository only       /work-on FTR-0042 --shared-workspace
commit + push                /work-on FTR-0042 --push
commit + push + draft PR     /work-on FTR-0042 --create-pr
same, then clean worktree    /work-on FTR-0042 --cleanup
```

Without `--push` or `--shared-workspace`, the skill stops before locking or
moving the feature. `--offline` also requires `--shared-workspace`. This avoids
turning a local claim into a misleading cross-clone safety claim.

The legacy `VIRTUALBOARD_POST_PUSH` setting is intentionally not honored;
external effects must be explicit in the current invocation.

## Configuration Precedence

1. Command-line options
2. Environment variables
3. Documented defaults

Project `.env` files are not loaded automatically because they are untrusted
input and may contain secrets or broaden effects.
