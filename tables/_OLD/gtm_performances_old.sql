CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.gtm_performances`(start_date DATE, end_date DATE) AS (
SELECT 
    -- USER DATA
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
    case 
      when session_number = 1 then 'new_user'
      when session_number > 1 then 'returning_user'
    end as user_type,
    case 
      when session_number = 1 then client_id
      else null
    end as new_user,
    case 
      when session_number > 1 then client_id
      else null
    end as returning_user,

    -- SESSION DATA
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

    -- PAGE DATA
    ARRAY(
      SELECT AS STRUCT
        name,
        STRUCT(
          value.string AS string,
          value.int AS int,
          value.float AS float,
          TO_JSON_STRING(value.json) AS json
        ) AS value
      FROM UNNEST(page_data)
    ) AS page_data,

    -- EVENT DATA
    event_date,
    event_datetime,
    event_timestamp,
    processing_event_timestamp,
    processing_event_timestamp - event_timestamp AS delay_in_milliseconds,
    (processing_event_timestamp - event_timestamp) / 1000 AS delay_in_seconds,
    event_origin,
    content_length,
    (SELECT value.string FROM UNNEST(event_data) WHERE name = 'cs_hostname') AS cs_hostname,
    (SELECT value.string FROM UNNEST(event_data) WHERE name = 'ss_hostname') AS ss_hostname,
    (SELECT value.string FROM UNNEST(event_data) WHERE name = 'cs_container_id') AS cs_container_id,
    (SELECT value.string FROM UNNEST(event_data) WHERE name = 'ss_container_id') AS ss_container_id,
    ROW_NUMBER() OVER (PARTITION BY client_id, session_id ORDER BY event_timestamp ASC) AS hit_number,
    event_name,
    event_id,
    ARRAY(
      SELECT AS STRUCT
        name,
        STRUCT(
          value.string AS string,
          value.int AS int,
          value.float AS float,
          TO_JSON_STRING(value.json) AS json
        ) AS value
      FROM UNNEST(event_data)
    ) AS event_data,
    TO_JSON_STRING(ecommerce) as ecommerce,
    TO_JSON_STRING(dataLayer) as dataLayer
  from `tom-moretti.nameless_analytics.events` (start_date, end_date, 'session_level')
);