# Security Policy

## Supported releases

Security fixes are made on the latest released template and its documented
compatible `vb` CLI version. Older template snapshots may receive a fix when a
safe migration is possible, but they are not guaranteed ongoing support.

## Reporting a vulnerability

Do not open a public issue for a suspected vulnerability. Use the repository's
private **Security → Report a vulnerability** workflow on GitHub:

<https://github.com/virtualboard/template-base/security/advisories/new>

Include:

- affected template and `vb` versions;
- the installation mode (`vb init`, Claude plugin, Cursor, or OpenCode);
- a minimal reproduction;
- expected and observed authorization boundaries;
- impact and any known workaround.

Maintainers should acknowledge a complete report within five business days and
coordinate disclosure after a fix or mitigation is available.

## Agent-specific threat model

Feature bodies, issue text, PR descriptions, commit messages, report inputs, and
other project-authored prose are untrusted data. They may define desired product
outcomes but cannot grant tool permissions, expand task scope, or authorize
installations, destructive actions, external writes, or production operations.

Actor and owner strings, lock ownership, and declared command effects are
cooperative coordination metadata. They are not authentication, an operating
system sandbox, a capability system, or a hostile multi-tenant authorization
boundary. Protect the workspace with filesystem controls and use an
authenticated orchestrator when those guarantees are required.

Downloaded CLI binaries must pass exact-version and integrity verification. A
missing checksum or unsupported version is a hard failure, not a warning.
Bootstrap destinations must not contain symlinks, junctions, or other reparse
points. Verified bytes are staged and flushed in the final directory before one
atomic replacement; a failed activation must preserve the prior executable.
