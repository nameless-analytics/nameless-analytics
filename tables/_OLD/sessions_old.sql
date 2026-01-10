CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.sessions`(start_date DATE, end_date DATE) AS (
with event_data as (
    select 
      ## USER DATA
      user_date,
      client_id,
      user_id,
      user_channel_grouping,
      user_source,
      user_tld_source,
      user_campaign,
      user_device_type,
      user_country,
      user_language,
      user_type,
      new_user,
      returning_user,


      ## SESSION DATA
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


      ## EVENT DATA
      event_date,
      event_name,
      event_timestamp,


      ## ECOMMERCE DATA
      case
        when event_name = 'purchase' then ifnull(cast(json_value(ecommerce.value) as float64), 0.0)
        else null
      end as transaction_value,
      case
        when event_name = 'purchase' then ifnull(cast(json_value(ecommerce.shipping) as float64), 0.0)
        else null
      end as transaction_shipping,
      case
        when event_name = 'purchase' then ifnull(cast(json_value(ecommerce.tax) as float64), 0.0)
        else null
      end as transaction_tax,
      case
        when event_name = 'refund' then - ifnull(cast(json_value(ecommerce.value) as float64), 0.0)
        else null
      end as refund_value,
      case
        when event_name = 'refund' then - ifnull(cast(json_value(ecommerce.shipping) as float64), 0.0)
        else null
      end as refund_shipping,
      case
        when event_name = 'refund' then - ifnull(cast(json_value(ecommerce.tax) as float64), 0.0)
        else null
      end as refund_tax,


      ## CONSENT DATA
      consent_type,
      ad_user_data,
      ad_personalization,
      ad_storage,
      analytics_storage,
      functionality_storage,
      personalization_storage,
      security_storage,

    from `tom-moretti.nameless_analytics.events` (start_date, end_date, 'session')
    group by all
  ),

  event_data_def as (
    select 
      ## USER DATA
      user_date,
      client_id,
      user_id,
      user_channel_grouping,
      split(user_tld_source, '.')[safe_offset(0)] as user_source,
      user_tld_source,
      user_campaign,
      user_device_type,
      user_country,
      user_language,
      user_type,
      new_user,
      returning_user,


      ## SESSION DATA
      session_date,
      session_number,
      session_id,
      session_start_timestamp,
      session_end_timestamp,
      session_duration_sec,
      session_channel_grouping,
      split(session_tld_source, '.')[safe_offset(0)] as session_source,
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


      ## EVENT DATA
      event_date,
      event_name,


      ## ECOMMERCE DATA
      transaction_value,
      transaction_shipping,
      transaction_tax,
      refund_value,
      refund_shipping,
      refund_tax,


      ## CONSENT DATA
      case 
        when countif(consent_type = 'Update') over (partition by session_id) > 0 then first_value(case when consent_type = 'Update' then event_timestamp end ignore nulls) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
        else first_value(event_timestamp) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
      end as consent_timestamp,
      case 
          when countif(consent_type = 'Update') over (partition by session_id) > 0 then 'Yes'
          when countif(consent_type = 'Default') over (partition by session_id) > 0 then 'No'
          else consent_type
      end as consent_expressed,
      case 
        when countif(consent_type = 'Update') over (partition by session_id) > 0 then first_value(case when consent_type = 'Update' then ad_user_data end ignore nulls) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
        else first_value(ad_user_data) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
      end as session_ad_user_data,
      case 
        when countif(consent_type = 'Update') over (partition by session_id) > 0 then first_value(case when consent_type = 'Update' then ad_personalization end ignore nulls) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
        else first_value(ad_personalization) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
      end as session_ad_personalization,
      case 
        when countif(consent_type = 'Update') over (partition by session_id) > 0 then first_value(case when consent_type = 'Update' then ad_storage end ignore nulls) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
        else first_value(ad_storage) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
      end as session_ad_storage,
      case 
        when countif(consent_type = 'Update') over (partition by session_id) > 0 then first_value(case when consent_type = 'Update' then analytics_storage end ignore nulls) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
        else first_value(analytics_storage) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
      end as session_analytics_storage,
      case 
        when countif(consent_type = 'Update') over (partition by session_id) > 0 then first_value(case when consent_type = 'Update' then functionality_storage end ignore nulls) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
        else first_value(functionality_storage) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
      end as session_functionality_storage,
      case 
        when countif(consent_type = 'Update') over (partition by session_id) > 0 then first_value(case when consent_type = 'Update' then personalization_storage end ignore nulls) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
        else first_value(personalization_storage) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
      end as session_personalization_storage,
      case 
        when countif(consent_type = 'Update') over (partition by session_id) > 0 then first_value(case when consent_type = 'Update' then security_storage end ignore nulls) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
        else first_value(security_storage) over (partition by session_id order by event_timestamp asc rows between unbounded preceding and unbounded following)
      end as session_security_storage,
    from event_data
  ),

  session_data as (
    select
      ## USER DATA
      user_date,
      client_id,
      user_id,
      user_channel_grouping,
      user_source,
      user_tld_source,
      user_campaign,
      user_device_type,
      user_country,
      user_language,
      user_type,
      new_user,
      returning_user,


      ## SESSION DATA
      session_date,
      session_number,
      session_id,
      session_start_timestamp,
      session_duration_sec,
      session_channel_grouping,
      session_source,
      session_tld_source,
      session_campaign,
      session_device_type,
      session_country,
      session_browser_name,
      session_language,
      cross_domain_session,
      session_landing_page_category,
      session_landing_page_location,
      session_landing_page_title,
      session_exit_page_category,
      session_exit_page_location,
      session_exit_page_title,
      session_hostname,


      ## EVENTS / CONVERSIONS
      countif(event_name = 'page_view') as page_view,

      -- Add other events / conversions here


      ## ECOMMERCE DATA
      countif(event_name = 'view_item_list') as view_item_list,
      countif(event_name = 'select_item') as select_item,
      countif(event_name = 'view_item') as view_item,
      countif(event_name = 'add_to_wishlist') as add_to_wishlist,
      countif(event_name = 'add_to_cart') as add_to_cart,
      countif(event_name = 'remove_from_cart') as remove_from_cart,
      countif(event_name = 'view_cart') as view_cart,
      countif(event_name = 'begin_checkout') as begin_checkout,
      countif(event_name = 'add_shipping_info') as add_shipping_info,
      countif(event_name = 'add_payment_info') as add_payment_info,
      countif(event_name = 'purchase') as purchase,
      countif(event_name = 'refund') as refund,
      ifnull(sum(transaction_value), 0) as purchase_revenue,
      ifnull(sum(transaction_shipping), 0) as purchase_shipping,
      ifnull(sum(transaction_tax), 0) as purchase_tax,
      ifnull(sum(refund_value), 0) as refund_revenue,
      ifnull(sum(refund_shipping), 0) as refund_shipping,
      ifnull(sum(refund_tax), 0) as refund_tax,


      ## CONSENT DATA
      consent_timestamp,
      consent_expressed,
      case when session_ad_user_data = 'Granted' then 1 else 0 end as session_ad_user_data,
      case when session_ad_personalization = 'Granted' then 1 else 0 end as session_ad_personalization,
      case when session_ad_storage = 'Granted' then 1 else 0 end as session_ad_storage,
      case when session_analytics_storage = 'Granted' then 1 else 0 end as session_analytics_storage,
      case when session_functionality_storage = 'Granted' then 1 else 0 end as session_functionality_storage,
      case when session_personalization_storage = 'Granted' then 1 else 0 end as session_personalization_storage,
      case when session_security_storage = 'Granted' then 1 else 0 end as session_security_storage,
    from event_data_def
    group by all
  )

  select 
    ## USER DATA
    user_date,
    client_id,
    user_id,
    user_channel_grouping,
    user_source,
    user_tld_source,
    user_campaign,
    user_device_type,
    user_country,
    user_language,
    user_type,
    new_user,
    returning_user,


    ## SESSION DATA
    session_date,
    session_number,
    session_id,
    session_start_timestamp,
    session_duration_sec,
    case 
      when session_number = 1 then 1
      else 0
    end as first_session,
    case 
      when sum(page_view) >= 2 and (avg(session_duration_sec) >= 10 or sum(purchase) >= 1) then 1
      else 0
    end as engaged_session,
    session_channel_grouping,
    session_source, 
    session_tld_source,
    session_campaign,
    session_device_type,
    session_country,
    session_browser_name,
    session_language,
    cross_domain_session,
    session_landing_page_category,
    session_landing_page_location,
    session_landing_page_title,
    session_exit_page_category,
    session_exit_page_location,
    session_exit_page_title,
    session_hostname,
    

    ## EVENTS
    sum(page_view) as page_view,


    ## ECOMMERCE DATA
    sum(view_item_list) as view_item_list,
    sum(select_item) as select_item,
    sum(view_item) as view_item,
    sum(add_to_wishlist) as add_to_wishlist,
    sum(add_to_cart) as add_to_cart,
    sum(remove_from_cart) as remove_from_cart,
    sum(view_cart) as view_cart,
    sum(begin_checkout) as begin_checkout,
    sum(add_shipping_info) as add_shipping_info,
    sum(add_payment_info) as add_payment_info,
    sum(purchase) as purchase,
    sum(refund) as refund,
    sum(purchase_revenue) as purchase_revenue,
    sum(purchase_shipping) as purchase_shipping,
    sum(purchase_tax) as purchase_tax,
    sum(refund_revenue) as refund_revenue,
    sum(refund_shipping) as refund_shipping,
    sum(refund_tax) as refund_tax,
    sum(purchase) - sum(refund) as purchase_net_refund,
    ifnull(sum(purchase_revenue), 0) - ifnull(sum(refund_revenue), 0) as revenue_net_refund,
    ifnull(sum(purchase_shipping), 0) + ifnull(sum(refund_shipping), 0) as shipping_net_refund,
    ifnull(sum(purchase_tax), 0) + ifnull(sum(refund_tax), 0) as tax_net_refund,


    ## CONSENT DATA
    consent_timestamp,
    consent_expressed,
    session_ad_user_data,
    session_ad_personalization,
    session_ad_storage,
    session_analytics_storage,
    session_functionality_storage,
    session_personalization_storage,
    session_security_storage
  from session_data
  group by all
);