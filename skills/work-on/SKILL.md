---
name: work-on
description: >
  Work on a VirtualBoard feature in an isolated git worktree.
  Creates a feature branch, spawns a new Claude Code session,
  and manages the full implementation workflow.
  Use when the user wants to implement a feature spec (FTR-XXXX)
---

# /work-on - Feature Implementation Skill

Work on a VirtualBoard feature specification in an isolated git worktree with automatic branch management.

## Usage

```
/work-on FTR-XXXX [options]
```

**Options:**
- `--autonomous` or `-a`: Run in fully autonomous mode (no clarifying questions)
- `--semi-autonomous` or `-s`: Only ask questions when blocked
- `--worktree-path <path>`: Custom worktree location (default: `/tmp/virtualboard-worktrees`)
- `--base-branch <branch>`: Base branch to create feature branch from (default: auto-detect or `main`)
- `--create-pr`: Create a draft PR after pushing
- `--cleanup`: Remove worktree after pushing (implies --create-pr)

## Workflow

When this skill is invoked, follow these steps exactly:

### Step 1: Parse Input

Extract the feature ID and options from the user's input:

```bash
# Example: /work-on FTR-0042 --autonomous --worktree-path ~/worktrees
# Feature ID: FTR-0042
# Mode: autonomous
# Worktree path: ~/worktrees
```

Validate the feature ID matches pattern `FTR-\d{4}`.

### Step 2: Locate the Feature File

Search for the feature file in all status directories:

```bash
# Search pattern
find features/ -name "FTR-XXXX-*.md" 2>/dev/null | head -1
```

The feature file will be in one of:
- `features/backlog/`
- `features/in-progress/`
- `features/blocked/`
- `features/review/`

If not found, inform the user and stop.

### Step 3: Read and Parse Feature

Read the feature file and extract:
- **Title**: From frontmatter `title` field
- **Feature slug**: From filename (e.g., `FTR-0042-user-authentication.md` → `user-authentication`)
- **Status**: Current status from frontmatter
- **Requirements**: From "Requirements" section
- **Acceptance Criteria**: From "Acceptance Criteria" section
- **Implementation Notes**: From "Implementation Notes" section

Display a summary to the user:
```
Feature: FTR-XXXX - <Title>
Status: <status>
Acceptance Criteria:
- [ ] Criterion 1
- [ ] Criterion 2
...
```

### Step 4: Setup Git Worktree

Determine the worktree configuration:

```bash
# Default worktree base path
WORKTREE_BASE="${VIRTUALBOARD_WORKTREE_PATH:-/tmp/virtualboard-worktrees}"

# Branch name format
BRANCH_NAME="feature/FTR-XXXX/<feature-slug>"

# Worktree directory
WORKTREE_DIR="$WORKTREE_BASE/FTR-XXXX"
```

Run the worktree setup script:

```bash
./scripts/worktree-setup.sh <feature_id> <feature_slug> [worktree_base_path]
```

The script will:
1. Check if branch exists (local or remote)
2. Create worktree directory
3. Either checkout existing branch or create new one from main
4. Report status (new branch or existing with N commits ahead of main)

### Step 5: Detect Existing Work

If the branch already exists, analyze what work has been done:

```bash
# In the worktree directory
cd "$WORKTREE_DIR"

# Check commits ahead of main
git log main..HEAD --oneline

# Check uncommitted changes
git status --porcelain
```

If existing work is found, summarize it for the user:
```
Existing work detected on branch feature/FTR-XXXX/<slug>:
- X commits ahead of main
- Last commit: "<commit message>"
- Uncommitted changes: Y files modified
```

### Step 6: Spawn New Claude Code Session

Change to the worktree directory and start a new Claude Code session:

```bash
cd "$WORKTREE_DIR"

# Start interactive Claude Code session
claude
```

Pass context to the new session by displaying:
1. The full feature specification
2. Implementation mode (interactive/semi-autonomous/autonomous)
3. Instructions to follow the VirtualBoard agent workflow

### Step 7: Implementation Phase

