# Generate Metrics Dashboard (GMD)

**Trigger Phrases:**
- "Generate Metrics Dashboard"
- "GMD"
- "Create dashboard"
- "Build analytics dashboard"

**Action:**
When the Data Engineer agent receives this command, it should:

## 1. Identify Dashboard Requirements
- Define target audience (executives, managers, analysts, engineers)
- Determine key metrics and KPIs to track
- Identify data sources for metrics
- Define refresh frequency (real-time, hourly, daily)
- Understand business questions the dashboard should answer
- Review existing analytics and reporting gaps

### 2. Define Metrics and KPIs

**Metric Categories:**

**Business Metrics:**
- Revenue and financial KPIs
- Customer acquisition/retention
- Conversion rates
- Growth metrics

**Operational Metrics:**
- System performance
- Service level indicators
- Processing throughput
- Error rates

**User Metrics:**
- Active users (DAU/MAU/WAU)
- User engagement
- Feature adoption
- User satisfaction

**Data Quality Metrics:**
- Pipeline success rates
- Data freshness
- Quality check pass rates
- Processing latency

### 3. Create Dashboard Structure

**Directory Structure:**
```
src/dashboards/{dashboard_name}/
├── config/
│   └── dashboard_config.yaml
├── metrics/
│   ├── metric_definitions.yaml
│   ├── business_metrics.py
│   ├── operational_metrics.py
│   └── user_metrics.py
├── queries/
│   ├── metric_queries.sql
│   └── aggregations.sql
├── visualizations/
│   └── chart_configs.json
└── components/  # For web-based dashboards
    ├── Dashboard.tsx
    ├── MetricCard.tsx
    └── ChartWidget.tsx
```

**Dashboard Configuration (YAML):**
```yaml
# dashboard_config.yaml
dashboard:
  name: Executive Business Dashboard
  description: High-level business metrics and KPIs
  owner: Data Team
  audience: Executive Leadership
  refresh_rate: 1h
  retention_days: 90

layout:
  grid:
    columns: 12
    rows: auto
    gap: 16

sections:
  - name: Key Performance Indicators
    position: { row: 1, col: 1, span: 12 }
    widgets:
      - id: total_revenue
        type: metric_card
        size: { cols: 3, rows: 1 }
      - id: active_users
        type: metric_card
        size: { cols: 3, rows: 1 }
      - id: conversion_rate
        type: metric_card
        size: { cols: 3, rows: 1 }
      - id: avg_order_value
        type: metric_card
        size: { cols: 3, rows: 1 }

  - name: Trends
    position: { row: 2, col: 1, span: 12 }
    widgets:
      - id: revenue_trend
        type: line_chart
        size: { cols: 6, rows: 2 }
      - id: user_growth
        type: area_chart
        size: { cols: 6, rows: 2 }

  - name: Detailed Analytics
    position: { row: 4, col: 1, span: 12 }
    widgets:
      - id: revenue_by_category
        type: bar_chart
        size: { cols: 6, rows: 2 }
      - id: user_segments
        type: pie_chart
        size: { cols: 6, rows: 2 }

filters:
  - name: date_range
    type: date_range
    default: last_30_days
    options: [today, last_7_days, last_30_days, last_90_days, custom]

  - name: region
    type: multi_select
    default: all
    options: [all, north_america, europe, asia, latin_america]
```

**Metric Definitions (YAML):**
```yaml
# metric_definitions.yaml
metrics:
  - id: total_revenue
    name: Total Revenue
    description: Sum of all completed order amounts
    category: business
    format: currency
    precision: 2
    calculation:
      type: aggregation
      function: sum
      field: order_amount
      filters:
        - status: completed
    targets:
      warning: 900000
      goal: 1000000
    trend:
      comparison: previous_period
      display: percentage_change

  - id: active_users
    name: Monthly Active Users
    description: Unique users with activity in the last 30 days
    category: user
    format: number
    calculation:
      type: distinct_count
      field: user_id
      timeframe: last_30_days
      filters:
        - event_type: [login, page_view, action]
    targets:
      warning: 45000
      goal: 50000

  - id: conversion_rate
    name: Conversion Rate
    description: Percentage of visitors who make a purchase
    category: business
    format: percentage
    precision: 2
    calculation:
      type: ratio
      numerator:
        function: count
        field: order_id
        filters:
          - status: completed
      denominator:
        function: distinct_count
        field: session_id
    targets:
      warning: 2.5
      goal: 3.0

  - id: avg_response_time
    name: Average API Response Time
    description: Mean response time for API requests
    category: operational
    format: duration
    unit: ms
    calculation:
      type: aggregation
      function: avg
      field: response_time_ms
      filters:
        - endpoint_type: api
    targets:
      warning: 200
      goal: 150
```

