# GBAT Command Example: User Login Feature

This document demonstrates how the GBAT (Generate Browser Automation Tests) command works in practice.

## Scenario

You have a feature FTR-0042 "User Login Feature" that needs browser automation testing.

---

## Step 1 - Trigger the Command

User Input:
```
GBAT for FTR-0042
```

or

```
Generate Browser Automation Tests for the User Login Feature
```

---

## Step 2 - Phase 1 Test Case Generation

### QA Agent Actions
1. Reads feature spec from `$VB_ROOT/features/in-progress/FTR-0042-user-login.md`
2. Analyzes UI components and user flows
3. Generates test cases document

### Output
File Created: `$VB_ROOT/reports/testing/browser/test-cases/TC-FTR-0042-user-login.md`

Content Preview:
```markdown
# Browser Test Cases: User Login Feature

**Feature ID:** FTR-0042
**Created:** 2025-12-12
**Author:** QA Agent
**Status:** Ready for Automation

## Test Cases

### TC-001: Successful Login with Valid Credentials
**Priority:** High
**Category:** Functional

#### Test Steps
1. Navigate to `/login`
2. Enter valid email in username field
3. Enter valid password in password field
4. Click submit button

#### Expected Results
- User is redirected to `/dashboard`
- Success message displayed
- User session is created

#### Selectors
- Username field: `[data-testid="username-input"]`
- Password field: `[data-testid="password-input"]`
- Submit button: `[data-testid="login-submit"]`
- Success message: `[data-testid="success-message"]`

### TC-002: Login Fails with Invalid Credentials
...

### TC-003: Form Validation for Empty Fields
...

### TC-004: Keyboard Navigation Works
...
```

Agent Response:
```
✅ Phase 1 Complete!

Generated 8 test cases:
- TC-001: Successful login with valid credentials (High Priority)
- TC-002: Login fails with invalid credentials (High Priority)
- TC-003: Form validation for empty fields (Medium Priority)
- TC-004: Keyboard navigation works (Medium Priority)
- TC-005: Password visibility toggle (Low Priority)
- TC-006: Remember me checkbox (Medium Priority)
- TC-007: Forgot password link (Medium Priority)
- TC-008: Social login buttons (Low Priority)

📄 Test cases saved to: $VB_ROOT/reports/testing/browser/test-cases/TC-FTR-0042-user-login.md

Would you like to proceed to Phase 2 (Generate Automation Scripts)? (yes/no)
```

---

## Step 3 - Phase 2 Generate Automation Scripts

User Input:
```
yes
```

### QA Agent Prompts
```
Please provide the following configuration:

1. Test output directory (default: ./tests/browser):
   > [user presses Enter for default]

2. Target browsers (options: chromium, firefox, webkit, all | default: chromium):
   > all

3. Base URL for testing (default: http://localhost:3000):
   > http://localhost:3000
```

### QA Agent Actions
1. Checks if Playwright is installed
2. Generates/updates `playwright.config.ts`
3. Creates Page Object Model files
4. Generates test specification files
5. Creates helper utilities

### Output Files Created

#### File 1 - playwright.config.ts
```typescript
import { defineConfig, devices } from '@playwright/test';

const virtualBoardRoot = process.env.VIRTUALBOARD_ROOT;
if (!virtualBoardRoot) throw new Error('VIRTUALBOARD_ROOT is required');
const browserResults = `${virtualBoardRoot}/reports/testing/browser/results`;

export default defineConfig({
  testDir: './tests/browser/specs',
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  reporter: [
    ['html', { outputFolder: `${browserResults}/html` }],
    ['json', { outputFile: `${browserResults}/results.json` }],
  ],
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],
});
```

