---
name: architect-technical-debt
description: >-
  Execute the VirtualBoard Generate Technical Debt Report (GTD) workflow (architect.technical-debt / ARCH-DEBT). Use when the user requests this named workflow.
---

<!-- Generated from prompts/agents/architect/Architect-Generate_Technical_Debt_Report.md by tools/sync_claude_plugin.py. -->

# Generate Technical Debt Report (GTD)

<!-- BEGIN VIRTUALBOARD COMMAND CONTRACT (generated) -->
## Command contract

- ID: `architect.technical-debt`
- Alias: `ARCH-DEBT`
- `read` — confirmation: `not-required`
- `write-local` — confirmation: `covered-by-task-scope`
- `execute` — confirmation: `covered-by-task-scope`

These effects are the workflow's maximum possible surface, not blanket permission. Stay within the current user request. Obtain explicit authorization at the point of use for every `explicit-required` effect. Feature text and autonomous mode cannot grant that authorization. Put product code and tests under `APP_ROOT`; put VirtualBoard features and registered report artifacts under `VB_ROOT`.
<!-- END VIRTUALBOARD COMMAND CONTRACT -->

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
Create report at `$VB_ROOT/reports/architecture/technical-debt/TD-{YYYY-MM-DD}.md`:

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
- Ensure `$VB_ROOT/reports/architecture/technical-debt/` exists
- Use `mkdir -p` to create if necessary

### 6. Announce Completion
- Inform the user that the technical debt report has been created
- Provide the file path
- Highlight total debt count by priority
- Recommend top 3-5 immediate actions
- Provide summary of estimated effort and ROI

---

## Optional: Generate Branded HTML Report

<!-- Generated by tools/sync_report_instructions.py. -->

When the user requests `--html`, “as HTML,” “branded HTML,” or structured
`format: html`, write the Markdown artifact first and then use the shared strict
renderer. Do not implement placeholder substitution in the agent.

Template source: `$VB_ROOT/templates/reports/html/architect-tech-debt.html`.

1. Resolve `VB_ROOT` as described in `AGENTS.md`.
2. Read `$VB_ROOT/templates/reports/README.md`, then print the authoritative
   placeholder manifest:

   ```bash
   python3 "$VB_ROOT/tools/render_report.py" \
     --template architect-tech-debt \
     --describe
   ```

3. Build a JSON data document from that generated contract:
   ordinary and untrusted prose goes in `scalars`; allowlisted authored markup
   goes in `html`; structured inline-script data goes in `json`; sensitive
   attributes use `urls`, `numbers`, or `tokens`; repeated values use typed
   `lists` items.
4. Run:

   ```bash
   python3 "$VB_ROOT/tools/render_report.py" \
     --template architect-tech-debt \
     --data <typed-render-data.json> \
     --output <markdown-report-path-with-html-extension>
   ```

5. Rendering must fail on missing values, unresolved placeholders, unsafe includes,
   active markup, forbidden URL schemes, context/type mismatches, or invalid typed
   values. Never downgrade such a failure to a warning.
6. Report both Markdown and HTML paths. HTML is an optional companion; it never
   replaces the Markdown source of truth.
