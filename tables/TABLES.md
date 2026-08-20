# Nameless Analytics | Reporting Tables
The Nameless Analytics Reporting Tables provide a structured set of BigQuery resources where user, session, and event data are centrally stored and processed.

For an overview of how Nameless Analytics works [start from here](../README.md#overview).

### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change



## Table of Contents

- [Setup](#setup)
  - [Create raw tables](#create-raw-tables)
  - [Create custom functions](#create-custom-functions)
  - [Create table functions](#create-table-functions)
- [Reporting fields](#reporting-fields)
- [Raw tables](#raw-tables)
- [Table functions](#table-functions)
  - [Events](#events)
  - [Events Debug](#events-debug)
  - [Users](#users)
  - [Users RFM](#users-rfm)
  - [Sessions](#sessions)
  - [Pages](#pages)
  - [Transactions](#transactions)
  - [Products](#products)
  - [Ecommerce Funnel](#ecommerce-funnel)
  - [Ecommerce Funnel Pivot](#ecommerce-funnel-pivot)
  - [Consents](#consents)
  - [Attribution Comparison](#attribution-comparison)
  - [Attribution Multi Touch](#attribution-multi-touch)
  - [Attribution Single Touch](#attribution-single-touch)
  - [Media Plan](#media-plan)
  - [Campaigns](#campaigns)
- [Data Governance and Maintenance](#data-governance-and-maintenance)
  - [Delete user data script](#delete-user-data-script)
  - [Manual user data deletion](#manual-user-data-deletion)
  - [Data Health Check](#data-health-check)

## Setup
The following SQL scripts are used to initialize the Nameless Analytics reporting environment in BigQuery.


### Create raw tables
This script is used to create the raw tables in BigQuery, the main dataset `nameless_analytics` and the `events_raw` and `calendar_dates` tables. This script also enables BigQuery advanced runtime, a more advanced query execution engine that automatically improves performance and efficiency for complex analytical queries. [Read more about it](https://cloud.google.com/bigquery/docs/advanced-runtime).

- [Raw tables](tables/tables.sql)


### Create custom functions
Create the custom user-defined functions (UDF) required for channel grouping and campaign parsing first by running the following SQL scripts:

The `get_custom_channel_grouping` UDF uses the same identical logic as the [server-side channel grouping](../README.md#channel-grouping-logic) to categorize traffic sources. It is used by the table functions to calculate the `custom_channel_grouping`, `session_custom_channel_grouping`, and `user_custom_channel_grouping` fields on the fly at query time. Since the UDF lives in BigQuery, it can be freely customized to adapt the channel grouping to specific analysis needs (e.g., adding new source categories or redefining grouping rules). Any change to this function will be retroactively applied to all historical data at query time.

The `get_campaign_part` UDF extracts structured campaign dimensions (year, country, funnel stage, platform, type, marketing objective, campaign name) from pipe-delimited campaign strings.

- [Custom Channel Grouping function](user-defined-functions/get_custom_channel_grouping.sql)
- [Get Campaign Part function](user-defined-functions/get_campaign_part.sql)


### Create table functions
To create the table functions you need, run the following SQL scripts in the order shown below:
- [Event table function](table-functions/events.sql)
- [Event Debug table function](table-functions/events_debug.sql)
- [Session table function](table-functions/sessions.sql)
- [User table function](table-functions/users.sql)
- [Page table function](table-functions/pages.sql)
- [Ecommerce Transaction table function](table-functions/ec_transactions.sql)
- [Ecommerce Product table function](table-functions/ec_products.sql)
- [Ecommerce Funnel table function](table-functions/ec_funnel.sql)
- [Ecommerce Funnel Pivot table function](table-functions/ec_funnel_pivot.sql)
- [Consents table function](table-functions/consents.sql)
- [Attribution Single Touch table function](table-functions/attribution_single_touch.sql)
- [Attribution Multi Touch table function](table-functions/attribution_multi_touch.sql)
- [Attribution Comparison table function](table-functions/attribution_comparison.sql)
- [User RFM table function](table-functions/users_rfm.sql)
- [Media Plan table function](table-functions/media_plan.sql)
- [Campaigns table function](table-functions/campaigns.sql)



## Reporting fields
The Reporting Fields Matrix provides an interactive overview of all reporting fields available across Nameless Analytics table functions, including functional scope, field type, value type, and field descriptions. The report is generated directly from the current BigQuery table function schemas, so it reflects the latest available reporting fields.

[Available metrics and dimensions](https://datastudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_05l6ownl6d)

</br>



## Raw tables
Raw tables are the foundational storage layer of Nameless Analytics, designed to capture and preserve every user interaction in its raw, unprocessed form. These tables serve as the single source of truth for all analytics data, storing event-level information with complete historical fidelity.

The architecture consists of two core tables: the **Events raw table** (`events_raw`), which stores all user, session, page, event, ecommerce, consent, and GTM performance data in a denormalized structure optimized for both write performance and analytical queries; and the **Dates table** (`calendar_dates`), a utility dimension table that provides comprehensive date attributes for time-based analysis and reporting.

All data is partitioned by date and clustered by key dimensions to ensure optimal query performance and cost efficiency when analyzing large datasets.

The main table is partitioned by `event_date` and clustered by `user_date`, `session_date`, `page_date`, and `event_name`.

The dates table is partitioned by `date` and clustered by `month_name` and `day_name`.



## Table functions
Table functions are predefined SQL queries that simplify data analysis by transforming raw event data into structured, easy-to-use formats for common reporting needs.

Unlike other systems, Nameless Analytics reporting functions are designed to work directly on the `events_raw` table as the single source of truth. By leveraging BigQuery window functions, they reflect the most up-to-date state of the data without requiring complex ETL processes or intermediate staging tables.

Streaming Protocol events are excluded from the calculation of the `session_duration_sec` and `time_on_page` fields.


### Events
Returns enriched event-level data for the selected date range and date scope, including user, session, page, event, ecommerce, consent, acquisition, device, and geographic attributes.

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

Always select data with the same data scope and date scope. 

For example: if you filter the events table function at event level, you probably will miss some data related to the user, like a change in his status that happened out of the selected date period.

[View SQL code](table-functions/events.sql)


### Events Debug
Returns event-level raw and typed parameter structures for debugging and data validation, including user, session, page, event, ecommerce, dataLayer, and consent data.

```sql
select * from `project.nameless_analytics.events_debug`(start_date, end_date)
```

[View SQL code](table-functions/events_debug.sql)


### Users
Aggregates event data at user level, including acquisition attributes, visit recency, customer classification, session metrics, and purchase/refund performance.

```sql
select * from `project.nameless_analytics.users`(start_date, end_date)
```

[View SQL code](table-functions/users.sql)


### Users RFM
Scores customers with at least one purchase using Recency, Frequency, and Monetary percentiles, normalized scores, discrete 1–5 scores, a configurable weighted RFM score, behavioral and value segments, and lifecycle status based on the configured churn window.

```sql
select * from `project.nameless_analytics.users_rfm`(start_date, end_date, churn_window_days, r_weight, f_weight, m_weight)
```

[View SQL code](table-functions/users_rfm.sql)


### Sessions
Aggregates event data at session level, including acquisition, engagement, behavioral events, ecommerce metrics, and consent states.

```sql
select * from `project.nameless_analytics.sessions`(start_date, end_date)
```

[View SQL code](table-functions/sessions.sql)


### Pages
Aggregates event data at page-view level, including page context, session and user dimensions, page timing, HTTP status, and page-view metrics.

```sql
select * from `project.nameless_analytics.pages`(start_date, end_date)
```

[View SQL code](table-functions/pages.sql)


### Transactions
Returns purchase and refund event rows enriched with transaction identifiers, revenue, tax, shipping, currency, coupon, and duplicate-event counts.

```sql
select * from `project.nameless_analytics.ec_transactions`(start_date, end_date)
```

[View SQL code](table-functions/ec_transactions.sql)


### Products
Aggregates ecommerce interaction data at item level, including product, list and promotion attributes, cart and wishlist actions, and purchase/refund quantities and revenue.

```sql
select * from `project.nameless_analytics.ec_products`(start_date, end_date)
```

[View SQL code](table-functions/ec_products.sql)


### Ecommerce Funnel
Builds a closed session-based ecommerce funnel from session start to purchase, marking each step as reached only when all preceding funnel event types are present in the same session.

```sql
select * from `project.nameless_analytics.ec_funnel`(start_date, end_date)
```

[View SQL code](table-functions/ec_funnel.sql)


### Ecommerce Funnel Pivot
Returns the closed ecommerce funnel in long format with one row per session and funnel step, including step reach status and next-step client ID for drop-off analysis.

```sql
select * from `project.nameless_analytics.ec_funnel_pivot`(start_date, end_date)
```

[View SQL code](table-functions/ec_funnel_pivot.sql)


### Consents
Returns consent data in long format with one row per session and consent category, including consent expression state and Granted/Denied indicators.

```sql
select * from `project.nameless_analytics.consents`(start_date, end_date)
```

[View SQL code](table-functions/consents.sql)


### Attribution Comparison
Aggregates attributed conversion credit and revenue by traffic dimensions across single-touch and multi-touch attribution models.

```sql
select * from `project.nameless_analytics.attribution_comparison`(start_date, end_date, conversion_name, lookback_days)
```

[View SQL code](table-functions/attribution_comparison.sql)


### Attribution Multi Touch
Calculates multi-touch attribution at touchpoint level using linear, time-decay, and position-based models across sessions within the specified lookback window.

```sql
select * from `project.nameless_analytics.attribution_multi_touch`(start_date, end_date, conversion_name, lookback_days)
```

[View SQL code](table-functions/attribution_multi_touch.sql)


### Attribution Single Touch
Calculates single-touch attribution per conversion using the user first click, the conversion-session last click, and the most recent non-direct session within the specified lookback window.

```sql
select * from `project.nameless_analytics.attribution_single_touch`(start_date, end_date, conversion_name, lookback_days)
```

[View SQL code](table-functions/attribution_single_touch.sql)


### Media Plan
Combines monthly planned campaign budgets with actual campaign spend for the selected date range, preserving campaign taxonomy dimensions.

```sql
select * from `project.nameless_analytics.media_plan`(start_date, end_date)
```

[View SQL code](table-functions/media_plan.sql)


### Campaigns
Combines daily campaign media performance with post-click user, session, conversion, ecommerce, and ROAS metrics.

```sql
select * from `project.nameless_analytics.campaigns`(start_date, end_date)
```

[View SQL code](table-functions/campaigns.sql)



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
DELETE FROM `project.nameless_analytics.events_raw`
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
FROM `project.nameless_analytics.events_raw`
WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY 1 
ORDER BY 1 DESC;
```

# ---

[Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_tables) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)

