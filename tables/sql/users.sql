CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.users`(start_date DATE, end_date DATE) AS (
with raw_user_data as (
    select
      # USER DATA
      user_date,
      user_id,
      client_id,
      new_user_client_id,
      returning_user_client_id,
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
      days_from_first_to_last_visit,
      days_from_first_visit,
      days_from_last_visit,
      
      # SESSION DATA
      session_id,
      session_duration_sec,
      session_number,

      # EVENT DATA
      event_name,
      event_timestamp,

      # ECOMMERCE DATA
      json_value(ecommerce, '$.transaction_id') as transaction_id,
      if(event_name = 'purchase', timestamp_millis(event_timestamp), null) as first_purchase_timestamp,
      if(event_name = 'purchase', timestamp_millis(event_timestamp), null) as last_purchase_timestamp,
      sum(case when event_name = 'purchase' then (ifnull(safe_cast(json_value(items, '$.price') as float64), 0.0) * ifnull(safe_cast(json_value(items, '$.quantity') as int64), 1)) else 0 end) as purchase_revenue,
      sum(case when event_name = 'refund' then -(ifnull(safe_cast(json_value(items, '$.price') as float64), 0.0) * ifnull(safe_cast(json_value(items, '$.quantity') as int64), 1)) else 0 end) as refund_revenue,
      sum(case when event_name = 'purchase' then ifnull(safe_cast(json_value(items, '$.quantity') as int64), 0) else 0 end) as purchase_qty,
      sum(case when event_name = 'refund' then ifnull(safe_cast(json_value(items, '$.quantity') as int64), 0) else 0 end) as refund_qty,

    from `tom-moretti.nameless_analytics.events`(start_date, end_date, 'user')
      left join unnest(json_extract_array(ecommerce, '$.items')) as items
    group by all
  ),
 
  user_data as (
    select
      # USER DATA
      user_date,
      user_id,
      client_id,
      new_user_client_id,
      returning_user_client_id,
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
      days_from_first_to_last_visit,
      days_from_first_visit,
      days_from_last_visit,
 
      # SESSION DATA
      session_id,
      session_duration_sec,
      session_number,
      max(session_number) over (partition by client_id) as total_sessions,
 
      # EVENT DATA
      countif(event_name = 'page_view') as page_view,
      countif(event_name = 'purchase') as purchase,
      countif(event_name = 'refund') as refund,
      count(*) as total_events,

      # ECOMMERCE DATA
      min(first_purchase_timestamp) as first_purchase_timestamp,
      max(last_purchase_timestamp) as last_purchase_timestamp,
      sum(purchase_revenue) as purchase_revenue,
      sum(refund_revenue) as refund_revenue,
      sum(purchase_qty) as purchase_qty,
      sum(refund_qty) as refund_qty,
      safe_divide(sum(purchase_revenue), countif(event_name = 'purchase')) as avg_purchase_value,
      safe_divide(sum(refund_revenue), countif(event_name = 'refund')) as avg_refund_value,      
    from raw_user_data
    group by all
  )
    
  select
    # USER DATA
    user_date,
    user_id,
    client_id,
    case 
      when total_sessions = 1 then 'new_user'
      when total_sessions > 1 then 'returning_user'
    end as user_type,
    max(new_user_client_id) as new_user_client_id,
    max(returning_user_client_id) as returning_user_client_id,
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
    max(days_from_first_to_last_visit) as days_from_first_to_last_visit,
    max(days_from_first_visit) as days_from_first_visit,
    max(days_from_last_visit) as days_from_last_visit,
  
    case when sum(purchase) >= 1 then 1 else 0 end as user_with_purchase,
    case when sum(refund) >= 1 then 1 else 0 end as user_with_refund,
  
    case 
      when sum(purchase) = 0 then 'Not customer'
      when sum(purchase) > 0 then 'Customer'
    end as customer_status,
  
    case 
      when sum(purchase) = 1 then 'New customer'
      when sum(purchase) > 1 then 'Returning customer'
      else 'Not customer'
    end as customer_type,
  
    case 
      when sum(purchase) >= 1 then client_id
      else null
    end as customer_client_id,

    case 
      when sum(purchase) = 1 then client_id
      else null
    end as new_customer_client_id,

    case 
      when sum(purchase) > 1 then client_id
      else null
    end as returning_customer_client_id,
  
    max(first_purchase_timestamp) as first_purchase_timestamp,
    max(last_purchase_timestamp) as last_purchase_timestamp,
  
    count(distinct session_id) as sessions,
    avg(session_duration_sec) as session_duration_sec,
    count(distinct session_id) / count(distinct client_id) as sessions_per_user,
    sum(page_view) as page_view,
    sum(total_events) as total_events,
    date_diff(current_date(), date(max(first_purchase_timestamp)), day) as days_from_first_purchase,
    date_diff(current_date(), date(max(last_purchase_timestamp)), day) as days_from_last_purchase,
    sum(purchase) as purchase,
    sum(refund) as refund,
    sum(purchase_qty) as item_quantity_purchased,
    sum(refund_qty) as item_quantity_refunded,
    sum(purchase_revenue) as purchase_revenue,
    sum(refund_revenue) as refund_revenue,
    sum(purchase_revenue) + sum(refund_revenue) as revenue_net_refund,
    avg(avg_purchase_value) as avg_purchase_value,
    avg(avg_refund_value) as avg_refund_value,
  from user_data
  group by all
);