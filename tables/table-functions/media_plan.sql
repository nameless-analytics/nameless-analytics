/* @datacloud.settings
{
  "version": 1,
  "service": "BIG_QUERY",
  "connectionInfo": {
    "billingProjectId": "INHERIT",
    "location": "INHERIT"
  },
  "dialect": "GOOGLE_SQL"
}
*/

CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.media_plan`(start_date DATE, end_date DATE) AS (
with media_plan_data as (
    SELECT
      FORMAT_DATE('%Y-%m', date) as year_month,
      FORMAT_DATE('%Y', date) as year,
      FORMAT_DATE('%m', date) as month,
      full_campaign_name as campaign,
      budget
    FROM `tom-moretti.nameless_analytics.media_plan_sheets`
    where true
      and date between start_date and end_date
      and full_campaign_name is not null
  ),

  online_campaigns_performances as (
    select
      FORMAT_DATE('%Y-%m', date) AS year_month,
      campaign,
      sum(cost) as spend
    from `tom-moretti.nameless_analytics.online_campaign_performance_sheets`
    where true
      and date between start_date and end_date
      and campaign is not null
    group by all
  )

  select 
    media_plan_data.year_month,
    media_plan_data.year,
    media_plan_data.month,
    `tom-moretti.nameless_analytics.get_campaign_part`(media_plan_data.campaign, 'campaign_year') as campaign_year,
    `tom-moretti.nameless_analytics.get_campaign_part`(media_plan_data.campaign, 'campaign_country') as campaign_country,
    `tom-moretti.nameless_analytics.get_campaign_part`(media_plan_data.campaign, 'campaign_funnel_stage') as campaign_funnel_stage,
    `tom-moretti.nameless_analytics.get_campaign_part`(media_plan_data.campaign, 'campaign_platform') as campaign_platform,
    `tom-moretti.nameless_analytics.get_campaign_part`(media_plan_data.campaign, 'campaign_type') as campaign_type,
    `tom-moretti.nameless_analytics.get_campaign_part`(media_plan_data.campaign, 'campaign_marketing_objective') as campaign_marketing_objective,
    `tom-moretti.nameless_analytics.get_campaign_part`(media_plan_data.campaign, 'campaign_name') as campaign_name,
    media_plan_data.campaign,
    sum(media_plan_data.budget) as budget,
    sum(online_campaigns_performances.spend) as spend
  from media_plan_data
  left join online_campaigns_performances
    on media_plan_data.year_month = online_campaigns_performances.year_month
    and media_plan_data.campaign = online_campaigns_performances.campaign
  group by all
);