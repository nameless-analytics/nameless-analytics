# Nameless Analytics | Reporting Tables

The Nameless Analytics Reporting Tables are a set of tables and table functions in BigQuery where user, session, and event data are stored and processed.

For an overview of how Nameless Analytics works [start from here](https://github.com/nameless-analytics/nameless-analytics/#high-level-data-flow).

🚧 **Nameless Analytics is currently in beta and is subject to change.** 🚧



</br>

## Table of Contents
- [Setup](#setup)
  - [Create tables](#create-tables)
  - [Create table functions](#create-table-functions)
- [Tables](#tables)
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



</br>

## Setup
The following SQL scripts are used to initialize the Nameless Analytics reporting environment in BigQuery.

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

#

### Create table functions
<details><summary>To create the table functions use this DML statement.</summary>

```sql
# Run the SQL scripts in this directory to create the table functions.
```
</details>
</br>

## Tables
Tables are the foundational storage layer of Nameless Analytics, designed to capture and preserve every user interaction in its raw, unprocessed form. These tables serve as the single source of truth for all analytics data, storing event-level information with complete historical fidelity.

The architecture consists of two core tables: the **Events raw table** (`events_raw`), which stores all user, session, page, event, ecommerce, consent, and GTM performance data in a denormalized structure optimized for both write performance and analytical queries; and the **Dates table** (`calendar_dates`), a utility dimension table that provides comprehensive date attributes for time-based analysis and reporting.

All data is partitioned by date and clustered by key dimensions to ensure optimal query performance and cost efficiency when analyzing large datasets.



### Events raw table
This main table is partitioned by `event_date` and clustered by `user_date`, `session_date`, `page_date`, and `event_name`.

<details><summary>View table schema</summary>

| Field name      | Type    | Mode     | Description                        |
|-----------------|---------|----------|------------------------------------|
| client_id       | STRING  | REQUIRED | Client ID                          |
| user_date       | DATE    | REQUIRED | User date                          |
| user_data       | RECORD  | REPEATED | User data                          |
| session_id      | STRING  | REQUIRED | Session ID                         |
| session_date    | DATE    | REQUIRED | Session date                       |
| session_data    | RECORD  | REPEATED | Session data                       |
| page_id         | STRING  | REQUIRED | Page ID                            |
| page_date       | DATE    | REQUIRED | Page date                          |
| page_data       | RECORD  | REPEATED | Page data                          |
| event_name      | STRING  | REQUIRED | Event name                         |
| event_id        | STRING  | REQUIRED | Event ID                           |
| event_date      | DATE    | REQUIRED | Date of the request                |
| event_timestamp | INTEGER | REQUIRED | Insertion timestamp of the event   |
| event_origin    | STRING  | REQUIRED | "Website" or "Streaming protocol"  |
| event_data      | RECORD  | REPEATED | Event data                         |
| ecommerce       | JSON    | NULLABLE | Ecommerce object                   |
| datalayer       | JSON    | NULLABLE | Current `dataLayer` value          |
| consent_data    | RECORD  | REPEATED | Consent data                       |
| gtm_data        | RECORD  | REPEATED | GTM performance and execution data |

</details>


#

### Dates table
This table is partitioned by `date` and clustered by `month_name` and `day_name`.

<details><summary>View table schema</summary>

| Field name         | Type    | Mode     | Description                                                    |
|--------------------|---------|----------|----------------------------------------------------------------|
| date               | DATE    | REQUIRED | The date value                                                 |
| year               | INTEGER | NULLABLE | Year extracted from the date                                   |
| quarter            | INTEGER | NULLABLE | Quarter of the year (1-4) extracted from the date              |
| month_number       | INTEGER | NULLABLE | Month number of the year (1-12) extracted from the date        |
| month_name         | STRING  | NULLABLE | Full name of the month (e.g., January) extracted from the date |
| week_number_sunday | INTEGER | NULLABLE | Week number of the year, starting on Sunday                    |
| week_number_monday | INTEGER | NULLABLE | Week number of the year, starting on Monday                    |
| day_number         | INTEGER | NULLABLE | Day number of the month (1-31)                                 |
| day_name           | STRING  | NULLABLE | Full name of the day of the week (e.g., Monday)                |
| day_of_week_number | INTEGER | NULLABLE | Day of the week number (1 for Monday, 7 for Sunday)            |
| is_weekend         | BOOLEAN | NULLABLE | True if the day is a Saturday or Sunday                        |

</details>

</br>

## Table functions
Table functions are predefined SQL queries that simplify data analysis by transforming raw event data into structured, easy-to-use formats for common reporting needs.

Unlike other systems, Nameless Analytics reporting functions are designed to work directly on the `events_raw` table as the single source of truth. By leveraging BigQuery **Window Functions**. This approach ensures that reports always reflect the most up-to-date state of the data without the need for complex ETL processes or intermediate staging tables.


### Events
Flattens raw event data and extracts custom parameters, making it easier to analyze specific interaction metrics.

[View SQL code](events.sql)

<details><summary>View table schema</summary>

| Field name | Type | Description | Calculation / Logic |
| :--- | :--- | :--- | :--- |
| **USER DATA** | | | |
| `user_date` | DATE | Date of the user's first visit | `events_raw.user_date` |
| `user_id` | STRING | Persistent user identifier (if provided) | `first_value(session_data.user_id) over (partition by session_id order by timestamp desc)` |
| `client_id` | STRING | Unique identifier for the browser/device | `events_raw.client_id` |
| `user_type` | STRING | "new_user" or "returning_user" | `if session_number = 1 then 'new_user' else 'returning_user'` |
| `new_user` | STRING | Client ID if it's a new user, else null | `if session_number = 1 then client_id else null` |
| `returning_user` | STRING | Client ID if it's a returning user, else null | `if session_number > 1 then client_id else null` |
| `user_first_session_timestamp` | INTEGER | Timestamp of the first session | `user_data.user_first_session_timestamp` |
| `user_last_session_timestamp` | INTEGER | Timestamp of the most recent session | `max(user_data.user_last_session_timestamp) over (partition by client_id)` |
| `days_from_first_to_last_visit` | INTEGER | Days between first and last visit | `datetime_diff(last_session_ts, first_session_ts, day)` |
| `days_from_first_visit` | INTEGER | Days since first visit | `datetime_diff(current_ts, first_session_ts, day)` |
| `days_from_last_visit` | INTEGER | Days since last visit | `datetime_diff(current_ts, last_session_ts, day)` |
| `user_channel_grouping` | STRING | Acquisition channel grouping | `user_data.user_channel_grouping` |
| `user_source` | STRING | Acquisition source | `user_data.user_source` |
| `user_tld_source` | STRING | Top Level Domain of the source | `user_data.user_tld_source` |
| `user_campaign` | STRING | Acquisition campaign name | `user_data.user_campaign` |
| `user_campaign_id` | STRING | Acquisition campaign ID | `user_data.user_campaign_id` |
| `user_campaign_click_id` | STRING | Acquisition campaign click ID (e.g. gclid) | `user_data.user_campaign_click_id` |
| `user_campaign_term` | STRING | Acquisition campaign term | `user_data.user_campaign_term` |
| `user_campaign_content` | STRING | Acquisition campaign content | `user_data.user_campaign_content` |
| `user_device_type` | STRING | Device type (mobile, desktop, tablet) | `user_data.user_device_type` |
| `user_country` | STRING | User's country | `user_data.user_country` |
| `user_language` | STRING | User's language | `user_data.user_language` |
| **SESSION DATA** | | | |
| `session_date` | DATE | Date of the session | `events_raw.session_date` |
| `session_id` | STRING | Unique identifier for the session | `events_raw.session_id` |
| `session_number` | INTEGER | Incremental session count for the user | `session_data.session_number` |
| `cross_domain_session` | STRING | Flag for cross-domain sessions | `first_value(session_data.cross_domain_session) over (partition by session_id)` |
| `session_start_timestamp` | INTEGER | Session start timestamp | `session_data.session_start_timestamp` |
| `session_end_timestamp` | INTEGER | Session end timestamp | `first_value(session_data.session_end_timestamp) over (partition by session_id)` |
| `session_duration_sec` | INTEGER | Session duration in seconds | `datetime_diff(max_session_end_ts, min_session_start_ts, second)` |
| `new_session` | INTEGER | 1 if new session, else 0 | `if session_number = 1 then 1 else 0` |
| `returning_session` | INTEGER | 1 if returning session, else 0 | `if session_number > 1 then 1 else 0` |
| `session_channel_grouping` | STRING | Session channel grouping | `session_data.session_channel_grouping` |
| `session_source` | STRING | Session source | `session_data.session_source` |
| `session_tld_source` | STRING | Session TLD source | `session_data.session_tld_source` |
| `session_campaign` | STRING | Session campaign name | `session_data.session_campaign` |
| `session_campaign_id` | STRING | Session campaign ID | `session_data.session_campaign_id` |
| `session_campaign_click_id` | STRING | Session campaign click ID | `session_data.session_campaign_click_id` |
| `session_campaign_term` | STRING | Session campaign term | `session_data.session_campaign_term` |
| `session_campaign_content` | STRING | Session campaign content | `session_data.session_campaign_content` |
| `session_device_type` | STRING | Session device type | `session_data.session_device_type` |
| `session_country` | STRING | Session country | `session_data.session_country` |
| `session_language` | STRING | Session language | `session_data.session_language` |
| `session_browser_name` | STRING | Browser name | `session_data.session_browser_name` |
| `session_hostname` | STRING | Hostname of the session | `session_data.session_hostname` |
| `session_landing_page_category` | STRING | Category of the landing page | `session_data.session_landing_page_category` |
| `session_landing_page_location` | STRING | Landing page URL | `session_data.session_landing_page_location` |
| `session_landing_page_title` | STRING | Landing page title | `session_data.session_landing_page_title` |
| `session_exit_page_category` | STRING | Category of the exit page | `first_value(session_data.session_exit_page_category) over (partition by session_id)` |
| `session_exit_page_location` | STRING | Exit page URL | `first_value(session_data.session_exit_page_location) over (partition by session_id)` |
| `session_exit_page_title` | STRING | Exit page title | `first_value(session_data.session_exit_page_title) over (partition by session_id)` |
| **PAGE DATA** | | | |
| `page_date` | DATE | Date of the page view | `events_raw.page_date` |
| `page_id` | STRING | Unique page view ID | `events_raw.page_id` |
| `page_view_number` | INTEGER | Sequential page view number | `session_data.total_page_views` |
| `page_load_timestamp` | INTEGER | Timestamp when page loaded | `page_data.page_timestamp` |
| `page_unload_timestamp` | INTEGER | Timestamp when page unloaded | `first_value(event_timestamp) over (partition by page_id order by timestamp desc)` |
| `page_category` | STRING | Page category | `page_data.page_category` |
| `page_title` | STRING | Page title | `page_data.page_title` |
| `page_language` | STRING | Page language | `page_data.page_language` |
| `page_hostname_protocol` | STRING | Protocol (http/https) | `page_data.page_hostname_protocol` |
| `page_hostname` | STRING | Hostname | `page_data.page_hostname` |
| `page_location` | STRING | Full URL | `page_data.page_location` |
| `page_fragment` | STRING | URL fragment (#) | `page_data.page_fragment` |
| `page_query` | STRING | URL query string (?) | `page_data.page_query` |
| `page_extension` | STRING | URL file extension | `page_data.page_extension` |
| `page_referrer` | STRING | HTTP Referrer | `page_data.page_referrer` |
| `page_status_code` | INTEGER | HTTP Status code | `page_data.page_status_code` |
| `time_on_page` | INTEGER | Time spent on page in seconds | `datetime_diff(page_unload_ts, page_load_ts, second)` |
| **EVENT DATA** | | | |
| `event_date` | DATE | Date of the event | `events_raw.event_date` |
| `event_timestamp` | INTEGER | Microsecond timestamp | `events_raw.event_timestamp` |
| `event_name` | STRING | Event name | `events_raw.event_name` |
| `event_id` | STRING | Unique event ID | `events_raw.event_id` |
| `event_number` | INTEGER | Sequential event number | `session_data.total_events` |
| `event_type` | STRING | Type of event | `event_data.event_type` |
| `channel_grouping` | STRING | Event channel grouping | `event_data.channel_grouping` |
| `source` | STRING | Event source | `event_data.source` |
| `tld_source` | STRING | Event TLD source | `event_data.tld_source` |
| `campaign` | STRING | Event campaign | `event_data.campaign` |
| `campaign_id` | STRING | Event campaign ID | `event_data.campaign_id` |
| `campaign_click_id` | STRING | Event campaign click ID | `event_data.campaign_click_id` |
| `campaign_term` | STRING | Event campaign term | `event_data.campaign_term` |
| `campaign_content` | STRING | Event campaign content | `event_data.campaign_content` |
| `browser_name` | STRING | Browser name | `event_data.browser_name` |
| `browser_version` | STRING | Browser version | `event_data.browser_version` |
| `browser_language` | STRING | Browser language | `event_data.browser_language` |
| `viewport_size` | STRING | Viewport dimensions | `event_data.viewport_size` |
| `user_agent` | STRING | User Agent string | `event_data.user_agent` |
| `device_type` | STRING | Device type at event level | `event_data.device_type` |
| `device_model` | STRING | Device model | `event_data.device_model` |
| `device_vendor` | STRING | Device vendor | `event_data.device_vendor` |
| `os_name` | STRING | OS name | `event_data.os_name` |
| `os_version` | STRING | OS version | `event_data.os_version` |
| `screen_size` | STRING | Screen resolution | `event_data.screen_size` |
| `country` | STRING | Event country | `event_data.country` |
| `city` | STRING | Event city | `event_data.city` |
| `cross_domain_id` | STRING | Cross domain ID parameter | `event_data.cross_domain_id` |
| `time_to_dom_interactive` | INTEGER | Performance metric (ms) | `event_data.time_to_dom_interactive` |
| `page_render_time` | INTEGER | Performance metric (ms) | `event_data.page_render_time` |
| `time_to_dom_complete` | INTEGER | Performance metric (ms) | `event_data.time_to_dom_complete` |
| `total_page_load_time` | INTEGER | Performance metric (ms) | `event_data.total_page_load_time` |
| `search_term` | STRING | Search query (for search events) | `event_data.search_term` |
| **ECOMMERCE** | | | |
| `ecommerce` | JSON | Ecommerce object | `events_raw.ecommerce` |
| **DATALAYER DATA** | | | |
| `datalayer` | JSON | DataLayer state | `events_raw.datalayer` |
| **CONSENT DATA** | | | |
| `consent_type` | STRING | Consent update type | `consent_data.consent_type` |
| `respect_consent_mode` | STRING | Flag for consent mode respect | `consent_data.respect_consent_mode` |
| `ad_user_data` | STRING | Consent status | `consent_data.ad_user_data` |
| `ad_personalization` | STRING | Consent status | `consent_data.ad_personalization` |
| `ad_storage` | STRING | Consent status | `consent_data.ad_storage` |
| `analytics_storage` | STRING | Consent status | `consent_data.analytics_storage` |
| `functionality_storage` | STRING | Consent status | `consent_data.functionality_storage` |
| `personalization_storage` | STRING | Consent status | `consent_data.personalization_storage` |
| `security_storage` | STRING | Consent status | `consent_data.security_storage` |
| **REQUEST DATA** | | | |
| `event_origin` | STRING | Origin of the event | `events_raw.event_origin` |
| `cs_hostname` | STRING | Client-side hostname | `gtm_data.cs_hostname` |
| `cs_container_id` | STRING | Client-side GTM container ID | `gtm_data.cs_container_id` |
| `cs_tag_name` | STRING | Client-side tag name | `gtm_data.cs_tag_name` |
| `cs_tag_id` | INTEGER | Client-side tag ID | `gtm_data.cs_tag_id` |
| `ss_hostname` | STRING | Server-side hostname | `gtm_data.ss_hostname` |
| `ss_container_id` | STRING | Server-side GTM container ID | `gtm_data.ss_container_id` |
| `ss_tag_name` | STRING | Server-side tag name | `gtm_data.ss_tag_name` |
| `ss_tag_id` | INTEGER | Server-side tag ID | `gtm_data.ss_tag_id` |
| `processing_event_timestamp` | INTEGER | Server-side processing timestamp | `gtm_data.processing_event_timestamp` |
| `content_length` | INTEGER | Payload size | `gtm_data.content_length` |
| **RAW ARRAYS** | | | |
| `user_data` | ARRAY | Raw user data array | `events_raw.user_data` |
| `session_data` | ARRAY | Raw session data array | `events_raw.session_data` |
| `page_data` | ARRAY | Raw page data array | `events_raw.page_data` |
| `event_data` | ARRAY | Raw event data array | `events_raw.event_data` |
| `gtm_data` | ARRAY | Raw GTM data array | `events_raw.gtm_data` |


</br>

Event data can be extracted at various levels:

#### User level
Returns events related to users acquired in the selected time period.

```sql
select * from `project.nameless_analytics.events` (start_date, end_date, 'User')
```

#### Session level: 
Returns events related to sessions that started in the selected time period.

```sql
select * from `project.nameless_analytics.events`(start_date, end_date, 'Session')
```

#### Page level
Returns events related to pages visited in the selected time period.

```sql
select * from `project.nameless_analytics.events`(start_date, end_date, 'Page')
```

#### Event level
Returns events that occurred in the selected time period.

```sql
select * from `project.nameless_analytics.events`(start_date, end_date, 'Event')
```

</details>


#

### Users
Aggregates data at the user level, calculating lifecycle metrics like total sessions, first/last seen dates, and lifetime values.

[View SQL code](users.sql)

<details><summary>View table schema</summary>

| Field name | Type | Description | Calculation / Logic |
| :--- | :--- | :--- | :--- |
| **USER DATA** | | | |
| `user_date` | DATE | Date of the user's first visit | `events.user_date` |
| `client_id` | STRING | Unique identifier for the user | `events.client_id` |
| `user_channel_grouping` | STRING | Acquisition channel grouping | `events.user_channel_grouping` |
| `user_source` | STRING | Acquisition source | `split(user_tld_source, '.')[0]` |
| `user_tld_source` | STRING | Acquisition TLD source | `events.user_tld_source` |
| `user_campaign` | STRING | Acquisition campaign | `events.user_campaign` |
| `user_campaign_click_id` | STRING | Acquisition campaign click ID | `events.user_campaign_click_id` |
| `user_campaign_term` | STRING | Acquisition campaign term | `events.user_campaign_term` |
| `user_campaign_content` | STRING | Acquisition campaign content | `events.user_campaign_content` |
| `user_device_type` | STRING | Device type used | `events.user_device_type` |
| `user_country` | STRING | User's country | `events.user_country` |
| `user_language` | STRING | User's language | `events.user_language` |
| `user_type` | STRING | "new_user" or "returning_user" | `if total_sessions = 1 then 'new_user' else 'returning_user'` |
| `new_user_client_id` | STRING | Client ID if new user | `max(events.new_user)` |
| `returning_user_client_id` | STRING | Client ID if returning user | `max(events.returning_user)` |
| `days_from_first_to_last_visit` | INTEGER | Total lifecycle duration in days | `max(events.days_from_first_to_last_visit)` |
| `days_from_first_visit` | INTEGER | Days since first visit | `max(events.days_from_first_visit)` |
| `days_from_last_visit` | INTEGER | Days since last visit | `max(events.days_from_last_visit)` |
| **ACTIVITY & ECOMMERCE** | | | |
| `is_customer` | STRING | "Customer" or "Not customer" | `if sum(purchase) > 0 then 'Customer' else 'Not customer'` |
| `customer_type` | STRING | "Not customer", "New customer", "Returning customer" | `case when sum(purchase) = 1 then 'New customer' when sum(purchase) > 1 then 'Returning customer' else 'Not customer' end` |
| `customers` | INTEGER | 1 if the user is a customer | `case when sum(purchase) >= 1 then 1 end` |
| `new_customers` | INTEGER | 1 if the user became a customer in this period | `case when sum(purchase) = 1 then 1 end` |
| `returning_customers` | INTEGER | 1 if the user was already a customer | `case when sum(purchase) > 1 then 1 end` |
| `sessions` | INTEGER | Total number of sessions | `count(distinct session_id)` |
| `session_duration_sec` | FLOAT | Average session duration | `avg(session_duration_sec)` |
| `page_view` | INTEGER | Total page views | `sum(page_view)` |
| `days_from_first_purchase` | INTEGER | Days since first purchase | `date_diff(current_date, user_first_purchase_ts, day)` |
| `days_from_last_purchase` | INTEGER | Days since last purchase | `date_diff(current_date, user_last_purchase_ts, day)` |
| `purchase` | INTEGER | Total purchases count | `sum(purchase)` |
| `refund` | INTEGER | Total refunds count | `sum(refund)` |
| `item_quantity_purchased` | INTEGER | Total items purchased | `sum(session_purchase_qty)` |
| `item_quantity_refunded` | INTEGER | Total items refunded | `sum(session_refund_qty)` |
| `purchase_revenue` | FLOAT | Total revenue generated | `sum(session_purchase_revenue)` |
| `refund_revenue` | FLOAT | Total revenue refunded | `sum(session_refund_revenue)` |
| `revenue_net_refund` | FLOAT | Revenue minus refunds | `purchase_revenue + refund_revenue` |
| `avg_purchase_value` | FLOAT | Average order value | `avg(session_avg_purchase_value)` |
| `avg_refund_value` | FLOAT | Average refund value | `avg(session_avg_refund_value)` |

</details>


#

### Sessions
Groups events into individual sessions, calculating duration, bounce rates, and landing/exit pages.


[View SQL code](sessions.sql)

<details><summary>View table schema</summary>

| Field name | Type | Description | Calculation / Logic |
| :--- | :--- | :--- | :--- |
| **USER DATA** | | | |
| `user_date` | DATE | Date of the user's first visit | `events.user_date` |
| `user_id` | STRING | Persistent user identifier | `events.user_id` |
| `client_id` | STRING | Unique identifier for the user | `events.client_id` |
| `user_type` | STRING | "new_user" or "returning_user" | `if session_number = 1 then 'new_user' else 'returning_user'` |
| `new_user` | STRING | Client ID if new user | `if session_number = 1 then client_id else null` |
| `new_users_percentage` | FLOAT | Percentage of new users | `safe_divide(count(distinct new_user), count(distinct client_id))` |
| `returning_user` | STRING | Client ID if returning user | `if session_number > 1 then client_id else null` |
| `returning_users_percentage` | FLOAT | Percentage of returning users | `safe_divide(count(distinct returning_user), count(distinct client_id))` |
| `user_channel_grouping` | STRING | Acquisition channel grouping | `events.user_channel_grouping` |
| `user_source` | STRING | Acquisition source | `events.user_source` |
| `user_tld_source` | STRING | Acquisition TLD source | `events.user_tld_source` |
| `user_campaign` | STRING | Acquisition campaign | `events.user_campaign` |
| `user_campaign_click_id` | STRING | Acquisition campaign click ID | `events.user_campaign_click_id` |
| `user_campaign_term` | STRING | Acquisition campaign term | `events.user_campaign_term` |
| `user_campaign_content` | STRING | Acquisition campaign content | `events.user_campaign_content` |
| `user_device_type` | STRING | Device type used | `events.user_device_type` |
| `user_country` | STRING | User's country | `events.user_country` |
| `user_language` | STRING | User's language | `events.user_language` |
| `user_conversion_rate` | FLOAT | User conversion rate | `safe_divide(count(distinct case when purchase > 0 then client_id end), count(distinct client_id))` |
| `user_value` | FLOAT | Average user value | `safe_divide(sum(purchase_revenue), count(distinct client_id))` |
| **SESSION DATA** | | | |
| `session_date` | DATE | Date of the session | `events.session_date` |
| `session_id` | STRING | Unique identifier for the session | `events.session_id` |
| `session_number` | INTEGER | Incremental session count for the user | `events.session_number` |
| `first_session` | STRING | 'true' if it is the first session | `if session_number = 1 then 'true' else 'false'` |
| `cross_domain_session` | STRING | Flag for cross-domain sessions | `events.cross_domain_session` |
| `session_start_timestamp` | INTEGER | Session start timestamp | `events.session_start_timestamp` |
| `session_duration_sec` | INTEGER | Session duration in seconds | `events.session_duration_sec` |
| `new_session` | INTEGER | 1 if new session, else 0 | `events.new_session` |
| `new_sessions_percentage` | FLOAT | Percentage of new sessions | `safe_divide(sum(new_session), count(distinct session_id))` |
| `returning_session` | INTEGER | 1 if returning session, else 0 | `events.returning_session` |
| `returning_sessions_percentage` | FLOAT | Percentage of returning sessions | `safe_divide(sum(returning_session), count(distinct session_id))` |
| `engaged_session` | INTEGER | 1 if engaged session, else 0 | `if page_view >= 2 AND (session_duration_sec >= 10 OR purchase >= 1) then 1 else 0` |
| `engaged_sessions_percentage` | FLOAT | Percentage of engaged sessions | `safe_divide(sum(engaged_session), count(distinct session_id))` |
| `session_channel_grouping` | STRING | Session channel grouping | `events.session_channel_grouping` |
| `session_source` | STRING | Session source | `events.session_source` |
| `session_tld_source` | STRING | Session TLD source | `events.session_tld_source` |
| `session_campaign` | STRING | Session campaign name | `events.session_campaign` |
| `session_campaign_click_id` | STRING | Session campaign click ID | `events.session_campaign_click_id` |
| `session_campaign_term` | STRING | Session campaign term | `events.session_campaign_term` |
| `session_campaign_content` | STRING | Session campaign content | `events.session_campaign_content` |
| `session_device_type` | STRING | Session device type | `events.session_device_type` |
| `session_browser_name` | STRING | Browser name | `events.session_browser_name` |
| `session_country` | STRING | Session country | `events.session_country` |
| `session_language` | STRING | Session language | `events.session_language` |
| `session_landing_page_category` | STRING | Landing page category | `events.session_landing_page_category` |
| `session_landing_page_location` | STRING | Landing page URL | `events.session_landing_page_location` |
| `session_landing_page_title` | STRING | Landing page title | `events.session_landing_page_title` |
| `session_exit_page_category` | STRING | Exit page category | `events.session_exit_page_category` |
| `session_exit_page_location` | STRING | Exit page URL | `events.session_exit_page_location` |
| `session_exit_page_title` | STRING | Exit page title | `events.session_exit_page_title` |
| `session_hostname` | STRING | Hostname | `events.session_hostname` |
| `session_conversion_rate` | FLOAT | Session conversion rate | `safe_divide(sum(purchase), count(distinct session_id))` |
| `session_value` | FLOAT | Average session value | `safe_divide(sum(purchase_revenue), count(distinct session_id))` |
| `sessions_per_user` | FLOAT | Average sessions per user | `safe_divide(count(distinct session_id), count(distinct client_id))` |
| `page_view_per_session` | FLOAT | Average page views per session | `safe_divide(sum(page_view), count(distinct session_id))` |
| **EVENTS** | | | |
| `page_view` | INTEGER | Total pages viewed | `countif(event_name = 'page_view')` |
| **ECOMMERCE DATA** | | | |
| `view_item_list` | INTEGER | View item list count | `countif(event_name = 'view_item_list')` |
| `select_item` | INTEGER | Select item count | `countif(event_name = 'select_item')` |
| `view_item` | INTEGER | View item count | `countif(event_name = 'view_item')` |
| `add_to_wishlist` | INTEGER | Add to wishlist count | `countif(event_name = 'add_to_wishlist')` |
| `add_to_cart` | INTEGER | Add to cart count | `countif(event_name = 'add_to_cart')` |
| `remove_from_cart` | INTEGER | Remove from cart count | `countif(event_name = 'remove_from_cart')` |
| `view_cart` | INTEGER | View cart count | `countif(event_name = 'view_cart')` |
| `begin_checkout` | INTEGER | Begin checkout count | `countif(event_name = 'begin_checkout')` |
| `add_shipping_info` | INTEGER | Add shipping info count | `countif(event_name = 'add_shipping_info')` |
| `add_payment_info` | INTEGER | Add payment info count | `countif(event_name = 'add_payment_info')` |
| `purchase` | INTEGER | Purchase count | `countif(event_name = 'purchase')` |
| `refund` | INTEGER | Refund count | `countif(event_name = 'refund')` |
| `purchase_revenue` | FLOAT | Revenue from purchases | `sum(ecommerce.value) where name = 'purchase'` |
| `purchase_shipping` | FLOAT | Shipping revenue | `sum(ecommerce.shipping) where name = 'purchase'` |
| `purchase_tax` | FLOAT | Tax revenue | `sum(ecommerce.tax) where name = 'purchase'` |
| `avg_order_value` | FLOAT | Average Order Value | `safe_divide(purchase_revenue, purchase)` |
| `refund_revenue` | FLOAT | Total refunded revenue | `sum(ecommerce.value) where name = 'refund'` |
| `refund_shipping` | FLOAT | Refunded shipping | `sum(ecommerce.shipping) where name = 'refund'` |
| `refund_tax` | FLOAT | Refunded tax | `sum(ecommerce.tax) where name = 'refund'` |
| `purchase_net_refund` | INTEGER | Net purchases (minus refunds) | `purchase - refund` |
| `revenue_net_refund` | FLOAT | Net revenue (minus refunds) | `purchase_revenue + refund_revenue` |
| `shipping_net_refund` | FLOAT | Net shipping | `purchase_shipping + refund_shipping` |
| `tax_net_refund` | FLOAT | Net tax | `purchase_tax + refund_tax` |
| **CONSENT DATA** | | | |
| `consent_timestamp` | INTEGER | Timestamp of consent | `max(consent_data.consent_timestamp)` |
| `consent_expressed` | STRING | Whether consent was expressed | `if countif(event_name = 'consent_update') > 0 then 'Yes' else 'No'` |
| `session_ad_user_data` | INTEGER | Ad user data consent count | `countif(ad_user_data = 'granted')` |
| `ad_user_data_accepted_percentage` | FLOAT | % Ad user data accepted | `safe_divide(session_ad_user_data, total_hits)` |
| `ad_user_data_denied_percentage` | FLOAT | % Ad user data denied | `safe_divide(countif(ad_user_data = 'denied'), total_hits)` |
| `session_ad_personalization` | INTEGER | Ad personalization consent count | `countif(ad_personalization = 'granted')` |
| `ad_personalization_accepted_percentage` | FLOAT | % Ad personalization accepted | `safe_divide(session_ad_personalization, total_hits)` |
| `ad_personalization_denied_percentage` | FLOAT | % Ad personalization denied | `safe_divide(countif(ad_personalization = 'denied'), total_hits)` |
| `session_ad_storage` | INTEGER | Ad storage consent count | `countif(ad_storage = 'granted')` |
| `ad_storage_accepted_percentage` | FLOAT | % Ad storage accepted | `safe_divide(session_ad_storage, total_hits)` |
| `ad_storage_denied_percentage` | FLOAT | % Ad storage denied | `safe_divide(countif(ad_storage = 'denied'), total_hits)` |
| `session_analytics_storage` | INTEGER | Analytics storage consent count | `countif(analytics_storage = 'granted')` |
| `analytics_storage_accepted_percentage` | FLOAT | % Analytics storage accepted | `safe_divide(session_analytics_storage, total_hits)` |
| `analytics_storage_denied_percentage` | FLOAT | % Analytics storage denied | `safe_divide(countif(analytics_storage = 'denied'), total_hits)` |
| `session_functionality_storage` | INTEGER | Functionality storage consent count | `countif(functionality_storage = 'granted')` |
| `functionality_storage_accepted_percentage` | FLOAT | % Functionality storage accepted | `safe_divide(session_functionality_storage, total_hits)` |
| `functionality_storage_denied_percentage` | FLOAT | % Functionality storage denied | `safe_divide(countif(functionality_storage = 'denied'), total_hits)` |
| `session_personalization_storage` | INTEGER | Personalization storage consent count | `countif(personalization_storage = 'granted')` |
| `session_security_storage` | INTEGER | Security storage consent count | `countif(security_storage = 'granted')` |
| `security_storage_accepted_percentage` | FLOAT | % Security storage accepted | `safe_divide(session_security_storage, total_hits)` |
| `security_storage_denied_percentage` | FLOAT | % Security storage denied | `safe_divide(countif(security_storage = 'denied'), total_hits)` |

</details>


#

### Pages
Focuses on page-level performance, aggregating views, time on page, and navigation paths.

[View SQL code](pages.sql)

<details><summary>View table schema</summary>

| Field name | Type | Description | Calculation / Logic |
| :--- | :--- | :--- | :--- |
| **USER DATA** | | | |
| `user_date` | DATE | Date of the user's first visit | `events.user_date` |
| `client_id` | STRING | Unique identifier for the user | `events.client_id` |
| `user_type` | STRING | "new_user" or "returning_user" | `events.user_type` |
| `new_user` | STRING | Client ID if new user | `events.new_user` |
| `returning_user` | STRING | Client ID if returning user | `events.returning_user` |
| `user_channel_grouping` | STRING | Acquisition channel grouping | `events.user_channel_grouping` |
| `user_source` | STRING | Acquisition source | `split(user_tld_source, '.')[0]` |
| `user_tld_source` | STRING | Acquisition TLD source | `events.user_tld_source` |
| `user_campaign` | STRING | Acquisition campaign | `events.user_campaign` |
| `user_campaign_click_id` | STRING | Acquisition campaign click ID | `events.user_campaign_click_id` |
| `user_campaign_term` | STRING | Acquisition campaign term | `events.user_campaign_term` |
| `user_campaign_content` | STRING | Acquisition campaign content | `events.user_campaign_content` |
| `user_device_type` | STRING | Device type used | `events.user_device_type` |
| `user_country` | STRING | User's country | `events.user_country` |
| `user_language` | STRING | User's language | `events.user_language` |
| **SESSION DATA** | | | |
| `session_date` | DATE | Date of the session | `events.session_date` |
| `session_id` | STRING | Unique identifier for the session | `events.session_id` |
| `session_number` | INTEGER | Incremental session count for the user | `events.session_number` |
| `cross_domain_session` | STRING | Flag for cross-domain sessions | `events.cross_domain_session` |
| `session_start_timestamp` | INTEGER | Session start timestamp | `events.session_start_timestamp` |
| `session_duration_sec` | INTEGER | Session duration in seconds | `events.session_duration_sec` |
| `new_session` | INTEGER | 1 if new session, else 0 | `events.new_session` |
| `returning_session` | INTEGER | 1 if returning session, else 0 | `events.returning_session` |
| `session_channel_grouping` | STRING | Session channel grouping | `events.session_channel_grouping` |
| `session_source` | STRING | Session source | `split(session_tld_source, '.')[0]` |
| `session_tld_source` | STRING | Session TLD source | `events.session_tld_source` |
| `session_campaign` | STRING | Session campaign name | `events.session_campaign` |
| `session_campaign_click_id` | STRING | Session campaign click ID | `events.session_campaign_click_id` |
| `session_campaign_term` | STRING | Session campaign term | `events.session_campaign_term` |
| `session_campaign_content` | STRING | Session campaign content | `events.session_campaign_content` |
| `session_device_type` | STRING | Session device type | `events.session_device_type` |
| `session_browser_name` | STRING | Browser name | `events.session_browser_name` |
| `session_country` | STRING | Session country | `events.session_country` |
| `session_language` | STRING | Session language | `events.session_language` |
| `session_landing_page_category` | STRING | Landing page category | `events.session_landing_page_category` |
| `session_landing_page_location` | STRING | Landing page URL | `events.session_landing_page_location` |
| `session_landing_page_title` | STRING | Landing page title | `events.session_landing_page_title` |
| `session_exit_page_category` | STRING | Exit page category | `events.session_exit_page_category` |
| `session_exit_page_location` | STRING | Exit page URL | `events.session_exit_page_location` |
| `session_exit_page_title` | STRING | Exit page title | `events.session_exit_page_title` |
| `session_hostname` | STRING | Hostname | `events.session_hostname` |
| **PAGE DATA** | | | |
| `page_date` | DATE | Date of the page activity | `events.page_date` |
| `page_id` | STRING | Unique page view ID | `events.page_id` |
| `page_view_number` | INTEGER | Sequential page number | `events.page_view_number` |
| `page_location` | STRING | Full URL location | `events.page_location` |
| `page_hostname` | STRING | Hostname | `events.page_hostname` |
| `page_title` | STRING | Title of the page | `events.page_title` |
| `page_category` | STRING | Category of the page | `events.page_category` |
| `page_load_datetime` | TIMESTAMP | Datetime of page load | `timestamp_millis(page_load_timestamp)` |
| `page_unload_datetime` | TIMESTAMP | Datetime of page unload | `timestamp_millis(page_unload_timestamp)` |
| `time_on_page` | FLOAT | Time spent on page (seconds) | `(page_unload_timestamp - page_load_timestamp) / 1000` |
| `time_to_dom_interactive` | FLOAT | Time to DOM interactive (seconds) | `max(events.time_to_dom_interactive) / 1000` |
| `page_render_time` | FLOAT | Page render time (seconds) | `max(events.page_render_time) / 1000` |
| `time_to_dom_complete` | FLOAT | Time to DOM complete (seconds) | `max(events.time_to_dom_complete) / 1000` |
| `page_load_time_sec` | FLOAT | Total load time (seconds) | `max(events.total_page_load_time) / 1000` |
| `page_status_code` | INTEGER | HTTP Status Code | `max(events.page_status_code)` |
| **EVENTS** | | | |
| `page_view` | INTEGER | Total view count (agg) | `sum(countif(event_name = 'page_view'))` |

</details>


#

### Transactions
Extracts and structures ecommerce transaction data, including revenue, tax, and shipping details.

[View SQL code](ec_transactions.sql)

<details><summary>View table schema</summary>

| Field name | Type | Description | Calculation / Logic |
| :--- | :--- | :--- | :--- |
| **USER DATA** | | | |
| `user_date` | DATE | Date of the user's first visit | `events.user_date` |
| `client_id` | STRING | Unique identifier for the user | `events.client_id` |
| `user_id` | STRING | Persistent user identifier | `events.user_id` |
| `user_channel_grouping` | STRING | Acquisition channel grouping | `events.user_channel_grouping` |
| `user_source` | STRING | Acquisition source | `split(user_tld_source, '.')[0]` |
| `user_tld_source` | STRING | Acquisition TLD source | `events.user_tld_source` |
| `user_campaign` | STRING | Acquisition campaign | `events.user_campaign` |
| `user_device_type` | STRING | Device type used | `events.user_device_type` |
| `user_country` | STRING | User's country | `events.user_country` |
| `user_language` | STRING | User's language | `events.user_language` |
| `user_type` | STRING | "new_user" or "returning_user" | `events.user_type` |
| `new_user` | STRING | Client ID if new user | `events.new_user` |
| `returning_user` | STRING | Client ID if returning user | `events.returning_user` |
| **SESSION DATA** | | | |
| `session_number` | INTEGER | Incremental session count for the user | `events.session_number` |
| `session_id` | STRING | Unique identifier for the session | `events.session_id` |
| `session_start_timestamp` | INTEGER | Session start timestamp | `events.session_start_timestamp` |
| `session_channel_grouping` | STRING | Session channel grouping | `events.session_channel_grouping` |
| `session_source` | STRING | Session source | `split(session_tld_source, '.')[0]` |
| `session_tld_source` | STRING | Session TLD source | `events.session_tld_source` |
| `session_campaign` | STRING | Session campaign name | `events.session_campaign` |
| `cross_domain_session` | STRING | Flag for cross-domain sessions | `events.cross_domain_session` |
| `session_device_type` | STRING | Session device type | `events.session_device_type` |
| `session_country` | STRING | Session country | `events.session_country` |
| `session_language` | STRING | Session language | `events.session_language` |
| `session_browser_name` | STRING | Browser name | `events.session_browser_name` |
| **EVENT DATA** | | | |
| `event_date` | DATE | Event date | `events.event_date` |
| `event_name` | STRING | Event name | `events.event_name` |
| `event_timestamp` | TIMESTAMP | Event timestamp | `timestamp_millis(event_timestamp)` |
| **ECOMMERCE DATA** | | | |
| `transaction_id` | STRING | Unique transaction ID | `json_value(ecommerce, '$.transaction_id')` |
| `purchase` | INTEGER | Purchase count | `countif(event_name = 'purchase')` |
| `refund` | INTEGER | Refund count | `countif(event_name = 'refund')` |
| `transaction_currency` | STRING | Currency code | `json_value(ecommerce, '$.currency')` |
| `transaction_coupon` | STRING | Coupon code | `json_value(ecommerce, '$.coupon')` |
| `purchase_revenue` | FLOAT | Revenue from purchases | `sum(json_value(ecommerce, '$.value')) if purchase` |
| `purchase_shipping` | FLOAT | Shipping revenue | `sum(json_value(ecommerce, '$.shipping')) if purchase` |
| `purchase_tax` | FLOAT | Tax revenue | `sum(json_value(ecommerce, '$.tax')) if purchase` |
| `refund_revenue` | FLOAT | Total refunded revenue | `sum(json_value(ecommerce, '$.value')) if refund` |
| `refund_shipping` | FLOAT | Refunded shipping | `sum(json_value(ecommerce, '$.shipping')) if refund` |
| `refund_tax` | FLOAT | Refunded tax | `sum(json_value(ecommerce, '$.tax')) if refund` |
| `purchase_net_refund` | INTEGER | Net purchases (minus refunds) | `purchase - refund` |
| `revenue_net_refund` | FLOAT | Net revenue (minus refunds) | `purchase_revenue - refund_revenue` |
| `shipping_net_refund` | FLOAT | Net shipping | `purchase_shipping + refund_shipping` |
| `tax_net_refund` | FLOAT | Net tax | `purchase_tax + refund_tax` |

</details>


#

### Products
Provides a granular view of product performance, including views, add-to-carts, and purchases per SKU.

[View SQL code](ec_products.sql)

<details><summary>View table schema</summary>

| Field name | Type | Description | Calculation / Logic |
| :--- | :--- | :--- | :--- |
| **USER DATA** | | | |
| `user_date` | DATE | Date of the user's first visit | `events.user_date` |
| `client_id` | STRING | Unique identifier for the user | `events.client_id` |
| `user_id` | STRING | Persistent user identifier | `events.user_id` |
| `user_channel_grouping` | STRING | Acquisition channel grouping | `events.user_channel_grouping` |
| `user_source` | STRING | Acquisition source | `split(user_tld_source, '.')[0]` |
| `user_tld_source` | STRING | Acquisition TLD source | `events.user_tld_source` |
| `user_campaign` | STRING | Acquisition campaign | `events.user_campaign` |
| `user_device_type` | STRING | Device type used | `events.user_device_type` |
| `user_country` | STRING | User's country | `events.user_country` |
| `user_language` | STRING | User's language | `events.user_language` |
| `user_type` | STRING | "new_user" or "returning_user" | `events.user_type` |
| `new_user` | STRING | Client ID if new user | `events.new_user` |
| `returning_user` | STRING | Client ID if returning user | `events.returning_user` |
| **SESSION DATA** | | | |
| `session_number` | INTEGER | Incremental session count for the user | `events.session_number` |
| `session_id` | STRING | Unique identifier for the session | `events.session_id` |
| `session_start_timestamp` | INTEGER | Session start timestamp | `events.session_start_timestamp` |
| `session_channel_grouping` | STRING | Session channel grouping | `events.session_channel_grouping` |
| `session_source` | STRING | Session source | `split(session_tld_source, '.')[0]` |
| `session_tld_source` | STRING | Session TLD source | `events.session_tld_source` |
| `session_campaign` | STRING | Session campaign name | `events.session_campaign` |
| `cross_domain_session` | STRING | Flag for cross-domain sessions | `events.cross_domain_session` |
| `session_device_type` | STRING | Session device type | `events.session_device_type` |
| `session_country` | STRING | Session country | `events.session_country` |
| `session_language` | STRING | Session language | `events.session_language` |
| `session_browser_name` | STRING | Browser name | `events.session_browser_name` |
| **EVENT DATA** | | | |
| `event_date` | DATE | Event date | `events.event_date` |
| `event_name` | STRING | Event name | `events.event_name` |
| `event_timestamp` | TIMESTAMP | Event timestamp | `timestamp_millis(event_timestamp)` |
| **ECOMMERCE DATA** | | | |
| `transaction_id` | STRING | Transaction ID | `json_value(ecommerce, '$.transaction_id')` |
| `list_id` | STRING | List ID (deprecated?) | `json_value(ecommerce, '$.item_list_id')` |
| `list_name` | STRING | List Name (deprecated?) | `json_value(ecommerce, '$.item_list_name')` |
| `item_list_id` | STRING | List ID | `json_value(items, '$.item_list_id')` |
| `item_list_name` | STRING | List Name | `json_value(items, '$.item_list_name')` |
| `item_affiliation` | STRING | Item affiliation | `json_value(items, '$.affiliation')` |
| `item_coupon` | STRING | Item coupon | `json_value(items, '$.coupon')` |
| `item_discount` | FLOAT | Item discount | `safe_cast(json_value(items, '$.discount'))` |
| `creative_name` | STRING | Creative name | `json_value(ecommerce, '$.creative_name')` |
| `creative_slot` | STRING | Creative slot | `json_value(ecommerce, '$.creative_slot')` |
| `promotion_id` | STRING | Promotion ID | `json_value(ecommerce, '$.promotion_id')` |
| `promotion_name` | STRING | Promotion name | `json_value(ecommerce, '$.promotion_name')` |
| `item_brand` | STRING | Brand | `json_value(items, '$.item_brand')` |
| `item_id` | STRING | Product ID | `json_value(items, '$.item_id')` |
| `item_name` | STRING | Product Name | `json_value(items, '$.item_name')` |
| `item_variant` | STRING | Variant | `json_value(items, '$.item_variant')` |
| `item_category` | STRING | Category Level 1 | `json_value(items, '$.item_category')` |
| `item_category_2` | STRING | Category Level 2 | `json_value(items, '$.item_category2')` |
| `item_category_3` | STRING | Category Level 3 | `json_value(items, '$.item_category3')` |
| `item_category_4` | STRING | Category Level 4 | `json_value(items, '$.item_category4')` |
| `item_category_5` | STRING | Category Level 5 | `json_value(items, '$.item_category5')` |
| `view_promotion` | INTEGER | View promotion count | `countif(event_name = 'view_promotion')` |
| `select_promotion` | INTEGER | Select promotion count | `countif(event_name = 'select_promotion')` |
| `view_item_list` | INTEGER | View item list count | `countif(event_name = 'view_item_list')` |
| `select_item` | INTEGER | Select item count | `countif(event_name = 'select_item')` |
| `view_item` | INTEGER | View item count | `countif(event_name = 'view_item')` |
| `add_to_wishlist` | INTEGER | Add to wishlist count | `countif(event_name = 'add_to_wishlist')` |
| `add_to_cart` | INTEGER | Add to cart count | `countif(event_name = 'add_to_cart')` |
| `remove_from_cart` | INTEGER | Remove from cart count | `countif(event_name = 'remove_from_cart')` |
| `view_cart` | INTEGER | View cart count | `countif(event_name = 'view_cart')` |
| `begin_checkout` | INTEGER | Begin checkout count | `countif(event_name = 'begin_checkout')` |
| `add_shipping_info` | INTEGER | Add shipping info count | `countif(event_name = 'add_shipping_info')` |
| `add_payment_info` | INTEGER | Add payment info count | `countif(event_name = 'add_payment_info')` |
| `item_quantity_purchased` | INTEGER | Quantity purchased | `sum(quantity) if event_name = 'purchase'` |
| `item_quantity_refunded` | INTEGER | Quantity refunded | `sum(quantity) if event_name = 'refund'` |
| `item_quantity_added_to_cart` | INTEGER | Quantity added to cart | `sum(quantity) if event_name = 'add_to_cart'` |
| `item_quantity_removed_from_cart` | INTEGER | Quantity removed from cart | `sum(quantity) if event_name = 'remove_from_cart'` |
| `item_purchase_revenue` | FLOAT | Revenue from item | `sum(price * quantity) if event_name = 'purchase'` |
| `item_refund_revenue` | FLOAT | Refunded item revenue | `-sum(price * quantity) if event_name = 'refund'` |
| `item_unique_purchases` | INTEGER | Unique purchases | `count(distinct item_name) where name = 'purchase'` |
| `item_revenue_net_refund` | FLOAT | Net revenue | `item_purchase_revenue + item_refund_revenue` |

</details>


#

### Shopping stages open funnel
Calculates drop-off rates across the entire shopping journey, regardless of where the user started.

[View SQL code](ec_shopping_stages_open_funnel.sql)

<details><summary>View table schema</summary>

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
| Field name | Type | Description | Calculation / Logic |
| :--- | :--- | :--- | :--- |
| `event_date` | DATE | Event date | `events.event_date` |
| `step_name` | STRING | Name of the funnel step | `0-All, 1-View item, 2-Add to cart, ..., 6-Purchase` |
| `client_id_next_step` | STRING | Client ID reaching next step | `client_id` if target next step was reached |
| `user_id_next_step` | STRING | User ID reaching next step | `user_id` if target next step was reached |
| `session_id_next_step` | STRING | Session ID reaching next step | `session_id` if target next step was reached |

</details>


#

### Shopping stages closed funnel
Analyzes the shopping journey for users who follow a specific, linear sequence of steps.

[View SQL code](ec_shopping_stages_closed_funnel.sql)

<details><summary>View table schema</summary>

| Field name | Type | Description |
| :--- | :--- | :--- |
| Field name | Type | Description | Calculation / Logic |
| :--- | :--- | :--- | :--- |
| `step_name` | STRING | Name of the funnel step | `0-All, 1-View item, 2-Add to cart, ..., 6-Purchase` |
| `step_index` | INTEGER | Order index of the step | `0, 1, 2, ..., 6` |
| `client_id` | STRING | User identifier at this step | `events.client_id` |
| `client_id_next_step` | STRING | Identifier if user reached next step | `client_id` if target next step was reached |
| `session_id` | STRING | Session identifier | `events.session_id` |
| `user_type` | STRING | User type | `events.user_type` |
| `session_source` | STRING | Session source | `events.session_source` |
| `session_channel_grouping` | STRING | Session channel grouping | `events.session_channel_grouping` |
| `session_device_type` | STRING | Device type | `events.session_device_type` |
| `session_country` | STRING | Country | `events.session_country` |

</details>


#

### GTM performances
Provides metrics on GTM container execution times and tag performance to help optimize site speed.

[View SQL code](gtm_performances.sql)

<details><summary>View table schema</summary>

| Field name | Type | Description |
| :--- | :--- | :--- |
| **USER DATA** | | |
| Field name | Type | Description | Calculation / Logic |
| :--- | :--- | :--- | :--- |
| **USER DATA** | | | |
| `user_date` | DATE | Date of the user's first visit | `events.user_date` |
| `client_id` | STRING | Unique identifier for the user | `events.client_id` |
| `user_id` | STRING | Persistent user identifier | `events.user_id` |
| `user_channel_grouping` | STRING | Acquisition channel grouping | `events.user_channel_grouping` |
| `user_source` | STRING | Acquisition source | `events.user_source` |
| `user_tld_source` | STRING | Acquisition TLD source | `events.user_tld_source` |
| `user_campaign` | STRING | Acquisition campaign | `events.user_campaign` |
| `user_device_type` | STRING | Device type used | `events.user_device_type` |
| `user_country` | STRING | User's country | `events.user_country` |
| `user_language` | STRING | User's language | `events.user_language` |
| `user_type` | STRING | "new_user" or "returning_user" | `events.user_type` |
| `new_user` | STRING | Client ID if new user | `events.new_user` |
| `returning_user` | STRING | Client ID if returning user | `events.returning_user` |
| **SESSION DATA** | | | |
| `session_date` | DATE | Date of the session | `events.session_date` |
| `session_number` | INTEGER | Incremental session count for the user | `events.session_number` |
| `session_id` | STRING | Unique identifier for the session | `events.session_id` |
| `session_start_timestamp` | INTEGER | Session start timestamp | `events.session_start_timestamp` |
| `session_end_timestamp` | INTEGER | Session end timestamp | `events.session_end_timestamp` |
| `session_duration_sec` | INTEGER | Session duration in seconds | `events.session_duration_sec` |
| `session_channel_grouping` | STRING | Session channel grouping | `events.session_channel_grouping` |
| `session_source` | STRING | Session source | `events.session_source` |
| `session_tld_source` | STRING | Session TLD source | `events.session_tld_source` |
| `session_campaign` | STRING | Session campaign name | `events.session_campaign` |
| `cross_domain_session` | STRING | Flag for cross-domain sessions | `events.cross_domain_session` |
| `session_landing_page_category` | STRING | Landing page category | `events.session_landing_page_category` |
| `session_landing_page_location` | STRING | Landing page URL | `events.session_landing_page_location` |
| `session_landing_page_title` | STRING | Landing page title | `events.session_landing_page_title` |
| `session_exit_page_category` | STRING | Exit page category | `events.session_exit_page_category` |
| `session_exit_page_location` | STRING | Exit page URL | `events.session_exit_page_location` |
| `session_exit_page_title` | STRING | Exit page title | `events.session_exit_page_title` |
| `session_hostname` | STRING | Hostname | `events.session_hostname` |
| `session_device_type` | STRING | Session device type | `events.session_device_type` |
| `session_country` | STRING | Session country | `events.session_country` |
| `session_language` | STRING | Session language | `events.session_language` |
| `session_browser_name` | STRING | Browser name | `events.session_browser_name` |
| **PAGE DATA** | | | |
| `page_data` | ARRAY | Raw page data array | `events.page_data` |
| **EVENT DATA** | | | |
| `event_date` | DATE | Event date | `events.event_date` |
| `event_datetime` | TIMESTAMP | Event datetime | `timestamp_millis(event_timestamp)` |
| `event_timestamp` | INTEGER | Event timestamp | `events.event_timestamp` |
| `processing_event_timestamp` | INTEGER | Server-side processing timestamp | `events.processing_event_timestamp` |
| `delay_in_milliseconds` | INTEGER | Processing delay (ms) | `processing_event_timestamp - event_timestamp` |
| `delay_in_seconds` | FLOAT | Processing delay (seconds) | `(processing_event_timestamp - event_timestamp) / 1000` |
| `event_origin` | STRING | Origin of the event | `events.event_origin` |
| `content_length` | INTEGER | Request content length | `events.content_length` |
| `cs_hostname` | STRING | Client-side hostname | `events.cs_hostname` |
| `ss_hostname` | STRING | Server-side hostname | `events.ss_hostname` |
| `cs_container_id` | STRING | Client-side container ID | `events.cs_container_id` |
| `ss_container_id` | STRING | Server-side container ID | `events.ss_container_id` |
| `hit_number` | INTEGER | Sequential hit number | `row_number() over(partition by session_id order by event_timestamp)` |
| `event_name` | STRING | Event name | `events.event_name` |
| `event_id` | STRING | Event ID | `events.event_id` |
| `event_data` | ARRAY | Raw event data array | `events.event_data` |
| `ecommerce` | JSON | Ecommerce object (stringified) | `to_json_string(events.ecommerce)` |
| `dataLayer` | JSON | DataLayer object (stringified) | `to_json_string(events.datalayer)` |

</details>


#

### Consents
Tracks changes in user consent status over time, ensuring compliance and data transparency.

[View SQL code](consents.sql)

<details><summary>View table schema</summary>

| Field name | Type | Description |
| :--- | :--- | :--- |
| Field name | Type | Description | Calculation / Logic |
| :--- | :--- | :--- | :--- |
| `event_date` | DATE | Event date | `events.event_date` |
| `event_timestamp` | INTEGER | Timestamp | `events.event_timestamp` |
| `event_name` | STRING | Event name | `events.event_name` |
| `consent_type` | STRING | Update type (default/update) | `consent_data.consent_type` |
| `respect_consent_mode` | STRING | Consent mode enabled flag | `consent_data.respect_consent_mode` |
| `ad_storage` | STRING | Ad storage consent | `consent_data.ad_storage` |
| `analytics_storage` | STRING | Analytics storage consent | `consent_data.analytics_storage` |
| `ad_user_data` | STRING | Ad user data consent | `consent_data.ad_user_data` |
| `ad_personalization` | STRING | Ad personalization consent | `consent_data.ad_personalization` |
| `functionality_storage` | STRING | Functional cookies | `consent_data.functionality_storage` |
| `personalization_storage` | STRING | Personalization cookies | `consent_data.personalization_storage` |
| `security_storage` | STRING | Security cookies | `consent_data.security_storage` |
| `client_id` | STRING | User identifier | `events.client_id` |
| `session_id` | STRING | Session identifier | `events.session_id` |

</details>



</br>
</br>

## Reporting fields
This table illustrates the fields available across different table functions, allowing you to easily identify common data points and specific metrics for each report.

<details><summary>Output Fields Matrix</summary>

| Scope | Field Name | Events | Users | Sessions | Pages | Transactions | Products | Open Funnel | Closed Funnel | GTM Performances | Consents |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **USER DATA** | `avg_purchase_value` | | X | | | | | | | | |
| | `avg_refund_value` | | X | | | | | | | | |
| | `client_id` | X | X | X | X | X | X | X | X | X | X |
| | `customer_type` | | X | | | | | | | | |
| | `customers` | | X | | | | | | | | |
| | `days_from_first_purchase` | | X | | | | | | | | |
| | `days_from_first_to_last_visit` | X | X | | | | | | | | |
| | `days_from_first_visit` | X | X | | | | | | | | |
| | `days_from_last_purchase` | | X | | | | | | | | |
| | `days_from_last_visit` | X | X | | | | | | | | |
| | `is_customer` | | X | | | | | | | | |
| | `item_quantity_purchased` | | X | | | | X | | | | |
| | `item_quantity_refunded` | | X | | | | X | | | | |
| | `new_customers` | | X | | | | | | | | |
| | `new_user` | X | | X | X | X | X | | X | X | X |
| | `new_user_client_id` | | X | | | | | | | | |
| | `new_users_percentage` | | | X | | | | | | | |
| | `page_view` | | X | X | X | | | | | | |
| | `purchase` | | X | X | | X | | | | | |
| | `purchase_revenue` | | X | X | | X | | | | | |
| | `refund` | | X | X | | X | | | | | |
| | `refund_revenue` | | X | X | | X | | | | | |
| | `respect_consent_mode` | X | | | | | | | | | |
| | `returning_customers` | | X | | | | | | | | |
| | `returning_user` | X | | X | X | X | X | | X | X | X |
| | `returning_user_client_id` | | X | | | | | | | | |
| | `returning_users_percentage` | | | X | | | | | | | |
| | `revenue_net_refund` | | X | X | | X | | | | | |
| | `sessions` | | X | | | | | | | | |
| | `user_campaign` | X | X | X | X | X | X | | X | X | X |
| | `user_campaign_click_id` | X | X | X | X | | | | | | |
| | `user_campaign_content` | X | X | X | X | | | | | | |
| | `user_campaign_id` | X | | | | | | | | | |
| | `user_campaign_term` | X | X | X | X | | | | | | |
| | `user_channel_grouping` | X | X | X | X | X | X | | X | X | X |
| | `user_conversion_rate` | | | X | | | | | | | |
| | `user_country` | X | X | X | X | X | X | | X | X | X |
| | `user_data` | X | | | | | | | | | |
| | `user_date` | X | X | X | X | X | X | | X | X | X |
| | `user_device_type` | X | X | X | X | X | X | | X | X | X |
| | `user_first_session_timestamp` | X | | | | | | | | | |
| | `user_id` | X | | X | | X | X | X | X | X | X |
| | `user_language` | X | X | X | X | X | X | | X | X | X |
| | `user_last_session_timestamp` | X | | | | | | | | | |
| | `user_source` | X | X | X | X | X | X | | X | X | X |
| | `user_tld_source` | X | X | X | X | X | X | | X | X | X |
| | `user_type` | X | X | X | X | X | X | | X | X | X |
| | `user_value` | | | X | | | | | | | |
| **SESSION DATA** | `cross_domain_session` | X | | X | X | X | X | | X | X | X |
| | `engaged_session` | | | X | | | | | | | X |
| | `engaged_sessions_percentage` | | | X | | | | | | | |
| | `first_session` | | | X | | | | | | | X |
| | `new_session` | X | | X | X | | | | | | |
| | `new_sessions_percentage` | | | X | | | | | | | |
| | `page_view_per_session` | | | X | | | | | | | |
| | `returning_session` | X | | X | X | | | | | | |
| | `returning_sessions_percentage` | | | X | | | | | | | |
| | `session_browser_name` | X | | X | X | X | X | | X | X | X |
| | `session_campaign` | X | | X | X | X | X | X | X | X | X |
| | `session_campaign_click_id` | X | | X | X | | | | | | |
| | `session_campaign_content` | X | | X | X | | | | | | |
| | `session_campaign_id` | X | | X | X | | | | | | |
| | `session_campaign_term` | X | | X | X | | | | | | |
| | `session_channel_grouping` | X | | X | X | X | X | X | X | X | X |
| | `session_conversion_rate` | | | X | | | | | | | |
| | `session_country` | X | | X | X | X | X | X | X | X | X |
| | `session_data` | X | | | | | | | | | |
| | `session_date` | X | | X | X | | | | X | X | X |
| | `session_device_type` | X | | X | X | X | X | X | X | X | X |
| | `session_duration_sec` | X | X | X | X | | | | X | X | X |
| | `session_end_timestamp` | X | | | | | | | X | X | |
| | `session_exit_page_category` | X | | X | X | | | | X | X | X |
| | `session_exit_page_location` | X | | X | X | | | | X | X | X |
| | `session_exit_page_title` | X | | X | X | | | | X | X | X |
| | `session_hostname` | X | | X | X | | | | X | X | X |
| | `session_id` | X | | X | X | X | X | X | X | X | X |
| | `session_landing_page_category` | X | | X | X | | | | X | X | X |
| | `session_landing_page_location` | X | | X | X | | | | X | X | X |
| | `session_landing_page_title` | X | | X | X | | | | X | X | X |
| | `session_language` | X | | X | X | X | X | X | X | X | X |
| | `session_number` | X | | X | X | X | X | | X | X | X |
| | `session_source` | X | | X | X | X | X | X | X | X | X |
| | `session_start_timestamp` | X | | X | X | X | X | X | X | X | X |
| | `session_tld_source` | X | | X | X | X | X | X | X | X | X |
| | `session_value` | | | X | | | | | | | |
| | `sessions_per_user` | | | X | | | | | | | |
| **PAGE DATA** | `page_category` | X | | | X | | | | | | |
| | `page_data` | X | | | | | | | | X | |
| | `page_date` | X | | | X | | | | | | |
| | `page_extension` | X | | | | | | | | | |
| | `page_fragment` | X | | | | | | | | | |
| | `page_hostname` | X | | | X | | | | | | |
| | `page_hostname_protocol` | X | | | | | | | | | |
| | `page_id` | X | | | X | | | | | | |
| | `page_language` | X | | | | | | | | | |
| | `page_load_datetime` | | | | X | | | | | | |
| | `page_load_time_sec` | | | | X | | | | | | |
| | `page_load_timestamp` | X | | | | | | | | | |
| | `page_location` | X | | | X | | | | | | |
| | `page_query` | X | | | | | | | | | |
| | `page_referrer` | X | | | | | | | | | |
| | `page_status_code` | X | | | X | | | | | | |
| | `page_title` | X | | | X | | | | | | |
| | `page_unload_datetime` | | | | X | | | | | | |
| | `page_unload_timestamp` | X | | | | | | | | | |
| | `page_view_number` | X | | | X | | | | | | |
| | `time_on_page` | X | | | X | | | | | | |
| **EVENT DATA** | `browser_language` | X | | | | | | | | | |
| | `browser_name` | X | | | | | | | | | |
| | `browser_version` | X | | | | | | | | | |
| | `campaign` | X | | | | | | | | | |
| | `campaign_click_id` | X | | | | | | | | | |
| | `campaign_content` | X | | | | | | | | | |
| | `campaign_id` | X | | | | | | | | | |
| | `campaign_term` | X | | | | | | | | | |
| | `channel_grouping` | X | | | | | | | | | |
| | `city` | X | | | | | | | | | |
| | `country` | X | | | | | | | | | |
| | `cross_domain_id` | X | | | | | | | | | |
| | `device_model` | X | | | | | | | | | |
| | `device_type` | X | | | | | | | | | |
| | `device_vendor` | X | | | | | | | | | |
| | `event_data` | X | | | | | | | | X | |
| | `event_date` | X | | | | X | X | X | X | X | |
| | `event_datetime` | | | | | | | | | X | |
| | `event_id` | X | | | | | | | | X | |
| | `event_name` | X | | | | X | X | X | | X | |
| | `event_number` | X | | | | | | | | | |
| | `event_timestamp` | X | | | | X | X | | | X | |
| | `event_type` | X | | | | | | | | | |
| | `hit_number` | | | | | | | | | X | |
| | `os_name` | X | | | | | | | | | |
| | `os_version` | X | | | | | | | | | |
| | `page_render_time` | X | | | X | | | | | | |
| | `screen_size` | X | | | | | | | | | |
| | `search_term` | X | | | | | | | | | |
| | `source` | X | | | | | | | | | |
| | `time_to_dom_complete` | X | | | X | | | | | | |
| | `time_to_dom_interactive` | X | | | X | | | | | | |
| | `tld_source` | X | | | | | | | | | |
| | `total_page_load_time` | X | | | | | | | | | |
| | `user_agent` | X | | | | | | | | | |
| | `viewport_size` | X | | | | | | | | | |
| **DATALAYER DATA** | `datalayer` | X | | | | | | | | X | |
| **ECOMMERCE DATA** | `add_payment_info` | | | X | | | X | | | | |
| | `add_shipping_info` | | | X | | | X | | | | |
| | `add_to_cart` | | | X | | | X | | | | |
| | `add_to_wishlist` | | | X | | | X | | | | |
| | `avg_order_value` | | | X | | | | | | | |
| | `begin_checkout` | | | X | | | X | | | | |
| | `client_id_next_step` | | | | | | | X | X | | |
| | `creative_name` | | | | | | X | | | | |
| | `creative_slot` | | | | | | X | | | | |
| | `ecommerce` | X | | | | | | | | X | |
| | `item_affiliation` | | | | | | X | | | | |
| | `item_brand` | | | | | | X | | | | |
| | `item_category` | | | | | | X | | | | |
| | `item_category_2` | | | | | | X | | | | |
| | `item_category_3` | | | | | | X | | | | |
| | `item_category_4` | | | | | | X | | | | |
| | `item_category_5` | | | | | | X | | | | |
| | `item_coupon` | | | | | | X | | | | |
| | `item_discount` | | | | | | X | | | | |
| | `item_id` | | | | | | X | | | | |
| | `item_list_id` | | | | | | X | | | | |
| | `item_list_name` | | | | | | X | | | | |
| | `item_name` | | | | | | X | | | | |
| | `item_purchase_revenue` | | | | | | X | | | | |
| | `item_quantity_added_to_cart` | | | | | | X | | | | |
| | `item_quantity_purchased` | | X | | | | X | | | | |
| | `item_quantity_refunded` | | X | | | | X | | | | |
| | `item_quantity_removed_from_cart` | | | | | | X | | | | |
| | `item_refund_revenue` | | | | | | X | | | | |
| | `item_revenue_net_refund` | | | | | | X | | | | |
| | `item_unique_purchases` | | | | | | X | | | | |
| | `item_variant` | | | | | | X | | | | |
| | `list_id` | | | | | | X | | | | |
| | `list_name` | | | | | | X | | | | |
| | `promotion_id` | | | | | | X | | | | |
| | `promotion_name` | | | | | | X | | | | |
| | `purchase` | | X | X | | X | | | | | |
| | `purchase_net_refund` | | | X | | X | | | | | |
| | `purchase_revenue` | | X | X | | X | | | | | |
| | `purchase_shipping` | | | X | | X | | | | | |
| | `purchase_tax` | | | X | | X | | | | | |
| | `refund` | | X | X | | X | | | | | |
| | `refund_revenue` | | X | X | | X | | | | | |
| | `refund_shipping` | | | X | | X | | | | | |
| | `refund_tax` | | | X | | X | | | | | |
| | `remove_from_cart` | | | X | | | X | | | | |
| | `revenue_net_refund` | | X | X | | X | | | | | |
| | `select_item` | | | X | | | X | | | | |
| | `select_promotion` | | | | | | X | | | | |
| | `session_id_next_step` | | | | | | | X | X | | |
| | `shipping_net_refund` | | | X | | X | | | | | |
| | `status` | | | | | | | X | | | |
| | `step_index` | | | | | | | X | | | |
| | `step_index_next_step` | | | | | | | X | | | |
| | `step_index_next_step_real` | | | | | | | X | | | |
| | `step_name` | | | | | | | X | X | | |
| | `tax_net_refund` | | | X | | X | | | | | |
| | `transaction_coupon` | | | | | X | | | | | |
| | `transaction_currency` | | | | | X | | | | | |
| | `transaction_id` | | | | | X | X | | | | |
| | `user_id_next_step` | | | | | | | | X | | |
| | `view_cart` | | | X | | | X | | | | |
| | `view_item` | | | X | | | X | | | | |
| | `view_item_list` | | | X | | | X | | | | |
| | `view_promotion` | | | | | | X | | | | |
| **CONSENT DATA** | `ad_personalization` | X | | | | | | | | | |
| | `ad_personalization_accepted_percentage` | | | X | | | | | | | |
| | `ad_personalization_denied_percentage` | | | X | | | | | | | |
| | `ad_storage` | X | | | | | | | | | |
| | `ad_storage_accepted_percentage` | | | X | | | | | | | |
| | `ad_storage_denied_percentage` | | | X | | | | | | | |
| | `ad_user_data` | X | | | | | | | | | |
| | `ad_user_data_accepted_percentage` | | | X | | | | | | | |
| | `ad_user_data_denied_percentage` | | | X | | | | | | | |
| | `analytics_storage` | X | | | | | | | | | |
| | `analytics_storage_accepted_percentage` | | | X | | | | | | | |
| | `analytics_storage_denied_percentage` | | | X | | | | | | | |
| | `consent_expressed` | | | X | | | | | | | |
| | `consent_name` | | | | | | | | | | X |
| | `consent_state` | | | | | | | | | | X |
| | `consent_timestamp` | | | X | | | | | | | |
| | `consent_type` | X | | | | | | | | | |
| | `consent_value_int_accepted` | | | | | | | | | | X |
| | `consent_value_int_denied` | | | | | | | | | | X |
| | `consent_value_string` | | | | | | | | | | X |
| | `functionality_storage` | X | | | | | | | | | |
| | `functionality_storage_accepted_percentage` | | | X | | | | | | | |
| | `functionality_storage_denied_percentage` | | | X | | | | | | | |
| | `personalization_storage` | X | | | | | | | | | |
| | `respect_consent_mode` | X | | | | | | | | | |
| | `security_storage` | X | | | | | | | | | |
| | `security_storage_accepted_percentage` | | | X | | | | | | | |
| | `security_storage_denied_percentage` | | | X | | | | | | | |
| | `session_ad_personalization` | | | X | | | | | | | |
| | `session_ad_storage` | | | X | | | | | | | |
| | `session_ad_user_data` | | | X | | | | | | | |
| | `session_analytics_storage` | | | X | | | | | | | |
| | `session_functionality_storage` | | | X | | | | | | | |
| | `session_id_consent_expressed` | | | | | | | | | | X |
| | `session_id_consent_mode_not_present` | | | | | | | | | | X |
| | `session_id_consent_not_expressed` | | | | | | | | | | X |
| | `session_personalization_storage` | | | X | | | | | | | |
| | `session_security_storage` | | | X | | | | | | | |
| **REQUEST DATA** | `content_length` | X | | | | | | | | X | |
| | `cs_container_id` | X | | | | | | | | X | |
| | `cs_hostname` | X | | | | | | | | X | |
| | `cs_tag_id` | X | | | | | | | | | |
| | `cs_tag_name` | X | | | | | | | | | |
| | `delay_in_milliseconds` | | | | | | | | | X | |
| | `delay_in_seconds` | | | | | | | | | X | |
| | `event_origin` | X | | | | | | | | X | |
| | `gtm_data` | X | | | | | | | | | |
| | `processing_event_timestamp` | X | | | | | | | | X | |
| | `ss_container_id` | X | | | | | | | | X | |
| | `ss_hostname` | X | | | | | | | | X | |
| | `ss_tag_id` | X | | | | | | | | | |
| | `ss_tag_name` | X | | | | | | | | | |
</details>

</br>

---

Reach me at: [Email](mailto:hello@tommasomoretti.com) | [Website](https://tommasomoretti.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics) | [Twitter](https://twitter.com/tommoretti88) | [LinkedIn](https://www.linkedin.com/in/tommasomoretti/)
