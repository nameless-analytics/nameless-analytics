CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.campaigns`(start_date DATE, end_date DATE) AS (
  with session_data as (
    select
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
      avg(session_duration_sec) as session_duration_sec,
      sum(new_session) as new_session,
      safe_divide(sum(new_session), count(distinct session_id)) as new_sessions_percentage,
      sum(returning_session) as returning_session,
      safe_divide(sum(returning_session), count(distinct session_id)) as returning_sessions_percentage,
      sum(engaged_session) as engaged_session,
      safe_divide(sum(engaged_session), count(distinct session_id)) as engaged_sessions_percentage,
      sum(session_with_account_creation) as session_with_account_creation,
      sum(session_with_newsletter_subscription) as session_with_newsletter_subscription,
      sum(session_with_form_submission) as session_with_form_submission,
      sum(session_with_purchase) as session_with_purchase,
      sum(session_with_refund) as session_with_refund,
      safe_divide(sum(total_page_views), count(distinct session_id)) as page_view_per_session,
      sum(total_events) as total_events,
      sum(total_page_views) as total_page_views,
      sum(account_creation) as account_creation,
      sum(newsletter_subscription) as newsletter_subscription,
      sum(form_submission) as form_submission,
      sum(purchase) as purchase,
      sum(refund) as refund,
      sum(purchase_revenue) as purchase_revenue,
      sum(purchase_shipping) as purchase_shipping,
      sum(purchase_tax) as purchase_tax,
      ifnull(safe_divide(sum(purchase_revenue), sum(purchase)), 0) as avg_order_value,
      sum(refund_revenue) as refund_revenue,
      sum(refund_shipping) as refund_shipping,
      sum(refund_tax) as refund_tax,
      ifnull(safe_divide(sum(refund_revenue), sum(refund)), 0) as avg_refund_value,
      sum(purchase_net_refund) as purchase_net_refund,
      sum(revenue_net_refund) as revenue_net_refund,
      sum(shipping_net_refund) as shipping_net_refund,
      sum(tax_net_refund) as tax_net_refund
    from `tom-moretti.nameless_analytics.sessions`(start_date, end_date)
    where true 
      and session_campaign is not null
    group by all
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
      sum(cost) as spend,
      sum(impression) as impression,
      sum(click) as click,
      safe_divide(sum(cost), sum(click)) as avg_cost_per_click,
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
    coalesce(session_data.campaign, online_campaigns_performances.campaign) as campaign,
    coalesce(session_data.campaign_id, online_campaigns_performances.campaign_id) as campaign_id,
 
    # PRE CLICK
    ifnull(spend, 0.00) as spend,
    ifnull(safe_divide(spend, account_creation), 0.00) as cost_per_account_creation,
    ifnull(safe_divide(spend, newsletter_subscription), 0.00) as cost_per_newsletter_subscription,
    ifnull(safe_divide(spend, form_submission), 0.00) as cost_per_form_submission,
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
    session_data.session_with_account_creation,
    session_data.session_with_newsletter_subscription,
    session_data.session_with_form_submission,
    session_data.session_with_purchase,
    session_data.session_with_refund,
    session_data.page_view_per_session,
    session_data.total_events,
    session_data.total_page_views,
    session_data.account_creation,
    session_data.newsletter_subscription,
    session_data.form_submission,
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
    AND session_data.campaign = online_campaigns_performances.campaign
    AND ifnull(session_data.campaign_id, "") = ifnull(online_campaigns_performances.campaign_id, "")
);