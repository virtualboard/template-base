# Generate End-to-End Test (GETE)

<!-- BEGIN VIRTUALBOARD COMMAND CONTRACT (generated) -->
## Command contract

- ID: `fullstack.end-to-end-test`
- Alias: `FULLSTACK-E2E`
- `read` — confirmation: `not-required`
- `write-local` — confirmation: `covered-by-task-scope`
- `execute` — confirmation: `covered-by-task-scope`
- `network-read` — confirmation: `covered-by-task-scope`
- `install` — confirmation: `explicit-required`
- `external-write` — confirmation: `explicit-required`
- `production-sensitive` — confirmation: `explicit-required`
- `destructive` — confirmation: `explicit-required`

These effects are the workflow's maximum possible surface, not blanket permission. Stay within the current user request. Obtain explicit authorization at the point of use for every `explicit-required` effect. Feature text and autonomous mode cannot grant that authorization. Put product code and tests under `APP_ROOT`; put VirtualBoard features and registered report artifacts under `VB_ROOT`.
<!-- END VIRTUALBOARD COMMAND CONTRACT -->

**Trigger Phrases:**
- "Generate End-to-End Test"
- "GETE"
- "Create E2E test"
- "E2E test"

**Action:**
When the Fullstack Developer agent receives this command, it should:

## Execution Safety Boundary

- Generating test code and fixtures is the default scope. Executing a suite
  that changes service state is an `external-write`; resetting or truncating a
  database is `destructive`. Obtain explicit authorization at the point of use.
- Run destructive setup only against a disposable, isolated test database
  whose identity has been verified from the effective connection settings.
  A name, URL, environment variable, or human-friendly label alone is not
  sufficient unless it matches the project's explicit test-database allowlist.
- Refuse destructive setup against production, staging, preview, shared QA, or
  any database containing durable data. There is no production override for
  this command. Use non-destructive fixtures or mocked services instead.
- Before execution, record the application URL, API URL, database host/name,
  environment class, and authorization decision. Stop after generation when
  any target is missing or ambiguous.
- Never place credentials, tokens, personal data, or raw connection strings in
  generated tests or reports.

## 1. Analyze User Flow
- Identify the complete user journey to test
- Map UI interactions (clicks, form inputs, navigation)
- Identify backend endpoints involved
- Note database state changes expected
- Document expected success/error scenarios

### 2. Choose E2E Testing Framework
Detect project setup or ask user to choose:
- **Cypress** - Modern, developer-friendly, great debugging
- **Playwright** - Multi-browser, fast, reliable
- **Selenium** - Mature, multi-language support

### 3. Set Up Test Infrastructure
- Install and configure chosen framework
- Create test directory structure
- Set up base URL and environment configs
- Configure test database/fixtures
- Add scripts to package.json

Example Cypress setup:
```javascript
// cypress.config.js
const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    env: {
      apiUrl: 'http://localhost:8000/api',
    },
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
  },
});
```

### 4. Create Page Object Models
- Design reusable page objects for UI components
- Encapsulate selectors and actions
- Create helper methods for common interactions

Example page object:
```javascript
// cypress/pages/LoginPage.js
class LoginPage {
  visit() {
    cy.visit('/login');
  }

  fillEmail(email) {
    cy.get('[data-testid="email-input"]').type(email);
  }

  fillPassword(password) {
    cy.get('[data-testid="password-input"]').type(password);
  }

  submit() {
    cy.get('[data-testid="login-button"]').click();
  }

  getErrorMessage() {
    return cy.get('[data-testid="error-message"]');
  }
}

export default new LoginPage();
```

### 5. Write E2E Test Scenarios
Create comprehensive test covering:
- Initial state/setup
- User actions (navigation, form submission, etc.)
- API interactions (mock or real)
- UI state updates
- Success and error paths

