---
spec_type: database-schema
title: <Database Schema Specification>
owner: <data-or-platform-team>
status: draft # draft | approved | deprecated
last_updated: YYYY-MM-DD
applicability: [web, mobile, desktop]
related_initiatives: []
---

# Database Schema Specification

## Purpose
Outline the authoritative data model, how it supports product experiences, and expectations for scalability, integrity, and governance.

## Scope
- Systems, services, and environments covered by this schema.
- Interfaces that read/write for each client (web, mobile, desktop, integrations).

## Data Classification & Compliance
- Sensitivity levels per domain, residency constraints, encryption requirements.
- Mapping to policies (GDPR, HIPAA, PCI, SOC 2, etc.).

## System Overview
- Diagram(s) referencing ERDs, UML, dbdocs, dbdiagram.io, or Mermaid definitions.
- Summary of database engines, versions, replication modes.

## Schema Summary
| Schema / DB | Purpose | Owner | Notes |
| ----------- | ------- | ----- | ----- |

## Entity Inventory
For each table/collection/view:
### `<table_name>`
- Business purpose, lifecycle, related features.
- Columns (name, type, nullable, default, constraints) in table form.
- Indexes (btree, hash, gin/gist), covering index strategy, partitioning.

## Relationships & Data Flows
- Foreign key diagrams, cascades, cardinality, polymorphic relationships.
- Write/read paths (services → tables), caching behavior, denormalization strategy.

## Stored Routines & Business Logic
- Functions, stored procedures, triggers, event-driven logic, justification.
- Versioning, test coverage expectations, idempotency requirements.

## Migrations & Change Management
- Tooling (Prisma, Flyway, Liquibase, Rails migrations, Atlas, Sqitch).
- Review process, rollout sequencing, backward compatibility expectations.

## Performance & Capacity Planning
- Estimated data volumes, growth rates, partition strategy, sharding plans.
- Benchmark results, slow query budgets, caching hints.

## Data Lifecycle & Retention
- Archival policies, deletion windows, legal hold implications, backups & restore cadence.
- Data masking/anonymization approach for lower environments.

## Observability & Quality
- Metrics (replication lag, deadlocks, queue depth), alert thresholds, dashboards.
- Data quality checks, reconciliation jobs, anomaly detection.

## Access Patterns & APIs
- Authoritative APIs/services per table, read/write throughput expectations, batching.
- Contract for analytics/reporting consumers.

## Risks & Mitigations
- Single points of failure, vendor lock-in, migration blockers, regulatory risk.

## Open Questions
- Outstanding modeling decisions, prototypes to validate, dependencies.

## References
- ERD files, db diagrams, ADRs, migration histories, incident postmortems, data dictionaries.
