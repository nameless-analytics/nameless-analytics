CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.users`(start_date DATE, end_date DATE) AS (
  with base_events as (
    select 
      # USER DATA
      user_date,
      client_id,
      user_id,
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
      days_from_first_to_last_visit,
      days_from_first_visit,
      days_from_last_visit,

      # SESSION DATA
      session_id,
      session_number,
      session_duration_sec,

      # EVENT DATA
      event_timestamp,
      event_name,
      ecommerce
    from `tom-moretti.nameless_analytics.events`(start_date, end_date, 'user')
  ),

  user_logic as (
    select
      ## USER DATA
      user_date,
      client_id,
      user_channel_grouping,
      split(user_tld_source, '.')[safe_offset(0)] as user_source,
      user_tld_source,
      user_campaign,
      user_campaign_click_id,
      user_campaign_term,
      user_campaign_content,
      user_device_type,
      user_country,
      user_language,
      max(days_from_first_to_last_visit) as days_from_first_to_last_visit,
      max(days_from_first_visit) as days_from_first_visit,
      max(days_from_last_visit) as days_from_last_visit,
      
      ## SESSION DATA
      session_id,
      max(session_duration_sec) as session_duration_sec,
      max(session_number) as session_number,
      max(new_user) as new_user,
      max(returning_user) as returning_user,

      ## EVENT DATA
      countif(event_name = 'page_view') as page_view,
      countif(event_name = 'purchase') as purchase,
      countif(event_name = 'refund') as refund,

      ## ECOMMERCE DATA (Item level summed to session level)
      sum(case when event_name = 'purchase' then (safe_cast(json_value(items, '$.price') as float64) * ifnull(safe_cast(json_value(items, '$.quantity') as int64), 1)) else 0 end) as session_purchase_revenue,
      sum(case when event_name = 'refund' then -(safe_cast(json_value(items, '$.price') as float64) * ifnull(safe_cast(json_value(items, '$.quantity') as int64), 1)) else 0 end) as session_refund_revenue,
      sum(case when event_name = 'purchase' then ifnull(safe_cast(json_value(items, '$.quantity') as int64), 0) else 0 end) as session_purchase_qty,
      sum(case when event_name = 'refund' then ifnull(safe_cast(json_value(items, '$.quantity') as int64), 0) else 0 end) as session_refund_qty,

      ifnull(safe_divide(sum(case when event_name = 'purchase' then (safe_cast(json_value(items, '$.price') as float64) * ifnull(safe_cast(json_value(items, '$.quantity') as int64), 1)) else 0 end), countif(event_name = 'purchase')), 0) as session_avg_purchase_value,
      ifnull(safe_divide(sum(case when event_name = 'refund' then -(safe_cast(json_value(items, '$.price') as float64) * ifnull(safe_cast(json_value(items, '$.quantity') as int64), 1)) else 0 end), countif(event_name = 'refund')), 0) as session_avg_refund_value,

      min(if(event_name = 'purchase', timestamp_millis(event_timestamp), null)) as session_first_purchase_ts,
      max(if(event_name = 'purchase', timestamp_millis(event_timestamp), null)) as session_last_purchase_ts
    from base_events
    left join unnest(json_extract_array(ecommerce, '$.items')) as items
    group by all
  ),

  user_prep as (
    select
      # USER DATA
      user_date,
      client_id,
      user_channel_grouping,
      user_source,
      user_tld_source,
      user_campaign,
      user_campaign_click_id,
      user_campaign_term,
      user_campaign_content,
      user_device_type,
      user_country,
      user_language,
      days_from_first_to_last_visit,
      days_from_first_visit,
      days_from_last_visit,

      # SESSION DATA
      session_id,
      session_duration_sec,
      session_number,
      new_user,
      returning_user,

      # EVENT DATA
      page_view,
      purchase,
      refund,

      # ECOMMERCE DATA
      session_purchase_revenue,
      session_refund_revenue,
      session_purchase_qty,
      session_refund_qty,
      session_avg_purchase_value,
      session_avg_refund_value,
      session_first_purchase_ts,
      session_last_purchase_ts,

      # USER AGGREGATIONS
      max(session_number) over (partition by client_id) as total_sessions,
      max(new_user) over (partition by client_id) as new_user_client_id,
      max(returning_user) over (partition by client_id) as returning_user_client_id,
      
      case when sum(purchase) over (partition by client_id) >= 1 then 1 end as customers,
      case when sum(purchase) over (partition by client_id) = 1 then 1 end as new_customers,
      case when sum(purchase) over (partition by client_id) > 1 then 1 end as returning_customers,
      
      min(session_first_purchase_ts) over (partition by client_id) as user_first_purchase_ts,
      max(session_last_purchase_ts) over (partition by client_id) as user_last_purchase_ts
    from user_logic
  )

  select
    ## USER DATA
    user_date,
    client_id,
    user_channel_grouping,
    user_source,
    user_tld_source,
    user_campaign,
    user_campaign_click_id,
    user_campaign_term,
    user_campaign_content,
    user_device_type,
    user_country,
    user_language,
    case 
      when max(total_sessions) = 1 then 'new_user'
      when max(total_sessions) > 1 then 'returning_user'
    end as user_type,
    max(new_user_client_id) as new_user_client_id,
    max(returning_user_client_id) as returning_user_client_id,
    max(days_from_first_to_last_visit) as days_from_first_to_last_visit,
    max(days_from_first_visit) as days_from_first_visit,
    max(days_from_last_visit) as days_from_last_visit,

    case 
      when sum(purchase) = 0 then 'Not customer'
      when sum(purchase) > 0 then 'Customer'
    end as is_customer,
    case 
      when sum(purchase) = 1 then 'New customer'
      when sum(purchase) > 1 then 'Returning customer'
      else 'Not customer'
    end as customer_type,

    max(customers) as customers,
    max(new_customers) as new_customers,
    max(returning_customers) as returning_customers,

    count(distinct session_id) as sessions,
    avg(session_duration_sec) as session_duration_sec,
    sum(page_view) as page_view,
    date_diff(current_date(), date(max(user_first_purchase_ts)), day) as days_from_first_purchase,
    date_diff(current_date(), date(max(user_last_purchase_ts)), day) as days_from_last_purchase,
    sum(purchase) as purchase,
    sum(refund) as refund,
    sum(session_purchase_qty) as item_quantity_purchased,
    sum(session_refund_qty) as item_quantity_refunded,
    sum(session_purchase_revenue) as purchase_revenue,
    sum(session_refund_revenue) as refund_revenue,
    sum(session_purchase_revenue) + sum(session_refund_revenue) as revenue_net_refund,
    avg(session_avg_purchase_value) as avg_purchase_value,
    avg(session_avg_refund_value) as avg_refund_value
  from user_prep
  group by all
);