#### File 2 - tests/browser/fixtures/pages/login-page.ts
```typescript
import { Page, Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly usernameInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;
  readonly successMessage: Locator;
  readonly passwordToggle: Locator;
  readonly rememberMeCheckbox: Locator;
  readonly forgotPasswordLink: Locator;

  constructor(page: Page) {
    this.page = page;
    this.usernameInput = page.locator('[data-testid="username-input"]');
    this.passwordInput = page.locator('[data-testid="password-input"]');
    this.submitButton = page.locator('[data-testid="login-submit"]');
    this.errorMessage = page.locator('[data-testid="error-message"]');
    this.successMessage = page.locator('[data-testid="success-message"]');
    this.passwordToggle = page.locator('[data-testid="password-toggle"]');
    this.rememberMeCheckbox = page.locator('[data-testid="remember-me"]');
    this.forgotPasswordLink = page.locator('[data-testid="forgot-password"]');
  }

  async navigate() {
    await this.page.goto('/login');
  }

  async login(username: string, password: string) {
    await this.usernameInput.fill(username);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  async togglePasswordVisibility() {
    await this.passwordToggle.click();
  }

  async isPasswordVisible(): Promise<boolean> {
    return await this.passwordInput.getAttribute('type') === 'text';
  }
}
```

#### File 3 - tests/browser/specs/login.spec.ts
```typescript
import { test, expect } from '@playwright/test';
import { LoginPage } from '../fixtures/pages/login-page';

test.describe('User Login Feature - FTR-0042', () => {
  let loginPage: LoginPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    await loginPage.navigate();
  });

  test('TC-001: Successful login with valid credentials', async ({ page }) => {
    // Arrange
    const validUsername = 'testuser@example.com';
    const validPassword = 'Test@1234';

    // Act
    await loginPage.login(validUsername, validPassword);

    // Assert
    await expect(page).toHaveURL(/.*dashboard/);
    await expect(loginPage.successMessage).toBeVisible();
    await expect(loginPage.successMessage).toContainText('Login successful');
  });

  test('TC-002: Login fails with invalid credentials', async ({ page }) => {
    // Arrange
    const invalidUsername = 'invalid@example.com';
    const invalidPassword = 'wrongpassword';

    // Act
    await loginPage.login(invalidUsername, invalidPassword);

    // Assert
    await expect(loginPage.errorMessage).toBeVisible();
    await expect(loginPage.errorMessage).toContainText('Invalid credentials');
    await expect(page).toHaveURL(/.*login/);
  });

  test('TC-003: Form validation for empty fields', async ({ page }) => {
    // Act - Submit without filling fields
    await loginPage.submitButton.click();

    // Assert
    await expect(loginPage.usernameInput).toHaveAttribute('aria-invalid', 'true');
    await expect(loginPage.passwordInput).toHaveAttribute('aria-invalid', 'true');
  });

  test('TC-004: Keyboard navigation works correctly', async ({ page }) => {
    // Act - Navigate with Tab key
    await page.keyboard.press('Tab');
    await expect(loginPage.usernameInput).toBeFocused();

    await page.keyboard.press('Tab');
    await expect(loginPage.passwordInput).toBeFocused();

    await page.keyboard.press('Tab');
    await expect(loginPage.submitButton).toBeFocused();

    // Test submission with Enter key
    await loginPage.usernameInput.fill('test@example.com');
    await page.keyboard.press('Tab');
    await loginPage.passwordInput.fill('Test@1234');
    await page.keyboard.press('Enter');

    // Assert
    await expect(page).toHaveURL(/.*dashboard/);
  });

  test('TC-005: Password visibility toggle works', async ({ page }) => {
    // Arrange
    await loginPage.passwordInput.fill('mypassword');

    // Assert initial state
    expect(await loginPage.isPasswordVisible()).toBe(false);

    // Act - Toggle visibility
    await loginPage.togglePasswordVisibility();

    // Assert password is visible
    expect(await loginPage.isPasswordVisible()).toBe(true);

    // Act - Toggle back
    await loginPage.togglePasswordVisibility();

    // Assert password is hidden again
    expect(await loginPage.isPasswordVisible()).toBe(false);
  });

  test('TC-006: Remember me checkbox persists session', async ({ page, context }) => {
    // Arrange
    await loginPage.login('test@example.com', 'Test@1234');
    await loginPage.rememberMeCheckbox.check();
    await loginPage.submitButton.click();

    // Wait for login to complete
    await expect(page).toHaveURL(/.*dashboard/);

    // Act - Close and reopen browser
    await page.close();
    const newPage = await context.newPage();
    await newPage.goto('/');

    // Assert - User should still be logged in
    await expect(newPage).toHaveURL(/.*dashboard/);
  });

  test('TC-007: Forgot password link navigates correctly', async ({ page }) => {
    // Act
    await loginPage.forgotPasswordLink.click();

    // Assert
    await expect(page).toHaveURL(/.*forgot-password/);
  });

  test('TC-008: Social login buttons are visible and clickable', async ({ page }) => {
    // Assert
    const googleButton = page.locator('[data-testid="google-login"]');
    const githubButton = page.locator('[data-testid="github-login"]');

    await expect(googleButton).toBeVisible();
    await expect(githubButton).toBeVisible();

    // Verify buttons are clickable
    await expect(googleButton).toBeEnabled();
    await expect(githubButton).toBeEnabled();
  });
});
```

