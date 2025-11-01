# Generate Database Migration (GDM)

**Trigger Phrases:**
- "Generate Database Migration"
- "GDM"
- "Create migration"
- "Database migration"

**Action:**
When the Backend Developer agent receives this command, it should:

## 1. Understand Migration Requirements
- Determine migration type: create table, alter table, add column, drop column, add index, etc.
- Identify database system (PostgreSQL, MySQL, MongoDB, etc.)
- Review existing schema and migrations
- Check for dependencies on other tables/migrations
- Plan rollback strategy

### 2. Generate Migration File
Create migration file based on the project's ORM/migration tool:

**For Sequelize (Node.js):**
```javascript
// migrations/YYYYMMDDHHMMSS-create-users-table.js
'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('users', {
      id: {
        type: Sequelize.INTEGER,
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      email: {
        type: Sequelize.STRING(255),
        allowNull: false,
        unique: true
      },
      name: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      password_hash: {
        type: Sequelize.STRING(255),
        allowNull: false
      },
      role: {
        type: Sequelize.ENUM('user', 'admin', 'moderator'),
        defaultValue: 'user',
        allowNull: false
      },
      is_active: {
        type: Sequelize.BOOLEAN,
        defaultValue: true
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP')
      }
    });

    // Add indexes
    await queryInterface.addIndex('users', ['email']);
    await queryInterface.addIndex('users', ['created_at']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('users');
  }
};
```

**For Knex (Node.js):**
```javascript
// migrations/20250101000000_create_users_table.js
exports.up = function(knex) {
  return knex.schema.createTable('users', function(table) {
    table.increments('id').primary();
    table.string('email', 255).notNullable().unique();
    table.string('name', 100).notNullable();
    table.string('password_hash', 255).notNullable();
    table.enu('role', ['user', 'admin', 'moderator']).defaultTo('user');
    table.boolean('is_active').defaultTo(true);
    table.timestamps(true, true);

    // Indexes
    table.index('email');
    table.index('created_at');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('users');
};
```

**For Django (Python):**
```python
# migrations/0001_create_users_table.py
from django.db import migrations, models

class Migration(migrations.Migration):
    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name='User',
            fields=[
                ('id', models.AutoField(primary_key=True)),
                ('email', models.EmailField(max_length=255, unique=True)),
                ('name', models.CharField(max_length=100)),
                ('password_hash', models.CharField(max_length=255)),
                ('role', models.CharField(
                    max_length=20,
                    choices=[('user', 'User'), ('admin', 'Admin'), ('moderator', 'Moderator')],
                    default='user'
                )),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'db_table': 'users',
                'indexes': [
                    models.Index(fields=['email']),
                    models.Index(fields=['created_at']),
                ],
            },
        ),
    ]
```

**For Rails (Ruby):**
```ruby
# db/migrate/20250101000000_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :email, null: false, limit: 255
      t.string :name, null: false, limit: 100
      t.string :password_hash, null: false
      t.string :role, default: 'user', null: false
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :created_at
  end
end
```

