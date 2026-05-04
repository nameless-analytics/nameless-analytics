CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.pages`(start_date DATE, end_date DATE) AS (
  select
    # USER DATA
    user_date,
    user_id, 
    client_id, 
    user_type, 
    new_user_client_id, 
    returning_user_client_id,
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
    time_on_page,
    
    -- Performance metrics
    max(total_page_load_time) / 1000 as page_load_time_sec,
    max(page_status_code) as page_status_code,

    # EVENT DATA
    countif(event_name = 'page_view') as page_view
  from `tom-moretti.nameless_analytics.events`(start_date, end_date, 'page')
  group by all
);