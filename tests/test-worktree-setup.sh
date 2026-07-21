#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
WORKTREE_SETUP="$ROOT/scripts/worktree-setup.sh"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/vb-worktree-test.XXXXXX")
TESTS_RUN=0

cleanup() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
    echo "not ok - $*" >&2
    exit 1
}

pass() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo "ok $TESTS_RUN - $*"
}

json_get() {
    local key=$1
    python3 -c 'import json, sys; print(json.load(sys.stdin)[sys.argv[1]])' "$key"
}

new_repo() {
    local name=$1
    REPO="$TEST_ROOT/$name"
    mkdir -p "$REPO"
    git -C "$REPO" init -q
    git -C "$REPO" symbolic-ref HEAD refs/heads/main
    git -C "$REPO" \
        -c user.name=Automation-Test \
        -c user.email=automation-test@example.invalid \
        -c commit.gpgsign=false \
        commit --allow-empty -qm initial
    WORKTREE_BASE="$TEST_ROOT/worktrees-$name"
}

# A local main branch is a reliable fallback when origin/HEAD is absent.
new_repo local-main
JSON_RESULT=$(
    cd "$REPO"
    "$WORKTREE_SETUP" FTR-0042 safe-feature "$WORKTREE_BASE" --json 2>"$TEST_ROOT/local-main.stderr"
)
[[ "$(printf '%s' "$JSON_RESULT" | json_get success)" == True ]] || fail "JSON success result was invalid"
[[ "$(printf '%s' "$JSON_RESULT" | json_get base_ref)" == main ]] || fail "main fallback was not selected"
[[ "$(printf '%s' "$JSON_RESULT" | json_get branch)" == feat/FTR-0042-safe-feature ]] || fail "branch name is not canonical"
WORKTREE_DIR=$(printf '%s' "$JSON_RESULT" | json_get worktree_path)
[[ -d "$WORKTREE_DIR" ]] || fail "worktree directory was not created"
[[ "$(git -C "$WORKTREE_DIR" branch --show-current)" == feat/FTR-0042-safe-feature ]] || fail "wrong branch checked out"
pass "resolves local main without origin and creates the canonical branch"

# JSON mode emits a single parseable object and recognizes an existing worktree.
EXISTING_RESULT=$(
    cd "$REPO"
    "$WORKTREE_SETUP" FTR-0042 safe-feature "$WORKTREE_BASE" --json 2>"$TEST_ROOT/existing.stderr"
)
[[ "$(printf '%s' "$EXISTING_RESULT" | json_get status)" == existing ]] || fail "existing worktree was not recognized"
[[ "$(printf '%s' "$EXISTING_RESULT" | wc -l | tr -d ' ')" == 0 ]] || fail "JSON result contained multiple lines"
pass "JSON mode returns one stable object for an existing worktree"

# A registered directory on another branch is not the requested feature
# worktree and must never be silently reused.
git -C "$WORKTREE_DIR" checkout -qb unrelated-branch
if (
    cd "$REPO"
    "$WORKTREE_SETUP" FTR-0042 safe-feature "$WORKTREE_BASE" --json
) >"$TEST_ROOT/wrong-branch.out" 2>"$TEST_ROOT/wrong-branch.err"; then
    fail "registered worktree on another branch was silently reused"
fi
grep -q "expected 'feat/FTR-0042-safe-feature'" "$TEST_ROOT/wrong-branch.out" \
    || fail "wrong-branch worktree error was not useful"
git -C "$WORKTREE_DIR" checkout -q feat/FTR-0042-safe-feature
pass "rejects a registered worktree on the wrong branch"

# Invalid slugs are rejected before Git or filesystem mutation.
if (
    cd "$REPO"
    "$WORKTREE_SETUP" FTR-0043 '../unsafe slug' "$WORKTREE_BASE" --json
) >"$TEST_ROOT/invalid-slug.out" 2>"$TEST_ROOT/invalid-slug.err"; then
    fail "invalid feature slug was accepted"
