# Generate Security Review (GSR)

**Trigger Phrases:**
- "Generate Security Review"
- "GSR"
- "Review security"
- "Security code review"

**Action:**
When the Security Engineer agent receives this command, it should:

## 1. Define Review Scope
- Identify code/feature/module to review
- Determine review type: Full codebase, new feature, changed files, or specific component
- List files and directories to analyze

### 2. Perform Security Code Review

**OWASP Top 10 Checks:**
- [ ] A01:2021 - Broken Access Control
- [ ] A02:2021 - Cryptographic Failures
- [ ] A03:2021 - Injection vulnerabilities
- [ ] A04:2021 - Insecure Design
- [ ] A05:2021 - Security Misconfiguration
- [ ] A06:2021 - Vulnerable and Outdated Components
- [ ] A07:2021 - Identification and Authentication Failures
- [ ] A08:2021 - Software and Data Integrity Failures
- [ ] A09:2021 - Security Logging and Monitoring Failures
- [ ] A10:2021 - Server-Side Request Forgery (SSRF)

**Input Validation:**
- [ ] All user inputs validated and sanitized
- [ ] Type checking enforced
- [ ] Length/size limits applied
- [ ] Whitelist validation used where possible
- [ ] Special characters properly escaped
- [ ] File upload validation (type, size, content)

**Authentication & Authorization:**
- [ ] Authentication required for protected endpoints
- [ ] Authorization checks at function/route level
- [ ] No authentication bypass vulnerabilities
- [ ] Password complexity enforced
- [ ] Account lockout mechanisms present
- [ ] Session tokens securely generated
- [ ] JWT tokens properly validated
- [ ] API keys not exposed in client code

**Cryptography:**
- [ ] Strong algorithms used (AES-256, RSA-2048+)
- [ ] No weak hashing (MD5, SHA1)
- [ ] Proper use of salts and IVs
- [ ] Secure random number generation
- [ ] Certificate validation enabled
- [ ] TLS 1.2+ enforced

**Secrets Management:**
- [ ] No hardcoded credentials
- [ ] No secrets in environment variables (client-side)
- [ ] Secrets stored in secure vault/manager
- [ ] No secrets in logs or error messages
- [ ] No secrets in version control
- [ ] API keys properly scoped and rotated

**Data Protection:**
- [ ] Sensitive data encrypted at rest
- [ ] Sensitive data encrypted in transit
- [ ] PII properly handled and masked
- [ ] Secure data deletion implemented
- [ ] No sensitive data in URLs
- [ ] No sensitive data in client-side storage

**Error Handling:**
- [ ] No sensitive info in error messages
- [ ] Generic error messages to clients
- [ ] Detailed errors logged securely
- [ ] No stack traces exposed to users
- [ ] Proper exception handling throughout

**Code Quality:**
- [ ] No SQL concatenation (use parameterized queries)
- [ ] No eval() or similar dangerous functions
- [ ] No deserialization of untrusted data
- [ ] Race conditions addressed
- [ ] Resource limits enforced
- [ ] Proper timeout configurations

### 3. Analyze Dependencies
```bash
# Check for vulnerable dependencies
npm audit --audit-level=moderate
pip check
cargo audit
```

**Dependency Review:**
- [ ] All dependencies up to date
- [ ] No known CVEs in dependencies
- [ ] Unnecessary dependencies removed
- [ ] Dependency sources verified
- [ ] License compliance checked

### 4. Generate Security Review Report
Create report at `.virtualboard/security/reviews/SR-{YYYY-MM-DD}-{component}.md`:

```markdown
# Security Review Report
**Date:** {YYYY-MM-DD}
**Reviewer:** Security Engineer
**Scope:** {Component/Feature/Module}
**Files Reviewed:** {Count}
**Lines of Code:** {Approximate count}

---

## Executive Summary
{Brief overview of security posture and key findings}

**Overall Security Rating:** 🔴 Critical | 🟡 Needs Improvement | 🟢 Good

---

## Critical Vulnerabilities
### CVE-001: {Vulnerability Name}
- **Severity:** Critical
- **Type:** {Injection/Auth Bypass/etc}
- **Location:** `{file}:{line}`
- **Description:** {What is vulnerable}
- **Exploit Scenario:** {How it could be exploited}
- **Impact:** {Data breach/System compromise/etc}
- **Remediation:**
  ```{language}
  // Before (vulnerable):
  {vulnerable code}

  // After (secure):
  {fixed code}
  ```
- **Priority:** Immediate (Fix within 24 hours)

---

## High Severity Issues
### HSV-001: {Issue Name}
- **Severity:** High
- **Type:** {Category}
- **Location:** `{file}:{line}`
- **Description:** {Issue details}
- **Remediation:** {Fix instructions}
- **Priority:** Urgent (Fix within 7 days)

---

## Medium Severity Issues
### MSV-001: {Issue Name}
- **Severity:** Medium
- **Location:** `{file}:{line}`
- **Description:** {Issue details}
- **Remediation:** {Fix instructions}

---

## Low Severity / Best Practices
### LSV-001: {Issue Name}
- **Severity:** Low
- **Description:** {Issue details}
- **Recommendation:** {Improvement suggestion}

---

## OWASP Top 10 Compliance
- ✅ A01:2021 - Broken Access Control
- ⚠️ A02:2021 - Cryptographic Failures (2 issues found)
- ✅ A03:2021 - Injection
- {Continue for all 10}

---

## Dependency Vulnerabilities
| Package | Current | Fixed In | Severity | CVE |
|---------|---------|----------|----------|-----|
| {name} | {ver} | {ver} | High | CVE-2024-XXXX |

---

## Positive Findings
- ✅ {Good security practice observed}
- ✅ {Another positive finding}

---

## Recommendations
1. **Immediate Actions:**
   - {Critical fix 1}
   - {Critical fix 2}

2. **Short-term (1-2 weeks):**
   - {High priority fix 1}
   - {High priority fix 2}

3. **Long-term Improvements:**
   - {Enhancement 1}
   - {Enhancement 2}

---

## Code Review Statistics
- Files Reviewed: {count}
- Total Issues Found: {count}
  - Critical: {count}
  - High: {count}
  - Medium: {count}
  - Low: {count}
- Security Test Coverage: {percentage}%

---

## Next Steps
1. {Action item}
2. {Action item}
3. Schedule follow-up review for: {Date}

---

**Reviewer Signature:** Security Engineer Agent
**Review Completed:** {YYYY-MM-DD HH:MM}
```

### 5. Generate Secure Code Examples
For each vulnerability found, provide:
- Vulnerable code snippet
- Secure alternative
- Explanation of the fix
- References to security standards

### 6. Announce Completion
- Provide security review report path
- Highlight critical and high-severity issues
- Provide immediate action items
- Offer to create remediation tasks in `.virtualboard/backlog/`
