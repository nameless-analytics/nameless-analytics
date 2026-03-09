CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.ec_transactions`(start_date DATE, end_date DATE) AS (
  with transaction_data_raw as (
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

      # EVENT DATA
      event_date,
      FORMAT_TIMESTAMP('%H:%M:%S', TIMESTAMP_MILLIS(event_timestamp)) AS hour_and_minute,
      event_name,
      event_origin,

      # ECOMMERCE DATA
      json_value(ecommerce, '$.transaction_id') as transaction_id,
      safe_cast(json_value(ecommerce, '$.value') as float64) as transaction_revenue,
      safe_cast(json_value(ecommerce, '$.tax') as float64) as transaction_tax,
      safe_cast(json_value(ecommerce, '$.shipping') as float64) as transaction_shipping,
      json_value(ecommerce, '$.currency') as transaction_currency,
      json_value(ecommerce, '$.coupon') as transaction_coupon
    from `tom-moretti.nameless_analytics.events`('2026-01-01', '2026-04-01', 'session')
    where regexp_contains(event_name, 'purchase|refund')
  )

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
    session_source,
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

    # EVENT DATA
    event_date,
    hour_and_minute,
    event_name,
    event_origin,

    # ECOMMERCE DATA      
    transaction_id,

    case
      when event_name = 'purchase' then 1
      else 0
    end as purchase,
    countif(event_name = 'purchase') over (partition by transaction_id) as duplicate_purchase, 
    if(event_name = 'purchase', ifnull(transaction_revenue, 0.0), 0) as purchase_revenue,
    if(event_name = 'purchase', ifnull(transaction_tax, 0.0), 0) as purchase_tax,
    if(event_name = 'purchase', ifnull(transaction_shipping, 0.0), 0) as purchase_shipping,
    if(event_name = 'purchase', ifnull(transaction_currency, null), null) as purchase_currency,
    if(event_name = 'purchase', ifnull(transaction_coupon, null), null) as purchase_coupon,

    case
      when event_name = 'refund' then 1
      else 0
    end as refund,
    countif(event_name = 'purchase') over (partition by transaction_id) as duplicate_refund, 
    if(event_name = 'refund', ifnull(transaction_revenue, 0.0), 0) as refund_revenue,
    if(event_name = 'refund', ifnull(transaction_shipping, 0.0), 0) as refund_shipping,
    if(event_name = 'refund', ifnull(transaction_tax, 0.0), 0) as refund_tax,
    if(event_name = 'refund', ifnull(transaction_currency, null), null) as refund_currency,
    if(event_name = 'refund', ifnull(transaction_coupon, null), null) as refund_coupon
  from transaction_data_raw
);