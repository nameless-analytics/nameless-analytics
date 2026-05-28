CREATE OR REPLACE FUNCTION `tom-moretti.nameless_analytics.get_custom_channel_grouping`(source STRING, campaign STRING) RETURNS STRING AS (
  CASE
    WHEN source IS NULL OR source = 'direct' THEN 'direct'
    WHEN source = 'tagassistant.google.com' THEN 'gtm_debugger'
    WHEN REGEXP_CONTAINS(source, r'(?i)chatgpt|gemini|bard|claude|alexa|siri|assistant|\.ai([/]|$)') THEN 'ai'
    WHEN REGEXP_CONTAINS(source, r'(?i)360\.cn|alice|aol|ar\.search\.yahoo\.com|ask|bing|google|yahoo|yandex|baidu|ecosia|duckduckgo|sogou|naver|seznam') THEN IF(campaign IS NOT NULL AND campaign != '', 'paid_search_engine', 'organic_search_engine')
    WHEN REGEXP_CONTAINS(source, r'(?i)facebook|twitter|t\.co|bsky\.app|instagram|pinterest|linkedin|reddit|vk\.com|tiktok|snapchat|tumblr|wechat|whatsapp') THEN IF(campaign IS NOT NULL AND campaign != '', 'paid_social', 'organic_social')
    WHEN REGEXP_CONTAINS(source, r'(?i)amazon|ebay|etsy|shopify|stripe|walmart|mercadolibre|alibaba|naver\.shopping') THEN IF(campaign IS NOT NULL AND campaign != '', 'paid_shopping', 'organic_shopping')
    WHEN REGEXP_CONTAINS(source, r'(?i)youtube|vimeo|netflix|twitch|dailymotion|hulu|disneyplus|wistia|youku') THEN IF(campaign IS NOT NULL AND campaign != '', 'paid_video', 'organic_video')
    WHEN REGEXP_CONTAINS(source, r'(?i)email|e-mail|newsletter|mailchimp|sendgrid|sparkpost') THEN 'email'
    WHEN campaign IS NULL OR campaign = '' THEN 'referral'
    ELSE 'affiliate'
  END
);