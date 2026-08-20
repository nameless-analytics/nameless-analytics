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

declare project_name string default 'PROJECT NAME';  -- Change this
declare dataset_name string default 'nameless_analytics';

declare media_plan string default format ("""
CREATE OR REPLACE TABLE FUNCTION `%s.%s.media_plan`(start_date DATE, end_date DATE) AS (
with media_plan_data as (
    select
      format_date('%%Y-%%m', date) as year_month,
      format_date('%%Y', date) as year,
      format_date('%%m', date) as month,
      full_campaign_name as campaign,
      ifnull(sum(budget), 0.0) as budget
    from `%s.%s.media_plan_sheets`
    where true
      and date between start_date and end_date
      and full_campaign_name is not null
    group by all
  ),

  online_campaigns_performances as (
    select
      FORMAT_DATE('%%Y-%%m', date) AS year_month,
      campaign,
      sum(cost) as spend
    from `%s.%s.online_campaign_performance_sheets`
    where true
      and date between start_date and end_date
      and campaign is not null
    group by all
  )

  select 
    media_plan_data.year_month,
    media_plan_data.year,
    media_plan_data.month,
    `%s.%s.get_campaign_part`(media_plan_data.campaign, 'campaign_year') as campaign_year,
    `%s.%s.get_campaign_part`(media_plan_data.campaign, 'campaign_country') as campaign_country,
    `%s.%s.get_campaign_part`(media_plan_data.campaign, 'campaign_funnel_stage') as campaign_funnel_stage,
    `%s.%s.get_campaign_part`(media_plan_data.campaign, 'campaign_platform') as campaign_platform,
    `%s.%s.get_campaign_part`(media_plan_data.campaign, 'campaign_type') as campaign_type,
    `%s.%s.get_campaign_part`(media_plan_data.campaign, 'campaign_marketing_objective') as campaign_marketing_objective,
    `%s.%s.get_campaign_part`(media_plan_data.campaign, 'campaign_name') as campaign_name,
    media_plan_data.campaign,
    media_plan_data.budget,
    ifnull(online_campaigns_performances.spend, 0.0) as spend
  from media_plan_data
  left join online_campaigns_performances
    on media_plan_data.year_month = online_campaigns_performances.year_month
    and media_plan_data.campaign = online_campaigns_performances.campaign
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

execute immediate media_plan;
