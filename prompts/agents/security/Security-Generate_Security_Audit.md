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

If the user requests `--html`, "as HTML"/"branded HTML", or `format: html`,
write the Markdown deliverable first, then render an additional HTML report.

1. Read `templates/reports/html/security-audit.html`. Its comment header lists the
   scalar fields and list-item shapes. Use the same findings and measurements
   as the Markdown report; do not invent values for unknown results.
2. Write a companion JSON data file with uppercase field names, native numbers,
   and arrays of objects for lists. Include every referenced field; use `""`,
   `null`, or `[]` for explicitly empty values. The default brand and raster logo
   are provided by the renderer.
3. Run the deterministic renderer:

   ```bash
   vb report render --template security-audit.html \
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
