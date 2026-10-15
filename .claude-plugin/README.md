# VirtualBoard Claude Code Plugin

VirtualBoard packages its Markdown-first software-delivery framework as a
Claude Code marketplace plugin. The installed plugin contributes:

- 10 specialized agents
- 31 namespaced workflow commands
- 1 feature implementation skill (`work-on`)

Claude Code reports commands and skills together under `Skills`, so the
expected installed inventory is **Skills (32)** and **Agents (10)**.

## Install

Add the repository marketplace and install the plugin:

```bash
claude plugin marketplace add virtualboard/template-base
claude plugin install virtualboard@virtualboard-marketplace
```

Inspect the installed component inventory:

```bash
claude plugin details virtualboard@virtualboard-marketplace
```

The plugin supplies agent behavior and workflows. Run it in a project that has
been initialized as a VirtualBoard workspace and follow the workspace's
`AGENTS.md` and `virtualboard.json` contract.

## Components

### Agents

The following agents are available by their scoped plugin names:

- `pm` — project planning and coordination
- `architect` — system design and architecture decisions
- `backend-dev` — APIs, data stores, and server-side behavior
- `frontend-dev` — interfaces, accessibility, and client behavior
- `fullstack-dev` — end-to-end implementation
- `qa` — quality planning and verification
- `devops` — delivery, infrastructure, and reliability
- `security` — security and compliance analysis
- `data` — analytics, pipelines, and data quality
- `ux` — product and experience design

### Workflow commands

Commands use collision-free names derived from the canonical command IDs. For
example:

```text
/virtualboard:pm-progress-report
/virtualboard:architect-decision
/virtualboard:backend-api-documentation
/virtualboard:qa-browser-automation
/virtualboard:security-threat-model
```

The complete command registry, aliases, role ownership, and effect declarations
live in `virtualboard.json` at the repository root.

### Feature implementation skill

Use the namespaced skill to work on a feature:

```text
/virtualboard:work-on FTR-0001
```

## Package layout

This repository is a marketplace root, while the distributable plugin is a
self-contained subdirectory:

```text
.claude-plugin/
  marketplace.json
plugins/claude/virtualboard/
  .claude-plugin/plugin.json
  agents/
  commands/
  skills/
```

Using a dedicated plugin root is intentional. Claude Code discovers components
from the standard directories, strict validation does not mistake framework
documentation for runtime agents, installed plugins are self-contained, and
`claude plugin details` can report the complete inventory.

The runtime files under `agents/`, `commands/`, and `skills/` inside the plugin
package are generated. Their canonical sources are:

- `virtualboard.json` — role and command registry plus inventory expectations
- `agents/` — agent prompts
- `prompts/agents/` — workflow command bodies
- `skills/` — reusable skills and supporting files

## Development and validation

After changing a canonical component, synchronize the package:

```bash
python3 tools/sync_claude_plugin.py --write
python3 tools/sync_work_on_plugins.py --write
```

Verify generated-file drift without changing files:

```bash
python3 tools/sync_claude_plugin.py --check
python3 tools/sync_work_on_plugins.py --check
```

Run strict manifest validation and the isolated installation smoke test:

```bash
claude plugin validate plugins/claude/virtualboard --strict
claude plugin validate . --strict
tests/test-claude-plugin.sh
```

The smoke test installs the marketplace into a temporary `HOME`; it does not
modify the developer's global Claude Code configuration. If the Claude Code CLI
is not installed, it still verifies generated inventory and skips runtime
checks. Set `REQUIRE_CLAUDE_PLUGIN_CLI=1` to make a missing CLI fail.

For an interactive local development session, load the actual plugin root:

```bash
claude --plugin-dir ./plugins/claude/virtualboard
```

## Release invariant

Before publishing, all of the following must agree:

1. `virtualboard.json` role, workflow, and skill expectations
2. generated package contents
3. `.claude-plugin/marketplace.json` metadata and source path
4. `plugins/claude/virtualboard/.claude-plugin/plugin.json` metadata
5. strict validation and installed `claude plugin details` output

## License

MIT
