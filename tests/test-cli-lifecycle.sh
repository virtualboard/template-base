#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
VB=${VB:-"$ROOT/.state/bin/vb"}
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/vb-cli-lifecycle.XXXXXX")
TESTS_RUN=0
LAST_STDOUT="$TEST_ROOT/last.stdout"
LAST_STDERR="$TEST_ROOT/last.stderr"

cleanup() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
    echo "not ok - $*" >&2
    if [[ -s "$LAST_STDOUT" ]]; then
        echo "--- command stdout ---" >&2
        sed -n '1,160p' "$LAST_STDOUT" >&2
    fi
    if [[ -s "$LAST_STDERR" ]]; then
        echo "--- command stderr ---" >&2
        sed -n '1,160p' "$LAST_STDERR" >&2
    fi
    exit 1
}

pass() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo "ok $TESTS_RUN - $*"
}

run_success() {
    local description=$1
    shift
    : > "$LAST_STDOUT"
    : > "$LAST_STDERR"
    if ! "$@" >"$LAST_STDOUT" 2>"$LAST_STDERR"; then
        fail "$description"
    fi
}

run_failure() {
    local description=$1
    shift
    : > "$LAST_STDOUT"
    : > "$LAST_STDERR"
    if "$@" >"$LAST_STDOUT" 2>"$LAST_STDERR"; then
        fail "$description"
    fi
}

frontmatter_value() {
    local field=$1
    local file=$2
    awk -v field="$field" '
        index($0, field ":") == 1 {
            value = substr($0, length(field) + 2)
            sub(/^[[:space:]]+/, "", value)
            gsub(/^"|"$/, "", value)
            print value
            exit
        }
    ' "$file"
}

replace_frontmatter_value() {
    local field=$1
    local value=$2
    local file=$3
    local temporary="$file.tmp"
    awk -v field="$field" -v value="$value" '
        index($0, field ":") == 1 { print field ": " value; next }
        { print }
    ' "$file" > "$temporary"
    mv -- "$temporary" "$file"
}

acquire_lock_token() {
    local description=$1
    shift
    local token
    : > "$LAST_STDOUT"
    : > "$LAST_STDERR"
    if ! token=$("$@" --token-only 2>"$LAST_STDERR"); then
        fail "$description"
    fi
    if [[ ! "$token" =~ ^[0-9a-f]{64}$ ]]; then
        fail "$description returned an invalid token"
    fi
    printf '%s' "$token"
}

[[ -x "$VB" ]] || fail "workspace-local vb is missing at $VB"
command -v python3 >/dev/null 2>&1 || fail "python3 is required for JSON contract assertions"

# A caller's environment must not accidentally satisfy identity checks.
unset VIRTUALBOARD_ACTOR AGENT_ID

mkdir -p \
    "$TEST_ROOT/features/backlog" \
    "$TEST_ROOT/features/in-progress" \
    "$TEST_ROOT/features/blocked" \
    "$TEST_ROOT/features/review" \
    "$TEST_ROOT/features/done" \
    "$TEST_ROOT/templates" \
    "$TEST_ROOT/schemas"
cp "$ROOT/virtualboard.json" "$TEST_ROOT/virtualboard.json"
cp "$ROOT/templates/feature.md" "$TEST_ROOT/templates/feature.md"
cp "$ROOT/schemas/frontmatter.schema.json" "$TEST_ROOT/schemas/frontmatter.schema.json"

run_failure \
    "vb new accepted a mutation without an explicit actor" \
    "$VB" --root "$TEST_ROOT" new "Missing Actor"
if find "$TEST_ROOT/features" -type f -name 'FTR-*.md' -print -quit | grep -q .; then
    fail "failed actor validation still created a feature"
fi
pass "feature mutations require an explicit actor"

run_success \
    "vb new failed with an explicit actor" \
    "$VB" --root "$TEST_ROOT" --actor implementer new \
    "One Two Three Four Five Six Seven" lifecycle contract

