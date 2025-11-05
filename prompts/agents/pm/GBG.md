# Generate Backlog Grooming (GBG)

**Trigger Phrases:**
- "Generate Backlog Grooming"
- "GBG"
- "Groom backlog"
- "Backlog grooming session"
- "Refine backlog"
- "Backlog refinement"

**Action:**
When the PM agent receives this command, it should perform a comprehensive backlog grooming session:

---

## 1. Scan All Backlog Features

- Read all feature files in `features/backlog/`
- Parse frontmatter for each feature:
  - `id`, `title`, `status`, `priority`, `complexity`, `created`, `updated`
  - `labels`, `dependencies`, `epic`, `risk_notes`
- Load acceptance criteria and requirements sections
- Create inventory of all backlog items

---

## 2. Assess Implementation Status (Per Feature)

For each backlog feature, determine current implementation state:

### 2.1. Check Codebase Implementation

**Search for evidence of implementation:**
- Search codebase for keywords from feature title
- Check for files/modules mentioned in feature spec
- Look for related test files
- Search for API endpoints or UI components described
- Check git history for related commits

**Classification:**
- **Fully Implemented**: Feature appears complete in codebase
- **Partially Implemented**: Some components exist, others missing
- **Not Implemented**: No evidence in codebase
- **Unknown**: Unable to determine (needs human input)

### 2.2. Interactive Assessment (For Each Feature)

**For FULLY IMPLEMENTED features:**

Ask the user:
```
🔍 Feature FTR-#### "{title}" appears to be fully implemented.

Evidence found:
- [List files, components, or code that matches the feature]
- [Acceptance criteria that appear to be met]

Options:
A) Move to REVIEW for formal review/testing
B) Move directly to DONE (user confirms it's complete)
C) Keep in BACKLOG (implementation found is not this feature)
D) Split feature (some parts done, some remain)

What would you like to do? [A/B/C/D]
```

**For PARTIALLY IMPLEMENTED features:**

Ask the user:
```
⚠️ Feature FTR-#### "{title}" is partially implemented.

What's done:
- [List implemented components]

What's missing:
- [List missing components from acceptance criteria]

Options:
A) Prioritize for completion (move to top of backlog with updated spec)
B) Split into two features:
   - FTR-#### (done parts) → Move to REVIEW/DONE
   - FTR-NEW (remaining work) → New feature in BACKLOG
C) Keep as-is in BACKLOG
D) Mark remaining work as out-of-scope (move done parts to DONE)

What would you like to do? [A/B/C/D]
```

**For NOT IMPLEMENTED features:**

Perform automated relevance check (Step 3) before asking user.

---

## 3. Automated Relevance Analysis

For features NOT YET IMPLEMENTED, analyze:

### 3.1. Codebase Evolution Check

- Compare feature requirements against current codebase architecture
- Identify if related systems have changed since feature was created
- Check if dependencies mentioned in spec still exist
- Note if similar functionality was implemented differently
- Detect if feature conflicts with recent architectural decisions

### 3.2. Dependency Status Check

- Check status of all dependencies listed in frontmatter
- Identify if dependencies are blocked, in-progress, or done
- Calculate dependency completion percentage
- Flag circular dependencies or long dependency chains

### 3.3. Priority & Effort Re-estimation

- Review current priority (`P0`, `P1`, `P2`, `P3`)
- Review complexity estimate (`XS`, `S`, `M`, `L`, `XL`)
- Compare against other backlog items
- Consider:
  - Time since creation (`created` date)
  - Related features completed since then
  - Current product priorities
  - Technical debt implications

### 3.4. Present Findings to User

```
📋 Feature FTR-#### "{title}" - NOT YET IMPLEMENTED

Created: {created} ({X} days ago)
Priority: {priority} | Complexity: {complexity}
Dependencies: {X complete, Y pending, Z blocked}

Relevance Analysis:
✅ Still relevant - [reasons why it's still needed]
⚠️ Needs update - [what needs to change in the spec]
❌ Possibly obsolete - [reasons it may no longer be needed]

Codebase Changes Since Creation:
- [List relevant changes that affect this feature]

Recommendation:
[AI recommendation: Keep as-is / Update spec / Deprioritize / Archive]

Options:
A) Keep in BACKLOG (still relevant, no changes needed)
B) Update feature spec (update requirements/acceptance criteria)
C) Deprioritize (lower priority or complexity)
D) Archive/Remove (decided not to do)
E) Defer (move to future/icebox category)

What would you like to do? [A/B/C/D/E]
```

