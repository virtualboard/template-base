# Generate User Journey (GUJ)

**Trigger Phrases:**
- "Generate User Journey"
- "GUJ"
- "Create user journey"
- "Map user flow"
- "User journey map"

**Action:**
When the UX/Product Designer agent receives this command, it should:

## 1. Define Journey Scope
- User persona(s) involved
- Journey goal/objective
- Entry and exit points
- Key scenarios/use cases

### 2. Map Journey Steps
- Identify all touchpoints
- Document user actions at each step
- Capture user thoughts/feelings
- Note pain points and opportunities

### 3. Create Journey Map
Create map at `.virtualboard/design/journeys/UJ-{journey-name}.md`:

```markdown
# User Journey: {Journey Name}

**Persona:** {Primary persona}
**Goal:** {What user wants to accomplish}
**Created:** {YYYY-MM-DD}

---

## Journey Overview
{Brief description of the journey}

**Scenario:** {Specific use case or scenario}

---

## Journey Map

### Stage 1: {Stage Name} (e.g., Awareness, Consideration)

**User Goal:** {What user wants to achieve in this stage}

| Touchpoint | User Action | Thoughts/Feelings | Pain Points | Opportunities |
|------------|-------------|-------------------|-------------|---------------|
| {Homepage} | Lands on site via search | "Is this what I need?" | Unclear value prop | Add hero section with clear message |
| {Feature page} | Explores features | "How does this work?" | Too technical | Add visual demos |

---

### Stage 2: {Stage Name}

{Repeat structure}

---

## Key Insights

### Pain Points
1. **{Pain Point}** - Severity: High/Medium/Low
   - Impact: {Description}
   - Occurs at: {Journey stage}

### Opportunities
1. **{Opportunity}** - Priority: High/Medium/Low
   - Improvement: {Description}
   - Affects: {Journey stage}

---

## Emotional Journey

```text
Emotion Level (High to Low)
    |     x
    |    x x     x
    |   x   x   x x
    |  x     x x   x
    | x       x     x
    +------------------
     Stage: 1 2 3 4 5
```

- **Peaks:** {What causes positive emotions}
- **Valleys:** {What causes negative emotions}

---

## Success Metrics
- {Metric 1}: {Target}
- {Metric 2}: {Target}

## Next Steps
1. {Design/development task}
2. {Research task}
3. {Testing task}

---

## Related Artifacts
- User Persona: {Link}
- Wireframes: {Link}
- Feature Spec: {FTR-####}

---

**Last Updated:** {YYYY-MM-DD}
```

### 4. Announce Completion
- Provide journey map path
- Highlight key pain points
- Suggest priority improvements
