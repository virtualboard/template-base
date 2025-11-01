# Generate Test Coverage Report (GTCR)

**Trigger Phrases:**
- "Generate Test Coverage Report"
- "GTCR"
- "Create test coverage report"
- "Test coverage analysis"

**Action:**
When the QA agent receives this command, it should:

## 1. Analyze Existing Tests
- Scan the codebase for test files (unit, integration, E2E)
- Identify testing frameworks in use (Jest, Mocha, Pytest, etc.)
- Check for coverage reports (coverage/lcov.info, etc.)
- Review test execution results

### 2. Run Coverage Analysis
- Execute test coverage tools if available:
  - JavaScript/TypeScript: `npm test -- --coverage` or `jest --coverage`
  - Python: `pytest --cov` or `coverage run`
  - Java: JaCoCo reports
  - Go: `go test -cover`
- Parse coverage data (line, branch, function, statement coverage)
- Identify untested or under-tested modules

### 3. Categorize Test Coverage
- **Unit Tests:** Test individual functions/methods in isolation
- **Integration Tests:** Test component interactions
- **End-to-End Tests:** Test complete user flows
- **Performance Tests:** Test system performance/load
- **Security Tests:** Test for vulnerabilities

### 4. Create Coverage Report
- Create coverage report at `.virtualboard/testing/coverage/TCR-{YYYY-MM-DD}-{feature-or-module}.md`
- Use the following structure:

