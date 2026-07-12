# VirtualBoard for Codex

This package is the Codex-native VirtualBoard integration. Its manifest is
runtime-specific because Claude agent and command component formats are not
portable. Its procedural `work-on` skill is an exact generated copy of the
canonical `skills/work-on/SKILL.md`, so safety guardrails cannot drift by
runtime.

The package exposes one `work-on` skill. The skill operates on the canonical
`virtualboard.json` contract in the target repository or its `.virtualboard`
workspace. It does not install itself into a personal marketplace and does not
modify global Codex configuration.

Refresh or verify the generated skill with
`python3 tools/sync_work_on_plugins.py --write` or `--check`; do not edit the
packaged copy directly.
