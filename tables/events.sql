CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.events`(start_date DATE, end_date DATE, date_scope STRING) AS (
  select
    # USER DATA
    user_date,
    first_value((select value.string from unnest(session_data) where name = 'user_id') IGNORE NULLS) over (partition by session_id order by event_timestamp desc) as user_id,
    client_id,

    case 
      when (select value.int from unnest(session_data) where name = 'session_number') = 1 then 'new_user'
      when (select value.int from unnest(session_data) where name = 'session_number') > 1 then 'returning_user'
    end as user_type,
    case 
      when (select value.int from unnest(session_data) where name = 'session_number') = 1 then client_id
      else null
    end as new_user,
    case 
      when (select value.int from unnest(session_data) where name = 'session_number') > 1 then client_id
      else null
    end as returning_user,

    (select value.int from unnest(user_data) where name = 'user_first_session_timestamp') as user_first_session_timestamp,
    first_value((select value.int from unnest(user_data) where name = 'user_last_session_timestamp')) over (partition by client_id order by event_timestamp desc) as user_last_session_timestamp,

    datetime_diff(
      timestamp_micros(first_value((select value.int from unnest(user_data) where name = 'user_last_session_timestamp')) over (partition by client_id order by event_timestamp desc)), 
      timestamp_micros((select value.int from unnest(user_data) where name = 'user_first_session_timestamp'))
    , day) as days_from_first_to_last_visit,
    datetime_diff(current_timestamp(), timestamp_millis((select value.int from unnest(user_data) where name = 'user_first_session_timestamp')), day) as days_from_first_visit, -- Da capire se ha senso
    datetime_diff(current_timestamp(), timestamp_millis(first_value((select value.int from unnest(user_data) where name = 'user_last_session_timestamp')) over (partition by client_id order by event_timestamp desc)), day) as days_from_last_visit, -- Da capire se ha senso
    
    (select value.string from unnest(user_data) where name = 'user_channel_grouping') as user_channel_grouping,
    (select value.string from unnest(user_data) where name = 'user_source') as user_source,
    (select value.string from unnest(user_data) where name = 'user_tld_source') as user_tld_source,
    (select value.string from unnest(user_data) where name = 'user_campaign') as user_campaign,
    (select value.string from unnest(user_data) where name = 'user_campaign_id') as user_campaign_id,
    (select value.string from unnest(user_data) where name = 'user_campaign_click_id') as user_campaign_click_id,
    (select value.string from unnest(user_data) where name = 'user_campaign_term') as user_campaign_term,
    (select value.string from unnest(user_data) where name = 'user_campaign_content') as user_campaign_content,

    (select value.string from unnest(user_data) where name = 'user_device_type') as user_device_type,
    (select value.string from unnest(user_data) where name = 'user_country') as user_country,
    (select value.string from unnest(user_data) where name = 'user_language') as user_language,
      
    -- Add user level custom dimension here
    
    
    # SESSION DATA
    session_date,
    session_id,
    
    (select value.int from unnest(session_data) where name = 'session_number') as session_number,
    first_value((select value.string from unnest(session_data) where name = 'cross_domain_session')) over (partition by session_id order by event_timestamp desc) as cross_domain_session,
    
    (select value.int from unnest(session_data) where name = 'session_start_timestamp') as session_start_timestamp,
    first_value((select value.int from unnest(session_data) where name = 'session_end_timestamp')) over (partition by session_id order by event_timestamp desc) as session_end_timestamp,
    datetime_diff(
      timestamp_millis(first_value((select value.int from unnest(session_data) where name = 'session_end_timestamp')) over (partition by session_id order by event_timestamp desc)), 
      timestamp_millis((select value.int from unnest(session_data) where name = 'session_start_timestamp'))
    , second) as session_duration_sec, -- Da integrare in firestore?

    case when (select value.int from unnest(session_data) where name = 'session_number') = 1 then 1 else 0 end as new_session,
    case when (select value.int from unnest(session_data) where name = 'session_number') > 1 then 1 else 0 end as returning_session,

    (select value.string from unnest(session_data) where name = 'session_channel_grouping') as session_channel_grouping,
    (select value.string from unnest(session_data) where name = 'session_source') as session_source,
    (select value.string from unnest(session_data) where name = 'session_tld_source') as session_tld_source,
    (select value.string from unnest(session_data) where name = 'session_campaign') as session_campaign,
    (select value.string from unnest(session_data) where name = 'session_campaign_id') as session_campaign_id,
    (select value.string from unnest(session_data) where name = 'session_campaign_click_id') as session_campaign_click_id,
    (select value.string from unnest(session_data) where name = 'session_campaign_term') as session_campaign_term,
    (select value.string from unnest(session_data) where name = 'session_campaign_content') as session_campaign_content,

    (select value.string from unnest(session_data) where name = 'session_device_type') as session_device_type,
    (select value.string from unnest(session_data) where name = 'session_country') as session_country,
    (select value.string from unnest(session_data) where name = 'session_language') as session_language,

    (select value.string from unnest(session_data) where name = 'session_browser_name') as session_browser_name,
    
    (select value.string from unnest(session_data) where name = 'session_hostname') as session_hostname,
    (select value.string from unnest(session_data) where name = 'session_landing_page_category') as session_landing_page_category,
    (select value.string from unnest(session_data) where name = 'session_landing_page_location') as session_landing_page_location,
    (select value.string from unnest(session_data) where name = 'session_landing_page_title') as session_landing_page_title,
    first_value((select value.string from unnest(session_data) where name = 'session_exit_page_category')) over (partition by session_id order by event_timestamp desc) as session_exit_page_category,
    first_value((select value.string from unnest(session_data) where name = 'session_exit_page_location')) over (partition by session_id order by event_timestamp desc) as session_exit_page_location,
    first_value((select value.string from unnest(session_data) where name = 'session_exit_page_title')) over (partition by session_id order by event_timestamp desc) as session_exit_page_title,
    
    -- Add session level custom dimension here
      
      
    # PAGE DATA
    page_date,
    page_id,
    (select value.int from unnest(session_data) where name = 'total_page_views') as page_view_number,	
    (select value.int from unnest(page_data) where name = 'page_timestamp') as page_load_timestamp,
    first_value(event_timestamp) over (partition by page_id order by event_timestamp desc) as page_unload_timestamp, --Da integrare in firestore?
    
    (select value.string from unnest(page_data) where name = 'page_category') as page_category,
    (select value.string from unnest(page_data) where name = 'page_title') as page_title,
    (select value.string from unnest(page_data) where name = 'page_language') as page_language,
    (select value.string from unnest(page_data) where name = 'page_hostname_protocol') as page_hostname_protocol,
    (select value.string from unnest(page_data) where name = 'page_hostname') as page_hostname,
    (select value.string from unnest(page_data) where name = 'page_location') as page_location,
    (select value.string from unnest(page_data) where name = 'page_fragment') as page_fragment,
    (select value.string from unnest(page_data) where name = 'page_query') as page_query,
    (select value.string from unnest(page_data) where name = 'page_extension') as page_extension,
    (select value.string from unnest(page_data) where name = 'page_referrer') as page_referrer,
    (select value.int from unnest(page_data) where name = 'page_status_code') as page_status_code,
    datetime_diff(
      timestamp_millis(first_value(event_timestamp) over (partition by page_id order by event_timestamp desc)),
      timestamp_millis(first_value(event_timestamp) over (partition by page_id order by event_timestamp asc))
    , second) as time_on_page, -- Da integrare in firestore?
    
    -- Add page level custom dimension here
    
    
    # EVENT DATA
    event_date,
    event_timestamp,	
    event_name,	
    event_id,	
    (select value.int from unnest(session_data) where name = 'total_events') as event_number,
    (select value.string from unnest(event_data) where name = 'event_type') as event_type, 
    
    (select value.string from unnest(event_data) where name = 'channel_grouping') as channel_grouping, 
    (select value.string from unnest(event_data) where name = 'source') as source, 
    (select value.string from unnest(event_data) where name = 'tld_source') as tld_source, 
    (select value.string from unnest(event_data) where name = 'campaign') as campaign, 
    (select value.string from unnest(event_data) where name = 'campaign_id') as campaign_id, 
    (select value.string from unnest(event_data) where name = 'campaign_click_id') as campaign_click_id,
    (select value.string from unnest(event_data) where name = 'campaign_term') as campaign_term, 
    (select value.string from unnest(event_data) where name = 'campaign_content') as campaign_content, 
    
    (select value.string from unnest(event_data) where name = 'browser_name') as browser_name, 
    (select value.string from unnest(event_data) where name = 'browser_version') as browser_version, 
    (select value.string from unnest(event_data) where name = 'browser_language') as browser_language, 
    (select value.string from unnest(event_data) where name = 'viewport_size') as viewport_size,
    (select value.string from unnest(event_data) where name = 'user_agent') as user_agent, 
    
    (select value.string from unnest(event_data) where name = 'device_type') as device_type, 
    (select value.string from unnest(event_data) where name = 'device_model') as device_model, 
    (select value.string from unnest(event_data) where name = 'device_vendor') as device_vendor, 
    (select value.string from unnest(event_data) where name = 'os_name') as os_name, 
    (select value.string from unnest(event_data) where name = 'os_version') as os_version, 
    (select value.string from unnest(event_data) where name = 'screen_size') as screen_size, 
      
    (select value.string from unnest(event_data) where name = 'country') as country, 
    (select value.string from unnest(event_data) where name = 'city') as city, 
        
    (select value.string from unnest(event_data) where name = 'cross_domain_id') as cross_domain_id, 
    
    -- Only for page_load_time event
    (select value.int from unnest(event_data) where name = 'time_to_dom_interactive') as time_to_dom_interactive, 
    (select value.int from unnest(event_data) where name = 'page_render_time') as page_render_time, 
    (select value.int from unnest(event_data) where name = 'time_to_dom_complete') as time_to_dom_complete, 
    (select value.int from unnest(event_data) where name = 'total_page_load_time') as total_page_load_time, 
    
    -- Only for search event
    (select value.string from unnest(event_data) where name = 'search_term') as search_term, 
    
    -- Add event level custom dimension here
    
    
    # ECOMMERCE DATA
    ecommerce,

    # DATALAYER DATA
    datalayer,

    # CONSENT DATA
    (select value.string from unnest(consent_data) where name = 'consent_type') as consent_type, 
    (select value.string from unnest(consent_data) where name = 'respect_consent_mode') as respect_consent_mode, 
    (select value.string from unnest(consent_data) where name = 'ad_user_data') as ad_user_data, 
    (select value.string from unnest(consent_data) where name = 'ad_personalization') as ad_personalization, 
    (select value.string from unnest(consent_data) where name = 'ad_storage') as ad_storage, 
    (select value.string from unnest(consent_data) where name = 'analytics_storage') as analytics_storage, 
    (select value.string from unnest(consent_data) where name = 'functionality_storage') as functionality_storage, 
    (select value.string from unnest(consent_data) where name = 'personalization_storage') as personalization_storage, 
    (select value.string from unnest(consent_data) where name = 'security_storage') as security_storage, 
    
    # REQUEST DATA
    event_origin,
    (select value.string from unnest(gtm_data) where name = 'cs_hostname') as cs_hostname,
    (select value.string from unnest(gtm_data) where name = 'cs_container_id') as cs_container_id,
    (select value.string from unnest(gtm_data) where name = 'cs_tag_name') as cs_tag_name,
    (select value.int from unnest(gtm_data) where name = 'cs_tag_id') as cs_tag_id,

    (select value.string from unnest(gtm_data) where name = 'ss_hostname') as ss_hostname,
    (select value.string from unnest(gtm_data) where name = 'ss_container_id') as ss_container_id,
    (select value.string from unnest(gtm_data) where name = 'ss_tag_name') as ss_tag_name,
    (select value.int from unnest(gtm_data) where name = 'ss_tag_id') as ss_tag_id,

    (select value.int from unnest(gtm_data) where name = 'processing_event_timestamp') as processing_event_timestamp,
    (select value.int from unnest(gtm_data) where name = 'content_length') as content_length,

    # RAW RECORD ARRAYS (for GTM performances and debugging)
    user_data,
    session_data,
    page_data,
    event_data,
    gtm_data
    
  from `tom-moretti.nameless_analytics.events_raw`
  where true
    and case 
      when date_scope = 'user' then user_date
      when date_scope = 'session' then session_date
      when date_scope = 'page' then page_date
      when date_scope = 'event' then event_date
    end between start_date and end_date
);