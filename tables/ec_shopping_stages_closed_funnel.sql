CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.ec_shopping_stages_closed_funnel`(start_date DATE, end_date DATE) AS (
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
      event_date
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

  join_steps as (
    select 
      -- USER DATA
      all_sessions.user_date,
      all_sessions.client_id as all_sessions_client_id,
      all_sessions.user_id as all_sessions_user_id,
      all_sessions.user_channel_grouping,
      all_sessions.user_source,
      all_sessions.user_tld_source,
      all_sessions.user_campaign,
      all_sessions.user_device_type,
      all_sessions.user_country,
      all_sessions.user_language,
      all_sessions.user_type,
      all_sessions.new_user,
      all_sessions.returning_user,
  
      -- SESSION DATA
      all_sessions.session_date,
      all_sessions.session_number,
      all_sessions.session_id as all_sessions_sessions,
      all_sessions.session_start_timestamp,
      all_sessions.session_end_timestamp,
      all_sessions.session_duration_sec,
      all_sessions.session_channel_grouping,
      split(all_sessions.session_tld_source, '.')[safe_offset(0)] as session_source,
      all_sessions.session_tld_source,
      all_sessions.session_campaign,
      all_sessions.cross_domain_session,  
      all_sessions.session_landing_page_category,
      all_sessions.session_landing_page_location,
      all_sessions.session_landing_page_title,
      all_sessions.session_exit_page_category,
      all_sessions.session_exit_page_location,
      all_sessions.session_exit_page_title,
      all_sessions.session_hostname,
      all_sessions.session_device_type,
      all_sessions.session_country,
      all_sessions.session_language,
      all_sessions.session_browser_name,
      
      all_sessions.event_date,

      view_item.client_id as view_item_client_id,
      add_to_cart.client_id as add_to_cart_client_id,
      begin_checkout.client_id as begin_checkout_client_id,
      add_shipping_info.client_id as add_shipping_info_client_id,
      add_payment_info.client_id as add_payment_info_client_id,
      purchase.client_id as purchase_client_id,

      view_item.user_id as view_item_user_id,
      add_to_cart.user_id as add_to_cart_user_id,
      begin_checkout.user_id as begin_checkout_user_id,
      add_shipping_info.user_id as add_shipping_info_user_id,
      add_payment_info.user_id as add_payment_info_user_id,
      purchase.user_id as purchase_user_id,

      view_item.session_id as view_item_sessions,
      add_to_cart.session_id as add_to_cart_sessions,
      begin_checkout.session_id as begin_checkout_sessions,
      add_shipping_info.session_id as add_shipping_info_sessions,
      add_payment_info.session_id as add_payment_info_sessions,
      purchase.session_id as purchase_sessions

    from all_sessions
      left join view_item
        on all_sessions.session_id = view_item.session_id
      left join add_to_cart
        on view_item.session_id = add_to_cart.session_id
      left join begin_checkout
        on add_to_cart.session_id = begin_checkout.session_id
      left join add_shipping_info
        on begin_checkout.session_id = add_shipping_info.session_id
      left join add_payment_info
        on add_shipping_info.session_id = add_payment_info.session_id
      left join purchase
        on add_payment_info.session_id = purchase.session_id
  ),

  steps_pivot as (
    select 
      *
    from join_steps
      unpivot((client_id, user_id, session_id) for step_name in (
        (all_sessions_client_id, all_sessions_user_id, all_sessions_sessions) as "0 - All",
        (view_item_client_id, view_item_user_id, view_item_sessions) as "1 - View item",
        (add_to_cart_client_id, add_to_cart_user_id, add_to_cart_sessions) as "2 - Add to cart",
        (begin_checkout_client_id, begin_checkout_user_id, begin_checkout_sessions) as "3 - Begin checkout",
        (add_shipping_info_client_id, add_shipping_info_user_id, add_shipping_info_sessions) as "4 - Add shipping info",
        (add_payment_info_client_id, add_payment_info_user_id, add_payment_info_sessions) as "5 - Add payment info",
        (purchase_client_id, purchase_user_id, purchase_sessions) as "6 - Purchase"
      ))
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
    lead(client_id, 1) over (
      partition by client_id, user_id, user_channel_grouping, user_source, user_tld_source, user_campaign, user_device_type, user_country, user_language, user_type, new_user, returning_user, session_date, session_number, session_id, session_start_timestamp, session_end_timestamp, session_duration_sec, session_channel_grouping, session_source, session_tld_source, session_campaign, cross_domain_session, session_landing_page_category, session_landing_page_location, session_landing_page_title, session_exit_page_category, session_exit_page_location, session_exit_page_title, session_hostname, session_device_type, session_country, session_language, session_browser_name
      order by event_date, client_id, user_id, user_channel_grouping, user_source, user_tld_source, user_campaign, user_device_type, user_country, user_language, user_type, new_user, returning_user, session_date, session_number, session_id, session_start_timestamp, session_end_timestamp, session_duration_sec, session_channel_grouping, session_source, session_tld_source, session_campaign, cross_domain_session, session_landing_page_category, session_landing_page_location, session_landing_page_title, session_exit_page_category, session_exit_page_location, session_exit_page_title, session_hostname, session_device_type, session_country, session_language, session_browser_name, step_name
    ) as client_id_next_step,
    lead(user_id, 1) over (
      partition by client_id, user_id, user_channel_grouping, user_source, user_tld_source, user_campaign, user_device_type, user_country, user_language, user_type, new_user, returning_user, session_date, session_number, session_id, session_start_timestamp, session_end_timestamp, session_duration_sec, session_channel_grouping, session_source, session_tld_source, session_campaign, cross_domain_session, session_landing_page_category, session_landing_page_location, session_landing_page_title, session_exit_page_category, session_exit_page_location, session_exit_page_title, session_hostname, session_device_type, session_country, session_language, session_browser_name
      order by event_date, client_id, user_id, user_channel_grouping, user_source, user_tld_source, user_campaign, user_device_type, user_country, user_language, user_type, new_user, returning_user, session_date, session_number, session_id, session_start_timestamp, session_end_timestamp, session_duration_sec, session_channel_grouping, session_source, session_tld_source, session_campaign, cross_domain_session, session_landing_page_category, session_landing_page_location, session_landing_page_title, session_exit_page_category, session_exit_page_location, session_exit_page_title, session_hostname, session_device_type, session_country, session_language, session_browser_name, step_name
    ) as user_id_next_step,
    lead(session_id, 1) over (
      partition by client_id, user_id, user_channel_grouping, user_source, user_tld_source, user_campaign, user_device_type, user_country, user_language, user_type, new_user, returning_user, session_date, session_number, session_id, session_start_timestamp, session_end_timestamp, session_duration_sec, session_channel_grouping, session_source, session_tld_source, session_campaign, cross_domain_session, session_landing_page_category, session_landing_page_location, session_landing_page_title, session_exit_page_category, session_exit_page_location, session_exit_page_title, session_hostname, session_device_type, session_country, session_language, session_browser_name
      order by event_date, client_id, user_id, user_channel_grouping, user_source, user_tld_source, user_campaign, user_device_type, user_country, user_language, user_type, new_user, returning_user, session_date, session_number, session_id, session_start_timestamp, session_end_timestamp, session_duration_sec, session_channel_grouping, session_source, session_tld_source, session_campaign, cross_domain_session, session_landing_page_category, session_landing_page_location, session_landing_page_title, session_exit_page_category, session_exit_page_location, session_exit_page_title, session_hostname, session_device_type, session_country, session_language, session_browser_name, step_name
    ) as session_id_next_step
  from steps_pivot
  where true 
    and event_date between start_date and end_date
  group by all
);