FEATURE_NAME=FTR-0001-one-two-three-four-five-six.md
FEATURE="$TEST_ROOT/features/backlog/$FEATURE_NAME"
[[ -f "$FEATURE" ]] || fail "vb new did not enforce the six-word slug bound"
[[ $(frontmatter_value id "$FEATURE") == FTR-0001 ]] || fail "vb new wrote the wrong feature ID"
[[ $(frontmatter_value status "$FEATURE") == backlog ]] || fail "vb new wrote the wrong initial status"
[[ $(frontmatter_value owner "$FEATURE") == unassigned ]] || fail "vb new wrote the wrong backlog owner"
[[ $(frontmatter_value implementation_owner "$FEATURE") == unassigned ]] || \
    fail "vb new omitted initial implementation provenance"
[[ $(frontmatter_value status_changed "$FEATURE") == "$(date +%F)" ]] || \
    fail "vb new omitted the lifecycle transition date"
grep -q '^risk_notes:' "$FEATURE" || fail "vb new omitted the required risk_notes field"
run_success \
    "newly created feature did not validate" \
    "$VB" --root "$TEST_ROOT" validate --only-features
pass "new features retain required provenance, risk metadata, and bounded slugs"

run_failure \
    "--owner was accepted as a substitute for caller identity" \
    "$VB" --root "$TEST_ROOT" lock FTR-0001 --owner implementer
IMPLEMENTER_LOCK_TOKEN=$(acquire_lock_token \
    "implementer could not acquire the feature lock" \
    "$VB" --root "$TEST_ROOT" --actor implementer lock FTR-0001)
[[ -f "$TEST_ROOT/.state/locks/FTR-0001.lock" ]] || fail "feature lock was not written to the contract path"
[[ ! -e "$TEST_ROOT/locks/FTR-0001.lock" ]] || fail "feature lock was also written to the legacy path"
[[ -f "$TEST_ROOT/audit.jsonl" ]] || fail "mutation audit log was not written to the backward-compatible contract path"
[[ ! -e "$TEST_ROOT/.state/audit.jsonl" ]] || fail "mutation audit log was also written to a second path"
run_success \
    "canonical audit log did not verify" \
    "$VB" --root "$TEST_ROOT" --json audit --verify
cp "$LAST_STDOUT" "$TEST_ROOT/audit-verified.json"
python3 - "$TEST_ROOT/audit-verified.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    payload = json.load(handle)
assert payload["success"] is True, payload
data = payload["data"]
assert data["path"] == "audit.jsonl", data
assert data["verified"] is True, data
assert data["total"] >= 1, data
PY
ESCAPED_LOCK="$TEST_ROOT/escaped-lock.lock"
run_failure \
    "lock ID traversal escaped the canonical lock directory" \
    "$VB" --root "$TEST_ROOT" --actor implementer lock ../../escaped-lock
[[ ! -e "$ESCAPED_LOCK" ]] || fail "rejected lock traversal created $ESCAPED_LOCK"
cp "$FEATURE" "$TEST_ROOT/before-attacker.md"
run_failure \
    "actor-only release bypassed the exact acquisition token" \
    "$VB" --root "$TEST_ROOT" --actor implementer lock FTR-0001 --release
run_failure \
    "another actor released a lock with the wrong token" \
    "$VB" --root "$TEST_ROOT" --actor attacker lock FTR-0001 --release \
    --token ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
run_failure \
    "another actor mutated a feature protected by an active lock" \
    "$VB" --root "$TEST_ROOT" --actor attacker update FTR-0001 --field priority=P0
cmp "$FEATURE" "$TEST_ROOT/before-attacker.md" >/dev/null || fail "rejected attacker mutation changed the feature"
pass "canonical locks and ownership checks reject another actor"

