# Generate Browser Automation Tests (GBAT)

**Trigger Phrases:**
- "Generate Browser Automation Tests"
- "GBAT"
- "Create Playwright tests"
- "Generate UI automation tests"
- "Create browser test cases"
- "Playwright test automation"

**Action:**
When the QA agent receives this command, it should execute a multi-phase workflow for browser automation testing using Playwright.

---

## Overview

This command performs a comprehensive browser automation testing workflow:
1. **Phase 1:** Generate test cases in markdown format
2. **Phase 2:** Generate Playwright automation scripts
3. **Phase 3:** Execute Playwright tests across specified browsers
4. **Phase 4:** Generate test execution reports

---

## Phase 1: Generate Test Cases

### 1.1 Analyze Feature for UI Testing
- Read the feature spec from `features/` (if feature ID provided)
- Identify all UI components and user interactions
- Map user flows and navigation paths
- Identify form inputs, buttons, links, and interactive elements
- Note accessibility requirements and responsive design needs

### 1.2 Identify Browser Test Scenarios
- **User Interaction Tests:**
  - Form submissions and validations
  - Button clicks and navigation
  - Drag and drop operations
  - File uploads
  - Modal dialogs and popups

- **Visual Tests:**
  - Element visibility and positioning
  - Responsive design across viewports
  - CSS styling verification
  - Image loading and display

- **Functional Tests:**
  - Data persistence and retrieval
  - API integration through UI
  - State management
  - Error handling and messages

- **Cross-Browser Tests:**
  - Browser-specific behavior
  - CSS compatibility
  - JavaScript feature support

### 1.3 Create Test Case Documentation
- Create directory: `.virtualboard/docs/browser-test-cases/` (if not exists)
- Create test case file: `.virtualboard/docs/browser-test-cases/TC-{FTR-####}-{feature-name}.md`
- Use the following structure:

```markdown
# Browser Test Cases: {Feature Name}

**Feature ID:** FTR-#### *(if applicable)*
**Created:** {YYYY-MM-DD}
**Author:** {Agent/Person}
**Status:** Draft | Ready for Automation | Automated | Deprecated

---

## Feature Overview
{Brief description of the feature and its UI components}

## Test Objectives
- {Objective 1}
- {Objective 2}

## Testing Scope
### Pages/Components Under Test
- {Page/Component 1}
- {Page/Component 2}

### Browser Support
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile browsers (if applicable)

### Viewport Sizes
- Desktop: 1920x1080
- Tablet: 768x1024
- Mobile: 375x667

---

## Test Cases

### TC-001: {Test Case Name}
**Priority:** High | Medium | Low
**Category:** User Interaction | Visual | Functional | Performance
**Feature ID:** FTR-#### *(if applicable)*

#### Description
{What this test case validates}

#### Preconditions
- {Condition 1}
- {Condition 2}

#### Test Steps
1. Navigate to `{URL or path}`
2. {Action 1 - e.g., "Click the login button"}
3. {Action 2 - e.g., "Enter 'testuser' in username field"}
4. {Action 3 - e.g., "Enter 'password123' in password field"}
5. {Action 4 - e.g., "Click submit button"}

#### Expected Results
- {Expected outcome 1}
- {Expected outcome 2}
- {Expected outcome 3}

#### Selectors (for automation)
- Username field: `#username` or `[data-testid="username-input"]`
- Password field: `#password` or `[data-testid="password-input"]`
- Submit button: `button[type="submit"]` or `[data-testid="submit-btn"]`
- Success message: `.success-message` or `[data-testid="success-msg"]`

#### Test Data
- Valid username: `testuser@example.com`
- Valid password: `Test@1234`
- Invalid credentials: `invalid@example.com` / `wrong`

#### Accessibility Checks
- [ ] Keyboard navigation works
- [ ] Screen reader announces form fields
- [ ] Focus indicators visible
- [ ] ARIA labels present

#### Cross-Browser Notes
{Any browser-specific behaviors or considerations}

