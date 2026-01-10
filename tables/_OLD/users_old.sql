CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.users_old`(start_date DATE, end_date DATE) AS (
with event_data as (
    select
      -- USER DATA
      user_date,
      client_id,
      user_channel_grouping,
      user_source,
      user_tld_source,
      user_campaign,
      user_device_type,
      user_country,
      user_language,
      case 
        when session_number = 1 then client_id
        else null
      end as new_user,
      case 
        when session_number > 1 then client_id
        else null
      end as returning_user,
      days_from_first_to_last_visit,
      days_from_first_visit,
      days_from_last_visit,

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
      
      # EVENT DATA
      event_date,
      event_name,
      event_timestamp,

      if(event_name = 'purchase', timestamp_millis(event_timestamp), null) as purchase_timestamp,
      min(if(event_name = 'purchase', timestamp_millis(event_timestamp), null)) over (partition by client_id) as first_purchase_timestamp,
      max(if(event_name = 'purchase', timestamp_millis(event_timestamp), null)) over (partition by client_id) as last_purchase_timestamp,

      case 
        when event_name = 'purchase' then json_value(ecommerce, '$.transaction_id')
        else null
      end as purchase_id,
      case 
        when event_name = 'refund' then json_value(ecommerce, '$.transaction_id')
        else null
      end as refund_id,
      sum(case 
        when event_name = 'purchase' then cast(json_value(items, '$.quantity') as int64)
        else 0
      end) as item_quantity_purchased,
      sum(case 
        when event_name ='refund' then cast(json_value(items, '$.quantity') as int64)
        else 0
      end) as item_quantity_refunded,
      sum(case 
        when event_name = 'purchase' then cast(json_value(items, '$.price') as float64) * cast(json_value(items, '$.quantity') as int64)
        else 0
      end) as item_revenue_purchased,
      sum(case 
        when event_name = 'refund' then -cast(json_value(items, '$.price') as float64) * cast(json_value(items, '$.quantity') as int64)
        else 0
      end) as item_revenue_refunded
    from `tom-moretti.nameless_analytics.events`(start_date, end_date, 'user')
      left join unnest(json_extract_array(ecommerce, '$.items')) as items
    group by all
  ),
    
  session_data as (
    select  
      -- USER DATA
      user_date,
      client_id,
      user_channel_grouping,
      split(user_source, '.')[safe_offset(0)] as user_source,
      user_tld_source,
      user_campaign,
      user_device_type,
      user_country,
      user_language,
      new_user,
      returning_user,
      days_from_first_to_last_visit,
      days_from_first_visit,
      days_from_last_visit,

      -- SESSION DATA
      session_date,
      session_number,
      max(session_number) over (partition by client_id) as max_session_number,
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

      # EVENT DATA
      event_date,
      event_name,
      countif(event_name = 'page_view') as page_view,
      countif(event_name = 'purchase') as purchase,
      countif(event_name = 'refund') as refund,
      first_purchase_timestamp,
      last_purchase_timestamp,
      sum(item_revenue_purchased) as item_revenue_purchased,
      sum(item_revenue_refunded) as item_revenue_refunded,
      sum(item_quantity_purchased) as item_quantity_purchased,
      sum(item_quantity_refunded) as item_quantity_refunded,
    from event_data
    group by all
  ),

  user_data_def as(
    select
      -- USER DATA
      user_date,
      client_id,
      user_channel_grouping,
      user_source,
      user_tld_source,
      user_campaign,
      user_device_type,
      user_country,
      user_language,
      case 
        when max_session_number = 1 then 'new_user'
        when max_session_number > 1 then 'returning_user'
      end as user_type,
      new_user,
      max(new_user) over (partition by client_id) as new_user_client_id,
      returning_user,
      max(returning_user) over (partition by client_id) as returning_user_client_id,
      days_from_first_to_last_visit,
      days_from_first_visit,
      days_from_last_visit,
      case 
        when sum(purchase) = 0 then 1
        else null
      end as not_customers,
      case 
        when sum(purchase) >= 1 then 1
        else null
      end as customers,
      case 
        when sum(purchase) = 1 then 1
        else null
      end as new_customers,
      case 
        when sum(purchase) > 1 then 1
        else null
      end as returning_customers,

      # SESSION DATA
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
      count(distinct session_id) as sessions,

      case 
        when sum(page_view) >= 2 and (avg(session_duration_sec) >= 10 or countif(event_name = 'purchase') >= 1) then 1
        else 0
      end as engaged_session,
      sum(page_view) as page_view,
      date_diff(CURRENT_DATE(), DATE(first_purchase_timestamp), day) as days_from_first_purchase,
      date_diff(CURRENT_DATE(), date(last_purchase_timestamp), day) as days_from_last_purchase,
      sum(purchase) as purchase,
      sum(refund) as refund,
      sum(item_quantity_purchased) as item_quantity_purchased,
      sum(item_quantity_refunded) as item_quantity_refunded,
      sum(item_revenue_purchased) as purchase_revenue,
      sum(item_revenue_refunded) as refund_revenue,
      sum(item_revenue_purchased) + sum(item_revenue_refunded) as revenue_net_refund,
      ifnull(safe_divide(sum(item_revenue_purchased), countif(event_name = 'purchase')), 0) as avg_purchase_value,
      ifnull(safe_divide(sum(item_revenue_refunded), countif(event_name = 'refund')), 0) as avg_refund_value
    from session_data
    group by all
  )

  select 
    # USER DATA 
    user_date,
    client_id,
    user_channel_grouping,
    user_source,
    user_tld_source,
    user_campaign,
    user_device_type,
    user_country,
    user_language,
    user_type,
    new_user_client_id,
    returning_user_client_id,
    days_from_first_to_last_visit,
    days_from_first_visit,
    days_from_last_visit,
    case 
      when sum(purchase) = 0 then 'Not customer'
      when sum(purchase) > 0 then 'Customer'
    end as is_customer,
    case 
      when sum(purchase) = 1 then 'New customer'
      when sum(purchase) > 1 then 'Returning customer'
      else 'Not customer'
    end as customer_type,

    -- max(not_customers) as not_customers,
    max(customers) as customers,
    max(new_customers) as new_customers,
    max(returning_customers) as returning_customers,

    sum(sessions) as sessions,
    avg(session_duration_sec) as session_duration_sec, 
    sum(page_view) as page_view,
    days_from_first_purchase,
    days_from_last_purchase,
    sum(purchase) as purchase,
    sum(refund) as refund,
    sum(item_quantity_purchased) as item_quantity_purchased,
    sum(item_quantity_refunded) as item_quantity_refunded,
    sum(purchase_revenue) as purchase_revenue,
    sum(refund_revenue) as refund_revenue,
    sum(revenue_net_refund) as revenue_net_refund,
    avg(avg_purchase_value) as avg_purchase_value,
    avg(avg_refund_value) as avg_refund_value
  from user_data_def
  group by all
);