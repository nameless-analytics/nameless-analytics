CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.ec_transactions`(start_date DATE, end_date DATE) AS (
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
      event_date,
      event_name,
      timestamp_millis(event_timestamp) as event_timestamp,
      event_origin,

      -- ECOMMERCE DATA
      ecommerce,
    from `tom-moretti.nameless_analytics.events` (start_date, end_date, 'session')
  ),

  transaction_data as (
    select 
      -- USER DATA
      user_date,
      client_id,
      user_id,
      user_channel_grouping,
      split(user_tld_source, '.')[safe_offset(0)] as user_source,
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
      session_channel_grouping,
      split(session_tld_source, '.')[safe_offset(0)] as session_source,
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
      event_date,
      event_name,
      event_timestamp,
      event_origin,

      -- ECOMMERCE DATA
      json_value(ecommerce.transaction_id) as transaction_id,
      json_value(ecommerce.currency) as transaction_currency,
      json_value(ecommerce.coupon) as transaction_coupon,
      case
        when event_name = 'purchase' then ifnull(cast(json_value(ecommerce.value) as float64), 0.0)
        else null
      end as purchase_revenue,
      case
        when event_name = 'purchase' then ifnull(cast(json_value(ecommerce.shipping) as float64), 0.0)
        else null
      end as purchase_shipping,
      case
        when event_name = 'purchase' then ifnull(cast(json_value(ecommerce.tax) as float64), 0.0)
        else null
      end as purchase_tax,
      case
        when event_name = 'refund' then ifnull(cast(json_value(ecommerce.value) as float64), 0.0)
        else null
      end as refund_revenue,
      case
        when event_name = 'refund' then ifnull(cast(json_value(ecommerce.shipping) as float64), 0.0)
        else null
      end as refund_shipping,
      case
        when event_name = 'refund' then ifnull(cast(json_value(ecommerce.tax) as float64), 0.0)
        else null
      end as refund_tax,
    from event_data
  ),

  transaction_data_def as (
    select 
      -- USER DATA
      user_date,
      client_id,
      user_id,
      user_channel_grouping,
      split(user_tld_source, '.')[safe_offset(0)] as user_source,
      user_tld_source,
      user_campaign,
      user_device_type,
      user_country,
      user_language,
      user_type,
      new_user,
      returning_user,
      
      -- SESSION DATA
      session_number,
      session_id,
      session_start_timestamp,
      session_channel_grouping,
      split(session_tld_source, '.')[safe_offset(0)] as session_source,
      session_tld_source,
      session_campaign,
      cross_domain_session,
      session_device_type,
      session_country,
      session_browser_name,
      session_language,
      
      -- EVENT DATA
      event_date,
      event_name,
      event_timestamp,
      event_origin,

      -- ECOMMERCE DATA
      countif(event_name = 'purchase') as purchase,
      countif(event_name = 'refund') as refund,
      transaction_id,
      transaction_currency,
      transaction_coupon,
      sum(purchase_revenue) as purchase_revenue,
      sum(purchase_shipping) as purchase_shipping,
      sum(purchase_tax) as purchase_tax,
      sum(refund_revenue) as refund_revenue,
      sum(refund_shipping) as refund_shipping,
      sum(refund_tax) as refund_tax,
    from transaction_data
    where true
      and regexp_contains(event_name, 'purchase|refund')
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
    session_number,
    session_id,
    session_start_timestamp,
    session_channel_grouping,
    session_source,
    session_tld_source,
    session_campaign,
    cross_domain_session,
    session_device_type,
    session_country,
    session_language,
    session_browser_name,
    
    -- EVENT DATA
    event_date,
    event_name,
    event_timestamp,
    event_origin,

    -- ECOMMERCE DATA
    transaction_id, 
    purchase,
    refund,
    transaction_currency,
    transaction_coupon,
    purchase_revenue,
    purchase_shipping,
    purchase_tax,
    refund_revenue,
    refund_shipping,
    refund_tax,
    purchase - refund as purchase_net_refund,
    ifnull(purchase_revenue, 0) - ifnull(refund_revenue, 0) as revenue_net_refund,
    ifnull(purchase_shipping, 0) + ifnull(refund_shipping, 0) as shipping_net_refund,
    ifnull(purchase_tax, 0) + ifnull(refund_tax, 0) as tax_net_refund,
  from transaction_data_def
);