CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.ec_closed_funnel_pivot`(start_date DATE, end_date DATE) AS (
select
    session_date as date,
    client_id,
    session_id,

    session_channel_grouping,
    session_source,
    session_campaign,
    session_device_type,
    session_country,
    case
      when step = 'session_start' then 1
      when step = 'view_item' then 2
      when step = 'add_to_cart' then 3
      when step = 'view_cart' then 4
      when step = 'begin_checkout' then 5
      when step = 'add_shipping_info' then 6
      when step = 'add_payment_info' then 7
      when step = 'purchase' then 8
    end as step_number,
    step,

  from `tom-moretti.nameless_analytics.ec_closed_funnel`(start_date, end_date)

  unpivot (
    step_client_id for step in (
      session_start,
      view_item,
      add_to_cart,
      view_cart,
      begin_checkout,
      add_shipping_info,
      add_payment_info,
      purchase
    )
  )
);