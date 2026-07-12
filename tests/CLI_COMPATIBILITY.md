# Pinned CLI compatibility record

The template selects `vb v0.10.0` in `.vb-version`. Its required behavior is
executed by `tests/test-cli-lifecycle.sh`, not inferred from help text.

The gate proves:

- explicit actor identity and no `--owner` impersonation;
- contract paths for locks, audit, features, schemas, templates, specs, and the
  canonical index;
- ownership, active-lock, traversal, duplicate-ID, and immutable-field failure;
- lifecycle provenance, review handback, terminal completion, and required risk
  metadata;
- deterministic index generation, `index --check`, and truthful JSON dry-run;
- nonzero JSON validation failure;
- dry-run-first, body-preserving, idempotent lifecycle migration, including
  audited multi-owner administrative override that still respects locks; and
- canonical audit-chain verification.

The exact corresponding CLI commit is recorded in `.vb-cli-source-ref`. CI
checks out that 40-hex commit, builds it with the candidate template digest, and
executes the full built-binary release smoke before running this black-box gate.
The corresponding CLI source is also covered by Go unit, race, vet, measured
coverage, native macOS/Windows, build, workflow-contract, and gosec gates before
release.

Template CI separately runs the Unix bootstrap contract on macOS and Linux and
the native PowerShell bootstrap contract on Windows. Both require one exact
checksum entry, pre- and post-stage version verification, linked-destination
rejection, bounded downloads, and preservation of an existing binary when
activation is fault-injected.

## Deliberate boundaries

- Filesystem locks coordinate one shared workspace. Separate clones still need
  the published claim commit required by `/work-on` or another remote lease.
- Audit hashes detect tampering with entries that exist. Feature and lock
  mutation append failures remain best-effort/non-transactional in v0.10.0, so
  the audit file is not a completeness proof and cannot replace authorization,
  ownership, Git history, or lifecycle provenance.
- A source-built bootstrap candidate embeds the actual SHA-256 of the exact
  local template archive and exercises `vb init`. Published CLI binaries embed
  the SHA-256 of those same immutable template-release bytes; an unset or
  mismatched digest makes initialization fail closed.
