CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.ec_products`(start_date DATE, end_date DATE) AS (
with product_data_raw as (
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
      event_timestamp,
      event_name,

      # ECOMMERCE & ITEMS DATA
      json_value(ecommerce, '$.transaction_id') as transaction_id,
      json_value(ecommerce, '$.item_list_id') as list_id,
      json_value(ecommerce, '$.item_list_name') as list_name,
      json_value(ecommerce, '$.creative_name') as creative_name,
      json_value(ecommerce, '$.creative_slot') as creative_slot,
      json_value(ecommerce, '$.promotion_id') as promotion_id,
      json_value(ecommerce, '$.promotion_name') as promotion_name,

      json_value(items, '$.item_list_id') as item_list_id,
      json_value(items, '$.item_list_name') as item_list_name,
      json_value(items, '$.affiliation') as item_affiliation,
      json_value(items, '$.coupon') as item_coupon,
      safe_cast(json_value(items, '$.discount') as float64) as item_discount,
      json_value(items, '$.item_brand') as item_brand,
      json_value(items, '$.item_id') as item_id,
      json_value(items, '$.item_name') as item_name,
      json_value(items, '$.item_variant') as item_variant,
      json_value(items, '$.item_category') as item_category,
      json_value(items, '$.item_category2') as item_category_2,
      json_value(items, '$.item_category3') as item_category_3,
      json_value(items, '$.item_category4') as item_category_4,
      json_value(items, '$.item_category5') as item_category_5,
      safe_cast(json_value(items, '$.price') as float64) as item_price,
      
      case when event_name = 'purchase' then safe_cast(json_value(items, '$.quantity') as int64) end as item_quantity_purchased,
      case when event_name = 'refund' then safe_cast(json_value(items, '$.quantity') as int64) end as item_quantity_refunded,
      case when event_name = 'add_to_cart' then safe_cast(json_value(items, '$.quantity') as int64) end as item_quantity_added_to_cart,
      case when event_name = 'remove_from_cart' then safe_cast(json_value(items, '$.quantity') as int64) end as item_quantity_removed_from_cart,
      
      case when event_name = 'purchase' then safe_cast(json_value(items, '$.price') as float64) * safe_cast(json_value(items, '$.quantity') as int64) end as item_purchase_revenue,
      case when event_name = 'refund' then safe_cast(json_value(items, '$.price') as float64) * safe_cast(json_value(items, '$.quantity') as int64) end as item_refund_revenue,
      case when event_name = 'purchase' then 1 end as item_unique_purchases
    from `tom-moretti.nameless_analytics.events`(start_date, end_date, 'session')
      left join unnest(json_extract_array(ecommerce, '$.items')) as items
    where regexp_contains(event_name, 'view_promotion|select_promotion|view_item_list|select_item|view_item|add_to_wishlist|add_to_cart|remove_from_cart|view_cart|begin_checkout|add_shipping_info|add_payment_info|purchase|refund')
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
    FORMAT_TIMESTAMP('%H:%M:%S', TIMESTAMP_MILLIS(event_timestamp)) AS hour_and_minute,
    event_name, 
    event_timestamp,
    
    # ECOMMERCE DATA
    transaction_id,
    case 
      when event_name = 'purchase' then transaction_id 
      else null 
    end as purchase_id,

    case 
      when event_name = 'refund' then transaction_id 
      else null 
    end as refund_id,
    
    list_id, 
    list_name, 
    item_list_id, 
    item_list_name, 
    item_affiliation, 
    item_coupon, 
    item_discount, 
    creative_name, 
    creative_slot, 
    promotion_id, 
    promotion_name, 
    item_brand, 
    item_id, 
    item_name, 
    item_variant, 
    item_category, 
    item_category_2, 
    item_category_3, 
    item_category_4, 
    item_category_5,
    
    countif(event_name = "view_promotion") as view_promotion,
    countif(event_name = "select_promotion") as select_promotion,
    countif(event_name = "view_item_list") as view_item_list,
    countif(event_name = "select_item") as select_item,
    countif(event_name = "view_item") as view_item,
    countif(event_name = "add_to_wishlist") as add_to_wishlist,
    countif(event_name = "add_to_cart") as add_to_cart,
    countif(event_name = "remove_from_cart") as remove_from_cart,
    countif(event_name = "view_cart") as view_cart,
    countif(event_name = "begin_checkout") as begin_checkout,
    countif(event_name = "add_shipping_info") as add_shipping_info,
    countif(event_name = "add_payment_info") as add_payment_info,
    countif(event_name = 'purchase') as purchase,
    countif(event_name = 'refund') as refund,

    sum(item_quantity_purchased) as item_quantity_purchased,
    count(distinct case when item_unique_purchases = 1 then item_name end) as item_unique_purchases,
    sum(item_quantity_added_to_cart) as item_quantity_added_to_cart,
    sum(item_quantity_removed_from_cart) as item_quantity_removed_from_cart,
    sum(item_purchase_revenue) as item_purchase_revenue,

    sum(item_quantity_refunded) as item_quantity_refunded,
    count(distinct case when item_unique_purchases = 1 then item_name end) as item_unique_refunds,
    sum(item_refund_revenue) as item_refund_revenue
  from product_data_raw
  group by all
); 