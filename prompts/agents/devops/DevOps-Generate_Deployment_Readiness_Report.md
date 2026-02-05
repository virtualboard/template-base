# Generate Deployment Readiness Report (GDRR)

**Trigger Phrases:**
- "Generate Deployment Readiness Report"
- "GDRR"
- "Create deployment readiness report"
- "Deployment assessment"

**Action:**
When the DevOps agent receives this command, it should:

## 1. Gather Deployment Information
- Identify the target environment (dev/staging/production)
- Review planned changes and features
- Check infrastructure dependencies
- Assess deployment complexity and risk
- Review recent incidents or issues

### 2. Analyze System Readiness
- Review CI/CD pipeline status
- Check infrastructure capacity and health
- Verify monitoring and alerting configuration
- Assess team readiness and availability
- Review security posture

### 3. Evaluate Dependencies
- Check external service dependencies
- Verify database migration readiness
- Review third-party integrations
- Confirm feature flags configuration
- Assess rollback capabilities

### 4. Create Readiness Report
- Create report at `.virtualboard/deployments/readiness/DRR-{YYYY-MM-DD}-{environment}.md`
- Use the following structure:

```markdown
# Deployment Readiness Report
**Date:** {YYYY-MM-DD}
**Environment:** {dev/staging/production}
**Risk Assessment:** Low | Medium | High | Critical
**Prepared By:** {Agent/Person}
**Target Deployment Date:** {YYYY-MM-DD}

---

## Executive Summary

**Overall Readiness:** ✅ Ready | ⚠️ Ready with Conditions | ❌ Not Ready

**Key Findings:**
- {Finding 1}
- {Finding 2}
- {Finding 3}

**Recommendation:** {Proceed/Delay/Cancel and why}

---

## Deployment Overview

### Changes Being Deployed
- {Change 1 - brief description}
- {Change 2 - brief description}
- {Change 3 - brief description}

### Business Impact
- **User Impact:** {High/Medium/Low - description}
- **System Impact:** {Description of technical impact}
- **Rollback Time:** ~{X} minutes
- **Maintenance Window Required:** Yes/No - {Duration if yes}

---

## Technical Readiness

### Code Quality
- [x] All CI/CD pipelines passing
- [x] Code reviews completed
- [x] Unit test coverage >= {X}%
- [x] Integration tests passing
- [ ] Performance tests completed
- [x] Security scans passed

**Status:** ✅ Ready | ⚠️ Issues Found | ❌ Blockers Exist

**Issues:**
- {Issue 1 if any}

---

### Infrastructure Readiness

#### Capacity Planning
- **Current Load:** {X}% capacity
- **Projected Post-Deployment:** {Y}% capacity
- **Scaling Plan:** {Auto-scaling/Manual scaling/None needed}

**Status:** ✅ Ready | ⚠️ Issues Found | ❌ Blockers Exist

#### Resource Checklist
- [ ] Compute resources sufficient
- [ ] Database capacity verified
- [ ] Storage capacity verified
- [ ] Network bandwidth adequate
- [ ] CDN/cache configuration verified

**Configuration:**
```yaml
# Example infrastructure configuration
resources:
  compute:
    instances: {count}
    type: {instance-type}
    auto_scaling: {enabled/disabled}
  database:
    size: {size}
    connections_max: {count}
  storage:
    total: {size}
    available: {size}
```

---

### Database Readiness

#### Migrations
- **Total Migrations:** {count}
- **Estimated Duration:** ~{X} minutes
- **Reversible:** Yes/No
- **Data Impact:** {Description}

**Migration Checklist:**
- [ ] Migrations tested in lower environment
- [ ] Backup strategy confirmed
- [ ] Rollback procedure documented
- [ ] Index creation strategy planned
- [ ] Lock impact assessed

**Example Migration:**
```sql
-- Migration: {migration-name}
-- Duration: ~{X} seconds
-- Impact: {impact description}

BEGIN;
  {SQL statements}
