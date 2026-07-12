---
spec_type: tech-stack
title: Demo Project Technology Stack
owner: demo-architecture
status: approved
last_updated: "2026-07-11"
applicability: [demo-project]
related_initiatives: [FTR-0001]
---

# Demo Project Technology Stack

## Purpose

Define the deliberately minimal technology boundary for the executable
VirtualBoard demonstration workspace.

## Architecture Overview

The demo contains Markdown state, schemas, and validation fixtures only; it has
no application runtime or hosted service.

## Languages, Frameworks & Tooling

Portable shell scripts and the pinned `vb` binary execute validation without a
Node.js, package-manager, or application-framework dependency.

## Security & Compliance Considerations

Fixtures contain no credentials or personal data, and all paths remain inside
the checked-out demonstration workspace.

## Operational Considerations

Repository tests validate lifecycle folders, dependency rules, schemas, and the
generated index deterministically before the demo is published.
