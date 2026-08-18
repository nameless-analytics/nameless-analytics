-- =========================================================================
-- MATRICE CAMPI COMPLETA CON DIZIONARIO DESCRIZIONI
-- DATASET: tom-moretti.nameless_analytics
-- COSTO ELABORAZIONE: 0 BYTE
-- =========================================================================

-- 1. Crea Viste temporanee di appoggio nel dataset per estrarre lo schema
FOR routine IN (
  SELECT 
    r.routine_name,
    COALESCE(
      STRING_AGG(
        CASE 
          WHEN p.data_type = 'DATE' THEN 'CURRENT_DATE()'
          WHEN p.data_type = 'STRING' THEN "'purchase'"
          WHEN p.data_type = 'INT64' THEN '30'
          WHEN p.data_type = 'FLOAT64' THEN '1.0'
          WHEN p.data_type = 'BOOL' THEN 'TRUE'
          ELSE 'NULL'
        END, 
        ', ' ORDER BY p.ordinal_position
      ), 
      ''
    ) AS dummy_args
  FROM `tom-moretti.nameless_analytics.INFORMATION_SCHEMA.ROUTINES` r
  LEFT JOIN `tom-moretti.nameless_analytics.INFORMATION_SCHEMA.PARAMETERS` p
    ON r.specific_name = p.specific_name
  WHERE r.routine_type = 'TABLE FUNCTION'
    AND r.routine_name NOT LIKE 'get_%'
  GROUP BY r.routine_name
)
DO
  EXECUTE IMMEDIATE FORMAT("""
    CREATE OR REPLACE VIEW `tom-moretti.nameless_analytics.matrix_%s` AS 
    SELECT * FROM `tom-moretti.nameless_analytics.%s`(%s);
  """, routine.routine_name, routine.routine_name, routine.dummy_args);

END FOR;

