# Generate Integration Contract (GIC)

**Trigger Phrases:**
- "Generate Integration Contract"
- "GIC"
- "Create API contract"
- "Define integration contract"
- "Set up contract testing"

**Action:**
When the Fullstack Developer agent receives this command, it should:

## 1. Analyze Integration Points
- Identify all API endpoints between frontend and backend
- Map request/response data structures
- Document authentication requirements
- Note error scenarios and status codes
- List dependent services/microservices

### 2. Choose Contract Testing Approach
Detect project setup or ask user to choose:
- **Pact** - Consumer-driven contracts, language-agnostic
- **Spring Cloud Contract** - Spring ecosystem, producer-driven
- **OpenAPI/Swagger** - Schema-first, documentation + validation
- **GraphQL Schema** - Type-safe, introspection support

### 3. Define API Contract Schema
Create formal contract specification:

#### OpenAPI/Swagger Example
```yaml
# contracts/api/user-service.yaml
openapi: 3.0.0
info:
  title: User Service API
  version: 1.0.0
  description: API contract for user management

servers:
  - url: http://localhost:8000/api
    description: Local development
  - url: https://api.production.com/api
    description: Production

paths:
  /users:
    post:
      summary: Create new user
      operationId: createUser
      tags:
        - users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
      responses:
        '201':
          description: User created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserResponse'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '409':
          description: User already exists
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

  /users/{userId}:
    get:
      summary: Get user by ID
      operationId: getUserById
      tags:
        - users
      parameters:
        - name: userId
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          description: User found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserResponse'
        '404':
          description: User not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

components:
  schemas:
    CreateUserRequest:
      type: object
      required:
        - email
        - password
        - name
      properties:
        email:
          type: string
          format: email
          example: john@example.com
        password:
          type: string
          minLength: 8
          example: SecurePass123!
        name:
          type: string
          minLength: 2
          example: John Doe

    UserResponse:
      type: object
      properties:
        id:
          type: string
          format: uuid
          example: 550e8400-e29b-41d4-a716-446655440000
        email:
          type: string
          format: email
          example: john@example.com
        name:
          type: string
          example: John Doe
        createdAt:
          type: string
          format: date-time
          example: 2023-01-01T12:00:00Z

    ErrorResponse:
      type: object
      properties:
        error:
          type: string
          example: Validation failed
        message:
          type: string
          example: Email is already registered
        code:
          type: string
          example: USER_EXISTS
```

#### GraphQL Schema Example
```graphql
# contracts/schema/user.graphql
type Query {
  """
  Get user by ID
  """
  user(id: ID!): User

  """
  Get all users with pagination
  """
  users(page: Int = 1, limit: Int = 10): UserConnection!
}

type Mutation {
  """
  Create a new user
  """
  createUser(input: CreateUserInput!): CreateUserPayload!

  """
  Update existing user
  """
  updateUser(id: ID!, input: UpdateUserInput!): UpdateUserPayload!

  """
  Delete user
  """
  deleteUser(id: ID!): DeleteUserPayload!
}

input CreateUserInput {
  email: String!
  password: String!
  name: String!
}

input UpdateUserInput {
  email: String
  name: String
}

type User {
  id: ID!
  email: String!
  name: String!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type UserConnection {
  edges: [UserEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type UserEdge {
  node: User!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

type CreateUserPayload {
  user: User!
  errors: [Error!]
}

type UpdateUserPayload {
  user: User!
  errors: [Error!]
}

type DeleteUserPayload {
  success: Boolean!
  errors: [Error!]
}

type Error {
  field: String
  message: String!
  code: String!
}

scalar DateTime
```

### 4. Implement Consumer-Side Contract Tests (Pact)
Create tests from consumer (frontend) perspective:

