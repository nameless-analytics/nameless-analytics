/* @datacloud.settings
{
  "version": 1,
  "service": "BIG_QUERY",
  "connectionInfo": {
    "billingProjectId": "INHERIT",
    "location": "INHERIT"
  },
  "dialect": "GOOGLE_SQL"
}
*/

declare project_name string default 'PROJECT NAME';  -- Change this
declare dataset_name string default 'nameless_analytics';

declare ec_funnel_pivot string default format ("""
CREATE OR REPLACE TABLE FUNCTION `%s.%s.ec_funnel_pivot`(start_date DATE, end_date DATE) AS (
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
    session_campaign_id,
    session_campaign_click_id,
    session_campaign_term,
    session_campaign_content,
    session_device_type,
    session_city,
    session_country,
    replace(step, '_client_id', '') as step,
    step_client_id
  FROM `%s.%s.ec_funnel`(start_date, end_date)
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
)

SELECT
  funnel.session_date,
  funnel.client_id,
  funnel.session_id,
  funnel.session_channel_grouping,
  funnel.session_custom_channel_grouping,
  funnel.session_source,
  funnel.session_campaign_year,
  funnel.session_campaign_country,
  funnel.session_campaign_funnel_stage,
  funnel.session_campaign_platform,
  funnel.session_campaign_type,
  funnel.session_campaign_marketing_objective,
  funnel.session_campaign_name,
  funnel.session_campaign,
  funnel.session_campaign_id,
  funnel.session_campaign_click_id,
  funnel.session_campaign_term,
  funnel.session_campaign_content,
  funnel.session_device_type,
  funnel.session_city,
  funnel.session_country,
  steps.step_number,
  funnel.step,
  funnel.step_client_id,
  funnel.step_client_id IS NOT NULL AS reached_step,

  lead(funnel.step_client_id) over (
    partition by funnel.client_id, funnel.session_id
    order by steps.step_number
  ) as next_step_client_id

FROM funnel
JOIN steps
  ON funnel.step = steps.step
);
""", project_name, dataset_name, project_name, dataset_name);

execute immediate ec_funnel_pivot;
