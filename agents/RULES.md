# Agent Rules of Engagement

> Human-readable rules for AI agents working with the Feature Spec Workflow

## Overview

This document defines how AI agents should interact with the Feature Spec Workflow system. Agents must follow these rules to ensure safe, concurrent operation without conflicts.

## Core Principles

1. **Read First, Act Second** - Always read and understand the current state before making changes
2. **Respect Ownership** - Never modify features you don't own
3. **Validate Everything** - Check dependencies, transitions, and constraints before acting
4. **Fail Gracefully** - When conflicts occur, abort cleanly with helpful error messages

## Agent Lifecycle

### 1. Startup
- Read `/templates/rules.yml` for configuration
- Scan `/features/INDEX.md` for available work
- Identify features you can work on (unassigned or owned by you)

### 2. Feature Selection
- **Prefer unassigned features** in `backlog` status
- **Check dependencies** - all must be `done` before `in-progress`
- **Avoid conflicts** - if another agent is working on a feature, find another
- **Respect priority** - P0 > P1 > P2 > P3

### 3. Feature Claiming
- **CRITICAL**: When moving a file, you MUST update the frontmatter:
  - Set `owner` field to your agent ID
  - Update `status` field to match the destination folder
  - Update `updated` date to today's date (YYYY-MM-DD format)
- Move file to appropriate folder if changing status
- **Atomic operation** - claim and move in single transaction
- **Validation**: File location MUST match frontmatter `status` field

