# Generate Data Quality Check (GDQ)

**Trigger Phrases:**
- "Generate Data Quality Check"
- "GDQ"
- "Create data validation"
- "Quality rules"

**Action:**
When the Data Engineer agent receives this command, it should:

## 1. Analyze Data Sources
- Identify all data tables, files, or streams to validate
- Review data schema and expected formats
- Understand business rules and constraints
- Identify critical fields requiring validation
- Map data dependencies and relationships
- Review existing quality issues or known problems

### 2. Define Quality Check Rules

**Quality Check Categories:**

**Completeness Checks:**
- Null/missing value detection
- Required field validation
- Record count thresholds

**Accuracy Checks:**
- Data type validation
- Format validation (dates, emails, phone numbers)
- Range checks (min/max values)
- Reference data validation

**Consistency Checks:**
- Cross-field validation
- Referential integrity
- Duplicate detection
- Business rule validation

**Timeliness Checks:**
- Data freshness validation
- SLA compliance checks
- Lag time monitoring

### 3. Create Quality Check Implementation

**Directory Structure:**
```
src/data_quality/{domain}/
├── checks/
│   ├── completeness_checks.py
│   ├── accuracy_checks.py
│   ├── consistency_checks.py
│   └── timeliness_checks.py
├── rules/
│   └── {entity}_rules.yaml
├── reports/
│   └── quality_report_template.py
└── tests/
    └── test_quality_checks.py
```

**Quality Rules Template (YAML):**
```yaml
# {entity}_rules.yaml
entity: {EntityName}
description: Data quality rules for {entity}

rules:
  completeness:
    - name: required_fields_not_null
      description: Critical fields must not be null
      fields: [id, created_at, user_id, status]
      severity: critical

    - name: minimum_row_count
      description: Daily data must contain at least N records
      threshold: 1000
      severity: warning

  accuracy:
    - name: email_format_valid
      description: Email field must match valid email pattern
      field: email
      pattern: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
      severity: critical

    - name: amount_positive
      description: Amount values must be positive
      field: amount
      condition: value >= 0
      severity: critical

    - name: status_valid_values
      description: Status must be from allowed list
      field: status
      allowed_values: [pending, active, completed, cancelled]
      severity: critical

  consistency:
    - name: end_date_after_start_date
      description: End date must be after start date
      fields: [start_date, end_date]
      condition: end_date >= start_date
      severity: critical

    - name: referential_integrity_users
      description: User ID must exist in users table
      field: user_id
      reference_table: users
      reference_field: id
      severity: critical

    - name: no_duplicate_emails
      description: Email addresses must be unique
      field: email
      unique: true
      severity: warning

  timeliness:
    - name: data_freshness
      description: Data should not be older than 24 hours
      field: created_at
      max_age_hours: 24
      severity: warning
```

