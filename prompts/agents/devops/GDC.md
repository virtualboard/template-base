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
