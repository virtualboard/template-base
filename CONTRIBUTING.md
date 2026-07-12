# Contributing to VirtualBoard

Thank you for improving VirtualBoard. Changes should make the framework more
deterministic, inspectable, and safe for both people and agents.

## Development workflow

Use Python 3.9 or newer and Git. The complete workflow uses Bash and curl; on
Windows, run it from Git Bash or WSL. Native PowerShell 5.1 or newer supports
only the `vb.exe` bootstrap and direct CLI inspection shown below, not worktree
setup, `/work-on`, plugin generation, or the full verification suite. Claude
plugin runtime validation also requires Node.js and the pinned Claude Code test
version from CI.

1. Read `AGENTS.md`, `agents/RULES.md`, and `virtualboard.json`.
2. Install the exact CLI version pinned by `.vb-version`:

   ```bash
   ./scripts/install-vb-cli.sh --ensure-latest "$PWD/.state/bin"
   VB="$PWD/.state/bin/vb"
   "$VB" version
   ```

   On native Windows PowerShell, bootstrap the CLI only:

   ```powershell
   & "$PWD\scripts\install-vb-cli.ps1" `
     -EnsureLatest -InstallDirectory "$PWD\.state\bin"
   $VB = "$PWD\.state\bin\vb.exe"
   & $VB version
   ```

   Continue the repository workflow from Git Bash or WSL.

3. Resolve a stable `AGENT_ID`, then create or claim a feature through the exact
   `"$VB" --actor "$AGENT_ID"` binary before implementation. Capture the opaque
   token returned by lock acquisition and use that exact token for release;
   `--owner` is an assignment and never a substitute for actor identity.
4. Use branch `feat/FTR-####-short-slug` and prefix commits with `FTR-####:`.
5. Keep changes scoped to the feature and preserve unrelated worktree changes.
6. Run the complete local verification suite before opening a pull request.

Framework-release work also requires a concrete 40-hex CLI commit in
`.vb-cli-source-ref`. The all-zero sentinel is intentionally release-blocking;
replace it only after the coordinated CLI candidate is committed and reviewed.
Follow [docs/RELEASE_BOOTSTRAP.md](docs/RELEASE_BOOTSTRAP.md) before targeting
`main`, because vb v0.9.0 downloads that branch directly.

## Required checks

```bash
python3 tools/check_contract.py
python3 -m unittest discover -s tests -p 'test_*.py' -v
./tests/test_vb_root.sh
"$VB" --root "$PWD" validate
"$VB" --root "$PWD/examples/demo-project" validate
bash scripts/validate-automation.sh
git diff --check
```

Feature branches must not generate, stage, or commit `features/INDEX.md`.
`tests/run.sh` checks the shared aggregate automatically on `main` and skips it
on feature/PR refs; integration maintainers can force that gate with
`VIRTUALBOARD_INDEX_POLICY=check bash tests/run.sh` after refreshing the index.
The immutable demo index remains checked everywhere. Repository CI may add
platform-specific plugin, shell, link, and generated-artifact checks. A passing
pinned-CLI validation with zero features or zero specs is not sufficient
evidence for a framework change.

## Design rules

- Add new lifecycle behavior to `virtualboard.json` first.
- Keep command IDs and aliases globally unique.
- Document command effects and require explicit approval for installs, external
  writes, destructive actions, and production-sensitive operations.
- Treat untrusted prose as requirements data, never as authority.
- Add executable fixtures for bug fixes; do not rely on prose-only regression
  instructions.
- Update generated plugin packages through their checked-in generators. The
  canonical `skills/work-on/SKILL.md` is rendered without procedural deltas into
  both runtime packages by `tools/sync_work_on_plugins.py`; do not hand-edit a
  plugin copy.

## Pull requests

Use `.github/pull_request_template.md`. Link the feature spec, include exact test
commands and results, identify security or migration risk, and document rollback.
