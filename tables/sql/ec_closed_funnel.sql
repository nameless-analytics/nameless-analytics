CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.ec_closed_funnel`(start_date DATE, end_date DATE) AS (
with session_steps as (
    select
      client_id,
      session_date,
      session_id,
      session_start_timestamp,
      session_channel_grouping, 
      session_source_cleaned as session_source,
      session_campaign,
      session_campaign_id,
      session_campaign_click_id,
      session_campaign_term,
      session_campaign_content,
      session_device_type, 
      session_country,

      MIN(IF(event_name = 'view_item', event_timestamp, NULL)) AS view_item_ts,
      MIN(IF(event_name = 'add_to_cart', event_timestamp, NULL)) AS add_to_cart_ts,
      MIN(IF(event_name = 'view_cart', event_timestamp, NULL)) AS view_cart_ts,
      MIN(IF(event_name = 'begin_checkout', event_timestamp, NULL)) AS begin_checkout_ts,
      MIN(IF(event_name = 'add_shipping_info', event_timestamp, NULL)) AS add_shipping_info_ts,
      MIN(IF(event_name = 'add_payment_info', event_timestamp, NULL)) AS add_payment_info_ts,
      MIN(IF(event_name = 'purchase', event_timestamp, NULL)) AS purchase_ts
  
    from `tom-moretti.nameless_analytics.events`(start_date, end_date, 'session')
    where event_name in ('view_item', 'add_to_cart', 'view_cart', 'begin_checkout', 'add_shipping_info', 'add_payment_info', 'purchase')
    group by all
  )
  
  select
    session_date,
    client_id,
    session_id,
    session_channel_grouping, 
    session_source,
    session_campaign,
    session_campaign_id,
    session_campaign_click_id,
    session_campaign_term,
    session_campaign_content,
    session_device_type, 
    session_country,
    case when session_start_timestamp is not null then client_id end as session_start,
    case when view_item_ts > session_start_timestamp then client_id end as view_item,
    case when view_item_ts > session_start_timestamp and add_to_cart_ts > view_item_ts then client_id end as add_to_cart,
    case when view_item_ts > session_start_timestamp and add_to_cart_ts > view_item_ts and view_cart_ts > add_to_cart_ts then client_id end as view_cart,
    case when view_item_ts > session_start_timestamp and add_to_cart_ts > view_item_ts and view_cart_ts > add_to_cart_ts and begin_checkout_ts > add_to_cart_ts then client_id end as begin_checkout,
    case when view_item_ts > session_start_timestamp and add_to_cart_ts > view_item_ts and view_cart_ts > add_to_cart_ts and begin_checkout_ts > add_to_cart_ts and add_shipping_info_ts > begin_checkout_ts then client_id end as add_shipping_info,
    case when view_item_ts > session_start_timestamp and add_to_cart_ts > view_item_ts and view_cart_ts > add_to_cart_ts and begin_checkout_ts > add_to_cart_ts and add_shipping_info_ts > begin_checkout_ts and add_payment_info_ts > add_shipping_info_ts then client_id end as add_payment_info,
    case when view_item_ts > session_start_timestamp and add_to_cart_ts > view_item_ts and view_cart_ts > add_to_cart_ts and begin_checkout_ts > add_to_cart_ts and add_shipping_info_ts > begin_checkout_ts and add_payment_info_ts > add_shipping_info_ts and purchase_ts > add_payment_info_ts then client_id end as purchase
  from session_steps
);