#### File 4 - tests/browser/helpers/test-utils.ts
```typescript
import { Page } from '@playwright/test';

export async function waitForLoadingSpinner(page: Page) {
  await page.waitForSelector('[data-testid="loading-spinner"]', { state: 'hidden' });
}

export async function clearSessionStorage(page: Page) {
  await page.evaluate(() => sessionStorage.clear());
}

export async function clearLocalStorage(page: Page) {
  await page.evaluate(() => localStorage.clear());
}

export async function mockLoginAPI(page: Page, success: boolean = true) {
  await page.route('**/api/auth/login', route => {
    if (success) {
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          user: { id: 1, email: 'test@example.com' },
          token: 'mock-jwt-token'
        })
      });
    } else {
      route.fulfill({
        status: 401,
        contentType: 'application/json',
        body: JSON.stringify({
          success: false,
          error: 'Invalid credentials'
        })
      });
    }
  });
}
```

Agent Response:
```
✅ Phase 2 Complete!

Generated Playwright automation:
📦 Configuration:
   - playwright.config.ts (browsers: chromium, firefox, webkit)

📄 Page Objects:
   - tests/browser/fixtures/pages/login-page.ts

🧪 Test Specs:
   - tests/browser/specs/login.spec.ts (8 test cases)

🛠️ Utilities:
   - tests/browser/helpers/test-utils.ts

Browsers configured: Chrome, Firefox, Safari
Base URL: http://localhost:3000

Would you like to proceed to Phase 3 (Execute Tests)? (yes/no)
```

---

## Step 4 - Phase 3 Execute Tests

User Input:
```
yes
```

### QA Agent Actions
1. Verifies Playwright browsers are installed
2. Checks that application is running
3. Executes tests across all configured browsers
4. Captures screenshots/videos for failures
5. Generates execution data