---

## 4. Best Practices Checks

For ALL backlog features, validate:

### 4.1. Spec Quality

- [ ] Title is clear and descriptive (3-100 characters)
- [ ] Summary section is complete and concise
- [ ] Problem statement articulates WHO, WHAT, WHY
- [ ] User stories are present and follow format
- [ ] Acceptance criteria are testable and specific
- [ ] Priority is assigned (`P0`-`P3`)
- [ ] Complexity is estimated (`XS`-`XL`)
- [ ] Labels are relevant and properly formatted

**Flag for refinement if:**
- Missing or incomplete sections
- Vague acceptance criteria
- No complexity estimate
- Conflicting information

### 4.2. Dependency Hygiene

- [ ] All dependencies reference valid FTR IDs
- [ ] No circular dependencies
- [ ] Dependency chain depth ≤ 3 levels (best practice)
- [ ] Blocked features have clear unblocking conditions

**Flag for attention if:**
- Dependencies on features that no longer exist
- Long dependency chains (> 3 levels)
- Dependencies on features with lower priority

### 4.3. Staleness Check

- Features older than 90 days without updates → Flag as "stale"
- Features with outdated references → Flag for spec refresh
- Features superseded by completed work → Flag for archival

### 4.4. Epic & Theme Alignment

- Check if `epic` field is populated when applicable
- Verify epic IDs reference valid epics
- Group features by epic for better prioritization
- Identify orphaned features (no epic, unclear purpose)

---

## 5. Prioritization Recommendations

After assessing all backlog features, generate prioritization recommendations:

### 5.1. Analyze Priority Distribution

```
Current Backlog Priority Breakdown:
- P0 (Critical): X features
- P1 (High): Y features
- P2 (Medium): Z features
- P3 (Low): W features
```

### 5.2. Identify High-Impact, Low-Effort Items

- Features with complexity `XS` or `S` and priority `P0` or `P1`
- Features with no dependencies (ready to start immediately)
- Features that unblock multiple other features

### 5.3. Recommend Re-prioritization

**Suggest promotions (increase priority):**
- Features blocking many other features
- Quick wins that deliver high value
- Technical debt items causing recurring issues
- Security or compliance requirements

**Suggest demotions (decrease priority):**
- Features dependent on many incomplete features
- Features no longer aligned with product strategy
- Nice-to-have features with high complexity
- Duplicate or overlapping features

---

## 6. Generate Grooming Report

Create a comprehensive report at `reports/{YYYY-MM-DD}_Backlog_Grooming_Report.md`:

