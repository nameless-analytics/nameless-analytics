CREATE OR REPLACE TABLE FUNCTION `tom-moretti.nameless_analytics.attribution_comparison`(start_date DATE, end_date DATE, conversion_event STRING, lookback_days INT64) AS (
  with attribution_data_single_touch as (
    select *
    from `tom-moretti.nameless_analytics.attribution_single_touch`(start_date, end_date, conversion_event, lookback_days)
  ),

  -- attribution_data_multi_touch as (
  --   select *
  --   from `tom-moretti.nameless_analytics.attribution_multi_touch`(start_date, end_date, conversion_event, lookback_days)
  -- ),

  attribution_models as (
    # LAST CLICK
    select
        last_click_channel_grouping as channel_grouping,
        last_click_source as source,
        conversion_id,
        'last_click' as attribution_model
    from attribution_data_single_touch
  
    union all
  
    # FIRST CLICK
    select
        first_click_channel_grouping as channel_grouping,
        first_click_source as source,
        conversion_id,
        'first_click' as attribution_model
    from attribution_data_single_touch
  
    union all
  
    # LAST CLICK NON-DIRECT
    select
        last_click_non_direct_channel_grouping as channel_grouping,
        last_click_non_direct_source as source,
        conversion_id,
        'last_click_non_direct' as attribution_model
    from attribution_data_single_touch

    # LINEAR

    # TIME DECAY
    
    # POSITION-BASED

  )

  select
    channel_grouping,
    source,
    count(conversion_id) as conversions,
    attribution_model,
  from attribution_models
  group by all
  order by conversions desc
);