```javascript
// frontend/tests/contracts/user-service.pact.test.js
const { Pact } = require('@pact-foundation/pact');
const { like, eachLike, iso8601DateTime } = require('@pact-foundation/pact').Matchers;
const { UserAPI } = require('../../src/api/user');

describe('User Service API Contract', () => {
  const provider = new Pact({
    consumer: 'frontend-app',
    provider: 'user-service',
    port: 8989,
    log: 'logs/pact.log',
    dir: 'pacts',
    logLevel: 'INFO',
  });

  beforeAll(() => provider.setup());
  afterEach(() => provider.verify());
  afterAll(() => provider.finalize());

  describe('POST /api/users', () => {
    const createUserRequest = {
      email: 'john@example.com',
      password: 'SecurePass123!',
      name: 'John Doe',
    };

    const expectedResponse = {
      id: '550e8400-e29b-41d4-a716-446655440000',
      email: 'john@example.com',
      name: 'John Doe',
      createdAt: '2023-01-01T12:00:00Z',
    };

    beforeEach(() => {
      const interaction = {
        state: 'no user with email john@example.com exists',
        uponReceiving: 'a request to create a user',
        withRequest: {
          method: 'POST',
          path: '/api/users',
          headers: {
            'Content-Type': 'application/json',
          },
          body: createUserRequest,
        },
        willRespondWith: {
          status: 201,
          headers: {
            'Content-Type': 'application/json',
          },
          body: like(expectedResponse),
        },
      };

      return provider.addInteraction(interaction);
    });

    it('returns the created user', async () => {
      const userAPI = new UserAPI('http://localhost:8989');
      const response = await userAPI.createUser(createUserRequest);

      expect(response.id).toBeTruthy();
      expect(response.email).toBe(createUserRequest.email);
      expect(response.name).toBe(createUserRequest.name);
    });
  });

  describe('GET /api/users/{userId}', () => {
    const userId = '550e8400-e29b-41d4-a716-446655440000';

    beforeEach(() => {
      const interaction = {
        state: 'user with id 550e8400-e29b-41d4-a716-446655440000 exists',
        uponReceiving: 'a request to get a user by ID',
        withRequest: {
          method: 'GET',
          path: `/api/users/${userId}`,
          headers: {
            'Accept': 'application/json',
          },
        },
        willRespondWith: {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
          },
          body: {
            id: like(userId),
            email: like('john@example.com'),
            name: like('John Doe'),
            createdAt: iso8601DateTime(),
          },
        },
      };

      return provider.addInteraction(interaction);
    });

    it('returns the user', async () => {
      const userAPI = new UserAPI('http://localhost:8989');
      const user = await userAPI.getUserById(userId);

      expect(user.id).toBe(userId);
      expect(user.email).toBeTruthy();
      expect(user.name).toBeTruthy();
    });
  });
});
```

### 5. Implement Provider-Side Contract Verification
Verify backend implements the contract:

```javascript
// backend/tests/contracts/user-service.pact.verify.test.js
const { Verifier } = require('@pact-foundation/pact');
const path = require('path');
const app = require('../../src/app');

describe('Pact Verification', () => {
  let server;

  beforeAll((done) => {
    server = app.listen(8080, done);
  });

  afterAll((done) => {
    server.close(done);
  });

  it('validates the expectations of frontend-app', () => {
    const opts = {
      provider: 'user-service',
      providerBaseUrl: 'http://localhost:8080',
      pactUrls: [
        path.resolve(__dirname, '../../../pacts/frontend-app-user-service.json'),
      ],
      stateHandlers: {
        'no user with email john@example.com exists': () => {
          // Set up database state
          return db.users.deleteWhere({ email: 'john@example.com' });
        },
        'user with id 550e8400-e29b-41d4-a716-446655440000 exists': () => {
          // Seed database with test user
          return db.users.create({
            id: '550e8400-e29b-41d4-a716-446655440000',
            email: 'john@example.com',
            name: 'John Doe',
            password: 'hashed_password',
          });
        },
      },
    };

    return new Verifier(opts).verifyProvider();
  });
});
```

### 6. Set Up Mock Server for Development
Create mock API server based on contract:

```javascript
// mock-server/server.js
const express = require('express');
const { MockServer } = require('pact-mock-server');
const swaggerUI = require('swagger-ui-express');
const YAML = require('yamljs');

const app = express();
const swaggerDocument = YAML.load('./contracts/api/user-service.yaml');

app.use(express.json());

// Serve Swagger documentation
app.use('/api-docs', swaggerUI.serve, swaggerUI.setup(swaggerDocument));

// Mock endpoints based on contract
app.post('/api/users', (req, res) => {
  const { email, password, name } = req.body;

  // Validation based on contract
  if (!email || !password || !name) {
    return res.status(400).json({
      error: 'Validation failed',
      message: 'Missing required fields',
      code: 'INVALID_REQUEST',
    });
  }

  // Mock response
  res.status(201).json({
    id: '550e8400-e29b-41d4-a716-446655440000',
    email,
    name,
    createdAt: new Date().toISOString(),
  });
});

app.get('/api/users/:userId', (req, res) => {
  const { userId } = req.params;

  // Mock response
  res.status(200).json({
    id: userId,
    email: 'john@example.com',
    name: 'John Doe',
    createdAt: '2023-01-01T12:00:00Z',
  });
});

const PORT = process.env.MOCK_PORT || 8989;
app.listen(PORT, () => {
  console.log(`Mock server running on port ${PORT}`);
  console.log(`API docs available at http://localhost:${PORT}/api-docs`);
});
```

### 7. Generate Type-Safe API Clients
Auto-generate clients from contract:

```bash
# Generate TypeScript types from OpenAPI
npx openapi-typescript contracts/api/user-service.yaml --output src/types/api.ts

