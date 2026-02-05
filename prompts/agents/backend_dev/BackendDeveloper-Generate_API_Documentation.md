# Generate API Documentation (GAD)

**Note:** This is Backend Developer's GAD (Generate API Documentation). For Architecture Decision Records, see Architect's Architect-Generate_Architecture_Decision command.

**Trigger Phrases:**
- "Generate API Documentation"
- "GAD"
- "Document API"
- "Create API docs"

**Action:**
When the Backend Developer agent receives this command, it should:

## 1. Scan API Endpoints
- Identify all API routes/endpoints in the codebase
- Extract HTTP methods (GET, POST, PUT, PATCH, DELETE)
- Identify route parameters, query parameters, and request bodies
- Determine response formats and status codes
- Review authentication/authorization requirements
- Identify rate limits or special headers

### 2. Analyze Endpoint Details
For each endpoint, document:
- **Path:** The URL path
- **Method:** HTTP verb
- **Description:** What the endpoint does
- **Request Schema:** Parameters, body structure, headers
- **Response Schema:** Success and error responses
- **Authentication:** Required auth method
- **Examples:** Sample requests and responses

### 3. Generate OpenAPI/Swagger Specification
Create specification at `docs/api/openapi.yaml` or `docs/api/swagger.json`:

```yaml
openapi: 3.0.0
info:
  title: {Project Name} API
  description: {API description}
  version: {version}
  contact:
    name: {Team/Contact}
    email: {email}
  license:
    name: {License}

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: https://staging-api.example.com/v1
    description: Staging
  - url: http://localhost:3000/v1
    description: Local development

tags:
  - name: {Resource}
    description: {Resource operations}

paths:
  /api/users:
    get:
      summary: List all users
      description: Retrieve a paginated list of users
      tags:
        - Users
      parameters:
        - name: page
          in: query
          description: Page number for pagination
          required: false
          schema:
            type: integer
            default: 1
        - name: limit
          in: query
          description: Number of items per page
          required: false
          schema:
            type: integer
            default: 20
            maximum: 100
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
                  pagination:
                    $ref: '#/components/schemas/Pagination'
              example:
                data:
                  - id: 1
                    name: John Doe
                    email: john@example.com
                pagination:
                  page: 1
                  limit: 20
                  total: 100
        '401':
          $ref: '#/components/responses/Unauthorized'
        '500':
          $ref: '#/components/responses/InternalError'
      security:
        - bearerAuth: []

    post:
      summary: Create a new user
      description: Create a new user account
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
            example:
              name: Jane Smith
              email: jane@example.com
              password: securePassword123
      responses:
        '201':
          description: User created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          $ref: '#/components/responses/BadRequest'
        '409':
          description: User already exists
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
      security:
        - bearerAuth: []

  /api/users/{id}:
    get:
      summary: Get user by ID
      description: Retrieve a specific user by their ID
      tags:
        - Users
      parameters:
        - name: id
          in: path
          required: true
          description: User ID
          schema:
            type: integer
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '404':
          $ref: '#/components/responses/NotFound'
      security:
        - bearerAuth: []

components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: integer
          example: 1
        name:
          type: string
          example: John Doe
        email:
          type: string
          format: email
          example: john@example.com
        created_at:
          type: string
          format: date-time
          example: 2025-01-01T00:00:00Z
        updated_at:
          type: string
          format: date-time
          example: 2025-01-01T00:00:00Z
      required:
        - id
        - name
        - email

    CreateUserRequest:
      type: object
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 100
        email:
          type: string
          format: email
        password:
          type: string
          minLength: 8
      required:
        - name
        - email
        - password

    Pagination:
      type: object
      properties:
        page:
          type: integer
        limit:
          type: integer
        total:
          type: integer
        total_pages:
          type: integer

    Error:
      type: object
      properties:
        error:
          type: string
        message:
          type: string
        code:
          type: string

  responses:
    BadRequest:
      description: Bad request - invalid input
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: Bad Request
            message: Invalid input data
            code: BAD_REQUEST

    Unauthorized:
      description: Unauthorized - authentication required
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: Unauthorized
            message: Authentication required
            code: UNAUTHORIZED

    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: Not Found
            message: Resource not found
            code: NOT_FOUND

    InternalError:
      description: Internal server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT token authentication

security:
  - bearerAuth: []
```

