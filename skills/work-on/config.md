# /work-on Skill Configuration

This document describes the configuration options for the `/work-on` skill.

## Environment Variables

### VIRTUALBOARD_WORKTREE_PATH

Base directory where git worktrees are created.

| Property | Value |
|----------|-------|
| Default | `/tmp/virtualboard-worktrees` |
| Type | Directory path |

**Example:**
```bash
export VIRTUALBOARD_WORKTREE_PATH="$HOME/worktrees"
```

Worktrees are created as subdirectories named by feature ID:
```
$VIRTUALBOARD_WORKTREE_PATH/
├── FTR-0001/
├── FTR-0042/
└── FTR-0099/
```

### VIRTUALBOARD_POST_PUSH

Action to take after pushing the feature branch.

| Property | Value |
|----------|-------|
| Default | `push` |
| Type | Enum |
| Options | `push`, `push+pr`, `push+pr+cleanup` |

**Options:**
- `push`: Push branch only (default)
- `push+pr`: Push branch and create a draft pull request
- `push+pr+cleanup`: Push, create PR, and remove the worktree

**Example:**
```bash
export VIRTUALBOARD_POST_PUSH="push+pr"
```

### VIRTUALBOARD_BASE_BRANCH

Base branch to create feature branches from.

| Property | Value |
|----------|-------|
| Default | Auto-detect from `origin/HEAD`, fallback to `main` |
| Type | Branch name |

**Example:**
```bash
export VIRTUALBOARD_BASE_BRANCH="develop"
```

This is useful for projects that use a `develop` branch or other branching strategies where features shouldn't branch directly from `main`.

### VIRTUALBOARD_SESSION_MODE

Default interaction mode for the implementation session.

| Property | Value |
|----------|-------|
| Default | `interactive` |
| Type | Enum |
| Options | `interactive`, `semi-autonomous`, `autonomous` |

**Options:**
- `interactive`: Ask clarifying questions, show progress, wait for approval
- `semi-autonomous`: Only ask questions when blocked, otherwise proceed
- `autonomous`: Complete the feature without user interaction

**Example:**
```bash
export VIRTUALBOARD_SESSION_MODE="semi-autonomous"
```

## Command Line Options

Command line options override environment variables.

| Option | Short | Description | Overrides |
|--------|-------|-------------|-----------|
| `--worktree-path <path>` | | Custom worktree location | `VIRTUALBOARD_WORKTREE_PATH` |
| `--autonomous` | `-a` | Fully autonomous mode | `VIRTUALBOARD_SESSION_MODE` |
| `--semi-autonomous` | `-s` | Semi-autonomous mode | `VIRTUALBOARD_SESSION_MODE` |
| `--create-pr` | | Create PR after push | `VIRTUALBOARD_POST_PUSH` |
| `--cleanup` | | Remove worktree after PR | `VIRTUALBOARD_POST_PUSH` |

## Configuration Precedence

1. Command line options (highest priority)
2. Environment variables
3. Default values (lowest priority)

## Shell Configuration

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) for persistent configuration:

```bash
# VirtualBoard /work-on configuration
export VIRTUALBOARD_WORKTREE_PATH="$HOME/dev/worktrees"
export VIRTUALBOARD_POST_PUSH="push+pr"
export VIRTUALBOARD_SESSION_MODE="interactive"
```

## Project-Level Configuration

You can also set these in a `.env` file at the project root:

```bash
# .env
VIRTUALBOARD_WORKTREE_PATH=/tmp/virtualboard-worktrees
VIRTUALBOARD_POST_PUSH=push
VIRTUALBOARD_SESSION_MODE=interactive
```

Note: The `.env` file must be sourced manually or by your shell tooling.
