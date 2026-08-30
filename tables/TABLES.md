# Nameless Analytics | Reporting Tables

Nameless Analytics Reporting Tables store processed events in BigQuery and expose table functions for user, session, page, ecommerce, consent, campaign and attribution reporting.

For an overview of how Nameless Analytics works, [start with the main README](../README.md#overview).

### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change

## Table of Contents

- [Setup](#setup)
  - [Configure the SQL scripts](#configure-the-sql-scripts)
  - [Create raw tables](#create-raw-tables)
  - [Create custom functions](#create-custom-functions)
  - [Configure optional campaign source tables](#configure-optional-campaign-source-tables)
  - [Create table functions](#create-table-functions)
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
  - [Attribution Single Touch](#attribution-single-touch)
  - [Attribution Multi Touch](#attribution-multi-touch)
  - [Attribution Comparison](#attribution-comparison)
  - [Media Plan](#media-plan)
  - [Campaigns](#campaigns)
- [Reporting fields](#reporting-fields)
- [Data governance & maintenance](#data-governance--maintenance)
  - [Cookies are not deleted](#cookies-are-not-deleted)
  - [Delete user data script](#delete-user-data-script)
  - [Manual user data deletion](#manual-user-data-deletion)
  - [Event volume check](#event-volume-check)

## Setup

Run the SQL scripts in BigQuery in the order described below.

### Configure the SQL scripts

Before running a script, update the variables declared at the top:

- set `project_name` in every SQL file;
- keep or change the default `dataset_name` (`nameless_analytics`) consistently across all files;
- set `dataset_location` in [`tables.sql`](tables/tables.sql).

The raw tables, custom functions, table functions and optional campaign source tables must use the same project and dataset.

### Create raw tables

Run [`tables.sql`](tables/tables.sql) to create the dataset, `events_raw` and `calendar_dates`.

### Create custom functions

Create both user-defined functions before the reporting table functions:

- [`get_custom_channel_grouping`](user-defined-functions/get_custom_channel_grouping.sql) applies the [channel grouping logic](../README.md#channel-grouping-logic) at query time. Customizations also affect historical reports.
- [`get_campaign_part`](user-defined-functions/get_campaign_part.sql) extracts the seven dimensions from the pipe-delimited [campaign taxonomy](../README.md#campaign-taxonomy).

### Configure optional campaign source tables

The `campaigns` and `media_plan` functions require the following source tables. They are not created by this repository and must reside in the same dataset as the table functions.

| Table | Suggested source | Used by |
|:---|:---|:---|
| `online_campaign_performance_sheets` | A native BigQuery table loaded from advertising platforms, or a connected Google Sheet | `campaigns`, `media_plan` |
| `media_plan_sheets` | A connected Google Sheet or another maintained BigQuery table | `media_plan` |

All other table functions work without these sources.

Reference sheets: [online campaign performance](https://docs.google.com/spreadsheets/d/1aDfDJ3aDDH88ybJ4HH7y2m7cSRcKLhl6R9Z8ZbBmE0Y/#gid=418285084) and [media plan](https://docs.google.com/spreadsheets/d/1aDfDJ3aDDH88ybJ4HH7y2m7cSRcKLhl6R9Z8ZbBmE0Y/#gid=1267353944).

#### online_campaign_performance_sheets

The table contains daily media performance, with one row per campaign and date. All six columns must exist; columns whose value is not required may contain `NULL`.

| Column | Type | Value required | Description |
|:---|:---|:---:|:---|
| `date` | DATE | Yes | Date on which the spend occurred. |
| `campaign` | STRING | Yes | Campaign name. The `campaigns` function compares it with `session_campaign` without distinguishing letter case. |
| `campaign_id` | STRING | No | Advertising campaign ID. It must match `utm_id` when used; `NULL` and an empty value are treated as equivalent. |
| `cost` | FLOAT64 | Yes | Spend in the reporting currency. |
| `impression` | INT64 | No | Impressions. Missing values are reported as zero. |
| `click` | INT64 | No | Clicks used to calculate CPC and click-through rate. |

#### media_plan_sheets

The table contains planned campaign budgets. In the reference sheet, use this schema for the `A:J` range. `media_plan` reads only the three columns marked **Yes**; the others are editable helpers and do not affect the output.

| Column | Type | Read by `media_plan` | Description |
|:---|:---|:---:|:---|
| `date` | DATE | Yes | Any date in the budget month. It must be recognized by BigQuery as a `DATE`. |
| `year` | INT64 | No | Optional helper field. |
| `country` | STRING | No | Optional helper field. |
| `funnel_stage` | STRING | No | Optional helper field. |
| `platform` | STRING | No | Optional helper field. |
| `campaign_type` | STRING | No | Optional helper field. |
| `marketing_objective` | STRING | No | Optional helper field. |
| `campaign_name` | STRING | No | Optional helper field. |
| `full_campaign_name` | STRING | Yes | Complete seven-part [campaign taxonomy](../README.md#campaign-taxonomy). It is matched exactly, including letter case, with the performance table's `campaign`. |
| `budget` | FLOAT64 | Yes | Planned budget. Rows are aggregated by month and campaign. |

Output taxonomy dimensions are extracted from `full_campaign_name`; output year and month are derived from `date`.

#### Connecting a Google Sheet to BigQuery

To use a Google Sheet as an external table:

1. In the dataset, select **Create table** and choose `Drive` as the source.
2. Paste the spreadsheet URL and choose `Google Sheet` as the file format.
3. Enter the relevant range:
   - `Online campaigns performances!A:F` for `online_campaign_performance_sheets`;
   - `Media plan pivot!A:J` for `media_plan_sheets`.
4. Use the exact table name and schema documented above, then set **Header rows to skip** to `1`.

Queries against an external table read the current sheet content without a separate reload.

#### Matching campaigns across sources

The `utm_campaign` query parameter becomes `session_campaign` and should use the same taxonomy as the campaign source tables.

- `campaigns` joins analytics and advertising data by date, case-insensitive campaign name and campaign ID. Its full join preserves unmatched rows from both sides.
- `media_plan` joins planned budget to advertising spend by month and exact campaign name. It preserves all media-plan rows; spend-only campaigns are not returned.

### Create table functions

Create the functions in dependency order:

1. Base functions: [`events`](table-functions/events.sql) and [`events_debug`](table-functions/events_debug.sql).
2. Core functions: [`sessions`](table-functions/sessions.sql), [`users`](table-functions/users.sql), [`pages`](table-functions/pages.sql), [`ec_transactions`](table-functions/ec_transactions.sql), [`ec_products`](table-functions/ec_products.sql), [`ec_funnel`](table-functions/ec_funnel.sql), [`attribution_single_touch`](table-functions/attribution_single_touch.sql) and [`attribution_multi_touch`](table-functions/attribution_multi_touch.sql).
3. Derived functions: [`consents`](table-functions/consents.sql), [`users_rfm`](table-functions/users_rfm.sql), [`ec_funnel_pivot`](table-functions/ec_funnel_pivot.sql) and [`attribution_comparison`](table-functions/attribution_comparison.sql).
4. Optional campaign functions: [`campaigns`](table-functions/campaigns.sql) and [`media_plan`](table-functions/media_plan.sql), after configuring their source tables.

## Raw tables

`events_raw` stores every event successfully written to BigQuery, including its user, session, page, event, ecommerce, consent and GTM data. `calendar_dates` provides reusable calendar dimensions.

| Table | Partition | Clustering |
|:---|:---|:---|
| `events_raw` | `event_date` | `user_date`, `session_date`, `page_date`, `event_name` |
| `calendar_dates` | `date` | `month_name`, `day_name` |

When querying `events_raw` directly, filter on `event_date` whenever possible to limit the partitions scanned. The reporting functions already apply a suitable partition boundary.

### Dates are UTC

Nameless Analytics treats `user_date`, `session_date`, `page_date` and `event_date` as UTC calendar dates. Website events derive them from their timestamps; Streaming Protocol senders should follow the same convention.

Timestamp fields such as `event_timestamp`, `session_start_timestamp` and `page_load_timestamp` are Unix epoch milliseconds and represent an absolute instant.

For local-day reporting, derive the date from the timestamp while retaining the UTC date range used by the table function:

```sql
select
  date(timestamp_millis(event_timestamp), 'Europe/Rome') as local_date,
  count(*) as events
from `project.nameless_analytics.events`(start_date, end_date, 'event')
group by all
order by local_date
```

If the reporting timezone differs from UTC, widen the input range by one day at each boundary and then filter the resulting `local_date` values.

## Table functions

Table functions transform `events_raw` into reporting-ready views at query time, without an intermediate reporting table.

Missing ecommerce numeric values are generally returned as zero. Refund values are expected to be positive; net metrics are calculated as purchase minus refund. Streaming Protocol events are excluded from `session_duration_sec` and `time_on_page`.

### Events

Returns enriched event-level data for the selected date range and scope.

```sql
select * from `project.nameless_analytics.events`(start_date, end_date, date_scope)
```

| `date_scope` | Returned events |
|:---|:---|
| `user` | Events belonging to users whose `user_date` is in the range |
| `session` | Events belonging to sessions whose `session_date` is in the range |
| `page` | Events belonging to pages whose `page_date` is in the range |
| `event` | Events whose `event_date` is in the range |

The scope determines both the selected population and the rows available to window calculations. Choose it according to the entity being analyzed.

[View SQL code](table-functions/events.sql)

### Events debug

Returns the raw and typed parameter structures used to validate stored user, session, page, event, ecommerce, dataLayer and consent data.

```sql
select * from `project.nameless_analytics.events_debug`(start_date, end_date)
```

[View SQL code](table-functions/events_debug.sql)

### Users

Aggregates users acquired in the selected range, including acquisition, recency, session and ecommerce metrics.

```sql
select * from `project.nameless_analytics.users`(start_date, end_date)
```

[View SQL code](table-functions/users.sql)

### Users RFM

Scores customers with at least one purchase using Recency, Frequency and Monetary metrics. Churn window and RFM weights are configurable.

```sql
select * from `project.nameless_analytics.users_rfm`(start_date, end_date, churn_window_days, r_weight, f_weight, m_weight)
```

[View SQL code](table-functions/users_rfm.sql)

### Sessions

Aggregates sessions started in the selected range, including acquisition, engagement, events, ecommerce and consent values.

```sql
select * from `project.nameless_analytics.sessions`(start_date, end_date)
```

[View SQL code](table-functions/sessions.sql)

### Pages

Aggregates page views from sessions started in the selected range, including page context, timing and HTTP status.

```sql
select * from `project.nameless_analytics.pages`(start_date, end_date)
```

[View SQL code](table-functions/pages.sql)

### Transactions

Returns purchase and refund events with transaction identifiers and monetary values. Missing and duplicate transaction ID fields are diagnostic: events are not automatically deduplicated.

```sql
select * from `project.nameless_analytics.ec_transactions`(start_date, end_date)
```

[View SQL code](table-functions/ec_transactions.sql)

### Products

Aggregates ecommerce interactions at item level, including product, list, promotion, cart, wishlist, purchase and refund data.

```sql
select * from `project.nameless_analytics.ec_products`(start_date, end_date)
```

[View SQL code](table-functions/ec_products.sql)

### Ecommerce funnel

Builds a cumulative, presence-based funnel within each session. A step is reached when its event type and all preceding funnel event types are present; chronological order is not evaluated.

```sql
select * from `project.nameless_analytics.ec_funnel`(start_date, end_date)
```

[View SQL code](table-functions/ec_funnel.sql)

### Ecommerce funnel pivot

Returns the same funnel in long format, with one row per session and step for progression and drop-off analysis.

```sql
select * from `project.nameless_analytics.ec_funnel_pivot`(start_date, end_date)
```

[View SQL code](table-functions/ec_funnel_pivot.sql)

### Consents

Returns one row per session and consent category. Session values use the first consent `Update` when present; otherwise the initial session values are retained and the consent state is reported as not expressed.

```sql
select * from `project.nameless_analytics.consents`(start_date, end_date)
```

[View SQL code](table-functions/consents.sql)

### Attribution single touch

Calculates user first click, conversion-session last click and last non-direct click within the configured lookback window. The last non-direct model falls back to the direct conversion session when no non-direct touchpoint exists.

```sql
select * from `project.nameless_analytics.attribution_single_touch`(start_date, end_date, conversion_name, lookback_days)
```

[View SQL code](table-functions/attribution_single_touch.sql)

### Attribution multi touch

Distributes conversion credit across touchpoints using linear, time-decay and position-based models within the configured lookback window.

```sql
select * from `project.nameless_analytics.attribution_multi_touch`(start_date, end_date, conversion_name, lookback_days)
```

[View SQL code](table-functions/attribution_multi_touch.sql)

### Attribution comparison

Aggregates conversion credit and revenue by traffic dimensions across the single-touch and multi-touch models.

```sql
select * from `project.nameless_analytics.attribution_comparison`(start_date, end_date, conversion_name, lookback_days)
```

[View SQL code](table-functions/attribution_comparison.sql)

### Media plan

Combines monthly planned budgets with matching campaign spend. All media-plan rows are retained; spend without a corresponding plan row is not returned.

Requires `media_plan_sheets` and `online_campaign_performance_sheets`.

```sql
select * from `project.nameless_analytics.media_plan`(start_date, end_date)
```

[View SQL code](table-functions/media_plan.sql)

### Campaigns

Combines daily advertising performance with post-click user, session, conversion, ecommerce and ROAS metrics. Its full join preserves unmatched advertising and analytics campaigns.

Requires `online_campaign_performance_sheets`.

```sql
select * from `project.nameless_analytics.campaigns`(start_date, end_date)
```

[View SQL code](table-functions/campaigns.sql)

## Reporting fields

Use the [Reporting Fields Matrix](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_05l6ownl6d) to browse the dimensions and metrics exposed by each table function.

## Data governance & maintenance

Deleting a Nameless Analytics user requires removing the identifier from both Firestore and BigQuery. The exact legal process, retention period and verification requirements depend on the implementation.

### Cookies are not deleted

The deletion methods below remove server-side data but do not expire the `na_u` cookie in the visitor's browser. Because the cookie is `HttpOnly`, client-side JavaScript cannot remove it; the visitor can clear site data, or the implementation can expire it through a server response.

If the cookie remains, a later `page_view` can recreate the same `client_id` with a new user history. Events sent before that initialization are rejected as orphan events; see [Event sequence](../setup-guides/TROUBLESHOOTING-GUIDE.md#event-sequence).

### Delete user data script

The provided [`Users deletion tool`](users-deletion-tool.py) is a reference utility for deleting a `client_id` from Firestore and BigQuery.

Before running it:

1. configure `client_id`, project, dataset, table and service-account path;
2. install the `google-cloud-firestore` and `google-cloud-bigquery` Python packages;
3. verify that the credentials can read and delete the Firestore document and execute BigQuery DML.

The script reads `user_date` from Firestore when available, deletes the Firestore document and then deletes the BigQuery rows. It uses the date to reduce the partitions scanned; without it, the BigQuery deletion falls back to `client_id` alone.

The operations are sequential, not atomic. A later step may fail after an earlier deletion succeeds, so confirm the result independently in both stores.

### Manual user data deletion

If deleting manually, remove the user from both stores.

#### BigQuery user data deletion

`client_id` alone is the completeness fallback:

```sql
delete from `project.nameless_analytics.events_raw`
where client_id = 'USER_CLIENT_ID';
```

When a trusted `user_date` is available, add it and the corresponding partition boundary to reduce the data scanned:

```sql
delete from `project.nameless_analytics.events_raw`
where client_id = 'USER_CLIENT_ID'
  and user_date = date '2026-01-01'
  and event_date >= date '2026-01-01';
```

Use the `client_id`-only version if the date cannot be verified, then confirm that no rows remain.

#### Firestore user data deletion

In the `users` collection, delete the document whose ID matches `client_id`. This removes the user snapshot and its session summaries.

### Event volume check

This query checks daily collection volume for the current day and the previous six days. A drop can indicate a tracking or ingestion problem, but this is not a complete pipeline health check.

```sql
select
  event_date,
  count(distinct client_id) as users,
  count(distinct session_id) as sessions,
  count(distinct page_id) as page_views,
  count(distinct event_id) as events
from `project.nameless_analytics.events_raw`
where event_date >= date_sub(current_date(), interval 6 day)
group by event_date
order by event_date desc;
```

#

[Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_tables) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
