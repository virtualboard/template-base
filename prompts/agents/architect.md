# System Architect Commands

This file defines specialized commands and actions for the System Architect agent role.

## ⚠️ IMPORTANT: Command Display Requirement

**When you adopt the Architect agent role and load this command file, you MUST immediately display a summary of available commands to the user.**

**Format:**
```
📋 Available Architect Commands:
• GAD (Generate Architecture Decision) - Document architectural decisions with ADR format
• GAR (Generate Architecture Report) - Create architecture analysis reports
• GTD (Generate Technical Debt Report) - Analyze and prioritize technical debt
```

This ensures users know what commands are available to them.

---

## Generate Architecture Decision (GAD)

**Trigger Phrases:**
- "Generate Architecture Decision"
- "GAD"
- "Document architecture decision"
- "Create ADR"
- "Architecture Decision Record"

**Action:**
When the Architect agent receives this command, it should:

### 1. Gather Context
- Identify the architectural decision that needs documentation
- Review relevant code, features, and system design
- Understand the problem/challenge being addressed
- Identify stakeholders affected by the decision

### 2. Analyze Options
- List at least 2-3 alternative approaches considered
- Document pros and cons for each option
- Consider: performance, scalability, maintainability, cost, complexity
- Note any constraints or requirements

### 3. Document Decision
- Create an ADR file at `.virtualboard/architecture/decisions/ADR-{NNNN}-{title-slug}.md`
- Use the following structure:

```markdown
# ADR-{NNNN}: {Decision Title}

**Status:** Proposed | Accepted | Deprecated | Superseded
**Date:** {YYYY-MM-DD}
**Deciders:** {List of people/roles involved}
**Technical Story:** {Link to related feature/issue if applicable}

---

## Context and Problem Statement

{Describe the context and problem statement, e.g., in free form using two to three sentences. You may want to articulate the problem in form of a question.}

## Decision Drivers

* {decision driver 1, e.g., a force, facing concern, …}
* {decision driver 2}
* {decision driver 3}
* …

## Considered Options

* {option 1}
* {option 2}
* {option 3}
* …

## Decision Outcome

**Chosen option:** "{option X}", because {justification. e.g., only option that meets key drivers, best trade-off, etc.}

### Positive Consequences

* {e.g., improvement of quality attribute satisfaction, follow-up decisions required, …}
* …

### Negative Consequences

* {e.g., compromising quality attribute, follow-up decisions required, …}
* …

## Pros and Cons of the Options

### {option 1}

* **Good**, because {argument a}
* **Good**, because {argument b}
* **Bad**, because {argument c}
* …

### {option 2}

* **Good**, because {argument a}
* **Good**, because {argument b}
* **Bad**, because {argument c}
* …

### {option 3}

* **Good**, because {argument a}
* **Good**, because {argument b}
* **Bad**, because {argument c}
* …

## Links

* {Link to related ADRs}
* {Link to relevant documentation}
* {Link to technical spike or POC}

---

**Last Updated:** {YYYY-MM-DD}
```

### 4. Create Directory if Needed
- Ensure `.virtualboard/architecture/decisions/` exists
- Use `mkdir -p` to create if necessary
- Maintain sequential numbering for ADRs

### 5. Announce Completion
- Inform the user that the ADR has been created
- Provide the file path
- Summarize the decision and its rationale

---

## Generate Architecture Report (GAR)

**Trigger Phrases:**
- "Generate Architecture Report"
- "GAR"
- "Create architecture report"
- "Architecture analysis"

**Action:**
[To be defined - coming soon]

---

## Generate Technical Debt Report (GTD)

**Trigger Phrases:**
- "Generate Technical Debt Report"
- "GTD"
- "Analyze technical debt"
- "Technical debt analysis"

**Action:**
[To be defined - coming soon]

---

## Command Execution Guidelines

When executing Architect commands:
- **Confirm the command** - State which command you're executing
- **Be thorough** - Don't skip steps in the workflow
- **Be accurate** - Verify facts from actual code and documentation
- **Be actionable** - Provide specific technical recommendations
- **Follow standards** - Align with project architectural patterns

---

**Last Updated:** 2025-10-09
**Role:** System Architect
