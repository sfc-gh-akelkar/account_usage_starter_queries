--sql
--This query approximates workloads by grouping QUERY_ATTRIBUTION_HISTORY.QUERY_TYPE into coarse categories.
--BEST-EFFORT APPROXIMATION!!!!!!! NEEDS REFINEMENT!!!!
SELECT
  DATE_TRUNC('day', qa.start_time) AS usage_date,
  CASE
    WHEN qh.query_type IN (
      'INSERT','UPDATE','DELETE','MERGE','COPY',
      'CREATE_TABLE_AS_SELECT','CREATE_STREAM','CREATE_TASK'
    ) THEN 'Data Engineering'

    WHEN qh.query_type IN ('SELECT','WITH','SHOW','DESCRIBE','EXPLAIN')
      THEN 'Analytics'

    WHEN qh.query_type IN ('CREATE','ALTER','DROP')
      THEN 'Platform'

    ELSE 'Other'
  END AS workload_category,
  SUM(qa.credits_attributed_compute)              AS total_credits,
  COUNT(DISTINCT qa.query_id)                     AS query_count,
  ROUND(AVG(qa.credits_attributed_compute), 6)    AS avg_credits_per_query,
  ROUND(MEDIAN(qa.credits_attributed_compute), 6) AS median_credits_per_query
FROM snowflake.account_usage.query_attribution_history AS qa
JOIN snowflake.account_usage.query_history AS qh
  ON qa.query_id = qh.query_id
WHERE qa.start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
  AND qa.credits_attributed_compute > 0
GROUP BY usage_date, workload_category
ORDER BY usage_date DESC, total_credits DESC;