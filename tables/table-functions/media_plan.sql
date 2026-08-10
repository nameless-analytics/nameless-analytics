CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.media_plan`(start_date DATE, end_date DATE) AS (
with media_plan_data as (
    SELECT
      FORMAT_DATE('%m-%Y', date) as date,
      full_campaign_name,
      budget
    FROM `tom-moretti.nameless_analytics.media_plan_sheets`
    where true
      and date between start_date and end_date
      and full_campaign_name is not null
  ),

  online_campaigns_performances as (
    select
      FORMAT_DATE('%m-%Y', date) AS date,
      campaign_name,
      campaign_id,
      cost as cost
    from `tom-moretti.nameless_analytics.online_campaign_performance_sheets`
    where true
      and date between start_date and end_date
      and campaign_name is not null
    group by all
  )

  select 
    media_plan_data.date,
    media_plan_data.full_campaign_name,
    split(media_plan_data.full_campaign_name, '|')[safe_offset(0)] as campaign_year,
    split(media_plan_data.full_campaign_name, '|')[safe_offset(1)] as campaign_country,
    split(media_plan_data.full_campaign_name, '|')[safe_offset(2)] as campaign_funnel_stage,
    split(media_plan_data.full_campaign_name, '|')[safe_offset(3)] as campaign_platform,
    split(media_plan_data.full_campaign_name, '|')[safe_offset(4)] as campaign_campaign_type,
    split(media_plan_data.full_campaign_name, '|')[safe_offset(5)] as campaign_marketing_objective,
    split(media_plan_data.full_campaign_name, '|')[safe_offset(6)] as campaign_name,
    media_plan_data.budget,
    online_campaigns_performances.cost,
    ifnull(1 - safe_divide((media_plan_data.budget - online_campaigns_performances.cost), media_plan_data.budget), 0.00) as spent_over_budget_percentage
  from media_plan_data
  left join online_campaigns_performances
    on media_plan_data.date = online_campaigns_performances.date
    and media_plan_data.full_campaign_name = online_campaigns_performances.campaign_name
);