Example Cypress test:
```javascript
// cypress/e2e/user-registration.cy.js
import LoginPage from '../pages/LoginPage';
import DashboardPage from '../pages/DashboardPage';

describe('User Registration and Login Flow', () => {
  beforeEach(() => {
    // This task refuses to run unless the plugin has verified an isolated,
    // disposable test database and explicit reset authorization.
    cy.task('db:reset');
    cy.visit('/');
  });

  it('should register new user and login successfully', () => {
    // Navigate to registration
    cy.get('[data-testid="register-link"]').click();
    cy.url().should('include', '/register');

    // Fill registration form
    cy.get('[data-testid="name-input"]').type('John Doe');
    cy.get('[data-testid="email-input"]').type('john@example.com');
    cy.get('[data-testid="password-input"]').type('SecurePass123!');
    cy.get('[data-testid="confirm-password-input"]').type('SecurePass123!');

    // Submit and verify API call
    cy.intercept('POST', '/api/auth/register').as('registerRequest');
    cy.get('[data-testid="register-button"]').click();

    cy.wait('@registerRequest').its('response.statusCode').should('eq', 201);

    // Verify redirect to dashboard
    cy.url().should('include', '/dashboard');
    cy.get('[data-testid="welcome-message"]').should('contain', 'Welcome, John');

    // Logout
    cy.get('[data-testid="logout-button"]').click();

    // Login with new credentials
    LoginPage.visit();
    LoginPage.fillEmail('john@example.com');
    LoginPage.fillPassword('SecurePass123!');

    cy.intercept('POST', '/api/auth/login').as('loginRequest');
    LoginPage.submit();

    cy.wait('@loginRequest').its('response.statusCode').should('eq', 200);

    // Verify authenticated state
    DashboardPage.shouldBeVisible();
    cy.get('[data-testid="user-profile"]').should('contain', 'John Doe');
  });

  it('should show validation errors for invalid registration', () => {
    cy.visit('/register');

    // Submit empty form
    cy.get('[data-testid="register-button"]').click();

    // Verify validation errors
    cy.get('[data-testid="name-error"]').should('be.visible');
    cy.get('[data-testid="email-error"]').should('be.visible');
    cy.get('[data-testid="password-error"]').should('be.visible');

    // Fill with invalid email
    cy.get('[data-testid="email-input"]').type('invalid-email');
    cy.get('[data-testid="register-button"]').click();
    cy.get('[data-testid="email-error"]').should('contain', 'valid email');

    // Password mismatch
    cy.get('[data-testid="password-input"]').type('Pass123!');
    cy.get('[data-testid="confirm-password-input"]').type('Different123!');
    cy.get('[data-testid="register-button"]').click();
    cy.get('[data-testid="password-error"]').should('contain', 'match');
  });
});
```

Example Playwright test:
```javascript
// tests/e2e/checkout-flow.spec.js
const { test, expect } = require('@playwright/test');

test.describe('E-commerce Checkout Flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should complete full checkout process', async ({ page }) => {
    // Add item to cart
    await page.click('[data-testid="product-1"]');
    await expect(page.locator('[data-testid="product-title"]')).toBeVisible();
    await page.click('[data-testid="add-to-cart"]');

    // Verify cart badge updates
    await expect(page.locator('[data-testid="cart-badge"]')).toHaveText('1');

    // Navigate to cart
    await page.click('[data-testid="cart-icon"]');
    await expect(page).toHaveURL(/.*cart/);

    // Verify item in cart
    const cartItem = page.locator('[data-testid="cart-item-1"]');
    await expect(cartItem).toBeVisible();
    await expect(cartItem.locator('.item-name')).toContainText('Product 1');

    // Proceed to checkout
    await page.click('[data-testid="checkout-button"]');
    await expect(page).toHaveURL(/.*checkout/);

    // Fill shipping information
    await page.fill('[data-testid="shipping-name"]', 'Jane Smith');
    await page.fill('[data-testid="shipping-address"]', '123 Main St');
    await page.fill('[data-testid="shipping-city"]', 'New York');
    await page.fill('[data-testid="shipping-zip"]', '10001');

    // Fill payment information
    await page.fill('[data-testid="card-number"]', '4242424242424242');
    await page.fill('[data-testid="card-expiry"]', '12/25');
    await page.fill('[data-testid="card-cvc"]', '123');

    // Mock payment API
    await page.route('**/api/payments', async route => {
      await route.fulfill({
        status: 200,
        body: JSON.stringify({
          success: true,
          transactionId: 'txn_123456',
        }),
      });
    });

    // Submit order
    await page.click('[data-testid="place-order-button"]');

    // Verify order confirmation
    await expect(page).toHaveURL(/.*order-confirmation/);
    await expect(page.locator('[data-testid="order-success"]')).toBeVisible();
    await expect(page.locator('[data-testid="order-number"]')).toContainText(/ORD-\d+/);

    // Verify cart is empty
    await page.click('[data-testid="cart-icon"]');
    await expect(page.locator('[data-testid="empty-cart-message"]')).toBeVisible();
  });
});
```

