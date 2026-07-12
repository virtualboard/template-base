# VirtualBoard for Claude Code

This directory is the self-contained Claude Code plugin package published by
the VirtualBoard marketplace. Claude Code discovers its runtime components from
the standard `agents/`, `commands/`, and `skills/` directories.

The component files are generated from the repository's canonical
`virtualboard.json`, `agents/`, `prompts/`, and `skills/` sources. Do not edit
generated components here directly.

Synchronize the package after changing a canonical source:

```bash
python3 tools/sync_claude_plugin.py --write
python3 tools/sync_work_on_plugins.py --write
```

Verify that the committed package is current:

```bash
python3 tools/sync_claude_plugin.py --check
python3 tools/sync_work_on_plugins.py --check
tests/test-claude-plugin.sh
```