fi
[[ "$(json_get success < "$TEST_ROOT/invalid-slug.out")" == False ]] || fail "invalid slug did not return structured error"
pass "rejects unsafe feature slugs"

if (
    cd "$REPO"
    "$WORKTREE_SETUP" FTR-0044 'one-two-three-four-five-six-seven' "$WORKTREE_BASE" --json
) >"$TEST_ROOT/long-slug.out" 2>"$TEST_ROOT/long-slug.err"; then
    fail "overlong feature slug was accepted"
fi
grep -q 'six-word limit' "$TEST_ROOT/long-slug.out" || fail "overlong slug error was not useful"
pass "enforces the configured six-word slug limit"

# Existing directories not registered with Git are preserved and cause failure.
UNOWNED_DIR="$(cd "$WORKTREE_BASE" && pwd -P)/$(basename "$REPO")/FTR-0043"
mkdir -p "$UNOWNED_DIR"
printf 'preserve me\n' > "$UNOWNED_DIR/sentinel"
if (
    cd "$REPO"
    "$WORKTREE_SETUP" FTR-0043 another-feature "$WORKTREE_BASE" --json
) >"$TEST_ROOT/unowned.out" 2>"$TEST_ROOT/unowned.err"; then
    fail "unregistered directory was accepted"
fi
[[ -f "$UNOWNED_DIR/sentinel" ]] || fail "unregistered directory was removed or altered"
pass "refuses to overwrite unregistered directories without deleting them"

# Fetch failures are surfaced, while --no-fetch permits an intentional local-only run.
new_repo fetch-failure
git -C "$REPO" remote add origin "$TEST_ROOT/does-not-exist.git"
if (
    cd "$REPO"
    "$WORKTREE_SETUP" FTR-0050 fetch-probe "$WORKTREE_BASE" --json
) >"$TEST_ROOT/fetch-failure.out" 2>"$TEST_ROOT/fetch-failure.err"; then
    fail "fetch failure was silently ignored"
fi
grep -q 'command failed' "$TEST_ROOT/fetch-failure.out" || fail "fetch failure was not reported"
LOCAL_RESULT=$(
    cd "$REPO"
    "$WORKTREE_SETUP" FTR-0050 fetch-probe "$WORKTREE_BASE" --no-fetch --json 2>"$TEST_ROOT/no-fetch.stderr"
)
[[ "$(printf '%s' "$LOCAL_RESULT" | json_get success)" == True ]] || fail "--no-fetch local run failed"
pass "surfaces fetch failures and supports explicit local-only operation"

# Explicit unresolved base refs fail with a useful structured error.
new_repo invalid-base
if (
    cd "$REPO"
    "$WORKTREE_SETUP" FTR-0060 base-probe "$WORKTREE_BASE" --base-branch missing-ref --json
) >"$TEST_ROOT/invalid-base.out" 2>"$TEST_ROOT/invalid-base.err"; then
    fail "unresolved base ref was accepted"
fi
grep -q "does not resolve" "$TEST_ROOT/invalid-base.out" || fail "unresolved base ref error was not useful"
pass "rejects unresolved explicit base refs"

# A fetched remote claim always wins over a stale or diverged local branch.
REMOTE="$TEST_ROOT/claim-origin.git"
SEED="$TEST_ROOT/claim-seed"
CLONE_A="$TEST_ROOT/claim-a"
CLONE_B="$TEST_ROOT/claim-b"
git init --bare -q "$REMOTE"
git clone -q "$REMOTE" "$SEED"
git -C "$SEED" symbolic-ref HEAD refs/heads/main
git -C "$SEED" \
    -c user.name=Automation-Test \
    -c user.email=automation-test@example.invalid \
    -c commit.gpgsign=false \
    commit --allow-empty -qm initial
git -C "$SEED" push -q -u origin main
git --git-dir="$REMOTE" symbolic-ref HEAD refs/heads/main
git clone -q "$REMOTE" "$CLONE_A"
git clone -q "$REMOTE" "$CLONE_B"

