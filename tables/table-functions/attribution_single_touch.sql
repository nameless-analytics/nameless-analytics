CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.attribution_single_touch`(start_date DATE, end_date DATE, conversion_event STRING, lookback_days INT64) AS (
  with conversions as (
    select
      # CONVERSION DATA
      event_date as conversion_date,
      event_timestamp as conversion_timestamp,
      event_id as conversion_id,
      client_id,
      session_id,

      # LAST CLICK
      split((select value.string from unnest(session_data) where name = 'session_tld_source'), '.')[safe_offset(0)] as last_click_source,
      (select value.string from unnest(session_data) where name = 'session_campaign') as last_click_campaign,
      (select value.string from unnest(session_data) where name = 'session_campaign_id') as last_click_campaign_id,
      (select value.string from unnest(session_data) where name = 'session_campaign_click_id') as last_click_campaign_click_id,
      (select value.string from unnest(session_data) where name = 'session_campaign_term') as last_click_campaign_term,
      (select value.string from unnest(session_data) where name = 'session_campaign_content') as last_click_campaign_content,
      (select value.string from unnest(session_data) where name = 'session_channel_grouping') as last_click_channel_grouping,

      # FIRST CLICK
      split((select value.string from unnest(user_data) where name = 'user_tld_source'), '.')[safe_offset(0)] as first_click_source,
      (select value.string from unnest(user_data) where name = 'user_campaign') as first_click_campaign,
      (select value.string from unnest(user_data) where name = 'user_campaign_id') as first_click_campaign_id,
      (select value.string from unnest(user_data) where name = 'user_campaign_click_id') as first_click_campaign_click_id,
      (select value.string from unnest(user_data) where name = 'user_campaign_term') as first_click_campaign_term,
      (select value.string from unnest(user_data) where name = 'user_campaign_content') as first_click_campaign_content,
      (select value.string from unnest(user_data) where name = 'user_channel_grouping') as first_click_channel_grouping

    from `tom-moretti.nameless_analytics.events_raw`
    where true 
    and event_date between start_date and end_date 
    and event_name = conversion_event
  ),

  sessions as (
    select
      client_id,
      session_id,
      session_start_timestamp,
      session_channel_grouping,
      session_source,
      session_campaign,
      session_campaign_id,
      session_campaign_click_id,
      session_campaign_term,
      session_campaign_content

    from `tom-moretti.nameless_analytics.sessions`(date_sub(start_date, interval lookback_days day), end_date)
  ),

  last_click_non_direct as (
    select
      conversion_id,

      array_agg(
        struct(
          session_start_timestamp,
          session_source as source,
          session_campaign as campaign,
          session_campaign_id as campaign_id,
          session_campaign_click_id as campaign_click_id,
          session_campaign_term as campaign_term,
          session_campaign_content as campaign_content,
          session_channel_grouping as channel_grouping
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
    client_id,
    session_id,

    # LAST CLICK
    last_click_source,
    last_click_campaign,
    last_click_campaign_id,
    last_click_campaign_click_id,
    last_click_campaign_term,
    last_click_campaign_content,
    last_click_channel_grouping,
    `tom-moretti.nameless_analytics.get_custom_channel_grouping`(last_click_source, last_click_campaign) as last_click_custom_channel_grouping,

    # FIRST CLICK
    first_click_source,
    first_click_campaign,
    first_click_campaign_id,
    first_click_campaign_click_id,
    first_click_campaign_term,
    first_click_campaign_content,
    first_click_channel_grouping,
    `tom-moretti.nameless_analytics.get_custom_channel_grouping`(first_click_source, first_click_campaign) as first_click_custom_channel_grouping,

    # LAST CLICK NON-DIRECT
    ifnull(traffic_source.source, last_click_source) as last_click_non_direct_source,
    ifnull(traffic_source.campaign, last_click_campaign) as last_click_non_direct_campaign,
    ifnull(traffic_source.campaign_id, last_click_campaign_id) as last_click_non_direct_campaign_id,
    ifnull(traffic_source.campaign_click_id, last_click_campaign_click_id) as last_click_non_direct_campaign_click_id,
    ifnull(traffic_source.campaign_term, last_click_campaign_term) as last_click_non_direct_campaign_term,
    ifnull(traffic_source.campaign_content, last_click_campaign_content) as last_click_non_direct_campaign_content,
    ifnull(traffic_source.channel_grouping, last_click_channel_grouping) as last_click_non_direct_channel_grouping,
    `tom-moretti.nameless_analytics.get_custom_channel_grouping`(ifnull(traffic_source.source, last_click_source), ifnull(traffic_source.campaign, last_click_campaign)) as last_click_non_direct_custom_channel_grouping

  from conversions
    left join last_click_non_direct using(conversion_id)
);