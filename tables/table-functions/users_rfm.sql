CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.users_rfm`(start_date DATE, end_date DATE, churn_window_days INT64) AS (
WITH customers AS (
  SELECT
    client_id,
    days_from_last_purchase,
    purchase,
    revenue_net_refund,
    purchase_revenue
  FROM `tom-moretti.nameless_analytics.users`(start_date, end_date)
  WHERE purchase > 0
),

customers_ranked AS (
  SELECT
    customers.*,
    DENSE_RANK() OVER (ORDER BY days_from_last_purchase ASC) AS r_rank,
    DENSE_RANK() OVER (ORDER BY purchase DESC) AS f_rank,
    DENSE_RANK() OVER (ORDER BY revenue_net_refund DESC) AS m_rank
  FROM customers
),

customers_normalized_ranked AS (
  SELECT
    customers_ranked.*,
    MAX(r_rank) OVER () AS r_max,
    MAX(f_rank) OVER () AS f_max,
    MAX(m_rank) OVER () AS m_max
  FROM customers_ranked
),

customers_normalized_ranked_scored AS (
  SELECT
    client_id,
    days_from_last_purchase,
    purchase,
    revenue_net_refund,
    purchase_revenue,

    -- Normalized score 0–100
    ((r_max - r_rank + 1) / r_max) * 100.0 AS R_normalized,
    ((f_max - f_rank + 1) / f_max) * 100.0 AS F_normalized,
    ((m_max - m_rank + 1) / m_max) * 100.0 AS M_normalized,

    -- Weighted score 0–5
    (
      0.15 * ((r_max - r_rank + 1) / r_max) * 100.0
      + 0.28 * ((f_max - f_rank + 1) / f_max) * 100.0
      + 0.57 * ((m_max - m_rank + 1) / m_max) * 100.0
    ) * 0.05 AS RFM_weighted_score

  FROM customers_normalized_ranked
)

SELECT
  client_id,
  days_from_last_purchase,
  purchase,
  revenue_net_refund,
  purchase_revenue,
  R_normalized, 
  F_normalized, 
  M_normalized,
  RFM_weighted_score,
  CASE
    WHEN days_from_last_purchase > churn_window_days THEN '0 - Churned'
    WHEN RFM_weighted_score >= 4.0 THEN '4 - Top'
    WHEN RFM_weighted_score >= 3.0 THEN '3 - High'
    WHEN RFM_weighted_score >= 2.0 THEN '2 - Regular'
    WHEN RFM_weighted_score >  0.0 THEN '1 - Low'
  END AS RFM_segment
FROM customers_normalized_ranked_scored
);