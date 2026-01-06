--sql
--This query approximates workloads by grouping METERING_DAILY_HISTORY.SERVICE_TYPE into coarse categories.
--BEST-EFFORT APPROXIMATION!!!!!!! NEEDS REFINEMENT!!!!
-- Approximation 1: Workloads by SERVICE_TYPE
WITH service_categorization AS (
  SELECT
    usage_date,
    service_type,
    CASE
      -- Data Engineering services
      WHEN service_type IN (
        'PIPE',                     -- Snowpipe
        'SNOWPIPE_STREAMING',
        'SERVERLESS_TASK',
        'AUTO_CLUSTERING',
        'DYNAMIC_TABLES',
        'MATERIALIZED_VIEW',
        'COPY_FILES'
      ) THEN 'Data Engineering'

      -- Analytics / general warehouse compute
      WHEN service_type = 'WAREHOUSE_METERING'
        THEN 'Analytics/Compute'

      -- Platform / governance / infra
      WHEN service_type IN (
        'CLOUD_SERVICES',
        'REPLICATION',
        'SEARCH_OPTIMIZATION',
        'SENSITIVE_DATA_CLASSIFICATION',
        'AUTOMATIC_CLUSTERING'
      ) THEN 'Platform'

      ELSE 'Other'
    END AS workload_category,
    SUM(credits_used_compute + COALESCE(credits_used_cloud_services, 0)) AS credits_consumed
  FROM snowflake.account_usage.metering_daily_history
  WHERE usage_date >= DATEADD(day, -30, CURRENT_DATE())
  GROUP BY usage_date, service_type
)
SELECT
  usage_date,
  workload_category,
  SUM(credits_consumed) AS daily_credits,
  ROUND(
    SUM(credits_consumed) * 100.0
    / NULLIF(SUM(SUM(credits_consumed)) OVER (PARTITION BY usage_date), 0),
    2
  ) AS pct_of_day
FROM service_categorization
GROUP BY usage_date, workload_category
ORDER BY usage_date DESC, daily_credits DESC;