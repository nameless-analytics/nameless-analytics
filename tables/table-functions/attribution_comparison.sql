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

declare attribution_comparison string default format ("""
CREATE OR REPLACE TABLE FUNCTION `%s.%s.attribution_comparison`(start_date DATE, end_date DATE, conversion_name STRING, lookback_days INT64) AS (
with attribution_data_single_touch as (
    select *
    from `%s.%s.attribution_single_touch`(start_date, end_date, conversion_name, lookback_days)
  ),

  attribution_data_multi_touch as (
    select *
    from `%s.%s.attribution_multi_touch`(start_date, end_date, conversion_name, lookback_days)
  ),

  attribution_models_single_touch as (
    select
      attribution_model.session_channel_grouping,
      attribution_model.session_custom_channel_grouping,
      attribution_model.session_source,
      attribution_model.session_campaign_year,
      attribution_model.session_campaign_country,
      attribution_model.session_campaign_funnel_stage,
      attribution_model.session_campaign_platform,
      attribution_model.session_campaign_type,
      attribution_model.session_campaign_marketing_objective,
      attribution_model.session_campaign_name,
      attribution_model.session_campaign,
      attribution_model.session_campaign_id,
      attribution_model.session_campaign_click_id,
      attribution_model.session_campaign_term,
      attribution_model.session_campaign_content,

      conversion_id,
      1.0 as attributed_conversions,
      conversion_revenue as attributed_revenue,
      attribution_model.attribution_model_name,
      'single_touch' as attribution_model_type

    from attribution_data_single_touch
    cross join unnest([
      struct(
        first_click_channel_grouping as session_channel_grouping,
        first_click_custom_channel_grouping as session_custom_channel_grouping,
        first_click_source as session_source,
        first_click_campaign_year as session_campaign_year,
        first_click_campaign_country as session_campaign_country,
        first_click_campaign_funnel_stage as session_campaign_funnel_stage,
        first_click_campaign_platform as session_campaign_platform,
        first_click_campaign_type as session_campaign_type,
        first_click_campaign_marketing_objective as session_campaign_marketing_objective,
        first_click_campaign_name as session_campaign_name,
        first_click_campaign as session_campaign,
        first_click_campaign_id as session_campaign_id,
        first_click_campaign_click_id as session_campaign_click_id,
        first_click_campaign_term as session_campaign_term,
        first_click_campaign_content as session_campaign_content,
        'first_click' as attribution_model_name
      ),

      struct(
        last_click_channel_grouping as session_channel_grouping,
        last_click_custom_channel_grouping as session_custom_channel_grouping,
        last_click_source as session_source,
        last_click_campaign_year as session_campaign_year,
        last_click_campaign_country as session_campaign_country,
        last_click_campaign_funnel_stage as session_campaign_funnel_stage,
        last_click_campaign_platform as session_campaign_platform,
        last_click_campaign_type as session_campaign_type,
        last_click_campaign_marketing_objective as session_campaign_marketing_objective,
        last_click_campaign_name as session_campaign_name,
        last_click_campaign as session_campaign,
        last_click_campaign_id as session_campaign_id,
        last_click_campaign_click_id as session_campaign_click_id,
        last_click_campaign_term as session_campaign_term,
        last_click_campaign_content as session_campaign_content,
        'last_click' as attribution_model_name
      ),

      struct(
        last_click_non_direct_channel_grouping as session_channel_grouping,
        last_click_non_direct_custom_channel_grouping as session_custom_channel_grouping,
        last_click_non_direct_source as session_source,
        last_click_non_direct_campaign_year as session_campaign_year,
        last_click_non_direct_campaign_country as session_campaign_country,
        last_click_non_direct_campaign_funnel_stage as session_campaign_funnel_stage,
        last_click_non_direct_campaign_platform as session_campaign_platform,
        last_click_non_direct_campaign_type as session_campaign_type,
        last_click_non_direct_campaign_marketing_objective as session_campaign_marketing_objective,
        last_click_non_direct_campaign_name as session_campaign_name,
        last_click_non_direct_campaign as session_campaign,
        last_click_non_direct_campaign_id as session_campaign_id,
        last_click_non_direct_campaign_click_id as session_campaign_click_id,
        last_click_non_direct_campaign_term as session_campaign_term,
        last_click_non_direct_campaign_content as session_campaign_content,
        'last_click_non_direct' as attribution_model_name
      )
    ]) as attribution_model
  ),

  attribution_models_multi_touch as (
    select
      session_channel_grouping,
      session_custom_channel_grouping,
      session_source,
      session_campaign_year,
      session_campaign_country,
      session_campaign_funnel_stage,
      session_campaign_platform,
      session_campaign_type,
      session_campaign_marketing_objective,
      session_campaign_name,
      session_campaign,
      session_campaign_id,
      session_campaign_click_id,
      session_campaign_term,
      session_campaign_content,

      conversion_id,
      attribution_model.attributed_conversions,
      attribution_model.attributed_revenue,
      attribution_model.attribution_model_name,
      'multi_touch' as attribution_model_type

    from attribution_data_multi_touch
    cross join unnest([
      struct(
        linear_attribution_credit as attributed_conversions,
        linear_attributed_revenue as attributed_revenue,
        'linear' as attribution_model_name
      ),

      struct(
        time_decay_attribution_credit as attributed_conversions,
        time_decay_attributed_revenue as attributed_revenue,
        'time_decay' as attribution_model_name
      ),

      struct(
        position_based_attribution_credit as attributed_conversions,
        position_based_attributed_revenue as attributed_revenue,
        'position_based' as attribution_model_name
      )
    ]) as attribution_model
  ),

  attribution_models as (
    select *
    from attribution_models_single_touch

    union all

    select *
    from attribution_models_multi_touch
  )

  select
    session_channel_grouping,
    session_custom_channel_grouping,
    session_source,
    session_campaign_year,
    session_campaign_country,
    session_campaign_funnel_stage,
    session_campaign_platform,
    session_campaign_type,
    session_campaign_marketing_objective,
    session_campaign_name,
    session_campaign,
    session_campaign_id,
    session_campaign_click_id,
    session_campaign_term,
    session_campaign_content,
    attribution_model_name,
    attribution_model_type,

    sum(attributed_conversions) as attributed_conversions,
    sum(attributed_revenue) as attributed_revenue

  from attribution_models
  group by all
);
""", project_name, dataset_name, project_name, dataset_name, project_name, dataset_name);

execute immediate attribution_comparison;
