# Generate Technical Debt Report (GTD)

**Trigger Phrases:**
- "Generate Technical Debt Report"
- "GTD"
- "Analyze technical debt"
- "Technical debt analysis"

**Action:**
When the Architect agent receives this command, it should:

## 1. Scan Codebase for Technical Debt
- Identify code smells and anti-patterns
- Review TODO/FIXME/HACK comments in code
- Analyze code complexity metrics (cyclomatic complexity, cognitive complexity)
- Check for outdated dependencies and deprecated APIs
- Identify duplicated code
- Review test coverage gaps
- Check for commented-out code
- Identify overly long functions/classes

### 2. Categorize Technical Debt
- **Code Quality:** Poor naming, complex logic, lack of documentation
- **Architecture:** Tight coupling, lack of abstraction, circular dependencies
- **Testing:** Missing tests, flaky tests, low coverage
- **Dependencies:** Outdated packages, security vulnerabilities
- **Performance:** N+1 queries, inefficient algorithms, memory leaks
- **Security:** Known vulnerabilities, insecure patterns
- **Documentation:** Missing or outdated docs
- **Infrastructure:** Configuration drift, manual processes

### 3. Assess Impact and Priority
For each debt item, evaluate:
- **Business Impact:** How it affects users/product
- **Risk:** Likelihood and severity of failure
- **Effort to Fix:** Time/complexity estimate
- **Trend:** Is it getting worse?
- **Dependencies:** What other work is blocked by this?

### 4. Generate Technical Debt Report
Create report at `.virtualboard/architecture/technical-debt/TD-{YYYY-MM-DD}.md`:

```markdown
# Technical Debt Report
**Generated:** {YYYY-MM-DD}
**Architect:** {Name/Team}
**Project:** {Project Name}

---

## Executive Summary

**Total Debt Items:** {X}
**High Priority:** {X} | **Medium Priority:** {X} | **Low Priority:** {X}

**Estimated Effort to Address All:** {X} developer-weeks

**Debt Trend:** 📈 Increasing | 📊 Stable | 📉 Decreasing

**Critical Findings:**
- {Key finding 1}
- {Key finding 2}
- {Key finding 3}

---

## Debt by Category

| Category       | Count | High | Medium | Low | Estimated Effort |
|----------------|-------|------|--------|-----|------------------|
| Code Quality   | {X}   | {X}  | {X}    | {X} | {X} days         |
| Architecture   | {X}   | {X}  | {X}    | {X} | {X} days         |
| Testing        | {X}   | {X}  | {X}    | {X} | {X} days         |
| Dependencies   | {X}   | {X}  | {X}    | {X} | {X} days         |
| Performance    | {X}   | {X}  | {X}    | {X} | {X} days         |
| Security       | {X}   | {X}  | {X}    | {X} | {X} days         |
| Documentation  | {X}   | {X}  | {X}    | {X} | {X} days         |
| **Total**      | **{X}** | **{X}** | **{X}** | **{X}** | **{X} days** |

---

## High Priority Technical Debt

### TD-001: {Debt Item Title}
**Category:** {Code Quality/Architecture/etc.}
**Severity:** 🔴 Critical | 🟡 High | 🟠 Medium | 🟢 Low

**Location:** `{file_path}:{line_numbers}` or `{module/component}`

**Description:**
{Detailed description of the technical debt issue}

**Business Impact:**
- {How this affects users, performance, or development}
- {Concrete examples of problems caused}

**Technical Details:**
```{language}
// Example of problematic code or pattern
{code snippet}
```

**Recommended Solution:**
1. {Step 1 to fix}
2. {Step 2 to fix}
3. {Step 3 to fix}

**Estimated Effort:** {X} hours/days
**Risk if Not Addressed:** {Description of what could go wrong}
**Dependencies:** {Related debt items or features}
**Owner:** {Team/Person responsible}
**Target Date:** {YYYY-MM-DD}

---

### TD-002: {Another High Priority Item}
{Repeat structure}

---

## Medium Priority Technical Debt

### TD-003: {Debt Item Title}
**Category:** {Category}
**Severity:** 🟠 Medium

**Location:** `{file_path}`
**Description:** {Brief description}
**Impact:** {Impact description}
**Effort:** {Estimate}
**Recommendation:** {Fix suggestion}

---

## Low Priority Technical Debt

### TD-010: {Debt Item Title}
**Category:** {Category}
**Severity:** 🟢 Low

**Location:** `{file_path}`
**Description:** {Brief description}
**Recommendation:** {Fix suggestion}

---

## Code Quality Metrics

### Complexity Analysis
| Metric | Threshold | Current | Status |
|--------|-----------|---------|--------|
| Average Cyclomatic Complexity | < 10 | {X} | ✅/⚠️/❌ |
| Max Cyclomatic Complexity | < 20 | {X} | ✅/⚠️/❌ |
| Cognitive Complexity | < 15 | {X} | ✅/⚠️/❌ |
| Function Length (avg) | < 50 lines | {X} | ✅/⚠️/❌ |

### Code Duplication
- **Total Duplicated Lines:** {X} ({X}% of codebase)
- **Duplicated Blocks:** {X}
- **Largest Duplicate:** {X} lines in `{file_path}`

### Test Coverage
- **Overall Coverage:** {XX}%
- **Unit Test Coverage:** {XX}%
- **Integration Test Coverage:** {XX}%
- **Uncovered Critical Paths:** {X}

---

## Dependency Analysis

### Outdated Dependencies
| Package | Current | Latest | Type | Security Issues |
|---------|---------|--------|------|-----------------|
| {name}  | {ver}   | {ver}  | {prod/dev} | {count} |

### Deprecated APIs in Use
- `{deprecated_api_1}` - Used in {X} places - Replace with: `{alternative}`
- `{deprecated_api_2}` - Used in {X} places - Replace with: `{alternative}`

---

## Architecture Debt

### Architectural Issues
1. {Issue Title}
   - **Problem:** {Description}
   - **Current State:** {How it is now}
   - **Desired State:** {How it should be}
   - **Migration Path:** {Steps to get there}
   - **Effort:** {Estimate}

### Coupling Analysis
- **Highly Coupled Modules:** {List}
- **Circular Dependencies:** {List or "None found"}
- **God Objects/Classes:** {List}

---

## Performance Debt

### Identified Performance Issues
1. {Issue Title}
   - **Location:** `{file_path}`
   - **Problem:** {Description}
   - **Impact:** {Performance impact}
   - **Solution:** {Optimization approach}
   - **Expected Improvement:** {Metric}

### Query Optimization Opportunities
- N+1 queries in `{location}` - Impact: {X}ms average
- Missing indexes on `{table}.{column}`
- Inefficient queries in `{location}`

---

## Security Debt

### Known Vulnerabilities
| Severity | Count | Examples |
|----------|-------|----------|
| Critical | {X}   | {CVE-####} |
| High     | {X}   | {CVE-####} |
| Medium   | {X}   | {List}     |
| Low      | {X}   | {List}     |

### Security Pattern Issues
- Missing input validation in `{location}`
- Insecure authentication in `{location}`
- Unencrypted sensitive data in `{location}`

---

## Documentation Debt

### Missing Documentation
- [ ] API documentation for `{endpoints}`
- [ ] Architecture diagrams for `{components}`
- [ ] Onboarding guide
- [ ] Deployment runbook
- [ ] Code comments in `{complex_modules}`

### Outdated Documentation
- `{doc_name}` - Last updated: {date} (code changed: {date})

---

## Recommended Action Plan

### Sprint 1 (Immediate - 2 weeks)
**Focus:** Critical security and stability issues
- [ ] TD-001: {Item} - Owner: {Name} - Due: {Date}
- [ ] TD-003: {Item} - Owner: {Name} - Due: {Date}

**Expected Impact:** {Description}
**Effort:** {X} developer-days

---

### Sprint 2-3 (Short-term - 4 weeks)
**Focus:** High-impact architectural improvements
- [ ] TD-005: {Item}
- [ ] TD-007: {Item}

**Expected Impact:** {Description}
**Effort:** {X} developer-days

---

### Quarter (Medium-term - 3 months)
**Focus:** Code quality and test coverage
- Major refactoring of `{module}`
- Increase test coverage from {X}% to {X}%
- Upgrade {X} critical dependencies

**Expected Impact:** {Description}
**Effort:** {X} developer-weeks

---

## Cost-Benefit Analysis

### Cost of Addressing Debt
- **Total Estimated Effort:** {X} developer-weeks
- **Estimated Cost:** ${X} (at ${X}/week)

### Cost of Not Addressing Debt
- **Development Slowdown:** {X}% slower feature development
- **Increased Bugs:** {X} bugs/month attributed to debt
- **Maintenance Overhead:** {X} hours/week
- **Risk of Major Failure:** {Description and estimated cost}

**ROI of Addressing Top 10 Items:** {X}% reduction in bug rate, {X}% faster development

---

**Next Review:** {YYYY-MM-DD}
**Last Updated:** {YYYY-MM-DD}
```