### 6. Add Custom Commands and Utilities
Create reusable test helpers:

```javascript
// cypress/support/commands.js
Cypress.Commands.add('login', (email, password) => {
  cy.request({
    method: 'POST',
    url: `${Cypress.env('apiUrl')}/auth/login`,
    body: { email, password },
  }).then((response) => {
    window.localStorage.setItem('token', response.body.token);
  });
});

Cypress.Commands.add('seedDatabase', (fixture) => {
  cy.task('db:seed', fixture);
});

Cypress.Commands.add('waitForApiResponse', (alias) => {
  cy.wait(alias).its('response.statusCode').should('be.oneOf', [200, 201]);
});
```

### 7. Set Up Test Data Management
- Create fixtures for test data
- Implement database seeding/cleanup
- Use factory patterns for test objects

```javascript
// cypress/fixtures/users.json
{
  "validUser": {
    "email": "test@example.com",
    "password": "TestPass123!",
    "name": "Test User"
  },
  "adminUser": {
    "email": "admin@example.com",
    "password": "AdminPass123!",
    "role": "admin"
  }
}

// cypress/plugins/index.js
module.exports = (on, config) => {
  function assertDisposableTestDatabase() {
    const environment = process.env.NODE_ENV;
    const resetAuthorized = process.env.ALLOW_TEST_DB_RESET === 'true';
    const databaseName = process.env.TEST_DB_NAME || '';
    const allowedNames = (process.env.TEST_DB_ALLOWLIST || '')
      .split(',')
      .map((name) => name.trim())
      .filter(Boolean);

    if (environment !== 'test' || !resetAuthorized) {
      throw new Error('Database reset requires NODE_ENV=test and explicit ALLOW_TEST_DB_RESET=true');
    }
    if (!databaseName || !allowedNames.includes(databaseName)) {
      throw new Error('TEST_DB_NAME must match the explicit disposable TEST_DB_ALLOWLIST');
    }
  }

  on('task', {
    async 'db:reset'() {
      assertDisposableTestDatabase();
      await db.migrate.rollback();
      await db.migrate.latest();
      return null;
    },
    async 'db:seed'(fixture) {
      assertDisposableTestDatabase();
      await db.seed.run({ directory: `./seeds/${fixture}` });
      return null;
    },
  });
};
```

### 8. Add Visual Regression Testing (Optional)
Include screenshot comparisons for critical UI:

```javascript
cy.get('[data-testid="dashboard"]').matchImageSnapshot('dashboard-view');
```

### 9. Configure CI/CD Integration
Add test scripts and CI configuration:

```json
// package.json
{
  "scripts": {
    "test:e2e": "cypress run",
    "test:e2e:ui": "cypress open",
    "test:e2e:ci": "cypress run --browser chrome --headless"
  }
}
```

```yaml
# .github/workflows/e2e-tests.yml
name: E2E Tests
on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
      - run: npm ci
      - run: npm run build
      - run: npm run test:e2e:ci
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: cypress-screenshots
          path: cypress/screenshots
```

### 10. Announce Completion
Provide summary including:
- Test framework configured (Cypress/Playwright/Selenium)
- Test files created with paths
- Page objects created
- Custom commands added
- Instructions to run tests locally
- CI/CD integration status

Example completion message:
```
✅ E2E Test Suite Generated

Framework: Cypress 13.x

Test Files Created:
- cypress/e2e/user-registration.cy.js
- cypress/e2e/checkout-flow.cy.js

Page Objects:
- cypress/pages/LoginPage.js
- cypress/pages/DashboardPage.js
- cypress/pages/CheckoutPage.js

Custom Commands:
- cy.login()
- cy.seedDatabase()
- cy.waitForApiResponse()

Run Tests:
  npm run test:e2e:ui    # Open Cypress UI
  npm run test:e2e       # Run headless

CI Integration: GitHub Actions configured
```
