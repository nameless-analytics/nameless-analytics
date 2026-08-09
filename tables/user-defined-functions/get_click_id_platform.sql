declare project_name string default 'PROJECT NAME';  -- Change this
declare dataset_name string default 'nameless_analytics';

declare get_click_id_platform string default format ("""
CREATE OR REPLACE FUNCTION `%s.%s.get_click_id_platform`(page_query STRING) RETURNS STRING AS (
  CASE
    WHEN REGEXP_CONTAINS(page_query, r'(^|&)(gclid|dclid|gclsrc|wbraid|gbraid)=') THEN 'google_ads'
    WHEN REGEXP_CONTAINS(page_query, r'(^|&)msclkid=') THEN 'microsoft_ads'
    WHEN REGEXP_CONTAINS(page_query, r'(^|&)fbclid=') THEN 'meta'
    WHEN REGEXP_CONTAINS(page_query, r'(^|&)ttclid=') THEN 'tiktok'
    WHEN REGEXP_CONTAINS(page_query, r'(^|&)twclid=') THEN 'x'
    WHEN REGEXP_CONTAINS(page_query, r'(^|&)li_fat_id=') THEN 'linkedin'
    WHEN REGEXP_CONTAINS(page_query, r'(^|&)epik=') THEN 'pinterest'
    WHEN REGEXP_CONTAINS(page_query, r'(^|&)scclid=') THEN 'snapchat'
    ELSE NULL
  END
);
""", project_name, dataset_name);

execute immediate get_click_id_platform;