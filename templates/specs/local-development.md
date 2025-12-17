---
spec_type: local-development
title: <Local Development Environment>
owner: <devx-or-platform-team>
status: draft # draft | approved | deprecated
last_updated: YYYY-MM-DD
applicability: [web, mobile, desktop]
related_initiatives: []
---

# Local Development Environment Specification

## Purpose
Describe the goals for the developer experience (onboarding time, productivity, platform coverage) and what problems this environment solves.

## Success Criteria
- Target onboarding time for a new engineer.
- Required parity with staging/production.
- Supported operating systems and hardware (Apple Silicon, Windows, Linux).

## Environment Support Matrix
| OS / Platform | Supported? | Notes |
| ------------- | ---------- | ----- |
| macOS         |            |       |
| Windows       |            |       |
| Linux         |            |       |
| Cloud DevBox  |            |       |

## Prerequisites
- Accounts, access groups, VPN, SSO requirements.
- Tooling versions (Git, language runtimes, package managers, Docker, virtualization).

## Quick Start Checklist
1. Clone repositories / configure submodules.
2. Bootstrap toolchains (`asdf`, `nvm`, `pyenv`, SDKMAN, etc.).
3. Install dependencies (backend, frontend, mobile, desktop).
4. Provision secrets/config (Vault, 1Password, Doppler, SSM, git-crypt, etc.).
5. Start required services (databases, queues, mocks, containers).
6. Run smoke tests / health checks.

## Tooling & Services Overview
| Area | Tool / Command | Purpose | Notes |
| ---- | -------------- | ------- | ----- |
| Backend API | `make api` | Starts web/API servers | Attach debugger instructions |
| Frontend     | `pnpm dev` | Launches web client | Port, HTTPS, proxy config |
| Mobile       | `yarn ios` | Runs simulator | Device requirements |
| Desktop      |            |                    |                       |

## Configuration & Secrets
- Config file locations, env var naming conventions, `.env` templates.
- How to rotate secrets locally, referencing security guidelines.

## Data & Seed Strategy
- Lightweight fixtures vs snapshot restores.
- Synthetic data tooling, anonymization guidance, sample scripts.
- How to reset or reseed services (DB, cache, search indexes, blob storage).

## Service & Dependency Emulation
- Which dependencies run locally vs remotely (e.g., real S3, localstack, WireMock, gRPC mocks).
- Contracts for teams owning shared services.

## Running the Stack
### Backend Services
- Command(s) to boot the stack, entrypoints per service, debugger hooks, hot reload notes.

### Web Frontend
- How to connect to local vs remote APIs, CORS configuration, env-specific URLs.

### Mobile / Desktop Clients
- Emulator/device setup, certificates, push notification sandboxing, packaging steps.

### Background Jobs & Workers
- Triggering scheduled jobs locally, using fake queues/timers.

## Testing Workflows
- Commands for unit/integration/e2e/perf tests, where results are stored.
- How to run selective suites, watch mode, coverage generation.

## Troubleshooting & Diagnostics
- Common failure cases, log locations, network tips, clean-room reset commands.
- Links to observability dashboards or local tooling (e.g., mailhog, jaeger-ui, grafana-lab).

## Automation & Tooling
- Scripts/Make targets for linting, formatting, DB migrations, asset builds.
- Developer containers, Nix flakes, DevBox definitions if applicable.

## Security & Compliance Notes
- Local data handling requirements (PII redaction, GDPR, HIPAA, PCI), machine hardening guidance.

## Ownership & Change Management
- Who maintains the dev experience.
- How updates are communicated (release notes, Slack channel, doc PRs).
- Validation cadence (e.g., quarterly DX review).

## References
- Link to onboarding guides, runbooks, architecture diagrams, DevEx backlog, issue templates.
