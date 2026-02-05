# Generate Threat Model (GTM)

**Trigger Phrases:**
- "Generate Threat Model"
- "GTM"
- "Threat modeling"
- "Create threat model"

**Action:**
When the Security Engineer agent receives this command, it should:

## 1. Define System Scope
- Identify the system/feature/component to model
- Define system boundaries and trust boundaries
- List external dependencies and integrations
- Identify users, roles, and actors
- Document data classifications (public, internal, confidential, restricted)

### 2. Create Data Flow Diagrams (DFD)

**DFD Elements:**
- External Entities (users, systems, services)
- Processes (application components, services)
- Data Stores (databases, caches, file systems)
- Data Flows (how data moves between elements)
- Trust Boundaries (where privilege levels change)

**DFD Template:**
```
┌─────────────────┐
│ External Entity │ (User, External System)
└────────┬────────┘
         │ Data Flow
         ▼
┌─────────────────┐
│    Process      │ (Application Component)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Data Store    │ (Database, Cache)
└─────────────────┘

Trust Boundary: ═══════════════════
```

### 3. Identify Threats Using STRIDE

For each DFD element, analyze threats using STRIDE methodology:

**S - Spoofing:**
- [ ] Can an attacker impersonate a user or system?
- [ ] Are authentication mechanisms sufficient?
- [ ] Can tokens/credentials be stolen or forged?

**T - Tampering:**
- [ ] Can data be modified in transit?
- [ ] Can data be modified at rest?
- [ ] Are integrity checks in place?
- [ ] Can configuration be tampered with?

**R - Repudiation:**
- [ ] Can users deny their actions?
- [ ] Are audit logs comprehensive and tamper-proof?
- [ ] Are all critical operations logged?

**I - Information Disclosure:**
- [ ] Can sensitive data be exposed?
- [ ] Are error messages revealing too much?
- [ ] Is data encrypted appropriately?
- [ ] Can logs leak sensitive information?

**D - Denial of Service:**
- [ ] Can the system be overwhelmed?
- [ ] Are rate limits implemented?
- [ ] Are resource quotas enforced?
- [ ] Can expensive operations be triggered repeatedly?

**E - Elevation of Privilege:**
- [ ] Can users gain unauthorized access?
- [ ] Are authorization checks comprehensive?
- [ ] Can privilege escalation occur through injection?
- [ ] Are administrative functions properly protected?

### 4. Assess Risk for Each Threat

**Risk Matrix:**
```
Impact:
Critical (4) - Data breach, system compromise, regulatory violation
High (3)     - Significant data loss, major service disruption
Medium (2)   - Limited data exposure, degraded performance
Low (1)      - Minor information disclosure, temporary inconvenience

Likelihood:
High (3)     - Easy to exploit, common attack vector
Medium (2)   - Requires some skill or specific conditions
Low (1)      - Difficult to exploit, requires insider access

Risk Score = Impact × Likelihood
```

**Risk Levels:**
- 9-12: Critical (Immediate mitigation required)
- 6-8: High (Mitigation within sprint)
- 3-4: Medium (Plan mitigation)
- 1-2: Low (Monitor and accept or mitigate later)

### 5. Define Mitigations

For each identified threat, provide:
- **Preventive Controls:** Stop the threat from occurring
- **Detective Controls:** Detect when threat occurs
- **Corrective Controls:** Respond to and recover from threat

**Common Mitigations:**
- Authentication/Authorization mechanisms
- Encryption (at rest, in transit)
- Input validation and sanitization
- Rate limiting and throttling
- Security logging and monitoring
- Network segmentation
- Least privilege access
- Security headers
- CSRF tokens
- Content Security Policy

### 6. Generate Threat Model Document
Create document at `.virtualboard/security/threat-models/TM-{YYYY-MM-DD}-{component}.md`:

```markdown
# Threat Model: {System/Feature Name}
**Date:** {YYYY-MM-DD}
**Version:** 1.0
**Author:** Security Engineer
**Status:** Draft | Under Review | Approved

---

## 1. System Overview
### Purpose
{Description of what the system does}

### Scope
{What is included in this threat model}

### Out of Scope
{What is explicitly not covered}

---

## 2. System Architecture

### Components
1. **{Component Name}**
   - Type: {Web App/API/Database/etc}
   - Technology: {Tech stack}
   - Hosting: {Cloud/On-prem/etc}
   - Trust Level: {Public/Internal/Restricted}

### External Dependencies
- {Service Name}: {Purpose}
- {Library Name}: {Purpose}

### Users & Roles
| Role | Access Level | Permissions |
|------|-------------|-------------|
| Anonymous User | Public | Read public content |
| Authenticated User | Internal | CRUD own data |
| Administrator | Restricted | Full system access |

### Data Classification
| Data Type | Classification | Storage | Encryption |
|-----------|---------------|---------|------------|
| User Credentials | Restricted | Database | At rest + in transit |
| PII | Confidential | Database | At rest + in transit |
| Session Tokens | Restricted | Redis | In transit |
| Public Content | Public | CDN | In transit |

---

## 3. Data Flow Diagram

```
[User Browser] ─────(1. HTTPS Request)────> [Load Balancer]
                                                    │
                                                    │ (2. Forward)
                                                    ▼
                                            [Web Application]
                                                    │
                                   ┌────────────────┼────────────────┐
                                   │                │                │
                          (3. Auth) │       (4. Query) │    (5. Cache) │
                                   ▼                ▼                ▼
                            [Auth Service]    [Database]      [Redis Cache]
                                   │
                          (6. MFA) │
                                   ▼
                            [MFA Provider]

