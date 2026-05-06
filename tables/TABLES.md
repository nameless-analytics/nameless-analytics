# Nameless Analytics | Reporting Tables
The Nameless Analytics Reporting Tables provide a structured set of BigQuery resources where user, session, and event data are centrally stored and processed.

For an overview of how Nameless Analytics works [start from here](../README.md#overview).

### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change 🚧



## Table of Contents

- [Setup](#setup)
  - [Create tables](#create-tables)
  - [Create table functions](#create-table-functions)
- [Raw tables](#raw-tables)
- [Table functions](#table-functions)
  - [Events](#events)
  - [Users](#users)
  - [Sessions](#sessions)
  - [Pages](#pages)
  - [Transactions](#transactions)
  - [Products](#products)
  - [Shopping stages open funnel](#shopping-stages-open-funnel)
  - [Shopping stages closed funnel](#shopping-stages-closed-funnel)
  - [Events debug](#events-debug)
  - [Consents](#consents)
- [Reporting fields](#reporting-fields)
- [Data Governance and Maintenance](#data-governance-and-maintenance)
  - [Delete user data script](#delete-user-data-script)
  - [Manual user data deletion](#manual-user-data-deletion)
  - [Data Health Check](#data-health-check)

## Setup
The following SQL scripts are used to initialize the Nameless Analytics reporting environment in BigQuery.


### Create tables
<details><summary>To create the tables use this DDL statement.</summary>
  
```sql
# NAMELESS ANALYTICS

# Project settings
declare project_name string default 'tom-moretti';  -- Change this
declare dataset_name string default 'nameless_analytics'; -- Change this
declare dataset_location string default 'eu'; -- Change this

# Tables
declare main_table_name string default 'events_raw';
declare dates_table_name string default 'calendar_dates';

# Paths
declare main_dataset_path string default CONCAT('`', project_name, '.', dataset_name, '`');
declare main_table_path string default CONCAT('`', project_name, '.', dataset_name, '.', main_table_name,'`');
declare dates_table_path string default CONCAT('`', project_name, '.', dataset_name, '.', dates_table_name,'`');


# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Enable BigQuery advanced runtime, a more advanced query execution engine that automatically improves performance and efficiency for complex analytical queries. For more informations: https://cloud.google.com/bigquery/docs/advanced-runtime
declare enable_bigquery_advanced_runtime string default format(
  """
    ALTER PROJECT `%s`
    SET OPTIONS (
      `region-%s.query_runtime` = 'advanced'
    );
  """
, project_name, dataset_location);


# Create main dataset (for more info https://cloud.google.com/bigquery/docs/datasets#sql)
declare main_dataset_sql string default format(
  """
    create schema if not exists %s
    options (
      # default_kms_key_name = 'KMS_KEY_NAME',
      # default_partition_expiration_days = PARTITION_EXPIRATION,
      # default_table_expiration_days = TABLE_EXPIRATION,
      # max_time_travel_hours = HOURS, # default 168 hours => 7 days 
      # storage_billing_model = BILLING_MODEL # Physical or logical (default)  
      description = 'Nameless Analytics',
      location = '%s'
    );
  """
, main_dataset_path, dataset_location);


# Create main table
declare main_table_sql string default format(
  """
    create table if not exists %s (
      client_id STRING NOT NULL OPTIONS (description = 'Client ID'),
      user_date DATE NOT NULL OPTIONS (description = 'User date'),
      user_data ARRAY<
        STRUCT<
          name STRING OPTIONS (description = 'User data parameter name'),
          value STRUCT<
            string STRING OPTIONS (description = 'User data parameter string value'),
            int INT64 OPTIONS (description = 'User data parameter int number value'),
            float FLOAT64 OPTIONS (description = 'User data parameter float number value'),
            json JSON OPTIONS (description = 'User data parameter JSON value'),
            bool BOOL OPTIONS (description = 'User data parameter boolean value')
          > OPTIONS (description = 'User data parameter value name')
        >
      > OPTIONS (description = 'User data'),

      session_id STRING NOT NULL OPTIONS (description = 'Session ID'),
      session_date DATE NOT NULL OPTIONS (description = 'Session date'),
      session_data ARRAY<
        STRUCT<
          name STRING OPTIONS (description = 'Session data parameter name'),
          value STRUCT<
            string STRING OPTIONS (description = 'Session data parameter string value'),
            int INT64 OPTIONS (description = 'Session data parameter int number value'),
            float FLOAT64 OPTIONS (description = 'Session data parameter float number value'),
            json JSON OPTIONS (description = 'Session data parameter JSON value'),
            bool BOOL OPTIONS (description = 'Session data parameter boolean value')
          > OPTIONS (description = 'Session data parameter value name')
        >
      > OPTIONS (description = 'Session data'),  

      page_id STRING NOT NULL OPTIONS (description = 'Page ID'),
      page_date DATE NOT NULL OPTIONS (description = 'Page date'),
      page_data ARRAY<
        STRUCT<
          name STRING OPTIONS (description = 'Page data parameter name'),
          value STRUCT<
            string STRING OPTIONS (description = 'Page data parameter string value'),
            int INT64 OPTIONS (description = 'Page data parameter int number value'),
            float FLOAT64 OPTIONS (description = 'Page data parameter float number value'),
            json JSON OPTIONS (description = 'Page data parameter JSON value'),
            bool BOOL OPTIONS (description = 'Page data parameter boolean value')
          > OPTIONS (description = 'Page data parameter value name')
        >
      > OPTIONS (description = 'Page data'),

      event_name STRING NOT NULL OPTIONS (description = 'Event name'),
      event_id STRING NOT NULL OPTIONS (description = 'Event ID'),
      event_date DATE NOT NULL OPTIONS (description = 'Event date'),
      event_timestamp INT64 NOT NULL OPTIONS (description = 'Event timestamp'),
      event_origin STRING NOT NULL OPTIONS (description = 'Event origin'),
      event_data ARRAY<
        STRUCT<
          name STRING OPTIONS (description = 'Event data parameter name'),
          value STRUCT<
            string STRING OPTIONS (description = 'Event data parameter string value'),
            int INT64 OPTIONS (description = 'Event data parameter int number value'),
            float FLOAT64 OPTIONS (description = 'Event data parameter float number value'),
            json JSON OPTIONS (description = 'Event data parameter JSON value'),
            bool BOOL OPTIONS (description = 'Event data parameter boolean value')
          > OPTIONS (description = 'Event data parameter value name')
        >
      > OPTIONS (description = 'Event data'),

      ecommerce JSON OPTIONS (description = 'Ecommerce object'),

      datalayer JSON OPTIONS (description = 'Current dataLayer value'),

      consent_data ARRAY<
        STRUCT<
          name STRING OPTIONS (description = 'Consent data parameter name'),
          value STRUCT<
            string STRING OPTIONS (description = 'Consent data parameter string value')
          > OPTIONS (description = 'Consent data parameter value name')
        >
      > OPTIONS (description = 'Consent data'),

      gtm_data ARRAY<
        STRUCT<
          name STRING OPTIONS (description = 'GTM execution parameter name'),
          value STRUCT<
            string STRING OPTIONS (description = 'GTM execution parameter string value'),
            int INT64 OPTIONS (description = 'Event data parameter int number value')
          > OPTIONS (description = 'GTM execution parameter value name')
        >
      > OPTIONS (description = 'GTM execution data')

    )

    PARTITION BY event_date
    CLUSTER BY user_date, session_date, page_date, event_name
    OPTIONS(
      description = 'Nameless Analytics | Main table',
      require_partition_filter = FALSE
    );
  """
, main_table_path);


# Create dates table
declare dates_table_sql string default FORMAT(
  """
    create table if not exists %s (
      date DATE NOT NULL OPTIONS(description = "The date value"),
      year INT64 OPTIONS(description = "Year extracted from the date"),
      quarter INT64 OPTIONS(description = "Quarter of the year (1-4) extracted from the date"),
      month_number INT64 OPTIONS(description = "Month number of the year (1-12) extracted from the date"),
      month_name STRING OPTIONS(description = "Full name of the month (e.g., January) extracted from the date"),
      week_number_sunday INT64 OPTIONS(description = "Week number of the year, starting on Sunday"),
      week_number_monday INT64 OPTIONS(description = "Week number of the year, starting on Monday"),  
      day_number INT64 OPTIONS(description = "Day number of the month (1-31)"),
      day_name STRING OPTIONS(description = "Full name of the day of the week (e.g., Monday)"),
      day_of_week_number INT64 OPTIONS(description = "Day of the week number (1 for Monday, 7 for Sunday)"),
      is_weekend BOOL OPTIONS(description = "True if the day is Saturday or Sunday")
    ) 
    
    PARTITION BY DATE_TRUNC(date, year)
    CLUSTER BY month_name, day_name
    OPTIONS (description = 'Nameless Analytics | Dates utility table')
    
    AS (
      SELECT 
        date,
        EXTRACT(YEAR FROM date) AS year,
        EXTRACT(QUARTER FROM date) AS quarter,
        EXTRACT(MONTH FROM date) AS month_number,
        FORMAT_DATE('%%B', date) AS month_name,
        EXTRACT(WEEK(SUNDAY) FROM date) AS week_number_sunday,
        EXTRACT(WEEK(MONDAY) FROM date) AS week_number_monday,
        EXTRACT(DAY FROM date) AS day_number,
        FORMAT_DATE('%%A', date) AS day_name,
        EXTRACT(DAYOFWEEK FROM date) AS day_of_week_number, 
        IF(EXTRACT(DAYOFWEEK FROM date) IN (1, 7), TRUE, FALSE) AS is_weekend
      FROM UNNEST(GENERATE_DATE_ARRAY('1970-01-01', '2050-12-31', INTERVAL 1 DAY)) AS date
    );
  """
, dates_table_path);


# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Enable BigQuery advanced runtime
execute immediate enable_bigquery_advanced_runtime; 

# Create main dataset
execute immediate main_dataset_sql; 

# Create main table
execute immediate main_table_sql; 

# Create dates table
execute immediate dates_table_sql; 
```
</details>


### Create table functions
<details><summary>To create the table functions use this DDL statement.</summary>

```sql
# Run the SQL scripts in this directory to create the table functions.
```
</details>



## Raw tables
Raw tables are the foundational storage layer of Nameless Analytics, designed to capture and preserve every user interaction in its raw, unprocessed form. These tables serve as the single source of truth for all analytics data, storing event-level information with complete historical fidelity.

The architecture consists of two core tables: the **Events raw table** (`events_raw`), which stores all user, session, page, event, ecommerce, consent, and GTM performance data in a denormalized structure optimized for both write performance and analytical queries; and the **Dates table** (`calendar_dates`), a utility dimension table that provides comprehensive date attributes for time-based analysis and reporting.

All data is partitioned by date and clustered by key dimensions to ensure optimal query performance and cost efficiency when analyzing large datasets.

The main table is partitioned by `event_date` and clustered by `user_date`, `session_date`, `page_date`, and `event_name`.

The dates table is partitioned by `date` and clustered by `month_name` and `day_name`.



## Table functions
Table functions are predefined SQL queries that simplify data analysis by transforming raw event data into structured, easy-to-use formats for common reporting needs.

Unlike other systems, Nameless Analytics reporting functions are designed to work directly on the `events_raw` table as the single source of truth. By leveraging BigQuery **Window Functions**. This approach ensures that reports always reflect the most up-to-date state of the data without the need for complex ETL processes or intermediate staging tables.

Streaming protocol events are excluded from the calculation of the `session_duration` and `time_on_page` fields.


### Events
Flattens raw event data and extracts custom parameters, making it easier to analyze specific interaction metrics.

Event data can be extracted at various levels:

```sql
-- User level
-- Returns events related to users acquired in the selected time period.

select * from `project.nameless_analytics.events` (start_date, end_date, 'user')


--Session level
-- Returns events related to sessions that started in the selected time period.

select * from `project.nameless_analytics.events`(start_date, end_date, 'session')


-- Page level
-- Returns events related to pages visited in the selected time period.

select * from `project.nameless_analytics.events`(start_date, end_date, 'page')


-- Event level
-- Returns events that occurred in the selected time period.

select * from `project.nameless_analytics.events`(start_date, end_date, 'event')
```

<details><summary>Output fields</summary>

| Field | Type | Description |
| :--- | :--- | :--- |
| `ad_personalization` | Dimension | Consent state for ad personalization. |
| `ad_storage` | Dimension | Consent state for advertising storage (e.g., cookies). |
| `ad_user_data` | Dimension | Consent state for sending user data to Google for advertising. |
| `analytics_storage` | Dimension | Consent state for analytics storage (e.g., cookies). |
| `browser_language` | Dimension | The language setting of the user's browser. |
| `browser_name` | Dimension | The name of the browser (e.g., Chrome, Safari). |
| `browser_version` | Dimension | The specific version of the browser. |
| `campaign` | Dimension | The name of the marketing campaign. |
| `campaign_click_id` | Dimension | The campaign click ID (e.g., GCLID). |
| `campaign_content` | Dimension | The content of the marketing campaign. |
| `campaign_id` | Dimension | The ID of the marketing campaign. |
| `campaign_term` | Dimension | The term (keyword) of the marketing campaign. |
| `channel_grouping` | Dimension | The acquisition channel grouping (e.g., Organic Search). |
| `city` | Dimension | The user's city based on IP address. |
| `client_id` | Dimension | Unique identifier for the client/browser. |
| `consent_type` | Dimension | The type of consent being expressed or updated. |
| `content_length_in_kb` | Metric | The length of the request content in kilobytes. |
| `country` | Dimension | The user's country based on IP address. |
| `cross_domain_id` | Dimension | Identifier for cross-domain tracking (derived from na_id). |
| `cross_domain_session` | Dimension | Indicates if the session is cross-domain. |
| `cs_container_id` | Dimension | Client-side GTM container ID. |
| `cs_hostname` | Dimension | Client-side GTM server hostname. |
| `cs_tag_id` | Dimension | Client-side GTM tag ID. |
| `cs_tag_name` | Dimension | Client-side GTM tag name. |
| `datalayer` | Dimension | Current JSON value of the dataLayer. |
| `days_from_first_to_last_visit` | Metric | Days between the user's first and last visit. |
| `days_from_first_visit` | Metric | Days since the user's first visit. |
| `days_from_last_visit` | Metric | Days since the user's last visit. |
| `delay_in_millis` | Metric | Delay between event occurrence and processing in milliseconds. |
| `delay_in_sec` | Metric | Delay between event occurrence and processing in seconds. |
| `device_model` | Dimension | The model of the user's device. |
| `device_type` | Dimension | The type of device (e.g., Mobile, Desktop). |
| `device_vendor` | Dimension | The manufacturer of the device. |
| `ecommerce` | Dimension | Structured ecommerce data in JSON format. |
| `event_data` | Dimension | Array of custom event parameters. |
| `event_date` | Dimension | The date the event occurred. |
| `event_id` | Dimension | Unique identifier for the event. |
| `event_name` | Dimension | The name of the interaction event. |
| `event_number` | Dimension | Sequential number of the event in the session. |
| `event_origin` | Dimension | The origin of the event (e.g., Web, Server). |
| `event_timestamp` | Metric | Unix timestamp (ms) of the event. |
| `event_type` | Dimension | Category or type of the event. |
| `functionality_storage` | Dimension | Consent state for necessary functional storage. |
| `new_session` | Metric | Indicates if this is a new session (1 for yes, 0 for no). |
| `new_user_client_id` | Dimension | Client ID if this is the user's first session, else null. |
| `os_name` | Dimension | The name of the operating system. |
| `os_version` | Dimension | The version of the operating system. |
| `page_category` | Dimension | Logical category of the page. |
| `page_data` | Dimension | Array of custom page parameters. |
| `page_date` | Dimension | The date the page was viewed. |
| `page_extension` | Dimension | The file extension of the page. |
| `page_fragment` | Dimension | The URL fragment (part after #). |
| `page_hostname` | Dimension | The hostname of the page viewed. |
| `page_hostname_protocol` | Dimension | The protocol of the URL (e.g., https). |
| `page_id` | Dimension | Unique identifier for the page view. |
| `page_language` | Dimension | The language set for the page. |
| `page_load_timestamp` | Dimension | Timestamp when the page started loading. |
| `page_location` | Dimension | The full URL of the page. |
| `page_query` | Dimension | The URL query string. |
| `page_referrer` | Dimension | The URL of the referring page. |
| `page_status_code` | Dimension | HTTP status code of the page. |
| `page_title` | Dimension | The title (document title) of the page. |
| `page_unload_timestamp` | Dimension | Timestamp when the page was closed. |
| `page_view_number` | Dimension | Sequential number of the page view in the session. |
| `personalization_storage` | Dimension | Consent state for personalization storage. |
| `processing_event_timestamp` | Dimension | Timestamp when the event was processed by the server. |
| `respect_consent_mode` | Dimension | Indicates if the system respected Consent Mode settings. |
| `returning_session` | Metric | Indicates if this is a returning session (1 for yes, 0 for no). |
| `returning_user_client_id` | Dimension | Client ID if this is not the user's first session, else null. |
| `screen_size` | Dimension | Physical resolution of the user's screen. |
| `search_term` | Dimension | The term searched by the user (for search events). |
| `security_storage` | Dimension | Consent state for security-related storage. |
| `session_browser_name` | Dimension | Browser name recorded at session start. |
| `session_campaign` | Dimension | Acquisition campaign for the session. |
| `session_campaign_click_id` | Dimension | Campaign click ID for the session. |
| `session_campaign_content` | Dimension | Campaign content for the session. |
| `session_campaign_id` | Dimension | Campaign ID for the session. |
| `session_campaign_term` | Dimension | Campaign term for the session. |
| `session_channel_grouping` | Dimension | Acquisition channel grouping for the session. |
| `session_city` | Dimension | City detected for the session. |
| `session_country` | Dimension | Country detected for the session. |
| `session_data` | Dimension | Array of session level metadata/parameters. |
| `session_date` | Dimension | The date the session started. |
| `session_device_type` | Dimension | Primary device type detected for the session. |
| `session_duration_sec` | Metric | Total duration of the session in seconds. |
| `session_end_timestamp` | Dimension | Timestamp of the last activity in the session. |
| `session_exit_page_category` | Dimension | Category of the last page visited in the session. |
| `session_exit_page_location` | Dimension | URL of the last page visited in the session. |
| `session_exit_page_title` | Dimension | Title of the last page visited in the session. |
| `session_hostname` | Dimension | Hostname recorded for the session. |
| `session_id` | Dimension | Unique identifier for the session. |
| `session_landing_page_category` | Dimension | Category of the first page visited in the session. |
| `session_landing_page_location` | Dimension | URL of the first page visited in the session. |
| `session_landing_page_title` | Dimension | Title of the first page visited in the session. |
| `session_language` | Dimension | Language recorded for the session. |
| `session_number` | Dimension | Sequence number of the session for the user. |
| `session_source` | Dimension | Traffic source for the session. |
| `session_source_cleaned` | Dimension | Normalized traffic source for the session. |
| `session_start_timestamp` | Dimension | Timestamp of the first event in the session. |
| `session_tld_source` | Dimension | Session source including TLD. |
| `session_type` | Dimension | Classification of the session (New vs Returning). |
| `source` | Dimension | Specific source for the event. |
| `source_cleaned` | Dimension | Normalized source for the event. |
| `ss_container_id` | Dimension | Server-side GTM container ID. |
| `ss_hostname` | Dimension | Server-side GTM server hostname. |
| `ss_tag_id` | Dimension | Server-side GTM tag ID. |
| `ss_tag_name` | Dimension | Server-side GTM tag name. |
| `time_on_page` | Metric | Seconds spent on the page. |
| `tld_source` | Dimension | Event source including TLD. |
| `total_page_load_time` | Metric | Total page load time in milliseconds. |
| `user_agent` | Dimension | Browser User Agent string. |
| `user_campaign` | Dimension | Original acquisition campaign for the user. |
| `user_campaign_click_id` | Dimension | Original acquisition click ID for the user. |
| `user_campaign_content` | Dimension | Original acquisition campaign content. |
| `user_campaign_id` | Dimension | Original acquisition campaign ID. |
| `user_campaign_term` | Dimension | Original acquisition campaign term. |
| `user_channel_grouping` | Dimension | Original acquisition channel grouping. |
| `user_city` | Dimension | User's city at the time of first acquisition. |
| `user_country` | Dimension | User's country at the time of first acquisition. |
| `user_data` | Dimension | Array of persistent user metadata. |
| `user_date` | Dimension | Date the user was first seen. |
| `user_device_type` | Dimension | Device type used at first acquisition. |
| `user_first_session_timestamp` | Dimension | Absolute timestamp of the user's first session. |
| `user_id` | Dimension | Business-level unique user identifier. |
| `user_language` | Dimension | User language recorded at acquisition. |
| `user_last_session_timestamp` | Dimension | Timestamp of the user's latest known session. |
| `user_source` | Dimension | Original source of acquisition. |
| `user_source_cleaned` | Dimension | Normalized source of acquisition. |
| `user_tld_source` | Dimension | Source of acquisition with TLD. |
| `user_type` | Dimension | User type classification (New vs Returning). |
| `viewport_size` | Metric | Dimensions of the visible browser window area. |

</details>

</br>

[View SQL code](events.sql)


### Users
Aggregates event data at user level.

<details><summary>Output fields</summary>

| `avg_purchase_value` | Metric | Average monetary value of purchases per user. |
| `avg_refund_value` | Metric | Average monetary value of refunds per user. |
| `client_id` | Dimension | Unique identifier for the client/browser. |
| `customer_client_id` | Dimension | Client ID of customers. |
| `customer_status` | Dimension | Status of the customer. |
| `customer_type` | Dimension | Classification of the customer based on purchase history. |
| `days_from_first_purchase` | Metric | Number of days since the user's first purchase event. |
| `days_from_first_to_last_visit` | Metric | Days between the user's first and most recent visits. |
| `days_from_first_visit` | Metric | Total days since the user's first recorded visit. |
| `days_from_last_purchase` | Metric | Number of days since the user's most recent purchase. |
| `days_from_last_visit` | Metric | Number of days since the user's most recent visit. |
| `first_purchase_timestamp` | Dimension | Timestamp of the user's very first purchase. |
| `item_quantity_purchased` | Metric | Total quantity of items purchased by the user. |
| `item_quantity_refunded` | Metric | Total quantity of items refunded by the user. |
| `last_purchase_timestamp` | Dimension | Timestamp of the user's most recent purchase. |
| `new_customer_client_id` | Dimension | Client ID of new customers. |
| `new_user_client_id` | Dimension | Client ID for users identified as new during the period. |
| `page_view` | Metric | Total number of page view events triggered by the user. |
| `purchase` | Metric | Total count of purchase events for the user. |
| `purchase_revenue` | Metric | Total revenue generated from user purchases. |
| `refund` | Metric | Total count of refund events for the user. |
| `refund_revenue` | Metric | Total value of refunds associated with the user. |
| `returning_customer_client_id` | Dimension | Client ID of returning customers. |
| `returning_user_client_id` | Dimension | Client ID for users identified as returning during the period. |
| `revenue_net_refund` | Metric | Total revenue minus the total value of refunds. |
| `session_duration_sec` | Metric | Total accumulated session duration for the user (in seconds). |
| `sessions` | Metric | Total number of sessions recorded for the user. |
| `sessions_per_user` | Metric | Average number of sessions per unique user. |
| `total_events` | Metric | Total number of events. |
| `user_campaign` | Dimension | Original acquisition campaign for the user. |
| `user_campaign_click_id` | Dimension | Original acquisition click ID for the user. |
| `user_campaign_content` | Dimension | Original acquisition campaign content. |
| `user_campaign_id` | Dimension | Original acquisition campaign ID. |
| `user_campaign_term` | Dimension | Original acquisition campaign term. |
| `user_channel_grouping` | Dimension | Original acquisition channel grouping. |
| `user_city` | Dimension | User's city at the time of acquisition. |
| `user_country` | Dimension | User's country at the time of acquisition. |
| `user_date` | Dimension | Date when the user was first seen. |
| `user_device_type` | Dimension | Device type used by the user at acquisition. |
| `user_id` | Dimension | Business-level unique identifier for the user. |
| `user_language` | Dimension | Preferred language of the user at acquisition. |
| `user_source` | Dimension | Original traffic source that acquired the user. |
| `user_type` | Dimension | User classification (New vs Returning). |
| `user_with_purchase` | Metric | Indicates if the user has completed at least one purchase. |
| `user_with_refund` | Metric | Indicates if the user has completed at least one refund. |
| :--- | :--- | :--- |
| Field | Type | Description |

</details>

</br>

[View SQL code](users.sql)


### Sessions
Aggregates event data at session level.

<details><summary>Output fields</summary>

| Field | Type | Description |
| :--- | :--- | :--- |
| `ad_personalization_accepted_percentage` | Metric | Percentage of sessions where ad personalization was accepted. |
| `ad_personalization_denied_percentage` | Metric | Percentage of sessions where ad personalization was denied. |
| `ad_storage_accepted_percentage` | Metric | Percentage of sessions where ad storage was accepted. |
| `ad_storage_denied_percentage` | Metric | Percentage of sessions where ad storage was denied. |
| `ad_user_data_accepted_percentage` | Metric | Percentage of sessions where ad user data was accepted. |
| `ad_user_data_denied_percentage` | Metric | Percentage of sessions where ad user data was denied. |
| `add_payment_info` | Metric | Total number of sessions where payment information was added. |
| `add_shipping_info` | Metric | Total number of sessions where shipping information was added. |
| `add_to_cart` | Metric | Total number of sessions with at least one add_to_cart event. |
| `add_to_wishlist` | Metric | Total number of sessions with at least one add_to_wishlist event. |
| `analytics_storage_accepted_percentage` | Metric | Percentage of sessions where analytics storage was accepted. |
| `analytics_storage_denied_percentage` | Metric | Percentage of sessions where analytics storage was denied. |
| `avg_order_value` | Metric | Average order value generated per session. |
| `avg_refund_value` | Metric | Average value of refunds issued per session. |
| `begin_checkout` | Metric | Total number of sessions where the checkout process was started. |
| `client_id` | Dimension | Unique identifier for the client/browser. |
| `consent_expressed` | Dimension | Indicates if a consent choice was expressed during the session. |
| `consent_timestamp` | Dimension | Timestamp when consent was recorded in the session. |
| `cross_domain_session` | Dimension | Indicates if the session spanned multiple domains. |
| `engaged_session` | Metric | Total number of sessions categorized as engaged. |
| `engaged_sessions_percentage` | Metric | Percentage of total sessions that were engaged. |
| `functionality_storage_accepted_percentage` | Metric | Percentage of sessions where functionality storage was accepted. |
| `functionality_storage_denied_percentage` | Metric | Percentage of sessions where functionality storage was denied. |
| `new_session` | Metric | Total number of new sessions. |
| `new_sessions_percentage` | Metric | Percentage of sessions that were new. |
| `new_user_client_id` | Dimension | Identification of users seen for the first time during the session. |
| `page_view` | Metric | Total number of page view events during the session. |
| `page_view_per_session` | Metric | Average number of page views per session. |
| `personalization_storage_accepted_percentage` | Metric | Percentage of sessions where personalization storage was accepted. |
| `personalization_storage_denied_percentage` | Metric | Percentage of sessions where personalization storage was denied. |
| `purchase` | Metric | Total number of sessions resulting in a purchase. |
| `purchase_net_refund` | Metric | Net number of purchases after accounting for refunds. |
| `purchase_revenue` | Metric | Total revenue generated by purchases in the session. |
| `purchase_shipping` | Metric | Total shipping charges for purchases in the session. |
| `purchase_tax` | Metric | Total tax charges for purchases in the session. |
| `refund` | Metric | Total number of sessions where a refund occurred. |
| `refund_revenue` | Metric | Total monetary value of refunds in the session. |
| `refund_shipping` | Metric | Total shipping value of items refunded in the session. |
| `refund_tax` | Metric | Total tax value of items refunded in the session. |
| `remove_from_cart` | Metric | Total number of sessions with at least one remove_from_cart event. |
| `returning_session` | Metric | Total number of returning sessions. |
| `returning_sessions_percentage` | Metric | Percentage of total sessions that were returning. |
| `returning_user_client_id` | Dimension | Identification of users who had previously visited the site. |
| `revenue_net_refund` | Metric | Total revenue generated minus the total value of refunds in the session. |
| `security_storage_accepted_percentage` | Metric | Percentage of sessions where security storage was accepted. |
| `security_storage_denied_percentage` | Metric | Percentage of sessions where security storage was denied. |
| `select_item` | Metric | Total number of sessions where an item was selected. |
| `select_promotion` | Metric | Total number of sessions where a promotion was selected. |
| `session_ad_personalization` | Metric | Count of sessions with ad personalization consent. |
| `session_ad_storage` | Metric | Count of sessions with ad storage consent. |
| `session_ad_user_data` | Metric | Count of sessions with ad user data consent. |
| `session_analytics_storage` | Metric | Count of sessions with analytics storage consent. |
| `session_browser_name` | Dimension | Browser name recorded at the start of the session. |
| `session_campaign` | Dimension | Acquisition campaign associated with the session. |
| `session_campaign_click_id` | Dimension | Click ID of the campaign associated with the session. |
| `session_campaign_content` | Dimension | Content of the campaign associated with the session. |
| `session_campaign_id` | Dimension | ID of the campaign associated with the session. |
| `session_campaign_term` | Dimension | Keyword/term of the campaign associated with the session. |
| `session_channel_grouping` | Dimension | Marketing channel grouping for the session. |
| `session_city` | Dimension | City detected at the start of the session. |
| `session_country` | Dimension | Country detected at the start of the session. |
| `session_date` | Dimension | Date when the session started. |
| `session_device_type` | Dimension | Primary device type used during the session. |
| `session_duration_sec` | Metric | Total active duration of the session (in seconds). |
| `session_exit_page_category` | Dimension | Category of the page where the session ended. |
| `session_exit_page_location` | Dimension | URL of the page where the session ended. |
| `session_exit_page_title` | Dimension | Title of the page where the session ended. |
| `session_functionality_storage` | Metric | Count of sessions with functionality storage consent. |
| `session_hostname` | Dimension | Hostname recorded for the session. |
| `session_id` | Dimension | Unique identifier for the session. |
| `session_landing_page_category` | Dimension | Category of the first page visited in the session. |
| `session_landing_page_location` | Dimension | URL of the first page visited in the session. |
| `session_landing_page_title` | Dimension | Title of the first page visited in the session. |
| `session_language` | Dimension | Primary language detected for the session. |
| `session_number` | Dimension | Sequence number of the session for the user. |
| `session_personalization_storage` | Metric | Count of sessions with personalization storage consent. |
| `session_security_storage` | Metric | Count of sessions with security storage consent. |
| `session_source` | Dimension | Traffic source that initiated the session. |
| `session_start_timestamp` | Dimension | Timestamp when the session officially began. |
| `session_with_purchase` | Metric | Indicates if the session includes at least one purchase event. |
| `session_with_refund` | Metric | Indicates if the session includes at least one refund event. |
| `shipping_net_refund` | Metric | Total shipping revenue minus refunded shipping charges. |
| `tax_net_refund` | Metric | Total tax revenue minus refunded tax charges. |
| `user_campaign` | Dimension | Original acquisition campaign for the user. |
| `user_campaign_click_id` | Dimension | Original acquisition click ID for the user. |
| `user_campaign_content` | Dimension | Original acquisition campaign content. |
| `user_campaign_id` | Dimension | Original acquisition campaign ID. |
| `user_campaign_term` | Dimension | Original acquisition campaign term. |
| `user_channel_grouping` | Dimension | Original acquisition channel grouping. |
| `user_city` | Dimension | User's city at acquisition. |
| `user_country` | Dimension | User's country at acquisition. |
| `user_date` | Dimension | Date the user was first seen. |
| `user_device_type` | Dimension | Device type at acquisition. |
| `user_id` | Dimension | Business-level unique identifier for the user. |
| `user_language` | Dimension | User language at acquisition. |
| `user_source` | Dimension | Original source that acquired the user. |
| `user_type` | Dimension | User classification (New vs Returning). |
| `view_cart` | Metric | Total number of sessions where the cart was viewed. |
| `view_item` | Metric | Total number of sessions where an item was viewed. |
| `view_item_list` | Metric | Total number of sessions where an item list was viewed. |
| `view_promotion` | Metric | Total number of sessions where a promotion was viewed. |

</details>

</br>

[View SQL code](sessions.sql)


### Pages
Aggregates event data at page level.

<details><summary>Output fields</summary>

| `client_id` | Dimension | Unique identifier for the client/browser. |
| `cross_domain_session` | Dimension | Indicates if the session is cross-domain. |
| `new_user_client_id` | Dimension | Client ID if this is the user's first session, else null. |
| `page_category` | Dimension | Logical category of the page. |
| `page_date` | Dimension | The date the page was viewed. |
| `page_hostname` | Dimension | The hostname of the page viewed. |
| `page_id` | Dimension | Unique identifier for the page view. |
| `page_load_time_sec` | Dimension | Time taken to load the page in seconds. |
| `page_load_timestamp` | Dimension | Timestamp when the page started loading. |
| `page_location` | Dimension | The full URL of the page. |
| `page_status_code` | Dimension | HTTP status code of the page. |
| `page_title` | Dimension | The title (document title) of the page. |
| `page_unload_timestamp` | Dimension | Timestamp when the page was closed. |
| `page_view` | Metric | Count of page views. |
| `page_view_number` | Dimension | Sequential number of the page view in the session. |
| `returning_user_client_id` | Dimension | Client ID if this is not the user's first session, else null. |
| `session_browser_name` | Dimension | Browser name recorded at session start. |
| `session_campaign` | Dimension | Acquisition campaign for the session. |
| `session_campaign_click_id` | Dimension | Campaign click ID for the session. |
| `session_campaign_content` | Dimension | Campaign content for the session. |
| `session_campaign_id` | Dimension | Campaign ID for the session. |
| `session_campaign_term` | Dimension | Campaign term for the session. |
| `session_channel_grouping` | Dimension | Acquisition channel grouping for the session. |
| `session_city` | Dimension | City detected for the session. |
| `session_country` | Dimension | Country detected for the session. |
| `session_date` | Dimension | The date the session started. |
| `session_device_type` | Dimension | Primary device type detected for the session. |
| `session_exit_page_category` | Dimension | Category of the last page visited in the session. |
| `session_exit_page_location` | Dimension | URL of the last page visited in the session. |
| `session_exit_page_title` | Dimension | Title of the last page visited in the session. |
| `session_hostname` | Dimension | Hostname recorded for the session. |
| `session_id` | Dimension | Unique identifier for the session. |
| `session_landing_page_category` | Dimension | Category of the first page visited in the session. |
| `session_landing_page_location` | Dimension | URL of the first page visited in the session. |
| `session_landing_page_title` | Dimension | Title of the first page visited in the session. |
| `session_language` | Dimension | Language recorded for the session. |
| `session_number` | Dimension | Sequence number of the session for the user. |
| `session_source` | Dimension | Traffic source for the session. |
| `session_start_timestamp` | Dimension | Timestamp of the first event in the session. |
| `session_type` | Dimension | Classification of the session (New vs Returning). |
| `time_on_page` | Metric | Seconds spent on the page. |
| `user_campaign` | Dimension | Original acquisition campaign for the user. |
| `user_campaign_click_id` | Dimension | Original acquisition click ID for the user. |
| `user_campaign_content` | Dimension | Original acquisition campaign content. |
| `user_campaign_id` | Dimension | Original acquisition campaign ID. |
| `user_campaign_term` | Dimension | Original acquisition campaign term. |
| `user_channel_grouping` | Dimension | Original acquisition channel grouping. |
| `user_city` | Dimension | User's city at the time of first acquisition. |
| `user_country` | Dimension | User's country at the time of first acquisition. |
| `user_date` | Dimension | Date the user was first seen. |
| `user_device_type` | Dimension | Device type used at first acquisition. |
| `user_id` | Dimension | Business-level unique user identifier. |
| `user_language` | Dimension | User language recorded at acquisition. |
| `user_source` | Dimension | Original source of acquisition. |
| `user_type` | Dimension | User type classification (New vs Returning). |
| :--- | :--- | :--- |
| Field | Type | Description |

</details>

</br>

[View SQL code](pages.sql)


### Transactions
Aggregates ecommerce data at transaction level.

<details><summary>Output fields</summary>

| `client_id` | Dimension | Unique identifier for the client/browser. |
| `cross_domain_session` | Dimension | Indicates if the session is cross-domain. |
| `duplicate_purchase` | Metric | Count of duplicate purchases. |
| `duplicate_refund` | Metric | Count of duplicate refunds. |
| `event_date` | Dimension | The date the event occurred. |
| `event_name` | Dimension | The name of the interaction event. |
| `event_origin` | Dimension | The origin of the event. |
| `hour_and_minute` | Dimension | Hour and minute of the event. |
| `new_user_client_id` | Dimension | Client ID if this is the user's first session, else null. |
| `purchase` | Metric | Total number of sessions with at least one purchase event. |
| `purchase_coupon` | Dimension | Coupon code applied to the purchase. |
| `purchase_currency` | Dimension | Currency used for the purchase. |
| `purchase_revenue` | Metric | Total revenue generated from purchases. |
| `purchase_shipping` | Metric | Total shipping costs for purchases. |
| `purchase_tax` | Metric | Total tax collected on purchases. |
| `refund` | Metric | Total number of sessions with at least one refund event. |
| `refund_coupon` | Dimension | Coupon code applied to the refund. |
| `refund_currency` | Dimension | Currency used for the refund. |
| `refund_revenue` | Metric | Total revenue refunded. |
| `refund_shipping` | Metric | Total shipping costs refunded. |
| `refund_tax` | Metric | Total tax refunded. |
| `returning_user_client_id` | Dimension | Client ID if this is not the user's first session, else null. |
| `session_browser_name` | Dimension | Browser name recorded at session start. |
| `session_campaign` | Dimension | Acquisition campaign for the session. |
| `session_campaign_click_id` | Dimension | Campaign click ID for the session. |
| `session_campaign_content` | Dimension | Campaign content for the session. |
| `session_campaign_id` | Dimension | Campaign ID for the session. |
| `session_campaign_term` | Dimension | Campaign term for the session. |
| `session_channel_grouping` | Dimension | Acquisition channel grouping for the session. |
| `session_city` | Dimension | City detected for the session. |
| `session_country` | Dimension | Country detected for the session. |
| `session_date` | Dimension | The date the session started. |
| `session_device_type` | Dimension | Primary device type detected for the session. |
| `session_end_timestamp` | Dimension | Timestamp of the last activity in the session. |
| `session_exit_page_category` | Dimension | Category of the last page visited in the session. |
| `session_exit_page_location` | Dimension | URL of the last page visited in the session. |
| `session_exit_page_title` | Dimension | Title of the last page visited in the session. |
| `session_hostname` | Dimension | Hostname recorded for the session. |
| `session_id` | Dimension | Unique identifier for the session. |
| `session_landing_page_category` | Dimension | Category of the first page visited in the session. |
| `session_landing_page_location` | Dimension | URL of the first page visited in the session. |
| `session_landing_page_title` | Dimension | Title of the first page visited in the session. |
| `session_language` | Dimension | Language recorded for the session. |
| `session_number` | Dimension | Sequence number of the session for the user. |
| `session_source` | Dimension | Traffic source for the session. |
| `session_start_timestamp` | Dimension | Timestamp of the first event in the session. |
| `session_type` | Dimension | Classification of the session (New vs Returning). |
| `transaction_id` | Dimension | Unique identifier for the transaction (Order ID). |
| `user_campaign` | Dimension | Original acquisition campaign for the user. |
| `user_campaign_click_id` | Dimension | Original acquisition click ID for the user. |
| `user_campaign_content` | Dimension | Original acquisition campaign content. |
| `user_campaign_id` | Dimension | Original acquisition campaign ID. |
| `user_campaign_term` | Dimension | Original acquisition campaign term. |
| `user_channel_grouping` | Dimension | Original acquisition channel grouping. |
| `user_city` | Dimension | User's city at the time of first acquisition. |
| `user_country` | Dimension | User's country at the time of first acquisition. |
| `user_date` | Dimension | Date the user was first seen. |
| `user_device_type` | Dimension | Device type used at first acquisition. |
| `user_id` | Dimension | Business-level unique user identifier. |
| `user_language` | Dimension | User language recorded at acquisition. |
| `user_source` | Dimension | Original source of acquisition. |
| `user_type` | Dimension | User type classification (New vs Returning). |
| :--- | :--- | :--- |
| Field | Type | Description |

</details>

</br>

[View SQL code](ec_transactions.sql)


### Products
Aggregates ecommerce data at product level. 

<details><summary>Output fields</summary>

| `add_payment_info` | Metric | Total number of sessions where payment information was added. |
| `add_shipping_info` | Metric | Total number of sessions where shipping information was added. |
| `add_to_cart` | Metric | Total number of sessions with at least one add_to_cart event. |
| `add_to_wishlist` | Metric | Total number of sessions with at least one add_to_wishlist event. |
| `begin_checkout` | Metric | Total number of sessions where the checkout process was started. |
| `client_id` | Dimension | Unique identifier for the client/browser. |
| `creative_name` | Dimension | Name of the marketing creative associated with the event. |
| `creative_slot` | Dimension | The slot or position of the marketing creative. |
| `cross_domain_session` | Dimension | Indicates if the session is cross-domain. |
| `event_date` | Dimension | The date the event occurred. |
| `event_name` | Dimension | The name of the interaction event. |
| `event_origin` | Dimension | The origin of the event. |
| `hour_and_minute` | Dimension | Hour and minute of the event. |
| `item_affiliation` | Dimension | The store or branch where the transaction occurred. |
| `item_brand` | Dimension | The brand associated with the item in the transaction. |
| `item_category` | Dimension | The primary category of the item. |
| `item_category_2` | Dimension | The second level category of the item. |
| `item_category_3` | Dimension | The third level category of the item. |
| `item_category_4` | Dimension | The fourth level category of the item. |
| `item_category_5` | Dimension | The fifth level category of the item. |
| `item_coupon` | Dimension | Coupon code specifically applied to an individual item. |
| `item_discount` | Metric | The monetary discount applied to the item. |
| `item_id` | Dimension | Unique identifier (SKU) for the product item. |
| `item_list_id` | Dimension | ID of the list in which the item was presented. |
| `item_list_name` | Dimension | Name of the list in which the item was presented. |
| `item_name` | Dimension | Legal or commercial name of the product item. |
| `item_quantity_added_to_cart` | Metric | Total quantity of this item added to the cart. |
| `item_quantity_purchased` | Metric | Total quantity of this item purchased in the transaction. |
| `item_quantity_refunded` | Metric | Total quantity of this item refunded in the transaction. |
| `item_quantity_removed_from_cart` | Metric | Total quantity of this item removed from the cart. |
| `item_revenue_purchased` | Metric | Gross revenue generated by the sale of this item. |
| `item_revenue_refunded` | Metric | Total value refunded for this specific item. |
| `item_variant` | Metric | Specific variant of the item (e.g., size or color). |
| `list_id` | Dimension | The ID of the product list. |
| `list_name` | Dimension | The name of the product list. |
| `new_user_client_id` | Dimension | Client ID if this is the user's first session, else null. |
| `promotion_id` | Dimension | The unique ID of the promotion applied. |
| `promotion_name` | Dimension | The commercial name of the promotion applied. |
| `purchase_id` | Dimension | The unique ID of the purchase transaction. |
| `refund_id` | Dimension | The unique ID of the refund transaction. |
| `remove_from_cart` | Metric | Total number of sessions with at least one remove_from_cart event. |
| `remove_from_wishlist` | Metric | Total number of sessions with at least one remove_from_wishlist event. |
| `returning_user_client_id` | Dimension | Client ID if this is not the user's first session, else null. |
| `select_item` | Metric | Total number of sessions where an item was selected. |
| `select_promotion` | Metric | Total number of sessions where a promotion was selected. |
| `session_browser_name` | Dimension | Browser name recorded at session start. |
| `session_campaign` | Dimension | Acquisition campaign for the session. |
| `session_campaign_click_id` | Dimension | Campaign click ID for the session. |
| `session_campaign_content` | Dimension | Campaign content for the session. |
| `session_campaign_id` | Dimension | Campaign ID for the session. |
| `session_campaign_term` | Dimension | Campaign term for the session. |
| `session_channel_grouping` | Dimension | Acquisition channel grouping for the session. |
| `session_city` | Dimension | City detected for the session. |
| `session_country` | Dimension | Country detected for the session. |
| `session_date` | Dimension | The date the session started. |
| `session_device_type` | Dimension | Primary device type detected for the session. |
| `session_end_timestamp` | Dimension | Timestamp of the last activity in the session. |
| `session_exit_page_category` | Dimension | Category of the last page visited in the session. |
| `session_exit_page_location` | Dimension | URL of the last page visited in the session. |
| `session_exit_page_title` | Dimension | Title of the last page visited in the session. |
| `session_hostname` | Dimension | Hostname recorded for the session. |
| `session_id` | Dimension | Unique identifier for the session. |
| `session_landing_page_category` | Dimension | Category of the first page visited in the session. |
| `session_landing_page_location` | Dimension | URL of the first page visited in the session. |
| `session_landing_page_title` | Dimension | Title of the first page visited in the session. |
| `session_language` | Dimension | Language recorded for the session. |
| `session_number` | Dimension | Sequence number of the session for the user. |
| `session_source` | Dimension | Traffic source for the session. |
| `session_start_timestamp` | Dimension | Timestamp of the first event in the session. |
| `session_type` | Dimension | Classification of the session (New vs Returning). |
| `transaction_id` | Dimension | Unique identifier for the transaction (Order ID). |
| `unique_item_purchases` | Metric | Number of unique product items in the transaction. |
| `unique_item_refunds` | Metric | Number of unique product items refunded. |
| `user_campaign` | Dimension | Original acquisition campaign for the user. |
| `user_campaign_click_id` | Dimension | Original acquisition click ID for the user. |
| `user_campaign_content` | Dimension | Original acquisition campaign content. |
| `user_campaign_id` | Dimension | Original acquisition campaign ID. |
| `user_campaign_term` | Dimension | Original acquisition campaign term. |
| `user_channel_grouping` | Dimension | Original acquisition channel grouping. |
| `user_city` | Dimension | User's city at the time of first acquisition. |
| `user_country` | Dimension | User's country at the time of first acquisition. |
| `user_date` | Dimension | Date the user was first seen. |
| `user_device_type` | Dimension | Device type used at first acquisition. |
| `user_id` | Dimension | Business-level unique user identifier. |
| `user_language` | Dimension | User language recorded at acquisition. |
| `user_source` | Dimension | Original source of acquisition. |
| `user_type` | Dimension | User type classification (New vs Returning). |
| `view_cart` | Metric | Total number of sessions where the cart was viewed. |
| `view_item` | Metric | Total number of sessions where an item was viewed. |
| `view_item_list` | Metric | Total number of sessions where an item list was viewed. |
| `view_promotion` | Metric | Total number of sessions where a promotion was viewed. |
| :--- | :--- | :--- |
| Field | Type | Description |

</details>

</br>

[View SQL code](ec_products.sql)


### Shopping stages open funnel
Aggregates event data at shopping stages level, regardless of where the user started.

<details><summary>Output fields</summary>

| Field | Type | Description |
| :--- | :--- | :--- |
| `client_id` | Dimension | Unique identifier for the client/browser. |
| `client_id_next_step` | Dimension | The client identifier for the next step in the funnel. |
| `cross_domain_session` | Dimension | Indicates if the session is cross-domain. |
| `event_date` | Dimension | The date the event occurred. |
| `new_user_client_id` | Dimension | Client ID if this is the user's first session, else null. |
| `returning_user_client_id` | Dimension | Client ID if this is not the user's first session, else null. |
| `session_browser_name` | Dimension | Browser name recorded at session start. |
| `session_campaign` | Dimension | Acquisition campaign for the session. |
| `session_channel_grouping` | Dimension | Acquisition channel grouping for the session. |
| `session_city` | Dimension | City detected for the session. |
| `session_country` | Dimension | Country detected for the session. |
| `session_date` | Dimension | The date the session started. |
| `session_device_type` | Dimension | Primary device type detected for the session. |
| `session_duration_sec` | Metric | Total duration of the session in seconds. |
| `session_end_timestamp` | Dimension | Timestamp of the last activity in the session. |
| `session_exit_page_category` | Dimension | Category of the last page visited in the session. |
| `session_exit_page_location` | Dimension | URL of the last page visited in the session. |
| `session_exit_page_title` | Dimension | Title of the last page visited in the session. |
| `session_hostname` | Dimension | Hostname recorded for the session. |
| `session_id` | Dimension | Unique identifier for the session. |
| `session_id_next_step` | Dimension | The session identifier for the next step in the funnel. |
| `session_landing_page_category` | Dimension | Category of the first page visited in the session. |
| `session_landing_page_location` | Dimension | URL of the first page visited in the session. |
| `session_landing_page_title` | Dimension | Title of the first page visited in the session. |
| `session_language` | Dimension | Language recorded for the session. |
| `session_number` | Dimension | Sequence number of the session for the user. |
| `session_source` | Dimension | Traffic source for the session. |
| `session_start_timestamp` | Dimension | Timestamp of the first event in the session. |
| `status` | Dimension | The status of the step in the funnel. |
| `step_index` | Dimension | The index of the current step in the funnel. |
| `step_index_next_step` | Dimension | The index of the next step in the funnel. |
| `step_index_next_step_real` | Dimension | The real index of the next step captured in the funnel. |
| `step_name` | Dimension | The name of the current step in the funnel. |
| `user_campaign` | Dimension | Original acquisition campaign for the user. |
| `user_channel_grouping` | Dimension | Original acquisition channel grouping. |
| `user_city` | Dimension | User's city at the time of first acquisition. |
| `user_country` | Dimension | User's country at the time of first acquisition. |
| `user_date` | Dimension | Date the user was first seen. |
| `user_device_type` | Dimension | Device type used at first acquisition. |
| `user_id` | Dimension | Business-level unique user identifier. |
| `user_language` | Dimension | User language recorded at acquisition. |
| `user_source` | Dimension | Original source of acquisition. |
| `user_tld_source` | Dimension | Source of acquisition with TLD. |
| `user_type` | Dimension | User type classification (New vs Returning). |

</details>

</br>

[View SQL code](ec_shopping_stages_open_funnel.sql)


### Shopping stages closed funnel
Aggregates event data at shopping stages level, for users who follow a specific, linear sequence of steps.

<details><summary>Output fields</summary>

| Field | Type | Description |
| :--- | :--- | :--- |
| `client_id` | Dimension | Unique identifier for the client/browser. |
| `client_id_next_step` | Dimension | The client identifier for the next step in the funnel. |
| `cross_domain_session` | Dimension | Indicates if the session is cross-domain. |
| `event_date` | Dimension | The date the event occurred. |
| `new_user_client_id` | Dimension | Client ID if this is the user's first session, else null. |
| `returning_user_client_id` | Dimension | Client ID if this is not the user's first session, else null. |
| `session_browser_name` | Dimension | Browser name recorded at session start. |
| `session_campaign` | Dimension | Acquisition campaign for the session. |
| `session_channel_grouping` | Dimension | Acquisition channel grouping for the session. |
| `session_city` | Dimension | City detected for the session. |
| `session_country` | Dimension | Country detected for the session. |
| `session_date` | Dimension | The date the session started. |
| `session_device_type` | Dimension | Primary device type detected for the session. |
| `session_duration_sec` | Metric | Total duration of the session in seconds. |
| `session_end_timestamp` | Dimension | Timestamp of the last activity in the session. |
| `session_exit_page_category` | Dimension | Category of the last page visited in the session. |
| `session_exit_page_location` | Dimension | URL of the last page visited in the session. |
| `session_exit_page_title` | Dimension | Title of the last page visited in the session. |
| `session_hostname` | Dimension | Hostname recorded for the session. |
| `session_id` | Dimension | Unique identifier for the session. |
| `session_id_next_step` | Dimension | The session identifier for the next step in the funnel. |
| `session_landing_page_category` | Dimension | Category of the first page visited in the session. |
| `session_landing_page_location` | Dimension | URL of the first page visited in the session. |
| `session_landing_page_title` | Dimension | Title of the first page visited in the session. |
| `session_language` | Dimension | Language recorded for the session. |
| `session_number` | Dimension | Sequence number of the session for the user. |
| `session_source` | Dimension | Traffic source for the session. |
| `session_start_timestamp` | Dimension | Timestamp of the first event in the session. |
| `session_tld_source` | Dimension | Session source including TLD. |
| `step_name` | Dimension | The name of the current step in the funnel. |
| `user_campaign` | Dimension | Original acquisition campaign for the user. |
| `user_channel_grouping` | Dimension | Original acquisition channel grouping. |
| `user_city` | Dimension | User's city at the time of first acquisition. |
| `user_country` | Dimension | User's country at the time of first acquisition. |
| `user_date` | Dimension | Date the user was first seen. |
| `user_device_type` | Dimension | Device type used at first acquisition. |
| `user_id` | Dimension | Business-level unique user identifier. |
| `user_id_next_step` | Dimension | The user identifier for the next step in the funnel. |
| `user_language` | Dimension | User language recorded at acquisition. |
| `user_source` | Dimension | Original source of acquisition. |
| `user_tld_source` | Dimension | Source of acquisition with TLD. |
| `user_type` | Dimension | User type classification (New vs Returning). |

</details>

</br>

[View SQL code](ec_shopping_stages_closed_funnel.sql)


### Events debug
Provides a flattened view of events with raw data for debugging and troubleshooting.

[View SQL code](events_debug.sql)

<details><summary>Output fields</summary>

| Field | Type | Description |
| :--- | :--- | :--- |
| `client_id` | Dimension | Unique identifier for the client/browser. |
| `session_id` | Dimension | Unique identifier for the session. |
| `page_date` | Dimension | The date the page was viewed. |
| `page_id` | Dimension | Unique identifier for the page view. |
| `page_view_number` | Dimension | Sequential number of the page view in the session. |
| `page_data` | Dimension | Array of custom page parameters. |
| `event_date` | Dimension | The date the event occurred. |
| `event_datetime` | Dimension | Exact date and time of the event. |
| `event_timestamp` | Metric | Unix timestamp (ms) of the event. |
| `event_origin` | Dimension | The origin of the event (e.g., Web, Server). |
| `event_name` | Dimension | The name of the interaction event. |
| `event_number` | Dimension | Sequential number of the event in the session. |
| `event_id` | Dimension | Unique identifier for the event. |
| `event_data` | Dimension | Array of custom event parameters. |
| `ecommerce` | Dimension | Structured ecommerce data in JSON format. |
| `datalayer` | Dimension | Current JSON value of the dataLayer. |
| `consent_data` | Dimension | Array of consent parameters. |

</details>



### Consents
Aggregates consent data at session level.

[View SQL code](consents.sql)

<details><summary>Output fields</summary>

| Field | Type | Description |
| :--- | :--- | :--- |
| `client_id` | Dimension | Unique identifier for the client/browser. |
| `consent_name` | Dimension | The name of the consent category (e.g., ad_storage, analytics_storage). |
| `consent_state` | Dimension | The current state of the consent (e.g., granted, denied). |
| `consent_value_int_accepted` | Metric | Integer flag (1/0) indicating if the consent was accepted. |
| `consent_value_int_denied` | Metric | Integer flag (1/0) indicating if the consent was denied. |
| `consent_value_string` | Dimension | The raw string value of the consent expressed. |
| `cross_domain_session` | Dimension | Indicates if the session is cross-domain. |
| `engaged_session` | Metric | Count of sessions that met the engagement criteria. |
| `new_user_client_id` | Dimension | Client ID if this is the user's first session, else null. |
| `returning_user_client_id` | Dimension | Client ID if this is not the user's first session, else null. |
| `session_browser_name` | Dimension | Browser name recorded at session start. |
| `session_campaign` | Dimension | Acquisition campaign for the session. |
| `session_channel_grouping` | Dimension | Acquisition channel grouping for the session. |
| `session_city` | Dimension | City detected for the session. |
| `session_country` | Dimension | Country detected for the session. |
| `session_date` | Dimension | The date the session started. |
| `session_device_type` | Dimension | Primary device type detected for the session. |
| `session_duration_sec` | Metric | Total duration of the session in seconds. |
| `session_exit_page_category` | Dimension | Category of the last page visited in the session. |
| `session_exit_page_location` | Dimension | URL of the last page visited in the session. |
| `session_exit_page_title` | Dimension | Title of the last page visited in the session. |
| `session_hostname` | Dimension | Hostname recorded for the session. |
| `session_id` | Dimension | Unique identifier for the session. |
| `session_id_consent_expressed` | Dimension | Session ID where a consent choice was explicitly expressed. |
| `session_id_consent_mode_not_present` | Dimension | Session ID where Consent Mode was not detected. |
| `session_id_consent_not_expressed` | Dimension | Session ID where no consent choice was expressed. |
| `session_landing_page_category` | Dimension | Category of the first page visited in the session. |
| `session_landing_page_location` | Dimension | URL of the first page visited in the session. |
| `session_landing_page_title` | Dimension | Title of the first page visited in the session. |
| `session_language` | Dimension | Language recorded for the session. |
| `session_number` | Dimension | Sequence number of the session for the user. |
| `session_source` | Dimension | Traffic source for the session. |
| `session_start_timestamp` | Dimension | Timestamp of the first event in the session. |
| `user_campaign` | Dimension | Original acquisition campaign for the user. |
| `user_channel_grouping` | Dimension | Original acquisition channel grouping. |
| `user_country` | Dimension | User's country at the time of first acquisition. |
| `user_date` | Dimension | Date the user was first seen. |
| `user_device_type` | Dimension | Device type used at first acquisition. |
| `user_id` | Dimension | Business-level unique user identifier. |
| `user_language` | Dimension | User language recorded at acquisition. |
| `user_source` | Dimension | Original source of acquisition. |
| `user_type` | Dimension | User type classification (New vs Returning). |

</details>



## Reporting fields
This table illustrates the fields available across different table functions, allowing you to easily identify common data points and specific metrics for each report.

<details><summary>Output Fields Matrix</summary>

| Field name | Field type | Value type | Events | Users | Sessions | Pages | Transactions | Products | Open_Funnel | Closed_Funnel | Events_Debug | Consents |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `ad_personalization` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `ad_personalization_accepted_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `ad_personalization_denied_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `ad_storage` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `ad_storage_accepted_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `ad_storage_denied_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `ad_user_data` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `ad_user_data_accepted_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `ad_user_data_denied_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `add_payment_info` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `add_shipping_info` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `add_to_cart` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `add_to_wishlist` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `analytics_storage` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `analytics_storage_accepted_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `analytics_storage_denied_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `avg_order_value` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `avg_purchase_value` | Metric | float |  | X |  |  |  |  |  |  |  |  |
| `avg_refund_value` | Metric | float |  | X | X |  |  |  |  |  |  |  |
| `begin_checkout` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `browser_language` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `browser_name` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `browser_version` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `campaign` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `campaign_click_id` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `campaign_content` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `campaign_id` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `campaign_term` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `channel_grouping` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `city` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `client_id` | Dimension | string | X | X | X | X | X | X | X | X | X | X |
| `client_id_next_step` | Dimension | string |  |  |  |  |  |  | X | X |  |  |
| `consent_expressed` | Dimension | string |  |  | X |  |  |  |  |  |  |  |
| `consent_name` | Dimension | string |  |  |  |  |  |  |  |  |  | X |
| `consent_state` | Dimension | string |  |  |  |  |  |  |  |  |  | X |
| `consent_timestamp` | Dimension | string |  |  | X |  |  |  |  |  |  |  |
| `consent_type` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `consent_value_int_accepted` | Metric | float |  |  |  |  |  |  |  |  |  | X |
| `consent_value_int_denied` | Metric | float |  |  |  |  |  |  |  |  |  | X |
| `consent_value_string` | Dimension | string |  |  |  |  |  |  |  |  |  | X |
| `content_length_in_kb` | Metric | integer | X |  |  |  |  |  |  |  |  |  |
| `country` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `creative_name` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `creative_slot` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `cross_domain_id` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `cross_domain_session` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `cs_container_id` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `cs_hostname` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `cs_tag_id` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `cs_tag_name` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `customer_client_id` | Dimension | string |  | X |  |  |  |  |  |  |  |  |
| `customer_status` | Dimension | string |  | X |  |  |  |  |  |  |  |  |
| `customer_type` | Dimension | string |  | X |  |  |  |  |  |  |  |  |
| `datalayer` | Dimension | JSON | X |  |  |  |  |  |  |  | X |  |
| `days_from_first_purchase` | Metric | integer |  | X |  |  |  |  |  |  |  |  |
| `days_from_first_to_last_visit` | Metric | integer | X | X |  |  |  |  |  |  |  |  |
| `days_from_first_visit` | Metric | integer | X | X |  |  |  |  |  |  |  |  |
| `days_from_last_purchase` | Metric | integer |  | X |  |  |  |  |  |  |  |  |
| `days_from_last_visit` | Metric | integer | X | X |  |  |  |  |  |  |  |  |
| `delay_in_millis` | Metric | integer | X |  |  |  |  |  |  |  |  |  |
| `delay_in_sec` | Metric | integer | X |  |  |  |  |  |  |  |  |  |
| `device_model` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `device_type` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `device_vendor` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `duplicate_purchase` | Metric | integer |  |  |  |  | X |  |  |  |  |  |
| `duplicate_refund` | Metric | integer |  |  |  |  | X |  |  |  |  |  |
| `ecommerce` | Dimension | JSON | X |  |  |  |  |  |  |  | X |  |
| `engaged_session` | Metric | integer |  |  | X |  |  |  |  |  |  | X |
| `engaged_sessions_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `event_data` | Dimension | Array | X |  |  |  |  |  |  |  | X |  |
| `event_date` | Dimension | string | X |  |  |  | X | X | X | X | X |  |
| `event_datetime` | Dimension | timestamp |  |  |  |  |  |  |  |  | X |  |
| `event_id` | Dimension | string | X |  |  |  |  |  |  |  | X |  |
| `event_name` | Dimension | string | X |  |  |  | X | X |  |  | X |  |
| `event_number` | Dimension | integer | X |  |  |  |  |  |  |  | X |  |
| `event_origin` | Dimension | string | X |  |  |  |  |  |  |  | X |  |
| `event_timestamp` | Metric | integer | X |  |  |  | X | X |  |  | X |  |
| `event_type` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `first_purchase_timestamp` | Dimension | string |  | X |  |  |  |  |  |  |  |  |
| `functionality_storage` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `functionality_storage_accepted_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `functionality_storage_denied_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `hour_and_minute` | Dimension | string |  |  |  |  | X | X |  |  |  |  |
| `item_affiliation` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `item_brand` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `item_category` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `item_category_2` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `item_category_3` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `item_category_4` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `item_category_5` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `item_coupon` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `item_discount` | Metric | float |  |  |  |  |  | X |  |  |  |  |
| `item_id` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `item_list_id` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `item_list_name` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `item_name` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `item_quantity_added_to_cart` | Metric | integer |  |  |  |  |  | X |  |  |  |  |
| `item_quantity_purchased` | Metric | integer |  | X |  |  |  | X |  |  |  |  |
| `item_quantity_refunded` | Metric | integer |  | X |  |  |  | X |  |  |  |  |
| `item_quantity_removed_from_cart` | Metric | integer |  |  |  |  |  | X |  |  |  |  |
| `item_revenue_net_refund` | Metric | float |  |  |  |  |  | X |  |  |  |  |
| `item_revenue_purchased` | Metric | float |  |  |  |  |  | X |  |  |  |  |
| `item_revenue_refunded` | Metric | float |  |  |  |  |  | X |  |  |  |  |
| `item_variant` | Metric | integer |  |  |  |  |  | X |  |  |  |  |
| `last_purchase_timestamp` | Dimension | string |  | X |  |  |  |  |  |  |  |  |
| `list_id` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `list_name` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `new_customer_client_id` | Dimension | string |  | X |  |  |  |  |  |  |  |  |
| `new_session` | Metric | integer | X |  | X |  |  |  |  |  |  |  |
| `new_sessions_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `new_user_client_id` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `os_name` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `os_version` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_category` | Dimension | string | X |  |  | X |  |  |  |  |  |  |
| `page_data` | Dimension | Array | X |  |  |  |  |  |  |  | X |  |
| `page_date` | Dimension | string | X |  |  | X |  |  |  |  | X |  |
| `page_extension` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_fragment` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_hostname` | Dimension | string | X |  |  | X |  |  |  |  |  |  |
| `page_hostname_protocol` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_id` | Dimension | string | X |  |  | X |  |  |  |  | X |  |
| `page_language` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_load_time_sec` | Dimension | float |  |  |  | X |  |  |  |  |  |  |
| `page_load_timestamp` | Dimension | integer | X |  |  | X |  |  |  |  |  |  |
| `page_location` | Dimension | string | X |  |  | X |  |  |  |  |  |  |
| `page_query` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_referrer` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_status_code` | Dimension | integer | X |  |  | X |  |  |  |  |  |  |
| `page_title` | Dimension | string | X |  |  | X |  |  |  |  |  |  |
| `page_unload_timestamp` | Dimension | integer | X |  |  | X |  |  |  |  |  |  |
| `page_view` | Metric | integer |  | X | X | X |  |  |  |  |  |  |
| `page_view_number` | Dimension | integer | X |  |  | X |  |  |  |  | X |  |
| `page_view_per_session` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `personalization_storage` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `personalization_storage_accepted_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |
| `personalization_storage_denied_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |
| `processing_event_timestamp` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `promotion_id` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `promotion_name` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `purchase` | Metric | integer |  | X | X |  | X |  |  |  |  |  |
| `purchase_coupon` | Dimension | string |  |  |  |  | X |  |  |  |  |  |
| `purchase_currency` | Dimension | string |  |  |  |  | X |  |  |  |  |  |
| `purchase_id` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `purchase_net_refund` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `purchase_revenue` | Metric | float |  | X | X |  | X |  |  |  |  |  |
| `purchase_shipping` | Metric | float |  |  | X |  | X |  |  |  |  |  |
| `purchase_tax` | Metric | float |  |  | X |  | X |  |  |  |  |  |
| `refund` | Metric | integer |  | X | X |  | X |  |  |  |  |  |
| `refund_coupon` | Dimension | string |  |  |  |  | X |  |  |  |  |  |
| `refund_currency` | Dimension | string |  |  |  |  | X |  |  |  |  |  |
| `refund_id` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `refund_revenue` | Metric | float |  | X | X |  | X |  |  |  |  |  |
| `refund_shipping` | Metric | float |  |  | X |  | X |  |  |  |  |  |
| `refund_tax` | Metric | float |  |  | X |  | X |  |  |  |  |  |
| `remove_from_cart` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `remove_from_wishlist` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `respect_consent_mode` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `returning_customer_client_id` | Dimension | string |  | X |  |  |  |  |  |  |  |  |
| `returning_session` | Metric | integer | X |  | X |  |  |  |  |  |  |  |
| `returning_sessions_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `returning_user_client_id` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `revenue_net_refund` | Metric | float |  | X | X |  |  |  |  |  |  |  |
| `screen_size` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `search_term` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `security_storage` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `security_storage_accepted_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `security_storage_denied_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `select_item` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `select_promotion` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `session_ad_personalization` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `session_ad_storage` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `session_ad_user_data` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `session_analytics_storage` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `session_browser_name` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_campaign` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_campaign_click_id` | Dimension | string | X |  | X | X | X | X |  |  | X |  |
| `session_campaign_content` | Dimension | string | X |  | X | X | X | X |  |  | X |  |
| `session_campaign_id` | Dimension | string | X |  | X |  | X | X |  |  | X |  |
| `session_campaign_term` | Dimension | string | X |  | X | X | X | X |  |  | X |  |
| `session_channel_grouping` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_city` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_country` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_data` | Dimension | array | X |  |  |  |  |  |  |  |  |  |
| `session_date` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_device_type` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_duration_sec` | Metric | integer | X | X | X |  |  |  | X | X |  | X |
| `session_end_timestamp` | Dimension | string | X |  |  |  | X | X | X | X | X |  |
| `session_exit_page_category` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_exit_page_location` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_exit_page_title` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_functionality_storage` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `session_hostname` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_id` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_id_consent_expressed` | Dimension | string |  |  |  |  |  |  |  |  |  | X |
| `session_id_consent_mode_not_present` | Dimension | string |  |  |  |  |  |  |  |  |  | X |
| `session_id_consent_not_expressed` | Dimension | string |  |  |  |  |  |  |  |  |  | X |
| `session_id_next_step` | Dimension | string |  |  |  |  |  |  | X | X |  |  |
| `session_landing_page_category` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_landing_page_location` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_landing_page_title` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_language` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_number` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_personalization_storage` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `session_security_storage` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `session_source` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_source_cleaned` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `session_start_timestamp` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_tld_source` | Dimension | string | X |  |  |  |  |  | X | X |  |  |
| `session_type` | Dimension | string | X |  |  | X | X | X |  |  | X |  |
| `session_with_purchase` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `session_with_refund` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `sessions` | Metric | integer |  | X |  |  |  |  |  |  |  |  |
| `sessions_per_user` | Metric | float |  | X |  |  |  |  |  |  |  |  |
| `shipping_net_refund` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `source` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `source_cleaned` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `ss_container_id` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `ss_hostname` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `ss_tag_id` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `ss_tag_name` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `status` | Dimension | string |  |  |  |  |  |  | X |  |  |  |
| `step_index` | Dimension | string |  |  |  |  |  |  | X |  |  |  |
| `step_index_next_step` | Dimension | string |  |  |  |  |  |  | X |  |  |  |
| `step_index_next_step_real` | Dimension | string |  |  |  |  |  |  | X |  |  |  |
| `step_name` | Dimension | string |  |  |  |  |  |  | X | X |  |  |
| `tax_net_refund` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `time_on_page` | Metric | float | X |  |  | X |  |  |  |  |  |  |
| `tld_source` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `total_events` | Metric | integer |  | X |  |  |  |  |  |  |  |  |
| `total_page_load_time` | Metric | integer | X |  |  |  |  |  |  |  |  |  |
| `transaction_id` | Dimension | string |  |  |  |  | X | X |  |  |  |  |
| `unique_item_purchases` | Metric | integer |  |  |  |  |  | X |  |  |  |  |
| `unique_item_refunds` | Metric | integer |  |  |  |  |  | X |  |  |  |  |
| `user_agent` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `user_campaign` | Dimension | string | X | X | X | X | X | X | X | X | X | X |
| `user_campaign_click_id` | Dimension | string | X | X | X | X | X | X |  |  | X |  |
| `user_campaign_content` | Dimension | string | X | X | X | X | X | X |  |  | X |  |
| `user_campaign_id` | Dimension | string | X | X | X | X | X | X |  |  | X |  |
| `user_campaign_term` | Dimension | string | X | X | X | X | X | X |  |  | X |  |
| `user_channel_grouping` | Dimension | string | X | X | X | X | X | X | X | X | X | X |
| `user_city` | Dimension | string | X | X | X | X | X | X | X | X | X |  |
| `user_country` | Dimension | string | X | X | X | X | X | X | X | X | X | X |
| `user_data` | Dimension | Array | X |  |  |  |  |  |  |  |  |  |
| `user_date` | Dimension | string | X | X | X | X | X | X | X | X | X | X |
| `user_device_type` | Dimension | string | X | X | X | X | X | X | X | X | X | X |
| `user_first_session_timestamp` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `user_id` | Dimension | string | X | X | X | X | X | X | X | X | X | X |
| `user_id_next_step` | Dimension | string |  |  |  |  |  |  |  | X |  |  |
| `user_language` | Dimension | string | X | X | X | X | X | X | X | X | X | X |
| `user_last_session_timestamp` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `user_source` | Dimension | string | X | X | X | X | X | X | X | X | X | X |
| `user_source_cleaned` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `user_tld_source` | Dimension | string | X |  |  |  |  |  | X | X |  |  |
| `user_type` | Dimension | string | X | X | X | X | X | X | X | X | X | X |
| `user_with_purchase` | Metric | integer |  | X |  |  |  |  |  |  |  |  |
| `user_with_refund` | Metric | integer |  | X |  |  |  |  |  |  |  |  |
| `view_cart` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `view_item` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `view_item_list` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `view_promotion` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `viewport_size` | Metric | integer | X |  |  |  |  |  |  |  |  |  |

</details>

</br>


## Data Governance and Maintenance
Below are SQL templates to help you manage data integrity and comply with privacy regulations.

To comply with GDPR "Right to be Forgotten" requests, data must be removed from both the historical timeline (BigQuery) and the real-time snapshots (Firestore).


### Delete user data script
You can use the provided [`Users deletion tool`](users-deletion-tool.py) Python script to handle both deletions in a single command. 

This is the recommended method.

### Manual user data deletion
If you prefer manual deletion, please remove data from both BigQuery and Firestore.

#### BigQuery user data deletion
Use the following DML statement to delete all records for a specific client_id. This will remove all user events.

```sql
# Delete all records for a specific client_id
DELETE FROM `project.dataset.events_raw`
WHERE client_id = 'USER_CLIENT_ID';
```

#### Firestore user data deletion
Locate the document in the `users` collection where the Document ID matches the `client_id` and delete it. This will remove the user profile and all associated session summaries.


### Data Health Check
To ensure your data pipeline is healthy and active, use this query to monitor the event volume per day. Sudden drops might indicate configuration issues in GTM or Cloud Run.

```sql
# Monitor daily event volume
SELECT 
  event_date, 
  count(distinct client_id) as users,
  count(distinct session_id) as sessions,
  count(distinct page_id) as page_views,
  count(distinct event_id) as events,
FROM `tom-moretti.nameless_analytics.events_raw`
WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY 1 
ORDER BY 1 DESC;
```

---

Reach me at: [Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_tables) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)