# Make the transition-date assertion observable even when all commands execute
# on the same day. This is test-fixture setup, not a lifecycle operation.
replace_frontmatter_value status_changed 2000-01-01 "$FEATURE"
run_success \
    "implementer could not claim the backlog feature" \
    "$VB" --root "$TEST_ROOT" --actor implementer move FTR-0001 in-progress --owner implementer
FEATURE="$TEST_ROOT/features/in-progress/$FEATURE_NAME"
[[ -f "$FEATURE" ]] || fail "claim did not move the immutable feature basename into in-progress"
[[ ! -e "$TEST_ROOT/features/backlog/$FEATURE_NAME" ]] || fail "claim left a second lifecycle copy behind"
[[ $(frontmatter_value owner "$FEATURE") == implementer ]] || fail "claim did not assign the current owner"
[[ $(frontmatter_value implementation_owner "$FEATURE") == implementer ]] || \
    fail "claim did not record the implementation owner"
[[ $(frontmatter_value status_changed "$FEATURE") == "$(date +%F)" ]] || fail "claim did not refresh status_changed"
pass "backlog to in-progress records lifecycle provenance atomically"

for managed_field in id status owner created updated implementation_owner status_changed; do
    cp "$FEATURE" "$TEST_ROOT/before-managed-update.md"
    run_failure \
        "managed field $managed_field was directly mutable" \
        "$VB" --root "$TEST_ROOT" --actor implementer update FTR-0001 \
        --field "$managed_field=forbidden"
    cmp "$FEATURE" "$TEST_ROOT/before-managed-update.md" >/dev/null || \
        fail "rejected update of $managed_field changed the feature"
done
run_success \
    "ordinary priority update was rejected" \
    "$VB" --root "$TEST_ROOT" --actor implementer update FTR-0001 --field priority=P1
run_success \
    "ordinary title update was rejected" \
    "$VB" --root "$TEST_ROOT" --actor implementer update FTR-0001 --field title="Renamed Contract Probe"
[[ -f "$FEATURE" ]] || fail "title update renamed the immutable feature basename"
[[ $(frontmatter_value priority "$FEATURE") == P1 ]] || fail "ordinary field update did not persist"
pass "managed lifecycle fields and the feature basename are immutable"

run_success \
    "initial index generation failed" \
    "$VB" --root "$TEST_ROOT" index
INDEX="$TEST_ROOT/features/INDEX.md"
[[ -f "$INDEX" ]] || fail "index generation did not create features/INDEX.md"
cp "$INDEX" "$TEST_ROOT/index-first.md"
run_success \
    "repeat index generation failed" \
    "$VB" --root "$TEST_ROOT" index
cmp "$INDEX" "$TEST_ROOT/index-first.md" >/dev/null || fail "unchanged feature state produced a different index"
run_success \
    "index --check rejected the canonical index" \
    "$VB" --root "$TEST_ROOT" index --check

printf '\n<!-- intentional drift -->\n' >> "$INDEX"
cp "$INDEX" "$TEST_ROOT/index-drift.md"
run_failure \
    "index --check accepted a drifted index" \
    "$VB" --root "$TEST_ROOT" index --check
cmp "$INDEX" "$TEST_ROOT/index-drift.md" >/dev/null || fail "index --check rewrote the drifted target"
run_success \
    "index regeneration after drift failed" \
    "$VB" --root "$TEST_ROOT" index

ESCAPED_INDEX="$(dirname "$TEST_ROOT")/$(basename "$TEST_ROOT").escaped-index.md"
run_failure \
    "index output traversal escaped the workspace" \
    "$VB" --root "$TEST_ROOT" index --output "../$(basename "$ESCAPED_INDEX")"
[[ ! -e "$ESCAPED_INDEX" ]] || fail "rejected index traversal created $ESCAPED_INDEX"

cp "$INDEX" "$TEST_ROOT/index-before-dry-run.md"
run_success \
    "JSON dry-run index generation failed" \
    "$VB" --root "$TEST_ROOT" --dry-run --json index
