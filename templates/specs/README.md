---
title: Specs Catalog
owner: platform
status: draft
last_updated: YYYY-MM-DD
---

# System Specification Templates

This directory contains cross-cutting specification templates that complement feature specs in `/features`. Each Markdown file provides a repeatable structure you can clone (`cp templates/specs/<template>.md specs/<project>-<area>.md`) or reference when drafting foundational documentation.

| Template | Purpose |
| -------- | ------- |
| `tech-stack.md` | Capture the canonical languages, frameworks, runtimes, and integrations that make up the product stack across all clients. |
| `local-development.md` | Document the developer onboarding experience, tooling requirements, and troubleshooting flows. |
| `hosting-and-infrastructure.md` | Describe cloud/on-prem environments, topology, and operational guardrails. |
| `ci-cd-pipeline.md` | Define build/test/deploy automation, gates, and ownership. |
| `database-schema.md` | Provide authoritative data model inventory, relationships, and governance controls. |
| `caching-and-performance.md` | Outline caching layers, performance targets, and instrumentation strategy. |
| `security-and-compliance.md` | Detail security controls, threat models, and compliance obligations. |
| `observability-and-incident-response.md` | Establish telemetry coverage, alerting, and incident management practices. |

## How to Use These Templates
1. Duplicate the relevant template (or subset of sections) into your feature/design doc.
2. Update the frontmatter metadata (`spec_type`, `title`, `owner`, `last_updated`, etc.) so automation can catalog the document.
3. Replace bracketed placeholder text with project-specific details.
4. Link completed specs from relevant feature files, PRs, or `/docs` articles for discoverability.

> Tip: Keep specs close to the code that implements them (e.g., `docs/architecture/`, `docs/ops/`). When the implementation changes, update both the spec body *and* the `last_updated` field.

## Validation

All system specs share the same schema (`schemas/system-spec.schema.json`). `vb validate` and `./scripts/ftr-validate.sh` verify that:

- `spec_type`, `status`, and `applicability` use allowed values.
- `last_updated` is either a real ISO date or the placeholder `YYYY-MM-DD` while templating.
- Arrays (`applicability`, `related_initiatives`) contain normalized tokens.

If something is missing, the validator will flag the offending file before your PR lands.