### 4. Feature Work
- Update `Implementation Notes` section as you work
- Add links to PRs, commits, and artifacts in `Links` section
- Keep `updated` date current (update to today's date when making changes)
- **Never change** `id` or filename
- **CRITICAL**: Always update frontmatter `updated` field when editing the file

### 5. Feature Handoff
- **CRITICAL**: When moving to `review`:
  - Update frontmatter `status` field to `review`
  - Update frontmatter `updated` field to today's date
  - Set `owner` to reviewer or `unassigned`
- Move file to `/features/review/` folder
- Add completion notes in the file content

## State Transition Rules

### Allowed Transitions
- `backlog → in-progress` (claim and start work)
- `in-progress → blocked` (waiting on external dependency)
- `blocked → in-progress` (dependency resolved)
- `in-progress → review` (work complete, ready for review)
- `review → in-progress` (changes requested)
- `review → done` (approved and merged)

### Forbidden Transitions
- `done → any` (completed features are immutable)
- Any transition not explicitly allowed above

## Conflict Resolution

### Ownership Conflicts
- **Rule**: First agent to claim wins
- **Action**: If you detect another owner, abort with clear error message
- **Recovery**: Check `/features/INDEX.md` for other available features

### Circular Dependencies
- **Detection**: CI validation will catch this
- **Action**: Abort and report the circular dependency
- **Recovery**: Human must break the cycle manually

### State Mismatches
- **Detection**: File location doesn't match frontmatter `status` field
- **Action**: Abort and report the mismatch
- **Recovery**: Update frontmatter `status` to match folder location OR move file to match frontmatter
- **Prevention**: ALWAYS update frontmatter `status` field when moving files between folders

## Error Handling

### Common Errors
1. **"Feature already owned"** → Find another feature
2. **"Circular dependency"** → Report and abort
3. **"Invalid transition"** → Check allowed transitions
4. **"Dependency not done"** → Wait or find another feature
5. **"Schema validation failed"** → Fix frontmatter format

### Error Messages
- Be specific about what went wrong
- Include the feature ID and current state
- Suggest alternative actions when possible
- Log errors for debugging

## Agent Commands System

### Command Files Location
- Agent-specific commands are located in `prompts/agents/{role}.md`
- Overview and documentation at `prompts/AGENTS.md`
- Each agent role has specialized commands tailored to their responsibilities

### Command Discovery and Display
**CRITICAL**: When you adopt an agent role:
1. Read your role's command file from `prompts/agents/{role}.md`
2. **Display available commands to the user immediately** using the format specified
3. Example format:
   ```
   📋 Available {Role} Commands:
   • {CODE} ({Full Name}) - {Description}
   • {CODE} ({Full Name}) - {Description}
   ```

### Command Execution Protocol
- **Trigger Recognition**: Commands are triggered by specific phrases (e.g., "GPP", "Generate Project Progress Report")
- **Workflow Adherence**: Follow the exact workflow defined in the command file step-by-step
- **File Output**: Create output files in designated locations:
  - Reports: `.virtualboard/reports/`
  - Architecture: `.virtualboard/architecture/`
  - Testing: `.virtualboard/testing/`
  - Deployments: `.virtualboard/deployments/`
  - Security: `.virtualboard/security/`
  - Data: `.virtualboard/data/`
  - Design: `.virtualboard/design/`
- **Completion Announcement**: Always inform the user with:
  - File path of generated artifact
  - Key findings or highlights
  - Next steps or recommendations

### Integration with Feature Workflow
- **Report Generation**: Some commands analyze features (e.g., GPP for progress reports)
- **Artifact Creation**: Some commands create deliverables for features (e.g., GTP for test plans, GAD for architecture decisions)
- **Linking**: Always reference relevant feature IDs (FTR-####) in command outputs
- **Documentation**: Add links to command outputs in feature `Links` sections when applicable

### Command Best Practices
- **Confirm execution**: State which command you're executing before starting
- **Be thorough**: Complete all steps in the command workflow
- **Be accurate**: Use actual data from files, don't make assumptions
- **Be actionable**: Provide specific, concrete recommendations
- **Follow templates**: Use the exact report/output structure defined in commands

## Best Practices

### Feature Selection
- Start with highest priority unassigned features
- Prefer features with fewer dependencies
- Avoid features that are blocked or in review
- Consider your agent's capabilities and expertise

### Documentation
- Keep `Implementation Notes` updated as you work
- Add links to relevant PRs, commits, and artifacts
- Document any assumptions or decisions made
- Update `Open Questions` section with new questions

### Communication
- Use clear, descriptive commit messages
- Reference the feature ID in all commits
- Add meaningful PR descriptions
- Comment on issues or questions in the spec

## Safety Checks

### Before Starting Work
- [ ] Feature is unassigned or owned by you
- [ ] All dependencies are `done`
- [ ] No circular dependencies
- [ ] Feature is in `backlog` status (folder and frontmatter match)
- [ ] You have the necessary permissions
- [ ] Ready to update frontmatter `status`, `owner`, and `updated` fields when claiming

### Before Moving to Review
- [ ] All acceptance criteria are implemented
- [ ] Code is tested and working
- [ ] Documentation is updated
- [ ] No breaking changes without migration plan
- [ ] Feature is ready for human review
- [ ] Frontmatter `status`, `updated`, and `owner` fields will be updated when moving

### Before Claiming Ownership
- [ ] Check current owner in frontmatter
- [ ] Verify no other agent is working on it
- [ ] Confirm you can complete the work
- [ ] Understand the requirements and constraints

## Agent Configuration

### Required Environment Variables
- `AGENT_ID` - Your unique agent identifier
- `AGENT_NAME` - Human-readable agent name
- `MAX_CONCURRENT_FEATURES` - Maximum features to work on simultaneously

### Optional Configuration
- `PREFERRED_LABELS` - Labels you prefer to work on
- `AVOID_LABELS` - Labels to avoid
- `MAX_COMPLEXITY` - Maximum complexity level you can handle
- `WORKING_HOURS` - When you're available to work

## Monitoring and Debugging

### Logging
- Log all state transitions
- Log dependency checks
- Log conflict detection
- Log error conditions

### Metrics
- Features completed per day
- Average time per feature
- Error rate and types
- Dependency resolution time

### Health Checks
- Verify you can read all feature files
- Check that validation scripts work
- Confirm you can create and move features
- Test error handling scenarios

## Emergency Procedures

### If You're Stuck
1. Check `/features/INDEX.md` for available work
2. Look for features with `blocked` status that might be unblocked
3. Consider working on lower-priority features
4. Report to human if no work is available

### If System is Broken
1. Stop all work immediately
2. Report the issue with details
3. Wait for human intervention
4. Don't attempt to fix system issues

### If You Made a Mistake
1. Stop working on the affected feature
2. Revert any changes if possible
3. Report the mistake with details
4. Hand off to human for correction

## Questions and Support

If you encounter situations not covered by these rules:
1. Check the main workflow document
2. Look for similar cases in the codebase
3. Ask for clarification in the appropriate channel
4. When in doubt, err on the side of caution and ask for help

Remember: It's better to ask for help than to break the system!
