CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.pages`(start_date DATE, end_date DATE) AS (
with event_data as ( 
    select 
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
      page_id,
      first_value(event_timestamp) over (partition by page_id order by event_timestamp asc) as page_load_timestamp,
      first_value(event_timestamp) over (partition by page_id order by event_timestamp desc) as page_unload_timestamp,
      page_category,
      page_location,
      page_title,
      page_hostname,
      page_status_code,
      time_to_dom_interactive,
      page_render_time,
      time_to_dom_complete,
      total_page_load_time,

      -- EVENT DATA
      event_date,
      event_name,
      event_timestamp,    
    from `tom-moretti.nameless_analytics.events` (start_date, end_date , 'session')
  ),

  page_data as(
    select 
      -- USER DATA
      user_date,
      client_id,
      user_id,
      user_channel_grouping,
      ifnull(split(user_tld_source, '.')[safe_offset(0)], user_source) as user_source,
      user_tld_source,
      user_campaign,
      user_device_type,
      user_country,
      user_language,
      user_type,
      new_user,
      returning_user,

      -- SESSION DATA
      session_date,
      session_number,
      session_id,
      session_start_timestamp,
      session_channel_grouping,
      ifnull(split(session_tld_source, '.')[safe_offset(0)], session_source) as session_source,
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
      dense_rank() over (partition by session_id order by page_load_timestamp desc) as page_view_number,
      page_id,
      page_location,
      page_hostname,
      page_title,
      page_category,
      page_load_timestamp,
      timestamp_millis(page_load_timestamp) as page_load_datetime,
      page_unload_timestamp,
      timestamp_millis(page_unload_timestamp) as page_unload_datetime,
      time_to_dom_interactive,
      page_render_time,
      time_to_dom_complete,
      total_page_load_time,
      page_status_code,
      max(time_to_dom_interactive) over (partition by page_id) as max_time_to_dom_interactive,
      max(page_render_time) over (partition by page_id) as max_page_render_time,
      max(time_to_dom_complete) over (partition by page_id) as max_time_to_dom_complete,
      max(total_page_load_time) over (partition by page_id) as max_total_page_load_time,
      max(page_status_code) over (partition by page_id) as max_page_status_code,
      countif(event_name = 'page_view') as page_view,
      count(1) as total_events,
    from event_data
    group by all
  )

  select 
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
    user_type,
    new_user,
    returning_user,

    -- SESSION DATA
    session_date,
    session_number,
    session_id,
    session_start_timestamp,
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
    page_view_number,
    page_id,
    page_location,
    page_hostname,
    page_title,
    page_category,
    page_load_datetime,
    page_unload_datetime,
    (page_unload_timestamp - page_load_timestamp) / 1000 as time_on_page,
    max_time_to_dom_interactive / 1000 as time_to_dom_interactive,
    max_page_render_time / 1000 as page_render_time,
    max_time_to_dom_complete / 1000 as time_to_dom_complete,
    max_total_page_load_time / 1000 as page_load_time_sec,
    max_page_status_code as page_status_code,
    sum(total_events) as total_events,
    sum(page_view) as page_view,
  from page_data
  group by all
);