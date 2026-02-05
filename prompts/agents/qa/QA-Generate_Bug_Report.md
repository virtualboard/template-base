# Generate Bug Report (GBR)

**Trigger Phrases:**
- "Generate Bug Report"
- "GBR"
- "Report bug"
- "Create bug report"
- "Log defect"

**Action:**
When the QA agent receives this command, it should:

## 1. Gather Bug Information
- Identify the bug/defect observed
- Determine what functionality is affected
- Assess the impact on users/system
- Check if this is a regression or new issue
- Verify the bug is reproducible

### 2. Classify Bug Severity
- **Critical/Blocker:** System crash, data loss, security vulnerability, no workaround
- **High:** Major feature broken, significant impact, difficult workaround exists
- **Medium:** Feature partially broken, moderate impact, workaround available
- **Low:** Minor issue, cosmetic problem, minimal impact

### 3. Classify Bug Priority
- **P0 (Urgent):** Must fix immediately, blocking release
- **P1 (High):** Should fix in current sprint
- **P2 (Medium):** Fix in next 1-2 sprints
- **P3 (Low):** Fix when time permits

### 4. Create Bug Report
- Create bug report at `.virtualboard/testing/bugs/BUG-{####}-{short-description}.md`
- Use the following structure:

```markdown
# Bug Report: {Short Description}

**Bug ID:** BUG-{####}
**Created:** {YYYY-MM-DD}
**Reporter:** {Agent/Person}
**Status:** Open | In Progress | Fixed | Closed | Won't Fix
**Severity:** Critical | High | Medium | Low
**Priority:** P0 | P1 | P2 | P3

---

## Summary
{One-line description of the bug}

## Description
{Detailed description of what's wrong and the impact}

---

## Environment
- **Platform/OS:** {e.g., Windows 11, macOS 14, Ubuntu 22.04}
- **Browser:** {e.g., Chrome 120, Firefox 121} *(if applicable)*
- **Version/Build:** {Application version or commit hash}
- **Environment:** {dev/staging/production}
- **Device:** {Desktop/Mobile/Tablet} *(if applicable)*

---

## Steps to Reproduce
1. {Step 1 - be specific}
2. {Step 2 - include exact inputs/data}
3. {Step 3 - include actions taken}
4. {Continue as needed}

## Expected Behavior
{What should happen when following the steps above}

## Actual Behavior
{What actually happens - describe the bug}

---

## Visual Evidence

### Screenshots
{Add screenshots if applicable}
- Screenshot 1: {Description}
- Screenshot 2: {Description}

### Error Messages/Logs
```
{Paste exact error messages, stack traces, or relevant logs}
```

### Video Recording
{Link to video recording if available}

---

## Reproduction Rate
- [ ] 100% - Always reproducible
- [ ] 75-99% - Almost always reproducible
- [ ] 50-74% - Frequently reproducible
- [ ] 25-49% - Sometimes reproducible
- [ ] <25% - Rarely reproducible

## Impact Assessment
- **Users Affected:** {All users / Specific user group / Edge case}
- **Business Impact:** {Revenue impact, user experience, compliance, etc.}
- **Workaround Available:** {Yes/No - describe if yes}

---

## Technical Analysis

### Root Cause (if known)
{Technical explanation of what's causing the bug}

### Affected Components
- {Component/Module 1}
- {Component/Module 2}
- {Related systems}

### Related Issues
- Related to: BUG-{####}
- Blocks: FTR-{####}
- Blocked by: BUG-{####}

---

## Proposed Solution
{Suggested fix or approach to resolve the bug}

## Testing Notes
{How to verify the fix / What to test after fixing}

---

## Additional Context
{Any other relevant information, browser console logs, network requests, etc.}

## Attachments
- {File 1}
- {File 2}

---

**Last Updated:** {YYYY-MM-DD}
**Assigned To:** {Developer name/agent}
**Fixed In:** {Version/Build number}
```

### 5. Create Directory if Needed
- Ensure `.virtualboard/testing/bugs/` exists
- Use `mkdir -p` to create if necessary

### 6. Determine Escalation Needs
- **Escalate immediately if:**
  - Severity is Critical/Blocker
  - Security vulnerability detected
  - Data loss or corruption possible
  - Production system affected
  - Privacy/compliance issue

### 7. Link to Related Items
- Link bug to related feature (if applicable): `FTR-####`
- Link to test plan where bug was found (if applicable): `TP-FTR-####`
- Reference any related bugs or issues

### 8. Announce Completion
- Inform the user that the bug report has been created
- Provide the file path
- Highlight severity, priority, and any escalation needs
- Suggest next steps (assign to developer, add to sprint, etc.)