Console Output:
```
Installing Playwright browsers if needed...
✓ Browsers installed

Running tests...

Running 24 tests using 3 workers (8 tests × 3 browsers)

  ✓ [chromium] › login.spec.ts:12:3 › TC-001: Successful login... (1.2s)
  ✓ [chromium] › login.spec.ts:26:3 › TC-002: Login fails... (0.8s)
  ✓ [chromium] › login.spec.ts:39:3 › TC-003: Form validation... (0.5s)
  ✓ [chromium] › login.spec.ts:48:3 › TC-004: Keyboard navigation... (1.1s)
  ✓ [chromium] › login.spec.ts:66:3 › TC-005: Password visibility... (0.7s)
  ✓ [chromium] › login.spec.ts:83:3 › TC-006: Remember me... (1.5s)
  ✓ [chromium] › login.spec.ts:98:3 › TC-007: Forgot password... (0.6s)
  ✓ [chromium] › login.spec.ts:105:3 › TC-008: Social login... (0.4s)

  ✓ [firefox] › login.spec.ts:12:3 › TC-001: Successful login... (1.4s)
  ✓ [firefox] › login.spec.ts:26:3 › TC-002: Login fails... (0.9s)
  ✓ [firefox] › login.spec.ts:39:3 › TC-003: Form validation... (0.6s)
  ✓ [firefox] › login.spec.ts:48:3 › TC-004: Keyboard navigation... (1.3s)
  ✓ [firefox] › login.spec.ts:66:3 › TC-005: Password visibility... (0.8s)
  ✓ [firefox] › login.spec.ts:83:3 › TC-006: Remember me... (1.6s)
  ✓ [firefox] › login.spec.ts:98:3 › TC-007: Forgot password... (0.7s)
  ✓ [firefox] › login.spec.ts:105:3 › TC-008: Social login... (0.5s)

  ✓ [webkit] › login.spec.ts:12:3 › TC-001: Successful login... (1.3s)
  ✓ [webkit] › login.spec.ts:26:3 › TC-002: Login fails... (0.8s)
  ✓ [webkit] › login.spec.ts:39:3 › TC-003: Form validation... (0.6s)
  ✓ [webkit] › login.spec.ts:48:3 › TC-004: Keyboard navigation... (1.2s)
  ✗ [webkit] › login.spec.ts:66:3 › TC-005: Password visibility... (1.1s)
  ✓ [webkit] › login.spec.ts:83:3 › TC-006: Remember me... (1.5s)
  ✓ [webkit] › login.spec.ts:98:3 › TC-007: Forgot password... (0.6s)
  ✓ [webkit] › login.spec.ts:105:3 › TC-008: Social login... (0.4s)

  23 passed (18.2s)
  1 failed
```

Agent Response:
```
✅ Phase 3 Complete!

Test Execution Summary:
- Total tests: 24 (8 test cases × 3 browsers)
- Passed: 23 (95.8%)
- Failed: 1 (4.2%)
- Total time: 18.2s

Failed Tests:
❌ TC-005: Password visibility toggle - Safari/WebKit only
   Error: Element [data-testid="password-toggle"] not found
   Screenshot: saved to screenshots/tc-005-webkit-failure.png

Would you like to proceed to Phase 4 (Generate Report)?
Report format: markdown (default) / html / both
>
```

---

## Step 5 - Phase 4 Generate Report

User Input:
```
both
```

### QA Agent Actions
1. Creates report directory structure
2. Generates markdown report
3. Copies HTML report from Playwright
4. Organizes screenshots and videos
5. Updates test case documentation

### Output Files

File Created: `$VB_ROOT/reports/testing/browser/results/report-2025-12-12-14-30.md`

Content Preview:
```markdown
# Browser Test Execution Report

**Execution Date:** 2025-12-12 14:30:15
**Feature:** User Login Feature
**Feature ID:** FTR-0042
**Test Cases File:** `$VB_ROOT/reports/testing/browser/test-cases/TC-FTR-0042-user-login.md`
**Executed By:** QA Agent

---

## Executive Summary

- **Total Tests:** 24
- **Passed:** 23 (95.8%)
- **Failed:** 1 (4.2%)
- **Skipped:** 0
- **Execution Time:** 18.2s
- **Status:** ⚠️ PARTIAL (1 failure in WebKit)

---

## Browser Coverage

| Browser        | Tests Run | Passed | Failed | Status |
|----------------|-----------|--------|--------|--------|
| Chrome         | 8         | 8      | 0      | ✅ PASS |
| Firefox        | 8         | 8      | 0      | ✅ PASS |
| Safari (WebKit)| 8         | 7      | 1      | ❌ FAIL |

---

## Detailed Test Results

### ✅ Passed Tests (23)

#### TC-001: Successful login with valid credentials
- **Browsers:** Chrome (1.2s), Firefox (1.4s), Safari (1.3s)
- **Status:** PASSED
- **Description:** User can login with valid credentials and is redirected to dashboard

[... more passed tests ...]

---

### ❌ Failed Tests (1)

#### TC-005: Password visibility toggle works
- **Browser:** Safari/WebKit only
- **Duration:** 1.1s
- **Status:** FAILED
- **Description:** User should be able to toggle password visibility

**Error Message:**
```
Error: locator.click: Error: Element [data-testid="password-toggle"] not found
    at LoginPage.togglePasswordVisibility (login-page.ts:28:5)