```markdown
# Test Coverage Report: {Feature/Module/Full Codebase}

**Report ID:** TCR-{YYYY-MM-DD}
**Created:** {YYYY-MM-DD}
**Analyst:** {Agent/Person}
**Period Covered:** {Date range or Sprint #}
**Scope:** {Full codebase / Specific feature / Module}

---

## Executive Summary

**Overall Coverage:** {X}%
- **Line Coverage:** {X}%
- **Branch Coverage:** {X}%
- **Function Coverage:** {X}%
- **Statement Coverage:** {X}%

**Coverage Trend:** ⬆️ Increasing | ⬇️ Decreasing | ➡️ Stable

**Status:** 🟢 Healthy (>80%) | 🟡 Needs Improvement (60-80%) | 🔴 Critical (<60%)

---

## Coverage by Test Type

### Unit Tests
- **Coverage:** {X}%
- **Total Tests:** {###}
- **Passing:** {###}
- **Failing:** {###}
- **Status:** {Assessment}

### Integration Tests
- **Coverage:** {X}%
- **Total Tests:** {###}
- **Passing:** {###}
- **Failing:** {###}
- **Status:** {Assessment}

### End-to-End Tests
- **Coverage:** {X}%
- **Total Tests:** {###}
- **Passing:** {###}
- **Failing:** {###}
- **Status:** {Assessment}

### Other Test Types
- **Performance Tests:** {X}% coverage, {###} tests
- **Security Tests:** {X}% coverage, {###} tests
- **Accessibility Tests:** {X}% coverage, {###} tests

---

## Coverage by Module/Component

### Module: {Module Name}
- **Path:** `{src/path/to/module}`
- **Overall Coverage:** {X}%
- **Line Coverage:** {X}%
- **Branch Coverage:** {X}%
- **Status:** 🟢 | 🟡 | 🔴

**Files:**
| File | Lines | Branches | Functions | Coverage |
|------|-------|----------|-----------|----------|
| `{filename.js}` | {X}% | {X}% | {X}% | {X}% |
| `{filename2.js}` | {X}% | {X}% | {X}% | {X}% |

**Uncovered Critical Paths:**
- {Critical function/path 1}
- {Critical function/path 2}

---

### Module: {Module Name 2}
{Repeat structure}

---

## Critical Gaps Identified

### 1. {Gap Title}
**Severity:** Critical | High | Medium | Low
**Module/Component:** {Name}
**Description:** {What's not covered}
**Impact:** {Risk if not tested}
**Recommendation:** {Suggested tests to add}

### 2. {Gap Title}
{Repeat structure}

---

## Files with Low/No Coverage

### Zero Coverage (0%)
| File Path | Lines | Reason |
|-----------|-------|--------|
| `{path/to/file}` | {###} | {e.g., Not tested, legacy code} |

### Low Coverage (<50%)
| File Path | Lines | Coverage | Priority |
|-----------|-------|----------|----------|
| `{path/to/file}` | {###} | {X}% | High/Med/Low |

---

## Test Quality Metrics

### Test Code Ratio
- **Production Code:** {###} lines
- **Test Code:** {###} lines
- **Ratio:** {1:X} (Target: 1:1 to 1:2)

### Test Maintainability
- **Flaky Tests:** {###} ({X}% of total)
- **Skipped Tests:** {###} ({X}% of total)
- **Slow Tests (>5s):** {###} ({X}% of total)

### Code Complexity vs Coverage
| High Complexity Files | Cyclomatic Complexity | Coverage | Risk |
|----------------------|----------------------|----------|------|
| `{filename}` | {##} | {X}% | 🔴 High |

---

## Coverage Trends

### Historical Comparison
| Date | Overall Coverage | Change |
|------|-----------------|--------|
| {YYYY-MM-DD} | {X}% | - |
| {YYYY-MM-DD} | {X}% | +{X}% |
| {YYYY-MM-DD} | {X}% | -{X}% |

### Coverage by Sprint/Release
| Sprint/Release | Coverage | Tests Added | Tests Removed |
|----------------|----------|-------------|---------------|
| {Sprint #} | {X}% | {##} | {##} |

---

## Recommendations

### Immediate Actions (High Priority)
1. **Add tests for:** {Critical uncovered code}
2. **Fix flaky tests:** {List of unstable tests}
3. **Remove/Update skipped tests:** {List of skipped tests}

### Short-term Improvements (1-2 Sprints)
1. **Increase coverage in:** {Module/component name}
2. **Add integration tests for:** {Feature/workflow}
3. **Implement:** {Test type needed}

### Long-term Strategy
1. **Coverage goals:** Achieve {X}% overall coverage by {date}
2. **Testing standards:** Establish minimum {X}% coverage for new code
3. **CI/CD integration:** Fail builds below {X}% coverage threshold

---

## Testing Infrastructure

### Tools & Frameworks
- **Test Runner:** {Jest, Mocha, Pytest, etc.}
- **Coverage Tool:** {Istanbul, Coverage.py, etc.}
- **E2E Framework:** {Cypress, Playwright, Selenium, etc.}
- **Mocking:** {Jest mocks, Sinon, unittest.mock, etc.}

### CI/CD Integration
- [ ] Tests run on every commit
- [ ] Coverage reports generated automatically
- [ ] Coverage thresholds enforced
- [ ] Failed tests block merges

---

## Exclusions & Notes

### Excluded from Coverage
- {Path/files excluded and why}
- {Generated code, third-party libs, etc.}

### Known Limitations
- {Any limitations in the analysis}
- {Areas that can't be easily tested}

---

## Appendix

### Coverage Report Files
- **Full HTML Report:** `{path/to/coverage/index.html}`
- **LCOV Report:** `{path/to/lcov.info}`
- **JSON Report:** `{path/to/coverage.json}`

### Commands to Reproduce
```bash
{Commands to run tests and generate coverage}
```

---

**Last Updated:** {YYYY-MM-DD}
**Next Review:** {YYYY-MM-DD}
```

### 5. Create Directory if Needed
- Ensure `.virtualboard/testing/coverage/` exists
- Use `mkdir -p` to create if necessary

### 6. Calculate Coverage Metrics
- **Overall Coverage:** Weighted average of line/branch/function coverage
- **By Module:** Aggregate coverage for each major component
- **Trend Analysis:** Compare with previous reports if available

### 7. Identify Priority Gaps
- **Critical Gaps:** Untested critical paths, security-sensitive code, complex business logic
- **High Priority:** Public APIs, data transformations, error handling
- **Medium Priority:** Utility functions, helpers, common workflows
- **Low Priority:** Simple getters/setters, configuration code

### 8. Provide Actionable Recommendations
- Specific files/functions that need tests
- Suggested test types (unit, integration, E2E)
- Priority order for addressing gaps
- Coverage improvement targets

### 9. Announce Completion
- Inform the user that the coverage report has been created
- Provide the file path
- Highlight overall coverage percentage and trend
- Summarize critical gaps and top recommendations
- Suggest next steps for improving coverage
