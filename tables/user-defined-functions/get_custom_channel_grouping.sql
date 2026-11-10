declare project_name string default 'PROJECT NAME';  -- Change this
declare dataset_name string default 'nameless_analytics';

-- The custom channel grouping, beside the standard one (get_channel_grouping,
-- the Server-side Client Tag's logic, which stays as it is). Off by default:
-- it returns NULL for every row until you replace the body with your own
-- rules, on the same source, medium, campaign and click ID. For example:
--   CASE
--     WHEN REGEXP_CONTAINS(source, r'(?i)partner') THEN 'partners'
--     WHEN LOWER(medium) = 'qr' THEN 'offline'
--     ELSE 'other'
--   END
-- Changes apply to historical reports at query time.
declare get_custom_channel_grouping string default format ("""
CREATE OR REPLACE FUNCTION `%s.%s.get_custom_channel_grouping`(source STRING, medium STRING, campaign STRING, campaign_click_id STRING) RETURNS STRING AS (
  CAST(NULL AS STRING)
);
""", project_name, dataset_name);

execute immediate get_custom_channel_grouping;
