# Generate Architecture Report (GAR)

**Trigger Phrases:**
- "Generate Architecture Report"
- "GAR"
- "Create architecture report"
- "Architecture analysis"

**Action:**
When the Architect agent receives this command, it should:

## 1. Analyze System Architecture
- Scan project structure and key directories
- Identify architectural patterns in use (MVC, microservices, layered, etc.)
- Review technology stack and frameworks
- Map component dependencies and relationships
- Identify integration points and external dependencies

### 2. Assess Architecture Quality
- **Scalability:** Evaluate horizontal/vertical scaling capabilities
- **Performance:** Identify potential bottlenecks and optimization opportunities
- **Security:** Review security patterns and vulnerabilities
- **Maintainability:** Assess code organization and modularity
- **Testability:** Review test coverage and testing architecture
- **Reliability:** Evaluate error handling and resilience patterns

### 3. Generate Architecture Report
Create report at `.virtualboard/architecture/reports/AR-{YYYY-MM-DD}.md`:

```markdown
# Architecture Report
**Generated:** {YYYY-MM-DD}
**Architect:** {Name/Team}
**System:** {Project Name}

---

## Executive Summary
{2-3 sentence overview of architecture health and key findings}

---

## System Overview

### Technology Stack
- **Frontend:** {Framework/libraries}
- **Backend:** {Framework/language}
- **Database:** {Database system}
- **Infrastructure:** {Cloud provider, deployment model}
- **External Services:** {Third-party integrations}

### Architecture Pattern
**Primary Pattern:** {Monolith/Microservices/Serverless/Layered/etc.}

**Description:** {Brief description of how the architecture is organized}

---

## Component Analysis

### Layer 1: {Layer Name} (e.g., Presentation Layer)
**Purpose:** {What this layer does}
**Technologies:** {Technologies used}
**Components:**
- `{Component 1}` - {Description}
- `{Component 2}` - {Description}

**Dependencies:**
- Depends on: {Other layers/components}
- Used by: {Other layers/components}

**Health:** ✅ Good | ⚠️ Needs Attention | ❌ Critical Issues

---

### Layer 2: {Layer Name}
{Repeat structure}

---

## Architecture Diagram

```mermaid
graph TB
    UI[User Interface]
    API[API Gateway]
    Auth[Authentication Service]
    BL[Business Logic]
    Data[Data Access Layer]
    DB[(Database)]
    Cache[(Cache)]
    Queue[Message Queue]

    UI --> API
    API --> Auth
    API --> BL
    BL --> Data
    Data --> DB
    Data --> Cache
    BL --> Queue
```

---

## Quality Attributes Assessment

### Scalability
**Rating:** ⭐⭐⭐⭐☆ (4/5)
**Strengths:**
- {Strength 1}
- {Strength 2}

**Weaknesses:**
- {Weakness 1}
- {Weakness 2}

**Recommendations:**
- {Recommendation 1}

---

### Performance
**Rating:** ⭐⭐⭐☆☆ (3/5)
**Bottlenecks Identified:**
- {Bottleneck 1}: {Description}
- {Bottleneck 2}: {Description}

**Optimization Opportunities:**
- {Opportunity 1}
- {Opportunity 2}

---

### Security
**Rating:** ⭐⭐⭐⭐☆ (4/5)
**Security Measures:**
- ✅ {Measure 1}
- ✅ {Measure 2}
- ⚠️ {Gap 1}

**Vulnerabilities:**
- {Vulnerability description and remediation}

---

### Maintainability
**Rating:** ⭐⭐⭐☆☆ (3/5)
**Code Organization:** {Assessment}
**Documentation:** {Assessment}
**Technical Debt:** {Assessment}

---

### Testability
**Rating:** ⭐⭐⭐⭐☆ (4/5)
**Test Coverage:** {XX}%
**Testing Strategy:**
- Unit Tests: {Status}
- Integration Tests: {Status}
- E2E Tests: {Status}

---

### Reliability
**Rating:** ⭐⭐⭐☆☆ (3/5)
**Error Handling:** {Assessment}
**Monitoring:** {Assessment}
**Disaster Recovery:** {Assessment}

---

## Dependency Analysis

### External Dependencies
| Dependency | Version | Last Updated | Vulnerabilities | Status |
|------------|---------|--------------|-----------------|--------|
| {Package}  | {Ver}   | {Date}       | {Count}         | ✅/⚠️/❌ |

### Internal Dependencies
```mermaid
graph LR
    A[Module A] --> B[Module B]
    A --> C[Module C]
    B --> D[Module D]
    C --> D
