#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/vb-schema-test.XXXXXX")
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

command -v vb >/dev/null 2>&1 || fail "vb is required for schema contract tests"

mkdir -p \
    "$TEST_ROOT/features/backlog" \
    "$TEST_ROOT/features/blocked" \
    "$TEST_ROOT/features/in-progress" \
    "$TEST_ROOT/features/review" \
    "$TEST_ROOT/features/done" \
    "$TEST_ROOT/specs" \
    "$TEST_ROOT/schemas"
cp "$ROOT/schemas/frontmatter.schema.json" "$TEST_ROOT/schemas/"
cp "$ROOT/schemas/system-spec.schema.json" "$TEST_ROOT/schemas/"
printf '0.7.0\n' > "$TEST_ROOT/.template-version"
TODAY=$(date +%F)

write_feature() {
    local path=$1
    local status=$2
    local owner=$3
    local labels=${4:-'[contract]'}
    local implementation_owner=${5:-$owner}
    cat > "$path" <<EOF
---
id: FTR-0001
title: Contract Probe
status: $status
owner: $owner
implementation_owner: $implementation_owner
priority: P2
complexity: S
created: "$TODAY"
updated: "$TODAY"
status_changed: "$TODAY"
labels: $labels
dependencies: []
risk_notes: "Contract fixture only."
---
# Feature Spec: Contract Probe

<untrusted-content>

## Summary
Exercise the lifecycle schema contract.

## Problem Statement
Invalid metadata must fail validation deterministically.

## Goals & Non-Goals
- **Goal:** Verify lifecycle schema rules.
- **Non-Goal:** Implement application behavior.

## User Stories
- As a maintainer, I want invalid metadata rejected so fixtures remain trustworthy.

## Requirements
### Functional
- Validate the selected lifecycle metadata.

### Non-Functional
- Keep the fixture deterministic.

## Acceptance Criteria (Testable)
- [x] The focused schema assertion passes.

## UI/UX Notes
- No user interface is involved.

## Data & API
- Only feature frontmatter is under test.

## Rollout & Migration
- This is an isolated temporary fixture.

## Monitoring & Metrics
- The shell test exit status is the signal.

## Security & Compliance
- No secrets or external systems are used.

## Implementation Notes
- The fixture is generated and validated by tests/test-schema-contract.sh.

## Open Questions
- None.

## Links
- [Canonical schema copy](../../schemas/frontmatter.schema.json)

</untrusted-content>
EOF
}

write_spec() {
    local date_value=$1
    cat > "$TEST_ROOT/specs/contract.md" <<EOF
---
spec_type: tech-stack
title: Contract Specification
owner: platform
status: draft
last_updated: $date_value
applicability: [web]
related_initiatives: []
---
# Contract Specification
EOF
}

# Backlog may remain explicitly unassigned.
write_feature "$TEST_ROOT/features/backlog/FTR-0001-contract-probe.md" backlog unassigned
if ! vb --root "$TEST_ROOT" validate --only-features >"$TEST_ROOT/backlog-valid.out" 2>&1; then
    cat "$TEST_ROOT/backlog-valid.out" >&2
    fail "valid backlog contract probe did not validate"
fi
pass "backlog permits the explicit unassigned owner"

# Entering in-progress requires a concrete owner.
mv "$TEST_ROOT/features/backlog/FTR-0001-contract-probe.md" "$TEST_ROOT/features/in-progress/"
write_feature "$TEST_ROOT/features/in-progress/FTR-0001-contract-probe.md" in-progress unassigned
if vb --root "$TEST_ROOT" validate --only-features >"$TEST_ROOT/unassigned.out" 2>&1; then
    fail "in-progress feature with unassigned owner passed validation"
fi
grep -q owner "$TEST_ROOT/unassigned.out" || fail "owner validation error was not reported"
write_feature "$TEST_ROOT/features/in-progress/FTR-0001-contract-probe.md" in-progress automation-agent
vb --root "$TEST_ROOT" validate --only-features >/dev/null
pass "in-progress requires and accepts a concrete owner"

# Owner identities are stable machine-safe handles, not arbitrary prose.
write_feature "$TEST_ROOT/features/in-progress/FTR-0001-contract-probe.md" in-progress 'agent with spaces'
if vb --root "$TEST_ROOT" validate --only-features >"$TEST_ROOT/invalid-owner.out" 2>&1; then
    fail "owner containing spaces passed validation"
fi
write_feature "$TEST_ROOT/features/in-progress/FTR-0001-contract-probe.md" in-progress automation-agent
pass "owner identities use the canonical stable-handle pattern"

# A blocked feature came from active work and must retain a concrete owner.
mv "$TEST_ROOT/features/in-progress/FTR-0001-contract-probe.md" "$TEST_ROOT/features/blocked/"
write_feature "$TEST_ROOT/features/blocked/FTR-0001-contract-probe.md" blocked unassigned
if vb --root "$TEST_ROOT" validate --only-features >"$TEST_ROOT/blocked-unassigned.out" 2>&1; then
    fail "blocked feature with unassigned owner passed validation"
fi
write_feature "$TEST_ROOT/features/blocked/FTR-0001-contract-probe.md" blocked automation-agent
vb --root "$TEST_ROOT" validate --only-features >/dev/null
mv "$TEST_ROOT/features/blocked/FTR-0001-contract-probe.md" "$TEST_ROOT/features/in-progress/"
pass "blocked features retain a concrete owner"

# Review and done remain attributable to a concrete owner as well.
for managed_status in review done; do
    mv "$TEST_ROOT/features/in-progress/FTR-0001-contract-probe.md" "$TEST_ROOT/features/$managed_status/"
    write_feature "$TEST_ROOT/features/$managed_status/FTR-0001-contract-probe.md" "$managed_status" unassigned '[contract]' automation-agent
    if vb --root "$TEST_ROOT" validate --only-features >"$TEST_ROOT/$managed_status-unassigned.out" 2>&1; then
        fail "$managed_status feature with unassigned owner passed validation"
    fi
    write_feature "$TEST_ROOT/features/$managed_status/FTR-0001-contract-probe.md" "$managed_status" review-agent '[contract]' automation-agent
    vb --root "$TEST_ROOT" validate --only-features >/dev/null
    mv "$TEST_ROOT/features/$managed_status/FTR-0001-contract-probe.md" "$TEST_ROOT/features/in-progress/"
done
pass "review and done features retain a concrete owner"

# Duplicate labels and dependencies are rejected by the schema.
write_feature "$TEST_ROOT/features/in-progress/FTR-0001-contract-probe.md" in-progress automation-agent '[contract, contract]'
if vb --root "$TEST_ROOT" validate --only-features >"$TEST_ROOT/duplicates.out" 2>&1; then
    fail "duplicate labels passed validation"
fi
grep -qi unique "$TEST_ROOT/duplicates.out" || fail "duplicate-label validation error was not reported"
pass "duplicate labels are rejected"

# A copied system spec must replace the placeholder with a real date.
rm -f "$TEST_ROOT/features/in-progress/FTR-0001-contract-probe.md"
write_spec YYYY-MM-DD
if vb --root "$TEST_ROOT" validate --only-specs >"$TEST_ROOT/placeholder.out" 2>&1; then
    fail "system-spec date placeholder passed validation"
fi
write_spec "$TODAY"
vb --root "$TEST_ROOT" validate --only-specs >/dev/null
pass "system specs require a real ISO date"

echo "1..$TESTS_RUN"
