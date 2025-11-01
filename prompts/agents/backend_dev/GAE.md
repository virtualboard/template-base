# Generate API Endpoint (GAE)

**Trigger Phrases:**
- "Generate API Endpoint"
- "GAE"
- "Create API endpoint"
- "Create endpoint"
- "New API route"

**Action:**
When the Backend Developer agent receives this command, it should:

## 1. Gather Requirements
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