**SQL Queries for Metrics:**
```sql
-- queries/metric_queries.sql

-- Total Revenue
SELECT
    DATE_TRUNC('day', order_date) as date,
    SUM(total_amount) as total_revenue,
    COUNT(*) as order_count,
    AVG(total_amount) as avg_order_value
FROM orders
WHERE status = 'completed'
    AND order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', order_date)
ORDER BY date;

-- Active Users by Day
SELECT
    DATE_TRUNC('day', event_timestamp) as date,
    COUNT(DISTINCT user_id) as daily_active_users,
    COUNT(*) as total_events
FROM user_events
WHERE event_timestamp >= CURRENT_DATE - INTERVAL '90 days'
    AND event_type IN ('login', 'page_view', 'action')
GROUP BY DATE_TRUNC('day', event_timestamp)
ORDER BY date;

-- Conversion Funnel
SELECT
    funnel_step,
    COUNT(DISTINCT user_id) as users,
    COUNT(DISTINCT user_id) * 100.0 / FIRST_VALUE(COUNT(DISTINCT user_id))
        OVER (ORDER BY step_order) as conversion_rate
FROM (
    SELECT user_id, 'landing' as funnel_step, 1 as step_order
    FROM page_views WHERE page = 'home'
    UNION ALL
    SELECT user_id, 'product_view' as funnel_step, 2 as step_order
    FROM page_views WHERE page LIKE 'product/%'
    UNION ALL
    SELECT user_id, 'add_to_cart' as funnel_step, 3 as step_order
    FROM events WHERE event_type = 'add_to_cart'
    UNION ALL
    SELECT user_id, 'checkout' as funnel_step, 4 as step_order
    FROM events WHERE event_type = 'checkout_started'
    UNION ALL
    SELECT user_id, 'purchase' as funnel_step, 5 as step_order
    FROM orders WHERE status = 'completed'
) funnel
GROUP BY funnel_step, step_order
ORDER BY step_order;
```

**Python Metric Calculation Example:**
```python
# metrics/business_metrics.py
from typing import Dict, Any, List
import pandas as pd
from datetime import datetime, timedelta

class BusinessMetrics:
    """Calculate business metrics and KPIs"""

    def __init__(self, db_connection):
        self.db = db_connection

    def calculate_revenue_metrics(self, start_date: str, end_date: str) -> Dict[str, Any]:
        """Calculate revenue-related metrics"""
        query = """
            SELECT
                SUM(total_amount) as total_revenue,
                COUNT(*) as order_count,
                AVG(total_amount) as avg_order_value,
                COUNT(DISTINCT user_id) as unique_customers
            FROM orders
            WHERE status = 'completed'
                AND order_date BETWEEN %s AND %s
        """

        result = self.db.execute(query, (start_date, end_date))
        current = result.fetchone()

        # Calculate previous period for comparison
        date_diff = (datetime.fromisoformat(end_date) -
                    datetime.fromisoformat(start_date)).days
        prev_start = (datetime.fromisoformat(start_date) -
                     timedelta(days=date_diff)).isoformat()
        prev_end = start_date

        prev_result = self.db.execute(query, (prev_start, prev_end))
        previous = prev_result.fetchone()

        return {
            'total_revenue': {
                'value': float(current['total_revenue'] or 0),
                'previous': float(previous['total_revenue'] or 0),
                'change_percent': self._calculate_change(
                    current['total_revenue'],
                    previous['total_revenue']
                ),
                'trend': 'up' if current['total_revenue'] > previous['total_revenue'] else 'down'
            },
            'order_count': {
                'value': int(current['order_count'] or 0),
                'previous': int(previous['order_count'] or 0),
            },
            'avg_order_value': {
                'value': float(current['avg_order_value'] or 0),
                'previous': float(previous['avg_order_value'] or 0),
            }
        }

    def calculate_user_metrics(self, days: int = 30) -> Dict[str, Any]:
        """Calculate user engagement metrics"""
        query = """
            SELECT
                COUNT(DISTINCT CASE
                    WHEN event_timestamp >= CURRENT_DATE - INTERVAL '1 day'
                    THEN user_id END) as dau,
                COUNT(DISTINCT CASE
                    WHEN event_timestamp >= CURRENT_DATE - INTERVAL '7 days'
                    THEN user_id END) as wau,
                COUNT(DISTINCT CASE
                    WHEN event_timestamp >= CURRENT_DATE - INTERVAL '30 days'
                    THEN user_id END) as mau
            FROM user_events
        """

        result = self.db.execute(query).fetchone()

        return {
            'dau': int(result['dau'] or 0),
            'wau': int(result['wau'] or 0),
            'mau': int(result['mau'] or 0),
            'stickiness': {
                'dau_mau': round((result['dau'] / result['mau'] * 100), 2) if result['mau'] else 0,
                'dau_wau': round((result['dau'] / result['wau'] * 100), 2) if result['wau'] else 0,
            }
        }

    @staticmethod
    def _calculate_change(current: float, previous: float) -> float:
        """Calculate percentage change between two values"""
        if not previous or previous == 0:
            return 0
        return round(((current - previous) / previous) * 100, 2)
```

