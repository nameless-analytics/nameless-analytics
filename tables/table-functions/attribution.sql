CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.attribution_comparison`(start_date DATE, end_date DATE, lookback_days INT64) AS (
WITH all_attributions AS (
  -- 1. Last Click Puro
  SELECT session_source_cleaned AS source_medium, 1.0 AS weight, 'last_click' AS model 
  FROM `nameless_analytics.events_test`(start_date, end_date, 'event', lookback_days) 
  WHERE event_name = 'purchase'  -- Può essere 'purchase', 'generate_lead', ecc.

  UNION ALL

  -- 2. Last Click Non-Direct
  SELECT source_last_non_direct AS source_medium, 1.0 AS weight, 'last_non_direct' AS model 
  FROM `nameless_analytics.events_test`(start_date, end_date, 'event', lookback_days) 
  WHERE event_name = 'purchase'

  UNION ALL

  -- 3. First Click
  SELECT source_first_click AS source_medium, 1.0 AS weight, 'first_click' AS model 
  FROM `nameless_analytics.events_test`(start_date, end_date, 'event', lookback_days) 
  WHERE event_name = 'purchase'

  UNION ALL

  -- 4. Time Decay
  SELECT source_time_decay AS source_medium, weight_time_decay AS weight, 'time_decay' AS model 
  FROM `nameless_analytics.events_test`(start_date, end_date, 'event', lookback_days) 
  WHERE event_name = 'purchase'
)

SELECT 
  source_medium,
  ROUND(SUM(IF(model = 'last_click', weight, 0)), 2) AS conversioni_last_click,
  ROUND(SUM(IF(model = 'last_non_direct', weight, 0)), 2) AS conversioni_last_click_non_direct,
  ROUND(SUM(IF(model = 'first_click', weight, 0)), 2) AS conversioni_first_click,
  ROUND(SUM(IF(model = 'time_decay', weight, 0)), 2) AS conversioni_time_decay
FROM all_attributions
WHERE source_medium IS NOT NULL
GROUP BY 1
ORDER BY conversioni_last_click DESC
)