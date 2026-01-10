CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.ec_shopping_stages_open_funnel`(start_date DATE, end_date DATE) AS (
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

      -- EVENT DATA
      event_name,
      event_date,
      -- event_timestamp,
    from `tom-moretti.nameless_analytics.events` (start_date, end_date, 'session_level')
  ),

  all_sessions as (
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
      event_date,
    from event_data
    group by all
  ),

  view_item as (
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
      event_date
    from event_data
    where event_name = 'view_item'
    group by all
  ),

  add_to_cart as (
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
      event_date
    from event_data
    where event_name = 'add_to_cart'
    group by all
  ),

  view_cart as (
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
      event_date
    from event_data
    where event_name = 'view_cart'
    group by all
  ),

  begin_checkout as (
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
      event_date
    from event_data
    where event_name = 'begin_checkout'
    group by all
  ),

  add_payment_info as (
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
      event_date
    from event_data
    where event_name = 'add_payment_info'
    group by all
  ),

  add_shipping_info as (
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
      event_date
    from event_data
    where event_name = 'add_shipping_info'
    group by all
  ),

  purchase as (
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
      event_date
    from event_data
    where event_name = 'purchase'
    group by all
  ),

  union_steps as (
    select 
      *,
      'All' as status,
      "0 - All" as step_name,
      0 as step_index
    from all_sessions

    union all

    select 
      *,
      case 
        when session_id not in (select session_id from all_sessions) then 'New funnel entries'
        else 'Continuing funnel entries'
      end as status,
      "1 - View item" as step_name,
      1 as step_index
    from view_item

    union all

    select 
      *,
      case 
        when session_id not in (select session_id from view_item) then 'New funnel entries'
        else 'Continuing funnel entries'
      end as status,
      "2 - Add to cart" as step_name,
      2 as step_index
    from add_to_cart

    union all

    select 
      *,
      case 
        when session_id not in (select session_id from add_to_cart) then 'New funnel entries'
        else 'Continuing funnel entries'
      end as status,
      "3 - Begin checkout" as step_name,
      3 as step_index
    from begin_checkout

    union all

    select 
      *,
      case 
        when session_id not in (select session_id from begin_checkout) then 'New funnel entries'
        else 'Continuing funnel entries'
      end as status,
      "4 - Add shipping info" as step_name,
      4 as step_index
    from add_shipping_info
        
    union all
        
    select 
      *,
      case 
        when session_id not in (select session_id from add_shipping_info) then 'New funnel entries'
        else 'Continuing funnel entries'
      end as status,
      "5 - Add payment info" as step_name,
      5 as step_index
    from add_payment_info
        
    union all

    select 
      *,
      case 
        when session_id not in (select session_id from add_payment_info) then 'New funnel entries'
        else 'Continuing funnel entries'
      end as status,
      "6 - Purchase" as step_name,
      6 as step_index
    from purchase
  ),
      
  union_steps_def as (
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
      event_date,
      step_name,
      step_index,
      case 
        when step_name = '6 - Purchase' then null 
        else step_index + 1 
      end as step_index_next_step_real,
      lead(step_index, 1) over (
        partition by client_id, user_id, user_channel_grouping, user_source, user_tld_source, user_campaign, user_device_type, user_country, user_language, user_type, new_user, returning_user, session_date, session_number, session_id, session_start_timestamp, session_end_timestamp, session_duration_sec, session_channel_grouping, session_source, session_tld_source, session_campaign, cross_domain_session, session_landing_page_category, session_landing_page_location, session_landing_page_title, session_exit_page_category, session_exit_page_location, session_exit_page_title, session_hostname, session_device_type, session_country, session_language, session_browser_name
        order by event_date, client_id, user_id, user_channel_grouping, user_source, user_tld_source, user_campaign, user_device_type, user_country, user_language, user_type, new_user, returning_user, session_date, session_number, session_id, session_start_timestamp, session_end_timestamp, session_duration_sec, session_channel_grouping, session_source, session_tld_source, session_campaign, cross_domain_session, session_landing_page_category, session_landing_page_location, session_landing_page_title, session_exit_page_category, session_exit_page_location, session_exit_page_title, session_hostname, session_device_type, session_country, session_language, session_browser_name, step_name
      ) as step_index_next_step,
      status,
      lead(client_id, 1) over (
        partition by client_id, user_id, user_channel_grouping, user_source, user_tld_source, user_campaign, user_device_type, user_country, user_language, user_type, new_user, returning_user, session_date, session_number, session_id, session_start_timestamp, session_end_timestamp, session_duration_sec, session_channel_grouping, session_source, session_tld_source, session_campaign, cross_domain_session, session_landing_page_category, session_landing_page_location, session_landing_page_title, session_exit_page_category, session_exit_page_location, session_exit_page_title, session_hostname, session_device_type, session_country, session_language, session_browser_name
        order by event_date, client_id, user_id, user_channel_grouping, user_source, user_tld_source, user_campaign, user_device_type, user_country, user_language, user_type, new_user, returning_user, session_date, session_number, session_id, session_start_timestamp, session_end_timestamp, session_duration_sec, session_channel_grouping, session_source, session_tld_source, session_campaign, cross_domain_session, session_landing_page_category, session_landing_page_location, session_landing_page_title, session_exit_page_category, session_exit_page_location, session_exit_page_title, session_hostname, session_device_type, session_country, session_language, session_browser_name, step_name
      ) as client_id_next_step,
      lead(session_id, 1) over (
        partition by client_id, user_id, user_channel_grouping, user_source, user_tld_source, user_campaign, user_device_type, user_country, user_language, user_type, new_user, returning_user, session_date, session_number, session_id, session_start_timestamp, session_end_timestamp, session_duration_sec, session_channel_grouping, session_source, session_tld_source, session_campaign, cross_domain_session, session_landing_page_category, session_landing_page_location, session_landing_page_title, session_exit_page_category, session_exit_page_location, session_exit_page_title, session_hostname, session_device_type, session_country, session_language, session_browser_name
        order by event_date, client_id, user_id, user_channel_grouping, user_source, user_tld_source, user_campaign, user_device_type, user_country, user_language, user_type, new_user, returning_user, session_date, session_number, session_id, session_start_timestamp, session_end_timestamp, session_duration_sec, session_channel_grouping, session_source, session_tld_source, session_campaign, cross_domain_session, session_landing_page_category, session_landing_page_location, session_landing_page_title, session_exit_page_category, session_exit_page_location, session_exit_page_title, session_hostname, session_device_type, session_country, session_language, session_browser_name, step_name
      ) as session_id_next_step,
    from union_steps
  )

  select 
    event_date,
    client_id,
    user_id,
    session_id,
    session_channel_grouping,
    split(session_tld_source, '.')[safe_offset(0)] as session_source,
    session_tld_source,
    session_campaign,
    session_device_type,
    session_country,
    session_language,
    step_name,
    step_index,
    step_index_next_step_real,
    step_index_next_step,
    status,
    case 
      when step_name = '6 - Purchase' then null 
      else case when step_index_next_step_real = step_index_next_step then client_id_next_step else null end 
    end as client_id_next_step,
    case 
      when step_name = '6 - Purchase' then null 
      else case when step_index_next_step_real = step_index_next_step then session_id_next_step else null end 
    end as session_id_next_step,
  from union_steps_def
  where true 
    and event_date between start_date and end_date
);