**React Dashboard Component Example:**
```typescript
// components/Dashboard.tsx
import React, { useEffect, useState } from 'react';
import { MetricCard } from './MetricCard';
import { ChartWidget } from './ChartWidget';
import { fetchDashboardData } from '../api/metrics';

interface DashboardProps {
  dashboardId: string;
  dateRange: string;
}

export const Dashboard: React.FC<DashboardProps> = ({ dashboardId, dateRange }) => {
  const [metrics, setMetrics] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      const data = await fetchDashboardData(dashboardId, dateRange);
      setMetrics(data);
      setLoading(false);
    };

    loadData();
    const interval = setInterval(loadData, 300000); // Refresh every 5 minutes

    return () => clearInterval(interval);
  }, [dashboardId, dateRange]);

  if (loading) return <div>Loading dashboard...</div>;

  return (
    <div className="dashboard-container">
      <h1>Executive Business Dashboard</h1>

      <section className="kpi-section">
        <MetricCard
          title="Total Revenue"
          value={metrics.total_revenue.value}
          format="currency"
          trend={metrics.total_revenue.change_percent}
          target={1000000}
        />
        <MetricCard
          title="Active Users"
          value={metrics.active_users.value}
          format="number"
          trend={metrics.active_users.change_percent}
          target={50000}
        />
        <MetricCard
          title="Conversion Rate"
          value={metrics.conversion_rate.value}
          format="percentage"
          trend={metrics.conversion_rate.change_percent}
          target={3.0}
        />
      </section>

      <section className="charts-section">
        <ChartWidget
          title="Revenue Trend"
          type="line"
          data={metrics.revenue_trend}
          xAxis="date"
          yAxis="revenue"
        />
        <ChartWidget
          title="User Growth"
          type="area"
          data={metrics.user_growth}
          xAxis="date"
          yAxis="users"
        />
      </section>
    </div>
  );
};
```

### 4. Create Dashboard Documentation

**File Location:** `.virtualboard/dashboards/{dashboard_name}/README.md`

