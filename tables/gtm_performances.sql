CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.gtm_performances`(start_date DATE, end_date DATE) AS (
  with base_events as (
    select 
      # USER DATA
      user_date, 
      user_id,
      client_id, 
      user_type, 
      new_user, 
      returning_user,
      user_channel_grouping, 
      user_source,
      user_tld_source, 
      user_campaign, 
      user_device_type, 
      user_country, 
      user_language, 

      # SESSION DATA
      session_date, 
      session_id, 
      session_number, 
      cross_domain_session, 
      session_start_timestamp, 
      session_end_timestamp,
      session_duration_sec,
      session_channel_grouping, 
      session_source,
      session_tld_source, 
      session_campaign,
      session_device_type, 
      session_browser_name,
      session_country, 
      session_language,
      session_hostname,
      session_landing_page_category, 
      session_landing_page_location, 
      session_landing_page_title, 
      session_exit_page_category, 
      session_exit_page_location, 
      session_exit_page_title,

      # EVENT DATA
      event_date,
      event_timestamp,
      event_name,
      event_origin,
      event_id,
      ecommerce,
      
      # GTM DATA (Flattened in events())
      cs_hostname,
      cs_container_id,
      ss_hostname,
      ss_container_id,
      processing_event_timestamp,
      content_length,

      # RAW RECORD ARRAYS (For transformations)
      page_data,
      event_data,
      datalayer
    from `tom-moretti.nameless_analytics.events`(start_date, end_date, 'event')
  )

  select
    # USER DATA
    user_date,
    client_id,
    user_id,
    user_channel_grouping,
    user_source,
    user_tld_source,
    user_campaign,
    user_device_type,
    user_country,
    user_language,
    user_type,
    new_user,
    returning_user,

    # SESSION DATA
    session_date,
    session_number,
    session_id,
    session_start_timestamp,
    session_end_timestamp,
    session_duration_sec,
    session_channel_grouping,
    session_source,
    session_tld_source,
    session_campaign,
    cross_domain_session,
    session_landing_page_category,
    session_landing_page_location,
    session_landing_page_title,
    session_exit_page_category,
    session_exit_page_location,
    session_exit_page_title,
    session_hostname,
    session_device_type,
    session_country,
    session_language,
    session_browser_name,

    # PAGE DATA
    array(
      select as struct
        name,
        struct(
          value.string as string,
          value.int as int,
          value.float as float,
          to_json_string(value.json) as json
        ) as value
      from unnest(page_data)
    ) as page_data,

    # EVENT DATA
    event_date,
    timestamp_millis(event_timestamp) as event_datetime,
    event_timestamp,
    processing_event_timestamp,
    processing_event_timestamp - event_timestamp as delay_in_milliseconds,
    (processing_event_timestamp - event_timestamp) / 1000 as delay_in_seconds,
    event_origin,
    content_length,
    cs_hostname,
    ss_hostname,
    cs_container_id,
    ss_container_id,
    row_number() over (partition by client_id, session_id order by event_timestamp asc) as hit_number,
    event_name,
    event_id,
    array(
      select as struct
        name,
        struct(
          value.string as string,
          value.int as int,
          value.float as float,
          to_json_string(value.json) as json
        ) as value
      from unnest(event_data)
    ) as event_data,
    to_json_string(ecommerce) as ecommerce,
    to_json_string(datalayer) as dataLayer
  from base_events
);