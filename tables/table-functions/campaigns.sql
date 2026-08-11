CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.campaigns`(start_date DATE, end_date DATE) AS (
with session_data as (
    SELECT
      session_date,
      session_campaign_year as campaign_year,
      session_campaign_country as campaign_country,
      session_campaign_funnel_stage as campaign_funnel_stage,
      session_campaign_platform as campaign_platform,
      session_campaign_type as campaign_type,
      session_campaign_marketing_objective as campaign_marketing_objective,
      session_campaign_name as campaign_name,
      session_campaign as campaign,
      session_campaign_id as campaign_id,
      
      # POST CLICK
      count(distinct new_user_client_id) as new_users,
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
    where true 
      and session_campaign is not null
    GROUP BY ALL
  ),

  online_campaigns_performances as (
    select
      date,
    `tom-moretti.nameless_analytics.get_campaign_part`(campaign, 'campaign_year') as campaign_year,
    `tom-moretti.nameless_analytics.get_campaign_part`(campaign, 'campaign_country') as campaign_country,
    `tom-moretti.nameless_analytics.get_campaign_part`(campaign, 'campaign_funnel_stage') as campaign_funnel_stage,
    `tom-moretti.nameless_analytics.get_campaign_part`(campaign, 'campaign_platform') as campaign_platform,
    `tom-moretti.nameless_analytics.get_campaign_part`(campaign, 'campaign_type') as campaign_type,
    `tom-moretti.nameless_analytics.get_campaign_part`(campaign, 'campaign_marketing_objective') as campaign_marketing_objective,
    `tom-moretti.nameless_analytics.get_campaign_part`(campaign, 'campaign_name') as campaign_name,
      campaign,
      campaign_id, 
      cost as spend,
      sum(impression) as impression,
      sum(click) as click,
      safe_divide(cost, sum(click)) as avg_cost_per_click,
      safe_divide(sum(click), sum(impression)) as avg_click_through_rate,
    from `tom-moretti.nameless_analytics.online_campaign_performance_sheets`
    where true 
      and date between start_date and end_date
      and campaign is not null
      and date is not null
    group by all
  )

  select 
    coalesce(session_data.session_date, online_campaigns_performances.date) as session_date,
    coalesce(session_data.campaign_year, online_campaigns_performances.campaign_year) as campaign_year,
    coalesce(session_data.campaign_country, online_campaigns_performances.campaign_country) as campaign_country,
    coalesce(session_data.campaign_funnel_stage, online_campaigns_performances.campaign_funnel_stage) as campaign_funnel_stage,
    coalesce(session_data.campaign_platform, online_campaigns_performances.campaign_platform) as campaign_platform,
    coalesce(session_data.campaign_type, online_campaigns_performances.campaign_type) as campaign_type,
    coalesce(session_data.campaign_marketing_objective, online_campaigns_performances.campaign_marketing_objective) as campaign_marketing_objective,
    coalesce(session_data.campaign_name, online_campaigns_performances.campaign_name) as campaign_name,
    coalesce(session_data.campaign, online_campaigns_performances.campaign_name) as campaign,
    coalesce(session_data.campaign_id, online_campaigns_performances.campaign_id) as campaign_id,
 
    # PRE CLICK
    ifnull(spend, 0.00) as spend,
    ifnull(safe_divide(spend, sign_up), 0.00) as cost_per_sign_up,
    ifnull(safe_divide(spend, newsletter_subscription), 0.00) as cost_per_newsletter_subscription,
    ifnull(safe_divide(spend, form_submit), 0.00) as cost_per_form_submit,
    ifnull(safe_divide(spend, purchase), 0.00) as cost_per_purchase,
    ifnull(impression, 0.00) as impression,
    ifnull(click, 0.00) as click,
    ifnull(avg_cost_per_click, 0.00) as avg_cost_per_click,
    ifnull(avg_click_through_rate, 0.00) as avg_click_through_rate,
    
    # POST CLICK
    session_data.new_users,
    session_data.sessions,
    session_data.session_duration_sec,
    session_data.new_session,
    session_data.new_sessions_percentage,
    session_data.returning_session,
    session_data.returning_sessions_percentage,
    session_data.engaged_session,
    session_data.engaged_sessions_percentage,
    session_data.session_with_sign_up,
    session_data.session_with_newsletter_subscription,
    session_data.session_with_form_submit,
    session_data.session_with_purchase,
    session_data.session_with_refund,
    session_data.page_view_per_session,
    session_data.total_events,
    session_data.total_page_views,
    session_data.sign_up,
    session_data.newsletter_subscription,
    session_data.form_submit,
    session_data.purchase,
    session_data.refund,
    session_data.purchase_revenue,
    session_data.purchase_shipping,
    session_data.purchase_tax,
    session_data.avg_order_value,
    session_data.refund_revenue,
    session_data.refund_shipping,
    session_data.refund_tax,
    session_data.avg_refund_value,
    session_data.purchase_net_refund,
    session_data.revenue_net_refund,
    session_data.shipping_net_refund,
    session_data.tax_net_refund,
    ifnull(safe_divide(session_data.purchase_revenue, spend), 0.00) as roas,
    ifnull(safe_divide(session_data.revenue_net_refund, spend), 0.00) as roas_net_refund

  FROM session_data
  FULL JOIN online_campaigns_performances
    ON session_data.session_date = online_campaigns_performances.date
    AND session_data.campaign = online_campaigns_performances.campaign_name
    AND ifnull(session_data.campaign_id, "") = ifnull(online_campaigns_performances.campaign_id, "")
  group by all
);