**Python Implementation Template:**
```python
# completeness_checks.py
from typing import List, Dict, Any
import pandas as pd
from datetime import datetime

class CompletenessChecker:
    """Checks for data completeness issues"""

    def __init__(self, rules: Dict[str, Any]):
        self.rules = rules
        self.results = []

    def check_required_fields(self, df: pd.DataFrame, fields: List[str]) -> Dict:
        """Verify required fields have no null values"""
        issues = []

        for field in fields:
            if field not in df.columns:
                issues.append({
                    'field': field,
                    'issue': 'field_missing',
                    'count': 'N/A'
                })
                continue

            null_count = df[field].isna().sum()
            if null_count > 0:
                issues.append({
                    'field': field,
                    'issue': 'null_values',
                    'count': null_count,
                    'percentage': (null_count / len(df)) * 100
                })

        return {
            'check': 'required_fields_not_null',
            'passed': len(issues) == 0,
            'total_rows': len(df),
            'issues': issues
        }

    def check_row_count(self, df: pd.DataFrame, threshold: int) -> Dict:
        """Verify minimum row count threshold"""
        row_count = len(df)
        passed = row_count >= threshold

        return {
            'check': 'minimum_row_count',
            'passed': passed,
            'actual_count': row_count,
            'threshold': threshold,
            'difference': row_count - threshold
        }


# accuracy_checks.py
import re

class AccuracyChecker:
    """Checks for data accuracy issues"""

    def check_format(self, df: pd.DataFrame, field: str, pattern: str) -> Dict:
        """Validate field matches expected format"""
        invalid_count = 0
        invalid_samples = []

        for idx, value in df[field].items():
            if pd.isna(value):
                continue
            if not re.match(pattern, str(value)):
                invalid_count += 1
                if len(invalid_samples) < 5:
                    invalid_samples.append(str(value))

        return {
            'check': f'{field}_format_valid',
            'passed': invalid_count == 0,
            'invalid_count': invalid_count,
            'invalid_percentage': (invalid_count / len(df)) * 100,
            'samples': invalid_samples
        }

    def check_range(self, df: pd.DataFrame, field: str, min_val=None, max_val=None) -> Dict:
        """Validate field values within expected range"""
        out_of_range = df[field].notna()

        if min_val is not None:
            out_of_range &= (df[field] < min_val)
        if max_val is not None:
            out_of_range &= (df[field] > max_val)

        violations = df[out_of_range]

        return {
            'check': f'{field}_range_check',
            'passed': len(violations) == 0,
            'violations': len(violations),
            'min_value': min_val,
            'max_value': max_val,
            'actual_min': df[field].min(),
            'actual_max': df[field].max()
        }
```

**SQL Quality Check Examples:**
```sql
-- Completeness: Check for null values in critical fields
SELECT
    'null_check' as check_name,
    COUNT(*) as failed_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) as failed_percentage
FROM orders
WHERE user_id IS NULL
   OR order_date IS NULL
   OR total_amount IS NULL;

-- Accuracy: Check for invalid email formats
SELECT
    'email_format' as check_name,
    COUNT(*) as failed_count
FROM users
WHERE email NOT LIKE '%@%.%';

-- Consistency: Check referential integrity
SELECT
    'referential_integrity' as check_name,
    COUNT(*) as failed_count
FROM orders o
LEFT JOIN users u ON o.user_id = u.id
WHERE u.id IS NULL;

-- Timeliness: Check data freshness
SELECT
    'data_freshness' as check_name,
    COUNT(*) as failed_count
FROM orders
WHERE created_at < NOW() - INTERVAL '24 hours';
```

### 4. Create Quality Report Template

**File Location:** `.virtualboard/reports/{YYYY-MM-DD}_Data_Quality_Report_{Entity}.md`

