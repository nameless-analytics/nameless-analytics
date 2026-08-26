# Nameless Analytics | Reporting Tables
The Nameless Analytics Reporting Tables provide a structured set of BigQuery resources where user, session, and event data are centrally stored and processed.

For an overview of how Nameless Analytics works [start from here](../README.md#overview).


### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change



## Table of Contents

- [Setup](#setup)
  - [Create raw tables](#create-raw-tables)
  - [Create custom functions](#create-custom-functions)
  - [Create external campaign tables](#create-external-campaign-tables)
  - [Create table functions](#create-table-functions)
- [Reporting fields](#reporting-fields)
- [Raw tables](#raw-tables)
  - [Dates are UTC](#dates-are-utc)
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
  - [Attribution Single Touch](#attribution-single-touch)
  - [Attribution Multi Touch](#attribution-multi-touch)
  - [Media Plan](#media-plan)
  - [Campaigns](#campaigns)
- [Data governance & maintenance](#data-governance--maintenance)
  - [Cookies are not deleted](#cookies-are-not-deleted)
  - [Delete user data script](#delete-user-data-script)
  - [Manual user data deletion](#manual-user-data-deletion)
  - [Data Health Check](#data-health-check)



## Setup
The following SQL scripts are used to initialize the Nameless Analytics reporting environment in BigQuery.


### Create raw tables
This script is used to create the raw tables in BigQuery, the main dataset `nameless_analytics` and the `events_raw` and `calendar_dates` tables.

This script also enables BigQuery advanced runtime, a more advanced query execution engine that automatically improves performance and efficiency for complex analytical queries. [Read more about it](https://cloud.google.com/bigquery/docs/advanced-runtime).

[Create Raw tables](tables/tables.sql)


### Create custom functions
Create the custom user-defined functions (UDF) required for channel grouping and campaign parsing first by running the following SQL scripts:

The `get_custom_channel_grouping` UDF uses the same identical logic as the [server-side channel grouping](../README.md#channel-grouping-logic) to categorize traffic sources. It is used by the table functions to calculate the `custom_channel_grouping`, `session_custom_channel_grouping`, and `user_custom_channel_grouping` fields on the fly at query time. Since the UDF lives in BigQuery, it can be freely customized to adapt the channel grouping to specific analysis needs (e.g., adding new source categories or redefining grouping rules). Any change to this function will be retroactively applied to all historical data at query time.

The `get_campaign_part` UDF extracts structured campaign dimensions (year, country, funnel stage, platform, type, marketing objective, campaign name) from pipe-delimited campaign strings.

[Create Custom Channel Grouping function](user-defined-functions/get_custom_channel_grouping.sql)

[Create Get Campaign Part function](user-defined-functions/get_campaign_part.sql)


### Create external tables
To populate the corresponding reports, the `campaigns` and `media_plan` table functions read advertising data from two tables that **are not created by any script in this repository**. You must create, populate, and keep them up to date yourself. Both must reside in the same dataset as the table functions.

All the other table functions work without them: create these two only if you need campaign cost analysis or media plan tracking.

| Table | How to populate it | How often |
| :--- | :--- | :--- |
| `online_campaign_performance_sheets` | Preferably a native table loaded automatically with the campaign data exported from your advertising platforms. As a simpler alternative, a Google Sheet connected as an external table. | Daily |
| `media_plan_sheets` | A Google Sheet connected as an external table, so the plan stays editable by the marketing team without any load job. | Whenever the media plan is ready or gets revised |

Reference [Google Sheet for online_campaign_performance_sheets](https://docs.google.com/spreadsheets/d/1aDfDJ3aDDH88ybJ4HH7y2m7cSRcKLhl6R9Z8ZbBmE0Y/#gid=418285084)

Reference [Google Sheet for media_plan_sheets](https://docs.google.com/spreadsheets/d/1aDfDJ3aDDH88ybJ4HH7y2m7cSRcKLhl6R9Z8ZbBmE0Y/#gid=1267353944)


#### online_campaign_performance_sheets
Daily media performance, one row per campaign per day.

| Column | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `date` | DATE | Yes | The day the spend occurred. Join key with `session_date`. |
| `campaign` | STRING | Yes | Campaign name. Must match **exactly** the `utm_campaign` value used on landing URLs, otherwise the row will not join with analytics data. |
| `campaign_id` | STRING | No | Campaign ID from the advertising platform. Must match `utm_id` when used. An empty value on both sides is a valid match. |
| `cost` | FLOAT | Yes | Spend for that campaign on that day, in your reporting currency. |
| `impression` | INTEGER | No | Impressions served. Missing values are returned as `0`. |
| `click` | INTEGER | No | Clicks received. Used to calculate `avg_cost_per_click` and `avg_click_through_rate`. |

All six columns are read by the table functions.


#### media_plan_sheets
Planned budget per campaign. Budgets are aggregated by month.

| Column | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `date` | DATE | Yes | Any day belonging to the month the budget refers to. Rows are grouped by month. In the source sheet the value must be written as `MM/DD/YYYY` so that BigQuery converts it to a `DATE`. |
| `year` | INTEGER | No | Campaign year. Not read by the table functions: the `year` dimension in the output is derived from `date`. |
| `country` | STRING | No | Target country (e.g. `IT`). |
| `funnel_stage` | STRING | No | Funnel stage (e.g. `Upper funnel`). |
| `platform` | STRING | No | Advertising platform (e.g. `Google Ads`). |
| `campaign_type` | STRING | No | Campaign type (e.g. `Search ads`). |
| `marketing_objective` | STRING | No | Marketing objective (e.g. `Brand awareness`). |
| `campaign_name` | STRING | No | Campaign name without the taxonomy prefix. |
| `full_campaign_name` | STRING | Yes | The complete campaign taxonomy, with the seven parts joined by a pipe (`\|`) — see [Campaign taxonomy](../README.md#campaign-taxonomy). Join key with the `campaign` column of `online_campaign_performance_sheets`. |
| `budget` | FLOAT | Yes | Planned budget for the campaign in that month. Summed over the selected period. |


#### Connecting a Google Sheet to BigQuery
1. In BigQuery, open the dataset and select **Create table**.
2. Set **Create table from** to `Drive`, paste the spreadsheet URL and choose `Google Sheet` as the file format.
3. Set **Sheet range** to the tab holding the data:
    - `Media plan pivot!A:J` for `media_plan_sheets`
    - `Online campaigns performances!A:F` for `online_campaign_performance_sheets`
4. Name the table, provide the schema above and set **Header rows to skip** to `1`.

The external table always reads the current content of the sheet, so edits are reflected in the reports at the next query with no reload.


#### Matching campaigns across the three sources
The same campaign string has to appear identically in three places, otherwise the joins produce unmatched rows:

| Where | Column or parameter | Read by |
| :--- | :--- | :--- |
| Landing page URL | `utm_campaign` | `sessions` → `session_campaign` |
| `online_campaign_performance_sheets` | `campaign` | `campaigns`, `media_plan` |
| `media_plan_sheets` | `full_campaign_name` | `media_plan` |

`campaigns` joins on **date + campaign + campaign ID**, `media_plan` joins on **month + campaign**. Unmatched rows are preserved on both sides, so naming discrepancies stay visible instead of silently disappearing.


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
The Reporting Fields Matrix provides an interactive overview of all reporting fields available across Nameless Analytics table functions, including functional scope, field type, value type, and field descriptions.

[Available metrics and dimensions](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_05l6ownl6d)



## Raw tables
Raw tables are the foundational storage layer of Nameless Analytics, designed to capture and preserve every user interaction in its raw, unprocessed form. These tables serve as the single source of truth for all analytics data, storing event-level information with complete historical fidelity.

The architecture consists of two core tables: the **Events raw table** (`events_raw`), which stores all user, session, page, event, ecommerce, consent, and GTM performance data in a denormalized structure optimized for both write performance and analytical queries; and the **Dates table** (`calendar_dates`), a utility dimension table that provides comprehensive date attributes for time-based analysis and reporting.

All data is partitioned by date and clustered by key dimensions to ensure optimal query performance and cost efficiency when analyzing large datasets.

The main table is partitioned by `event_date` and clustered by `user_date`, `session_date`, `page_date`, and `event_name`.

`event_date` is the partition key because it is the largest of the four dates — `user_date` ≤ `session_date` ≤ `page_date` ≤ `event_date`, since each one inherits the event date of the event that created that entity. That ordering is what makes `event_date >= start_date` a valid lower bound for every scope of the table functions, and it is also the only column that grows with ingestion, so new events always land in the newest partition.

`user_date` comes first among the clustering keys, and the order is not the one you would guess from how often each column is filtered. Block pruning works on the minimum and maximum value of a column within each block, and the sort only matters for columns that need it to end up with narrow ranges. Inside a given `event_date` partition, `session_date` and `page_date` are almost constant — a session or a page can only span midnight UTC, never more — so their blocks have narrow ranges whatever the order is, and they prune from any position. `user_date` is the opposite: within the same partition it spans the entire history of the property, because returning visitors keep generating events years after their first visit. It is the only one of the four that becomes prunable *because* of the sort, so it takes the only position where the sort is guaranteed. Moving `session_date` first would give it nothing it does not already have, and would take from `user_date` the one thing it needs.

The dates table is partitioned by `date` and clustered by `month_name` and `day_name`.


### Dates are UTC
`event_date` and `page_date` are computed by the client-side library from the event timestamp using UTC, and `user_date` and `session_date` inherit the `event_date` of the event that created the user or the session. Every date field in the platform is therefore a **UTC calendar date**, and so are the date ranges of the table functions, which filter on those fields.

The timestamps are unaffected: `event_timestamp`, `session_start_timestamp`, `page_load_timestamp` and the others are Unix epoch milliseconds, an absolute instant with no time zone attached.

What this means in practice, for a site whose audience is not on UTC: an event fired at 00:30 in Rome (UTC+1) carries the **previous** day as `event_date`. Daily totals are therefore shifted by the local offset, and the shift grows to two hours during daylight saving time. Sessions that start before midnight UTC and continue after it are stored with the `session_date` of the day they started, so they stay whole; only their later events fall in the next partition, and the table functions do not put an upper bound on `event_date`, so those events are still returned.

To report on local days, convert from the timestamp instead of using the date fields, and keep the partition filter on `event_date` so the query stays cheap:

```sql
select
  date(timestamp_millis(event_timestamp), 'Europe/Rome') as local_date,
  count(*) as events
from `project.nameless_analytics.events`(start_date, end_date, 'event')
group by all
order by local_date
```

Bear in mind that a query filtered on UTC dates and grouped by local dates returns two partially empty days at the edges of the range: widen the range by one day on each side and discard them.



## Table functions
Table functions are predefined SQL queries that simplify data analysis by transforming raw event data into structured, easy-to-use formats for common reporting needs.

Unlike other systems, Nameless Analytics reporting functions are designed to work directly on the `events_raw` table as the single source of truth. By leveraging BigQuery window functions, they reflect the most up-to-date state of the data without requiring complex ETL processes or intermediate staging tables.

Missing ecommerce numeric values are returned as zero. Refund amounts are represented as positive values, while net metrics are calculated as purchase minus refund.

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


### Events debug
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

Duplicate and missing transaction ID fields are diagnostic only. The function preserves every ingested event and does not automatically deduplicate transactions.

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


### Ecommerce funnel
Builds a cumulative presence-based ecommerce funnel within each session, from session start to purchase. A step is marked as reached when its event type and all preceding funnel event types are present in the session.

```sql
select * from `project.nameless_analytics.ec_funnel`(start_date, end_date)
```

[View SQL code](table-functions/ec_funnel.sql)


### Ecommerce funnel pivot
Returns the presence-based ecommerce funnel in long format with one row per session and funnel step, including step reach status and next-step client ID for drop-off analysis.

```sql
select * from `project.nameless_analytics.ec_funnel_pivot`(start_date, end_date)
```

[View SQL code](table-functions/ec_funnel_pivot.sql)


### Consents
Returns consent data in long format with one row per session and consent category, including consent expression state and Granted/Denied indicators.

Session consent metrics use the first consent Update recorded in the session, representing the user's initial expressed consent.

```sql
select * from `project.nameless_analytics.consents`(start_date, end_date)
```

[View SQL code](table-functions/consents.sql)


### Attribution comparison
Aggregates attributed conversion credit and revenue by traffic dimensions across single-touch and multi-touch attribution models.

```sql
select * from `project.nameless_analytics.attribution_comparison`(start_date, end_date, conversion_name, lookback_days)
```

[View SQL code](table-functions/attribution_comparison.sql)


### Attribution single touch
Calculates single-touch attribution per conversion using the user first click, the conversion-session last click, and the most recent non-direct session within the specified lookback window.

The last-click non-direct model ignores direct sessions when a non-direct touchpoint exists within the lookback window. If only direct sessions exist, credit is assigned to the conversion-session direct touchpoint.

```sql
select * from `project.nameless_analytics.attribution_single_touch`(start_date, end_date, conversion_name, lookback_days)
```

[View SQL code](table-functions/attribution_single_touch.sql)


### Attribution multi touch
Calculates multi-touch attribution at touchpoint level using linear, time-decay, and position-based models across sessions within the specified lookback window.

```sql
select * from `project.nameless_analytics.attribution_multi_touch`(start_date, end_date, conversion_name, lookback_days)
```

[View SQL code](table-functions/attribution_multi_touch.sql)


### Media plan
Combines monthly planned campaign budgets with actual campaign spend for the selected date range, preserving campaign taxonomy dimensions.

Requires the `media_plan_sheets` and `online_campaign_performance_sheets` tables. See [Create external campaign tables](#create-external-campaign-tables).

```sql
select * from `project.nameless_analytics.media_plan`(start_date, end_date)
```

[View SQL code](table-functions/media_plan.sql)


### Campaigns
Combines daily campaign media performance with post-click user, session, conversion, ecommerce, and ROAS metrics.

Unmatched advertising and analytics campaigns are preserved in the results. Missing numeric metrics are returned as zero, making campaign naming and ID discrepancies visible.

Requires the `online_campaign_performance_sheets` table. See [Create external campaign tables](#create-external-campaign-tables).

```sql
select * from `project.nameless_analytics.campaigns`(start_date, end_date)
```

[View SQL code](table-functions/campaigns.sql)



## Data governance & maintenance
Below are SQL templates to help you manage data integrity and comply with privacy regulations.

To comply with GDPR "Right to be Forgotten" requests, data must be removed from both the historical timeline (BigQuery) and the real-time snapshots (Firestore).


### Cookies are not deleted
Both methods below remove data, not identifiers. The `na_u` cookie stays in the visitor's browser for 400 days, and since it is `HttpOnly` it cannot be removed from JavaScript.

If the visitor comes back to the site, the first `page_view` recreates a user document carrying the same `client_id`, and the user history starts over from that event: `user_date` is the date of that `page_view`, `session_number` is back to `1`, and the first-touch attribution is recomputed from the source the visitor arrived with. Every event that is not a `page_view` is rejected with a `403` until that document exists again.

A complete Right to be Forgotten request therefore has two parts: running the deletion, and having the visitor clear the site data from their own browser.


### Delete user data script
You can use the provided [`Users deletion tool`](users-deletion-tool.py) Python script to handle both deletions in a single command.

This is the recommended method.

The script reads the user's `user_date` from the Firestore document before deleting anything, and uses it to narrow the BigQuery statement. Since the Server-side Client Tag writes to BigQuery only after a successful Firestore write, that value is always there and always matches the one stored in BigQuery. A user present in BigQuery with no Firestore document can only be the result of a manual deletion: the script then falls back to `client_id` alone, scanning the whole table, because completeness wins over cost.


### Manual user data deletion
If you prefer manual deletion, please remove data from both BigQuery and Firestore.

#### BigQuery user data deletion
Use the following DML statement to delete all records for a specific client_id. This will remove all user events.

```sql
# Delete all records for a specific client_id
DELETE FROM `project.nameless_analytics.events_raw`
WHERE true
  AND client_id = 'USER_CLIENT_ID'
  AND user_date = 'USER_DATE'    # Optional, see below
  AND event_date >= 'USER_DATE'; # Optional, see below
```

`client_id` alone is enough to delete every row of that user, but it is neither the partition key nor a clustering key, so the statement scans and rewrites the whole table. Adding `user_date` — the `user_date` field at the top level of the user's Firestore document, in `YYYY-MM-DD` format — restricts the work to that user's cohort: the value is first-touch and never overwritten, and `event_date` is always greater than or equal to it, so neither filter can leave a row behind. Omit both if you cannot retrieve the date: a slower deletion is better than an incomplete one.

#### Firestore user data deletion
Locate the document in the `users` collection where the Document ID matches the `client_id` and delete it. This will remove the user profile and all associated session summaries.


### Data health check
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

#

[Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_tables) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
