CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.ec_transactions`(start_date DATE, end_date DATE) AS (
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
      user_source,
      user_tld_source, 
      user_campaign, 
      user_campaign_id,
      user_campaign_click_id,
      user_campaign_term,
      user_campaign_content,
      user_device_type, 
      user_country, 
      user_language, 

      # SESSION DATA
      session_date, 
      session_id, 
      session_number, 
      cross_domain_session, 
      session_start_timestamp, 
      session_end_timestamp,
      session_duration_sec,
      new_session,
      returning_session,
      session_channel_grouping, 
      session_source,
      session_tld_source, 
      session_campaign,
      session_campaign_id,
      session_campaign_click_id,
      session_campaign_term,
      session_campaign_content,
      session_device_type, 
      session_browser_name,
      session_country, 
      session_language,
      session_hostname,

      # EVENT DATA
      event_date,
      event_timestamp,
      event_name,
      ecommerce
    from `tom-moretti.nameless_analytics.events`(start_date, end_date, 'session')
    where regexp_contains(event_name, 'purchase|refund')
  ),

  transaction_logic as (
    select
      # USER DATA
      user_date,
      client_id,
      user_id,
      user_channel_grouping,
      split(user_tld_source, '.')[safe_offset(0)] as user_source_split,
      user_tld_source,
      user_campaign,
      user_device_type,
      user_country,
      user_language,
      user_type,
      new_user,
      returning_user,

      # SESSION DATA
      session_number,
      session_id,
      session_start_timestamp,
      session_channel_grouping,
      split(session_tld_source, '.')[safe_offset(0)] as session_source_split,
      session_tld_source,
      session_campaign,
      cross_domain_session,
      session_device_type,
      session_country,
      session_browser_name,
      session_language,

      # EVENT DATA
      event_date,
      event_name,
      timestamp_millis(event_timestamp) as event_datetime,

      # ECOMMERCE DATA
      json_value(ecommerce, '$.transaction_id') as transaction_id,
      json_value(ecommerce, '$.currency') as transaction_currency,
      json_value(ecommerce, '$.coupon') as transaction_coupon,
      
      if(event_name = 'purchase', ifnull(safe_cast(json_value(ecommerce, '$.value') as float64), 0.0), 0) as purchase_revenue,
      if(event_name = 'purchase', ifnull(safe_cast(json_value(ecommerce, '$.shipping') as float64), 0.0), 0) as purchase_shipping,
      if(event_name = 'purchase', ifnull(safe_cast(json_value(ecommerce, '$.tax') as float64), 0.0), 0) as purchase_tax,
      
      if(event_name = 'refund', ifnull(safe_cast(json_value(ecommerce, '$.value') as float64), 0.0), 0) as refund_revenue,
      if(event_name = 'refund', ifnull(safe_cast(json_value(ecommerce, '$.shipping') as float64), 0.0), 0) as refund_shipping,
      if(event_name = 'refund', ifnull(safe_cast(json_value(ecommerce, '$.tax') as float64), 0.0), 0) as refund_tax
    from base_events
  ),

  transaction_prep as (
    select
      # USER DATA
      user_date,
      client_id,
      user_id,
      user_channel_grouping,
      user_source_split,
      user_tld_source,
      user_campaign,
      user_device_type,
      user_country,
      user_language,
      user_type,
      new_user,
      returning_user,

      # SESSION DATA
      session_number,
      session_id,
      session_start_timestamp,
      session_channel_grouping,
      session_source_split,
      session_tld_source,
      session_campaign,
      cross_domain_session,
      session_device_type,
      session_country,
      session_browser_name,
      session_language,

      # EVENT DATA
      event_date,
      event_name,
      event_datetime,

      # ECOMMERCE DATA
      transaction_id,
      transaction_currency,
      transaction_coupon,
      purchase_revenue,
      purchase_shipping,
      purchase_tax,
      refund_revenue,
      refund_shipping,
      refund_tax,
      
      countif(event_name = 'purchase') as purchase,
      countif(event_name = 'refund') as refund,
      sum(purchase_revenue) as total_purchase_revenue,
      sum(purchase_shipping) as total_purchase_shipping,
      sum(purchase_tax) as total_purchase_tax,
      sum(refund_revenue) as total_refund_revenue,
      sum(refund_shipping) as total_refund_shipping,
      sum(refund_tax) as total_refund_tax
    from transaction_logic
    group by all
  )

  select
    # USER DATA
    user_date,
    client_id,
    user_id,
    user_channel_grouping,
    user_source_split as user_source,
    user_tld_source,
    user_campaign,
    user_device_type,
    user_country,
    user_language,
    user_type,
    new_user,
    returning_user,

    # SESSION DATA
    session_number,
    session_id,
    session_start_timestamp,
    session_channel_grouping,
    session_source_split as session_source,
    session_tld_source,
    session_campaign,
    cross_domain_session,
    session_device_type,
    session_country,
    session_language,
    session_browser_name,
    
    # EVENT DATA
    event_date,
    event_name,
    event_datetime as event_timestamp,

    # ECOMMERCE DATA
    transaction_id, 
    purchase,
    refund,
    transaction_currency,
    transaction_coupon,
    total_purchase_revenue as purchase_revenue,
    total_purchase_shipping as purchase_shipping,
    total_purchase_tax as purchase_tax,
    total_refund_revenue as refund_revenue,
    total_refund_shipping as refund_shipping,
    total_refund_tax as refund_tax,
    purchase - refund as purchase_net_refund,
    ifnull(total_purchase_revenue, 0) - ifnull(total_refund_revenue, 0) as revenue_net_refund,
    ifnull(total_purchase_shipping, 0) + ifnull(total_refund_shipping, 0) as shipping_net_refund,
    ifnull(total_purchase_tax, 0) + ifnull(total_refund_tax, 0) as tax_net_refund
  from transaction_prep
  group by all
);