-- 2. Salva la tabella 'fields' facendo il LEFT JOIN con il dizionario completo delle descrizioni
CREATE OR REPLACE TABLE `tom-moretti.nameless_analytics.fields` AS
WITH dictionary AS (
  SELECT 'F_normalized' AS field_name, 'Metric' AS field_type, 'Normalized Frequency score for RFM segmentation.' AS field_description UNION ALL
  SELECT 'M_normalized' AS field_name, 'Metric' AS field_type, 'Normalized Monetary score for RFM segmentation.' AS field_description UNION ALL
  SELECT 'RFM_segment' AS field_name, 'Dimension' AS field_type, 'RFM segment classification name.' AS field_description UNION ALL
  SELECT 'RFM_weighted_score' AS field_name, 'Metric' AS field_type, 'Weighted composite RFM score.' AS field_description UNION ALL
  SELECT 'R_normalized' AS field_name, 'Metric' AS field_type, 'Normalized Recency score for RFM segmentation.' AS field_description UNION ALL
  SELECT 'account_creation' AS field_name, 'Metric' AS field_type, 'Total count of account creation events.' AS field_description UNION ALL
  SELECT 'ad_personalization' AS field_name, 'Dimension' AS field_type, 'Consent state for ad personalization.' AS field_description UNION ALL
  SELECT 'ad_personalization_accepted_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions where ad personalization was accepted.' AS field_description UNION ALL
  SELECT 'ad_personalization_denied_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions where ad personalization was denied.' AS field_description UNION ALL
  SELECT 'ad_storage' AS field_name, 'Dimension' AS field_type, 'Consent state for advertising storage (e.g., cookies).' AS field_description UNION ALL
  SELECT 'ad_storage_accepted_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions where ad storage was accepted.' AS field_description UNION ALL
  SELECT 'ad_storage_denied_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions where ad storage was denied.' AS field_description UNION ALL
  SELECT 'ad_user_data' AS field_name, 'Dimension' AS field_type, 'Consent state for sending user data to Google for advertising.' AS field_description UNION ALL
  SELECT 'ad_user_data_accepted_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions where ad user data was accepted.' AS field_description UNION ALL
  SELECT 'ad_user_data_denied_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions where ad user data was denied.' AS field_description UNION ALL
  SELECT 'add_payment_info' AS field_name, 'Metric' AS field_type, 'Total number of sessions where payment information was added.' AS field_description UNION ALL
  SELECT 'add_shipping_info' AS field_name, 'Metric' AS field_type, 'Total number of sessions where shipping information was added.' AS field_description UNION ALL
  SELECT 'add_to_cart' AS field_name, 'Metric' AS field_type, 'Total number of sessions with at least one add_to_cart event.' AS field_description UNION ALL
  SELECT 'add_to_wishlist' AS field_name, 'Metric' AS field_type, 'Total number of sessions with at least one add_to_wishlist event.' AS field_description UNION ALL
  SELECT 'analytics_storage' AS field_name, 'Dimension' AS field_type, 'Consent state for analytics storage (e.g., cookies).' AS field_description UNION ALL
  SELECT 'analytics_storage_accepted_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions where analytics storage was accepted.' AS field_description UNION ALL
  SELECT 'analytics_storage_denied_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions where analytics storage was denied.' AS field_description UNION ALL
  SELECT 'attributed_account_creation' AS field_name, 'Metric' AS field_type, 'Total count of account creation events attributed.' AS field_description UNION ALL
  SELECT 'attributed_conversions' AS field_name, 'Metric' AS field_type, 'Total count of conversions attributed.' AS field_description UNION ALL
  SELECT 'attributed_form_submission' AS field_name, 'Metric' AS field_type, 'Total count of form submission events attributed.' AS field_description UNION ALL
  SELECT 'attributed_newsletter_subscription' AS field_name, 'Metric' AS field_type, 'Total count of newsletter subscription events attributed.' AS field_description UNION ALL
  SELECT 'attributed_purchase' AS field_name, 'Metric' AS field_type, 'Total count of purchase events attributed.' AS field_description UNION ALL
  SELECT 'attributed_revenue' AS field_name, 'Metric' AS field_type, 'Total purchase revenue attributed.' AS field_description UNION ALL
  SELECT 'attribution_model' AS field_name, 'Dimension' AS field_type, 'Attribution model applied.' AS field_description UNION ALL
  SELECT 'attribution_model_name' AS field_name, 'Dimension' AS field_type, 'Name of the attribution model.' AS field_description UNION ALL
  SELECT 'attribution_model_type' AS field_name, 'Dimension' AS field_type, 'Type classification of attribution model.' AS field_description UNION ALL
  SELECT 'avg_click_through_rate' AS field_name, 'Metric' AS field_type, 'Average click through rate.' AS field_description UNION ALL
  SELECT 'avg_cost_per_click' AS field_name, 'Metric' AS field_type, 'Average cost per click.' AS field_description UNION ALL
  SELECT 'avg_order_value' AS field_name, 'Metric' AS field_type, 'Average order value generated per session.' AS field_description UNION ALL
  SELECT 'avg_purchase_value' AS field_name, 'Metric' AS field_type, 'Average monetary value of purchases per user.' AS field_description UNION ALL
  SELECT 'avg_refund_value' AS field_name, 'Metric' AS field_type, 'Average monetary value of refunds per user.' AS field_description UNION ALL
  SELECT 'begin_checkout' AS field_name, 'Metric' AS field_type, 'Total number of sessions where the checkout process was started.' AS field_description UNION ALL
  SELECT 'browser_language' AS field_name, 'Dimension' AS field_type, 'The language setting of the user browser.' AS field_description UNION ALL
  SELECT 'browser_name' AS field_name, 'Dimension' AS field_type, 'The name of the browser (e.g., Chrome, Safari).' AS field_description UNION ALL
  SELECT 'browser_version' AS field_name, 'Dimension' AS field_type, 'The specific version of the browser.' AS field_description UNION ALL
  SELECT 'budget' AS field_name, 'Metric' AS field_type, 'Allocated campaign budget amount.' AS field_description UNION ALL
  SELECT 'campaign' AS field_name, 'Dimension' AS field_type, 'The name of the marketing campaign.' AS field_description UNION ALL
  SELECT 'campaign_click_id' AS field_name, 'Dimension' AS field_type, 'The campaign click ID (e.g., GCLID).' AS field_description UNION ALL
  SELECT 'campaign_content' AS field_name, 'Dimension' AS field_type, 'The content of the marketing campaign.' AS field_description UNION ALL
  SELECT 'campaign_country' AS field_name, 'Dimension' AS field_type, 'Target country of the marketing campaign.' AS field_description UNION ALL
  SELECT 'campaign_funnel_stage' AS field_name, 'Dimension' AS field_type, 'Funnel stage assigned to campaign.' AS field_description UNION ALL
  SELECT 'campaign_id' AS field_name, 'Dimension' AS field_type, 'The ID of the marketing campaign.' AS field_description UNION ALL
  SELECT 'campaign_marketing_objective' AS field_name, 'Dimension' AS field_type, 'Marketing objective of the campaign for the event.' AS field_description UNION ALL
  SELECT 'campaign_medium' AS field_name, 'Dimension' AS field_type, 'The medium of the marketing campaign.' AS field_description UNION ALL
  SELECT 'campaign_name' AS field_name, 'Dimension' AS field_type, 'Full campaign name.' AS field_description UNION ALL
  SELECT 'campaign_platform' AS field_name, 'Dimension' AS field_type, 'Platform running the campaign.' AS field_description UNION ALL
  SELECT 'campaign_source' AS field_name, 'Dimension' AS field_type, 'The source of the marketing campaign.' AS field_description UNION ALL
  SELECT 'campaign_term' AS field_name, 'Dimension' AS field_type, 'The term (keyword) of the marketing campaign.' AS field_description UNION ALL
  SELECT 'campaign_type' AS field_name, 'Dimension' AS field_type, 'Classification type of marketing campaign.' AS field_description UNION ALL
  SELECT 'campaign_year' AS field_name, 'Dimension' AS field_type, 'Year of the campaign run.' AS field_description UNION ALL
  SELECT 'channel_grouping' AS field_name, 'Dimension' AS field_type, 'The acquisition channel grouping (e.g., Organic Search).' AS field_description UNION ALL
  SELECT 'city' AS field_name, 'Dimension' AS field_type, 'The user city based on IP address.' AS field_description UNION ALL
  SELECT 'click' AS field_name, 'Metric' AS field_type, 'Total clicks count.' AS field_description UNION ALL
  SELECT 'client_id' AS field_name, 'Dimension' AS field_type, 'Unique identifier for the client/browser.' AS field_description UNION ALL
  SELECT 'consent_expressed' AS field_name, 'Dimension' AS field_type, 'Indicates if a consent choice was expressed during the session.' AS field_description UNION ALL
  SELECT 'consent_name' AS field_name, 'Dimension' AS field_type, 'The name of the consent category (e.g., ad_storage, analytics_storage).' AS field_description UNION ALL
  SELECT 'consent_state' AS field_name, 'Dimension' AS field_type, 'The current state of the consent (e.g., granted, denied).' AS field_description UNION ALL
  SELECT 'consent_timestamp' AS field_name, 'Dimension' AS field_type, 'Timestamp when consent was recorded in the session.' AS field_description UNION ALL
  SELECT 'consent_type' AS field_name, 'Dimension' AS field_type, 'The type of consent being expressed or updated.' AS field_description UNION ALL
  SELECT 'consent_value_int_accepted' AS field_name, 'Metric' AS field_type, 'Integer flag (1/0) indicating if the consent was accepted.' AS field_description UNION ALL
  SELECT 'consent_value_int_denied' AS field_name, 'Metric' AS field_type, 'Integer flag (1/0) indicating if the consent was denied.' AS field_description UNION ALL
  SELECT 'consent_value_string' AS field_name, 'Dimension' AS field_type, 'The raw string value of the consent expressed.' AS field_description UNION ALL
  SELECT 'content_length_in_kb' AS field_name, 'Metric' AS field_type, 'The length of the request content in kilobytes.' AS field_description UNION ALL
  SELECT 'conversion_date' AS field_name, 'Dimension' AS field_type, 'Date of conversion.' AS field_description UNION ALL
  SELECT 'conversion_id' AS field_name, 'Dimension' AS field_type, 'Identifier of conversion.' AS field_description UNION ALL
  SELECT 'conversion_name' AS field_name, 'Dimension' AS field_type, 'Name of conversion event.' AS field_description UNION ALL
  SELECT 'conversion_revenue' AS field_name, 'Metric' AS field_type, 'Revenue generated by conversion.' AS field_description UNION ALL
  SELECT 'conversion_session_id' AS field_name, 'Dimension' AS field_type, 'Session ID when conversion occurred.' AS field_description UNION ALL
  SELECT 'conversion_timestamp' AS field_name, 'Dimension' AS field_type, 'Timestamp of conversion.' AS field_description UNION ALL
  SELECT 'conversions' AS field_name, 'Metric' AS field_type, 'Count of conversions.' AS field_description UNION ALL
  SELECT 'conversions_revenue' AS field_name, 'Metric' AS field_type, 'Total revenue from conversions.' AS field_description UNION ALL
  SELECT 'cost_per_account_creation' AS field_name, 'Metric' AS field_type, 'Cost per account creation event.' AS field_description UNION ALL
  SELECT 'cost_per_form_submission' AS field_name, 'Metric' AS field_type, 'Cost per form submission event.' AS field_description UNION ALL
  SELECT 'cost_per_newsletter_subscription' AS field_name, 'Metric' AS field_type, 'Cost per newsletter subscription event.' AS field_description UNION ALL
  SELECT 'cost_per_purchase' AS field_name, 'Metric' AS field_type, 'Cost per purchase event.' AS field_description UNION ALL
  SELECT 'country' AS field_name, 'Dimension' AS field_type, 'The user country based on IP address.' AS field_description UNION ALL
  SELECT 'creative_name' AS field_name, 'Dimension' AS field_type, 'Name of the marketing creative associated with the event.' AS field_description UNION ALL
  SELECT 'creative_slot' AS field_name, 'Dimension' AS field_type, 'The slot or position of the marketing creative.' AS field_description UNION ALL
  SELECT 'cross_domain_id' AS field_name, 'Dimension' AS field_type, 'Identifier for cross-domain tracking (derived from na_id).' AS field_description UNION ALL
  SELECT 'cross_domain_session' AS field_name, 'Dimension' AS field_type, 'Indicates if the session is cross-domain.' AS field_description UNION ALL
  SELECT 'cs_container_id' AS field_name, 'Dimension' AS field_type, 'Client-side GTM container ID.' AS field_description UNION ALL
  SELECT 'cs_hostname' AS field_name, 'Dimension' AS field_type, 'Client-side GTM server hostname.' AS field_description UNION ALL
  SELECT 'cs_tag_id' AS field_name, 'Dimension' AS field_type, 'Client-side GTM tag ID.' AS field_description UNION ALL
  SELECT 'cs_tag_name' AS field_name, 'Dimension' AS field_type, 'Client-side GTM tag name.' AS field_description UNION ALL
  SELECT 'custom_channel_grouping' AS field_name, 'Dimension' AS field_type, 'Custom traffic source channel grouping for the event calculated on the fly.' AS field_description UNION ALL
  SELECT 'customer_client_id' AS field_name, 'Dimension' AS field_type, 'Client ID of customers.' AS field_description UNION ALL
  SELECT 'customer_status' AS field_name, 'Dimension' AS field_type, 'Status of the customer.' AS field_description UNION ALL
  SELECT 'customer_type' AS field_name, 'Dimension' AS field_type, 'Classification of the customer based on purchase history.' AS field_description UNION ALL
  SELECT 'datalayer' AS field_name, 'Dimension' AS field_type, 'Current JSON value of the dataLayer.' AS field_description UNION ALL
  SELECT 'datalayer_key' AS field_name, 'Dimension' AS field_type, 'Key in dataLayer object.' AS field_description UNION ALL
  SELECT 'date' AS field_name, 'Dimension' AS field_type, 'The date of the funnel step.' AS field_description UNION ALL
  SELECT 'days_before_conversion' AS field_name, 'Metric' AS field_type, 'Days elapsed before conversion.' AS field_description UNION ALL
  SELECT 'days_from_first_purchase' AS field_name, 'Metric' AS field_type, 'Number of days since the user first purchase event.' AS field_description UNION ALL
  SELECT 'days_from_first_to_last_visit' AS field_name, 'Metric' AS field_type, 'Days between the user first and last visit.' AS field_description UNION ALL
  SELECT 'days_from_first_visit' AS field_name, 'Metric' AS field_type, 'Days since the user first visit.' AS field_description UNION ALL
  SELECT 'days_from_last_purchase' AS field_name, 'Metric' AS field_type, 'Number of days since the user most recent purchase.' AS field_description UNION ALL
  SELECT 'days_from_last_visit' AS field_name, 'Metric' AS field_type, 'Days since the user last visit.' AS field_description UNION ALL
  SELECT 'def_ad_personalization' AS field_name, 'Dimension' AS field_type, 'Default ad personalization consent.' AS field_description UNION ALL
  SELECT 'def_ad_storage' AS field_name, 'Dimension' AS field_type, 'Default ad storage consent.' AS field_description UNION ALL
  SELECT 'def_ad_user_data' AS field_name, 'Dimension' AS field_type, 'Default ad user data consent.' AS field_description UNION ALL
  SELECT 'def_analytics_storage' AS field_name, 'Dimension' AS field_type, 'Default analytics storage consent.' AS field_description UNION ALL
  SELECT 'def_functionality_storage' AS field_name, 'Dimension' AS field_type, 'Default functionality storage consent.' AS field_description UNION ALL
  SELECT 'def_personalization_storage' AS field_name, 'Dimension' AS field_type, 'Default personalization storage consent.' AS field_description UNION ALL
  SELECT 'def_security_storage' AS field_name, 'Dimension' AS field_type, 'Default security storage consent.' AS field_description UNION ALL
  SELECT 'delay_in_millis' AS field_name, 'Metric' AS field_type, 'Delay between event occurrence and processing in milliseconds.' AS field_description UNION ALL
  SELECT 'delay_in_sec' AS field_name, 'Metric' AS field_type, 'Delay between event occurrence and processing in seconds.' AS field_description UNION ALL
  SELECT 'device_category' AS field_name, 'Dimension' AS field_type, 'Device category (desktop, mobile, tablet).' AS field_description UNION ALL
  SELECT 'device_language' AS field_name, 'Dimension' AS field_type, 'Device language setting.' AS field_description UNION ALL
  SELECT 'device_model' AS field_name, 'Dimension' AS field_type, 'The model of the user device.' AS field_description UNION ALL
  SELECT 'device_os' AS field_name, 'Dimension' AS field_type, 'Operating system of device.' AS field_description UNION ALL
  SELECT 'device_os_version' AS field_name, 'Dimension' AS field_type, 'OS version of device.' AS field_description UNION ALL
  SELECT 'device_type' AS field_name, 'Dimension' AS field_type, 'The type of device (e.g., Mobile, Desktop).' AS field_description UNION ALL
  SELECT 'device_vendor' AS field_name, 'Dimension' AS field_type, 'The manufacturer of the device.' AS field_description UNION ALL
  SELECT 'duplicate_purchase' AS field_name, 'Metric' AS field_type, 'Count of duplicate purchases.' AS field_description UNION ALL
  SELECT 'duplicate_refund' AS field_name, 'Metric' AS field_type, 'Count of duplicate refunds.' AS field_description UNION ALL
  SELECT 'ecommerce' AS field_name, 'Dimension' AS field_type, 'Structured ecommerce data in JSON format.' AS field_description UNION ALL
  SELECT 'ecommerce_key' AS field_name, 'Dimension' AS field_type, 'Key in ecommerce object.' AS field_description UNION ALL
  SELECT 'engaged_session' AS field_name, 'Metric' AS field_type, 'Total number of sessions categorized as engaged.' AS field_description UNION ALL
  SELECT 'engaged_sessions_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of total sessions that were engaged.' AS field_description UNION ALL
  SELECT 'event_data' AS field_name, 'Dimension' AS field_type, 'Array of custom event parameters.' AS field_description UNION ALL
  SELECT 'event_date' AS field_name, 'Dimension' AS field_type, 'The date the event occurred.' AS field_description UNION ALL
  SELECT 'event_datetime' AS field_name, 'Dimension' AS field_type, 'Date and time of event.' AS field_description UNION ALL
  SELECT 'event_id' AS field_name, 'Dimension' AS field_type, 'Unique identifier for the event.' AS field_description UNION ALL
  SELECT 'event_name' AS field_name, 'Dimension' AS field_type, 'The name of the interaction event.' AS field_description UNION ALL
  SELECT 'event_number' AS field_name, 'Metric' AS field_type, 'Sequential number of the event in the session.' AS field_description UNION ALL
  SELECT 'event_origin' AS field_name, 'Dimension' AS field_type, 'The origin of the event (e.g., Web, Server).' AS field_description UNION ALL
  SELECT 'event_timestamp' AS field_name, 'Metric' AS field_type, 'Unix timestamp (ms) of the event.' AS field_description UNION ALL
  SELECT 'event_type' AS field_name, 'Dimension' AS field_type, 'Category or type of the event.' AS field_description UNION ALL
  SELECT 'events_count' AS field_name, 'Metric' AS field_type, 'Total count of logged events.' AS field_description UNION ALL
  SELECT 'f_max' AS field_name, 'Metric' AS field_type, 'Max frequency score.' AS field_description UNION ALL
  SELECT 'f_rank' AS field_name, 'Metric' AS field_type, 'Rank of frequency score.' AS field_description UNION ALL
  SELECT 'first_click_campaign' AS field_name, 'Dimension' AS field_type, 'First click campaign.' AS field_description UNION ALL
  SELECT 'first_click_campaign_click_id' AS field_name, 'Dimension' AS field_type, 'First click campaign click ID.' AS field_description UNION ALL
  SELECT 'first_click_campaign_content' AS field_name, 'Dimension' AS field_type, 'First click campaign content.' AS field_description UNION ALL
  SELECT 'first_click_campaign_country' AS field_name, 'Dimension' AS field_type, 'First click campaign country.' AS field_description UNION ALL
  SELECT 'first_click_campaign_funnel_stage' AS field_name, 'Dimension' AS field_type, 'First click campaign funnel stage.' AS field_description UNION ALL
  SELECT 'first_click_campaign_id' AS field_name, 'Dimension' AS field_type, 'First click campaign ID.' AS field_description UNION ALL
  SELECT 'first_click_campaign_marketing_objective' AS field_name, 'Dimension' AS field_type, 'First click marketing objective.' AS field_description UNION ALL
  SELECT 'first_click_campaign_name' AS field_name, 'Dimension' AS field_type, 'First click campaign name.' AS field_description UNION ALL
  SELECT 'first_click_campaign_platform' AS field_name, 'Dimension' AS field_type, 'First click campaign platform.' AS field_description UNION ALL
  SELECT 'first_click_campaign_term' AS field_name, 'Dimension' AS field_type, 'First click campaign term.' AS field_description UNION ALL
  SELECT 'first_click_campaign_type' AS field_name, 'Dimension' AS field_type, 'First click campaign type.' AS field_description UNION ALL
  SELECT 'first_click_campaign_year' AS field_name, 'Dimension' AS field_type, 'First click campaign year.' AS field_description UNION ALL
  SELECT 'first_click_channel_grouping' AS field_name, 'Dimension' AS field_type, 'First click channel grouping.' AS field_description UNION ALL
  SELECT 'first_click_custom_channel_grouping' AS field_name, 'Dimension' AS field_type, 'First click custom channel grouping.' AS field_description UNION ALL
  SELECT 'first_click_source' AS field_name, 'Dimension' AS field_type, 'First click traffic source.' AS field_description UNION ALL
  SELECT 'first_purchase_date' AS field_name, 'Dimension' AS field_type, 'Date of first purchase.' AS field_description UNION ALL
  SELECT 'first_purchase_timestamp' AS field_name, 'Dimension' AS field_type, 'Timestamp of the user very first purchase.' AS field_description UNION ALL
  SELECT 'first_visit_date' AS field_name, 'Dimension' AS field_type, 'Date of first visit.' AS field_description UNION ALL
  SELECT 'form_submission' AS field_name, 'Metric' AS field_type, 'Total count of form submission events.' AS field_description UNION ALL
  SELECT 'full_campaign_name' AS field_name, 'Dimension' AS field_type, 'Full string of campaign name.' AS field_description UNION ALL
  SELECT 'functionality_storage' AS field_name, 'Dimension' AS field_type, 'Consent state for necessary functional storage.' AS field_description UNION ALL
  SELECT 'functionality_storage_accepted_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions where functionality storage was accepted.' AS field_description UNION ALL
  SELECT 'functionality_storage_denied_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions where functionality storage was denied.' AS field_description UNION ALL
  SELECT 'has_update' AS field_name, 'Dimension' AS field_type, 'Has update flag.' AS field_description UNION ALL
  SELECT 'hour_and_minute' AS field_name, 'Dimension' AS field_type, 'Hour and minute of the event.' AS field_description UNION ALL
  SELECT 'impression' AS field_name, 'Metric' AS field_type, 'Total impression count.' AS field_description UNION ALL
  SELECT 'item_affiliation' AS field_name, 'Dimension' AS field_type, 'The store or branch where the transaction occurred.' AS field_description UNION ALL
  SELECT 'item_brand' AS field_name, 'Dimension' AS field_type, 'The brand associated with the item in the transaction.' AS field_description UNION ALL
  SELECT 'item_category' AS field_name, 'Dimension' AS field_type, 'The primary category of the item.' AS field_description UNION ALL
  SELECT 'item_category2' AS field_name, 'Dimension' AS field_type, 'Secondary category of item.' AS field_description UNION ALL
  SELECT 'item_category3' AS field_name, 'Dimension' AS field_type, 'Tertiary category of item.' AS field_description UNION ALL
  SELECT 'item_category_2' AS field_name, 'Dimension' AS field_type, 'The second level category of the item.' AS field_description UNION ALL
  SELECT 'item_category_3' AS field_name, 'Dimension' AS field_type, 'The third level category of the item.' AS field_description UNION ALL
  SELECT 'item_category_4' AS field_name, 'Dimension' AS field_type, 'The fourth level category of the item.' AS field_description UNION ALL
  SELECT 'item_category_5' AS field_name, 'Dimension' AS field_type, 'The fifth level category of the item.' AS field_description UNION ALL
  SELECT 'item_coupon' AS field_name, 'Dimension' AS field_type, 'Coupon code specifically applied to an individual item.' AS field_description UNION ALL
  SELECT 'item_data' AS field_name, 'Dimension' AS field_type, 'Custom item parameters.' AS field_description UNION ALL
  SELECT 'item_discount' AS field_name, 'Metric' AS field_type, 'The monetary discount applied to the item.' AS field_description UNION ALL
  SELECT 'item_id' AS field_name, 'Dimension' AS field_type, 'Unique identifier (SKU) for the product item.' AS field_description UNION ALL
  SELECT 'item_json' AS field_name, 'Dimension' AS field_type, 'JSON item structure.' AS field_description UNION ALL
  SELECT 'item_key' AS field_name, 'Dimension' AS field_type, 'Key in item parameters.' AS field_description UNION ALL
  SELECT 'item_list_id' AS field_name, 'Dimension' AS field_type, 'ID of the list in which the item was presented.' AS field_description UNION ALL
  SELECT 'item_list_name' AS field_name, 'Dimension' AS field_type, 'Name of the list in which the item was presented.' AS field_description UNION ALL
  SELECT 'item_name' AS field_name, 'Dimension' AS field_type, 'Legal or commercial name of the product item.' AS field_description UNION ALL
  SELECT 'item_number' AS field_name, 'Metric' AS field_type, 'Index number of item.' AS field_description UNION ALL
  SELECT 'item_offset' AS field_name, 'Metric' AS field_type, 'Offset position of item.' AS field_description UNION ALL
  SELECT 'item_price' AS field_name, 'Metric' AS field_type, 'Unit price of item.' AS field_description UNION ALL
  SELECT 'item_quantity_added_to_cart' AS field_name, 'Metric' AS field_type, 'Total quantity of this item added to the cart.' AS field_description UNION ALL
  SELECT 'item_quantity_added_to_wishlist' AS field_name, 'Metric' AS field_type, 'Total quantity of this item added to wishlist.' AS field_description UNION ALL
  SELECT 'item_quantity_purchased' AS field_name, 'Metric' AS field_type, 'Total quantity of items purchased by the user.' AS field_description UNION ALL
  SELECT 'item_quantity_refunded' AS field_name, 'Metric' AS field_type, 'Total quantity of items refunded by the user.' AS field_description UNION ALL
  SELECT 'item_quantity_removed_from_cart' AS field_name, 'Metric' AS field_type, 'Total quantity of this item removed from the cart.' AS field_description UNION ALL
  SELECT 'item_quantity_removed_from_wishlist' AS field_name, 'Metric' AS field_type, 'Total quantity of this item removed from wishlist.' AS field_description UNION ALL
  SELECT 'item_revenue_purchased' AS field_name, 'Metric' AS field_type, 'Gross revenue generated by the sale of this item.' AS field_description UNION ALL
  SELECT 'item_revenue_refunded' AS field_name, 'Metric' AS field_type, 'Total value refunded for this specific item.' AS field_description UNION ALL
  SELECT 'item_variant' AS field_name, 'Dimension' AS field_type, 'Specific variant of the item (e.g., size or color).' AS field_description UNION ALL
  SELECT 'items' AS field_name, 'Dimension' AS field_type, 'Array of items.' AS field_description UNION ALL
  SELECT 'items_add_to_cart_quantity' AS field_name, 'Metric' AS field_type, 'Total items quantity added to cart.' AS field_description UNION ALL
  SELECT 'items_purchased_quantity' AS field_name, 'Metric' AS field_type, 'Total items quantity purchased.' AS field_description UNION ALL
  SELECT 'items_viewed_quantity' AS field_name, 'Metric' AS field_type, 'Total items quantity viewed.' AS field_description UNION ALL
  SELECT 'json' AS field_name, 'Dimension' AS field_type, 'Raw JSON payload.' AS field_description UNION ALL
  SELECT 'last_click_campaign' AS field_name, 'Dimension' AS field_type, 'Last click campaign.' AS field_description UNION ALL
  SELECT 'last_click_campaign_click_id' AS field_name, 'Dimension' AS field_type, 'Last click campaign click ID.' AS field_description UNION ALL
  SELECT 'last_click_campaign_content' AS field_name, 'Dimension' AS field_type, 'Last click campaign content.' AS field_description UNION ALL
  SELECT 'last_click_campaign_country' AS field_name, 'Dimension' AS field_type, 'Last click campaign country.' AS field_description UNION ALL
  SELECT 'last_click_campaign_funnel_stage' AS field_name, 'Dimension' AS field_type, 'Last click campaign funnel stage.' AS field_description UNION ALL
  SELECT 'last_click_campaign_id' AS field_name, 'Dimension' AS field_type, 'Last click campaign ID.' AS field_description UNION ALL
  SELECT 'last_click_campaign_marketing_objective' AS field_name, 'Dimension' AS field_type, 'Last click marketing objective.' AS field_description UNION ALL
  SELECT 'last_click_campaign_name' AS field_name, 'Dimension' AS field_type, 'Last click campaign name.' AS field_description UNION ALL
  SELECT 'last_click_campaign_platform' AS field_name, 'Dimension' AS field_type, 'Last click campaign platform.' AS field_description UNION ALL
  SELECT 'last_click_campaign_term' AS field_name, 'Dimension' AS field_type, 'Last click campaign term.' AS field_description UNION ALL
  SELECT 'last_click_campaign_type' AS field_name, 'Dimension' AS field_type, 'Last click campaign type.' AS field_description UNION ALL
  SELECT 'last_click_campaign_year' AS field_name, 'Dimension' AS field_type, 'Last click campaign year.' AS field_description UNION ALL
  SELECT 'last_click_channel_grouping' AS field_name, 'Dimension' AS field_type, 'Last click channel grouping.' AS field_description UNION ALL
  SELECT 'last_click_custom_channel_grouping' AS field_name, 'Dimension' AS field_type, 'Last click custom channel grouping.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_campaign' AS field_name, 'Dimension' AS field_type, 'Last click non direct campaign.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_campaign_click_id' AS field_name, 'Dimension' AS field_type, 'Last click non direct campaign click ID.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_campaign_content' AS field_name, 'Dimension' AS field_type, 'Last click non direct campaign content.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_campaign_country' AS field_name, 'Dimension' AS field_type, 'Last click non direct campaign country.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_campaign_funnel_stage' AS field_name, 'Dimension' AS field_type, 'Last click non direct campaign funnel stage.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_campaign_id' AS field_name, 'Dimension' AS field_type, 'Last click non direct campaign ID.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_campaign_marketing_objective' AS field_name, 'Dimension' AS field_type, 'Last click non direct marketing objective.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_campaign_name' AS field_name, 'Dimension' AS field_type, 'Last click non direct campaign name.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_campaign_platform' AS field_name, 'Dimension' AS field_type, 'Last click non direct campaign platform.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_campaign_term' AS field_name, 'Dimension' AS field_type, 'Last click non direct campaign term.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_campaign_type' AS field_name, 'Dimension' AS field_type, 'Last click non direct campaign type.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_campaign_year' AS field_name, 'Dimension' AS field_type, 'Last click non direct campaign year.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_channel_grouping' AS field_name, 'Dimension' AS field_type, 'Last click non direct channel grouping.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_custom_channel_grouping' AS field_name, 'Dimension' AS field_type, 'Last click non direct custom channel grouping.' AS field_description UNION ALL
  SELECT 'last_click_non_direct_source' AS field_name, 'Dimension' AS field_type, 'Last click non direct traffic source.' AS field_description UNION ALL
  SELECT 'last_click_source' AS field_name, 'Dimension' AS field_type, 'Last click traffic source.' AS field_description UNION ALL
  SELECT 'last_purchase_date' AS field_name, 'Dimension' AS field_type, 'Date of last purchase.' AS field_description UNION ALL
  SELECT 'last_purchase_timestamp' AS field_name, 'Dimension' AS field_type, 'Timestamp of the user most recent purchase.' AS field_description UNION ALL
  SELECT 'last_visit_date' AS field_name, 'Dimension' AS field_type, 'Date of last visit.' AS field_description UNION ALL
  SELECT 'lead_type' AS field_name, 'Dimension' AS field_type, 'Type classification of lead.' AS field_description UNION ALL
  SELECT 'linear_attributed_revenue' AS field_name, 'Metric' AS field_type, 'Attributed revenue using linear model.' AS field_description UNION ALL
  SELECT 'linear_attribution_credit' AS field_name, 'Metric' AS field_type, 'Credit score using linear attribution.' AS field_description UNION ALL
  SELECT 'linear_weight' AS field_name, 'Metric' AS field_type, 'Linear weight factor.' AS field_description UNION ALL
  SELECT 'list_id' AS field_name, 'Dimension' AS field_type, 'The ID of the product list.' AS field_description UNION ALL
  SELECT 'list_name' AS field_name, 'Dimension' AS field_type, 'The name of the product list.' AS field_description UNION ALL
  SELECT 'm_max' AS field_name, 'Metric' AS field_type, 'Max monetary score.' AS field_description UNION ALL
  SELECT 'm_rank' AS field_name, 'Metric' AS field_type, 'Rank of monetary score.' AS field_description UNION ALL
  SELECT 'month' AS field_name, 'Dimension' AS field_type, 'Month of activity.' AS field_description UNION ALL
  SELECT 'name' AS field_name, 'Dimension' AS field_type, 'Name attribute.' AS field_description UNION ALL
  SELECT 'new_customer_client_id' AS field_name, 'Dimension' AS field_type, 'Client ID of new customers.' AS field_description UNION ALL
  SELECT 'new_session' AS field_name, 'Metric' AS field_type, 'Indicates if this is a new session (1 for yes, 0 for no).' AS field_description UNION ALL
  SELECT 'new_sessions_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions that were new.' AS field_description UNION ALL
  SELECT 'new_user_client_id' AS field_name, 'Dimension' AS field_type, 'Client ID if this is the user first session, else null.' AS field_description UNION ALL
  SELECT 'new_users' AS field_name, 'Metric' AS field_type, 'Count of new users.' AS field_description UNION ALL
  SELECT 'newsletter_subscription' AS field_name, 'Metric' AS field_type, 'Total count of newsletter subscription events.' AS field_description UNION ALL
  SELECT 'next_step_client_id' AS field_name, 'Dimension' AS field_type, 'The client ID for the next step in the sequence (for drop-off analysis).' AS field_description UNION ALL
  SELECT 'os_name' AS field_name, 'Dimension' AS field_type, 'The name of the operating system.' AS field_description UNION ALL
  SELECT 'os_version' AS field_name, 'Dimension' AS field_type, 'The version of the operating system.' AS field_description UNION ALL
  SELECT 'page_category' AS field_name, 'Dimension' AS field_type, 'Logical category of the page.' AS field_description UNION ALL
  SELECT 'page_data' AS field_name, 'Dimension' AS field_type, 'Array of custom page parameters.' AS field_description UNION ALL
  SELECT 'page_date' AS field_name, 'Dimension' AS field_type, 'The date the page was viewed.' AS field_description UNION ALL
  SELECT 'page_extension' AS field_name, 'Dimension' AS field_type, 'The file extension of the page.' AS field_description UNION ALL
  SELECT 'page_fragment' AS field_name, 'Dimension' AS field_type, 'The URL fragment (part after #).' AS field_description UNION ALL
  SELECT 'page_hostname' AS field_name, 'Dimension' AS field_type, 'The hostname of the page viewed.' AS field_description UNION ALL
  SELECT 'page_hostname_protocol' AS field_name, 'Dimension' AS field_type, 'The protocol of the URL (e.g., https).' AS field_description UNION ALL
  SELECT 'page_id' AS field_name, 'Dimension' AS field_type, 'Unique identifier for the page view.' AS field_description UNION ALL
  SELECT 'page_language' AS field_name, 'Dimension' AS field_type, 'The language set for the page.' AS field_description UNION ALL
  SELECT 'page_load_time_sec' AS field_name, 'Metric' AS field_type, 'Time taken to load the page in seconds.' AS field_description UNION ALL
  SELECT 'page_load_timestamp' AS field_name, 'Dimension' AS field_type, 'Timestamp when the page started loading.' AS field_description UNION ALL
  SELECT 'page_path' AS field_name, 'Dimension' AS field_type, 'The path of the page.' AS field_description UNION ALL
  SELECT 'page_query' AS field_name, 'Dimension' AS field_type, 'The URL query string.' AS field_description UNION ALL
  SELECT 'page_referrer' AS field_name, 'Dimension' AS field_type, 'The URL of the referring page.' AS field_description UNION ALL
  SELECT 'page_status_code' AS field_name, 'Dimension' AS field_type, 'HTTP status code of the page.' AS field_description UNION ALL
  SELECT 'page_title' AS field_name, 'Dimension' AS field_type, 'The title (document title) of the page.' AS field_description UNION ALL
  SELECT 'page_unload_timestamp' AS field_name, 'Dimension' AS field_type, 'Timestamp when the page was closed.' AS field_description UNION ALL
  SELECT 'page_url' AS field_name, 'Dimension' AS field_type, 'The URL of the page.' AS field_description UNION ALL
  SELECT 'page_view' AS field_name, 'Metric' AS field_type, 'Total count of page view events.' AS field_description UNION ALL
  SELECT 'page_view_number' AS field_name, 'Metric' AS field_type, 'Sequential number of the page view in the session.' AS field_description UNION ALL
  SELECT 'page_view_per_session' AS field_name, 'Metric' AS field_type, 'Average number of page views per session.' AS field_description UNION ALL
  SELECT 'parameter_name' AS field_name, 'Dimension' AS field_type, 'Name of parameter.' AS field_description UNION ALL
  SELECT 'personalization_storage' AS field_name, 'Dimension' AS field_type, 'Consent state for personalization storage.' AS field_description UNION ALL
  SELECT 'personalization_storage_accepted_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions where personalization storage was accepted.' AS field_description UNION ALL
  SELECT 'personalization_storage_denied_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions where personalization storage was denied.' AS field_description UNION ALL
  SELECT 'position_based_attributed_revenue' AS field_name, 'Metric' AS field_type, 'Attributed revenue using position based model.' AS field_description UNION ALL
  SELECT 'position_based_attribution_credit' AS field_name, 'Metric' AS field_type, 'Credit score using position based attribution.' AS field_description UNION ALL
  SELECT 'position_based_weight' AS field_name, 'Metric' AS field_type, 'Position based weight factor.' AS field_description UNION ALL
  SELECT 'processing_event_timestamp' AS field_name, 'Dimension' AS field_type, 'Timestamp when the event was processed by the server.' AS field_description UNION ALL
  SELECT 'product_add_to_cart' AS field_name, 'Metric' AS field_type, 'Total add to cart events for the product.' AS field_description UNION ALL
  SELECT 'product_detail_views' AS field_name, 'Metric' AS field_type, 'Total detail view events for the product.' AS field_description UNION ALL
  SELECT 'product_list_clicks' AS field_name, 'Metric' AS field_type, 'Total list click events for the product.' AS field_description UNION ALL
  SELECT 'product_list_views' AS field_name, 'Metric' AS field_type, 'Total list view events for the product.' AS field_description UNION ALL
  SELECT 'product_purchases' AS field_name, 'Metric' AS field_type, 'Total purchase events for the product.' AS field_description UNION ALL
  SELECT 'product_quantity_purchased' AS field_name, 'Metric' AS field_type, 'Total units purchased for the product.' AS field_description UNION ALL
  SELECT 'product_revenue' AS field_name, 'Metric' AS field_type, 'Total monetary revenue generated by the product.' AS field_description UNION ALL
  SELECT 'promotion_id' AS field_name, 'Dimension' AS field_type, 'The unique ID of the promotion applied.' AS field_description UNION ALL
  SELECT 'promotion_name' AS field_name, 'Dimension' AS field_type, 'The commercial name of the promotion applied.' AS field_description UNION ALL
  SELECT 'purchase' AS field_name, 'Metric' AS field_type, 'Total count of purchase events for the user.' AS field_description UNION ALL
  SELECT 'purchase_coupon' AS field_name, 'Dimension' AS field_type, 'Coupon code applied to the purchase.' AS field_description UNION ALL
  SELECT 'purchase_currency' AS field_name, 'Dimension' AS field_type, 'Currency used for the purchase.' AS field_description UNION ALL
  SELECT 'purchase_id' AS field_name, 'Dimension' AS field_type, 'The unique ID of the purchase transaction.' AS field_description UNION ALL
  SELECT 'purchase_net_refund' AS field_name, 'Metric' AS field_type, 'Net number of purchases after accounting for refunds.' AS field_description UNION ALL
  SELECT 'purchase_qty' AS field_name, 'Metric' AS field_type, 'Total purchase quantity.' AS field_description UNION ALL
  SELECT 'purchase_revenue' AS field_name, 'Metric' AS field_type, 'Total revenue generated from user purchases.' AS field_description UNION ALL
  SELECT 'purchase_shipping' AS field_name, 'Metric' AS field_type, 'Total shipping charges for purchases in the session.' AS field_description UNION ALL
  SELECT 'purchase_tax' AS field_name, 'Metric' AS field_type, 'Total tax charges for purchases in the session.' AS field_description UNION ALL
  SELECT 'quantity' AS field_name, 'Metric' AS field_type, 'Quantity of items associated with the transaction.' AS field_description UNION ALL
  SELECT 'r_max' AS field_name, 'Metric' AS field_type, 'Max recency score.' AS field_description UNION ALL
  SELECT 'r_rank' AS field_name, 'Metric' AS field_type, 'Rank of recency score.' AS field_description UNION ALL
  SELECT 'reached_step' AS field_name, 'Metric' AS field_type, 'Boolean indicating if the user reached this step.' AS field_description UNION ALL
  SELECT 'refund' AS field_name, 'Metric' AS field_type, 'Total count of refund events for the user.' AS field_description UNION ALL
  SELECT 'refund_coupon' AS field_name, 'Dimension' AS field_type, 'Coupon code applied to the refund.' AS field_description UNION ALL
  SELECT 'refund_currency' AS field_name, 'Dimension' AS field_type, 'Currency used for the refund.' AS field_description UNION ALL
  SELECT 'refund_id' AS field_name, 'Dimension' AS field_type, 'The unique ID of the refund transaction.' AS field_description UNION ALL
  SELECT 'refund_qty' AS field_name, 'Metric' AS field_type, 'Total refund quantity.' AS field_description UNION ALL
  SELECT 'refund_revenue' AS field_name, 'Metric' AS field_type, 'Total value of refunds associated with the user.' AS field_description UNION ALL
  SELECT 'refund_shipping' AS field_name, 'Metric' AS field_type, 'Total shipping value of items refunded in the session.' AS field_description UNION ALL
  SELECT 'refund_tax' AS field_name, 'Metric' AS field_type, 'Total tax value of items refunded in the session.' AS field_description UNION ALL
  SELECT 'refund_value' AS field_name, 'Metric' AS field_type, 'Total monetary amount refunded.' AS field_description UNION ALL
  SELECT 'remove_from_cart' AS field_name, 'Metric' AS field_type, 'Total number of sessions with at least one remove_from_cart event.' AS field_description UNION ALL
  SELECT 'remove_from_wishlist' AS field_name, 'Metric' AS field_type, 'Total number of sessions with at least one remove_from_wishlist event.' AS field_description UNION ALL
  SELECT 'respect_consent_mode' AS field_name, 'Dimension' AS field_type, 'Indicates if the system respected Consent Mode settings.' AS field_description UNION ALL
  SELECT 'returning_customer_client_id' AS field_name, 'Dimension' AS field_type, 'Client ID of returning customers.' AS field_description UNION ALL
  SELECT 'returning_session' AS field_name, 'Metric' AS field_type, 'Indicates if this is a returning session (1 for yes, 0 for no).' AS field_description UNION ALL
  SELECT 'returning_sessions_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of total sessions that were returning.' AS field_description UNION ALL
  SELECT 'returning_user_client_id' AS field_name, 'Dimension' AS field_type, 'Client ID if this is not the user first session, else null.' AS field_description UNION ALL
  SELECT 'revenue_net_refund' AS field_name, 'Metric' AS field_type, 'Total revenue minus the total value of refunds.' AS field_description UNION ALL
  SELECT 'rfm_segment' AS field_name, 'Dimension' AS field_type, 'RFM (Recency, Frequency, Monetary) segment classification.' AS field_description UNION ALL
  SELECT 'roas' AS field_name, 'Metric' AS field_type, 'Return on ad spend.' AS field_description UNION ALL
  SELECT 'roas_net_refund' AS field_name, 'Metric' AS field_type, 'Return on ad spend accounting for refunds.' AS field_description UNION ALL
  SELECT 'screen_size' AS field_name, 'Dimension' AS field_type, 'Physical resolution of the user screen.' AS field_description UNION ALL
  SELECT 'search_term' AS field_name, 'Dimension' AS field_type, 'The term searched by the user (for search events).' AS field_description UNION ALL
  SELECT 'security_storage' AS field_name, 'Dimension' AS field_type, 'Consent state for security-related storage.' AS field_description UNION ALL
  SELECT 'security_storage_accepted_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions where security storage was accepted.' AS field_description UNION ALL
  SELECT 'security_storage_denied_percentage' AS field_name, 'Metric' AS field_type, 'Percentage of sessions where security storage was denied.' AS field_description UNION ALL
  SELECT 'select_item' AS field_name, 'Metric' AS field_type, 'Total number of sessions where an item was selected.' AS field_description UNION ALL
  SELECT 'select_promotion' AS field_name, 'Metric' AS field_type, 'Total number of sessions where a promotion was selected.' AS field_description UNION ALL
  SELECT 'session_ad_personalization' AS field_name, 'Metric' AS field_type, 'Count of sessions with ad personalization consent.' AS field_description UNION ALL
  SELECT 'session_ad_storage' AS field_name, 'Metric' AS field_type, 'Count of sessions with ad storage consent.' AS field_description UNION ALL
  SELECT 'session_ad_user_data' AS field_name, 'Metric' AS field_type, 'Count of sessions with ad user data consent.' AS field_description UNION ALL
  SELECT 'session_analytics_storage' AS field_name, 'Metric' AS field_type, 'Count of sessions with analytics storage consent.' AS field_description UNION ALL
  SELECT 'session_campaign_click_id' AS field_name, 'Dimension' AS field_type, 'The campaign click ID associated with the session.' AS field_description UNION ALL
  SELECT 'session_campaign_content' AS field_name, 'Dimension' AS field_type, 'The ad content or creative attributed to the session.' AS field_description UNION ALL
  SELECT 'session_campaign_id' AS field_name, 'Dimension' AS field_type, 'The campaign ID attributed to the session.' AS field_description UNION ALL
  SELECT 'session_campaign_marketing_objective' AS field_name, 'Dimension' AS field_type, 'Marketing objective of the campaign attributed to the session.' AS field_description UNION ALL
  SELECT 'session_campaign_medium' AS field_name, 'Dimension' AS field_type, 'The medium (e.g., cpc, organic) attributed to the session.' AS field_description UNION ALL
  SELECT 'session_campaign_name' AS field_name, 'Dimension' AS field_type, 'The campaign name attributed to the session.' AS field_description UNION ALL
  SELECT 'session_campaign_source' AS field_name, 'Dimension' AS field_type, 'The traffic source (e.g., google, newsletter) attributed to the session.' AS field_description UNION ALL
  SELECT 'session_campaign_term' AS field_name, 'Dimension' AS field_type, 'The term (paid keyword) attributed to the session.' AS field_description UNION ALL
  SELECT 'session_channel_grouping' AS field_name, 'Dimension' AS field_type, 'Default channel grouping assigned to the session.' AS field_description UNION ALL
  SELECT 'session_city' AS field_name, 'Dimension' AS field_type, 'Geographic city derived from the session IP address.' AS field_description UNION ALL
  SELECT 'session_country' AS field_name, 'Dimension' AS field_type, 'Geographic country derived from the session IP address.' AS field_description UNION ALL
  SELECT 'session_custom_channel_grouping' AS field_name, 'Dimension' AS field_type, 'Custom channel grouping attributed to the session.' AS field_description UNION ALL
  SELECT 'session_date' AS field_name, 'Dimension' AS field_type, 'The date when the session occurred (YYYYMMDD).' AS field_description UNION ALL
  SELECT 'session_device_category' AS field_name, 'Dimension' AS field_type, 'Device category (desktop, mobile, tablet) used in the session.' AS field_description UNION ALL
  SELECT 'session_device_model' AS field_name, 'Dimension' AS field_type, 'Specific device model used in the session.' AS field_description UNION ALL
  SELECT 'session_device_os' AS field_name, 'Dimension' AS field_type, 'Operating system of the device used in the session.' AS field_description UNION ALL
  SELECT 'session_device_os_version' AS field_name, 'Dimension' AS field_type, 'Version of the operating system used in the session.' AS field_description UNION ALL
  SELECT 'session_device_type' AS field_name, 'Dimension' AS field_type, 'Device type (e.g., Mobile, Desktop) used in the session.' AS field_description UNION ALL
  SELECT 'session_device_vendor' AS field_name, 'Dimension' AS field_type, 'Device manufacturer associated with the session.' AS field_description UNION ALL
  SELECT 'session_duration_sec' AS field_name, 'Metric' AS field_type, 'Total duration of the session in seconds.' AS field_description UNION ALL
  SELECT 'session_end_timestamp' AS field_name, 'Dimension' AS field_type, 'Epoch timestamp (ms) when the session ended.' AS field_description UNION ALL
  SELECT 'session_event_origin' AS field_name, 'Dimension' AS field_type, 'Primary origin (Web vs Server) of events in the session.' AS field_description UNION ALL
  SELECT 'session_events_count' AS field_name, 'Metric' AS field_type, 'Total count of events logged during the session.' AS field_description UNION ALL
  SELECT 'session_first_page_category' AS field_name, 'Dimension' AS field_type, 'Category of the landing page of the session.' AS field_description UNION ALL
  SELECT 'session_first_page_hostname' AS field_name, 'Dimension' AS field_type, 'Hostname of the landing page of the session.' AS field_description UNION ALL
  SELECT 'session_first_page_hostname_protocol' AS field_name, 'Dimension' AS field_type, 'Protocol of the landing page URL.' AS field_description UNION ALL
  SELECT 'session_first_page_path' AS field_name, 'Dimension' AS field_type, 'Path of the landing page (first page viewed in session).' AS field_description UNION ALL
  SELECT 'session_first_page_query' AS field_name, 'Dimension' AS field_type, 'Query string of the landing page URL.' AS field_description UNION ALL
  SELECT 'session_first_page_referrer' AS field_name, 'Dimension' AS field_type, 'External referrer URL that initiated the session.' AS field_description UNION ALL
  SELECT 'session_first_page_title' AS field_name, 'Dimension' AS field_type, 'Title of the landing page of the session.' AS field_description UNION ALL
  SELECT 'session_first_page_url' AS field_name, 'Dimension' AS field_type, 'Full URL of the landing page of the session.' AS field_description UNION ALL
  SELECT 'session_functionality_storage' AS field_name, 'Metric' AS field_type, 'Count of sessions with functionality storage consent.' AS field_description UNION ALL
  SELECT 'session_id' AS field_name, 'Dimension' AS field_type, 'Unique identifier for the session.' AS field_description UNION ALL
  SELECT 'session_last_page_category' AS field_name, 'Dimension' AS field_type, 'Category of the exit page of the session.' AS field_description UNION ALL
  SELECT 'session_last_page_hostname' AS field_name, 'Dimension' AS field_type, 'Hostname of the exit page of the session.' AS field_description UNION ALL
  SELECT 'session_last_page_hostname_protocol' AS field_name, 'Dimension' AS field_type, 'Protocol of the exit page URL.' AS field_description UNION ALL
  SELECT 'session_last_page_path' AS field_name, 'Dimension' AS field_type, 'Path of the exit page (last page viewed in session).' AS field_description UNION ALL
  SELECT 'session_last_page_query' AS field_name, 'Dimension' AS field_type, 'Query string of the exit page URL.' AS field_description UNION ALL
  SELECT 'session_last_page_title' AS field_name, 'Dimension' AS field_type, 'Title of the exit page of the session.' AS field_description UNION ALL
  SELECT 'session_last_page_url' AS field_name, 'Dimension' AS field_type, 'Full URL of the exit page of the session.' AS field_description UNION ALL
  SELECT 'session_number' AS field_name, 'Metric' AS field_type, 'Sequential count of sessions for the user.' AS field_description UNION ALL
  SELECT 'session_origin' AS field_name, 'Dimension' AS field_type, 'Origin of the session.' AS field_description UNION ALL
  SELECT 'session_os_name' AS field_name, 'Dimension' AS field_type, 'Name of operating system used in the session.' AS field_description UNION ALL
  SELECT 'session_os_version' AS field_name, 'Dimension' AS field_type, 'Version of operating system used in the session.' AS field_description UNION ALL
  SELECT 'session_page_views' AS field_name, 'Metric' AS field_type, 'Total number of page views within the session.' AS field_description UNION ALL
  SELECT 'session_personalization_storage' AS field_name, 'Metric' AS field_type, 'Count of sessions with personalization storage consent.' AS field_description UNION ALL
  SELECT 'session_screen_size' AS field_name, 'Dimension' AS field_type, 'Screen resolution recorded during the session.' AS field_description UNION ALL
  SELECT 'session_security_storage' AS field_name, 'Metric' AS field_type, 'Count of sessions with security storage consent.' AS field_description UNION ALL
  SELECT 'session_source_cleaned' AS field_name, 'Dimension' AS field_type, 'Cleaned traffic source assigned to the session.' AS field_description UNION ALL
  SELECT 'session_start_timestamp' AS field_name, 'Dimension' AS field_type, 'Epoch timestamp (ms) when the session started.' AS field_description UNION ALL
  SELECT 'session_tld_source' AS field_name, 'Dimension' AS field_type, 'Top Level Domain of the session traffic source.' AS field_description UNION ALL
  SELECT 'session_user_language' AS field_name, 'Dimension' AS field_type, 'Language setting of the user during the session.' AS field_description UNION ALL
  SELECT 'session_with_account_creation' AS field_name, 'Metric' AS field_type, 'Total count of sessions containing an account creation event.' AS field_description UNION ALL
  SELECT 'session_with_add_payment_info' AS field_name, 'Metric' AS field_type, 'Flag/count indicating if payment info was added.' AS field_description UNION ALL
  SELECT 'session_with_add_shipping_info' AS field_name, 'Metric' AS field_type, 'Flag/count indicating if shipping info was added.' AS field_description UNION ALL
  SELECT 'session_with_add_to_cart' AS field_name, 'Metric' AS field_type, 'Flag/count indicating if add_to_cart occurred.' AS field_description UNION ALL
  SELECT 'session_with_add_to_wishlist' AS field_name, 'Metric' AS field_type, 'Flag/count indicating if add_to_wishlist occurred.' AS field_description UNION ALL
  SELECT 'session_with_begin_checkout' AS field_name, 'Metric' AS field_type, 'Flag/count indicating if checkout was started.' AS field_description UNION ALL
  SELECT 'session_with_form_submission' AS field_name, 'Metric' AS field_type, 'Total count of sessions containing a form submission event.' AS field_description UNION ALL
  SELECT 'session_with_newsletter_subscription' AS field_name, 'Metric' AS field_type, 'Total count of sessions containing a newsletter subscription event.' AS field_description UNION ALL
  SELECT 'session_with_purchase' AS field_name, 'Metric' AS field_type, 'Flag or count indicating if the session resulted in a purchase.' AS field_description UNION ALL
  SELECT 'session_with_refund' AS field_name, 'Metric' AS field_type, 'Flag or count indicating if the session resulted in a refund.' AS field_description UNION ALL
  SELECT 'session_with_remove_from_cart' AS field_name, 'Metric' AS field_type, 'Flag/count indicating if items were removed from cart.' AS field_description UNION ALL
  SELECT 'session_with_remove_from_wishlist' AS field_name, 'Metric' AS field_type, 'Flag/count indicating if items were removed from wishlist.' AS field_description UNION ALL
  SELECT 'session_with_select_item' AS field_name, 'Metric' AS field_type, 'Flag/count indicating if an item was selected.' AS field_description UNION ALL
  SELECT 'session_with_select_promotion' AS field_name, 'Metric' AS field_type, 'Flag/count indicating if a promotion was selected.' AS field_description UNION ALL
  SELECT 'session_with_view_cart' AS field_name, 'Metric' AS field_type, 'Flag/count indicating if the cart was viewed.' AS field_description UNION ALL
  SELECT 'session_with_view_item' AS field_name, 'Metric' AS field_type, 'Flag/count indicating if an item detail was viewed.' AS field_description UNION ALL
  SELECT 'session_with_view_item_list' AS field_name, 'Metric' AS field_type, 'Flag/count indicating if an item list was viewed.' AS field_description UNION ALL
  SELECT 'session_with_view_promotion' AS field_name, 'Metric' AS field_type, 'Flag/count indicating if a promotion was viewed.' AS field_description UNION ALL
  SELECT 'sessions_count' AS field_name, 'Metric' AS field_type, 'Total number of sessions.' AS field_description UNION ALL
  SELECT 'sh_container_id' AS field_name, 'Dimension' AS field_type, 'Server-side GTM container ID.' AS field_description UNION ALL
  SELECT 'sh_hostname' AS field_name, 'Dimension' AS field_type, 'Server-side GTM server hostname.' AS field_description UNION ALL
  SELECT 'single_touch_attributed_revenue' AS field_name, 'Metric' AS field_type, 'Attributed revenue using single touch model.' AS field_description UNION ALL
  SELECT 'single_touch_attribution_credit' AS field_name, 'Metric' AS field_type, 'Credit score using single touch attribution.' AS field_description UNION ALL
  SELECT 'single_touch_weight' AS field_name, 'Metric' AS field_type, 'Single touch weight factor.' AS field_description UNION ALL
  SELECT 'time_decay_attributed_revenue' AS field_name, 'Metric' AS field_type, 'Attributed revenue using time decay model.' AS field_description UNION ALL
  SELECT 'time_decay_attribution_credit' AS field_name, 'Metric' AS field_type, 'Credit score using time decay attribution.' AS field_description UNION ALL
  SELECT 'time_decay_weight' AS field_name, 'Metric' AS field_type, 'Time decay weight factor.' AS field_description UNION ALL
  SELECT 'time_on_page' AS field_name, 'Metric' AS field_type, 'Duration spent by the user on the specific page in seconds.' AS field_description UNION ALL
  SELECT 'total_avg_order_value' AS field_name, 'Metric' AS field_type, 'Overall average order value.' AS field_description UNION ALL
  SELECT 'total_conversions' AS field_name, 'Metric' AS field_type, 'Total conversions count.' AS field_description UNION ALL
  SELECT 'total_conversions_revenue' AS field_name, 'Metric' AS field_type, 'Total revenue from conversions.' AS field_description UNION ALL
  SELECT 'total_cost' AS field_name, 'Metric' AS field_type, 'Total advertising cost.' AS field_description UNION ALL
  SELECT 'total_engaged_sessions' AS field_name, 'Metric' AS field_type, 'Total engaged sessions count.' AS field_description UNION ALL
  SELECT 'total_item_discount' AS field_name, 'Metric' AS field_type, 'Total item discounts.' AS field_description UNION ALL
  SELECT 'total_item_quantity_purchased' AS field_name, 'Metric' AS field_type, 'Total item quantity purchased.' AS field_description UNION ALL
  SELECT 'total_item_quantity_refunded' AS field_name, 'Metric' AS field_type, 'Total item quantity refunded.' AS field_description UNION ALL
  SELECT 'total_item_revenue_purchased' AS field_name, 'Metric' AS field_type, 'Total gross item revenue purchased.' AS field_description UNION ALL
  SELECT 'total_item_revenue_refunded' AS field_name, 'Metric' AS field_type, 'Total item revenue refunded.' AS field_description UNION ALL
  SELECT 'total_items_add_to_cart_quantity' AS field_name, 'Metric' AS field_type, 'Total quantity of items added to cart.' AS field_description UNION ALL
  SELECT 'total_items_purchased_quantity' AS field_name, 'Metric' AS field_type, 'Total quantity of items purchased.' AS field_description UNION ALL
  SELECT 'total_items_viewed_quantity' AS field_name, 'Metric' AS field_type, 'Total quantity of items viewed.' AS field_description UNION ALL
  SELECT 'total_new_sessions' AS field_name, 'Metric' AS field_type, 'Total new sessions count.' AS field_description UNION ALL
  SELECT 'total_new_users' AS field_name, 'Metric' AS field_type, 'Total new users count.' AS field_description UNION ALL
  SELECT 'total_page_views' AS field_name, 'Metric' AS field_type, 'Aggregated total count of page views.' AS field_description UNION ALL
  SELECT 'total_product_revenue' AS field_name, 'Metric' AS field_type, 'Total product revenue.' AS field_description UNION ALL
  SELECT 'total_purchase_net_refund' AS field_name, 'Metric' AS field_type, 'Total purchases net of refunds.' AS field_description UNION ALL
  SELECT 'total_purchase_revenue' AS field_name, 'Metric' AS field_type, 'Total purchase revenue.' AS field_description UNION ALL
  SELECT 'total_purchase_shipping' AS field_name, 'Metric' AS field_type, 'Total shipping revenue.' AS field_description UNION ALL
  SELECT 'total_purchase_tax' AS field_name, 'Metric' AS field_type, 'Total tax collected.' AS field_description UNION ALL
  SELECT 'total_purchases' AS field_name, 'Metric' AS field_type, 'Aggregated total count of completed purchases.' AS field_description UNION ALL
  SELECT 'total_refund_revenue' AS field_name, 'Metric' AS field_type, 'Total refund revenue.' AS field_description UNION ALL
  SELECT 'total_refund_shipping' AS field_name, 'Metric' AS field_type, 'Total shipping refunded.' AS field_description UNION ALL
  SELECT 'total_refund_tax' AS field_name, 'Metric' AS field_type, 'Total tax refunded.' AS field_description UNION ALL
  SELECT 'total_refunds' AS field_name, 'Metric' AS field_type, 'Total count of refunds.' AS field_description UNION ALL
  SELECT 'total_returning_sessions' AS field_name, 'Metric' AS field_type, 'Total returning sessions count.' AS field_description UNION ALL
  SELECT 'total_revenue' AS field_name, 'Metric' AS field_type, 'Aggregated total revenue.' AS field_description UNION ALL
  SELECT 'total_revenue_net_refund' AS field_name, 'Metric' AS field_type, 'Total revenue net of refunds.' AS field_description UNION ALL
  SELECT 'total_sessions' AS field_name, 'Metric' AS field_type, 'Total sessions count.' AS field_description UNION ALL
  SELECT 'total_users' AS field_name, 'Metric' AS field_type, 'Total users count.' AS field_description UNION ALL
  SELECT 'total_users_with_purchase' AS field_name, 'Metric' AS field_type, 'Total count of users with at least one purchase.' AS field_description UNION ALL
  SELECT 'total_users_with_refund' AS field_name, 'Metric' AS field_type, 'Total count of users with at least one refund.' AS field_description UNION ALL
  SELECT 'transaction_coupon' AS field_name, 'Dimension' AS field_type, 'Coupon code applied to the transaction.' AS field_description UNION ALL
  SELECT 'transaction_currency' AS field_name, 'Dimension' AS field_type, 'Currency used for transaction.' AS field_description UNION ALL
  SELECT 'transaction_id' AS field_name, 'Dimension' AS field_type, 'Unique order or transaction ID.' AS field_description UNION ALL
  SELECT 'transaction_revenue' AS field_name, 'Metric' AS field_type, 'Total revenue of transaction.' AS field_description UNION ALL
  SELECT 'transaction_shipping' AS field_name, 'Metric' AS field_type, 'Shipping charges of transaction.' AS field_description UNION ALL
  SELECT 'transaction_tax' AS field_name, 'Metric' AS field_type, 'Tax charges of transaction.' AS field_description UNION ALL
  SELECT 'transactions_count' AS field_name, 'Metric' AS field_type, 'Total count of transactions.' AS field_description UNION ALL
  SELECT 'type' AS field_name, 'Dimension' AS field_type, 'Classification type.' AS field_description UNION ALL
  SELECT 'udf' AS field_name, 'Dimension' AS field_type, 'User Defined Function payload.' AS field_description UNION ALL
  SELECT 'user_campaign_click_id' AS field_name, 'Dimension' AS field_type, 'Click ID attributed to the user.' AS field_description UNION ALL
  SELECT 'user_campaign_content' AS field_name, 'Dimension' AS field_type, 'Ad content attributed to the user.' AS field_description UNION ALL
  SELECT 'user_campaign_id' AS field_name, 'Dimension' AS field_type, 'Campaign ID attributed to the user.' AS field_description UNION ALL
  SELECT 'user_campaign_marketing_objective' AS field_name, 'Dimension' AS field_type, 'Marketing objective of the campaign attributed to the user.' AS field_description UNION ALL
  SELECT 'user_campaign_medium' AS field_name, 'Dimension' AS field_type, 'Medium attributed to the user.' AS field_description UNION ALL
  SELECT 'user_campaign_name' AS field_name, 'Dimension' AS field_type, 'Campaign name attributed to the user.' AS field_description UNION ALL
  SELECT 'user_campaign_source' AS field_name, 'Dimension' AS field_type, 'Traffic source attributed to the user.' AS field_description UNION ALL
  SELECT 'user_campaign_term' AS field_name, 'Dimension' AS field_type, 'Paid keyword attributed to the user.' AS field_description UNION ALL
  SELECT 'user_channel_grouping' AS field_name, 'Dimension' AS field_type, 'Channel grouping attributed to the user.' AS field_description UNION ALL
  SELECT 'user_city' AS field_name, 'Dimension' AS field_type, 'Geographic city of the user.' AS field_description UNION ALL
  SELECT 'user_country' AS field_name, 'Dimension' AS field_type, 'Geographic country of the user.' AS field_description UNION ALL
  SELECT 'user_custom_channel_grouping' AS field_name, 'Dimension' AS field_type, 'Custom channel grouping attributed to the user.' AS field_description UNION ALL
  SELECT 'user_date' AS field_name, 'Dimension' AS field_type, 'Date of the user record.' AS field_description UNION ALL
  SELECT 'user_device_category' AS field_name, 'Dimension' AS field_type, 'Device category used by the user.' AS field_description UNION ALL
  SELECT 'user_device_model' AS field_name, 'Dimension' AS field_type, 'Device model used by the user.' AS field_description UNION ALL
  SELECT 'user_device_os' AS field_name, 'Dimension' AS field_type, 'Operating system used by the user.' AS field_description UNION ALL
  SELECT 'user_device_os_version' AS field_name, 'Dimension' AS field_type, 'OS version used by the user.' AS field_description UNION ALL
  SELECT 'user_device_type' AS field_name, 'Dimension' AS field_type, 'Device type utilized by the user.' AS field_description UNION ALL
  SELECT 'user_device_vendor' AS field_name, 'Dimension' AS field_type, 'Device manufacturer utilized by the user.' AS field_description UNION ALL
  SELECT 'user_event_origin' AS field_name, 'Dimension' AS field_type, 'Primary event origin for the user.' AS field_description UNION ALL
  SELECT 'user_first_page_category' AS field_name, 'Dimension' AS field_type, 'Category of user first page view.' AS field_description UNION ALL
  SELECT 'user_first_page_hostname' AS field_name, 'Dimension' AS field_type, 'Hostname of user first page view.' AS field_description UNION ALL
  SELECT 'user_first_page_hostname_protocol' AS field_name, 'Dimension' AS field_type, 'Protocol of user first page view.' AS field_description UNION ALL
  SELECT 'user_first_page_path' AS field_name, 'Dimension' AS field_type, 'Path of user first page view.' AS field_description UNION ALL
  SELECT 'user_first_page_query' AS field_name, 'Dimension' AS field_type, 'Query of user first page view.' AS field_description UNION ALL
  SELECT 'user_first_page_referrer' AS field_name, 'Dimension' AS field_type, 'Referrer of user first page view.' AS field_description UNION ALL
  SELECT 'user_first_page_title' AS field_name, 'Dimension' AS field_type, 'Title of user first page view.' AS field_description UNION ALL
  SELECT 'user_first_page_url' AS field_name, 'Dimension' AS field_type, 'URL of user first page view.' AS field_description UNION ALL
  SELECT 'user_first_session_timestamp' AS field_name, 'Dimension' AS field_type, 'Timestamp of the user first session.' AS field_description UNION ALL
  SELECT 'user_id' AS field_name, 'Dimension' AS field_type, 'Unique identifier for the authenticated user.' AS field_description UNION ALL
  SELECT 'user_language' AS field_name, 'Dimension' AS field_type, 'Preferred language of the user.' AS field_description UNION ALL
  SELECT 'user_last_page_category' AS field_name, 'Dimension' AS field_type, 'Category of user last page view.' AS field_description UNION ALL
  SELECT 'user_last_page_hostname' AS field_name, 'Dimension' AS field_type, 'Hostname of user last page view.' AS field_description UNION ALL
  SELECT 'user_last_page_hostname_protocol' AS field_name, 'Dimension' AS field_type, 'Protocol of user last page view.' AS field_description UNION ALL
  SELECT 'user_last_page_path' AS field_name, 'Dimension' AS field_type, 'Path of user last page view.' AS field_description UNION ALL
  SELECT 'user_last_page_query' AS field_name, 'Dimension' AS field_type, 'Query of user last page view.' AS field_description UNION ALL
  SELECT 'user_last_page_title' AS field_name, 'Dimension' AS field_type, 'Title of user last page view.' AS field_description UNION ALL
  SELECT 'user_last_page_url' AS field_name, 'Dimension' AS field_type, 'URL of user last page view.' AS field_description UNION ALL
  SELECT 'user_last_session_timestamp' AS field_name, 'Dimension' AS field_type, 'Timestamp of the user most recent session.' AS field_description UNION ALL
  SELECT 'user_origin' AS field_name, 'Dimension' AS field_type, 'Origin classification of user.' AS field_description UNION ALL
  SELECT 'user_os_name' AS field_name, 'Dimension' AS field_type, 'OS name used by the user.' AS field_description UNION ALL
  SELECT 'user_os_version' AS field_name, 'Dimension' AS field_type, 'OS version used by the user.' AS field_description UNION ALL
  SELECT 'user_page_views' AS field_name, 'Metric' AS field_type, 'Total page views by the user.' AS field_description UNION ALL
  SELECT 'user_pseudo_id' AS field_name, 'Dimension' AS field_type, 'GA4 pseudo ID.' AS field_description UNION ALL
  SELECT 'user_screen_size' AS field_name, 'Dimension' AS field_type, 'Screen resolution of the user.' AS field_description UNION ALL
  SELECT 'user_sessions_count' AS field_name, 'Metric' AS field_type, 'Total sessions count for the user.' AS field_description UNION ALL
  SELECT 'user_source' AS field_name, 'Dimension' AS field_type, 'Original source attributed to the user.' AS field_description UNION ALL
  SELECT 'user_source_cleaned' AS field_name, 'Dimension' AS field_type, 'Cleaned source attributed to user.' AS field_description UNION ALL
  SELECT 'user_tld_source' AS field_name, 'Dimension' AS field_type, 'Top level domain source attributed to user.' AS field_description UNION ALL
  SELECT 'user_type' AS field_name, 'Dimension' AS field_type, 'User type classification (new vs returning).' AS field_description UNION ALL
  SELECT 'user_with_purchase' AS field_name, 'Metric' AS field_type, 'Flag or metric indicating if the user has made a purchase.' AS field_description UNION ALL
  SELECT 'user_with_refund' AS field_name, 'Metric' AS field_type, 'Flag or metric indicating if the user has requested a refund.' AS field_description UNION ALL
  SELECT 'users_count' AS field_name, 'Metric' AS field_type, 'Total count of users.' AS field_description UNION ALL
  SELECT 'users_custom_channel_grouping' AS field_name, 'Dimension' AS field_type, 'Custom channel grouping defined at user level.' AS field_description UNION ALL
  SELECT 'value' AS field_name, 'Metric' AS field_type, 'Monetary value.' AS field_description UNION ALL
  SELECT 'value_net_refund' AS field_name, 'Metric' AS field_type, 'Monetary value net of refunds.' AS field_description UNION ALL
  SELECT 'view_cart' AS field_name, 'Metric' AS field_type, 'Total number of sessions where the cart was viewed.' AS field_description UNION ALL
  SELECT 'view_item' AS field_name, 'Metric' AS field_type, 'Total number of sessions where an item detail was viewed.' AS field_description UNION ALL
  SELECT 'view_item_list' AS field_name, 'Metric' AS field_type, 'Total number of sessions where an item list was viewed.' AS field_description UNION ALL
  SELECT 'view_promotion' AS field_name, 'Metric' AS field_type, 'Total number of sessions where a promotion was viewed.' AS field_description UNION ALL
  SELECT 'year' AS field_name, 'Dimension' AS field_type, 'Year of activity.'
)
SELECT 
  REPLACE(c.table_name, 'matrix_', '') AS table_function_name,
  c.column_name AS field_name,
  COALESCE(d.field_type, 'Dimension') AS field_type,

  -- Value type derived automatically from the real Table Function output schema
  CASE
    WHEN c.data_type = 'STRING' THEN 'string'
    WHEN c.data_type IN ('INT64', 'INTEGER') THEN 'integer'
    WHEN c.data_type IN ('FLOAT64', 'FLOAT', 'NUMERIC', 'BIGNUMERIC', 'DECIMAL', 'BIGDECIMAL') THEN 'float'
    WHEN c.data_type IN ('BOOL', 'BOOLEAN') THEN 'boolean'
    WHEN c.data_type = 'DATE' THEN 'date'
    WHEN c.data_type = 'DATETIME' THEN 'datetime'
    WHEN c.data_type = 'TIMESTAMP' THEN 'timestamp'
    WHEN c.data_type = 'TIME' THEN 'time'
    WHEN c.data_type = 'JSON' THEN 'json'
    WHEN STARTS_WITH(c.data_type, 'ARRAY<') THEN 'array'
    WHEN STARTS_WITH(c.data_type, 'STRUCT<') THEN 'struct'
    ELSE LOWER(c.data_type)
  END AS value_type,

  COALESCE(
    d.field_description,
    CONCAT('Field representing ', REPLACE(c.column_name, '_', ' '))
  ) AS field_description,

  'X' AS is_present

