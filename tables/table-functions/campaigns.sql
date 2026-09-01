declare project_name string default 'PROJECT NAME';  -- Change this
declare dataset_name string default 'nameless_analytics';

declare campaigns string default format ("""
CREATE OR REPLACE TABLE FUNCTION `%s.%s.campaigns`(start_date DATE, end_date DATE) AS (
with session_data as (
    select
      session_date,
      session_campaign_year,
      session_campaign_country,
      session_campaign_funnel_stage,
      session_campaign_platform,
      session_campaign_type,
      session_campaign_marketing_objective,
      session_campaign_name,
      session_campaign,
      session_campaign_id,

      # POST CLICK
      count(distinct new_user_client_id) as new_users,
      count(distinct session_id) as sessions,
      avg(session_duration_sec) as avg_session_duration_sec,
      sum(new_session) as total_new_sessions,
      safe_divide(sum(new_session), count(distinct session_id)) as new_sessions_percentage,
      sum(returning_session) as total_returning_sessions,
      safe_divide(sum(returning_session), count(distinct session_id)) as returning_sessions_percentage,
      sum(engaged_session) as total_engaged_sessions,
      safe_divide(sum(engaged_session), count(distinct session_id)) as engaged_sessions_percentage,
      sum(session_with_sign_up) as sessions_with_sign_up,
      sum(session_with_newsletter_sign_up) as sessions_with_newsletter_sign_up,
      sum(session_with_new_lead) as sessions_with_new_lead,
      sum(session_with_purchase) as sessions_with_purchase,
      sum(session_with_refund) as sessions_with_refund,
      safe_divide(sum(total_page_views), count(distinct session_id)) as page_view_per_session,
      sum(total_events) as total_events,
      sum(total_page_views) as total_page_views,
      sum(sign_up) as sign_up,
      sum(newsletter_sign_up) as newsletter_sign_up,
      sum(new_lead) as new_lead,
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
    from `%s.%s.sessions`(start_date, end_date)
    where true 
      and session_campaign is not null
    group by all
  ),

  online_campaigns_performances as (
    select
      date,
      `%s.%s.get_campaign_part`(campaign, 'campaign_year') as session_campaign_year,
      `%s.%s.get_campaign_part`(campaign, 'campaign_country') as session_campaign_country,
      `%s.%s.get_campaign_part`(campaign, 'campaign_funnel_stage') as session_campaign_funnel_stage,
      `%s.%s.get_campaign_part`(campaign, 'campaign_platform') as session_campaign_platform,
      `%s.%s.get_campaign_part`(campaign, 'campaign_type') as session_campaign_type,
      `%s.%s.get_campaign_part`(campaign, 'campaign_marketing_objective') as session_campaign_marketing_objective,
      `%s.%s.get_campaign_part`(campaign, 'campaign_name') as session_campaign_name,
      campaign as session_campaign,
      campaign_id as session_campaign_id, 
      sum(cost) as spend,
      sum(impression) as impression,
      sum(click) as click,
      safe_divide(sum(cost), sum(click)) as avg_cost_per_click,
      safe_divide(sum(click), sum(impression)) as avg_click_through_rate,
    from `%s.%s.online_campaign_performance_sheets`
    where true 
      and date between start_date and end_date
      and date is not null
      and campaign is not null
    group by all
  )

  select 
    coalesce(session_data.session_date, online_campaigns_performances.date) as session_date,
    coalesce(session_data.session_campaign_year, online_campaigns_performances.session_campaign_year) as session_campaign_year,
    coalesce(session_data.session_campaign_country, online_campaigns_performances.session_campaign_country) as session_campaign_country,
    coalesce(session_data.session_campaign_funnel_stage, online_campaigns_performances.session_campaign_funnel_stage) as session_campaign_funnel_stage,
    coalesce(session_data.session_campaign_platform, online_campaigns_performances.session_campaign_platform) as session_campaign_platform,
    coalesce(session_data.session_campaign_type, online_campaigns_performances.session_campaign_type) as session_campaign_type,
    coalesce(session_data.session_campaign_marketing_objective, online_campaigns_performances.session_campaign_marketing_objective) as session_campaign_marketing_objective,
    coalesce(session_data.session_campaign_name, online_campaigns_performances.session_campaign_name) as session_campaign_name,
    coalesce(session_data.session_campaign, online_campaigns_performances.session_campaign) as session_campaign,
    coalesce(session_data.session_campaign_id, online_campaigns_performances.session_campaign_id) as session_campaign_id,

    # PRE CLICK
    ifnull(spend, 0.00) as spend,
    ifnull(safe_divide(spend, sign_up), 0.00) as cost_per_sign_up,
    ifnull(safe_divide(spend, newsletter_sign_up), 0.00) as cost_per_newsletter_sign_up,
    ifnull(safe_divide(spend, new_lead), 0.00) as cost_per_new_lead,
    ifnull(safe_divide(spend, purchase), 0.00) as cost_per_purchase,
    ifnull(impression, 0.00) as impression,
    ifnull(click, 0.00) as click,
    ifnull(avg_cost_per_click, 0.00) as avg_cost_per_click,
    ifnull(avg_click_through_rate, 0.00) as avg_click_through_rate,

    # POST CLICK
    ifnull(session_data.new_users, 0) as new_users,
    ifnull(session_data.sessions, 0) as sessions,
    ifnull(session_data.avg_session_duration_sec, 0.0) as avg_session_duration_sec,
    ifnull(session_data.total_new_sessions, 0) as total_new_sessions,
    ifnull(session_data.new_sessions_percentage, 0.0) as new_sessions_percentage,
    ifnull(session_data.total_returning_sessions, 0) as total_returning_sessions,
    ifnull(session_data.returning_sessions_percentage, 0.0) as returning_sessions_percentage,
    ifnull(session_data.total_engaged_sessions, 0) as total_engaged_sessions,
    ifnull(session_data.engaged_sessions_percentage, 0.0) as engaged_sessions_percentage,
    ifnull(session_data.sessions_with_sign_up, 0) as sessions_with_sign_up,
    ifnull(session_data.sessions_with_newsletter_sign_up, 0) as sessions_with_newsletter_sign_up,
    ifnull(session_data.sessions_with_new_lead, 0) as sessions_with_new_lead,
    ifnull(session_data.sessions_with_purchase, 0) as sessions_with_purchase,
    ifnull(session_data.sessions_with_refund, 0) as sessions_with_refund,
    ifnull(session_data.page_view_per_session, 0.0) as page_view_per_session,
    ifnull(session_data.total_events, 0) as total_events,
    ifnull(session_data.total_page_views, 0) as total_page_views,
    ifnull(session_data.sign_up, 0) as sign_up,
    ifnull(session_data.newsletter_sign_up, 0) as newsletter_sign_up,
    ifnull(session_data.new_lead, 0) as new_lead,
    ifnull(session_data.purchase, 0) as purchase,
    ifnull(session_data.refund, 0) as refund,
    ifnull(session_data.purchase_revenue, 0.0) as purchase_revenue,
    ifnull(session_data.purchase_shipping, 0.0) as purchase_shipping,
    ifnull(session_data.purchase_tax, 0.0) as purchase_tax,
    ifnull(session_data.avg_order_value, 0.0) as avg_order_value,
    ifnull(session_data.refund_revenue, 0.0) as refund_revenue,
    ifnull(session_data.refund_shipping, 0.0) as refund_shipping,
    ifnull(session_data.refund_tax, 0.0) as refund_tax,
    ifnull(session_data.avg_refund_value, 0.0) as avg_refund_value,
    ifnull(session_data.purchase_net_refund, 0) as purchase_net_refund,
    ifnull(session_data.revenue_net_refund, 0.0) as revenue_net_refund,
    ifnull(session_data.shipping_net_refund, 0.0) as shipping_net_refund,
    ifnull(session_data.tax_net_refund, 0.0) as tax_net_refund,
    ifnull(safe_divide(session_data.purchase_revenue, spend), 0.00) as roas,
    ifnull(safe_divide(session_data.revenue_net_refund, spend), 0.00) as roas_net_refund

  FROM session_data
  FULL JOIN online_campaigns_performances
    ON session_data.session_date = online_campaigns_performances.date
    AND lower(session_data.session_campaign) = lower(online_campaigns_performances.session_campaign)
    AND ifnull(session_data.session_campaign_id, "") = ifnull(online_campaigns_performances.session_campaign_id, "")
);
""",
project_name, dataset_name,
project_name, dataset_name,
project_name, dataset_name,
project_name, dataset_name,
project_name, dataset_name,
project_name, dataset_name,
project_name, dataset_name,
project_name, dataset_name,
project_name, dataset_name,
project_name, dataset_name);

execute immediate campaigns;
