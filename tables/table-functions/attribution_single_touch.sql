Server-side Client Tag

declare project_name string default 'PROJECT NAME';  -- Change this
declare dataset_name string default 'nameless_analytics';

declare attribution_single_touch string default format ("""
CREATE OR REPLACE TABLE FUNCTION `%s.%s.attribution_single_touch`(start_date DATE, end_date DATE, conversion_name STRING, lookback_days INT64) AS (
with conversions as (
    select
      # CONVERSION DATA
      event_date as conversion_date,
      event_timestamp as conversion_timestamp,
      event_id as conversion_id,
      event_name as conversion_name,
      if(event_name = 'purchase', ifnull(safe_cast(json_value(ecommerce, '$.value') as float64), 0.0), 0.0) as conversion_revenue,
      client_id,
      session_id as conversion_session_id,

      # FIRST CLICK
      user_channel_grouping as first_click_channel_grouping,
      user_custom_channel_grouping as first_click_custom_channel_grouping,
      user_source_cleaned as first_click_source,
      user_campaign_year as first_click_campaign_year,
      user_campaign_country as first_click_campaign_country,
      user_campaign_funnel_stage as first_click_campaign_funnel_stage,
      user_campaign_platform as first_click_campaign_platform,
      user_campaign_type as first_click_campaign_type,
      user_campaign_marketing_objective as first_click_campaign_marketing_objective,
      user_campaign_name as first_click_campaign_name,
      user_campaign as first_click_campaign,
      user_campaign_id as first_click_campaign_id,
      user_campaign_click_id as first_click_campaign_click_id,
      user_campaign_term as first_click_campaign_term,
      user_campaign_content as first_click_campaign_content,

      # LAST CLICK
      session_channel_grouping as last_click_channel_grouping,
      session_custom_channel_grouping as last_click_custom_channel_grouping,
      session_source_cleaned as last_click_source,
      session_campaign_year as last_click_campaign_year,
      session_campaign_country as last_click_campaign_country,
      session_campaign_funnel_stage as last_click_campaign_funnel_stage,
      session_campaign_platform as last_click_campaign_platform,
      session_campaign_type as last_click_campaign_type,
      session_campaign_marketing_objective as last_click_campaign_marketing_objective,
      session_campaign_name as last_click_campaign_name,
      session_campaign as last_click_campaign,
      session_campaign_id as last_click_campaign_id,
      session_campaign_click_id as last_click_campaign_click_id,
      session_campaign_term as last_click_campaign_term,
      session_campaign_content as last_click_campaign_content

    from `%s.%s.events`(start_date, end_date, 'session')
    where true 
      and event_name = conversion_name
  ),

  sessions as (
    select distinct
      client_id,
      session_id,
      session_start_timestamp,
      session_channel_grouping,
      session_custom_channel_grouping,
      session_source_cleaned as session_source,
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
      session_campaign_content

    from `%s.%s.events`(date_sub(start_date, interval lookback_days day), end_date, 'session')
  ),

  last_click_non_direct as (
    select
      conversion_id,

      array_agg(
        struct(
          session_start_timestamp,
          session_channel_grouping as channel_grouping,
          session_custom_channel_grouping as custom_channel_grouping,
          session_source as source,
          session_campaign_year as campaign_year,
          session_campaign_country as campaign_country,
          session_campaign_funnel_stage as campaign_funnel_stage,
          session_campaign_platform as campaign_platform,
          session_campaign_type as campaign_type,
          session_campaign_marketing_objective as campaign_marketing_objective,
          session_campaign_name as campaign_name,
          session_campaign as campaign,
          session_campaign_id as campaign_id,
          session_campaign_click_id as campaign_click_id,
          session_campaign_term as campaign_term,
          session_campaign_content as campaign_content
        )
        order by session_start_timestamp desc
        limit 1
      )[safe_offset(0)] as traffic_source

    from conversions
    inner join sessions using(client_id)

    where true
      and session_start_timestamp <= conversion_timestamp
      and session_source is not null
      and session_source != 'direct'
      and session_channel_grouping != 'direct'
      and datetime_diff(datetime(timestamp_millis(conversion_timestamp)), datetime(timestamp_millis(session_start_timestamp)), day) <= lookback_days

    group by conversion_id
  )

  select
    # CONVERSION DATA
    conversion_date,
    conversion_timestamp,
    conversion_id,
    conversion_name,
    conversion_revenue,
    client_id,
    conversion_session_id,

    # FIRST CLICK
    first_click_channel_grouping,
    first_click_custom_channel_grouping,
    first_click_source,
    first_click_campaign_year,
    first_click_campaign_country,
    first_click_campaign_funnel_stage,
    first_click_campaign_platform,
    first_click_campaign_type,
    first_click_campaign_marketing_objective,
    first_click_campaign_name,
    first_click_campaign,
    first_click_campaign_id,
    first_click_campaign_click_id,
    first_click_campaign_term,
    first_click_campaign_content,

    # LAST CLICK
    last_click_channel_grouping,
    last_click_custom_channel_grouping,
    last_click_source,
    last_click_campaign_year,
    last_click_campaign_country,
    last_click_campaign_funnel_stage,
    last_click_campaign_platform,
    last_click_campaign_type,
    last_click_campaign_marketing_objective,
    last_click_campaign_name,
    last_click_campaign,
    last_click_campaign_id,
    last_click_campaign_click_id,
    last_click_campaign_term,
    last_click_campaign_content,

    # LAST CLICK NON-DIRECT
    ifnull(traffic_source.channel_grouping, last_click_channel_grouping) as last_click_non_direct_channel_grouping,
    ifnull(traffic_source.custom_channel_grouping, last_click_custom_channel_grouping) as last_click_non_direct_custom_channel_grouping,
    ifnull(traffic_source.source, last_click_source) as last_click_non_direct_source,
    ifnull(traffic_source.campaign_year, last_click_campaign_year) as last_click_non_direct_campaign_year,
    ifnull(traffic_source.campaign_country, last_click_campaign_country) as last_click_non_direct_campaign_country,
    ifnull(traffic_source.campaign_funnel_stage, last_click_campaign_funnel_stage) as last_click_non_direct_campaign_funnel_stage,
    ifnull(traffic_source.campaign_platform, last_click_campaign_platform) as last_click_non_direct_campaign_platform,
    ifnull(traffic_source.campaign_type, last_click_campaign_type) as last_click_non_direct_campaign_type,
    ifnull(traffic_source.campaign_marketing_objective, last_click_campaign_marketing_objective) as last_click_non_direct_campaign_marketing_objective,
    ifnull(traffic_source.campaign_name, last_click_campaign_name) as last_click_non_direct_campaign_name,
    ifnull(traffic_source.campaign, last_click_campaign) as last_click_non_direct_campaign,
    ifnull(traffic_source.campaign_id, last_click_campaign_id) as last_click_non_direct_campaign_id,
    ifnull(traffic_source.campaign_click_id, last_click_campaign_click_id) as last_click_non_direct_campaign_click_id,
    ifnull(traffic_source.campaign_term, last_click_campaign_term) as last_click_non_direct_campaign_term,
    ifnull(traffic_source.campaign_content, last_click_campaign_content) as last_click_non_direct_campaign_content

  from conversions
  left join last_click_non_direct using(conversion_id)
);
""", project_name, dataset_name, project_name, dataset_name, project_name, dataset_name);

execute immediate attribution_single_touch;
