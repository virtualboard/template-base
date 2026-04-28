# Generate Deployment Checklist (GDC)

**Trigger Phrases:**
- "Generate Deployment Checklist"
- "GDC"
- "Create deployment checklist"
- "Deployment verification"

**Action:**
When the DevOps agent receives this command, it should:

## 1. Analyze Deployment Scope
- Identify features/changes being deployed
- Review infrastructure requirements
- Check dependency updates
- Assess risk level (low/medium/high)

### 2. Create Comprehensive Checklist
- Create checklist at `.virtualboard/deployments/checklists/DC-{YYYY-MM-DD}-{environment}.md`
- Use the following structure:

```markdown
# Deployment Checklist
**Date:** {YYYY-MM-DD}
**Environment:** {dev/staging/production}
**Risk Level:** Low | Medium | High
**Deploy Lead:** {Person/Team}

---

## Pre-Deployment Checks

### Code & Build
- [ ] All CI/CD pipelines passing
- [ ] Code reviewed and approved
- [ ] Unit tests passing (coverage >= X%)
- [ ] Integration tests passing
- [ ] No known critical/blocker bugs
- [ ] Version numbers updated
- [ ] Changelog updated

### Infrastructure
- [ ] Infrastructure changes reviewed
- [ ] Capacity planning verified
- [ ] Database migrations tested
- [ ] Environment variables configured
- [ ] Secrets/credentials rotated (if needed)
- [ ] DNS changes prepared (if needed)

### Security
- [ ] Security scan completed
- [ ] Dependency vulnerabilities addressed
- [ ] Access controls verified
- [ ] Compliance requirements met

### Monitoring & Observability
- [ ] Logging configured
- [ ] Metrics/dashboards updated
- [ ] Alerts configured
- [ ] APM/tracing enabled

---

## Deployment Steps

### 1. Pre-Deploy
- [ ] Notify stakeholders
- [ ] Schedule maintenance window (if needed)
- [ ] Database backup completed
- [ ] Rollback plan documented

### 2. Deploy
- [ ] Execute deployment script/pipeline
- [ ] Verify deployment logs
- [ ] Run smoke tests
- [ ] Verify health checks

### 3. Post-Deploy Verification
- [ ] Application responding
- [ ] Database migrations applied
- [ ] API endpoints functional
- [ ] Frontend assets loading
- [ ] No error spikes in logs
- [ ] Performance within SLA
- [ ] User flows working

---

## Rollback Plan

**Trigger Conditions:**
- {Condition 1}
- {Condition 2}

**Rollback Steps:**
1. {Step 1}
2. {Step 2}
3. {Step 3}

**Rollback Time:** ~{X} minutes

---

## Post-Deployment

- [ ] Monitor for {X} hours
- [ ] Update runbooks (if needed)
- [ ] Document lessons learned
- [ ] Close deployment ticket
- [ ] Notify stakeholders of completion

---

**Status:** Pending | In Progress | Completed | Rolled Back
**Last Updated:** {YYYY-MM-DD HH:MM}
```

### 3. Announce Completion
- Inform user that checklist has been created
- Provide file path
- Highlight critical items and rollback plan

---

## Optional: Generate Branded HTML Report

If the user appends `--html`, says "as HTML"/"branded HTML", or sets
`format: html`, also produce an HTML rendering. **Additive** — the Markdown
report is always written first.

1. Load `templates/reports/html/devops-deployment-checklist.html`. The comment block at the top of
   that file lists every placeholder this command must compute, with the same
   names used in the Markdown report.
2. Inline `{INCLUDE: _partials/<name>.html}` directives by reading and
   pasting the referenced files; iterate until no `{INCLUDE:` markers remain.
3. Substitute `{BRAND_LOGO_DATAURI}` with the contents of
   `templates/reports/html/_partials/astucia-logo.b64.txt`, **stripping leading
   and trailing whitespace** (the file may end in a newline that must not
   appear inside `src="…"`).
4. Substitute `{BRAND_NAME}` (default `Astucia`) and `{BRAND_TAGLINE}`
   (default `AI Development Studio`) unless the user provided overrides.
5. Substitute the cross-cutting placeholders (`REPORT_TITLE`,
   `REPORT_TITLE_HTML`, `REPORT_SUBTITLE`, `EYEBROW`, `GENERATED_DATE`,
   `GENERATED_DATETIME`, `AUTHOR_AGENT`, `CLASSIFICATION`, `PROJECT_NAME`,
   `NAV_LINKS`, `FOOTER_PRIMARY_LINE`, `FOOTER_SECONDARY_LINE`,
   `FOOTER_NOTE_BLOCK`, `EXTRA_SCRIPTS`).
6. Substitute the per-template scalar placeholders:
   `ENVIRONMENT`, `TARGET_VERSION`, `DEPLOY_WINDOW`, `OWNER`, `KPI_TOTAL`, `KPI_REQUIRED`, `KPI_DONE`, `KPI_PENDING`, `NOTES_HTML`.
7. Expand each `{#NAME}…{/NAME}` list block once per item using the
   per-template list placeholders: `HERO_META_CELLS`, `PRE_DEPLOY`, `DEPLOY`, `POST_DEPLOY`, `ROLLBACK_STEPS`. The per-item field names are
   documented in the template's top comment.
8. For each list, set the matching `LIST_EMPTY_<NAME>` scalar to `""` if the
   list has items, or to a small italic note (e.g.
   `<p class="empty-note">No items.</p>`) if the list is empty.
9. Write the rendered HTML next to the Markdown:
   `.virtualboard/deployments/checklists/DC-{YYYY-MM-DD}-{env}.html`.
10. **Verify before reporting completion.** Search the rendered output for any
    literal `{` — there must be none. Resolve leftovers (or substitute the
    empty string for known-optional slots) before continuing.
11. In your final reply, list **both** file paths.

A filled-in reference example lives at
`templates/reports/examples/devops-deployment-checklist.example.html`.