cp "$LAST_STDOUT" "$TEST_ROOT/index-dry-run.json"
python3 - "$TEST_ROOT/index-dry-run.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    payload = json.load(handle)
assert payload["success"] is True, payload
data = payload["data"]
assert data["written"] is False, data
assert data["dry_run"] is True, data
assert data["checked"] is False, data
PY
cmp "$INDEX" "$TEST_ROOT/index-before-dry-run.md" >/dev/null || fail "dry-run index generation changed the target"
pass "indexes are deterministic, checkable, and truthful in JSON dry-run mode"

run_success \
    "acceptance evidence update failed before review" \
    "$VB" --root "$TEST_ROOT" --actor implementer update FTR-0001 \
    --body-section 'Acceptance Criteria (Testable)=- [x] Lifecycle ownership, token release, and terminal review are covered.'
run_success \
    "implementation evidence update failed before review" \
    "$VB" --root "$TEST_ROOT" --actor implementer update FTR-0001 \
    --body-section 'Implementation Notes=- Exercised lifecycle moves, ownership restoration, exact-token releases, and validation.'
run_success \
    "artifact reference update failed before review" \
    "$VB" --root "$TEST_ROOT" --actor implementer update FTR-0001 \
    --body-section 'Links=- FTR-0001 lifecycle compatibility evidence'
run_failure \
    "implementation owner was accepted as its own reviewer" \
    "$VB" --root "$TEST_ROOT" --actor implementer move FTR-0001 review \
    --owner implementer
[[ -f "$FEATURE" ]] || fail "rejected self-review moved the feature"

replace_frontmatter_value status_changed 2000-01-01 "$FEATURE"
run_success \
    "implementer could not hand the feature to review" \
    "$VB" --root "$TEST_ROOT" --actor implementer move FTR-0001 review --owner reviewer
FEATURE="$TEST_ROOT/features/review/$FEATURE_NAME"
[[ $(frontmatter_value owner "$FEATURE") == reviewer ]] || fail "review handoff did not assign the reviewer"
[[ $(frontmatter_value implementation_owner "$FEATURE") == implementer ]] || \
    fail "review handoff lost the implementation owner"
[[ $(frontmatter_value status_changed "$FEATURE") == "$(date +%F)" ]] || \
    fail "review handoff did not refresh status_changed"
run_success \
    "implementer could not release its lock after handoff" \
    "$VB" --root "$TEST_ROOT" --actor implementer lock FTR-0001 --release \
    --token "$IMPLEMENTER_LOCK_TOKEN"
REVIEWER_LOCK_TOKEN=$(acquire_lock_token \
    "reviewer could not acquire the review lock" \
    "$VB" --root "$TEST_ROOT" --actor reviewer lock FTR-0001)
cp "$FEATURE" "$TEST_ROOT/before-invalid-review-handback.md"
run_failure \
    "reviewer handed changes to an actor other than the preserved implementer" \
    "$VB" --root "$TEST_ROOT" --actor reviewer move FTR-0001 in-progress --owner attacker
cmp "$FEATURE" "$TEST_ROOT/before-invalid-review-handback.md" >/dev/null || \
    fail "rejected review handback changed the feature"
run_success \
    "reviewer could not return requested changes to the preserved implementer" \
    "$VB" --root "$TEST_ROOT" --actor reviewer move FTR-0001 in-progress
FEATURE="$TEST_ROOT/features/in-progress/$FEATURE_NAME"
[[ $(frontmatter_value owner "$FEATURE") == implementer ]] || \
    fail "review handback did not restore the preserved implementer"
[[ $(frontmatter_value implementation_owner "$FEATURE") == implementer ]] || \
    fail "review handback rewrote implementation provenance"
run_success \
    "reviewer could not release its lock after requested changes" \
    "$VB" --root "$TEST_ROOT" --actor reviewer lock FTR-0001 --release \
    --token "$REVIEWER_LOCK_TOKEN"
