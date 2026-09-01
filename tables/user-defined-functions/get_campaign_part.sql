declare project_name string default 'PROJECT NAME';  -- Change this
declare dataset_name string default 'nameless_analytics';

declare get_campaign_part string default format ("""
CREATE OR REPLACE FUNCTION `%s.%s.get_campaign_part`(campaign STRING, part_name STRING) RETURNS STRING AS (
  CASE
    when part_name = 'campaign_year' then split(campaign, '|')[safe_offset(0)]
    when part_name = 'campaign_country' then split(campaign, '|')[safe_offset(1)]
    when part_name = 'campaign_funnel_stage' then split(campaign, '|')[safe_offset(2)]
    when part_name = 'campaign_platform' then split(campaign, '|')[safe_offset(3)]
    when part_name = 'campaign_type' then split(campaign, '|')[safe_offset(4)]
    when part_name = 'campaign_marketing_objective' then split(campaign, '|')[safe_offset(5)]
    when part_name = 'campaign_name' then split(campaign, '|')[safe_offset(6)]
    else null
  END
);
""", project_name, dataset_name);

execute immediate get_campaign_part;