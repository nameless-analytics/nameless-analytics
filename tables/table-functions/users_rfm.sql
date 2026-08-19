CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.users_rfm`(start_date DATE, end_date DATE, churn_window_days INT64, r_weight FLOAT64, f_weight FLOAT64, m_weight FLOAT64) AS (
WITH customers AS (
  SELECT
    # USER DATA
    user_id,
    client_id,
    customer_type,
    user_channel_grouping,
    user_custom_channel_grouping,
    user_source,
    user_campaign,
    user_campaign_id,
    user_device_type,
    user_country,
    user_city,

    # CUSTOMER DATA
    first_purchase_timestamp,
    last_purchase_timestamp,
    days_from_first_purchase,
    days_from_last_purchase,
    purchase,
    refund,
    purchase_net_refund,
    purchase_revenue,
    refund_revenue,
    revenue_net_refund,
    avg_order_value

  FROM `tom-moretti.nameless_analytics.users`(start_date, end_date)
  WHERE purchase > 0
),


customers_percentiles AS (
  SELECT
    *,

    # RECENCY
    # Lower days_from_last_purchase = better
    CASE
      WHEN COUNT(*) OVER () = 1 THEN 1.0
      ELSE PERCENT_RANK() OVER (ORDER BY days_from_last_purchase DESC)
    END AS r_percentile,

    # FREQUENCY
    # Higher purchase = better
    CASE
      WHEN COUNT(*) OVER () = 1 THEN 1.0
      ELSE PERCENT_RANK() OVER (ORDER BY purchase ASC)
    END AS f_percentile,

    # MONETARY
    # Higher revenue_net_refund = better
    CASE
      WHEN COUNT(*) OVER () = 1 THEN 1.0
      ELSE PERCENT_RANK() OVER (ORDER BY revenue_net_refund ASC)
    END AS m_percentile
  
  FROM customers
),


customers_scored AS (
  SELECT
    *,

    # RFM NORMALIZED SCORES 0-100
    r_percentile * 100.0 AS r_normalized,
    f_percentile * 100.0 AS f_normalized,
    m_percentile * 100.0 AS m_normalized,

    # RFM SCORES 1-5
    CAST(LEAST(5, FLOOR(r_percentile * 5) + 1) AS INT64) AS r_score,
    CAST(LEAST(5, FLOOR(f_percentile * 5) + 1) AS INT64) AS f_score,
    CAST(LEAST(5, FLOOR(m_percentile * 5) + 1) AS INT64) AS m_score
  
  FROM customers_percentiles
),


customers_rfm AS (
  SELECT
    *,

    # RFM CODE
    CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) AS rfm_code,

    # RFM WEIGHTED SCORE 0-5
    SAFE_DIVIDE((r_normalized * r_weight) + (f_normalized * f_weight) + (m_normalized * m_weight), r_weight + f_weight + m_weight) * 0.05 AS rfm_weighted_score
  
  FROM customers_scored
),


customers_segmented AS (
  SELECT
    *,

    # RFM VALUE SEGMENT
    CASE
      WHEN rfm_weighted_score >= 4.0 THEN '4 - Top'
      WHEN rfm_weighted_score >= 3.0 THEN '3 - High'
      WHEN rfm_weighted_score >= 2.0 THEN '2 - Regular'
      ELSE '1 - Low'
    END AS rfm_value_segment,

    # RFM BEHAVIORAL SEGMENT
    CASE
      # CHAMPIONS
      WHEN r_score >= 4 AND f_score >= 4 THEN '8 - Champions'

      # LOYAL CUSTOMERS
      WHEN r_score = 3 AND f_score >= 4 THEN '7 - Loyal Customers'

      # POTENTIAL LOYALISTS
      WHEN r_score >= 4 AND f_score BETWEEN 2 AND 3 THEN '6 - Potential Loyalists'

      # NEW CUSTOMERS
      WHEN r_score = 5 AND f_score = 1 THEN '5 - New Customers'

      # PROMISING
      WHEN r_score = 4 AND f_score = 1 THEN '4 - Promising'

      # NEEDS ATTENTION
      WHEN r_score BETWEEN 2 AND 3 AND f_score BETWEEN 2 AND 3 THEN '3 - Needs Attention'

      # AT RISK
      WHEN r_score <= 2 AND f_score >= 3 THEN '2 - At Risk'

      # HIBERNATING
      WHEN r_score <= 2 AND f_score <= 2 THEN '1 - Hibernating'

      # FALLBACK
      ELSE '3 - Needs Attention'
    END AS rfm_behavioral_segment,

    # CUSTOMER LIFECYCLE
    CASE
      WHEN days_from_last_purchase > churn_window_days THEN 'Churned' 
      ELSE 'Active'
    END AS customer_lifecycle_status

  FROM customers_rfm
)


SELECT
  # USER DATA
  user_id,
  client_id,
  customer_type,
  user_channel_grouping,
  user_custom_channel_grouping,
  user_source,
  user_campaign,
  user_campaign_id,
  user_device_type,
  user_country,
  user_city,

  # CUSTOMER DATA
  first_purchase_timestamp,
  last_purchase_timestamp,
  days_from_first_purchase,
  days_from_last_purchase,
  purchase,
  refund,
  purchase_net_refund,
  purchase_revenue,
  refund_revenue,
  revenue_net_refund,
  avg_order_value,

  # RFM PERCENTILES
  r_percentile,
  f_percentile,
  m_percentile,

  # RFM NORMALIZED SCORES
  r_normalized,
  f_normalized,
  m_normalized,

  # RFM SCORES
  r_score,
  f_score,
  m_score,
  rfm_code,

  # RFM VALUE
  rfm_weighted_score,
  rfm_value_segment,

  # RFM BEHAVIOR
  rfm_behavioral_segment,

  # CUSTOMER LIFECYCLE
  customer_lifecycle_status

FROM customers_segmented
);