In the new session, follow this implementation workflow:

#### 7a. Analyze Codebase
- Read CLAUDE.md and understand project structure
- Identify files relevant to the feature
- Understand existing patterns and conventions

#### 7b. Ask Clarifying Questions (unless autonomous)
If any requirements are unclear:
- List specific questions about implementation details
- Wait for user response before proceeding

#### 7c. Implement Feature
- Follow acceptance criteria as implementation checklist
- Make incremental changes
- Run tests after significant changes
- Update feature file with implementation notes

#### 7d. Validate Implementation
- Run project tests/linting
- Verify all acceptance criteria are met
- Check for regressions

### Step 8: Commit Changes

Stage all changes and create commit:

```bash
git add -A

git commit -m "$(cat <<'EOF'
<Descriptive commit title>

<Body explaining what was implemented and why>

- Implemented <feature aspect 1>
- Added <feature aspect 2>
- Updated <related files>

FTR-XXXX implemented using the @virtualboard /work-on skill
EOF
)"
```

**Commit message requirements:**
- First line: Clear, descriptive title (50 chars max)
- Body: Explain what was done and why
- Footer: Always include `FTR-XXXX implemented using the @virtualboard /work-on skill`

### Step 9: Push Branch

Push the branch to remote:

```bash
git push -u origin "feature/FTR-XXXX/<feature-slug>"
```

### Step 10: Post-Push Actions

Based on configuration:

**If `--create-pr` or `--cleanup`:**
```bash
gh pr create \
  --title "FTR-XXXX: <Feature Title>" \
  --body "$(cat <<'EOF'
## Summary
Implements feature FTR-XXXX: <Title>

## Changes
- <Change 1>
- <Change 2>

## Testing
- [ ] Acceptance criteria verified
- [ ] Tests passing

## Feature Spec
See `features/<status>/FTR-XXXX-<slug>.md`
EOF
)" \
  --draft
```

**If `--cleanup`:**
```bash
# Return to original repo
cd -

# Remove worktree
git worktree remove "$WORKTREE_DIR"

# Optionally prune
git worktree prune
```

### Step 11: Update Feature Status

Move the feature to `in-progress` if it was in `backlog`:

```bash
./scripts/ftr-move.sh FTR-XXXX in-progress
```

Update the feature file's frontmatter:
- `status: in-progress`
- `owner: <appropriate agent or "claude">`
- `updated: <today's date>`

## Configuration

The skill respects these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `VIRTUALBOARD_WORKTREE_PATH` | `/tmp/virtualboard-worktrees` | Base directory for worktrees |
| `VIRTUALBOARD_BASE_BRANCH` | Auto-detect or `main` | Base branch to create feature branches from |
| `VIRTUALBOARD_POST_PUSH` | `push` | Action after push: `push`, `push+pr`, `push+pr+cleanup` |
| `VIRTUALBOARD_SESSION_MODE` | `interactive` | Default mode: `interactive`, `semi-autonomous`, `autonomous` |

## Error Handling

### Feature Not Found
```
Error: Feature FTR-XXXX not found in features/ directory.
Please verify the feature ID exists.
```

### Worktree Already Exists
```
Worktree already exists at <path>.
Options:
1. Continue working in existing worktree
2. Remove and recreate: git worktree remove <path>
```

### Branch Conflicts
```
Warning: Branch feature/FTR-XXXX/<slug> has diverged from remote.
Please resolve conflicts before continuing.
```

### Push Failures
```
Error: Push failed. Please check:
- Remote repository permissions
- Branch protection rules
- Network connectivity
```

## Examples

**Basic usage:**
```
/work-on FTR-0042
```

**Autonomous mode with PR creation:**
```
/work-on FTR-0042 --autonomous --create-pr
```

**Custom worktree location:**
```
/work-on FTR-0042 --worktree-path ~/projects/worktrees
```

**Branch from develop instead of main:**
```
/work-on FTR-0042 --base-branch develop
```

**Full automation:**
```
/work-on FTR-0042 -a --cleanup
```