FROM `tom-moretti.nameless_analytics.INFORMATION_SCHEMA.COLUMNS` c

LEFT JOIN dictionary d 
  ON c.column_name = d.field_name

WHERE true
  AND c.table_name LIKE 'matrix_%'

ORDER BY
  table_function_name,
  c.ordinal_position;

-- =========================================================================
-- OUTPUT
-- =========================================================================
-- La tabella `fields` è la source of truth in formato long:
--
-- table_function_name
-- field_name
-- field_type
-- value_type
-- field_description
-- is_present
--
-- Una seconda query/view può usare questa tabella per:
-- 1. creare una riga per field_name;
-- 2. pivotare le Table Functions in colonne;
-- 3. concatenare le righe in Markdown con STRING_AGG().
-- =========================================================================


-- 3. Pulizia automatica: elimina le viste temporanee create al punto 1
FOR routine IN (
  SELECT routine_name 
  FROM `tom-moretti.nameless_analytics.INFORMATION_SCHEMA.ROUTINES`
  WHERE routine_type = 'TABLE FUNCTION' AND routine_name NOT LIKE 'get_%'
)
DO
  EXECUTE IMMEDIATE FORMAT("""
    DROP VIEW IF EXISTS `tom-moretti.nameless_analytics.matrix_%s`;
  """, routine.routine_name);
END FOR;
