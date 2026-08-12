CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.attribution_multi_touch`(start_date DATE, end_date DATE, conversion_name STRING, lookback_days INT64) AS (
  with conversions as (
    select
      # CONVERSION DATA
      event_date as conversion_date,
      event_timestamp as conversion_timestamp,
      event_id as conversion_id,
      event_name as conversion_name,
      if(event_name = 'purchase', ifnull(safe_cast(json_value(ecommerce, '$.value') as float64), 0.0), 0.0) as conversion_revenue,
      client_id,
      session_id as conversion_session_id

    from `tom-moretti.nameless_analytics.events`(start_date, end_date, 'session')
    where true
      and event_name = conversion_name
  ),

  sessions as (
    select
      client_id,
      session_id,
      session_start_timestamp,

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
      session_campaign_content

    from `tom-moretti.nameless_analytics.sessions`(date_sub(start_date, interval lookback_days day), end_date)
  ),

  attribution_path as (
    select
      # CONVERSION DATA
      conversions.conversion_date,
      conversions.conversion_timestamp,
      conversions.conversion_id,
      conversions.conversion_name,
      conversions.conversion_revenue,
      conversions.client_id,
      conversions.conversion_session_id,

      # TOUCHPOINT DATA
      sessions.session_id,
      sessions.session_start_timestamp,

      row_number() over (partition by conversions.conversion_id order by sessions.session_start_timestamp asc, sessions.session_id asc) as touchpoint_number,
      count(*) over (partition by conversions.conversion_id) as touchpoint_count,
      safe_divide(timestamp_diff(
        timestamp_millis(conversions.conversion_timestamp),
        timestamp_millis(sessions.session_start_timestamp),
        second
      ), 86400.0) as days_before_conversion,

      # TRAFFIC DATA
      sessions.session_channel_grouping,
      sessions.session_custom_channel_grouping,
      sessions.session_source,

      sessions.session_campaign_year,
      sessions.session_campaign_country,
      sessions.session_campaign_funnel_stage,
      sessions.session_campaign_platform,
      sessions.session_campaign_type,
      sessions.session_campaign_marketing_objective,
      sessions.session_campaign_name,

      sessions.session_campaign,
      sessions.session_campaign_id,
      sessions.session_campaign_click_id,
      sessions.session_campaign_term,
      sessions.session_campaign_content

    from conversions
    inner join sessions
      using(client_id)

    where true
      and sessions.session_start_timestamp <= conversions.conversion_timestamp
      and datetime_diff(datetime(timestamp_millis(conversions.conversion_timestamp)), datetime(timestamp_millis(sessions.session_start_timestamp)), day) <= lookback_days
  ),

  attribution_raw_weights as (
    select
      attribution_path.*,

      # LINEAR
      safe_divide(1.0, touchpoint_count) as linear_weight,

      # TIME DECAY
      power(0.5, safe_divide(days_before_conversion, 7.0)) as time_decay_raw_weight, # Half-life = 7 days

      # POSITION-BASED
      case
        when touchpoint_count = 1 then 1.0
        when touchpoint_count = 2 then 0.5
        when touchpoint_number = 1 then 0.4
        when touchpoint_number = touchpoint_count then 0.4
        else safe_divide(0.2, touchpoint_count - 2)
      end as position_based_weight # 40% first touch / 20% middle touches / 40% last touch

    from attribution_path
  ),

  attribution_weights as (
    select
      attribution_raw_weights.*,
      safe_divide(time_decay_raw_weight, sum(time_decay_raw_weight) over (partition by conversion_id)) as time_decay_weight # Normalize Time Decay weights to 1 per conversion

    from attribution_raw_weights
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

    # TOUCHPOINT DATA
    touchpoint_number,
    touchpoint_count,
    session_id,
    session_start_timestamp,
    days_before_conversion,

    # TRAFFIC DATA
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

    # LINEAR
    linear_weight as linear_attribution_credit,
    conversion_revenue * linear_weight as linear_attributed_revenue,

    # TIME DECAY
    time_decay_weight as time_decay_attribution_credit,
    conversion_revenue * time_decay_weight as time_decay_attributed_revenue,

    # POSITION-BASED
    position_based_weight as position_based_attribution_credit,
    conversion_revenue * position_based_weight as position_based_attributed_revenue

  from attribution_weights
);