```markdown
# Backlog Grooming Report
**Generated:** {YYYY-MM-DD HH:MM}
**Groomer:** PM Agent
**Session Duration:** {X} minutes
**Features Reviewed:** {X} of {Y} backlog items

---

## Executive Summary

[2-3 sentence summary of backlog health, key findings, and recommended actions]

**Health Score:** {X}/10
- Spec Quality: {X}/10
- Dependency Hygiene: {X}/10
- Priority Clarity: {X}/10
- Readiness: {X}/10

---

## Grooming Session Results

### Features Assessed

| Status | Count | Action Taken |
|--------|-------|--------------|
| ✅ Fully Implemented (moved out) | X | Moved to REVIEW/DONE |
| ⚠️ Partially Implemented (split) | Y | Split into separate features |
| 📝 Spec Updated | Z | Requirements refreshed |
| 🗑️ Archived/Removed | W | Decided not to do |
| ✓ Validated as-is | V | Kept in backlog, no changes |
| **Total Reviewed** | **XX** | |

---

## 📊 Implementation Status Findings

### Fully Implemented Features (Should Move Out of Backlog)

| Feature ID | Title | Recommendation | User Decision |
|------------|-------|----------------|---------------|
| FTR-#### | Feature Name | Move to REVIEW | [User choice] |
| FTR-#### | Feature Name | Move to DONE | [User choice] |

**Action Required:** Move these features out of backlog per user decisions.

---

### Partially Implemented Features

| Feature ID | Title | Completed % | Recommendation | User Decision |
|------------|-------|-------------|----------------|---------------|
| FTR-#### | Feature Name | 60% | Split feature | [User choice] |
| FTR-#### | Feature Name | 40% | Prioritize completion | [User choice] |

**Action Required:** Follow up on splits or prioritization changes.

---

### Not Implemented Features - Relevance Analysis

#### ✅ Validated & Ready (No Changes Needed)

| Feature ID | Title | Priority | Complexity | Dependencies | Ready? |
|------------|-------|----------|------------|--------------|--------|
| FTR-#### | Name | P1 | M | 0 pending | ✓ Yes |

#### 📝 Updated Specifications

| Feature ID | Title | Changes Made | Reason |
|------------|-------|--------------|--------|
| FTR-#### | Name | [Updated requirements] | [Codebase evolution] |

#### 🗑️ Archived / Removed

| Feature ID | Title | Reason for Removal |
|------------|-------|--------------------|
| FTR-#### | Name | Decided not to do |
| FTR-#### | Name | Superseded by FTR-#### |

#### ⏸️ Deferred / Deprioritized

| Feature ID | Title | Original Priority | New Priority | Reason |
|------------|-------|-------------------|--------------|--------|
| FTR-#### | Name | P1 | P3 | [Reason] |

---

## 🚨 Issues & Red Flags

### Quality Issues Found

**Features Needing Spec Refinement:**
- FTR-#### - [Issue: Vague acceptance criteria]
- FTR-#### - [Issue: Missing complexity estimate]
- FTR-#### - [Issue: Incomplete problem statement]

**Action Required:** Schedule refinement sessions for these features.

---

### Dependency Problems

**Circular Dependencies Detected:**
- FTR-#### ↔ FTR-#### - [Description of cycle]

**Long Dependency Chains (> 3 levels):**
- FTR-#### → FTR-#### → FTR-#### → FTR-#### (4 levels)

**Invalid Dependency References:**
- FTR-#### references FTR-XXXX (does not exist)

**Action Required:** Resolve dependency issues before features can progress.

---

### Stale Features (> 90 days old)

| Feature ID | Title | Age (days) | Last Updated | Recommendation |
|------------|-------|------------|--------------|----------------|
| FTR-#### | Name | 120 | YYYY-MM-DD | [Refresh spec / Archive] |

**Action Required:** Review stale features for continued relevance.

---

## 📈 Prioritization Recommendations

### Current Priority Distribution

```
P0 (Critical):  ██████░░░░ X features (XX%)
P1 (High):      ████████░░ Y features (YY%)
P2 (Medium):    ██████████ Z features (ZZ%)
P3 (Low):       ████░░░░░░ W features (WW%)
```

---

### 🎯 High-Impact, Low-Effort Opportunities

**Quick Wins (Should prioritize):**

| Feature ID | Title | Priority | Complexity | Impact | Effort | Score |
|------------|-------|----------|------------|--------|--------|-------|
| FTR-#### | Name | P1 | XS | High | Low | ⭐⭐⭐⭐⭐ |
| FTR-#### | Name | P2 | S | High | Low | ⭐⭐⭐⭐ |

**Recommendation:** Move these to P0 or top of P1 queue.

---

### 🔓 Unblocking Features (Enable Multiple Others)

**Features that unblock the most work:**

| Feature ID | Title | Current Priority | Unblocks | Recommendation |
|------------|-------|------------------|----------|----------------|
| FTR-#### | Name | P2 | 5 features | Promote to P1 |
| FTR-#### | Name | P1 | 3 features | Keep at P1, prioritize |

**Recommendation:** Prioritize these to unblock downstream work.

---

### ⬆️ Suggested Priority Promotions

| Feature ID | Title | Current | Recommended | Reason |
|------------|-------|---------|-------------|--------|
| FTR-#### | Name | P2 | P1 | Unblocks 5 features |
| FTR-#### | Name | P3 | P2 | Security requirement |

---

### ⬇️ Suggested Priority Demotions

| Feature ID | Title | Current | Recommended | Reason |
|------------|-------|---------|-------------|--------|
| FTR-#### | Name | P1 | P2 | Blocked by 4 features |
| FTR-#### | Name | P2 | P3 | No longer strategic |

---

## 📋 Ready-to-Start Features

**Features with all prerequisites met:**

| Feature ID | Title | Priority | Complexity | Labels | Epic |
|------------|-------|----------|------------|--------|------|
| FTR-#### | Name | P0 | M | backend, api | EP-001 |
| FTR-#### | Name | P1 | S | frontend, ui | EP-002 |

**Recommendation:** These are ready for agent assignment immediately.

---

## 🎯 Epic & Theme Alignment

### Features by Epic

**Epic EP-#### - {Epic Name}:**
- FTR-#### - {Title} (P1, M)
- FTR-#### - {Title} (P2, S)
- FTR-#### - {Title} (P1, L)
- **Total:** X features | **Completed:** Y/X (ZZ%)

**Orphaned Features (No Epic):**
- FTR-#### - {Title} - [Recommend epic assignment]

---

## 🔄 Backlog Composition Analysis

### By Priority
- **P0:** X features (XX% of backlog)
- **P1:** Y features (YY% of backlog)
- **P2:** Z features (ZZ% of backlog)
- **P3:** W features (WW% of backlog)

### By Complexity
- **XS:** X features (XX story points estimated)
- **S:** Y features (YY story points estimated)
- **M:** Z features (ZZ story points estimated)
- **L:** W features (WW story points estimated)
- **XL:** V features (VV story points estimated)

### By Category (Labels)
- **backend:** X features
- **frontend:** Y features
- **infrastructure:** Z features
- **security:** W features
- **data:** V features

---

## ✅ Recommended Actions

### Immediate (This Week)

1. **Move completed features out of backlog:**
   - FTR-#### → REVIEW
   - FTR-#### → DONE

2. **Resolve dependency issues:**
   - Break circular dependency: FTR-#### ↔ FTR-####
   - Fix invalid references: [List]

3. **Prioritize quick wins:**
   - Move FTR-#### to P0 (high impact, low effort)
   - Assign FTR-#### to available agent

4. **Refine incomplete specs:**
   - FTR-#### - Add acceptance criteria
   - FTR-#### - Clarify requirements

### Short-term (Next 2 Weeks)

1. **Update stale features:**
   - Review features older than 90 days
   - Archive or refresh specs

2. **Implement priority changes:**
   - [List specific FTR re-prioritizations]

3. **Split partially implemented features:**
   - FTR-#### → FTR-#### (done) + FTR-NEW (remaining)

4. **Focus on unblocking features:**
   - Complete FTR-#### to unblock 5 downstream features

### Long-term (This Month)

1. **Epic planning:**
   - Ensure all features are assigned to epics
   - Balance work across epics

2. **Technical debt:**
   - Address architecture concerns raised in specs
   - Update features to reflect new patterns

3. **Capacity planning:**
   - Estimate timeline for current backlog
   - Identify resource constraints

---

## 📊 Backlog Health Metrics

### Quality Metrics
- **Complete specs:** XX/YY (ZZ%)
- **Properly prioritized:** XX/YY (ZZ%)
- **Estimated complexity:** XX/YY (ZZ%)
- **Has acceptance criteria:** XX/YY (ZZ%)

### Readiness Metrics
- **Ready to start:** XX features (no blockers)
- **Blocked by dependencies:** YY features
- **Needs refinement:** ZZ features
- **Stale (> 90 days):** WW features

### Dependency Metrics
- **Features with dependencies:** XX
- **Average dependency chain depth:** X.X levels
- **Circular dependencies:** X (should be 0)
- **Invalid dependencies:** X (should be 0)

---

## 🎯 Next Steps for Product Team

1. **Review grooming decisions** with stakeholders
2. **Approve priority changes** recommended in this report
3. **Schedule refinement sessions** for flagged features
4. **Assign ready features** to available development agents
5. **Archive features** marked for removal
6. **Update roadmap** based on backlog composition

---

## 📅 Follow-up

**Next Grooming Session:** [Recommended date, typically 1-2 weeks]

**Items Requiring Human Decision:**
- [List any features or decisions that need stakeholder input]

**Open Questions:**
- [List any questions raised during grooming]

---

## Appendix A: Feature Details

### Features Requiring User Input

[For each feature that required user interaction during grooming, capture the Q&A]

**FTR-####: {Title}**
- **Question Asked:** [The question posed to user]
- **User Response:** [What the user decided]
- **Action Taken:** [What was done as a result]

---

## Appendix B: Codebase Analysis Notes

[Technical notes discovered during codebase scanning]

**Architecture Changes:**
- [List relevant architecture changes since features were created]

**New Patterns Introduced:**
- [List new patterns that should be considered in backlog features]

**Deprecated Components:**
- [List deprecated code that affects backlog features]

---

**Report Generated By:** PM Agent (Backlog Grooming Command)
**Next Grooming Recommended:** {YYYY-MM-DD}
```