### 5. Create Directory if Needed
- Ensure `.virtualboard/architecture/technical-debt/` exists
- Use `mkdir -p` to create if necessary

### 6. Announce Completion
- Inform the user that the technical debt report has been created
- Provide the file path
- Highlight total debt count by priority
- Recommend top 3-5 immediate actions
- Provide summary of estimated effort and ROI

---

## Optional: Generate Branded HTML Report

If the user appends `--html`, says "as HTML"/"branded HTML", or sets
`format: html`, also produce an HTML rendering. **Additive** — the Markdown
report is always written first.

1. Load `templates/reports/html/architect-tech-debt.html`. The comment block at the top of
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
   `EXECUTIVE_SUMMARY_HTML`, `KPI_TOTAL`, `KPI_HIGH`, `KPI_MEDIUM`, `KPI_LOW`, `EFFORT_TOTAL_WEEKS`, `DEBT_TREND`, `DEBT_TREND_CLASS`, `METRICS_HTML`, `DEPENDENCIES_HTML`, `ARCHITECTURE_DEBT_HTML`, `PERFORMANCE_HTML`, `SECURITY_HTML`, `DOCUMENTATION_HTML`, `COST_BENEFIT_HTML`, `NEXT_REVIEW_DATE`.
7. Expand each `{#NAME}…{/NAME}` list block once per item using the
   per-template list placeholders: `HERO_META_CELLS`, `DEBT_BY_CATEGORY`, `HIGH_DEBT`, `MEDIUM_DEBT`, `LOW_DEBT`, `SPRINT_1_ITEMS`, `SPRINT_2_3_ITEMS`, `QUARTER_ITEMS`. The per-item field names are
   documented in the template's top comment.
8. For each list, set the matching `LIST_EMPTY_<NAME>` scalar to `""` if the
   list has items, or to a small italic note (e.g.
   `<p class="empty-note">No items.</p>`) if the list is empty.
9. Write the rendered HTML next to the Markdown:
   `.virtualboard/architecture/technical-debt/TD-{YYYY-MM-DD}.html`.
10. **Verify before reporting completion.** Search the rendered output for any
    literal `{` — there must be none. Resolve leftovers (or substitute the
    empty string for known-optional slots) before continuing.
11. In your final reply, list **both** file paths.

A filled-in reference example lives at
`templates/reports/examples/architect-tech-debt.example.html`.
