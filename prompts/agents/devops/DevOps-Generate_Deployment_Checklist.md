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

If the user requests `--html`, "as HTML"/"branded HTML", or `format: html`,
write the Markdown deliverable first, then render an additional HTML report.

1. Read `templates/reports/html/devops-deployment-checklist.html`. Its comment header lists the
   scalar fields and list-item shapes. Use the same findings and measurements
   as the Markdown report; do not invent values for unknown results.
2. Write a companion JSON data file with uppercase field names, native numbers,
   and arrays of objects for lists. Include every referenced field; use `""`,
   `null`, or `[]` for explicitly empty values. The default brand and raster logo
   are provided by the renderer.
3. Run the deterministic renderer:

   ```bash
   vb report render --template devops-deployment-checklist.html \
     --data REPORT_DATA.json --output REPORT.html
   ```

   Replace the example paths with paths beside the Markdown deliverable, using
   the same basename for `.md`, `.json`, and `.html`. Includes and repeated
   blocks are resolved by the CLI; do not manually substitute template text.
4. Strings are escaped, including `*_HTML` fields. Annotate reviewed markup as
   `{"html":"<p>Reviewed content</p>"}` and add `--allow-html` only when those
   fragments are intended as markup. Supply `*_JSON` fields as native JSON
   values; the renderer safely serializes them in inline scripts.
5. Validate with `--dry-run` if useful, then inspect the generated HTML. Existing
   output requires `--force`; a rendering error must preserve earlier output.
   If the installed CLI lacks `report render`, report that limitation instead
   of claiming an HTML artifact was produced.
6. List the Markdown and HTML paths in the final reply, with the companion JSON
   path so the report can be reproduced.

See `templates/reports/README.md` for the input contract and the runnable
`templates/reports/examples/pm-progress-report.data.json` for a complete example.