---

## 7. Execution Workflow

### Step-by-Step Process

1. **Initialize session:**
   ```
   🎯 Starting Backlog Grooming Session...
   Found {X} features in backlog. This may take some time.
   ```

2. **Process each feature** (show progress):
   ```
   [1/{X}] Analyzing FTR-#### "{title}"...
   ```

3. **Pause for user input** when needed (interactive prompts)

4. **Apply user decisions** immediately:
   - Move files between folders
   - Update frontmatter
   - Create new features if splitting
   - Archive features if decided

5. **Update feature index** after changes:
   ```bash
   vb index || ./scripts/ftr-index.sh
   ```

6. **Validate changes:**
   ```bash
   vb validate || ./scripts/ftr-validate.sh
   ```

7. **Generate final report** with all findings and recommendations

8. **Announce completion:**
   ```
   ✅ Backlog Grooming Complete!

   Summary:
   - {X} features reviewed
   - {Y} moved out of backlog
   - {Z} specs updated
   - {W} archived

   📄 Full report: reports/{YYYY-MM-DD}_Backlog_Grooming_Report.md

   ⚠️ Action required for {N} items - see report for details.
   ```

---

## 8. Implementation Notes

### Tools to Use

- **Codebase search:** Use `Grep` tool to search for implementation evidence
- **File operations:** Use `vb move` or `ftr-move.sh` for feature transitions
- **Validation:** Use `vb validate` or `ftr-validate.sh` after changes
- **User interaction:** Use `AskUserQuestion` tool for decision points
- **Report generation:** Use `Write` tool to create report file

