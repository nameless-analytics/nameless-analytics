# Nameless Analytics | Reporting Tables

The Nameless Analytics Reporting Tables are a set of tables and table functions in BigQuery where user, session, and event data are stored and processed.

For an overview of how Nameless Analytics works [start from here](../README.md#high-level-data-flow).

### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change 🚧



## Table of Contents

- [Setup](#setup)
  - [Create tables](#create-tables)
  - [Create table functions](#create-table-functions)
- [Raw tables](#raw-tables)
  - [Events raw table](#events-raw-table)
  - [Dates table](#dates-table)
- [Table functions](#table-functions)
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
- [Reporting fields](#reporting-fields)
- [Data Governance and Maintenance](#data-governance-and-maintenance)
  - [Delete user data deletion Script (Recommended)](#delete-user-data-deletion-script-recommended)
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
      # storage_billing_model = BILLING_MODEL # Phytical or logical (default)  
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
      event_timestamp int NOT NULL OPTIONS (description = 'Event timestamp'),
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


### Events raw table
This main table is partitioned by `event_date` and clustered by `user_date`, `session_date`, `page_date`, and `event_name`.


### Dates table
This table is partitioned by `date` and clustered by `month_name` and `day_name`.



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
[View SQL code](events.sql)


### Users
Aggregates data at the user level, calculating lifecycle metrics like total sessions, first/last seen dates, and lifetime values.

[View SQL code](users.sql)


### Sessions
Groups events into individual sessions, calculating duration, bounce rates, and landing/exit pages.

[View SQL code](sessions.sql)


### Pages
Focuses on page-level performance, aggregating views, time on page, and navigation paths.

[View SQL code](pages.sql)


### Transactions
Extracts and structures ecommerce transaction data, including revenue, tax, and shipping details.

[View SQL code](ec_transactions.sql)


### Products
Provides a granular view of product performance, including views, add-to-carts, and purchases per SKU.

[View SQL code](ec_products.sql)


### Shopping stages open funnel
Calculates drop-off rates across the entire shopping journey, regardless of where the user started.

[View SQL code](ec_shopping_stages_open_funnel.sql)


### Shopping stages closed funnel
Analyzes the shopping journey for users who follow a specific, linear sequence of steps.

[View SQL code](ec_shopping_stages_closed_funnel.sql)


### GTM performances
Provides metrics on GTM container execution times and tag performance to help optimize site speed.

[View SQL code](gtm_performances.sql)


### Consents
Tracks changes in user consent status over time, ensuring compliance and data transparency.

[View SQL code](consents.sql)



## Reporting fields
This table illustrates the fields available across different table functions, allowing you to easily identify common data points and specific metrics for each report.

<details><summary>Output Fields Matrix</summary>

| Field name | Field type | Value type | Events | Users | Sessions | Pages | Transactions | Products | Open_Funnel | Closed_Funnel | GTM_Performances | Consents |
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
| `add_shipping_info` | Metric | float |  |  | X |  |  | X |  |  |  |  |
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
| `content_length` | Metric | integer | X |  |  |  |  |  |  |  | X |  |
| `country` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `creative_name` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `creative_slot` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `cross_domain_id` (from `na_id`) | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `cross_domain_session` | Dimension | string | X |  | X | X | X | X |  | X | X | X |
| `cs_container_id` | Dimension | string | X |  |  |  |  |  |  |  | X |  |
| `cs_hostname` | Dimension | string | X |  |  |  |  |  |  |  | X |  |
| `cs_tag_id` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `cs_tag_name` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `customer_type` | Dimension | string |  | X |  |  |  |  |  |  |  |  |
| `customers` | Metric | integer |  | X |  |  |  |  |  |  |  |  |
| `datalayer` | Dimension | JSON | X |  |  |  |  |  |  |  | X |  |
| `days_from_first_purchase` | Metric | integer |  | X |  |  |  |  |  |  |  |  |
| `days_from_first_to_last_visit` | Metric | integer | X | X |  |  |  |  |  |  |  |  |
| `days_from_first_visit` | Metric | integer | X | X |  |  |  |  |  |  |  |  |
| `days_from_last_purchase` | Metric | integer |  | X |  |  |  |  |  |  |  |  |
| `days_from_last_visit` | Metric | integer | X | X |  |  |  |  |  |  |  |  |
| `delay_in_milliseconds` | Metric | integer |  |  |  |  |  |  |  |  | X |  |
| `delay_in_sec` | Metric | integer |  |  |  |  |  |  |  |  | X |  |
| `device_model` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `device_type` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `device_vendor` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `ecommerce` | Dimension | JSON | X |  |  |  |  |  |  |  | X |  |
| `engaged_session` | Metric | integer |  |  | X |  |  |  |  |  |  | X |
| `engaged_sessions_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `event_data` | Dimension | Array | X |  |  |  |  |  |  |  | X |  |
| `event_date` | Dimension | string | X |  |  |  | X | X | X | X | X |  |
| `event_datetime` | Dimension | string |  |  |  |  |  |  |  |  | X |  |
| `event_id` | Dimension | string | X |  |  |  |  |  |  |  | X |  |
| `event_name` | Dimension | string | X |  |  |  | X | X |  |  | X |  |
| `event_number` | Dimension | string | X |  |  |  |  |  |  |  | X |  |
| `event_origin` | Dimension | string | X |  |  |  |  |  |  |  | X |  |
| `event_timestamp` | Metric | integer | X |  |  |  | X | X |  |  | X |  |
| `event_type` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `first_purchase_timestamp` | Dimension | string |  | X |  |  |  |  |  |  |  |  |
| `functionality_storage` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `functionality_storage_accepted_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `functionality_storage_denied_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `hostname` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `is_customer` | Dimension | string |  | X |  |  |  |  |  |  |  |  |
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
| `item_purchase_revenue` | Metric | float |  |  |  |  |  | X |  |  |  |  |
| `item_quantity_added_to_cart` | Metric | integer |  |  |  |  |  | X |  |  |  |  |
| `item_quantity_purchased` | Metric | integer |  | X |  |  |  | X |  |  |  |  |
| `item_quantity_refunded` | Metric | integer |  | X |  |  |  | X |  |  |  |  |
| `item_quantity_removed_from_cart` | Metric | integer |  |  |  |  |  | X |  |  |  |  |
| `item_refund_revenue` | Metric | float |  |  |  |  |  | X |  |  |  |  |
| `item_revenue_net_refund` | Metric | float |  |  |  |  |  | X |  |  |  |  |
| `item_unique_purchases` | Metric | integer |  |  |  |  |  | X |  |  |  |  |
| `item_variant` | Metric | integer |  |  |  |  |  | X |  |  |  |  |
| `last_purchase_timestamp` | Dimension | string |  | X |  |  |  |  |  |  |  |  |
| `list_id` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `list_name` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `new_customers` | Metric | integer |  | X |  |  |  |  |  |  |  |  |
| `new_session` | Metric | integer | X |  | X |  |  |  |  |  |  |  |
| `new_sessions_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `new_user` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `new_user_client_id` | Dimension | string |  | X |  |  |  |  |  |  |  |  |
| `os_name` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `os_version` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_category` | Dimension | string | X |  |  | X |  |  |  |  |  |  |
| `page_data` | Dimension | Array | X |  |  |  |  |  |  |  | X |  |
| `page_date` | Dimension | string | X |  |  | X |  |  |  |  |  |  |
| `page_extension` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_fragment` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_hostname` | Dimension | string | X |  |  | X |  |  |  |  |  |  |
| `page_hostname_protocol` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_id` | Dimension | string | X |  |  | X |  |  |  |  |  |  |
| `page_language` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_load_datetime` | Dimension | string |  |  |  | X |  |  |  |  |  |  |
| `page_load_time_sec` | Dimension | string |  |  |  | X |  |  |  |  |  |  |
| `page_load_timestamp` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_location` | Dimension | string | X |  |  | X |  |  |  |  |  |  |
| `page_query` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_referrer` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_status_code` | Dimension | string | X |  |  | X |  |  |  |  |  |  |
| `page_title` | Dimension | string | X |  |  | X |  |  |  |  |  |  |
| `page_unload_datetime` | Dimension | string |  |  |  | X |  |  |  |  |  |  |
| `page_unload_timestamp` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `page_view` | Metric | integer |  | X | X | X |  |  |  |  |  |  |
| `page_view_number` | Dimension | string | X |  |  | X |  |  |  |  |  |  |
| `page_view_per_session` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `personalization_storage` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `personalization_storage_accepted_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |
| `personalization_storage_denied_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |
| `processing_event_timestamp` | Dimension | string | X |  |  |  |  |  |  |  | X |  |
| `promotion_id` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `promotion_name` | Dimension | string |  |  |  |  |  | X |  |  |  |  |
| `purchase` | Metric | integer |  | X | X |  |  |  |  |  |  |  |
| `purchase_net_refund` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `purchase_revenue` | Metric | float |  | X | X |  | X |  |  |  |  |  |
| `purchase_shipping` | Metric | float |  |  | X |  | X |  |  |  |  |  |
| `purchase_tax` | Metric | float |  |  | X |  | X |  |  |  |  |  |
| `purchase_transaction_id` | Dimension | string |  |  |  |  | X |  |  |  |  |  |
| `refund` | Metric | integer |  | X | X |  |  |  |  |  |  |  |
| `refund_revenue` | Metric | float |  | X | X |  | X |  |  |  |  |  |
| `refund_shipping` | Metric | float |  |  | X |  | X |  |  |  |  |  |
| `refund_tax` | Metric | float |  |  | X |  | X |  |  |  |  |  |
| `refund_transaction_id` | Dimension | string |  |  |  |  | X |  |  |  |  |  |
| `remove_from_cart` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `respect_consent_mode` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `returning_customers` | Metric | integer |  | X |  |  |  |  |  |  |  |  |
| `returning_session` | Metric | integer | X |  | X |  |  |  |  |  |  |  |
| `returning_sessions_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `returning_user` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `returning_user_client_id` | Dimension | string |  | X |  |  |  |  |  |  |  |  |
| `revenue_net_refund` | Metric | float |  | X | X |  |  |  |  |  |  |  |
| `screen_size` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `search_term` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `security_storage` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `security_storage_accepted_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `security_storage_denied_percentage` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `select_item` | Metric | integer |  |  | X |  |  | X |  |  |  |  |
| `select_promotion` | Metric | integer |  |  |  |  |  | X |  |  |  |  |
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
| `session_conversion_rate` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `session_country` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_data` | Dimension | Array | X |  |  |  |  |  |  |  |  |  |
| `session_date` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_device_type` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_duration_sec` | Metric | integer | X | X | X |  |  |  |  | X |  | X |
| `session_end_timestamp` | Dimension | string | X |  |  |  | X | X |  | X | X |  |
| `session_exit_page_category` | Dimension | string | X |  | X | X | X | X |  | X | X | X |
| `session_exit_page_location` | Dimension | string | X |  | X | X | X | X |  | X | X | X |
| `session_exit_page_title` | Dimension | string | X |  | X | X | X | X |  | X | X | X |
| `session_functionality_storage` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `session_hostname` | Dimension | string | X |  | X | X | X | X |  | X | X | X |
| `session_id` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_id_consent_expressed` | Dimension | string |  |  |  |  |  |  |  |  |  | X |
| `session_id_consent_mode_not_present` | Dimension | string |  |  |  |  |  |  |  |  |  | X |
| `session_id_consent_not_expressed` | Dimension | string |  |  |  |  |  |  |  |  |  | X |
| `session_id_next_step` | Dimension | string |  |  |  |  |  |  | X | X |  |  |
| `session_landing_page_category` | Dimension | string | X |  | X | X | X | X |  | X | X | X |
| `session_landing_page_location` | Dimension | string | X |  | X | X | X | X |  | X | X | X |
| `session_landing_page_title` | Dimension | string | X |  | X | X | X | X |  | X | X | X |
| `session_language` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_number` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_personalization_storage` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `session_security_storage` | Metric | integer |  |  | X |  |  |  |  |  |  |  |
| `session_source` | Dimension | string | X |  | X | X | X | X | X | X | X | X |
| `session_source_cleaned` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `session_start_timestamp` | Dimension | string | X |  | X | X | X | X |  | X | X | X |
| `session_tld_source` | Dimension | string | X |  |  |  |  |  | X | X |  |  |
| `session_type` | Dimension | string | X |  |  | X | X | X |  |  | X |  |
| `session_value` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `sessions` | Metric | integer |  | X |  |  |  |  |  |  |  |  |
| `sessions_per_user` | Metric | float |  | X |  |  |  |  |  |  |  |  |
| `shipping_net_refund` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `source` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `source_cleaned` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `ss_container_id` | Dimension | string | X |  |  |  |  |  |  |  | X |  |
| `ss_hostname` | Dimension | string | X |  |  |  |  |  |  |  | X |  |
| `ss_tag_id` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `ss_tag_name` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `status` | Dimension | string |  |  |  |  |  |  | X |  |  |  |
| `step_index` | Dimension | string |  |  |  |  |  |  | X |  |  |  |
| `step_index_next_step` | Dimension | string |  |  |  |  |  |  | X |  |  |  |
| `step_index_next_step_real` | Dimension | string |  |  |  |  |  |  | X |  |  |  |
| `step_name` | Dimension | string |  |  |  |  |  |  | X | X |  |  |
| `tax_net_refund` | Metric | float |  |  | X |  |  |  |  |  |  |  |
| `time_on_page` | Metric | integer | X |  |  | X |  |  |  |  |  |  |
| `tld_source` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `total_page_load_time` | Metric | integer | X |  |  |  |  |  |  |  |  |  |
| `transaction_coupon` | Dimension | string |  |  |  |  | X |  |  |  |  |  |
| `transaction_currency` | Dimension | string |  |  |  |  | X |  |  |  |  |  |
| `transaction_id` | Dimension | string |  |  |  |  | X | X |  |  |  |  |
| `user_agent` | Dimension | string | X |  |  |  |  |  |  |  |  |  |
| `user_campaign` | Dimension | string | X | X | X | X | X | X | X | X | X | X |
| `user_campaign_click_id` | Dimension | string | X | X | X | X | X | X |  |  | X |  |
| `user_campaign_content` | Dimension | string | X | X | X | X | X | X |  |  | X |  |
| `user_campaign_id` | Dimension | string | X | X | X | X | X | X |  |  | X |  |
| `user_campaign_term` | Dimension | string | X | X | X | X | X | X |  |  | X |  |
| `user_channel_grouping` | Dimension | string | X | X | X | X | X | X | X | X | X | X |
| `user_city` | Dimension | string | X | X | X | X | X | X | X | X | X |  |
| `user_conversion_rate` | Metric | float |  | X |  |  |  |  |  |  |  |  |
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
| `user_value` | Metric | float |  | X |  |  |  |  |  |  |  |  |
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


### Delete user data deletion Script (Recommended)
You can use the provided Python script `users-deletion-tools.py` to handle both deletions in a single command.

### Manual user data deletion
#### BigQuery user data deletion
If you prefer manual deletion in BigQuery, use the following DML statement:

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

Reach me at: [Email](mailto:hello@namelessanalytics.com) | [Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_tables) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
