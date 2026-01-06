--sql
--This query approximates AI/ML‑related credits by day. If the AI‑related ACCOUNT_USAGE views are available in your account, you can also look at AI/ML‑related credits separately. This query intentionally does not merge these back into the totals above to avoid double‑counting; it’s meant as an additional lens.
--This query intentionally does not merge these back into the totals in the other queries to avoid double‑counting; it’s meant as an additional lens.
--BEST-EFFORT APPROXIMATION!!!!!!! NEEDS REFINEMENT!!!!
-- Approximation 3: AI/ML‑related credits by day (separate view)
WITH ai_ml_daily AS (
  -- Example: Cortex Search (if available)
  SELECT
    usage_date,
    'Cortex Search' AS service_name,
    SUM(credits)    AS credits_consumed
  FROM snowflake.account_usage.cortex_search_daily_usage_history
  WHERE usage_date >= DATEADD(day, -30, CURRENT_DATE())
  GROUP BY usage_date

  UNION ALL

  -- Example: AISQL (if available)
  SELECT
    DATE_TRUNC('day', usage_time) AS usage_date,
    'Cortex AISQL'                AS service_name,
    SUM(token_credits)            AS credits_consumed
  FROM snowflake.account_usage.cortex_aisql_usage_history
  WHERE usage_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
  GROUP BY DATE_TRUNC('day', usage_time)
)
SELECT
  usage_date,
  service_name,
  credits_consumed
FROM ai_ml_daily
WHERE credits_consumed > 0
ORDER BY usage_date DESC, credits_consumed DESC;