---

### TC-002: {Test Case Name}
{Repeat structure for each test case}

---

## Edge Cases

### EC-001: {Edge Case Name}
**Description:** {What edge case is being tested}
**Steps:** {How to test}
**Expected:** {Expected behavior}

---

## Test Data Requirements
- **User Accounts:**
  - Valid user: `{username/email}`
  - Admin user: `{username/email}`
  - Invalid user: `{username/email}`

- **Test Data:**
  - {Data type 1}: {Description and values}
  - {Data type 2}: {Description and values}

## Dependencies
- {Dependency 1 - e.g., "Backend API must be running"}
- {Dependency 2 - e.g., "Test database must be seeded"}

## Environment Setup
- Base URL: `{URL}`
- Test environment: `{dev/staging/qa}`
- Authentication required: Yes/No

---

**Automation Status:** Not Automated | In Progress | Automated
**Last Updated:** {YYYY-MM-DD}
```

### 1.4 Announce Phase 1 Completion
- Inform user that test cases have been generated
- Provide file path
- Show count of test cases created
- Ask user if they want to proceed to Phase 2 (automation)

---

## Phase 2: Generate Playwright Automation Scripts

### 2.1 Gather Automation Requirements
**Ask the user for:**
- Test output directory (default: `./tests/browser`)
- Target browsers (default: `chromium`)
  - Options: `chromium`, `firefox`, `webkit` (Safari), `all`
- Base URL for testing (e.g., `http://localhost:3000`)
- Any additional Playwright configuration preferences

### 2.2 Verify Playwright Setup
- Check if Playwright is installed in the project
- Check for existing `playwright.config.ts` or `playwright.config.js`
- If not present, ask user if they want to:
  - Generate a Playwright configuration
  - Install Playwright (`npm init playwright@latest`)

### 2.3 Create Test Directory Structure
- Create test output directory (e.g., `./tests/browser/`)
- Create subdirectories if needed:
  - `./tests/browser/fixtures/` (for test data and page objects)
  - `./tests/browser/helpers/` (for utility functions)
  - `./tests/browser/specs/` (for test specifications)

