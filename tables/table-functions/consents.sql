/* @datacloud.settings
{
  "version": 1,
  "service": "BIG_QUERY",
  "connectionInfo": {
    "billingProjectId": "INHERIT",
    "location": "INHERIT"
  },
  "dialect": "GOOGLE_SQL"
}
*/

CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.consents`(start_date DATE, end_date DATE) AS (
with consent_data as (
    select
      # USER DATA
      user_date, 
      user_id, 
      client_id, 
      user_channel_grouping, 
      user_custom_channel_grouping, 
      user_source,
      user_campaign_year,
      user_campaign_country,
      user_campaign_funnel_stage,
      user_campaign_platform,
      user_campaign_type,
      user_campaign_marketing_objective,
      user_campaign_name,
      user_campaign, 
      user_device_type, 
      user_city,
      user_country, 
      user_language, 
      user_type, 
      new_user_client_id, 
      returning_user_client_id,

      # SESSION DATA
      session_date,
      session_number,
      session_id,
      session_start_timestamp,
      session_duration_sec,
      engaged_session,
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
      session_device_type,
      session_country, 
      session_city,
      session_browser_name,
      session_language,
      cross_domain_session,
      session_landing_page_category,
      session_landing_page_url,
      session_landing_page_path,
      session_landing_page_title,
      session_exit_page_category,
      session_exit_page_url,
      session_exit_page_path,
      session_exit_page_title,
      session_hostname,

      # CONSENT DATA
      case 
        when consent_expressed = 'Yes' then 'Consent expressed'
        when consent_expressed = 'No' then 'Consent not expressed'
        else consent_expressed
      end as consent_state,
      consent_name,
      consent_value_int_accepted_raw
    from `tom-moretti.nameless_analytics.sessions`(start_date, end_date)
    unpivot (
      consent_value_int_accepted_raw for consent_name in (
        session_ad_user_data, 
        session_ad_personalization, 
        session_ad_storage, 
        session_analytics_storage, 
        session_functionality_storage, 
        session_personalization_storage, 
        session_security_storage
      )
    )
  )

  select 
    # USER DATA
    user_date,
    user_id,
    client_id,
    user_channel_grouping,
    user_custom_channel_grouping,
    user_source,
    user_campaign_year,
    user_campaign_country,
    user_campaign_funnel_stage,
    user_campaign_platform,
    user_campaign_type,
    user_campaign_marketing_objective,
    user_campaign_name,
    user_campaign,
    user_device_type,
    user_city,
    user_country,
    user_language,
    user_type,
    new_user_client_id,
    returning_user_client_id,
  
    # SESSION DATA
    session_date,
    session_number,
    session_id,
    session_start_timestamp,
    session_duration_sec,
    engaged_session,
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
    session_device_type,
    session_country, 
    session_city,
    session_browser_name,
    session_language,
    cross_domain_session,
    session_landing_page_category,
    session_landing_page_url,
    session_landing_page_path,
    session_landing_page_title,
    session_exit_page_category,
    session_exit_page_url,
    session_exit_page_path,
    session_exit_page_title,
    session_hostname,

    # CONSENT DATA
    consent_state,    
    case when consent_state = 'Consent expressed' then session_id end as session_id_consent_expressed,
    case when consent_state = 'Consent not expressed' then session_id end as session_id_consent_not_expressed,
    case when consent_state = 'Consent mode not present' then session_id end as session_id_consent_mode_not_present,
    consent_name,
    case 
      when consent_state = 'Consent expressed' and consent_value_int_accepted_raw = 1 then 'Granted'
      when consent_state = 'Consent expressed' and consent_value_int_accepted_raw = 0 then 'Denied'
    end as consent_value_string,
    case when consent_state = 'Consent expressed' and consent_value_int_accepted_raw = 1 then 1 end as consent_value_int_accepted,
    case when consent_state = 'Consent expressed' and consent_value_int_accepted_raw = 0 then 1 end as consent_value_int_denied
  from consent_data
  group by all
);