**For TypeORM (TypeScript):**
```typescript
// migrations/1704067200000-CreateUsersTable.ts
import { MigrationInterface, QueryRunner, Table, TableIndex } from "typeorm";

export class CreateUsersTable1704067200000 implements MigrationInterface {
    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.createTable(
            new Table({
                name: "users",
                columns: [
                    {
                        name: "id",
                        type: "int",
                        isPrimary: true,
                        isGenerated: true,
                        generationStrategy: "increment",
                    },
                    {
                        name: "email",
                        type: "varchar",
                        length: "255",
                        isUnique: true,
                        isNullable: false,
                    },
                    {
                        name: "name",
                        type: "varchar",
                        length: "100",
                        isNullable: false,
                    },
                    {
                        name: "password_hash",
                        type: "varchar",
                        length: "255",
                        isNullable: false,
                    },
                    {
                        name: "role",
                        type: "enum",
                        enum: ["user", "admin", "moderator"],
                        default: "'user'",
                    },
                    {
                        name: "is_active",
                        type: "boolean",
                        default: true,
                    },
                    {
                        name: "created_at",
                        type: "timestamp",
                        default: "CURRENT_TIMESTAMP",
                    },
                    {
                        name: "updated_at",
                        type: "timestamp",
                        default: "CURRENT_TIMESTAMP",
                        onUpdate: "CURRENT_TIMESTAMP",
                    },
                ],
            }),
            true
        );

        await queryRunner.createIndex(
            "users",
            new TableIndex({
                name: "IDX_USERS_EMAIL",
                columnNames: ["email"],
            })
        );

        await queryRunner.createIndex(
            "users",
            new TableIndex({
                name: "IDX_USERS_CREATED_AT",
                columnNames: ["created_at"],
            })
        );
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.dropTable("users");
    }
}
```

### 3. Add Migration for Relationships (if needed)

**Example: Add Foreign Key:**
```javascript
// migrations/YYYYMMDDHHMMSS-add-user-posts-relation.js
'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('posts', {
      id: {
        type: Sequelize.INTEGER,
        autoIncrement: true,
        primaryKey: true
      },
      user_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      title: {
        type: Sequelize.STRING(200),
        allowNull: false
      },
      content: {
        type: Sequelize.TEXT,
        allowNull: true
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      }
    });

    await queryInterface.addIndex('posts', ['user_id']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('posts');
  }
};
```

### 4. Document Migration

Create documentation at `docs/migrations/MIGRATION-{NNNN}.md`:

```markdown
# Migration: {Migration Name}

**File:** `migrations/{timestamp}-{name}.{ext}`
**Created:** {YYYY-MM-DD}
**Status:** Pending | Applied | Rolled Back

---

## Summary
{Brief description of what this migration does}

## Changes

### Tables Created
- `users` - User account information

### Columns Added
- `users.email` (VARCHAR(255), NOT NULL, UNIQUE) - User email address
- `users.name` (VARCHAR(100), NOT NULL) - User full name
- `users.password_hash` (VARCHAR(255), NOT NULL) - Hashed password
- `users.role` (ENUM, DEFAULT 'user') - User role
- `users.is_active` (BOOLEAN, DEFAULT true) - Account status

### Indexes Created
- `users(email)` - Unique index for email lookups
- `users(created_at)` - Index for date-based queries

### Foreign Keys
- N/A

## Dependencies
- None (initial migration)

## Rollback Plan
- Drops the `users` table and all associated indexes

## Data Migration (if applicable)
- N/A

## Testing
```bash
# Run migration
npm run migrate:up
# or
npx sequelize-cli db:migrate

# Test that table exists
# Verify schema matches expected structure

# Rollback if needed
npm run migrate:down
```

## Notes
- Ensure database user has CREATE TABLE and CREATE INDEX permissions
- Consider impact on existing data (if any)
- This migration is safe to run in production

---

**Last Updated:** {YYYY-MM-DD}
```

### 5. Add Migration Commands

Document commands in project README or migration guide:

```markdown
## Database Migrations

### Run Migrations
```bash
# Run all pending migrations
npm run migrate

# Run specific migration
npm run migrate -- --name 20250101000000-create-users-table
```

### Rollback Migrations
```bash
# Rollback last migration
npm run migrate:rollback

# Rollback to specific migration
npm run migrate:rollback -- --to 20250101000000
```

### Check Migration Status
```bash
npm run migrate:status
```

### Create New Migration
```bash
npm run migrate:create -- --name add-users-table
```
```

### 6. Announce Completion
- Inform the user that the migration has been created
- Provide the migration file path
- List changes included (tables, columns, indexes, foreign keys)
- Provide migration command to run
- Remind about testing the migration before applying to production
- Include rollback command
