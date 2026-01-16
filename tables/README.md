# Nameless Analytics | Reporting Tables

The Nameless Analytics Reporting Tables are a set of tables and table functions in BigQuery where user, session, and event data are stored and processed.

For an overview of how Nameless Analytics works [start from here](https://github.com/nameless-analytics/nameless-analytics/#high-level-data-flow).



## Table of Contents
- [Tables](#tables)
  - [Create tables](#create-tables)
  - [Events raw table](#events-raw-table)
  - [Dates table](#dates-table)
- [Table functions](#table-functions)
  - [Reporting fields](#reporting-fields)
  - [Create table functions](#create-table-functions)
  - [Events](#events)
  - [Users](#users)
  - [Sessions](#sessions)
  - [Pages](#pages)
  - [Transactions](#transactions)
  - [Products](#products)
  - [Shopping stages open funnel](#shopping-stages-open-funnel)
  - [Shopping stages closed funnel](#shopping-stages-closed-funnel)
  - [GTM performances](#gtm-performances)
  - [Consents](#consents)




## Tables
Tables are the foundational storage layer of Nameless Analytics, designed to capture and preserve every user interaction in its raw, unprocessed form. These tables serve as the single source of truth for all analytics data, storing event-level information with complete historical fidelity.

The architecture consists of two core tables: the **Events raw table** (`events_raw`), which stores all user, session, page, event, ecommerce, consent, and GTM performance data in a denormalized structure optimized for both write performance and analytical queries; and the **Dates table** (`calendar_dates`), a utility dimension table that provides comprehensive date attributes for time-based analysis and reporting.

All data is partitioned by date and clustered by key dimensions to ensure optimal query performance and cost efficiency when analyzing large datasets.

### Create tables
<details><summary>To create the tables use this DML statement.</summary>
  
```sql
# NAMELESS ANALYTICS

# Project settings
declare project_name string default 'project_name';  -- Change this
declare dataset_name string default 'dataset_name'; -- Change this
declare dataset_location string default 'dataset_location'; -- Change this

# Tables
declare main_table_name string default 'events_raw';
declare dates_table_name string default 'calendar_dates';

# Paths
declare main_dataset_path string default CONCAT('`', project_name, '.', dataset_name, '`');
declare main_table_path string default CONCAT('`', project_name, '.', dataset_name, '.', main_table_name,'`');
declare dates_table_path string default CONCAT('`', project_name, '.', dataset_name, '.', dates_table_name,'`');


# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


# Enable BigQuery advanced runtime (for more info https://cloud.google.com/bigquery/docs/advanced-runtime)
# Enables a more advanced query execution engine that automatically improves performance and efficiency for complex analytical queries
declare enable_bigquery_advanced_runtime string default format(
  """
    ALTER PROJECT `%s`
    SET OPTIONS (
      `region-%s.query_runtime` = 'advanced' # default null
    );
  """
, project_name, dataset_location);


# Main dataset (for more info https://cloud.google.com/bigquery/docs/datasets#sql)
declare main_dataset_sql string default format(
  """
    create schema if not exists %s
    options (
      # default_kms_key_name = 'KMS_KEY_NAME',
      # default_partition_expiration_days = PARTITION_EXPIRATION,
      # default_table_expiration_days = TABLE_EXPIRATION,
      # max_time_travel_hours = HOURS, # default 168 hours => 7 days 
      # storage_billing_model = BILLING_MODEL # Phytical or logical (default)  
      description = 'Nameless Analytics',
      location = '%s'
    );
  """
, main_dataset_path, dataset_location);


# Main table
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
            json JSON OPTIONS (description = 'User data parameter JSON value')
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
            json JSON OPTIONS (description = 'Session data parameter JSON value')
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
            json JSON OPTIONS (description = 'Page data parameter JSON value')
          > OPTIONS (description = 'Page data parameter value name')
        >
      > OPTIONS (description = 'Page data'),

      event_name STRING NOT NULL OPTIONS (description = 'Event name'),
      event_id STRING NOT NULL OPTIONS (description = 'Event ID'),
      event_date DATE NOT NULL OPTIONS (description = 'Event date'),
      event_timestamp int NOT NULL OPTIONS (description = 'Event timestamp'),
      event_origin STRING NOT NULL OPTIONS (description = 'Event origin'),
      event_data ARRAY<
        STRUCT<
          name STRING OPTIONS (description = 'Event data parameter name'),
          value STRUCT<
            string STRING OPTIONS (description = 'Event data parameter string value'),
            int INT64 OPTIONS (description = 'Event data parameter int number value'),
            float FLOAT64 OPTIONS (description = 'Event data parameter float number value'),
            json JSON OPTIONS (description = 'Event data parameter JSON value')
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
            int INT64 OPTIONS (description = 'GTM execution parameter int number value')
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


# Dates table
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


# Create tables 
execute immediate enable_bigquery_advanced_runtime;
execute immediate main_dataset_sql;
execute immediate main_table_sql;
execute immediate dates_table_sql;
```
</details>


### Events raw table
This main table is partitioned by `event_date` and clustered by `user_date`, `session_date`, `page_date`, and `event_name`.

<details><summary>Output Fields Summary</summary>

| Field name      | Type    | Mode     | Description                                |
|-----------------|---------|----------|--------------------------------------------|
| client_id       | STRING  | REQUIRED | Client ID.                                 |
| user_date       | DATE    | REQUIRED | User date.                                 |
| user_data       | RECORD  | REPEATED | User data.                                 |
| session_id      | STRING  | REQUIRED | Session ID.                                |
| session_date    | DATE    | REQUIRED | Session date.                              |
| session_data    | RECORD  | REPEATED | Session data.                              |
| page_id         | STRING  | REQUIRED | Page ID.                                   |
| page_date       | DATE    | REQUIRED | Page date.                                 |
| page_data       | RECORD  | REPEATED | Page data.                                 |
| event_name      | STRING  | REQUIRED | Event name.                                |
| event_id        | STRING  | REQUIRED | Event ID.                                  |
| event_date      | DATE    | REQUIRED | Date of the request.                       |
| event_timestamp | INTEGER | REQUIRED | Insertion timestamp of the event.          |
| event_origin    | STRING  | REQUIRED | "Website" or "Streaming protocol".          |
| event_data      | RECORD  | REPEATED | Event data.                                |
| ecommerce       | JSON    | NULLABLE | Ecommerce object.                          |
| datalayer       | JSON    | NULLABLE | Current `dataLayer` value.                 |
| consent_data    | RECORD  | REPEATED | Consent data.                              |
| gtm_data        | RECORD  | REPEATED | GTM performance and execution data.        |

</details>

### Dates table
This table is partitioned by `date` and clustered by `month_name` and `day_name`.

<details><summary>Output Fields Summary</summary>

| Field name         | Type    | Mode     | Description                                                     |
|--------------------|---------|----------|---------------------------------------------------------------- |
| date               | DATE    | REQUIRED | The date value.                                                 |
| year               | INTEGER | NULLABLE | Year extracted from the date.                                   |
| quarter            | INTEGER | NULLABLE | Quarter of the year (1-4) extracted from the date.              |
| month_number       | INTEGER | NULLABLE | Month number of the year (1-12) extracted from the date.        |
| month_name         | STRING  | NULLABLE | Full name of the month (e.g., January) extracted from the date. |
| week_number_sunday | INTEGER | NULLABLE | Week number of the year, starting on Sunday.                    |
| week_number_monday | INTEGER | NULLABLE | Week number of the year, starting on Monday.                    |
| day_number         | INTEGER | NULLABLE | Day number of the month (1-31).                                 |
| day_name           | STRING  | NULLABLE | Full name of the day of the week (e.g., Monday).                |
| day_of_week_number | INTEGER | NULLABLE | Day of the week number (1 for Monday, 7 for Sunday).            |
| is_weekend         | BOOLEAN | NULLABLE | True if the day is a Saturday or Sunday.                        |

</details>



## Table functions
Table functions are predefined SQL queries that simplify data analysis by transforming raw event data into structured, easy-to-use formats for common reporting needs.

Unlike other systems, Nameless Analytics reporting functions are designed to work directly on the `events_raw` table as the single source of truth. By leveraging BigQuery **Window Functions**. This approach ensures that reports always reflect the most up-to-date state of the data without the need for complex ETL processes or intermediate staging tables.

### Reporting fields
This table illustrates the fields available across different table functions, allowing you to easily identify common data points and specific metrics for each report.

<details><summary>Output Fields Matrix</summary>

| Field Name | Events | Users | Sessions | Pages | Transactions | Products | Open Funnel | Closed Funnel | GTM Performances | Consents |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `ad_personalization` | X | | | | | | | | | X |
| `ad_personalization_accepted_percentage` | | | X | | | | | | | |
| `ad_personalization_denied_percentage` | | | X | | | | | | | |
| `ad_storage` | X | | | | | | | | | X |
| `ad_storage_accepted_percentage` | | | X | | | | | | | |
| `ad_storage_denied_percentage` | | | X | | | | | | | |
| `ad_user_data` | X | | | | | | | | | X |
| `ad_user_data_accepted_percentage` | | | X | | | | | | | |
| `ad_user_data_denied_percentage` | | | X | | | | | | | |
| `add_payment_info` | | | X | | | X | | | | |
| `add_shipping_info` | | | X | | | X | | | | |
| `add_to_cart` | | | X | | | X | | | | |
| `add_to_wishlist` | | | X | | | X | | | | |
| `analytics_storage` | X | | | | | | | | | X |
| `analytics_storage_accepted_percentage` | | | X | | | | | | | |
| `analytics_storage_denied_percentage` | | | X | | | | | | | |
| `avg_order_value` | | | X | | | | | | | |
| `avg_purchase_value` | | X | | | | | | | | |
| `avg_refund_value` | | X | | | | | | | | |
| `begin_checkout` | | | X | | | X | | | | |
| `browser_language` | X | | | | | | | | | |
| `browser_name` | X | | | | | | | | | |
| `browser_version` | X | | | | | | | | | |
| `campaign` | X | | | | | | | | | |
| `campaign_click_id` | X | | | | | | | | | |
| `campaign_content` | X | | | | | | | | | |
| `campaign_id` | X | | | | | | | | | |
| `campaign_term` | X | | | | | | | | | |
| `channel_grouping` | X | | | | | | | | | |
| `city` | X | | | | | | | | | |
| `client_id` | X | X | X | X | X | X | X | X | X | X |
| `client_id_next_step` | | | | | | | X | X | | |
| `consent_expressed` | | | X | | | | | | | |
| `consent_timestamp` | | | X | | | | | | | |
| `consent_type` | X | | | | | | | | | X |
| `content_length` | X | | | | | | | | X | |
| `country` | X | | | | | | | | | |
| `creative_name` | | | | | | X | | | | |
| `creative_slot` | | | | | | X | | | | |
| `cross_domain_id` | X | | | | | | | | | |
| `cross_domain_session` | X | | X | X | X | X | X | | X | |
| `cs_container_id` | X | | | | | | | | X | |
| `cs_hostname` | X | | | | | | | | X | |
| `cs_tag_id` | X | | | | | | | | | |
| `cs_tag_name` | X | | | | | | | | | |
| `customer_type` | | X | | | | | | | | |
| `customers` | | X | | | | | | | | |
| `dataLayer` / `datalayer` | X | | | | | | | | X | |
| `days_from_first_purchase` | | X | | | | | | | | |
| `days_from_first_to_last_visit` | X | X | | | | | | | | |
| `days_from_first_visit` | X | X | | | | | | | | |
| `days_from_last_purchase` | | X | | | | | | | | |
| `days_from_last_visit` | X | X | | | | | | | | |
| `delay_in_milliseconds` | | | | | | | | | X | |
| `delay_in_seconds` | | | | | | | | | X | |
| `device_model` | X | | | | | | | | | |
| `device_type` | X | | | | | | | | | |
| `device_vendor` | X | | | | | | | | | |
| `ecommerce` | X | | | | | | | | X | |
| `engaged_session` | | | X | | | | | | | |
| `engaged_sessions_percentage` | | | X | | | | | | | |
| `event_data` | X | | | | | | | | X | |
| `event_date` | X | | | | X | X | X | | X | X |
| `event_datetime` | | | | | | | | | X | |
| `event_id` | X | | | | | | | | X | |
| `event_name` | X | | | | X | X | | | X | X |
| `event_number` | X | | | | | | | | | |
| `event_origin` | X | | | | | | | | X | |
| `event_timestamp` | X | | | | X | X | | | X | X |
| `event_type` | X | | | | | | | | | |
| `first_session` | | | X | | | | | | | |
| `functionality_storage` | X | | | | | | | | | X |
| `functionality_storage_accepted_percentage` | | | X | | | | | | | |
| `functionality_storage_denied_percentage` | | | X | | | | | | | |
| `gtm_data` | X | | | | | | | | | |
| `hit_number` | | | | | | | | | X | |
| `is_customer` | | X | | | | | | | | |
| `item_affiliation` | | | | | | X | | | | |
| `item_brand` | | | | | | X | | | | |
| `item_category` | | | | | | X | | | | |
| `item_category_2/3/4/5` | | | | | | X | | | | |
| `item_coupon` | | | | | | X | | | | |
| `item_discount` | | | | | | X | | | | |
| `item_id` | | | | | | X | | | | |
| `item_list_id` | | | | | | X | | | | |
| `item_list_name` | | | | | | X | | | | |
| `item_name` | | | | | | X | | | | |
| `item_purchase_revenue` | | | | | | X | | | | |
| `item_quantity_added_to_cart` | | | | | | X | | | | |
| `item_quantity_purchased` | | X | | | | X | | | | |
| `item_quantity_refunded` | | X | | | | X | | | | |
| `item_quantity_removed_from_cart` | | | | | | X | | | | |
| `item_refund_revenue` | | | | | | X | | | | |
| `item_revenue_net_refund` | | | | | | X | | | | |
| `item_unique_purchases` | | | | | | X | | | | |
| `item_variant` | | | | | | X | | | | |
| `list_id` | | | | | | X | | | | |
| `list_name` | | | | | | X | | | | |
| `new_customers` | | X | | | | | | | | |
| `new_session` | X | | X | X | | | | | | |
| `new_sessions_percentage` | | | X | | | | | | | |
| `new_user` | X | | X | X | X | X | X | | X | |
| `new_user_client_id` | | X | | | | | | | | |
| `new_users_percentage` | | | X | | | | | | | |
| `os_name` | X | | | | | | | | | |
| `os_version` | X | | | | | | | | | |
| `page_category` | X | | | X | | | | | | |
| `page_data` | X | | | | | | | | X | |
| `page_date` | X | | | X | | | | | | |
| `page_extension` | X | | | | | | | | | |
| `page_fragment` | X | | | | | | | | | |
| `page_hostname` | X | | | X | | | | | | |
| `page_hostname_protocol` | X | | | | | | | | | |
| `page_id` | X | | | X | | | | | | |
| `page_language` | X | | | | | | | | | |
| `page_load_datetime` | | | | X | | | | | | |
| `page_load_time_sec` | | | | X | | | | | | |
| `page_load_timestamp` | X | | | | | | | | | |
| `page_location` | X | | | X | | | | | | |
| `page_query` | X | | | | | | | | | |
| `page_referrer` | X | | | | | | | | | |
| `page_render_time` | X | | | X | | | | | | |
| `page_status_code` | X | | | X | | | | | | |
| `page_title` | X | | | X | | | | | | |
| `page_unload_datetime` | | | | X | | | | | | |
| `page_unload_timestamp` | X | | | | | | | | | |
| `page_view` | | X | X | X | | | | | | |
| `page_view_number` | X | | | X | | | | | | |
| `page_view_per_session` | | | X | | | | | | | |
| `personalization_storage` | X | | | | | | | | | X |
| `processing_event_timestamp` | X | | | | | | | | X | |
| `promotion_id` | | | | | | X | | | | |
| `promotion_name` | | | | | | X | | | | |
| `purchase` | | X | X | | X | | | | | |
| `purchase_net_refund` | | | X | | X | | | | | |
| `purchase_revenue` | | X | X | | X | | | | | |
| `purchase_shipping` | | | X | | X | | | | | |
| `purchase_tax` | | | X | | X | | | | | |
| `refund` | | X | X | | X | | | | | |
| `refund_revenue` | | X | X | | X | | | | | |
| `refund_shipping` | | | X | | X | | | | | |
| `refund_tax` | | | X | | X | | | | | |
| `remove_from_cart` | | | X | | | X | | | | |
| `respect_consent_mode` | X | | | | | | | | | X |
| `returning_customers` | | X | | | | | | | | |
| `returning_session` | X | | X | X | | | | | | |
| `returning_sessions_percentage` | | | X | | | | | | | |
| `returning_user` | X | | X | X | X | X | X | | X | |
| `returning_user_client_id` | | X | | | | | | | | |
| `returning_users_percentage` | | | X | | | | | | | |
| `revenue_net_refund` | | X | X | | X | | | | | |
| `screen_size` | X | | | | | | | | | |
| `search_term` | X | | | | | | | | | |
| `security_storage` | X | | | | | | | | | X |
| `security_storage_accepted_percentage` | | | X | | | | | | | |
| `security_storage_denied_percentage` | | | X | | | | | | | |
| `select_item` | | | X | | | X | | | | |
| `select_promotion` | | | | | | X | | | | |
| `session_ad_personalization` | | | X | | | | | | | |
| `session_ad_storage` | | | X | | | | | | | |
| `session_ad_user_data` | | | X | | | | | | | |
| `session_analytics_storage` | | | X | | | | | | | |
| `session_browser_name` | X | | X | X | X | X | X | | X | |
| `session_campaign` | X | | X | X | X | X | X | | X | |
| `session_campaign_click_id` | X | | X | X | | | | | | |
| `session_campaign_content` | X | | X | X | | | | | | |
| `session_campaign_id` | X | | | | | | | | | |
| `session_campaign_term` | X | | X | X | | | | | | |
| `session_channel_grouping` | X | | X | X | X | X | X | X | X | |
| `session_conversion_rate` | | | X | | | | | | | |
| `session_country` | X | | X | X | X | X | X | X | X | |
| `session_data` | X | | | | | | | | | |
| `session_date` | X | | X | X | | | X | | X | |
| `session_device_type` | X | | X | X | X | X | X | X | X | |
| `session_duration_sec` | X | X | X | X | | | X | | X | |
| `session_end_timestamp` | X | | | | | | X | | X | |
| `session_exit_page_category` | X | | X | X | | | X | | X | |
| `session_exit_page_location` | X | | X | X | | | X | | X | |
| `session_exit_page_title` | X | | X | X | | | X | | X | |
| `session_functionality_storage` | | | X | | | | | | | |
| `session_hostname` | X | | X | X | | | X | | X | |
| `session_id` | X | | X | X | X | X | X | X | X | X |
| `session_id_next_step` | | | | | | | X | | | |
| `session_landing_page_category` | X | | X | X | | | X | | X | |
| `session_landing_page_location` | X | | X | X | | | X | | X | |
| `session_landing_page_title` | X | | X | X | | | X | | X | |
| `session_language` | X | | X | X | X | X | X | | X | |
| `session_number` | X | | X | X | X | X | X | | X | |
| `session_personalization_storage` | | | X | | | | | | | |
| `session_security_storage` | | | X | | | | | | | |
| `session_source` | X | | X | X | X | X | X | X | X | |
| `session_start_timestamp` | X | | X | X | X | X | X | | X | |
| `session_tld_source` | X | | X | X | X | X | X | | X | |
| `session_value` | | | X | | | | | | | |
| `sessions` | | X | | | | | | | | |
| `sessions_per_user` | | | X | | | | | | | |
| `shipping_net_refund` | | | X | | X | | | | | |
| `source` | X | | | | | | | | | |
| `ss_container_id` | X | | | | | | | | X | |
| `ss_hostname` | X | | | | | | | | X | |
| `ss_tag_id` | X | | | | | | | | | |
| `ss_tag_name` | X | | | | | | | | | |
| `step_index` | | | | | | | | X | | |
| `step_name` | | | | | | | X | X | | |
| `tax_net_refund` | | | X | | X | | | | | |
| `time_on_page` | X | | | X | | | | | | |
| `time_to_dom_complete` | X | | | X | | | | | | |
| `time_to_dom_interactive` | X | | | X | | | | | | |
| `tld_source` | X | | | | | | | | | |
| `total_page_load_time` | X | | | | | | | | | |
| `transaction_coupon` | | | | | X | | | | | |
| `transaction_currency` | | | | | X | | | | | |
| `transaction_id` | | | | | X | X | | | | |
| `user_agent` | X | | | | | | | | | |
| `user_campaign` | X | X | X | X | X | X | X | | X | |
| `user_campaign_click_id` | X | X | X | X | | | | | | |
| `user_campaign_content` | X | X | X | X | | | | | | |
| `user_campaign_id` | X | | | | | | | | | |
| `user_campaign_term` | X | X | X | X | | | | | | |
| `user_channel_grouping` | X | X | X | X | X | X | X | | X | |
| `user_conversion_rate` | | | X | | | | | | | |
| `user_country` | X | X | X | X | X | X | X | | X | |
| `user_data` | X | | | | | | | | | |
| `user_date` | X | X | X | X | X | X | X | | X | |
| `user_device_type` | X | X | X | X | X | X | X | | X | |
| `user_first_session_timestamp` | X | | | | | | | | | |
| `user_id` | X | | X | | X | X | X | | X | |
| `user_id_next_step` | | | | | | | X | | | |
| `user_language` | X | X | X | X | X | X | X | | X | |
| `user_last_session_timestamp` | X | | | | | | | | | |
| `user_source` | X | X | X | X | X | X | X | | X | |
| `user_tld_source` | X | X | X | X | X | X | X | | X | |
| `user_type` | X | X | X | X | X | X | X | X | X | |
| `user_value` | | | X | | | | | | | |
| `view_cart` | | | X | | | X | | | | |
| `view_item` | | | X | | | X | | | | |
| `view_item_list` | | | X | | | X | | | | |
| `view_promotion` | | | | | | X | | | | |
| `viewport_size` | X | | | | | | | | | |

</details>


### Create table functions
<details><summary>To create the table functions use this DML statement.</summary>

```sql
# Run the SQL scripts in this directory to create the table functions.
```
</details>


### Events
Flattens raw event data and extracts custom parameters, making it easier to analyze specific interaction metrics. Event data can be extracted at various levels.

#### User level
Returns users acquired in the selected time period.

```sql
select * from `project.nameless_analytics.events` (start_date, end_date, 'User')
```

#### Session level: 
Returns sessions that started in the selected time period.

```sql
select * from `project.nameless_analytics.events`(start_date, end_date, 'Session')
```

#### Page level
Returns pages visited in the selected time period.

```sql
select * from `project.nameless_analytics.events`(start_date, end_date, 'Page')
```

#### Event level
Returns events that occurred in the selected time period.

```sql
select * from `project.nameless_analytics.events`(start_date, end_date, 'Event')
```

[View source Code](events.sql)

<details><summary>Output Fields Summary</summary>

| Field name | Type | Description |
| :--- | :--- | :--- |
| **USER DATA** | | |
| `user_date` | DATE | Date of the user's first visit |
| `user_id` | STRING | Persistent user identifier (if provided) |
| `client_id` | STRING | Unique identifier for the browser/device |
| `user_type` | STRING | "new_user" or "returning_user" |
| `new_user` | STRING | Client ID if it's a new user, else null |
| `returning_user` | STRING | Client ID if it's a returning user, else null |
| `user_first_session_timestamp` | INTEGER | Timestamp of the first session |
| `user_last_session_timestamp` | INTEGER | Timestamp of the most recent session |
| `days_from_first_to_last_visit` | INTEGER | Days between first and last visit |
| `days_from_first_visit` | INTEGER | Days since first visit |
| `days_from_last_visit` | INTEGER | Days since last visit |
| `user_channel_grouping` | STRING | Acquisition channel grouping |
| `user_source` | STRING | Acquisition source |
| `user_tld_source` | STRING | Top Level Domain of the source |
| `user_campaign` | STRING | Acquisition campaign name |
| `user_campaign_id` | STRING | Acquisition campaign ID |
| `user_campaign_click_id` | STRING | Acquisition campaign click ID (e.g. gclid) |
| `user_campaign_term` | STRING | Acquisition campaign term |
| `user_campaign_content` | STRING | Acquisition campaign content |
| `user_device_type` | STRING | Device type (mobile, desktop, tablet) |
| `user_country` | STRING | User's country |
| `user_language` | STRING | User's language |
| **SESSION DATA** | | |
| `session_date` | DATE | Date of the session |
| `session_id` | STRING | Unique identifier for the session |
| `session_number` | INTEGER | Incremental session count for the user |
| `cross_domain_session` | STRING | Flag for cross-domain sessions |
| `session_start_timestamp` | INTEGER | Session start timestamp |
| `session_end_timestamp` | INTEGER | Session end timestamp |
| `session_duration_sec` | INTEGER | Session duration in seconds |
| `new_session` | INTEGER | 1 if new session, else 0 |
| `returning_session` | INTEGER | 1 if returning session, else 0 |
| `session_channel_grouping` | STRING | Session channel grouping |
| `session_source` | STRING | Session source |
| `session_tld_source` | STRING | Session TLD source |
| `session_campaign` | STRING | Session campaign name |
| `session_campaign_id` | STRING | Session campaign ID |
| `session_campaign_click_id` | STRING | Session campaign click ID |
| `session_campaign_term` | STRING | Session campaign term |
| `session_campaign_content` | STRING | Session campaign content |
| `session_device_type` | STRING | Session device type |
| `session_country` | STRING | Session country |
| `session_language` | STRING | Session language |
| `session_browser_name` | STRING | Browser name |
| `session_hostname` | STRING | Hostname of the session |
| `session_landing_page_category` | STRING | Category of the landing page |
| `session_landing_page_location` | STRING | Landing page URL |
| `session_landing_page_title` | STRING | Landing page title |
| `session_exit_page_category` | STRING | Category of the exit page |
| `session_exit_page_location` | STRING | Exit page URL |
| `session_exit_page_title` | STRING | Exit page title |
| **PAGE DATA** | | |
| `page_date` | DATE | Date of the page view |
| `page_id` | STRING | Unique page view ID |
| `page_view_number` | INTEGER | Sequential page view number |
| `page_load_timestamp` | INTEGER | Timestamp when page loaded |
| `page_unload_timestamp` | INTEGER | Timestamp when page unloaded |
| `page_category` | STRING | Page category |
| `page_title` | STRING | Page title |
| `page_language` | STRING | Page language |
| `page_hostname_protocol` | STRING | Protocol (http/https) |
| `page_hostname` | STRING | Hostname |
| `page_location` | STRING | Full URL |
| `page_fragment` | STRING | URL fragment (#) |
| `page_query` | STRING | URL query string (?) |
| `page_extension` | STRING | URL file extension |
| `page_referrer` | STRING | HTTP Referrer |
| `page_status_code` | INTEGER | HTTP Status code |
| `time_on_page` | INTEGER | Time spent on page in seconds |
| **EVENT DATA** | | |
| `event_date` | DATE | Date of the event |
| `event_timestamp` | INTEGER | Microsecond timestamp |
| `event_name` | STRING | Event name |
| `event_id` | STRING | Unique event ID |
| `event_number` | INTEGER | Sequential event number |
| `event_type` | STRING | Type of event |
| `channel_grouping` | STRING | Event channel grouping |
| `source` | STRING | Event source |
| `tld_source` | STRING | Event TLD source |
| `campaign` | STRING | Event campaign |
| `campaign_id` | STRING | Event campaign ID |
| `campaign_click_id` | STRING | Event campaign click ID |
| `campaign_term` | STRING | Event campaign term |
| `campaign_content` | STRING | Event campaign content |
| `browser_name` | STRING | Browser name |
| `browser_version` | STRING | Browser version |
| `browser_language` | STRING | Browser language |
| `viewport_size` | STRING | Viewport dimensions |
| `user_agent` | STRING | User Agent string |
| `device_type` | STRING | Device type at event level |
| `device_model` | STRING | Device model |
| `device_vendor` | STRING | Device vendor |
| `os_name` | STRING | OS name |
| `os_version` | STRING | OS version |
| `screen_size` | STRING | Screen resolution |
| `country` | STRING | Event country |
| `city` | STRING | Event city |
| `cross_domain_id` | STRING | Cross domain ID parameter |
| `time_to_dom_interactive` | INTEGER | Performance metric (ms) |
| `page_render_time` | INTEGER | Performance metric (ms) |
| `time_to_dom_complete` | INTEGER | Performance metric (ms) |
| `total_page_load_time` | INTEGER | Performance metric (ms) |
| `search_term` | STRING | Search query (for search events) |
| **ECOMMERCE** | | |
| `ecommerce` | JSON | Ecommerce object |
| **DATALAYER DATA** | | |
| `datalayer` | JSON | DataLayer state |
| **CONSENT DATA** | | |
| `consent_type` | STRING | Consent update type |
| `respect_consent_mode` | STRING | Flag for consent mode respect |
| `ad_user_data` | STRING | Consent status |
| `ad_personalization` | STRING | Consent status |
| `ad_storage` | STRING | Consent status |
| `analytics_storage` | STRING | Consent status |
| `functionality_storage` | STRING | Consent status |
| `personalization_storage` | STRING | Consent status |
| `security_storage` | STRING | Consent status |
| **REQUEST DATA** | | |
| `event_origin` | STRING | Origin of the event |
| `cs_hostname` | STRING | Client-side hostname |
| `cs_container_id` | STRING | Client-side GTM container ID |
| `cs_tag_name` | STRING | Client-side tag name |
| `cs_tag_id` | INTEGER | Client-side tag ID |
| `ss_hostname` | STRING | Server-side hostname |
| `ss_container_id` | STRING | Server-side GTM container ID |
| `ss_tag_name` | STRING | Server-side tag name |
| `ss_tag_id` | INTEGER | Server-side tag ID |
| `processing_event_timestamp` | INTEGER | Server-side processing timestamp |
| `content_length` | INTEGER | Payload size |
| **RAW ARRAYS** | | |
| `user_data` | ARRAY | Raw user data array |
| `session_data` | ARRAY | Raw session data array |
| `page_data` | ARRAY | Raw page data array |
| `event_data` | ARRAY | Raw event data array |
| `gtm_data` | ARRAY | Raw GTM data array |

</details>


### Users
Aggregates data at the user level, calculating lifecycle metrics like total sessions, first/last seen dates, and lifetime values.
[View source Code](users.sql)

<details><summary>Output Fields Summary</summary>

| Field name | Type | Description |
| :--- | :--- | :--- |
| **USER DATA** | | |
| `user_date` | DATE | Date of the user's first visit |
| `client_id` | STRING | Unique identifier for the user |
| `user_channel_grouping` | STRING | Acquisition channel grouping |
| `user_source` | STRING | Acquisition source |
| `user_tld_source` | STRING | Acquisition TLD source |
| `user_campaign` | STRING | Acquisition campaign |
| `user_campaign_click_id` | STRING | Acquisition campaign click ID |
| `user_campaign_term` | STRING | Acquisition campaign term |
| `user_campaign_content` | STRING | Acquisition campaign content |
| `user_device_type` | STRING | Device type used |
| `user_country` | STRING | User's country |
| `user_language` | STRING | User's language |
| `user_type` | STRING | "new_user" or "returning_user" |
| `new_user_client_id` | STRING | Client ID if new user |
| `returning_user_client_id` | STRING | Client ID if returning user |
| `days_from_first_to_last_visit` | INTEGER | Total lifecycle duration in days |
| `days_from_first_visit` | INTEGER | Days since first visit |
| `days_from_last_visit` | INTEGER | Days since last visit |
| **ACTIVITY & ECOMMERCE** | | |
| `is_customer` | STRING | "Customer" or "Not customer" |
| `customer_type` | STRING | "Not customer", "New customer", "Returning customer" |
| `customers` | INTEGER | 1 if the user is a customer |
| `new_customers` | INTEGER | 1 if the user became a customer in this period |
| `returning_customers` | INTEGER | 1 if the user was already a customer |
| `sessions` | INTEGER | Total number of sessions |
| `session_duration_sec` | FLOAT | Average session duration |
| `page_view` | INTEGER | Total page views |
| `days_from_first_purchase` | INTEGER | Days since first purchase |
| `days_from_last_purchase` | INTEGER | Days since last purchase |
| `purchase` | INTEGER | Total purchases count |
| `refund` | INTEGER | Total refunds count |
| `item_quantity_purchased` | INTEGER | Total items purchased |
| `item_quantity_refunded` | INTEGER | Total items refunded |
| `purchase_revenue` | FLOAT | Total revenue generated |
| `refund_revenue` | FLOAT | Total revenue refunded |
| `revenue_net_refund` | FLOAT | Revenue minus refunds |
| `avg_purchase_value` | FLOAT | Average order value |
| `avg_refund_value` | FLOAT | Average refund value |

</details>


### Sessions
Groups events into individual sessions, calculating duration, bounce rates, and landing/exit pages.
[View source Code](sessions.sql)

<details><summary>Output Fields Summary</summary>

| Field name | Type | Description |
| :--- | :--- | :--- |
| **USER DATA** | | |
| `user_date` | DATE | Date of the user's first visit |
| `user_id` | STRING | Persistent user identifier |
| `client_id` | STRING | Unique identifier for the user |
| `user_type` | STRING | "new_user" or "returning_user" |
| `new_user` | STRING | Client ID if new user |
| `new_users_percentage` | FLOAT | Percentage of new users |
| `returning_user` | STRING | Client ID if returning user |
| `returning_users_percentage` | FLOAT | Percentage of returning users |
| `user_channel_grouping` | STRING | Acquisition channel grouping |
| `user_source` | STRING | Acquisition source |
| `user_tld_source` | STRING | Acquisition TLD source |
| `user_campaign` | STRING | Acquisition campaign |
| `user_campaign_click_id` | STRING | Acquisition campaign click ID |
| `user_campaign_term` | STRING | Acquisition campaign term |
| `user_campaign_content` | STRING | Acquisition campaign content |
| `user_device_type` | STRING | Device type used |
| `user_country` | STRING | User's country |
| `user_language` | STRING | User's language |
| `user_conversion_rate` | FLOAT | User conversion rate |
| `user_value` | FLOAT | Average user value |
| **SESSION DATA** | | |
| `session_date` | DATE | Date of the session |
| `session_id` | STRING | Unique identifier for the session |
| `session_number` | INTEGER | Incremental session count for the user |
| `first_session` | STRING | 'true' if it is the first session |
| `cross_domain_session` | STRING | Flag for cross-domain sessions |
| `session_start_timestamp` | INTEGER | Session start timestamp |
| `session_duration_sec` | INTEGER | Session duration in seconds |
| `new_session` | INTEGER | 1 if new session, else 0 |
| `new_sessions_percentage` | FLOAT | Percentage of new sessions |
| `returning_session` | INTEGER | 1 if returning session, else 0 |
| `returning_sessions_percentage` | FLOAT | Percentage of returning sessions |
| `engaged_session` | INTEGER | 1 if engaged session, else 0 |
| `engaged_sessions_percentage` | FLOAT | Percentage of engaged sessions |
| `session_channel_grouping` | STRING | Session channel grouping |
| `session_source` | STRING | Session source |
| `session_tld_source` | STRING | Session TLD source |
| `session_campaign` | STRING | Session campaign name |
| `session_campaign_click_id` | STRING | Session campaign click ID |
| `session_campaign_term` | STRING | Session campaign term |
| `session_campaign_content` | STRING | Session campaign content |
| `session_device_type` | STRING | Session device type |
| `session_browser_name` | STRING | Browser name |
| `session_country` | STRING | Session country |
| `session_language` | STRING | Session language |
| `session_landing_page_category` | STRING | Landing page category |
| `session_landing_page_location` | STRING | Landing page URL |
| `session_landing_page_title` | STRING | Landing page title |
| `session_exit_page_category` | STRING | Exit page category |
| `session_exit_page_location` | STRING | Exit page URL |
| `session_exit_page_title` | STRING | Exit page title |
| `session_hostname` | STRING | Hostname |
| `session_conversion_rate` | FLOAT | Session conversion rate |
| `session_value` | FLOAT | Average session value |
| `sessions_per_user` | FLOAT | Average sessions per user |
| `page_view_per_session` | FLOAT | Average page views per session |
| **EVENTS** | | |
| `page_view` | INTEGER | Total pages viewed |
| **ECOMMERCE DATA** | | |
| `view_item_list` | INTEGER | View item list count |
| `select_item` | INTEGER | Select item count |
| `view_item` | INTEGER | View item count |
| `add_to_wishlist` | INTEGER | Add to wishlist count |
| `add_to_cart` | INTEGER | Add to cart count |
| `remove_from_cart` | INTEGER | Remove from cart count |
| `view_cart` | INTEGER | View cart count |
| `begin_checkout` | INTEGER | Begin checkout count |
| `add_shipping_info` | INTEGER | Add shipping info count |
| `add_payment_info` | INTEGER | Add payment info count |
| `purchase` | INTEGER | Purchase count |
| `refund` | INTEGER | Refund count |
| `purchase_revenue` | FLOAT | Revenue from purchases |
| `purchase_shipping` | FLOAT | Shipping revenue |
| `purchase_tax` | FLOAT | Tax revenue |
| `avg_order_value` | FLOAT | Average Order Value |
| `refund_revenue` | FLOAT | Total refunded revenue |
| `refund_shipping` | FLOAT | Refunded shipping |
| `refund_tax` | FLOAT | Refunded tax |
| `purchase_net_refund` | INTEGER | Net purchases (minus refunds) |
| `revenue_net_refund` | FLOAT | Net revenue (minus refunds) |
| `shipping_net_refund` | FLOAT | Net shipping |
| `tax_net_refund` | FLOAT | Net tax |
| **CONSENT DATA** | | |
| `consent_timestamp` | INTEGER | Timestamp of consent |
| `consent_expressed` | STRING | Whether consent was expressed |
| `session_ad_user_data` | INTEGER | Ad user data consent count |
| `ad_user_data_accepted_percentage` | FLOAT | % Ad user data accepted |
| `ad_user_data_denied_percentage` | FLOAT | % Ad user data denied |
| `session_ad_personalization` | INTEGER | Ad personalization consent count |
| `ad_personalization_accepted_percentage` | FLOAT | % Ad personalization accepted |
| `ad_personalization_denied_percentage` | FLOAT | % Ad personalization denied |
| `session_ad_storage` | INTEGER | Ad storage consent count |
| `ad_storage_accepted_percentage` | FLOAT | % Ad storage accepted |
| `ad_storage_denied_percentage` | FLOAT | % Ad storage denied |
| `session_analytics_storage` | INTEGER | Analytics storage consent count |
| `analytics_storage_accepted_percentage` | FLOAT | % Analytics storage accepted |
| `analytics_storage_denied_percentage` | FLOAT | % Analytics storage denied |
| `session_functionality_storage` | INTEGER | Functionality storage consent count |
| `functionality_storage_accepted_percentage` | FLOAT | % Functionality storage accepted |
| `functionality_storage_denied_percentage` | FLOAT | % Functionality storage denied |
| `session_personalization_storage` | INTEGER | Personalization storage consent count |
| `session_security_storage` | INTEGER | Security storage consent count |
| `security_storage_accepted_percentage` | FLOAT | % Security storage accepted |
| `security_storage_denied_percentage` | FLOAT | % Security storage denied |

</details>


### Pages
Focuses on page-level performance, aggregating views, time on page, and navigation paths.
[View source Code](pages.sql)

<details><summary>Output Fields Summary</summary>

| Field name | Type | Description |
| :--- | :--- | :--- |
| **USER DATA** | | |
| `user_date` | DATE | Date of the user's first visit |
| `client_id` | STRING | Unique identifier for the user |
| `user_type` | STRING | "new_user" or "returning_user" |
| `new_user` | STRING | Client ID if new user |
| `returning_user` | STRING | Client ID if returning user |
| `user_channel_grouping` | STRING | Acquisition channel grouping |
| `user_source` | STRING | Acquisition source |
| `user_tld_source` | STRING | Acquisition TLD source |
| `user_campaign` | STRING | Acquisition campaign |
| `user_campaign_click_id` | STRING | Acquisition campaign click ID |
| `user_campaign_term` | STRING | Acquisition campaign term |
| `user_campaign_content` | STRING | Acquisition campaign content |
| `user_device_type` | STRING | Device type used |
| `user_country` | STRING | User's country |
| `user_language` | STRING | User's language |
| **SESSION DATA** | | |
| `session_date` | DATE | Date of the session |
| `session_id` | STRING | Unique identifier for the session |
| `session_number` | INTEGER | Incremental session count for the user |
| `cross_domain_session` | STRING | Flag for cross-domain sessions |
| `session_start_timestamp` | INTEGER | Session start timestamp |
| `session_duration_sec` | INTEGER | Session duration in seconds |
| `new_session` | INTEGER | 1 if new session, else 0 |
| `returning_session` | INTEGER | 1 if returning session, else 0 |
| `session_channel_grouping` | STRING | Session channel grouping |
| `session_source` | STRING | Session source |
| `session_tld_source` | STRING | Session TLD source |
| `session_campaign` | STRING | Session campaign name |
| `session_campaign_click_id` | STRING | Session campaign click ID |
| `session_campaign_term` | STRING | Session campaign term |
| `session_campaign_content` | STRING | Session campaign content |
| `session_device_type` | STRING | Session device type |
| `session_browser_name` | STRING | Browser name |
| `session_country` | STRING | Session country |
| `session_language` | STRING | Session language |
| `session_landing_page_category` | STRING | Landing page category |
| `session_landing_page_location` | STRING | Landing page URL |
| `session_landing_page_title` | STRING | Landing page title |
| `session_exit_page_category` | STRING | Exit page category |
| `session_exit_page_location` | STRING | Exit page URL |
| `session_exit_page_title` | STRING | Exit page title |
| `session_hostname` | STRING | Hostname |
| **PAGE DATA** | | |
| `page_date` | DATE | Date of the page activity |
| `page_id` | STRING | Unique page view ID |
| `page_view_number` | INTEGER | Sequential page number |
| `page_location` | STRING | Full URL location |
| `page_hostname` | STRING | Hostname |
| `page_title` | STRING | Title of the page |
| `page_category` | STRING | Category of the page |
| `page_load_datetime` | TIMESTAMP | Datetime of page load |
| `page_unload_datetime` | TIMESTAMP | Datetime of page unload |
| `time_on_page` | FLOAT | Time spent on page (seconds) |
| `time_to_dom_interactive` | FLOAT | Time to DOM interactive (seconds) |
| `page_render_time` | FLOAT | Page render time (seconds) |
| `time_to_dom_complete` | FLOAT | Time to DOM complete (seconds) |
| `page_load_time_sec` | FLOAT | Total load time (seconds) |
| `page_status_code` | INTEGER | HTTP Status Code |
| **EVENTS** | | |
| `page_view` | INTEGER | Total view count (agg) |

</details>


### Transactions
Extracts and structures ecommerce transaction data, including revenue, tax, and shipping details.
[View source Code](ec_transactions.sql)

<details><summary>Output Fields Summary</summary>

| Field name | Type | Description |
| :--- | :--- | :--- |
| **USER DATA** | | |
| `user_date` | DATE | Date of the user's first visit |
| `client_id` | STRING | Unique identifier for the user |
| `user_id` | STRING | Persistent user identifier |
| `user_channel_grouping` | STRING | Acquisition channel grouping |
| `user_source` | STRING | Acquisition source |
| `user_tld_source` | STRING | Acquisition TLD source |
| `user_campaign` | STRING | Acquisition campaign |
| `user_device_type` | STRING | Device type used |
| `user_country` | STRING | User's country |
| `user_language` | STRING | User's language |
| `user_type` | STRING | "new_user" or "returning_user" |
| `new_user` | STRING | Client ID if new user |
| `returning_user` | STRING | Client ID if returning user |
| **SESSION DATA** | | |
| `session_number` | INTEGER | Incremental session count for the user |
| `session_id` | STRING | Unique identifier for the session |
| `session_start_timestamp` | INTEGER | Session start timestamp |
| `session_channel_grouping` | STRING | Session channel grouping |
| `session_source` | STRING | Session source |
| `session_tld_source` | STRING | Session TLD source |
| `session_campaign` | STRING | Session campaign name |
| `cross_domain_session` | STRING | Flag for cross-domain sessions |
| `session_device_type` | STRING | Session device type |
| `session_country` | STRING | Session country |
| `session_language` | STRING | Session language |
| `session_browser_name` | STRING | Browser name |
| **EVENT DATA** | | |
| `event_date` | DATE | Event date |
| `event_name` | STRING | Event name |
| `event_timestamp` | TIMESTAMP | Event timestamp |
| **ECOMMERCE DATA** | | |
| `transaction_id` | STRING | Unique transaction ID |
| `purchase` | INTEGER | Purchase count |
| `refund` | INTEGER | Refund count |
| `transaction_currency` | STRING | Currency code |
| `transaction_coupon` | STRING | Coupon code |
| `purchase_revenue` | FLOAT | Revenue from purchases |
| `purchase_shipping` | FLOAT | Shipping revenue |
| `purchase_tax` | FLOAT | Tax revenue |
| `refund_revenue` | FLOAT | Total refunded revenue |
| `refund_shipping` | FLOAT | Refunded shipping |
| `refund_tax` | FLOAT | Refunded tax |
| `purchase_net_refund` | INTEGER | Net purchases (minus refunds) |
| `revenue_net_refund` | FLOAT | Net revenue (minus refunds) |
| `shipping_net_refund` | FLOAT | Net shipping |
| `tax_net_refund` | FLOAT | Net tax |

</details>


### Products
Provides a granular view of product performance, including views, add-to-carts, and purchases per SKU.
[View source Code](ec_products.sql)

<details><summary>Output Fields Summary</summary>

| Field name | Type | Description |
| :--- | :--- | :--- |
| **USER DATA** | | |
| `user_date` | DATE | Date of the user's first visit |
| `client_id` | STRING | Unique identifier for the user |
| `user_id` | STRING | Persistent user identifier |
| `user_channel_grouping` | STRING | Acquisition channel grouping |
| `user_source` | STRING | Acquisition source |
| `user_tld_source` | STRING | Acquisition TLD source |
| `user_campaign` | STRING | Acquisition campaign |
| `user_device_type` | STRING | Device type used |
| `user_country` | STRING | User's country |
| `user_language` | STRING | User's language |
| `user_type` | STRING | "new_user" or "returning_user" |
| `new_user` | STRING | Client ID if new user |
| `returning_user` | STRING | Client ID if returning user |
| **SESSION DATA** | | |
| `session_number` | INTEGER | Incremental session count for the user |
| `session_id` | STRING | Unique identifier for the session |
| `session_start_timestamp` | INTEGER | Session start timestamp |
| `session_channel_grouping` | STRING | Session channel grouping |
| `session_source` | STRING | Session source |
| `session_tld_source` | STRING | Session TLD source |
| `session_campaign` | STRING | Session campaign name |
| `cross_domain_session` | STRING | Flag for cross-domain sessions |
| `session_device_type` | STRING | Session device type |
| `session_country` | STRING | Session country |
| `session_language` | STRING | Session language |
| `session_browser_name` | STRING | Browser name |
| **EVENT DATA** | | |
| `event_date` | DATE | Event date |
| `event_name` | STRING | Event name |
| `event_timestamp` | TIMESTAMP | Event timestamp |
| **ECOMMERCE DATA** | | |
| `transaction_id` | STRING | Transaction ID |
| `list_id` | STRING | List ID (deprecated?) |
| `list_name` | STRING | List Name (deprecated?) |
| `item_list_id` | STRING | List ID |
| `item_list_name` | STRING | List Name |
| `item_affiliation` | STRING | Item affiliation |
| `item_coupon` | STRING | Item coupon |
| `item_discount` | FLOAT | Item discount |
| `creative_name` | STRING | Creative name |
| `creative_slot` | STRING | Creative slot |
| `promotion_id` | STRING | Promotion ID |
| `promotion_name` | STRING | Promotion name |
| `item_brand` | STRING | Brand |
| `item_id` | STRING | Product ID |
| `item_name` | STRING | Product Name |
| `item_variant` | STRING | Variant |
| `item_category` | STRING | Category Level 1 |
| `item_category_2` | STRING | Category Level 2 |
| `item_category_3` | STRING | Category Level 3 |
| `item_category_4` | STRING | Category Level 4 |
| `item_category_5` | STRING | Category Level 5 |
| `view_promotion` | INTEGER | View promotion count |
| `select_promotion` | INTEGER | Select promotion count |
| `view_item_list` | INTEGER | View item list count |
| `select_item` | INTEGER | Select item count |
| `view_item` | INTEGER | View item count |
| `add_to_wishlist` | INTEGER | Add to wishlist count |
| `add_to_cart` | INTEGER | Add to cart count |
| `remove_from_cart` | INTEGER | Remove from cart count |
| `view_cart` | INTEGER | View cart count |
| `begin_checkout` | INTEGER | Begin checkout count |
| `add_shipping_info` | INTEGER | Add shipping info count |
| `add_payment_info` | INTEGER | Add payment info count |
| `item_quantity_purchased` | INTEGER | Quantity purchased |
| `item_quantity_refunded` | INTEGER | Quantity refunded |
| `item_quantity_added_to_cart` | INTEGER | Quantity added to cart |
| `item_quantity_removed_from_cart` | INTEGER | Quantity removed from cart |
| `item_purchase_revenue` | FLOAT | Revenue from item |
| `item_refund_revenue` | FLOAT | Refunded item revenue |
| `item_unique_purchases` | INTEGER | Unique purchases |
| `item_revenue_net_refund` | FLOAT | Net revenue |

</details>


### Shopping stages open funnel
Calculates drop-off rates across the entire shopping journey, regardless of where the user started.
[View source Code](ec_shopping_stages_open_funnel.sql)

<details><summary>Output Fields Summary</summary>

| Field name | Type | Description |
| :--- | :--- | :--- |
| **USER DATA** | | |
| `user_date` | DATE | Date of the user's first visit |
| `client_id` | STRING | Unique identifier for the user |
| `user_id` | STRING | Persistent user identifier |
| `user_channel_grouping` | STRING | Acquisition channel grouping |
| `user_source` | STRING | Acquisition source |
| `user_tld_source` | STRING | Acquisition TLD source |
| `user_campaign` | STRING | Acquisition campaign |
| `user_device_type` | STRING | Device type used |
| `user_country` | STRING | User's country |
| `user_language` | STRING | User's language |
| `user_type` | STRING | "new_user" or "returning_user" |
| `new_user` | STRING | Client ID if new user |
| `returning_user` | STRING | Client ID if returning user |
| **SESSION DATA** | | |
| `session_date` | DATE | Date of the session |
| `session_number` | INTEGER | Incremental session count for the user |
| `session_id` | STRING | Unique identifier for the session |
| `session_start_timestamp` | INTEGER | Session start timestamp |
| `session_end_timestamp` | INTEGER | Session end timestamp |
| `session_duration_sec` | INTEGER | Session duration in seconds |
| `session_channel_grouping` | STRING | Session channel grouping |
| `session_source` | STRING | Session source |
| `session_tld_source` | STRING | Session TLD source |
| `session_campaign` | STRING | Session campaign name |
| `cross_domain_session` | STRING | Flag for cross-domain sessions |
| `session_landing_page_category` | STRING | Landing page category |
| `session_landing_page_location` | STRING | Landing page URL |
| `session_landing_page_title` | STRING | Landing page title |
| `session_exit_page_category` | STRING | Exit page category |
| `session_exit_page_location` | STRING | Exit page URL |
| `session_exit_page_title` | STRING | Exit page title |
| `session_hostname` | STRING | Hostname |
| `session_device_type` | STRING | Session device type |
| `session_country` | STRING | Session country |
| `session_language` | STRING | Session language |
| `session_browser_name` | STRING | Browser name |
| **FUNNEL DATA** | | |
| `event_date` | DATE | Event date |
| `step_name` | STRING | Name of the funnel step |
| `client_id_next_step` | STRING | Client ID reaching next step |
| `user_id_next_step` | STRING | User ID reaching next step |
| `session_id_next_step` | STRING | Session ID reaching next step |

</details>


### Shopping stages closed funnel
Analyzes the shopping journey for users who follow a specific, linear sequence of steps.
[View source Code](ec_shopping_stages_closed_funnel.sql)

<details><summary>Output Fields Summary</summary>

| Field name | Type | Description |
| :--- | :--- | :--- |
| `step_name` | STRING | Name of the funnel step |
| `step_index` | INTEGER | Order index of the step |
| `client_id` | STRING | User identifier at this step |
| `client_id_next_step` | STRING | Identifier if user reached next step |
| `session_id` | STRING | Session identifier |
| `user_type` | STRING | User type |
| `session_source` | STRING | Session source |
| `session_channel_grouping` | STRING | Session channel grouping |
| `session_device_type` | STRING | Device type |
| `session_country` | STRING | Country |

</details>


### GTM performances
Provides metrics on GTM container execution times and tag performance to help optimize site speed.
[View source Code](gtm_performances.sql)

<details><summary>Output Fields Summary</summary>

| Field name | Type | Description |
| :--- | :--- | :--- |
| **USER DATA** | | |
| `user_date` | DATE | Date of the user's first visit |
| `client_id` | STRING | Unique identifier for the user |
| `user_id` | STRING | Persistent user identifier |
| `user_channel_grouping` | STRING | Acquisition channel grouping |
| `user_source` | STRING | Acquisition source |
| `user_tld_source` | STRING | Acquisition TLD source |
| `user_campaign` | STRING | Acquisition campaign |
| `user_device_type` | STRING | Device type used |
| `user_country` | STRING | User's country |
| `user_language` | STRING | User's language |
| `user_type` | STRING | "new_user" or "returning_user" |
| `new_user` | STRING | Client ID if new user |
| `returning_user` | STRING | Client ID if returning user |
| **SESSION DATA** | | |
| `session_date` | DATE | Date of the session |
| `session_number` | INTEGER | Incremental session count for the user |
| `session_id` | STRING | Unique identifier for the session |
| `session_start_timestamp` | INTEGER | Session start timestamp |
| `session_end_timestamp` | INTEGER | Session end timestamp |
| `session_duration_sec` | INTEGER | Session duration in seconds |
| `session_channel_grouping` | STRING | Session channel grouping |
| `session_source` | STRING | Session source |
| `session_tld_source` | STRING | Session TLD source |
| `session_campaign` | STRING | Session campaign name |
| `cross_domain_session` | STRING | Flag for cross-domain sessions |
| `session_landing_page_category` | STRING | Landing page category |
| `session_landing_page_location` | STRING | Landing page URL |
| `session_landing_page_title` | STRING | Landing page title |
| `session_exit_page_category` | STRING | Exit page category |
| `session_exit_page_location` | STRING | Exit page URL |
| `session_exit_page_title` | STRING | Exit page title |
| `session_hostname` | STRING | Hostname |
| `session_device_type` | STRING | Session device type |
| `session_country` | STRING | Session country |
| `session_language` | STRING | Session language |
| `session_browser_name` | STRING | Browser name |
| **PAGE DATA** | | |
| `page_data` | ARRAY | Raw page data array |
| **EVENT DATA** | | |
| `event_date` | DATE | Event date |
| `event_datetime` | TIMESTAMP | Event datetime |
| `event_timestamp` | INTEGER | Event timestamp |
| `processing_event_timestamp` | INTEGER | Server-side processing timestamp |
| `delay_in_milliseconds` | INTEGER | Processing delay (ms) |
| `delay_in_seconds` | FLOAT | Processing delay (seconds) |
| `event_origin` | STRING | Origin of the event |
| `content_length` | INTEGER | Request content length |
| `cs_hostname` | STRING | Client-side hostname |
| `ss_hostname` | STRING | Server-side hostname |
| `cs_container_id` | STRING | Client-side container ID |
| `ss_container_id` | STRING | Server-side container ID |
| `hit_number` | INTEGER | Sequential hit number |
| `event_name` | STRING | Event name |
| `event_id` | STRING | Event ID |
| `event_data` | ARRAY | Raw event data array |
| `ecommerce` | JSON | Ecommerce object (stringified) |
| `dataLayer` | JSON | DataLayer object (stringified) |

</details>


### Consents
Tracks changes in user consent status over time, ensuring compliance and data transparency.
[View source Code](consents.sql)

<details><summary>Output Fields Summary</summary>

| Field name | Type | Description |
| :--- | :--- | :--- |
| `event_date` | DATE | Event date |
| `event_timestamp` | INTEGER | Timestamp |
| `event_name` | STRING | Event name |
| `consent_type` | STRING | Update type (default/update) |
| `respect_consent_mode` | STRING | Consent mode enabled flag |
| `ad_storage` | STRING | Ad storage consent |
| `analytics_storage` | STRING | Analytics storage consent |
| `ad_user_data` | STRING | Ad user data consent |
| `ad_personalization` | STRING | Ad personalization consent |
| `functionality_storage` | STRING | Functional cookies |
| `personalization_storage` | STRING | Personalization cookies |
| `security_storage` | STRING | Security cookies |
| `client_id` | STRING | User identifier |
| `session_id` | STRING | Session identifier |

</details>

---

Reach me at: [Email](mailto:hello@tommasomoretti.com) | [Website](https://tommasomoretti.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics) | [Twitter](https://twitter.com/tommoretti88) | [LinkedIn](https://www.linkedin.com/in/tommasomoretti/)