### 4. Create API Documentation Files

**Main Documentation File:** `docs/api/README.md`

```markdown
# API Documentation

**Base URL:** `https://api.example.com/v1`

**Authentication:** Bearer Token (JWT)

---

## Overview

{Brief description of the API}

## Authentication

All API requests require authentication using a JWT token in the Authorization header:

```
Authorization: Bearer YOUR_JWT_TOKEN
```

To obtain a token, use the `/auth/login` endpoint.

---

## Endpoints

### Users

#### List Users
```http
GET /api/users?page=1&limit=20
```

**Description:** Retrieve a paginated list of users

**Query Parameters:**
- `page` (integer, optional): Page number (default: 1)
- `limit` (integer, optional): Items per page (default: 20, max: 100)

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2025-01-01T00:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

---

#### Create User
```http
POST /api/users
```

**Request Body:**
```json
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "password": "securePassword123"
}
```

**Response (201 Created):**
```json
{
  "id": 2,
  "name": "Jane Smith",
  "email": "jane@example.com",
  "created_at": "2025-01-01T00:00:00Z"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid input
- `409 Conflict` - User already exists

---

## Error Handling

All errors follow this format:

```json
{
  "error": "Error Type",
  "message": "Human-readable error message",
  "code": "ERROR_CODE"
}
```

### Common Error Codes
- `BAD_REQUEST` - Invalid input data
- `UNAUTHORIZED` - Missing or invalid authentication
- `FORBIDDEN` - Insufficient permissions
- `NOT_FOUND` - Resource not found
- `CONFLICT` - Resource conflict (e.g., duplicate)
- `INTERNAL_ERROR` - Server error

---

## Rate Limiting

- **Rate Limit:** 100 requests per minute
- **Headers:**
  - `X-RateLimit-Limit`: Maximum requests allowed
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Time when limit resets (Unix timestamp)

---

## Pagination

List endpoints support pagination with these parameters:
- `page`: Page number (1-indexed)
- `limit`: Items per page

Response includes a `pagination` object with total count and pages.

---

## Versioning

API version is included in the URL path: `/v1/...`

When breaking changes are introduced, a new version will be created (e.g., `/v2/...`)

---

## SDKs & Tools

- **Swagger UI:** {URL}
- **Postman Collection:** {Link}
- **Client Libraries:** {Links}

---

**Last Updated:** {YYYY-MM-DD}
```

### 5. Set Up Swagger UI (Optional)
If the project uses Swagger UI, configure it:

```javascript
// swagger.config.js
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: '{Project Name} API',
      version: '{version}',
    },
  },
  apis: ['./routes/*.js'], // Path to API routes
};

const specs = swaggerJsdoc(options);

module.exports = { specs, swaggerUi };
```

### 6. Create Postman Collection
Generate a Postman collection file at `docs/api/postman_collection.json`:

```json
{
  "info": {
    "name": "{Project Name} API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Users",
      "item": [
        {
          "name": "List Users",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              }
            ],
            "url": {
              "raw": "{{baseUrl}}/api/users?page=1&limit=20",
              "host": ["{{baseUrl}}"],
              "path": ["api", "users"],
              "query": [
                {"key": "page", "value": "1"},
                {"key": "limit", "value": "20"}
              ]
            }
          }
        }
      ]
    }
  ],
  "variable": [
    {
      "key": "baseUrl",
      "value": "http://localhost:3000/v1"
    },
    {
      "key": "token",
      "value": ""
    }
  ]
}
```

### 7. Announce Completion
- Inform the user that API documentation has been generated
- Provide file paths:
  - OpenAPI/Swagger spec: `docs/api/openapi.yaml`
  - README: `docs/api/README.md`
  - Postman collection: `docs/api/postman_collection.json`
- List total endpoints documented
- Provide instructions for viewing (e.g., Swagger UI URL)
- Suggest next steps (e.g., hosting docs, generating client SDKs)
