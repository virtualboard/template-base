# VirtualBoard Demo Project

This fixture contains a valid feature in every lifecycle state plus one approved
system specification. It exists so repository validation and onboarding tests are
never vacuous.

It deliberately omits `virtualboard.json` and carries an explicit pre-v0.8
`.template-version` marker to exercise the CLI's bounded legacy-layout
compatibility path. The repository root and lifecycle compatibility gate cover
the canonical contract-aware layout and `.state` paths. A markerless directory
must fail closed instead of being guessed to be a legacy workspace.

Run:

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
VB="$REPO_ROOT/.state/bin/vb"
"$VB" --root "$REPO_ROOT/examples/demo-project" validate
"$VB" --root "$REPO_ROOT/examples/demo-project" index --dry-run
```

Install the exact pinned binary from the repository Quick Start first. Never
substitute an arbitrary `vb` from `PATH` for this compatibility fixture.

The example schemas and feature template are intentionally copied into the
fixture because `vb` resolves them beneath its configured root. CI verifies
that these copies match the canonical files in `/schemas` and `/templates`.
