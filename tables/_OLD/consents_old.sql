CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.consents`(start_date DATE, end_date DATE) AS (
with event_data as (
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
      user_type,
      new_user,
      returning_user,
  
      -- SESSION DATA
      session_date,
      session_number,
      session_id,
      session_start_timestamp,
      session_duration_sec,
      first_session,
      engaged_session,
      session_channel_grouping,
      session_source, 
      session_tld_source,
      session_campaign,
      session_device_type,
      session_country,
      session_browser_name,
      session_language,
      cross_domain_session,
      session_landing_page_category,
      session_landing_page_location,
      session_landing_page_title,
      session_exit_page_category,
      session_exit_page_location,
      session_exit_page_title,
      session_hostname,

      -- CONSENT DATA
      case 
        when consent_expressed = 'Yes' then 'Consent expressed'
        when consent_expressed = 'No' then 'Consent not expressed'
        else consent_expressed
      end as consent_state,
      consent AS consent_name,
      value AS consent_value_int_accepted
    FROM `tom-moretti.nameless_analytics.sessions`(start_date, end_date)
    UNPIVOT (
      value FOR consent IN (session_ad_user_data, session_ad_personalization, session_ad_storage, session_analytics_storage, session_functionality_storage, session_personalization_storage, session_security_storage)
    )
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
    session_duration_sec,
    first_session,
    engaged_session,
    session_channel_grouping,
    session_source, 
    session_tld_source,
    session_campaign,
    session_device_type,
    session_country,
    session_browser_name,
    session_language,
    cross_domain_session,
    session_landing_page_category,
    session_landing_page_location,
    session_landing_page_title,
    session_exit_page_category,
    session_exit_page_location,
    session_exit_page_title,
    session_hostname,

    -- CONSENT DATA
    consent_state,    
    case 
      when consent_state = 'Consent expressed' then session_id
      else null
    end as session_id_consent_expressed,
    case 
      when consent_state = 'Consent not expressed' then session_id
      else null
    end as session_id_consent_not_expressed,
    case 
      when consent_state = 'Consent mode not present' then session_id
      else null
    end as session_id_consent_mode_not_present,
    consent_name,
    case 
      when consent_state = 'Consent expressed' and consent_value_int_accepted = 1 then 'Granted'
      when consent_state = 'Consent expressed' and consent_value_int_accepted = 0 then 'Denied'
      else null
    end as consent_value_string,
    case 
      when consent_state = 'Consent expressed' and consent_name = "session_ad_user_data" and consent_value_int_accepted = 1 then 1
      when consent_state = 'Consent expressed' and consent_name = "session_ad_personalization" and consent_value_int_accepted = 1 then 1
      when consent_state = 'Consent expressed' and consent_name = "session_ad_storage" and consent_value_int_accepted = 1 then 1
      when consent_state = 'Consent expressed' and consent_name = "session_analytics_storage" and consent_value_int_accepted = 1 then 1
      when consent_state = 'Consent expressed' and consent_name = "session_functionality_storage" and consent_value_int_accepted = 1 then 1
      when consent_state = 'Consent expressed' and consent_name = "session_personalization_storage" and consent_value_int_accepted = 1 then 1
      when consent_state = 'Consent expressed' and consent_name = "session_security_storage" and consent_value_int_accepted = 1 then 1
      else null
    end as consent_value_int_accepted,
    case 
      when consent_state = 'Consent expressed' and consent_name = "session_ad_user_data" and consent_value_int_accepted = 0 then 1
      when consent_state = 'Consent expressed' and consent_name = "session_ad_personalization" and consent_value_int_accepted = 0 then 1
      when consent_state = 'Consent expressed' and consent_name = "session_ad_storage" and consent_value_int_accepted = 0 then 1
      when consent_state = 'Consent expressed' and consent_name = "session_analytics_storage" and consent_value_int_accepted = 0 then 1
      when consent_state = 'Consent expressed' and consent_name = "session_functionality_storage" and consent_value_int_accepted = 0 then 1
      when consent_state = 'Consent expressed' and consent_name = "session_personalization_storage" and consent_value_int_accepted = 0 then 1
      when consent_state = 'Consent expressed' and consent_name = "session_security_storage" and consent_value_int_accepted = 0 then 1
      else null
    end as consent_value_int_denied,
  from event_data
  group by all
);