```

**Circular Dependencies:** {None | List if found}
**Coupling Assessment:** {Tight/Loose coupling analysis}

---

## Architectural Patterns & Principles

### Patterns in Use
- ✅ {Pattern 1}: {Where/how it's used}
- ✅ {Pattern 2}: {Where/how it's used}
- ⚠️ {Anti-pattern found}: {Description}

### SOLID Principles Adherence
- **Single Responsibility:** {Assessment}
- **Open/Closed:** {Assessment}
- **Liskov Substitution:** {Assessment}
- **Interface Segregation:** {Assessment}
- **Dependency Inversion:** {Assessment}

---

## Technical Debt

### High Priority Debt
1. {Debt Item 1}
   - Impact: High/Medium/Low
   - Effort: {Estimate}
   - Recommendation: {Action}

### Medium Priority Debt
1. {Debt Item 1}

### Low Priority Debt
1. {Debt Item 1}

**Total Debt Score:** {X}/10 (lower is better)

---

## Integration Points

### External Integrations
| Service | Type | Purpose | Health Check | Documentation |
|---------|------|---------|--------------|---------------|
| {Name}  | REST | {Why}   | ✅           | {Link}        |

### API Contracts
- **Versioning Strategy:** {Strategy}
- **Breaking Changes:** {How handled}
- **Documentation:** {OpenAPI/Swagger/etc.}

---

## Recommendations

### Immediate Actions (0-30 days)
1. {Action 1}
   - Why: {Justification}
   - Impact: {Expected benefit}
   - Effort: {Estimate}

2. {Action 2}

### Short-term (1-3 months)
1. {Action 1}

### Long-term (3-12 months)
1. {Action 1}

---

## Architecture Evolution

### Recent Changes
- {YYYY-MM-DD}: {Change description}

### Planned Changes
- {Future architecture improvements}

### Migration Paths
- {From current state to future state}

---

## Metrics

### System Metrics
- **Response Time (p95):** {X}ms
- **Throughput:** {X} req/s
- **Error Rate:** {X}%
- **Uptime:** {XX.XX}%

### Code Metrics
- **Lines of Code:** {X}
- **Cyclomatic Complexity:** {Avg/Max}
- **Test Coverage:** {XX}%
- **Code Duplication:** {X}%

---

## Risk Assessment

### High Risks
- {Risk 1}
  - Likelihood: High/Medium/Low
  - Impact: High/Medium/Low
  - Mitigation: {Strategy}

### Medium Risks
- {Risk 1}

---

## Conclusion

{Summary of architecture health, key strengths, critical improvements needed}

---

## Related Documents
- Architecture Decision Records: `.virtualboard/architecture/decisions/`
- Technical Specifications: {Links}
- System Diagrams: {Links}

---

**Next Review:** {YYYY-MM-DD}
**Last Updated:** {YYYY-MM-DD}
```

### 4. Create Directory if Needed
- Ensure `.virtualboard/architecture/reports/` exists
- Use `mkdir -p` to create if necessary

### 5. Announce Completion
- Inform the user that the architecture report has been created
- Provide the file path
- Highlight key findings, critical issues, and top recommendations
- Summarize overall architecture health rating
