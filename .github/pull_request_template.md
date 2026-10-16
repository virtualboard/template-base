## Feature

- Feature ID: `FTR-____`
- Spec link: <!-- Link the exact feature spec; do not use a wildcard path. -->

## Summary

<!-- What changed, why, and which user-visible outcome it delivers. -->

## Acceptance criteria

<!-- Copy the applicable criteria from the feature spec and mark verified items. -->

- [ ] Criteria are implemented or explicitly deferred in the feature spec.
- [ ] Implementation notes and links are current.

## Verification evidence

<!-- List exact commands, results, screenshots, or runtime evidence. -->

- [ ] Unit/integration tests pass.
- [ ] `"$VB" --root "$VB_ROOT" validate` passes with non-vacuous fixture coverage.
- [ ] Contract, plugin inventory, and generated-drift checks pass when applicable.
- [ ] Documentation examples changed by this PR were executed verbatim.

## Effects and authorization

- [ ] Local writes only
- [ ] Dependency installation (approval recorded)
- [ ] External write such as push/PR/deployment (approval recorded)
- [ ] Production-sensitive operation (approval and rollback recorded)
- [ ] Destructive operation (approval recorded)

## Risk and rollback

- Risk level: <!-- low / medium / high / critical -->
- Security/privacy impact:
- Migration or compatibility impact:
- Rollback procedure:

## Review

- [ ] No unrelated changes are included.
- [ ] Lifecycle transition is valid.
- [ ] The feature is in `review` before merge and moves to `done` only after approval.