Trust Boundaries:
═══════════════════════════════════════════════════════════════════
Public Internet | DMZ | Internal Network | Data Layer
═══════════════════════════════════════════════════════════════════
```

### Data Flow Descriptions
1. **User → Load Balancer:** User initiates HTTPS request
2. **Load Balancer → Web App:** Request forwarded with TLS termination
3. **Web App → Auth Service:** Authentication validation
4. **Web App → Database:** Query user data
5. **Web App → Cache:** Check/store cached data
6. **Auth Service → MFA Provider:** Multi-factor authentication

---

## 4. Threat Analysis

### Threat #1: Session Token Theft (Spoofing)
- **Element:** Data Flow 1 (User → Load Balancer)
- **STRIDE Category:** Spoofing
- **Description:** Attacker intercepts or steals session token to impersonate user
- **Attack Vectors:**
  - XSS attack to steal token from browser
  - Man-in-the-middle attack on unsecured connection
  - Token exposed in logs or error messages
- **Impact:** Critical (4)
- **Likelihood:** Medium (2)
- **Risk Score:** 8 (High)
- **Existing Mitigations:**
  - HTTPOnly cookies prevent XSS access
  - Secure flag ensures HTTPS-only transmission
  - TLS 1.3 encrypts all traffic
- **Residual Risk:** Medium
- **Additional Mitigations Needed:**
  - [ ] Implement token rotation on privilege escalation
  - [ ] Add device fingerprinting
  - [ ] Implement concurrent session detection
  - [ ] Add session binding to IP address (optional)
- **Status:** Mitigation planned

---

### Threat #2: SQL Injection (Tampering)
- **Element:** Data Flow 4 (Web App → Database)
- **STRIDE Category:** Tampering
- **Description:** Attacker injects malicious SQL to modify or extract data
- **Attack Vectors:**
  - Unsanitized user input in SQL queries
  - Dynamic query construction
  - Second-order SQL injection through stored data
- **Impact:** Critical (4)
- **Likelihood:** Low (1)
- **Risk Score:** 4 (Medium)
- **Existing Mitigations:**
  - ✅ Parameterized queries used throughout
  - ✅ ORM with built-in protection
  - ✅ Database user has limited permissions
  - ✅ Input validation on all endpoints
- **Residual Risk:** Low
- **Additional Mitigations Needed:**
  - [ ] Add automated SQL injection testing to CI/CD
  - [ ] Implement database query monitoring
- **Status:** Accepted with monitoring

---

### Threat #3: Insufficient Logging (Repudiation)
- **Element:** Process (Web Application)
- **STRIDE Category:** Repudiation
- **Description:** Users can deny malicious actions due to insufficient audit logs
- **Impact:** High (3)
- **Likelihood:** High (3)
- **Risk Score:** 9 (Critical)
- **Existing Mitigations:**
  - Basic access logs enabled
- **Residual Risk:** High
- **Required Mitigations:**
  - [ ] Implement comprehensive audit logging
  - [ ] Log all authentication events
  - [ ] Log all data modifications with user context
  - [ ] Log all privilege escalations
  - [ ] Implement log integrity protection
  - [ ] Set up log monitoring and alerting
- **Status:** Mitigation required (Sprint 1)

---

### Threat #4: PII Exposure in Logs (Information Disclosure)
- **Element:** Data Store (Application Logs)
- **STRIDE Category:** Information Disclosure
- **Description:** Sensitive PII logged in error messages or debug logs
- **Impact:** Critical (4)
- **Likelihood:** Medium (2)
- **Risk Score:** 8 (High)
- **Existing Mitigations:**
  - Error handling with generic messages
- **Residual Risk:** High
- **Required Mitigations:**
  - [ ] Implement PII masking in logging framework
  - [ ] Audit all log statements for sensitive data
  - [ ] Implement log access controls
  - [ ] Add automated PII detection in logs
- **Status:** Mitigation required (Sprint 1)

---

### Threat #5: API Rate Limit Bypass (Denial of Service)
- **Element:** Data Flow 1 (User → Load Balancer)
- **STRIDE Category:** Denial of Service
- **Description:** Attacker overwhelms API with requests, degrading service
- **Impact:** High (3)
- **Likelihood:** High (3)
- **Risk Score:** 9 (Critical)
- **Existing Mitigations:**
  - Basic rate limiting at load balancer (100 req/min per IP)
- **Residual Risk:** Medium
- **Required Mitigations:**
  - [ ] Implement tiered rate limiting (IP, user, API key)
  - [ ] Add CAPTCHA for suspicious patterns
  - [ ] Implement request queuing and backpressure
  - [ ] Add DDoS protection service
  - [ ] Monitor and alert on traffic spikes
- **Status:** Mitigation in progress

---

### Threat #6: Privilege Escalation via IDOR (Elevation of Privilege)
- **Element:** Process (Web Application)
- **STRIDE Category:** Elevation of Privilege
- **Description:** User accesses other users' data by manipulating object IDs
- **Impact:** Critical (4)
- **Likelihood:** Medium (2)
- **Risk Score:** 8 (High)
- **Existing Mitigations:**
  - Basic authentication checks
- **Residual Risk:** High
- **Required Mitigations:**
  - [ ] Implement object-level authorization checks
  - [ ] Use indirect references (mapping layer)
  - [ ] Add automated IDOR testing
  - [ ] Implement resource ownership validation
- **Status:** Mitigation required (Sprint 2)

---

## 5. Risk Summary

### Critical Risks (9-12)
| ID | Threat | Risk Score | Status |
|----|--------|-----------|--------|
| #3 | Insufficient Logging | 9 | Mitigation required |
| #5 | API Rate Limit Bypass | 9 | Mitigation in progress |

### High Risks (6-8)
| ID | Threat | Risk Score | Status |
|----|--------|-----------|--------|
| #1 | Session Token Theft | 8 | Mitigation planned |
| #4 | PII Exposure in Logs | 8 | Mitigation required |
| #6 | Privilege Escalation via IDOR | 8 | Mitigation required |

### Medium Risks (3-4)
| ID | Threat | Risk Score | Status |
|----|--------|-----------|--------|
| #2 | SQL Injection | 4 | Accepted with monitoring |

---

## 6. Mitigation Roadmap

### Sprint 1 (Immediate)
- [ ] Implement comprehensive audit logging (#3)
- [ ] Implement PII masking in logs (#4)
- [ ] Add log monitoring and alerting (#3)

### Sprint 2 (Short-term)
- [ ] Implement object-level authorization (#6)
- [ ] Add session token rotation (#1)
- [ ] Complete tiered rate limiting (#5)

### Sprint 3 (Medium-term)
- [ ] Add automated security testing to CI/CD (#2, #6)
- [ ] Implement device fingerprinting (#1)
- [ ] Add DDoS protection service (#5)

---

## 7. Assumptions & Dependencies

**Assumptions:**
- TLS certificates are properly managed and renewed
- Database backups are encrypted and tested regularly
- Network segmentation is properly configured
- Developers follow secure coding guidelines

**Dependencies:**
- Security team approval for architecture changes
- Budget approval for DDoS protection service
- Third-party MFA provider SLA maintained

---

## 8. Review & Approval

| Role | Name | Status | Date |
|------|------|--------|------|
| Security Engineer | {Name} | Completed | {Date} |
| System Architect | {Name} | Pending | |
| Development Lead | {Name} | Pending | |
| Product Manager | {Name} | Pending | |

---

## 9. Maintenance

**Next Review Date:** {Date - typically 6 months or when major changes occur}

**Review Triggers:**
- Major feature additions
- Architecture changes
- New integrations or dependencies
- Security incidents
- Compliance requirement changes

---

**Document Version History:**
- v1.0 ({Date}): Initial threat model created
```

### 7. Create Visual Diagrams
Generate supplementary diagram files:

**Architecture Diagram** (`.virtualboard/security/threat-models/diagrams/TM-{component}-architecture.md`):
- System components and their relationships
- Network boundaries and zones
- Data flow paths

**Attack Tree Diagram** (`.virtualboard/security/threat-models/diagrams/TM-{component}-attack-tree.md`):
- Root: Primary security objective
- Branches: Different attack paths
- Leaves: Specific vulnerabilities or attack techniques

### 8. Announce Completion
- Provide threat model document path
- Highlight critical and high-risk threats
- Summarize mitigation roadmap
- Request stakeholder review and approval
- Offer to create mitigation tasks in `.virtualboard/backlog/`