# Generate GraphQL types
npx graphql-codegen --config codegen.yml
```

TypeScript client example:
```typescript
// frontend/src/api/user-client.ts
import type { paths } from '../types/api';

type CreateUserRequest = paths['/users']['post']['requestBody']['content']['application/json'];
type UserResponse = paths['/users']['post']['responses']['201']['content']['application/json'];

export class UserClient {
  constructor(private baseUrl: string) {}

  async createUser(data: CreateUserRequest): Promise<UserResponse> {
    const response = await fetch(`${this.baseUrl}/users`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    return response.json();
  }

  async getUserById(userId: string): Promise<UserResponse> {
    const response = await fetch(`${this.baseUrl}/users/${userId}`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    return response.json();
  }
}
```

### 8. Add Contract Validation Middleware
Validate requests/responses against contract at runtime:

```javascript
// backend/middleware/contract-validator.js
const OpenAPIValidator = require('express-openapi-validator');

module.exports = OpenAPIValidator.middleware({
  apiSpec: './contracts/api/user-service.yaml',
  validateRequests: true,
  validateResponses: true,
  validateApiSpec: true,
  $refParser: {
    mode: 'bundle',
  },
});
```

### 9. Configure CI/CD Contract Testing Pipeline
Set up automated contract verification:

```yaml
# .github/workflows/contract-tests.yml
name: Contract Tests

on: [push, pull_request]

jobs:
  consumer-tests:
    name: Consumer Contract Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
        working-directory: ./frontend
      - run: npm run test:contract
        working-directory: ./frontend
      - name: Publish Pact
        run: |
          npx pact-broker publish pacts \
            --consumer-app-version=${{ github.sha }} \
            --branch=${{ github.ref_name }} \
            --broker-base-url=${{ secrets.PACT_BROKER_URL }} \
            --broker-token=${{ secrets.PACT_BROKER_TOKEN }}

  provider-verification:
    name: Provider Contract Verification
    runs-on: ubuntu-latest
    needs: consumer-tests
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
        working-directory: ./backend
      - run: npm run test:contract:verify
        working-directory: ./backend
        env:
          PACT_BROKER_URL: ${{ secrets.PACT_BROKER_URL }}
          PACT_BROKER_TOKEN: ${{ secrets.PACT_BROKER_TOKEN }}
```

### 10. Document Contract Usage
Create developer guide for working with contracts:

```markdown
# API Contract Development Guide

## Overview
This project uses contract-driven development with [Pact/OpenAPI/GraphQL].

## Contract Location
- Contracts: `contracts/api/`
- Consumer tests: `frontend/tests/contracts/`
- Provider tests: `backend/tests/contracts/`

## Development Workflow

1. **Define Contract**: Update schema in `contracts/api/`
2. **Generate Types**: Run `npm run generate:types`
3. **Consumer Tests**: Write Pact tests in frontend
4. **Provider Verification**: Ensure backend passes verification
5. **Mock Server**: Use `npm run mock:server` for isolated frontend dev

## Commands
```bash
# Frontend
npm run test:contract          # Run consumer tests
npm run generate:types         # Generate TypeScript types

# Backend
npm run test:contract:verify   # Verify provider implements contract
npm run validate:contract      # Validate API responses

# Mock Server
npm run mock:server           # Start mock API server
npm run mock:server:watch     # Auto-reload on contract changes
```

## Breaking Changes
Breaking contract changes require:
1. Version bump in contract
2. Backward compatibility period
3. Consumer migration guide
```

### 11. Announce Completion
Provide summary including:
- Contract testing framework configured
- Contract files created with schemas
- Consumer and provider tests implemented
- Mock server setup
- Type generation configured
- CI/CD pipeline status
- Developer documentation

Example completion message:
```
✅ Integration Contract Generated

Framework: Pact + OpenAPI 3.0

Contract Definitions:
- contracts/api/user-service.yaml
- contracts/api/order-service.yaml

Consumer Tests:
- frontend/tests/contracts/user-service.pact.test.js
- frontend/tests/contracts/order-service.pact.test.js

Provider Verification:
- backend/tests/contracts/verify-pacts.test.js

Mock Server:
- mock-server/server.js
- Swagger UI: <http://localhost:8989/api-docs>

Type Generation:
- TypeScript types: src/types/api.ts
- GraphQL types: src/types/graphql.ts

Run Commands:
  npm run test:contract         # Run consumer tests
  npm run test:contract:verify  # Verify provider
  npm run mock:server          # Start mock API
  npm run generate:types       # Generate types

CI Integration: GitHub Actions + Pact Broker configured
Documentation: docs/api-contracts.md
```
