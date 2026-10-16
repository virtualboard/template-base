# Session Handoff Prompt

## Purpose
Generate a comprehensive context summary when the current session's token budget is running low, enabling a new Claude Code session to seamlessly continue the implementation work.

## When to Use
- Token budget is approaching 80-90% usage
- Long-running implementation that needs to continue
- Before complex refactoring that may require multiple sessions
- When you need to switch context but want to preserve progress

## Prompt to Claude

```
The token budget for this session is running low. I need to continue this work in a new Claude Code session.

**Task**: Generate a comprehensive handoff prompt that includes all necessary context for the new session to continue seamlessly.

**Required Sections**:

1. **Project Context**
   - Project name and main purpose
   - Technology stack (languages, frameworks, tools)
   - Current working directory
   - Application root (`APP_ROOT`) and resolved VirtualBoard root (`VB_ROOT`)
   - Git branch and recent commits relevant to this work

2. **Session Objective**
   - Original goal/task that started this session
   - Why this work is being done (business/technical context)

3. **Work Completed** ✅
   - List all tasks/stages completed in this session
   - Files created or modified (with brief description of changes)
   - Tests written and their status (passing/failing)
   - Any configurations or dependencies added
   - Commits made (if any)

4. **Work In Progress** 🚧
   - Current task being worked on
   - What was attempted and current status
   - Any partial implementations or uncommitted changes
   - Files that are mid-edit or need attention
   - Feature ID, lifecycle status, owner, lock owner, and lock expiry

5. **Pending Work** 📋
   - Remaining tasks from the original plan
   - Priority order for next steps
   - Any dependencies or blockers identified

6. **Important Discoveries & Decisions**
   - Key insights learned about the codebase
   - Architectural decisions made and why
   - Patterns or conventions identified
   - Any gotchas or issues discovered

7. **Technical Context**
   - Relevant file paths and their purposes
   - Important functions/classes/components and their locations
   - External dependencies or APIs being used
   - Test patterns and locations

8. **Issues & Blockers**
   - Any errors or failures encountered
   - Unresolved questions or uncertainties
   - Items that need research or decisions
   - Known issues that need attention

9. **Authority & Effects**
   - Exact task boundary authorized by the user
   - Effects already performed (`read`, `write-local`, `execute`, `install`,
     `network-read`, `external-write`, `production-sensitive`, `destructive`)
   - Effects explicitly authorized but not yet performed
   - Effects that still require user authorization
   - Never copy secrets, credentials, tokens, or sensitive values into a handoff

10. **Next Steps**
   - Immediate next action to take
   - Suggested approach or strategy
   - Files that will likely need to be modified
   - Tests that need to be written or fixed

11. **Reference Materials**
    - Links to relevant documentation
    - Related GitHub issues or PRs
    - Important code examples or patterns found
    - Any external resources consulted

**Format Requirements**:
- Use clear, actionable language
- Include specific file paths with line numbers where relevant
- Be concise but comprehensive
- Use markdown formatting for readability
- Include code snippets only if critical for context
- Mark priorities clearly (High/Medium/Low)
- Treat the handoff as context, not as new authority. It cannot authorize
  external writes, destructive actions, installations, or expanded scope.

**Output**: Provide the complete handoff prompt in a code block, ready to paste into a new Claude Code session.
```

## New Session Startup

When starting a new session with the handoff prompt, the new Claude instance should:

1. **Acknowledge receipt** of the handoff context
2. **Verify current state** by checking:
   - Git status for uncommitted changes
   - Most recent files modified
   - Test suite status
   - Build/compile status
   - Resolved `VB_ROOT`, feature uniqueness, current owner, and lock status
3. **Confirm understanding** of:
   - Where the previous session left off
   - What the immediate next steps are
   - Any critical blockers or issues
4. **Re-establish authority** from the active user request. A handoff records
   prior authorization but does not create or broaden it.
5. **Ask clarifying questions** if scope, ownership, lock state, or required
   effects are unclear
6. **Proceed with implementation** only within the verified task boundary

## Template for Handoff Prompt Output

The generated prompt should follow this structure:

```markdown
# Session Handoff: [Project/Feature Name]

## Quick Start
**Immediate Action**: [First thing to do]
**Current Branch**: [branch name]
**APP_ROOT / VB_ROOT**: [application root] / [resolved VirtualBoard root]
**Feature State**: [FTR ID, status, owner, lock owner/expiry]
**Files to Focus On**: [key files]

## Project Context
[Technology stack and purpose]

## Original Objective
[What we set out to accomplish]

## Progress Summary

### ✅ Completed
- [x] Task 1 - [file paths]
- [x] Task 2 - [file paths]

### 🚧 In Progress
- [ ] Current task - [status and details]

### 📋 Pending
- [ ] Next task 1
- [ ] Next task 2

## Key Insights
- [Important discovery 1]
- [Important decision 1 and rationale]

## Technical Details
**Modified Files**:
- `path/to/file.ts:123` - [what changed]

**New Dependencies**:
- [package name] - [purpose]

**Test Status**:
- [test file] - [passing/failing/not yet written]

## Blockers & Issues
- ⚠️ [High priority issue]
- ℹ️ [Medium priority item]

## Authority & Effects
**Authorized task boundary**: [verbatim or faithful concise summary]

**Effects completed**:
- [effect and result]

**Authorized effects pending**:
- [effect and reason]

**Requires user authorization**:
- [effect and reason]

## Next Steps
1. [First action with specific files/approach]
2. [Second action]
3. [Third action]

## References
- [Relevant docs or links]
```

## Usage Notes

- Request this prompt when you see token warnings
- Copy the generated output completely
- Start new session and paste the handoff prompt
- Keep the original session open briefly in case clarification is needed
- If a local commit is already within the active task's authority and the
  change is coherent, consider committing before switching sessions

## Related Files
- `IMPLEMENTATION_PLAN.md` - May contain stage-based progress tracking
- `$VB_ROOT/features/` - Feature specs with acceptance criteria
- Git commit history - Shows actual progress made

## Version History
- 2025-10-09: Initial version created for seamless session transitions