```

**Failure Analysis:**
The password visibility toggle button is not being rendered in Safari. This appears to be a browser-specific issue where the toggle icon is not displayed or the selector is incorrect for WebKit.

**Screenshot:**
![Failure Screenshot](./screenshots/tc-005-webkit-failure.png)

**Suggested Fix:**
1. Check if the password toggle button is rendered in Safari
2. Verify the `data-testid` attribute exists in Safari
3. Consider using a different selector or adding fallback selectors
4. Check CSS for Safari-specific display issues

**Create Bug Report:** BUG-0123 *(create with GBR command)*

---

## Performance Metrics

Average test duration by browser:
- Chrome: 0.86s per test
- Firefox: 0.98s per test
- Safari: 0.88s per test

---

## Recommendations

1. **Fix Safari Password Toggle Issue** - High priority, affects UX
2. **Add Mobile Browser Tests** - Consider adding iOS Safari and Chrome Mobile
3. **Implement Visual Regression Tests** - For better UI consistency checks
4. **Add Performance Metrics** - Track page load times and interaction speeds

---

## Artifacts

- **HTML Report:** [View Report](./html/index.html)
- **Screenshots:** `./screenshots/`
- **Videos:** `./videos/`
- **Test Cases:** `$VB_ROOT/reports/testing/browser/test-cases/TC-FTR-0042-user-login.md`
- **Test Specs:** `./tests/browser/specs/login.spec.ts`

---

**Report Generated By:** QA Agent
**Last Updated:** 2025-12-12 14:30:45
```

Final Agent Response:
```
✅ All Phases Complete!

📊 Test Execution Report Generated:
   - Markdown: $VB_ROOT/reports/testing/browser/results/report-2025-12-12-14-30.md
   - HTML: $VB_ROOT/reports/testing/browser/results/html/index.html

📸 Artifacts:
   - Screenshots: $VB_ROOT/reports/testing/browser/results/screenshots/
   - Videos: $VB_ROOT/reports/testing/browser/results/videos/

🎯 Results Summary:
   - 23/24 tests passed (95.8%)
   - 1 failure in Safari (password toggle)
   - All Chrome and Firefox tests passing

⚠️ Action Required:
   - Review Safari failure for TC-005
   - Consider creating bug report with GBR command
   - Feature FTR-0042 is 95.8% validated

Would you like me to:
1. Create a bug report for the Safari issue (GBR)
2. Update the feature status in features/in-progress/FTR-0042-user-login.md
3. Generate a test coverage report (GTCR)

Type 'GBR' to create bug report, or specify another action.
```

---

## Summary

The GBAT command successfully:

1. ✅ Generated 8 comprehensive test cases
2. ✅ Created Page Object Model for maintainable tests
3. ✅ Generated 8 Playwright test specifications
4. ✅ Executed tests across Chrome, Firefox, and Safari
5. ✅ Identified 1 browser-specific issue
6. ✅ Generated detailed reports in markdown and HTML
7. ✅ Captured screenshots and videos for failures
8. ✅ Provided actionable recommendations

**Total Time:** ~5 minutes from start to complete reports
**Files Created:** 12 files (config, page objects, specs, helpers, test cases, reports)
**Tests Automated:** 24 (8 test cases × 3 browsers)
**Coverage:** 95.8% passing
