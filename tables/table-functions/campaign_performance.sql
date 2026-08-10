CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.campaign_performance`(start_date DATE, end_date DATE) AS (
with session_data as (
    SELECT
      session_date,
      session_channel_grouping,
      session_source,
      session_campaign,
      session_campaign_id,
      session_campaign_term,
      session_campaign_content,
      
      # POST CLICK
      count(distinct client_id) as users,
      count(distinct new_user_client_id) as new_users,
      count(distinct returning_user_client_id) as returning_users,
      count(distinct session_id) as sessions,
      session_duration_sec,
      new_session,
      new_sessions_percentage,
      returning_session,
      returning_sessions_percentage,
      engaged_session,
      engaged_sessions_percentage,
      session_with_sign_up,
      session_with_newsletter_subscription,
      session_with_form_submit,
      session_with_purchase,
      session_with_refund,
      page_view_per_session,
      total_events,
      total_page_views,
      sign_up,
      newsletter_subscription,
      form_submit,
      purchase,
      refund,
      purchase_revenue,
      purchase_shipping,
      purchase_tax,
      avg_order_value,
      refund_revenue,
      refund_shipping,
      refund_tax,
      avg_refund_value,
      purchase_net_refund,
      revenue_net_refund,
      shipping_net_refund,
      tax_net_refund,
    FROM `tom-moretti.nameless_analytics.sessions`(start_date, end_date)
    GROUP BY ALL
  ),

  online_campaigns_performances as (
    select
      date,
      campaign_name,
      campaign_id,
      cost as cost,
      sum(impression) as impression,
      sum(click) as click,
      safe_divide(cost, sum(click)) as avg_cost_per_click,
      safe_divide(sum(click), sum(impression)) as avg_click_through_rate,
    from `tom-moretti.nameless_analytics.online_campaign_performance_sheets`
    where date between start_date and end_date
    and campaign_name is not null
    group by all
  )

  select 
    session_date,
    session_channel_grouping,
    session_source,
    split(session_data.session_campaign, '|')[safe_offset(0)] as session_campaign_year,
    split(session_data.session_campaign, '|')[safe_offset(1)] as session_campaign_country,
    split(session_data.session_campaign, '|')[safe_offset(2)] as session_campaign_funnel_stage,
    split(session_data.session_campaign, '|')[safe_offset(3)] as session_campaign_platform,
    split(session_data.session_campaign, '|')[safe_offset(4)] as session_campaign_campaign_type,
    split(session_data.session_campaign, '|')[safe_offset(5)] as session_campaign_marketing_objective,
    session_campaign,
    session_campaign_id,
    session_campaign_term,
    session_campaign_content,

    # PRE CLICK
    ifnull(cost, 0.00) as cost,
    ifnull(safe_divide(cost, sign_up), 0.00) as cost_per_sign_up,
    ifnull(safe_divide(cost, newsletter_subscription), 0.00) as cost_per_newsletter_subscription,
    ifnull(safe_divide(cost, form_submit), 0.00) as cost_per_form_submit,
    ifnull(safe_divide(cost, purchase), 0.00) as cost_per_purchase,
    ifnull(impression, 0.00) as impression,
    ifnull(click, 0.00) as click,
    ifnull(avg_cost_per_click, 0.00) as avg_cost_per_click,
    ifnull(avg_click_through_rate, 0.00) as avg_click_through_rate,
    
    # POST CLICK
    new_users,
    sessions,
    session_duration_sec,
    new_session,
    new_sessions_percentage,
    returning_session,
    returning_sessions_percentage,
    engaged_session,
    engaged_sessions_percentage,
    session_with_sign_up,
    session_with_newsletter_subscription,
    session_with_form_submit,
    session_with_purchase,
    session_with_refund,
    page_view_per_session,
    total_events,
    total_page_views,
    sign_up,
    newsletter_subscription,
    form_submit,
    purchase,
    refund,
    purchase_revenue,
    purchase_shipping,
    purchase_tax,
    avg_order_value,
    refund_revenue,
    refund_shipping,
    refund_tax,
    avg_refund_value,
    purchase_net_refund,
    revenue_net_refund,
    shipping_net_refund,
    tax_net_refund,
    ifnull(safe_divide(purchase_revenue, cost), 0.00) as roas,
    ifnull(safe_divide(revenue_net_refund, cost), 0.00) as roas_net_refund

  FROM session_data
  LEFT JOIN online_campaigns_performances
    ON session_data.session_date = online_campaigns_performances.date
    AND session_data.session_campaign = online_campaigns_performances.campaign_name
    AND ifnull(session_data.session_campaign_id, "") = ifnull(online_campaigns_performances.campaign_id, "")
  group by all
);