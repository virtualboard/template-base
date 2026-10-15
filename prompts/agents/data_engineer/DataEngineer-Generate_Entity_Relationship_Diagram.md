# Entity Relationship Diagram (ERD)

**Trigger Phrases:**
- "Entity Relationship Diagram"
- "ERD"
- "Create data model diagram"
- "Generate ERD"
- "Create database diagram"
- "Show data model"

**Action:**
When the Data Engineer agent receives this command, it should:

## 1. Analyze Project Data Models
- Scan database schemas (SQL files, migrations, ORM models)
- Identify service models (API endpoints, service layer)
- Extract UI data structures (component props, state management)
- Map relationships between entities
- Document primary keys, foreign keys, and constraints
- Identify data domains and bounded contexts

### 2. Create Mermaid ERD Diagram

**ERD Template Structure:**
```markdown
# Entity Relationship Diagram

## Overview
{Description of the data model and its scope}

## Database Schemas
{Mermaid ERD diagram for database entities}

## Service Models
{Mermaid ERD diagram for service layer entities}

## UI Data Structures
{Mermaid ERD diagram for UI state and props}

## Relationships Summary
{Text description of key relationships}

## Key Entities

### {Entity Name}
- **Type:** {Database/Service/UI}
- **Description:** {Entity purpose}
- **Key Fields:**
  - `field_name` (type): Description
  - `field_name` (type): Description

## Data Flow
{High-level data flow description}

---

**Generated:** {YYYY-MM-DD}
**Scope:** {Database/Services/UI}
**Owner:** Data Engineering Team
```

**Mermaid ERD Syntax Example:**
````markdown
```mermaid
erDiagram
    USER ||--o{ ORDER : places
    USER {
        int id PK
        string email
        string name
        datetime created_at
    }
    ORDER ||--|{ ORDER_ITEM : contains
    ORDER {
        int id PK
        int user_id FK
        float total_amount
        string status
    }
    ORDER_ITEM }o--|| PRODUCT : references
    ORDER_ITEM {
        int id PK
        int order_id FK
        int product_id FK
        int quantity
    }
    PRODUCT {
        int id PK
        string name
        float price
        string category
    }
```
````

### 3. Document Relationships
- Identify one-to-one, one-to-many, many-to-many relationships
- Document cardinality and constraints
- Note any circular dependencies or design issues
- Suggest optimizations for query performance

### 4. Generate Report

**File Location:** `.virtualboard/reports/{YYYY-MM-DD}_Entity_Relationship_Diagram.md`

**Report Sections:**
1. **Overview** - High-level description of the data model
2. **Database Schemas** - ERD for database entities (Mermaid diagram)
3. **Service Models** - ERD for service layer models (Mermaid diagram)
4. **UI Data Structures** - ERD for UI state and components (Mermaid diagram)
5. **Entity Catalog** - Detailed list of all entities with fields
6. **Relationship Map** - Text description of all relationships
7. **Data Flow** - High-level flow diagram
8. **Recommendations** - Suggestions for improvements

### 5. Best Practices for ERD Creation

**Database ERD:**
- Include all tables and columns
- Show primary keys (PK) and foreign keys (FK)
- Use appropriate cardinality symbols (||, }o, o|)
- Group related entities by domain
- Include indexes and constraints notes

**Service Model ERD:**
- Map API request/response models
- Show service boundaries
- Document data transformations between services
- Include shared/common models

**UI Data ERD:**
- Show component prop structures
- Map state management (Redux, Context, etc.)
- Document form data structures
- Include UI-specific computed fields

### 6. Announce Completion
- List all entities discovered and documented
- Show key relationships identified
- Provide recommendations for data model improvements
- Include link to the generated diagram file

---

## Optional: Generate Branded HTML Report

If the user requests `--html`, "as HTML"/"branded HTML", or `format: html`,
write the Markdown deliverable first, then render an additional HTML report.

1. Read `templates/reports/html/data-erd.html`. Its comment header lists the
   scalar fields and list-item shapes. Use the same findings and measurements
   as the Markdown report; do not invent values for unknown results.
2. Write a companion JSON data file with uppercase field names, native numbers,
   and arrays of objects for lists. Include every referenced field; use `""`,
   `null`, or `[]` for explicitly empty values. The default brand and raster logo
   are provided by the renderer.
3. Run the deterministic renderer:

   ```bash
   vb report render --template data-erd.html \
     --data REPORT_DATA.json --output REPORT.html
   ```

   Replace the example paths with paths beside the Markdown deliverable, using
   the same basename for `.md`, `.json`, and `.html`. Includes and repeated
   blocks are resolved by the CLI; do not manually substitute template text.
4. Strings are escaped, including `*_HTML` fields. Annotate reviewed markup as
   `{"html":"<p>Reviewed content</p>"}` and add `--allow-html` only when those
   fragments are intended as markup. Supply `*_JSON` fields as native JSON
   values; the renderer safely serializes them in inline scripts.
5. Validate with `--dry-run` if useful, then inspect the generated HTML. Existing
   output requires `--force`; a rendering error must preserve earlier output.
   If the installed CLI lacks `report render`, report that limitation instead
   of claiming an HTML artifact was produced.
6. List the Markdown and HTML paths in the final reply, with the companion JSON
   path so the report can be reproduced.

See `templates/reports/README.md` for the input contract and the runnable
`templates/reports/examples/pm-progress-report.data.json` for a complete example.
