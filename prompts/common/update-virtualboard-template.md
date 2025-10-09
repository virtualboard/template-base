# Update VirtualBoard Template

## Purpose
Synchronize the local `.virtualboard/` directory with the latest changes from the VirtualBoard template repository while preserving project-specific customizations.

## Prompt

```
I need to update the local VirtualBoard template files to match the latest version from the upstream repository.

**Task**: Compare and update the following directories:
- `.virtualboard/agents/`
- `.virtualboard/prompts/`
- Any other `.virtualboard/` subdirectories

**Source**: https://github.com/virtualboard/template-base

**Requirements**:
1. **Preserve local changes**: Keep any project-specific modifications already made to files under `.virtualboard/`
2. **Add new content**: Include all new files and updates from the template repository
3. **Merge intelligently**: When both local customizations and upstream changes exist in the same file:
   - Keep project-specific sections/modifications
   - Add new sections/features from upstream
   - Note any conflicts that need manual review
4. **Report changes**: Provide a summary of:
   - New files added
   - Existing files updated
   - Any conflicts or items requiring attention
   - Files that were preserved unchanged due to local modifications

**Specific areas to check**:
- Agent definition files (`.virtualboard/agents/*.md`)
- Prompt templates (`.virtualboard/prompts/**/*.md`)
- Configuration files (e.g., `AGENTS.md`, `README.md`)
- Any new directories or structure changes

**Process**:
1. Fetch the latest template structure from the repository
2. Compare with local `.virtualboard/` contents
3. Create a backup or note current state before making changes
4. Apply updates while preserving local modifications
5. Report all changes made

Please proceed with the update.
```

## Usage Notes

- Run this prompt periodically (e.g., monthly or when you know template updates exist)
- Review the reported changes before committing
- Consider creating a git commit before running to easily revert if needed
- If major conflicts arise, you may need to manually reconcile changes

## Related Files

- `.virtualboard/AGENTS.md` - Agent system documentation
- `.virtualboard/README.md` - VirtualBoard usage instructions
- `.claude/CLAUDE.md` - References agent adoption process

## Version History

- 2025-10-09: Initial version created from successful update workflow