CLAIM_BRANCH=feat/FTR-0070-remote-claim
git -C "$CLONE_A" branch "$CLAIM_BRANCH" main
git -C "$CLONE_B" checkout -qb "$CLAIM_BRANCH"
git -C "$CLONE_B" \
    -c user.name=Remote-Claimer \
    -c user.email=remote-claimer@example.invalid \
    -c commit.gpgsign=false \
    commit --allow-empty -qm 'FTR-0070: publish claim'
git -C "$CLONE_B" push -q -u origin "$CLAIM_BRANCH"

if (
    cd "$CLONE_A"
    "$WORKTREE_SETUP" FTR-0070 remote-claim "$TEST_ROOT/claim-worktrees" --json
) >"$TEST_ROOT/stale-claim.out" 2>"$TEST_ROOT/stale-claim.err"; then
    fail "stale local claim branch ignored the newer remote claim"
fi
grep -q "behind origin/$CLAIM_BRANCH" "$TEST_ROOT/stale-claim.out" \
    || fail "stale local claim error did not identify the newer remote claim"
pass "rejects a stale local branch after fetching a newer remote claim"

git -C "$CLONE_A" checkout -q "$CLAIM_BRANCH"
git -C "$CLONE_A" \
    -c user.name=Local-Claimer \
    -c user.email=local-claimer@example.invalid \
    -c commit.gpgsign=false \
    commit --allow-empty -qm 'FTR-0070: conflicting local claim'
if (
    cd "$CLONE_A"
    "$WORKTREE_SETUP" FTR-0070 remote-claim "$TEST_ROOT/claim-worktrees" --json
) >"$TEST_ROOT/diverged-claim.out" 2>"$TEST_ROOT/diverged-claim.err"; then
    fail "diverged local and remote claim branches were accepted"
fi
grep -q "diverges from origin/$CLAIM_BRANCH" "$TEST_ROOT/diverged-claim.out" \
    || fail "diverged claim error was not useful"
pass "rejects diverged local and remote claim branches"

# A narrow origin refspec must not hide an exact remote claim branch. The
# helper probes and fetches the canonical ref explicitly before branch setup.
NARROW_BRANCH=feat/FTR-0071-narrow-refspec
git -C "$CLONE_B" checkout -q main
git -C "$CLONE_B" checkout -qb "$NARROW_BRANCH"
git -C "$CLONE_B" \
    -c user.name=Remote-Claimer \
    -c user.email=remote-claimer@example.invalid \
    -c commit.gpgsign=false \
    commit --allow-empty -qm 'FTR-0071: publish narrow-refspec claim'
git -C "$CLONE_B" push -q -u origin "$NARROW_BRANCH"
NARROW_OID=$(git -C "$CLONE_B" rev-parse HEAD)

git -C "$CLONE_A" config --unset-all remote.origin.fetch
git -C "$CLONE_A" config --add remote.origin.fetch \
    '+refs/heads/main:refs/remotes/origin/main'
git -C "$CLONE_A" update-ref -d "refs/remotes/origin/$NARROW_BRANCH"
NARROW_RESULT=$(
    cd "$CLONE_A"
    "$WORKTREE_SETUP" FTR-0071 narrow-refspec "$TEST_ROOT/claim-worktrees" --json \
        2>"$TEST_ROOT/narrow-refspec.err"
)
[[ "$(printf '%s' "$NARROW_RESULT" | json_get status)" == remote_branch ]] \
    || fail "exact remote claim was not selected with a narrow fetch refspec"
NARROW_WORKTREE=$(printf '%s' "$NARROW_RESULT" | json_get worktree_path)
[[ "$(git -C "$NARROW_WORKTREE" rev-parse HEAD)" == "$NARROW_OID" ]] \
    || fail "worktree did not use the exact published claim commit"
pass "detects and fetches an exact remote claim outside a narrow refspec"

echo "1..$TESTS_RUN"
