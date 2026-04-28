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

### 5. Optional — Generate Branded HTML Report

If the user appends `--html`, says "as HTML"/"branded HTML", or sets
`format: html`, also produce an HTML rendering. **Additive** — Markdown is
always written first.

1. Load `templates/reports/html/security-audit.html`. The comment block at
   the top of that file lists every placeholder this command must compute.
2. Inline `{{INCLUDE: _partials/<name>.html}}` directives until none remain.
3. Substitute `{{BRAND_LOGO_DATAURI}}` from
   `templates/reports/html/_partials/astucia-logo.b64.txt` (strip leading and
   trailing whitespace).
4. Substitute `{{BRAND_NAME}}` (`Astucia`) and `{{BRAND_TAGLINE}}`
   (`AI Development Studio`) unless overridden.
5. Substitute the cross-cutting placeholders and per-template scalars
   (`AUDIT_SCOPE_HTML`, `EXECUTIVE_SUMMARY_HTML`, `KPI_FINDINGS`,
   `KPI_CRITICAL`, `KPI_HIGH`, `KPI_MEDIUM`, `KPI_LOW`, `OVERALL_RATING`,
   `OVERALL_RATING_CLASS`, `COMPLIANCE_HTML`, `TIMELINE_HTML`,
   `NEXT_AUDIT_DATE`).
6. Build `FINDINGS_JSON` as a `JSON.stringify`-formatted array of objects
   with keys `id`, `sev` (`critical`/`high`/`medium`/`low`), `title`, `file`,
   `impact`, `likelihood`, `reco`. Escape any literal `</` inside values as
   `<\/` to keep the inline `<script>` tag intact.
7. Expand the list blocks (`HERO_META_CELLS`, `STANDARDS_CHECKED`,
   `REMEDIATION_IMMEDIATE`, `REMEDIATION_SHORT`, `REMEDIATION_LONG`).
8. Set each `LIST_EMPTY_<NAME>` scalar to `""` if the list has items, or to
   a small italic note if empty.
9. Write the HTML next to the Markdown:
   `.virtualboard/security/audits/SA-{YYYY-MM-DD}.html`.
10. Verify no literal `{{` remains. Report both file paths.

Reference example: `templates/reports/examples/security-audit.example.html`.
