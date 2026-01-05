# Product Categories / Workload Approximation Queries

Sample queries to approximate Snowflake "Product Category" or "Workload" views using the public `SNOWFLAKE.ACCOUNT_USAGE` schema.

## ⚠️ Important Disclaimer

The Product Category dashboards and workload views you may have seen are powered by **internal telemetry and classification pipelines** that use additional metadata not exposed in the public `ACCOUNT_USAGE` views. 

**These queries are best-effort approximations.** They will not exactly match the official Product Categories or workload views, but they provide a reproducible and transparent starting point for understanding how credits are distributed across different types of workloads in your account.

---

## Queries Included

| File | Purpose | Data Source |
|------|---------|-------------|
| `Workloads by service type (high-level split).sql` | High-level workload split by service type | `METERING_DAILY_HISTORY` |
| `Query-level workloads (warehouse compute only).sql` | Warehouse compute attributed to query types | `QUERY_ATTRIBUTION_HISTORY` + `QUERY_HISTORY` |
| `ML-specific view (separate lens).sql` | AI/ML credit consumption (separate lens) | Cortex-specific views |

---

## Query Details

### 1. Workloads by Service Type (High-Level Split)

**Best for:** Quick, high-level view of where credits are being consumed across the platform.

This query categorizes `SERVICE_TYPE` values from `METERING_DAILY_HISTORY` into workload buckets:

| Category | SERVICE_TYPE Values |
|----------|---------------------|
| Data Engineering | `PIPE`, `SNOWPIPE_STREAMING`, `SERVERLESS_TASK`, `AUTO_CLUSTERING`, `DYNAMIC_TABLES`, `MATERIALIZED_VIEW`, `COPY_FILES` |
| Analytics/Compute | `WAREHOUSE_METERING` |
| Platform | `CLOUD_SERVICES`, `REPLICATION`, `SEARCH_OPTIMIZATION`, `SENSITIVE_DATA_CLASSIFICATION` |
| Other | Everything else |

**Output columns:**
- `usage_date` — Day of usage
- `workload_category` — Mapped category
- `daily_credits` — Total credits consumed
- `pct_of_day` — Percentage of that day's total consumption

---

### 2. Query-Level Workloads (Warehouse Compute Only)

**Best for:** Understanding how warehouse compute is distributed across query types.

This query joins `QUERY_ATTRIBUTION_HISTORY` with `QUERY_HISTORY` to attribute warehouse credits to specific query types:

| Category | QUERY_TYPE Values |
|----------|-------------------|
| Data Engineering | `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `COPY`, `CREATE_TABLE_AS_SELECT`, `CREATE_STREAM`, `CREATE_TASK` |
| Analytics | `SELECT`, `WITH`, `SHOW`, `DESCRIBE`, `EXPLAIN` |
| Platform | `CREATE`, `ALTER`, `DROP` |
| Other | Everything else |

**Output columns:**
- `usage_date` — Day of usage
- `workload_category` — Mapped category
- `total_credits` — Sum of attributed compute credits
- `query_count` — Number of queries
- `avg_credits_per_query` — Average credit cost per query
- `median_credits_per_query` — Median credit cost per query

---

### 3. AI/ML-Specific View (Separate Lens)

**Best for:** Tracking AI/ML credit consumption from Cortex services.

This query pulls from AI-specific `ACCOUNT_USAGE` views:
- `CORTEX_SEARCH_DAILY_USAGE_HISTORY` — Cortex Search credits
- `CORTEX_AISQL_USAGE_HISTORY` — Cortex AI SQL functions (COMPLETE, TRANSLATE, etc.)

> **Note:** This query is intentionally kept separate to avoid double-counting. Use it as an additional lens alongside the other queries, not merged into them.

**You can extend this query** to include other AI/ML views if available in your account:
- `CORTEX_ANALYST_USAGE_HISTORY` — Cortex Analyst
- `DOCUMENT_AI_USAGE_HISTORY` — Document AI
- `NOTEBOOKS_CONTAINER_RUNTIME_HISTORY` — Snowflake Notebooks on Container Runtime

---

## Prerequisites

These queries require:

```sql
USE ROLE ACCOUNTADMIN;  -- Or a role with IMPORTED PRIVILEGES on SNOWFLAKE database
USE SCHEMA SNOWFLAKE.ACCOUNT_USAGE;
```

---

## Customization Recommendations

These queries are starting points. To align them with how your teams think about workloads:

### 1. Adjust SERVICE_TYPE Mappings

Edit the `CASE` statements to match your organization's definitions:

```sql
-- Example: Move MATERIALIZED_VIEW to Analytics instead of Data Engineering
WHEN service_type = 'MATERIALIZED_VIEW' THEN 'Analytics'
```

### 2. Add QUERY_TAG Conventions

If your teams use query tags, you can add classification rules:

```sql
WHEN UPPER(qh.query_tag) LIKE '%ETL%' THEN 'Data Engineering'
WHEN UPPER(qh.query_tag) LIKE '%REPORT%' THEN 'Analytics'
WHEN UPPER(qh.query_tag) LIKE '%LOOKER%' THEN 'BI Tools'
```

### 3. Extend the AI/ML View

Add more Cortex/AI views as they become available:

```sql
UNION ALL

SELECT
  DATE_TRUNC('day', start_time) AS usage_date,
  'Cortex Analyst' AS service_name,
  SUM(credits) AS credits_consumed
FROM snowflake.account_usage.cortex_analyst_usage_history
WHERE start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
GROUP BY 1
```

---

## Known Limitations

| Limitation | Details |
|------------|---------|
| **Not a 1:1 match** | These queries approximate but do not reproduce the internal Product Category classifications |
| **Warehouse classification is coarse** | All warehouse compute defaults to "Analytics/Compute" unless you add query-level logic |
| **AI/ML views may not exist** | Some Cortex views are only populated if you're using those features |
| **Data latency** | ACCOUNT_USAGE views have up to 45 min – 3 hour latency |
| **Retention** | Most views retain 365 days of data |

---

## Questions?

For questions about these queries or help customizing them for your environment, reach out to your Snowflake account team.