### 2.4 Generate Playwright Configuration
If configuration doesn't exist, create `playwright.config.ts`:

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/browser/specs',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { outputFolder: '.virtualboard/docs/browser-test-reports/html' }],
    ['json', { outputFile: '.virtualboard/docs/browser-test-reports/results.json' }],
    ['list']
  ],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    // Mobile browsers
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],
  webServer: {
    command: 'npm run dev', // Adjust based on project
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

### 2.5 Generate Page Object Models (Optional but Recommended)
Create page objects for better test maintainability in `./tests/browser/fixtures/pages/`:

```typescript
// Example: login-page.ts
import { Page, Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly usernameInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;
  readonly successMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.usernameInput = page.locator('[data-testid="username-input"]');
    this.passwordInput = page.locator('[data-testid="password-input"]');
    this.submitButton = page.locator('[data-testid="submit-btn"]');
    this.errorMessage = page.locator('.error-message');
    this.successMessage = page.locator('.success-message');
  }

  async navigate() {
    await this.page.goto('/login');
  }

  async login(username: string, password: string) {
    await this.usernameInput.fill(username);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  async getErrorMessage() {
    return await this.errorMessage.textContent();
  }

  async isSuccessMessageVisible() {
    return await this.successMessage.isVisible();
  }
}
```

### 2.6 Generate Test Specifications
Read the test case markdown file and generate Playwright test specs in `./tests/browser/specs/`:

```typescript
// Example: login.spec.ts
import { test, expect } from '@playwright/test';
import { LoginPage } from '../fixtures/pages/login-page';

test.describe('Login Feature', () => {
  let loginPage: LoginPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    await loginPage.navigate();
  });

  test('TC-001: User can login with valid credentials', async ({ page }) => {
    // Arrange
    const validUsername = 'testuser@example.com';
    const validPassword = 'Test@1234';

    // Act
    await loginPage.login(validUsername, validPassword);

    // Assert
    await expect(page).toHaveURL(/.*dashboard/);
    await expect(loginPage.successMessage).toBeVisible();
  });

  test('TC-002: User cannot login with invalid credentials', async ({ page }) => {
    // Arrange
    const invalidUsername = 'invalid@example.com';
    const invalidPassword = 'wrong';

    // Act
    await loginPage.login(invalidUsername, invalidPassword);

    // Assert
    await expect(loginPage.errorMessage).toBeVisible();
    await expect(loginPage.errorMessage).toContainText('Invalid credentials');
  });

  test('TC-003: Form validation for empty fields', async ({ page }) => {
    // Act
    await loginPage.submitButton.click();

    // Assert
    await expect(loginPage.usernameInput).toHaveAttribute('aria-invalid', 'true');
    await expect(loginPage.passwordInput).toHaveAttribute('aria-invalid', 'true');
  });

  test('TC-004: Keyboard navigation works correctly', async ({ page }) => {
    // Act
    await page.keyboard.press('Tab');
    await expect(loginPage.usernameInput).toBeFocused();

    await page.keyboard.press('Tab');
    await expect(loginPage.passwordInput).toBeFocused();

    await page.keyboard.press('Tab');
    await expect(loginPage.submitButton).toBeFocused();
  });
});
```

### 2.7 Generate Test Utilities
Create helper functions in `./tests/browser/helpers/`:

```typescript
// Example: test-utils.ts
import { Page } from '@playwright/test';

export async function waitForLoadingSpinner(page: Page) {
  await page.waitForSelector('.loading-spinner', { state: 'hidden' });
}

export async function fillFormField(page: Page, selector: string, value: string) {
  await page.locator(selector).fill(value);
  await page.waitForTimeout(100); // Debounce if needed
}

export async function takeAccessibilitySnapshot(page: Page, name: string) {
  const snapshot = await page.accessibility.snapshot();
  // Save snapshot for analysis
  return snapshot;
}

export async function mockApiResponse(page: Page, url: string, response: any) {
  await page.route(url, route => {
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify(response),
    });
  });
}
```

### 2.8 Announce Phase 2 Completion
- Inform user that Playwright tests have been generated
- Provide paths to generated files
- Show count of test specs created
- List the browsers configured for testing
- Ask user if they want to proceed to Phase 3 (execution)

---

## Phase 3: Execute Playwright Tests

### 3.1 Verify Test Environment
- Check that application is running (if not using webServer in config)
- Verify base URL is accessible
- Check that test database is seeded (if applicable)
- Verify authentication tokens or test accounts exist

### 3.2 Install Playwright Browsers (if needed)
```bash
npx playwright install
```

### 3.3 Execute Tests
Run Playwright tests with specified browsers:

```bash
# Run all tests on all configured browsers
npx playwright test

# Run tests on specific browser
npx playwright test --project=chromium
npx playwright test --project=firefox
npx playwright test --project=webkit

# Run specific test file
npx playwright test login.spec.ts

# Run tests in headed mode (visible browser)
npx playwright test --headed

# Run tests with debugging
npx playwright test --debug

# Run tests and generate HTML report
npx playwright test --reporter=html
```

### 3.4 Monitor Test Execution
- Track test progress
- Capture any failures or errors
- Note execution time per test
- Collect screenshots and videos for failures
- Log any console errors or warnings

### 3.5 Handle Test Failures
If tests fail:
- Capture error messages and stack traces
- Save screenshots of failure states
- Record videos of failed test runs
- Generate trace files for debugging
- Suggest potential fixes based on error analysis

### 3.6 Announce Phase 3 Completion
- Inform user that tests have been executed
- Provide summary of results:
  - Total tests run
  - Tests passed
  - Tests failed
  - Tests skipped
  - Execution time
- Ask user about desired report format for Phase 4

---

## Phase 4: Generate Test Execution Report

### 4.1 Gather Report Requirements
**Ask the user for:**
- Report format: `markdown` (default) or `html`
- Report output directory (default: `.virtualboard/docs/browser-test-reports/`)
- Include screenshots: Yes (default) / No
- Include failure details: Yes (default) / No

### 4.2 Create Report Directory
- Create directory: `.virtualboard/docs/browser-test-reports/` (if not exists)
- Create subdirectories:
  - `screenshots/` (for test screenshots)
  - `videos/` (for test recordings)
  - `traces/` (for Playwright traces)
  - `html/` (for HTML reports)

### 4.3 Generate Markdown Report
Create report file: `.virtualboard/docs/browser-test-reports/report-{YYYY-MM-DD}-{HH-mm}.md`

```markdown
# Browser Test Execution Report

**Execution Date:** {YYYY-MM-DD HH:mm:ss}
**Feature:** {Feature Name}
**Feature ID:** FTR-#### *(if applicable)*
**Test Cases File:** `.virtualboard/docs/browser-test-cases/TC-{FTR-####}-{feature-name}.md`
**Executed By:** {Agent/Person}

---

## Executive Summary

- **Total Tests:** {count}
- **Passed:** {count} ({percentage}%)
- **Failed:** {count} ({percentage}%)
- **Skipped:** {count} ({percentage}%)
- **Execution Time:** {duration}
- **Status:** PASSED | FAILED | PARTIAL

---

## Browser Coverage

| Browser | Tests Run | Passed | Failed | Skipped | Status |
|---------|-----------|--------|--------|---------|--------|
| Chrome  | {count}   | {count}| {count}| {count} | ✅ PASS |
| Firefox | {count}   | {count}| {count}| {count} | ✅ PASS |
| Safari  | {count}   | {count}| {count}| {count} | ❌ FAIL |
| Edge    | {count}   | {count}| {count}| {count} | ✅ PASS |

---

## Test Results by Category

### User Interaction Tests
- **Total:** {count}
- **Passed:** {count}
- **Failed:** {count}

### Visual Tests
- **Total:** {count}
- **Passed:** {count}
- **Failed:** {count}

### Functional Tests
- **Total:** {count}
- **Passed:** {count}
- **Failed:** {count}

---

## Detailed Test Results

### ✅ Passed Tests ({count})

#### TC-001: {Test Case Name}
- **Browser:** Chrome, Firefox, Safari
- **Duration:** {duration}ms
- **Status:** PASSED
- **Description:** {brief description}

#### TC-002: {Test Case Name}
- **Browser:** Chrome, Firefox
- **Duration:** {duration}ms
- **Status:** PASSED
- **Description:** {brief description}

---

### ❌ Failed Tests ({count})

#### TC-003: {Test Case Name}
- **Browser:** Safari
- **Duration:** {duration}ms
- **Status:** FAILED
- **Description:** {brief description}

**Error Message:**
```
{Error message and stack trace}
```

**Failure Analysis:**
{Analysis of why the test failed}

**Screenshot:**
![Failure Screenshot](./screenshots/tc-003-safari-failure.png)

**Video Recording:**
[View Video](./videos/tc-003-safari-failure.webm)

**Suggested Fix:**
{Suggested fix or next steps}

**Related Bug:** BUG-#### *(create bug report if needed)*

---

### ⏭️ Skipped Tests ({count})

#### TC-010: {Test Case Name}
- **Browser:** All
- **Reason:** {Why test was skipped}

---

## Performance Metrics

| Test Case | Browser | Duration | Status |
|-----------|---------|----------|--------|
| TC-001    | Chrome  | 1.2s     | ✅     |
| TC-001    | Firefox | 1.5s     | ✅     |
| TC-002    | Chrome  | 0.8s     | ✅     |

**Average Test Duration:** {duration}
**Total Execution Time:** {duration}

---

## Accessibility Issues Found

### Issue 1: Missing ARIA labels
- **Severity:** Medium
- **Location:** Login form
- **Description:** Username field missing aria-label
- **Recommendation:** Add aria-label="Username" to input field

### Issue 2: Insufficient color contrast
- **Severity:** High
- **Location:** Submit button
- **Description:** Button text contrast ratio is 3.5:1 (should be 4.5:1)
- **Recommendation:** Increase text contrast or adjust background color

---

## Cross-Browser Compatibility Issues

### Issue: CSS Grid layout broken in Safari
- **Browsers Affected:** Safari 15.x
- **Impact:** High
- **Description:** Grid items overlap on Safari
- **Workaround:** Use flexbox fallback for Safari
- **Related Test:** TC-005

---

## Recommendations

1. **Fix critical failures** in Safari browser (TC-003, TC-005)
2. **Address accessibility issues** found during testing
3. **Optimize test performance** for tests taking >2s
4. **Add mobile browser tests** for better coverage
5. **Create regression test suite** for failed tests

---

## Test Environment

- **Base URL:** {URL}
- **Environment:** {dev/staging/qa}
- **Playwright Version:** {version}
- **Node Version:** {version}
- **OS:** {operating system}

---

## Artifacts

- **HTML Report:** [View Report](./html/index.html)
- **Test Screenshots:** `./screenshots/`
- **Test Videos:** `./videos/`
- **Playwright Traces:** `./traces/` *(open with `npx playwright show-trace <file>`)*
- **Test Cases:** `.virtualboard/docs/browser-test-cases/TC-{FTR-####}-{feature-name}.md`
- **Test Specs:** `./tests/browser/specs/`

---

## Sign-off

- [ ] All critical tests passed
- [ ] No blocker issues found
- [ ] Accessibility standards met
- [ ] Cross-browser compatibility verified
- [ ] Performance within acceptable range
- [ ] Ready for next stage (review/production)

---

**Next Steps:**
1. {Next step 1}
2. {Next step 2}
3. {Next step 3}

**Report Generated By:** QA Agent
**Last Updated:** {YYYY-MM-DD HH:mm:ss}
```

### 4.4 Generate HTML Report (if requested)
Playwright automatically generates HTML reports. Open with:
```bash
npx playwright show-report .virtualboard/docs/browser-test-reports/html
```

### 4.5 Create Bug Reports for Failures
For each failed test, ask user if they want to:
- Create a bug report (using GBR command)
- Link the bug to the feature
- Assign the bug to a developer

### 4.6 Update Test Case Status
Update the test case markdown file with automation status:
- Mark tests as "Automated"
- Add links to automation scripts
- Add links to execution reports
- Update last execution date

### 4.7 Announce Phase 4 Completion
- Inform user that report has been generated
- Provide report file path
- Summarize key findings:
  - Overall pass/fail status
  - Critical issues found
  - Accessibility concerns
  - Cross-browser compatibility issues
- Suggest next steps

---

## Complete Workflow Example

### User triggers command
```
"GBAT - Generate browser automation tests for FTR-0042 (User Login Feature)"
```

### QA Agent Response

Phase 1 - Generating Test Cases
- Reading feature FTR-0042...
- Identified 8 UI test scenarios
- Created test cases: `.virtualboard/docs/browser-test-cases/TC-FTR-0042-user-login.md`
- ✅ Phase 1 complete. Proceed to Phase 2? (yes/no)

Phase 2 - Generating Playwright Automation
- Test directory: `./tests/browser/` (default) or specify custom path?
- Target browsers: chromium, firefox, webkit (all) or specify?
- Base URL: `http://localhost:3000` or specify?

User provides inputs or accepts defaults...

- ✅ Playwright config created: `playwright.config.ts`
- ✅ Page objects created: `./tests/browser/fixtures/pages/login-page.ts`
- ✅ Test specs created: `./tests/browser/specs/login.spec.ts`
- ✅ Utilities created: `./tests/browser/helpers/test-utils.ts`
- ✅ Phase 2 complete. Proceed to Phase 3? (yes/no)

Phase 3 - Executing Tests
- Installing Playwright browsers...
- Running tests on: chromium, firefox, webkit
- Executing 8 test cases...
- ✅ 7 tests passed
- ❌ 1 test failed (Safari only)
- ⏱️ Total time: 12.5s
- ✅ Phase 3 complete. Generate report? (markdown/html/both)

Phase 4 - Generating Report
- Report format: markdown (default) or html?
- Include screenshots: yes (default)

User confirms...

- ✅ Report generated: `.virtualboard/docs/browser-test-reports/report-2025-12-12-14-30.md`
- ✅ HTML report: `.virtualboard/docs/browser-test-reports/html/index.html`
- ✅ Screenshots saved: `./screenshots/`
- ✅ Videos saved: `./videos/`

Summary:
- 8 test cases created and automated
- 7/8 tests passing (87.5%)
- 1 failure in Safari (CSS Grid issue)
- Create bug report for Safari issue? (yes/no)

---

## Directory Structure Created

After running GBAT, the following structure will exist:

```
.virtualboard/
└── docs/
    ├── browser-test-cases/
    │   └── TC-FTR-####-feature-name.md
    └── browser-test-reports/
        ├── report-YYYY-MM-DD-HH-mm.md
        ├── screenshots/
        │   └── tc-###-browser-failure.png
        ├── videos/
        │   └── tc-###-browser-failure.webm
        ├── traces/
        │   └── tc-###-browser-trace.zip
        └── html/
            └── index.html

tests/
└── browser/
    ├── fixtures/
    │   └── pages/
    │       └── {page-name}-page.ts
    ├── helpers/
    │   └── test-utils.ts
    └── specs/
        └── {feature-name}.spec.ts

playwright.config.ts
```

---

## Command Options and Flags

Users can provide additional options when invoking GBAT:

```
# Full automation flow
"GBAT for FTR-0042"

# Just generate test cases (Phase 1 only)
"GBAT --test-cases-only for FTR-0042"

# Generate test cases and automation (Phases 1-2)
"GBAT --no-execute for FTR-0042"

# Execute existing tests only (Phase 3-4)
"GBAT --execute-only for login tests"

# Specify browsers
"GBAT for FTR-0042 --browsers=chromium,firefox"

# Specify output directory
"GBAT for FTR-0042 --test-dir=./e2e/tests"

# Specify report format
"GBAT for FTR-0042 --report=html"

# Run in CI mode
"GBAT for FTR-0042 --ci"
```

---

## Integration with Other QA Commands

- **GTP (Generate Test Plan):** GBAT can reference test plans to generate browser tests
- **GBR (Generate Bug Report):** Failed GBAT tests can automatically create bug reports
- **GTCR (Generate Test Coverage Report):** GBAT results feed into coverage analysis

---

## Best Practices

1. **Use data-testid attributes** in application code for stable selectors
2. **Implement Page Object Model** for maintainable tests
3. **Run tests in CI/CD pipeline** for continuous validation
4. **Keep test data isolated** to prevent test interference
5. **Use visual regression testing** for UI consistency
6. **Test accessibility** in every browser test
7. **Monitor test flakiness** and fix unstable tests
8. **Version control test cases** alongside code
9. **Review test coverage** regularly and add missing scenarios
10. **Document browser-specific workarounds** in test code

---

## Troubleshooting

### Playwright not installed
```bash
npm init playwright@latest
# or
yarn create playwright
```

### Tests timing out
- Increase timeout in playwright.config.ts
- Check if application is running
- Verify selectors are correct

### Browser not launching
```bash
npx playwright install
npx playwright install-deps
```

### Flaky tests
- Add explicit waits for dynamic content
- Use Playwright's auto-waiting features
- Check for race conditions in application code

### Screenshot comparison failures
- Update baseline images if design changed
- Check for animation or timing issues
- Use threshold tolerance for minor differences

---

**Last Updated:** 2025-12-12
**Command Version:** 1.0.0
