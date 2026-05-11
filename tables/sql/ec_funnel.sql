CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.ec_funnel`(start_date DATE, end_date DATE) AS (
WITH sessions AS (
  SELECT
    session_date,
    client_id,
    session_id,
    session_channel_grouping,
    session_source_cleaned AS session_source,
    session_campaign,
    session_campaign_id,
    session_campaign_click_id,
    session_campaign_term,
    session_campaign_content,
    session_device_type,
    session_country,
    1 as session_start,
    countif(event_name = 'view_item') as view_item,
    countif(event_name = 'add_to_cart') as add_to_cart,
    countif(event_name = 'view_cart') as view_cart,
    countif(event_name = 'begin_checkout') as begin_checkout,
    countif(event_name = 'add_shipping_info') as add_shipping_info,
    countif(event_name = 'add_payment_info') as add_payment_info,
    countif(event_name = 'purchase') as purchase,
  FROM `tom-moretti.nameless_analytics.events`(start_date, end_date, 'session')
  group by all
)

select
  client_id,
  session_date,
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
  if(session_start > 0, client_id, null) as session_start,
  if(session_start > 0 and view_item > 0, client_id, null) as view_item,
  if(session_start > 0 and view_item > 0 and add_to_cart > 0, client_id, null) as add_to_cart, 	
  if(session_start > 0 and view_item > 0 and add_to_cart > 0 and view_cart > 0, client_id, null) as view_cart,
  if(session_start > 0 and view_item > 0 and add_to_cart > 0 and view_cart > 0 and begin_checkout > 0, client_id, null) as begin_checkout, 	
  if(session_start > 0 and view_item > 0 and add_to_cart > 0 and view_cart > 0 and begin_checkout > 0 and add_shipping_info > 0, client_id, null) as add_shipping_info, 	
  if(session_start > 0 and view_item > 0 and add_to_cart > 0 and view_cart > 0 and begin_checkout > 0 and add_shipping_info > 0 and add_payment_info > 0, client_id, null) as add_payment_info, 	
  if(session_start > 0 and view_item > 0 and add_to_cart > 0 and view_cart > 0 and begin_checkout > 0 and add_shipping_info > 0 and add_payment_info > 0 and purchase > 0, client_id, null) as purchase, 
from sessions
);