# Coordinated v0.8 template / v0.10 CLI release

This release has two ordering constraints:

1. CLI v0.10 embeds the SHA-256 of the immutable template v0.8 archive, so the
   template asset must exist before final CLI binaries are built.
2. CLI v0.9.0 downloads `template-base/main.zip`. Moving template `main` to an
   incompatible v0.8 commit before that client is retired would silently change
   what an already-installed binary executes.

The release pipeline breaks the circular dependency by building template tests
from an exact CLI source commit, not from a pre-existing v0.10 release. It
protects v0.9 users by allowing the reviewed v0.8 tag to come from a protected
`release/v0.8.0` branch while `main` remains at the compatible v0.7 line.

## Stop-ship invariants

Stop immediately if any of these is true:

- `.vb-cli-source-ref` is absent, not exactly 40 lowercase hex characters, is
  the all-zero sentinel, or does not equal the reviewed CLI candidate commit;
- the CLI source version does not equal `.vb-version`;
- Go reports anything other than `go1.25.0`;
- the template archive, checksum entry, compiled digest, or embedded
  `version.txt` disagree;
- built-binary `init → validate → index --check → install cursor → install
  opencode` fails against the exact candidate archive;
- native macOS or Windows core/lifecycle/install tests fail in the CLI release;
- either release workflow cannot attest provenance, cannot bind its draft to
  the exact tag commit, or finds a published same-tag release; or
- the v0.9.0 compatibility rehearsal fails for a proposed change to template
  `main`.

Never delete or replace a published release to recover. A failed publication
leaves its source-bound draft in place. A retry may resume only when the draft's
exact marker, tag, target commit, title, and prerelease state still match; any
other same-tag release is a stop-ship failure. Keep `main` unchanged, fix forward
with new patch versions, and repeat the complete rehearsal.

## One-time preparation

1. Keep `origin/main` at the v0.7-compatible commit.
2. Create and protect `release/v0.8.0` from that commit. Review the framework
   hardening change into that release branch, not into `main`.
3. Commit and review the v0.10 CLI candidate. Put that exact commit SHA in
   `.vb-cli-source-ref`; never use a branch name, tag, abbreviated SHA, or local
   dirty-tree hash.
4. On the template release branch, build one candidate archive and rehearse it:

   ```bash
   TEMPLATE_RELEASE="v$(tr -d '[:space:]' < version.txt)"
   ARCHIVE="/tmp/template-base-${TEMPLATE_RELEASE}.zip"
   git archive --format=zip --prefix="template-base-${TEMPLATE_RELEASE}/" \
     --output="$ARCHIVE" HEAD
   GO=go scripts/build-vb-cli-candidate.sh \
     /path/to/exact/vb-cli-checkout "$ARCHIVE" .state/bin/vb
   VB_TEMPLATE_ARCHIVE_FILE="$ARCHIVE" \
     /path/to/exact/vb-cli-checkout/scripts/release-smoke.sh \
     .state/bin/vb "$ARCHIVE" "$TEMPLATE_RELEASE"
   ```

   The CLI checkout's `HEAD` must equal `.vb-cli-source-ref`, and `go env
   GOVERSION` must be `go1.25.0`.

## Publication sequence

Each tag, push, and release is an external write and requires explicit owner
authorization.

1. Tag the exact protected `release/v0.8.0` head as `v0.8.0`. The template
   workflow reruns all contracts, builds the exact CLI source candidate, smokes
   the exact archive it will publish, creates `template-checksums.txt`, attests
   both files, creates or resumes a draft bound to the exact tag commit, and
   reconciles assets only after revalidating that draft. It verifies the exact
   two-file name, size, upload-state, and available digest inventory before one
   `draft: false` API transition. It refuses every published same-tag release.
2. Download `template-base-v0.8.0.zip` and `template-checksums.txt` through exact
   `/releases/download/v0.8.0/` URLs. Require exactly one checksum match and
   verify SHA-256 locally. Verify provenance with:

   ```bash
   gh attestation verify template-base-v0.8.0.zip \
     --repo virtualboard/template-base
   ```

3. Tag the reviewed CLI candidate as `v0.10.0`. Its workflow derives v0.8.0
   from CLI source, downloads and fingerprints the template exactly once,
   shares that immutable artifact/digest with every build, reruns the
   built-binary smoke, executes native macOS and Windows tests through the
   reusable CI workflow, and attests the final binaries and checksum manifest.
   Its publication gate applies the same source-bound draft protocol to the
   exact seven-file release inventory (six native binaries plus checksums).
4. Download the exact v0.10.0 binary and `checksums.txt`, verify one checksum
   entry, verify the GitHub attestation, run `vb version`, and repeat the
   init/validate/index/install smoke in a disposable application.

## Protecting moving-main v0.9 users

Publishing template v0.8 and CLI v0.10 does not authorize moving template
`main`. CLI v0.9.0 remains branch-coupled for every user who has not upgraded.

The CI job `legacy-main-compatibility` checks out immutable CLI commit
`d0d05d656c721ade944ad4dd61e1aa7d3ffb0f8a`, redirects only its two test URLs to
the local candidate archive, then runs init, validate, new, validate, and index.
It runs for pull requests targeting `main` and is a required stop-ship check.

If that rehearsal fails, keep v0.8 on `release/v0.8.0`. Do not waive the check.
Move `main` only after one of these is true:

- the candidate is made genuinely v0.9-compatible and the rehearsal passes; or
- v0.9 moving-main support has been explicitly retired under a reviewed support
  policy and migration communication plan.

Because v0.10 consumes the immutable v0.8 release asset, leaving template
`main` on v0.7 does not prevent new clients from using the hardened framework.
