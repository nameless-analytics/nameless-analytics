CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.ec_closed_funnel`(start_date DATE, end_date DATE) AS (
WITH sessions AS (
    SELECT
      client_id,
      session_date,
      session_id,
      session_start_timestamp,
      session_channel_grouping,
      session_source_cleaned AS session_source,
      session_campaign,
      session_campaign_id,
      session_campaign_click_id,
      session_campaign_term,
      session_campaign_content,
      session_device_type,
      session_country
    FROM `tom-moretti.nameless_analytics.events`(start_date, end_date, 'session')
    group by all
  ),

  ecommerce_events AS (
    SELECT
      client_id,
      session_id,
      event_name,
      event_timestamp
    FROM `tom-moretti.nameless_analytics.events`(start_date, end_date, 'session')
    WHERE event_name IN ('view_item', 'add_to_cart', 'view_cart', 'begin_checkout', 'add_shipping_info', 'add_payment_info', 'purchase')
  ),

  session_steps AS (
    SELECT
      sessions.*,
      MIN(IF(event_name = 'view_item', event_timestamp, NULL)) AS view_item_ts,
      MIN(IF(event_name = 'add_to_cart', event_timestamp, NULL)) AS add_to_cart_ts,
      MIN(IF(event_name = 'view_cart', event_timestamp, NULL)) AS view_cart_ts,
      MIN(IF(event_name = 'begin_checkout', event_timestamp, NULL)) AS begin_checkout_ts,
      MIN(IF(event_name = 'add_shipping_info', event_timestamp, NULL)) AS add_shipping_info_ts,
      MIN(IF(event_name = 'add_payment_info', event_timestamp, NULL)) AS add_payment_info_ts,
      MIN(IF(event_name = 'purchase', event_timestamp, NULL)) AS purchase_ts
    FROM sessions
    LEFT JOIN ecommerce_events
      USING(client_id, session_id)
    GROUP BY ALL
  )

  SELECT
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

    -- FUNNEL STEPS
    CASE WHEN session_start_timestamp IS NOT NULL THEN client_id END AS session_start,
    CASE WHEN view_item_ts > session_start_timestamp THEN client_id END AS view_item,
    CASE WHEN (view_item_ts > session_start_timestamp AND add_to_cart_ts > view_item_ts )THEN client_id END AS add_to_cart,
    CASE WHEN (view_item_ts > session_start_timestamp AND add_to_cart_ts > view_item_ts AND view_cart_ts > add_to_cart_ts) THEN client_id END AS view_cart,
    CASE WHEN (view_item_ts > session_start_timestamp AND add_to_cart_ts > view_item_ts AND view_cart_ts > add_to_cart_ts AND begin_checkout_ts > view_cart_ts )THEN client_id END AS begin_checkout,
    CASE WHEN (view_item_ts > session_start_timestamp AND add_to_cart_ts > view_item_ts AND view_cart_ts > add_to_cart_ts AND begin_checkout_ts > view_cart_ts AND add_shipping_info_ts > begin_checkout_ts)THEN client_id END AS add_shipping_info,
    CASE WHEN (view_item_ts > session_start_timestamp AND add_to_cart_ts > view_item_ts AND view_cart_ts > add_to_cart_ts AND begin_checkout_ts > view_cart_ts AND add_shipping_info_ts > begin_checkout_ts AND add_payment_info_ts > add_shipping_info_ts) THEN client_id END AS add_payment_info,
    CASE WHEN (view_item_ts > session_start_timestamp AND add_to_cart_ts > view_item_ts AND view_cart_ts > add_to_cart_ts AND begin_checkout_ts > view_cart_ts AND add_shipping_info_ts > begin_checkout_ts AND add_payment_info_ts > add_shipping_info_ts AND purchase_ts > add_payment_info_ts) THEN client_id END AS purchase
  FROM session_steps
);