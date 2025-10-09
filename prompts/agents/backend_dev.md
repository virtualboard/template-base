# Backend Developer Commands

This file defines specialized commands and actions for the Backend Developer agent role.

## ⚠️ IMPORTANT: Command Display Requirement

**When you adopt the Backend Developer agent role and load this command file, you MUST immediately display a summary of available commands to the user.**

**Format:**
```
📋 Available Backend Developer Commands:
• GAE (Generate API Endpoint) - Scaffold REST/GraphQL endpoint with validation
• GDM (Generate Database Migration) - Create database migration file
• GAD (Generate API Documentation) - Auto-generate OpenAPI/Swagger docs
```

This ensures users know what commands are available to them.

---

## Generate API Endpoint (GAE)

**Trigger Phrases:**
- "Generate API Endpoint"
- "GAE"
- "Create API endpoint"
- "Create endpoint"
- "New API route"

**Action:**
When the Backend Developer agent receives this command, it should:

### 1. Gather Requirements
- HTTP method (GET, POST, PUT, DELETE, PATCH)
- Route path (e.g., `/api/users/:id`)
- Request/response schema
- Authentication/authorization requirements
- Validation rules

### 2. Create Endpoint Files

**Example Structure (Node.js/Express):**
```
src/api/
├── routes/{resource}.routes.ts
├── controllers/{resource}.controller.ts
├── services/{resource}.service.ts
├── validators/{resource}.validator.ts
└── tests/{resource}.test.ts
```

**Controller Template:**
```typescript
import { Request, Response } from 'express';
import { {Resource}Service } from '../services/{resource}.service';

export class {Resource}Controller {
  async create(req: Request, res: Response) {
    try {
      const data = req.body;
      const result = await {Resource}Service.create(data);
      res.status(201).json(result);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}
```

**Validation Template:**
```typescript
import { body, param, validationResult } from 'express-validator';

export const {resource}Validators = {
  create: [
    body('field1').notEmpty().withMessage('Field1 is required'),
    body('field2').isEmail().withMessage('Invalid email'),
  ],

  update: [
    param('id').isUUID().withMessage('Invalid ID'),
    body('field1').optional().notEmpty(),
  ]
};
```

### 3. Add Tests
```typescript
import request from 'supertest';
import app from '../app';

describe('{Resource} API', () => {
  describe('POST /api/{resource}', () => {
    it('should create a new {resource}', async () => {
      const response = await request(app)
        .post('/api/{resource}')
        .send({ /* test data */ });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
    });
  });
});
```

### 4. Update API Documentation
- Add endpoint to OpenAPI/Swagger spec
- Document request/response schemas
- Include example requests

### 5. Announce Completion
- Show file paths created
- Provide curl example
- List validation rules

---

## Generate Database Migration (GDM)

**Trigger Phrases:**
- "Generate Database Migration"
- "GDM"
- "Create migration"
- "Database migration"

**Action:**
[To be defined - coming soon]

---

## Generate API Documentation (GAD)

**Trigger Phrases:**
- "Generate API Documentation"
- "GAD"
- "Document API"
- "Create API docs"

**Action:**
[To be defined - coming soon]

---

## Command Execution Guidelines

When executing Backend commands:
- **Confirm the command** - State which command you're executing
- **Be thorough** - Include proper error handling and validation
- **Be accurate** - Test API endpoints and data flows
- **Be actionable** - Provide specific optimizations or fixes
- **Follow patterns** - Maintain consistency with existing backend architecture

---

**Last Updated:** 2025-10-09
**Role:** Backend Developer
