CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.ec_funnel_pivot`(start_date DATE, end_date DATE) AS (
WITH steps AS (
    SELECT 1 AS step_number, 'session_start' AS step UNION ALL
    SELECT 2, 'view_item' UNION ALL
    SELECT 3, 'add_to_cart' UNION ALL
    SELECT 4, 'view_cart' UNION ALL
    SELECT 5, 'begin_checkout' UNION ALL
    SELECT 6, 'add_shipping_info' UNION ALL
    SELECT 7, 'add_payment_info' UNION ALL
    SELECT 8, 'purchase'
  ),

  funnel AS (
    SELECT
      session_date,
      client_id,
      session_id,
      session_channel_grouping,
      session_custom_channel_grouping,
      session_source,
      session_campaign_year,
      session_campaign_country,
      session_campaign_funnel_stage,
      session_campaign_platform,
      session_campaign_type,
      session_campaign_marketing_objective,
      session_campaign_name,
      session_campaign,
      session_device_type,
      session_country,
      replace(step, '_client_id', '') as step,
      step_client_id,
    FROM `tom-moretti.nameless_analytics.ec_funnel`(start_date, end_date)
    UNPIVOT INCLUDE NULLS (
      step_client_id FOR step IN (
        session_start_client_id,
        view_item_client_id,
        add_to_cart_client_id,
        view_cart_client_id,
        begin_checkout_client_id,
        add_shipping_info_client_id,
        add_payment_info_client_id,
        purchase_client_id
      )
    )
  ),
 
  sessions AS (
    SELECT DISTINCT
      session_date,
      client_id,
      session_id,
      session_channel_grouping,
      session_custom_channel_grouping,
      session_source,
      session_campaign_year,
      session_campaign_country,
      session_campaign_funnel_stage,
      session_campaign_platform,
      session_campaign_type,
      session_campaign_marketing_objective,
      session_campaign_name,
      session_campaign,
      session_device_type,
      session_country
    FROM funnel
  ),

  all_steps AS (
    SELECT
      sessions.*,
      steps.step_number,
      steps.step
    FROM sessions
    CROSS JOIN steps
  )

  SELECT
    all_steps.session_date,
    all_steps.client_id,
    all_steps.session_id,
    all_steps.session_channel_grouping,
    all_steps.session_custom_channel_grouping,
    all_steps.session_source,
    all_steps.session_campaign_year,
    all_steps.session_campaign_country,
    all_steps.session_campaign_funnel_stage,
    all_steps.session_campaign_platform,
    all_steps.session_campaign_type,
    all_steps.session_campaign_marketing_objective,
    all_steps.session_campaign_name,
    all_steps.session_campaign,
    all_steps.session_device_type,
    all_steps.session_country,
    all_steps.step_number,
    all_steps.step,
    funnel.step_client_id,
    funnel.step_client_id IS NOT NULL AS reached_step,
    LEAD(funnel.step_client_id) OVER (
      PARTITION BY all_steps.client_id, all_steps.session_id
      ORDER BY all_steps.step_number
    ) AS next_step_client_id
  FROM all_steps
  LEFT JOIN funnel
    ON all_steps.session_date = funnel.session_date
    AND all_steps.client_id = funnel.client_id
    AND all_steps.session_id = funnel.session_id
    AND all_steps.step = funnel.step
);