IMPLEMENTER_RETURN_LOCK_TOKEN=$(acquire_lock_token \
    "implementer could not reacquire the returned feature" \
    "$VB" --root "$TEST_ROOT" --actor implementer lock FTR-0001)
[[ "$IMPLEMENTER_RETURN_LOCK_TOKEN" != "$IMPLEMENTER_LOCK_TOKEN" ]] || \
    fail "reacquired implementer lock reused its prior acquisition token"
run_failure \
    "stale implementer token released a newer same-owner acquisition" \
    "$VB" --root "$TEST_ROOT" --actor implementer lock FTR-0001 --release \
    --token "$IMPLEMENTER_LOCK_TOKEN"
run_success \
    "implementer could not return the revised feature to review" \
    "$VB" --root "$TEST_ROOT" --actor implementer move FTR-0001 review --owner reviewer
FEATURE="$TEST_ROOT/features/review/$FEATURE_NAME"
run_success \
    "implementer could not release its revised feature lock" \
    "$VB" --root "$TEST_ROOT" --actor implementer lock FTR-0001 --release \
    --token "$IMPLEMENTER_RETURN_LOCK_TOKEN"
REVIEWER_FINAL_LOCK_TOKEN=$(acquire_lock_token \
    "reviewer could not reacquire the revised review" \
    "$VB" --root "$TEST_ROOT" --actor reviewer lock FTR-0001)
[[ "$REVIEWER_FINAL_LOCK_TOKEN" != "$REVIEWER_LOCK_TOKEN" ]] || \
    fail "reacquired reviewer lock reused its prior acquisition token"
run_failure \
    "stale reviewer token released a newer same-owner acquisition" \
    "$VB" --root "$TEST_ROOT" --actor reviewer lock FTR-0001 --release \
    --token "$REVIEWER_LOCK_TOKEN"
replace_frontmatter_value status_changed 2000-01-01 "$FEATURE"
run_success \
    "reviewer could not approve review to done" \
    "$VB" --root "$TEST_ROOT" --actor reviewer move FTR-0001 done --owner reviewer
FEATURE="$TEST_ROOT/features/done/$FEATURE_NAME"
[[ $(frontmatter_value owner "$FEATURE") == reviewer ]] || fail "done transition lost the reviewer owner"
[[ $(frontmatter_value implementation_owner "$FEATURE") == implementer ]] || \
    fail "done transition lost implementation provenance"
[[ $(frontmatter_value status_changed "$FEATURE") == "$(date +%F)" ]] || \
    fail "done transition did not refresh status_changed"
cp "$FEATURE" "$TEST_ROOT/before-terminal-transition.md"
run_failure \
    "terminal done feature accepted another transition" \
    "$VB" --root "$TEST_ROOT" --actor reviewer move FTR-0001 review --owner reviewer
[[ -f "$FEATURE" ]] || fail "rejected terminal transition moved the feature"
cmp "$FEATURE" "$TEST_ROOT/before-terminal-transition.md" >/dev/null || \
    fail "rejected terminal transition rewrote the feature"
run_success \
    "reviewer could not release the completed feature lock" \
    "$VB" --root "$TEST_ROOT" --actor reviewer lock FTR-0001 --release \
    --token "$REVIEWER_FINAL_LOCK_TOKEN"
grep -q '^risk_notes:' "$FEATURE" || fail "lifecycle transitions dropped required risk metadata"
pass "review handback preserves the implementer and review to done is terminal"

replace_frontmatter_value priority P9 "$FEATURE"
: > "$LAST_STDOUT"
: > "$LAST_STDERR"
if "$VB" --root "$TEST_ROOT" --json validate --only-features \
    >"$LAST_STDOUT" 2>"$LAST_STDERR"; then
    fail "invalid JSON-mode validation returned a zero exit status"
