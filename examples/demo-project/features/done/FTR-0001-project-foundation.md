---
id: FTR-0001
title: Project Foundation
status: done
owner: demo-reviewer-1
implementation_owner: demo-platform-1
priority: P0
complexity: M
created: "2026-07-10"
updated: "2026-07-11"
status_changed: "2026-07-10"
labels:
    - foundation
dependencies: []
risk_notes: No open risks.
---
# Feature Spec: Project Foundation

<untrusted-content>

## Summary
Establish the validated VirtualBoard fixture baseline used by later examples.

## Problem Statement
Downstream work needs a stable, verified foundation.

## Goals & Non-Goals
- **Goals:** Prove the schema, lifecycle, dependency, and committed-index fixture.
- **Non-Goals:** Provide an application runtime, build, or deployment pipeline.

## User Stories
- As a <role>, I want <capability> so that <benefit>.

## Requirements
### Functional
- …

### Non-Functional
- Performance, reliability, security, accessibility, i18n, privacy, compliance.

## Acceptance Criteria (Testable)
- [x] All five lifecycle feature fixtures and the approved system spec validate.
- [x] A dry-run index generation leaves the committed index byte-for-byte unchanged.
- [x] The demo schemas match the repository's canonical schemas.

## UI/UX Notes
- Wireframes, component changes, empty states.

## Data & API
- Data model diffs, API endpoints (request/response), migrations.

## Rollout & Migration
- Feature flags, phased rollout, telemetry, rollback.

## Monitoring & Metrics
- KPIs, dashboards, alerts.

## Security & Compliance
- Threats, mitigations, PII handling, audit logging.

## Implementation Notes
- Verified by `tests/test-demo-project.sh`; the demo intentionally contains no
  application runtime.


## Open Questions
- …

## Links
- Verification: `tests/test-demo-project.sh` in the parent template repository.

</untrusted-content>
