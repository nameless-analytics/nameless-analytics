CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.users`(start_date DATE, end_date DATE) AS (
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
      user_id,
      client_id,
      user_type,
      max(new_user) as new_user,
      max(returning_user) as returning_user,
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
      
      ## SESSION DATA
      session_id,
      max(session_duration_sec) as session_duration_sec,
      max(session_number) as session_number,

      ## EVENT DATA
      countif(event_name = 'page_view') as page_view,
      countif(event_name = 'purchase') as purchase,
      countif(event_name = 'refund') as refund,

      ## ECOMMERCE DATA
      sum(case when event_name = 'purchase' then (safe_cast(json_value(items, '$.price') as float64) * ifnull(safe_cast(json_value(items, '$.quantity') as int64), 1)) else 0 end) as purchase_revenue,
      sum(case when event_name = 'refund' then -(safe_cast(json_value(items, '$.price') as float64) * ifnull(safe_cast(json_value(items, '$.quantity') as int64), 1)) else 0 end) as refund_revenue,
      sum(case when event_name = 'purchase' then ifnull(safe_cast(json_value(items, '$.quantity') as int64), 0) else 0 end) as purchase_qty,
      sum(case when event_name = 'refund' then ifnull(safe_cast(json_value(items, '$.quantity') as int64), 0) else 0 end) as refund_qty,

      ifnull(safe_divide(sum(case when event_name = 'purchase' then (safe_cast(json_value(items, '$.price') as float64) * ifnull(safe_cast(json_value(items, '$.quantity') as int64), 1)) else 0 end), countif(event_name = 'purchase')), 0) as avg_purchase_value,
      ifnull(safe_divide(sum(case when event_name = 'refund' then -(safe_cast(json_value(items, '$.price') as float64) * ifnull(safe_cast(json_value(items, '$.quantity') as int64), 1)) else 0 end), countif(event_name = 'refund')), 0) as avg_refund_value,

      min(if(event_name = 'purchase', timestamp_millis(event_timestamp), null)) as first_purchase_timestamp,
      max(if(event_name = 'purchase', timestamp_millis(event_timestamp), null)) as last_purchase_timestamp
    from base_events
    left join unnest(json_extract_array(ecommerce, '$.items')) as items
    group by all
  ),

  user_prep as (
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
      days_from_first_to_last_visit,
      days_from_first_visit,
      days_from_last_visit,

      # SESSION DATA
      session_id,
      session_duration_sec,
      session_number,
      returning_user,
      max(session_number) over (partition by client_id) as total_sessions,

      # EVENT DATA
      page_view,

      # ECOMMERCE DATA
      case when sum(purchase) over (partition by client_id) >= 1 then 1 end as customers,
      case when sum(purchase) over (partition by client_id) = 1 then 1 end as new_customers,
      case when sum(purchase) over (partition by client_id) > 1 then 1 end as returning_customers,
      min(first_purchase_timestamp) over (partition by client_id) as first_purchase_timestamp,
      max(last_purchase_timestamp) over (partition by client_id) as last_purchase_timestamp,
      purchase,
      refund,
      purchase_revenue,
      refund_revenue,
      purchase_qty,
      refund_qty,
      avg_purchase_value,
      avg_refund_value,
      
      
    from user_logic
)

  select
    ## USER DATA
    user_date,
    client_id,
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
    case 
      when max(total_sessions) = 1 then 'New user'
      when max(total_sessions) > 1 then 'Returning user'
    end as user_type,

    case 
      when max(total_sessions) = 1 then client_id
      else null
    end as new_user_client_id,
    case 
      when max(total_sessions) > 1 then client_id
      else null
    end as returning_user_client_id,
 
    max(days_from_first_to_last_visit) as days_from_first_to_last_visit,
    max(days_from_first_visit) as days_from_first_visit,
    max(days_from_last_visit) as days_from_last_visit,

    safe_divide(sum(purchase), count(distinct client_id)) as user_conversion_rate,
    safe_divide(sum(purchase_revenue), count(distinct client_id)) as user_value,

    case 
      when sum(purchase) = 0 then 'Not customer'
      when sum(purchase) > 0 then 'Customer'
    end as is_customer,
    case 
      when sum(purchase) = 1 then 'New customer'
      when sum(purchase) > 1 then 'Returning customer'
      else null
    end as customer_type,

    max(customers) as customers,
    max(new_customers) as new_customers,
    max(returning_customers) as returning_customers,

    count(distinct session_id) as sessions,
    avg(session_duration_sec) as session_duration_sec,
    count(distinct session_id) / count(distinct client_id) as sessions_per_user,
    sum(page_view) as page_view,
    date_diff(current_date(), date(max(first_purchase_timestamp)), day) as days_from_first_purchase,
    date_diff(current_date(), date(max(last_purchase_timestamp)), day) as days_from_last_purchase,
    sum(purchase) as purchase,
    sum(refund) as refund,
    sum(purchase_qty) as item_quantity_purchased,
    sum(refund_qty) as item_quantity_refunded,
    sum(purchase_revenue) as purchase_revenue,
    sum(refund_revenue) as refund_revenue,
    sum(purchase_revenue) + sum(refund_revenue) as revenue_net_refund,
    safe_divide(sum(purchase_revenue), sum(purchase)) as avg_purchase_value,
    safe_divide(sum(refund_revenue), sum(refund)) as avg_refund_value,
  from user_prep
  group by all
);