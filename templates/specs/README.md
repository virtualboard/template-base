---
title: Specs Catalog
owner: platform
status: draft
last_updated: YYYY-MM-DD
---

# System Specification Templates

This directory contains cross-cutting specification templates that complement
feature specs under `$VB_ROOT/features`. Copy instantiated system specs into
`$VB_ROOT/specs`, the only canonical directory scanned by `vb validate`.

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
1. Copy the relevant complete template to `$VB_ROOT/specs/<spec-type>.md`.
2. Update the frontmatter metadata (`spec_type`, `title`, `owner`,
   `last_updated`, etc.) so automation can catalog the document.
3. Replace every placeholder, including `YYYY-MM-DD`, with real project data.
4. Link the canonical spec from relevant features, PRs, and application docs;
   do not create a second authoritative copy elsewhere.

> Application docs may summarize or link a system spec, but the validated source
> remains under `$VB_ROOT/specs`. Update its body and `last_updated` together.

## Validation

All system specs share the same schema (`schemas/system-spec.schema.json`). `vb validate` verifies that:

- `spec_type`, `status`, and `applicability` use allowed values.
- `last_updated` is a real ISO date. The literal template placeholder
  `YYYY-MM-DD` is invalid in an instantiated spec.
- Arrays (`applicability`, `related_initiatives`) contain normalized tokens.

If something is missing, the validator will flag the offending file before your PR lands.