fi
cp "$LAST_STDOUT" "$TEST_ROOT/invalid-validation.json"
python3 - "$TEST_ROOT/invalid-validation.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    payload = json.load(handle)
assert payload["success"] is False, payload
features = payload["data"]["features"]
assert features["invalid"] >= 1, features
PY
replace_frontmatter_value priority P1 "$FEATURE"
run_success \
    "restored feature failed validation" \
    "$VB" --root "$TEST_ROOT" validate --only-features
pass "JSON validation failures return a nonzero process status"

MIGRATION_ROOT="$TEST_ROOT/migration-workspace"
mkdir -p \
    "$MIGRATION_ROOT/features/backlog" \
    "$MIGRATION_ROOT/features/in-progress" \
    "$MIGRATION_ROOT/features/blocked" \
    "$MIGRATION_ROOT/features/review" \
    "$MIGRATION_ROOT/features/done" \
    "$MIGRATION_ROOT/templates" \
    "$MIGRATION_ROOT/schemas"
cp "$ROOT/virtualboard.json" "$MIGRATION_ROOT/virtualboard.json"
cp "$ROOT/templates/feature.md" "$MIGRATION_ROOT/templates/feature.md"
cp "$ROOT/schemas/frontmatter.schema.json" "$MIGRATION_ROOT/schemas/frontmatter.schema.json"
LEGACY_FEATURE="$MIGRATION_ROOT/features/review/FTR-0042-legacy-review.md"
cat > "$LEGACY_FEATURE" <<'EOF'
---
id: FTR-0042
title: Legacy Review
status: review
owner: reviewer
priority: P2
complexity: M
created: 2024-01-01
updated: 2024-01-02
labels: [migration]
dependencies: []
risk_notes: ""
---

# Feature Spec: Legacy Review

## Summary

MIGRATION-BODY-SENTINEL
EOF
cp "$LEGACY_FEATURE" "$TEST_ROOT/legacy-before-preflight.md"
run_failure \
    "ambiguous lifecycle migration passed preflight without explicit provenance" \
    "$VB" --root "$MIGRATION_ROOT" --actor reviewer migrate lifecycle-metadata
cmp "$LEGACY_FEATURE" "$TEST_ROOT/legacy-before-preflight.md" >/dev/null || \
    fail "failed migration preflight partially rewrote a legacy feature"

run_success \
    "lifecycle migration dry-run failed with explicit provenance" \
    "$VB" --root "$MIGRATION_ROOT" --actor reviewer --dry-run --json \
    migrate lifecycle-metadata \
    --implementation-owner FTR-0042=implementer \
    --status-changed FTR-0042=2024-01-03
cp "$LAST_STDOUT" "$TEST_ROOT/migration-dry-run.json"
python3 - "$TEST_ROOT/migration-dry-run.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    payload = json.load(handle)
assert payload["success"] is True, payload
data = payload["data"]
assert data["changed"] == 1, data
assert data["dry_run"] is True, data
assert data["features"] == ["FTR-0042"], data
PY
cmp "$LEGACY_FEATURE" "$TEST_ROOT/legacy-before-preflight.md" >/dev/null || \
    fail "dry-run lifecycle migration rewrote a legacy feature"

run_success \
    "lifecycle migration failed with explicit provenance" \
    "$VB" --root "$MIGRATION_ROOT" --actor reviewer migrate lifecycle-metadata \
    --implementation-owner FTR-0042=implementer \
    --status-changed FTR-0042=2024-01-03
[[ $(frontmatter_value implementation_owner "$LEGACY_FEATURE") == implementer ]] || \
    fail "lifecycle migration did not record the explicit implementation owner"
[[ $(frontmatter_value status_changed "$LEGACY_FEATURE") == 2024-01-03 ]] || \
    fail "lifecycle migration did not record the explicit transition date"
grep -q '^MIGRATION-BODY-SENTINEL$' "$LEGACY_FEATURE" || \
    fail "lifecycle migration did not preserve the feature body"