**Dashboard Documentation Template:**
```markdown
# Dashboard: {Dashboard Name}

## Overview
**Purpose:** {What business questions does this dashboard answer}
**Audience:** {Who is this dashboard for}
**Refresh Rate:** {How often data updates}
**Owner:** Data Engineering Team

## Key Metrics

### Business KPIs
| Metric | Description | Target | Data Source |
|--------|-------------|--------|-------------|
| Total Revenue | Sum of completed orders | $1M/month | orders table |
| Conversion Rate | % of visitors who purchase | 3.0% | orders + sessions |
| Average Order Value | Mean order amount | $75 | orders table |
| Customer LTV | Lifetime value per customer | $500 | orders + users |

### User Engagement
| Metric | Description | Target | Data Source |
|--------|-------------|--------|-------------|
| Daily Active Users | Unique users per day | 10K | user_events |
| Monthly Active Users | Unique users per month | 50K | user_events |
| DAU/MAU Ratio | User stickiness | 20% | calculated |
| Session Duration | Avg time per session | 8 min | sessions |

### Operational Metrics
| Metric | Description | Target | Data Source |
|--------|-------------|--------|-------------|
| API Response Time | Mean API latency | <150ms | api_logs |
| Error Rate | % of failed requests | <0.5% | api_logs |
| Data Pipeline SLA | % on-time completions | >99% | pipeline_runs |

## Visualizations

### Revenue Trend (Line Chart)
- **Type:** Time series line chart
- **X-Axis:** Date (daily)
- **Y-Axis:** Revenue amount ($)
- **Time Range:** Last 90 days
- **Annotations:** Target line, month boundaries

### User Growth (Area Chart)
- **Type:** Stacked area chart
- **Metrics:** DAU, WAU, MAU
- **Time Range:** Last 90 days
- **Colors:** Blue gradient

### Conversion Funnel (Funnel Chart)
- **Stages:** Landing → Product View → Cart → Checkout → Purchase
- **Metric:** Count of users at each stage
- **Display:** Percentage conversion rate

### Revenue by Category (Bar Chart)
- **Type:** Horizontal bar chart
- **Dimension:** Product category
- **Metric:** Total revenue
- **Sort:** Descending by revenue

## Filters and Parameters

### Global Filters
- **Date Range:** Preset or custom date range
- **Region:** Multi-select (All, North America, Europe, Asia)
- **User Segment:** Single-select (All, New, Returning, VIP)

### Drill-Down Capabilities
- Click on chart elements to filter other widgets
- Click on metric cards to view detailed breakdown
- Export capabilities for all visualizations

## Data Sources

### Primary Tables
```sql
-- Orders data
orders (id, user_id, total_amount, status, order_date, region)

-- User events
user_events (id, user_id, event_type, event_timestamp, properties)

-- Sessions
sessions (id, user_id, start_time, end_time, page_views)
```

### Data Refresh
- **Orders:** Real-time (stream processing)
- **User Events:** Real-time (stream processing)
- **Aggregated Metrics:** Hourly batch job
- **Historical Trends:** Daily batch job

## Technical Implementation

### Technology Stack
- **Backend:** Python + FastAPI
- **Database:** PostgreSQL
- **Caching:** Redis
- **Frontend:** React + TypeScript
- **Charts:** Recharts / Chart.js
- **Deployment:** Docker + Kubernetes

### API Endpoints
```
GET /api/dashboards/{dashboard_id}/metrics?date_range={range}
GET /api/dashboards/{dashboard_id}/chart/{chart_id}?filters={filters}
POST /api/dashboards/{dashboard_id}/export
```

### Performance Considerations
- Metrics cached for 5 minutes
- Pre-aggregated tables for historical data
- Materialized views for complex calculations
- Pagination for large datasets

## Access and Permissions
- **View Access:** All employees
- **Edit Access:** Data Team
- **Admin Access:** Data Engineering Lead

## Maintenance

### Regular Tasks
- Weekly: Review metric accuracy
- Monthly: Update targets and benchmarks
- Quarterly: Add new metrics based on feedback

### Known Issues
- {List any current limitations or known issues}

### Future Enhancements
- [ ] Add predictive forecasting
- [ ] Implement anomaly detection alerts
- [ ] Add export to PDF feature
- [ ] Create mobile-responsive version

---

**Last Updated:** {YYYY-MM-DD}
**Version:** 1.0
**Contact:** data-team@company.com
```

### 5. Create Directory if Needed
If `.virtualboard/dashboards/{dashboard_name}/` doesn't exist, create it along with all configuration files, metric definitions, and documentation.

### 6. Announce Completion
- Total number of metrics defined
- Number of visualizations created
- List of dashboard sections and widgets
- Data sources connected
- Path to dashboard configuration and documentation
- URL to access the dashboard (if deployed)
- Instructions for customization and maintenance
