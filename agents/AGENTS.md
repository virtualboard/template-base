# Agent System Prompts

This document catalogs the agent-facing system prompts found in `agents/` and outlines how the virtual team covers design, build, test, deploy, and operate responsibilities for cloud systems. Every agent must follow the shared guardrails defined in [`agents/RULES.md`](agents/RULES.md).

## Shared Workflow Expectations
- Every role prompt instructs agents to learn the `.virtualboard` Markdown feature workflow before acting.
- Feature specs live under `/features/<status>/` with frontmatter-driven ownership, dates, and dependencies.
- Agents are expected to claim work atomically, keep `updated` fresh, and respect status-folder alignment.
- Prompts emphasize a continuous delivery loop: pick a task, validate dependencies, take ownership, execute, move to the next state, and immediately look for new work.

## Current Agent Prompts

### Project Manager — `agents/pm.md`
- Owns planning cadence: sprint goals, prioritization, stakeholder updates, blocker removal.
- Creates new specs in `/features/backlog/` and drives them through planning and review.
- Must continuously monitor backlog, assign ownership, and maintain progress reporting loops.

### System Architect — `agents/architect.md`
- Defines technical standards, architectural direction, and high-level implementation plans.
- Reviews major changes, manages technical debt, and seeds features for the build team.
- Follows the same claim → implement → review cycle, focused on design-heavy backlog items.

### UX/Product Designer — `agents/ux_product_designer.md`
- Shapes user journeys, wireframes, prototypes, and design-system updates tied to spec `UI/UX Notes`.
- Partners with PM and engineering to refine acceptance criteria and document usability findings.

### Backend Developer — `agents/backend_dev.md`
- Implements APIs, data models, auth flows, scalability and performance improvements.
- Targets features labeled `backend`, `api`, `database`, or `server`; handles testing and documentation for backend work.

### Frontend Developer — `agents/frontend_dev.md`
- Crafts UI components, accessibility, responsive layouts, state management, and performance tuning.
- Focuses on features labeled `frontend`, `ui`, or `components`, pairing closely with backend specs.

### Fullstack Developer — `agents/fullstack_dev.md`
- Bridges frontend and backend responsibilities, delivering end-to-end vertical slices.
- Picks up cross-cutting features when coordination between specialized roles would slow delivery.

### DevOps & Reliability Engineer — `agents/devops_engineer.md`
- Owns CI/CD, infrastructure-as-code, observability, and incident-response readiness.
- Ensures deployment plans, monitoring hooks, and rollback strategies are captured in specs.

### Security & Compliance Engineer — `agents/security_compliance_engineer.md`
- Performs threat modeling, security reviews, and regulatory alignment before release.
- Updates `Security & Compliance` sections with mitigations, evidence, and go/no-go guidance.

### Data & Analytics Engineer — `agents/data_analytics_engineer.md`
- Designs data models, pipelines, dashboards, and experimentation frameworks tied to metrics.
- Keeps telemetry, instrumentation, and analytics requirements current in specs.

### QA Engineer — `agents/qa.md`
- Engages when features reach review, executes manual/automated test plans, reports regressions.
- Controls the final gate to `done`, either certifying completion or routing work back to the backlog.

### Rules of Engagement — `agents/RULES.md`
- Provides universal guardrails: read-first, respect ownership, validate transitions, and log actions.
- Lists safety checklists, conflict resolution, and environment configuration expectations for all agents.

The expanded roster ensures the virtual team can design, build, test, secure, deploy, and operate cloud information systems end to end using the Virtual Board workflow.