run_success \
    "repeating a completed lifecycle migration was not idempotent" \
    "$VB" --root "$MIGRATION_ROOT" --actor reviewer --json migrate lifecycle-metadata
cp "$LAST_STDOUT" "$TEST_ROOT/migration-idempotent.json"
python3 - "$TEST_ROOT/migration-idempotent.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    payload = json.load(handle)
assert payload["success"] is True, payload
data = payload["data"]
assert data["changed"] == 0, data
assert data["dry_run"] is False, data
PY
pass "lifecycle migration preflights, preserves bodies, and is idempotent"

MULTI_OWNER_FEATURE="$MIGRATION_ROOT/features/review/FTR-0043-multi-owner-review.md"
cat > "$MULTI_OWNER_FEATURE" <<'EOF'
---
id: FTR-0043
title: Multi Owner Review
status: review
owner: other-reviewer
priority: P2
complexity: M
created: 2024-02-01
updated: 2024-02-02
labels: [migration]
dependencies: []
risk_notes: ""
---
# Feature Spec: Multi Owner Review

## Summary

MULTI-OWNER-BODY-SENTINEL
EOF
cp "$MULTI_OWNER_FEATURE" "$TEST_ROOT/multi-owner-before.md"
run_failure \
    "multi-owner migration bypassed ownership without administrative force" \
    "$VB" --root "$MIGRATION_ROOT" --actor migration-admin migrate lifecycle-metadata \
    --implementation-owner FTR-0043=other-implementer \
    --status-changed FTR-0043=2024-02-03
cmp "$MULTI_OWNER_FEATURE" "$TEST_ROOT/multi-owner-before.md" >/dev/null || \
    fail "rejected multi-owner migration changed the feature"
run_success \
    "administrative multi-owner migration failed" \
    "$VB" --root "$MIGRATION_ROOT" --actor migration-admin migrate lifecycle-metadata --force \
    --implementation-owner FTR-0043=other-implementer \
    --status-changed FTR-0043=2024-02-03
[[ $(frontmatter_value implementation_owner "$MULTI_OWNER_FEATURE") == other-implementer ]] || \
    fail "administrative migration did not preserve the explicit implementer"
[[ $(frontmatter_value status_changed "$MULTI_OWNER_FEATURE") == 2024-02-03 ]] || \
    fail "administrative migration did not preserve the explicit transition date"
grep -q '^MULTI-OWNER-BODY-SENTINEL$' "$MULTI_OWNER_FEATURE" || \
    fail "administrative migration rewrote the feature body"
run_success \
    "migration audit chain did not verify" \
    "$VB" --root "$MIGRATION_ROOT" audit --verify
grep -q 'migrate-lifecycle-metadata' "$MIGRATION_ROOT/audit.jsonl" || \
    fail "administrative migration did not emit canonical audit evidence"
pass "multi-owner migration requires explicit, lock-respecting administrative force"

DUPLICATE="$TEST_ROOT/features/done/FTR-0001-duplicate.md"
cp "$FEATURE" "$DUPLICATE"
cp "$FEATURE" "$TEST_ROOT/before-duplicate-lookup.md"
run_failure \
    "point mutation selected one of two duplicate feature IDs" \
    "$VB" --root "$TEST_ROOT" --actor reviewer update FTR-0001 --field priority=P0
cmp "$FEATURE" "$TEST_ROOT/before-duplicate-lookup.md" >/dev/null || \
    fail "ambiguous point mutation changed the original feature"
cmp "$DUPLICATE" "$TEST_ROOT/before-duplicate-lookup.md" >/dev/null || \
    fail "ambiguous point mutation changed the duplicate feature"
run_failure \
    "workspace validation accepted duplicate feature IDs" \
    "$VB" --root "$TEST_ROOT" validate --only-features
pass "duplicate IDs fail closed for point lookup and workspace validation"

echo "1..$TESTS_RUN"
