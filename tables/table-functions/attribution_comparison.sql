CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.attribution_comparison`(start_date DATE, end_date DATE, conversion_name STRING, lookback_days INT64) AS (
with attribution_data_single_touch as (
    select * from `tom-moretti.nameless_analytics.attribution_single_touch`(start_date, end_date, conversion_name, lookback_days)
  ),

  -- attribution_data_multi_touch as (
  --   select * from `tom-moretti.nameless_analytics.attribution_single_touch`(start_date, end_date, ['purchase', 'newsletter_subscription', 'form_submit', 'sign_up'], lookback_days)
  -- ),

  attribution_models as (
    # FIRST CLICK
    select
      first_click_channel_grouping as session_channel_grouping,
      first_click_custom_channel_grouping as session_custom_channel_grouping,
      first_click_source as session_source,
      first_click_campaign_year as session_campaign_year,
      first_click_campaign_country as session_campaign_country,
      first_click_campaign_funnel_stage as session_campaign_funnel_stage,
      first_click_campaign_platform as session_campaign_platform,
      first_click_campaign_type as session_campaign_type,
      first_click_campaign_marketing_objective as session_campaign_marketing_objective,
      first_click_campaign_name as session_campaign_name,
      first_click_campaign as session_campaign,
      first_click_campaign_id as session_campaign_id,
      first_click_campaign_click_id as session_campaign_click_id,
      first_click_campaign_term as session_campaign_term,
      first_click_campaign_content as session_campaign_content,
      conversion_id,
      conversion_name,
      conversion_revenue,
      'first_click' as attribution_model
    from attribution_data_single_touch

    union all

    # LAST CLICK
    select
      last_click_channel_grouping as session_channel_grouping,
      last_click_custom_channel_grouping as session_custom_channel_grouping,
      last_click_source as session_source,
      last_click_campaign_year as session_campaign_year,
      last_click_campaign_country as session_campaign_country,
      last_click_campaign_funnel_stage as session_campaign_funnel_stage,
      last_click_campaign_platform as session_campaign_platform,
      last_click_campaign_type as session_campaign_type,
      last_click_campaign_marketing_objective as session_campaign_marketing_objective,
      last_click_campaign_name as session_campaign_name,
      last_click_campaign as session_campaign,
      last_click_campaign_id as session_campaign_id,
      last_click_campaign_click_id as session_campaign_click_id,
      last_click_campaign_term as session_campaign_term,
      last_click_campaign_content as session_campaign_content,
      conversion_id,
      conversion_name,
      conversion_revenue,
      'last_click' as attribution_model
    from attribution_data_single_touch

    union all

    # LAST CLICK NON-DIRECT
    select
      last_click_non_direct_channel_grouping as session_channel_grouping,
      last_click_non_direct_custom_channel_grouping as session_custom_channel_grouping,
      last_click_non_direct_source as session_source,
      last_click_non_direct_campaign_year as session_campaign_year,
      last_click_non_direct_campaign_country as session_campaign_country,
      last_click_non_direct_campaign_funnel_stage as session_campaign_funnel_stage,
      last_click_non_direct_campaign_platform as session_campaign_platform,
      last_click_non_direct_campaign_type as session_campaign_type,
      last_click_non_direct_campaign_marketing_objective as session_campaign_marketing_objective,
      last_click_non_direct_campaign_name as session_campaign_name,
      last_click_non_direct_campaign as session_campaign,
      last_click_non_direct_campaign_id as session_campaign_id,
      last_click_non_direct_campaign_click_id as session_campaign_click_id,
      last_click_non_direct_campaign_term as session_campaign_term,
      last_click_non_direct_campaign_content as session_campaign_content,
      conversion_id,
      conversion_name,
      conversion_revenue,
      'last_click_non_direct' as attribution_model
    from attribution_data_single_touch

    # LINEAR

    # TIME DECAY

    # POSITION-BASED
  )

  select
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
    attribution_model,

    count(distinct conversion_id) as conversions,
    sum(conversion_revenue) as conversions_revenue
  from attribution_models
  group by all
);