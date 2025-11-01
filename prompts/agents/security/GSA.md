# Generate Security Audit (GSA)

**Trigger Phrases:**
- "Generate Security Audit"
- "GSA"
- "Security audit"
- "Audit security"
- "Security assessment"

**Action:**
When the Security Engineer agent receives this command, it should:

## 1. Scope Definition
- Identify systems/features to audit
- Define security domains: AuthN/AuthZ, Data, Infrastructure, Code
- Determine compliance requirements (GDPR, SOC2, HIPAA, etc.)

### 2. Perform Security Checks

**Authentication & Authorization:**
- [ ] Authentication mechanisms reviewed
- [ ] Password policies enforced
- [ ] MFA implementation verified
- [ ] Session management secure
- [ ] Authorization checks present
- [ ] Role-based access control (RBAC) implemented

**Data Security:**
- [ ] Data encrypted at rest
- [ ] Data encrypted in transit (TLS)
- [ ] Sensitive data properly masked/redacted
- [ ] PII handling compliant
- [ ] Database access controlled

**Code Security:**
- [ ] Input validation present
- [ ] SQL injection prevention
- [ ] XSS prevention measures
- [ ] CSRF tokens implemented
- [ ] Dependency vulnerabilities scanned
- [ ] Secrets not hardcoded

**Infrastructure:**
- [ ] Firewall rules reviewed
- [ ] Network segmentation proper
- [ ] Least privilege access
- [ ] Logging and monitoring enabled
- [ ] Backup and recovery tested

### 3. Generate Audit Report
Create report at `.virtualboard/security/audits/SA-{YYYY-MM-DD}.md`:

```markdown
# Security Audit Report
**Date:** {YYYY-MM-DD}
**Auditor:** Security Engineer
**Scope:** {System/Feature}
**Compliance:** {Standards}

---

## Executive Summary
{High-level findings and risk assessment}

## Findings

### Critical Issues
- **C-001:** {Issue description}
  - **Risk:** High
  - **Impact:** {Description}
  - **Remediation:** {Steps to fix}
  - **Deadline:** {Date}

### High Priority
- **H-001:** {Issue description}
  - **Risk:** Medium-High
  - **Impact:** {Description}
  - **Remediation:** {Steps to fix}

### Medium Priority
- **M-001:** {Issue description}

### Low Priority / Recommendations
- **L-001:** {Issue description}

---

## Compliance Status
- GDPR: ✅ Compliant | ⚠️ Partial | ❌ Non-compliant
- SOC2: {Status}
- {Other standards}

## Recommendations
1. {Priority recommendation}
2. {Priority recommendation}

## Timeline
- Critical fixes: Within 7 days
- High priority: Within 30 days
- Medium priority: Within 90 days

---

**Next Audit:** {Date}
```

### 4. Announce Completion
- Provide audit report path
- Highlight critical/high-priority issues
- Suggest immediate remediation steps
