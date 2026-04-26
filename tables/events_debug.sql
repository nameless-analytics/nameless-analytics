CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.events_debug`(start_date DATE, end_date DATE) AS (
with base_events as (
    select 
      # USER DATA
      user_date,
      client_id,
      user_data,

      # SESSION DATA
      session_date,
      session_id,
      session_data,

      # PAGE DATA
      page_date,
      page_id,
      dense_rank() over (partition by session_id order by (select value.int from unnest(page_data) where name = 'page_timestamp') asc) as page_view_number,

      # EVENT DATA
      event_date,
      event_timestamp,
      event_name,
      rank() over (partition by session_id order by event_timestamp asc) as event_number,
      event_origin,
      event_id,

      # ECOMMERCE DATA
      ecommerce,
  
      # RAW DATA
      page_data, 
      event_data,
      datalayer,
      consent_data
    from `tom-moretti.nameless_analytics.events_raw`
    where event_date between start_date and end_date
  )

  select
    # USER DATA
    user_date,
    client_id,
    array(
      select as struct
        name,
        struct(
          value.string as string,
          value.int as int,
          value.float as float,
          to_json_string(value.json) as json,
          value.bool as bool
        ) as value
      from unnest(user_data)
    ) as user_data,
  
    # SESSION DATA
    session_date,
    session_id,
    array(
      select as struct
        name,
        struct(
          value.string as string,
          value.int as int,
          value.float as float,
          to_json_string(value.json) as json,
          value.bool as bool
        ) as value
      from unnest(session_data)
    ) as session_data,
    
    # PAGE DATA
    page_date,
    page_id,
    page_view_number,
    array(
      select as struct
        name,
        struct(
          value.string as string,
          value.int as int,
          value.float as float,
          to_json_string(value.json) as json,
          value.bool as bool
        ) as value
      from unnest(page_data)
    ) as page_data,

    # EVENT DATA
    event_date,
    timestamp_millis(event_timestamp) as event_datetime,
    event_timestamp,
    event_origin,
    event_name,
    event_id,
    event_number,
    array(
      select as struct
        name,
        struct(
          value.string as string,
          value.int as int,
          value.float as float,
          to_json_string(value.json) as json,
          value.bool as bool
        ) as value
      from unnest(event_data)
    ) as event_data,

    to_json_string(ecommerce) as ecommerce,
    to_json_string(datalayer) as datalayer,
    consent_data
  from base_events
);