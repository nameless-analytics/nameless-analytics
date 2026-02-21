CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.pages`(start_date DATE, end_date DATE) AS (
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
      user_source_cleaned as user_source,
      user_campaign, 
      user_campaign_id,
      user_campaign_click_id,
      user_campaign_term,
      user_campaign_content,
      user_device_type, 
      user_country,
      user_city,
      user_language, 

      # SESSION DATA
      session_date, 
      session_id, 
      session_number, 
      cross_domain_session, 
      session_start_timestamp, 
      session_end_timestamp,
      session_type,
      session_channel_grouping, 
      session_source_cleaned as session_source,
      session_campaign,
      session_campaign_id,
      session_campaign_click_id,
      session_campaign_term,
      session_campaign_content,
      session_device_type, 
      session_browser_name,
      session_country, 
      session_city,
      session_language,
      session_hostname,
      session_landing_page_category, 
      session_landing_page_location, 
      session_landing_page_title, 
      session_exit_page_category, 
      session_exit_page_location, 
      session_exit_page_title,

      # PAGE DATA
      page_date,
      page_id,
      page_view_number,
      page_load_timestamp,
      page_unload_timestamp,
      page_category,
      page_title,
      page_location,
      page_hostname,
      page_status_code,
      time_on_page,

      # EVENT DATA
      event_timestamp,
      event_name,
      total_page_load_time
    from `tom-moretti.nameless_analytics.events`(start_date, end_date, 'page')
  ),

  page_logic as (
    select
      # USER DATA
      user_date, 
      client_id, 
      user_type, 
      new_user, 
      returning_user,
      user_channel_grouping, 
      user_source, 
      user_campaign, 
      user_campaign_click_id,
      user_campaign_term,
      user_campaign_content,
      user_device_type, 
      user_country,
      user_city, 
      user_language, 

      # SESSION DATA
      session_date, 
      session_id, 
      session_number, 
      cross_domain_session, 
      session_start_timestamp, 
      session_type,
      session_channel_grouping, 
      session_source, 
      session_campaign,
      session_campaign_click_id,
      session_campaign_term,
      session_campaign_content,
      session_device_type, 
      session_browser_name,
      session_country, 
      session_city,
      session_language,
      session_landing_page_category, 
      session_landing_page_location, 
      session_landing_page_title, 
      session_exit_page_category, 
      session_exit_page_location, 
      session_exit_page_title, 
      session_hostname,

      # PAGE DATA
      page_date,
      page_id,
      page_view_number,
      page_location,
      page_hostname,
      page_title,
      page_category,
      max(page_load_timestamp) as page_load_timestamp,
      max(page_unload_timestamp) as page_unload_timestamp,
      
      -- Performance metrics
      max(total_page_load_time) as total_page_load_time,
      max(page_status_code) as page_status_code,

      # EVENT DATA
      countif(event_name = 'page_view') as page_view
    from base_events
    group by all
  )

  select
    # USER DATA
    user_date, 
    client_id, 
    user_type, 
    new_user, 
    returning_user,
    user_channel_grouping, 
    user_source,
    user_campaign, 
    user_campaign_click_id,
    user_campaign_term,
    user_campaign_content,
    user_device_type, 
    user_country, 
    user_city,
    user_language, 

    # SESSION DATA
    session_date, 
    session_id, 
    session_number, 
    cross_domain_session, 
    session_start_timestamp, 
    session_type,
    session_channel_grouping, 
    session_source,
    session_campaign,
    session_campaign_click_id,
    session_campaign_term,
    session_campaign_content,
    session_device_type, 
    session_browser_name,
    session_country,
    session_city, 
    session_language,
    session_landing_page_category, 
    session_landing_page_location, 
    session_landing_page_title, 
    session_exit_page_category, 
    session_exit_page_location, 
    session_exit_page_title, 
    session_hostname,

    # PAGE DATA
    page_date,
    page_id,
    page_view_number,
    page_location,
    page_hostname,
    page_title,
    page_category,
    timestamp_millis(page_load_timestamp) as page_load_datetime,
    timestamp_millis(page_unload_timestamp) as page_unload_datetime,
    (page_unload_timestamp - page_load_timestamp) / 1000 as time_on_page,
    total_page_load_time / 1000 as page_load_time_sec,
    page_status_code as page_status_code,
    
    # EVENT DATA
    sum(page_view) as page_view
  from page_logic
  group by all
);