COMMIT;
```

**Status:** ✅ Ready | ⚠️ Issues Found | ❌ Blockers Exist

---

### Security & Compliance

#### Security Checklist
- [ ] Vulnerability scans completed
- [ ] Dependencies up to date
- [ ] Secrets rotated (if needed)
- [ ] Access controls verified
- [ ] SSL/TLS certificates valid
- [ ] API authentication tested

**Findings:**
- {Finding 1 if any}

#### Compliance Requirements
- [ ] {Compliance requirement 1}
- [ ] {Compliance requirement 2}
- [ ] Data privacy requirements met

**Status:** ✅ Ready | ⚠️ Issues Found | ❌ Blockers Exist

---

### Monitoring & Observability

#### Current State
- **Logging:** {Configured/Not Configured}
- **Metrics:** {Configured/Not Configured}
- **Alerts:** {Configured/Not Configured}
- **APM:** {Enabled/Disabled}
- **Dashboards:** {Available/Not Available}

**Monitoring Checklist:**
- [ ] Application logs flowing correctly
- [ ] Error tracking configured
- [ ] Performance metrics tracked
- [ ] Alert thresholds appropriate
- [ ] On-call schedule confirmed
- [ ] Runbooks updated

**Dashboard Links:**
- Application Health: {URL}
- Infrastructure Metrics: {URL}
- Business Metrics: {URL}

**Status:** ✅ Ready | ⚠️ Issues Found | ❌ Blockers Exist

---

## Operational Readiness

### Team Readiness
- **Deploy Lead:** {Name}
- **On-Call Engineer:** {Name}
- **Backup Contact:** {Name}
- **Communication Channel:** {Slack/Teams channel}

**Availability:**
- [ ] Deploy team available during deployment window
- [ ] On-call coverage confirmed for 24h post-deployment
- [ ] Key stakeholders notified
- [ ] Escalation path defined

### Documentation
- [ ] Deployment runbook updated
- [ ] Rollback procedures documented
- [ ] Architecture diagrams current
- [ ] API documentation updated
- [ ] User-facing docs ready

**Status:** ✅ Ready | ⚠️ Issues Found | ❌ Blockers Exist

---

## Risk Assessment

### Identified Risks

#### Risk 1: {Risk Title}
- **Probability:** Low | Medium | High
- **Impact:** Low | Medium | High | Critical
- **Description:** {What could go wrong}
- **Mitigation:** {How we're addressing it}
- **Contingency:** {What we'll do if it happens}

#### Risk 2: {Risk Title}
- **Probability:** Low | Medium | High
- **Impact:** Low | Medium | High | Critical
- **Description:** {What could go wrong}
- **Mitigation:** {How we're addressing it}
- **Contingency:** {What we'll do if it happens}

### Risk Matrix
```
Impact/Probability │ Low    │ Medium │ High
──────────────────┼────────┼────────┼────────
Critical          │        │        │
High              │        │ Risk1  │
Medium            │        │        │ Risk2
Low               │        │        │
```

---

## Rollback Strategy

### Rollback Plan
**Type:** {Blue-Green/Rolling/Database Restore/Git Revert}
**Estimated Time:** ~{X} minutes
**Data Loss Risk:** Yes/No - {Details}

**Trigger Conditions:**
- Error rate exceeds {X}%
- Response time degrades beyond {X}ms
- Critical functionality broken
- {Custom condition}

**Rollback Procedure:**
```bash
# Step 1: Immediate actions
{command or action}

# Step 2: Verify rollback
{verification steps}

# Step 3: Restore data (if needed)
{data restore commands}

# Step 4: Validate
{validation steps}
```

**Rollback Checklist:**
- [ ] Rollback steps tested in lower environment
- [ ] Database rollback procedure ready
- [ ] Communication template prepared
- [ ] Monitoring for rollback health

---

## Dependencies

### External Services
- **Service 1:** {Name} - Status: {Available/At Risk}
  - Version: {version}
  - Contact: {contact info}
  - SLA: {SLA details}

- **Service 2:** {Name} - Status: {Available/At Risk}
  - Version: {version}
  - Contact: {contact info}
  - SLA: {SLA details}

### Internal Dependencies
- [ ] {Dependent service 1} - Ready
- [ ] {Dependent service 2} - Ready
- [ ] {Dependent service 3} - Ready

**Status:** ✅ All Dependencies Ready | ⚠️ Some At Risk | ❌ Blockers Exist

---

## Pre-Deployment Tasks

### Must Complete Before Deploy
- [ ] {Task 1}
- [ ] {Task 2}
- [ ] {Task 3}

### Nice to Have
- [ ] {Optional task 1}
- [ ] {Optional task 2}

---

## Post-Deployment Validation

### Automated Checks
```bash
# Health check
curl https://{environment}.example.com/health

# Smoke test suite
npm run test:smoke

# Performance baseline
artillery run smoke-test.yml
```

### Manual Verification
- [ ] Login flow works
- [ ] Critical user paths functional
- [ ] Admin panel accessible
- [ ] {Custom verification 1}
- [ ] {Custom verification 2}

### Success Criteria
- [ ] All health checks passing
- [ ] Error rate < {X}%
- [ ] Response time < {X}ms p95
- [ ] No critical bugs reported
- [ ] {Custom metric} within acceptable range

**Monitoring Period:** {X} hours of intensive monitoring

---

## Communication Plan

### Stakeholder Notifications

**Pre-Deployment:**
- [ ] Engineering team notified 24h prior
- [ ] Customer support team briefed
- [ ] Stakeholders aware of maintenance window
- [ ] Status page updated (if applicable)

**During Deployment:**
- Updates every: {X} minutes
- Channel: {Slack/Teams/Email}
- Template: "{Brief status update}"

**Post-Deployment:**
- [ ] Success notification sent
- [ ] Monitoring summary shared
- [ ] Known issues documented
- [ ] Retrospective scheduled (if high risk)

---

## Final Recommendation

**Deployment Decision:** ✅ PROCEED | ⚠️ PROCEED WITH CAUTION | ❌ DELAY

**Justification:**
{Detailed explanation of the recommendation based on all factors above}

**Conditions for Proceeding (if applicable):**
1. {Condition 1}
2. {Condition 2}

**Next Steps:**
1. {Step 1}
2. {Step 2}
3. {Step 3}

---

## Sign-Off

- [ ] DevOps Engineer: _________________ Date: _______
- [ ] Engineering Lead: _________________ Date: _______
- [ ] Product Owner: ___________________ Date: _______

---

**Report Generated:** {YYYY-MM-DD HH:MM UTC}
**Valid Until:** {YYYY-MM-DD} (reports expire after {X} days)
**Next Review:** {YYYY-MM-DD}
```

### 5. Create Directory if Needed
- Ensure `.virtualboard/deployments/readiness/` exists
- Use `mkdir -p` to create if necessary

### 6. Announce Completion
- Inform the user that the deployment readiness report has been created
- Provide the file path
- Highlight the overall readiness status and any critical findings
- Note the final recommendation (Proceed/Delay/Cancel)
