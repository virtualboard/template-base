# Generate Data Pipeline (GDP)

**Trigger Phrases:**
- "Generate Data Pipeline"
- "GDP"
- "Create data pipeline"
- "Build ETL pipeline"
- "Create data flow"

**Action:**
When the Data Engineer agent receives this command, it should:

## 1. Define Pipeline Scope
- Data source(s) and destination(s)
- Transformation requirements
- Schedule/trigger (batch, real-time, event-driven)
- Data volume and performance requirements
- Dependencies on other pipelines

### 2. Create Pipeline Structure

**Example Structure (Python/Airflow):**
```
src/pipelines/{pipeline_name}/
├── dag_{pipeline_name}.py           # Airflow DAG definition
├── extractors/
│   └── {source}_extractor.py        # Data extraction logic
├── transformers/
│   └── {name}_transformer.py        # Data transformation logic
├── loaders/
│   └── {destination}_loader.py      # Data loading logic
├── schemas/
│   └── {entity}_schema.py           # Data schemas/models
└── tests/
    └── test_{pipeline_name}.py      # Pipeline tests
```

**DAG Template:**
```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    '{pipeline_name}',
    default_args=default_args,
    description='{Pipeline description}',
    schedule_interval='@daily',  # or cron expression
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=['data-pipeline', '{domain}'],
) as dag:

    extract_task = PythonOperator(
        task_id='extract_data',
        python_callable=extract_data,
    )

    transform_task = PythonOperator(
        task_id='transform_data',
        python_callable=transform_data,
    )

    load_task = PythonOperator(
        task_id='load_data',
        python_callable=load_data,
    )

    quality_check_task = PythonOperator(
        task_id='quality_check',
        python_callable=run_quality_checks,
    )

    extract_task >> transform_task >> load_task >> quality_check_task
```

### 3. Add Data Quality Checks
```python
def run_quality_checks(data):
    checks = [
        ('row_count', lambda df: len(df) > 0),
        ('null_check', lambda df: df['critical_field'].notna().all()),
        ('value_range', lambda df: df['amount'].between(0, 1000000).all()),
        ('schema_check', lambda df: set(df.columns) == expected_columns),
    ]

    for check_name, check_func in checks:
        assert check_func(data), f"Quality check failed: {check_name}"
```

### 4. Create Documentation
Create docs at `.virtualboard/data/pipelines/{pipeline_name}.md`:

```markdown
# Pipeline: {Name}

## Overview
{Description of what this pipeline does}

## Data Flow
```
{Source} → [Extract] → [Transform] → [Load] → {Destination}
```

## Schedule
- **Frequency:** {daily/hourly/real-time}
- **Trigger:** {time/event}

## Data Sources
- **{Source 1}:** {Description}
- **{Source 2}:** {Description}

## Transformations
1. {Transformation description}
2. {Transformation description}

## Data Destinations
- **{Destination}:** {Description}

## Quality Checks
- Row count validation
- Null value checks
- Data type validation
- Business rule validation

## Dependencies
- Upstream: {Pipeline dependencies}
- Downstream: {Pipelines that depend on this}

## Monitoring
- **Alerts:** {Alert conditions}
- **Dashboard:** {Link to monitoring dashboard}
- **SLA:** {Expected completion time}

---

**Owner:** Data Engineering Team
**Last Updated:** {YYYY-MM-DD}
```

### 5. Announce Completion
- List files created
- Show DAG visualization
- Provide testing instructions

---

## Optional: Generate Branded HTML Report

If the user requests `--html`, "as HTML"/"branded HTML", or `format: html`,
write the Markdown deliverable first, then render an additional HTML report.

1. Read `templates/reports/html/data-pipeline-doc.html`. Its comment header lists the
   scalar fields and list-item shapes. Use the same findings and measurements
   as the Markdown report; do not invent values for unknown results.
2. Write a companion JSON data file with uppercase field names, native numbers,
   and arrays of objects for lists. Include every referenced field; use `""`,
   `null`, or `[]` for explicitly empty values. The default brand and raster logo
   are provided by the renderer.
3. Run the deterministic renderer:

   ```bash
   vb report render --template data-pipeline-doc.html \
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