**Report Template:**
```markdown
# Data Quality Report: {Entity}

## Executive Summary
- **Report Date:** {YYYY-MM-DD HH:MM:SS}
- **Entity:** {EntityName}
- **Total Records:** {count}
- **Overall Quality Score:** {percentage}%
- **Status:** {PASS/FAIL}

## Quality Metrics

### Completeness (Weight: 30%)
| Check | Status | Pass Rate | Issues | Severity |
|-------|--------|-----------|--------|----------|
| Required Fields Not Null | ✅ PASS | 100% | 0 | Critical |
| Minimum Row Count | ✅ PASS | N/A | 0 | Warning |

**Completeness Score:** 100%

### Accuracy (Weight: 40%)
| Check | Status | Pass Rate | Issues | Severity |
|-------|--------|-----------|--------|----------|
| Email Format Valid | ❌ FAIL | 98.5% | 45 | Critical |
| Amount Positive | ✅ PASS | 100% | 0 | Critical |
| Status Valid Values | ⚠️ WARNING | 99.2% | 23 | Critical |

**Accuracy Score:** 98.9%

**Sample Issues:**
```
Invalid emails found:
- user@domain
- invalid.email@
- @nodomain.com
```

### Consistency (Weight: 20%)
| Check | Status | Pass Rate | Issues | Severity |
|-------|--------|-----------|--------|----------|
| End Date After Start | ✅ PASS | 100% | 0 | Critical |
| Referential Integrity | ❌ FAIL | 99.1% | 27 | Critical |
| No Duplicate Emails | ✅ PASS | 100% | 0 | Warning |

**Consistency Score:** 99.1%

### Timeliness (Weight: 10%)
| Check | Status | Pass Rate | Issues | Severity |
|-------|--------|-----------|--------|----------|
| Data Freshness | ✅ PASS | N/A | 0 | Warning |

**Timeliness Score:** 100%

## Failed Checks Detail

### Critical Issues (2)
1. **Email Format Validation**
   - Failed records: 45 (1.5%)
   - Impact: User communications may fail
   - Action: Validate and correct email formats

2. **Referential Integrity - User IDs**
   - Failed records: 27 (0.9%)
   - Impact: Orphaned records in orders table
   - Action: Clean up orphaned records or restore missing users

### Warnings (1)
1. **Status Valid Values**
   - Failed records: 23 (0.8%)
   - Impact: Unknown status values in system
   - Action: Map unknown statuses to valid values

## Trend Analysis
| Date | Overall Score | Critical Issues | Warnings |
|------|---------------|-----------------|----------|
| 2025-10-25 | 97.2% | 3 | 2 |
| 2025-10-28 | 98.1% | 2 | 1 |
| 2025-11-01 | 99.5% | 2 | 1 |

**Trend:** ✅ Improving

## Recommendations
1. **Immediate Actions:**
   - Fix email validation on data entry forms
   - Implement cascade delete for user records

2. **Short-term Improvements:**
   - Add database constraints for referential integrity
   - Implement real-time validation rules

3. **Long-term Strategy:**
   - Establish data quality SLAs
   - Automate quality monitoring and alerting

## Appendix
### Quality Check Configuration
- **Rules File:** `rules/{entity}_rules.yaml`
- **Check Scripts:** `checks/completeness_checks.py`, `checks/accuracy_checks.py`
- **Execution Time:** {duration} seconds

---

**Generated by:** Data Quality Framework v1.0
**Owner:** Data Engineering Team
**Next Check:** {next_scheduled_date}
```

### 5. Create Directory if Needed
If `.virtualboard/reports/` doesn't exist, create it along with the quality report file.

### 6. Announce Completion
- Total number of quality rules defined
- Number of critical vs warning checks
- Overall quality score achieved
- List of failed checks requiring immediate attention
- Path to generated quality report
- Recommendations for addressing quality issues

---

## Optional: Generate Branded HTML Report

If the user requests `--html`, "as HTML"/"branded HTML", or `format: html`,
write the Markdown deliverable first, then render an additional HTML report.

1. Read `templates/reports/html/data-quality-report.html`. Its comment header lists the
   scalar fields and list-item shapes. Use the same findings and measurements
   as the Markdown report; do not invent values for unknown results.
2. Write a companion JSON data file with uppercase field names, native numbers,
   and arrays of objects for lists. Include every referenced field; use `""`,
   `null`, or `[]` for explicitly empty values. The default brand and raster logo
   are provided by the renderer.
3. Run the deterministic renderer:

   ```bash
   vb report render --template data-quality-report.html \
     --data REPORT_DATA.json --output REPORT.html
   ```

   Replace the example paths with paths beside the Markdown deliverable, using
   the same basename for `.md`, `.json`, and `.html`. Includes and repeated
   blocks are resolved by the CLI; do not manually substitute template text.
4. Strings are escaped, including `*_HTML` fields. Annotate reviewed markup as
   `{"html":"<p>Reviewed content</p>"}` and add `--allow-html` only when those
   fragments are intended as markup. Supply `*_JSON` fields as native JSON
   values; the renderer safely serializes them in inline scripts.
5. Validate with `--dry-run` if useful, then inspect the generated HTML. Existing
   output requires `--force`; a rendering error must preserve earlier output.
   If the installed CLI lacks `report render`, report that limitation instead
   of claiming an HTML artifact was produced.
6. List the Markdown and HTML paths in the final reply, with the companion JSON
   path so the report can be reproduced.

See `templates/reports/README.md` for the input contract and the runnable
`templates/reports/examples/pm-progress-report.data.json` for a complete example.
