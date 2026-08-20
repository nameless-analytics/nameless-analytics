/* @datacloud.settings
{
  "version": 1,
  "service": "BIG_QUERY",
  "connectionInfo": {
    "billingProjectId": "INHERIT",
    "location": "INHERIT"
  },
  "dialect": "GOOGLE_SQL"
}
*/

# NAMELESS ANALYTICS

# Project settings
declare project_name string default 'PROJECT NAME';  -- Change this
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
      `region-%s.query_runtime` = 'advanced' # default null
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
# execute immediate enable_bigquery_advanced_runtime; 

# Create main dataset
# execute immediate main_dataset_sql; 

# Create main table
execute immediate main_table_sql; 

# Create dates table
# execute immediate dates_table_sql; 