### Best Practices

- **Be thorough but efficient:** Don't spend too long searching codebase per feature
- **Batch questions:** When possible, group multiple features with similar questions
- **Document everything:** Capture all decisions and rationale in the report
- **Update immediately:** Apply changes as you go, don't wait until end
- **Validate frequently:** Run validation after every 5-10 changes
- **Save progress:** Generate interim report if session is interrupted

### Error Handling

- If unable to determine implementation status → Ask user
- If feature move fails → Document in report, continue with others
- If validation fails → Note errors in report, don't block completion
- If codebase search is ambiguous → Present findings to user, let them decide

---

## 9. Create Reports Directory

- Ensure `reports/` directory exists before writing the report
- Use `mkdir -p reports` to create if necessary
- Name format: `{YYYY-MM-DD}_Backlog_Grooming_Report.md`

---

## 10. Follow-up Actions

After grooming session completes:

1. **Commit changes** (if git is being used):
   ```bash
   git add features/ reports/
   git commit -m "chore: backlog grooming session - {YYYY-MM-DD}

   - Reviewed {X} backlog features
   - Moved {Y} features to review/done
   - Updated {Z} feature specifications
   - Archived {W} obsolete features

   See reports/{YYYY-MM-DD}_Backlog_Grooming_Report.md for details"
   ```

2. **Share report** with stakeholders

3. **Schedule follow-up** for items requiring decisions

4. **Assign ready features** to development agents

5. **Update project roadmap** if priorities changed significantly

---

**Command Version:** 1.0
**Last Updated:** {YYYY-MM-DD}
**Maintained By:** PM Agent System
