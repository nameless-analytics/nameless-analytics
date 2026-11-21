# Nameless Analytics | Reporting Tables

Nameless Analytics Reporting Tables store processed events in BigQuery and expose table functions for user, session, page, ecommerce, consent, campaign and attribution reporting.

For an overview of how Nameless Analytics works, [start with the main README](../README.md#overview).

### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change

## Table of Contents

- [Setup](#setup)
  - [Configure the SQL scripts](#configure-the-sql-scripts)
  - [Create raw tables](#create-raw-tables)
  - [Create custom functions](#create-custom-functions)
  - [Create table functions](#create-table-functions)
- [Raw tables](#raw-tables)
  - [Dates are UTC](#dates-are-utc)
- [Table functions](#table-functions)
  - [Events](#events)
  - [Users](#users)
  - [Sessions](#sessions)
  - [Pages](#pages)
  - [Transactions](#transactions)
  - [Products](#products)
  - [Ecommerce Funnel](#ecommerce-funnel)
  - [Consents](#consents)
  - [Attribution Single Touch](#attribution-single-touch)
  - [Attribution Multi Touch](#attribution-multi-touch)
  - [Attribution Comparison](#attribution-comparison)
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

Create the user-defined functions before the reporting table functions:

- [`get_channel_grouping`](user-defined-functions/get_channel_grouping.sql) installs `get_channel_grouping` and `get_channel_paid`, the standard [channel grouping logic](../README.md#channel-grouping-logic) the Server-side Client Tag applies — where the traffic came from, and whether it was paid — for rows that never went through it, such as advertising platform data you join yourself. Keep it in sync with the tag and leave customizations to `get_custom_channel_grouping`.
- [`get_custom_channel_grouping`](user-defined-functions/get_custom_channel_grouping.sql) is your own channel grouping, beside the standard one, on the same source, medium, campaign and click ID. It returns `NULL` until you write your rules into it; changes also affect historical reports.
- [`get_campaign_part`](user-defined-functions/get_campaign_part.sql) extracts the seven dimensions from the pipe-delimited [campaign taxonomy](../README.md#campaign-taxonomy).

### Create table functions

Create the functions in dependency order:

1. Base function: [`events`](table-functions/events.sql).
2. Core functions: [`sessions`](table-functions/sessions.sql), [`users`](table-functions/users.sql), [`pages`](table-functions/pages.sql), [`ec_transactions`](table-functions/ec_transactions.sql), [`ec_products`](table-functions/ec_products.sql), [`ec_funnel`](table-functions/ec_funnel.sql), [`attribution_single_touch`](table-functions/attribution_single_touch.sql) and [`attribution_multi_touch`](table-functions/attribution_multi_touch.sql).
3. Derived functions: [`consents`](table-functions/consents.sql) and [`attribution_comparison`](table-functions/attribution_comparison.sql).

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

### Users

Aggregates users acquired in the selected range, including acquisition, recency, session and ecommerce metrics.

```sql
select * from `project.nameless_analytics.users`(start_date, end_date)
```

[View SQL code](table-functions/users.sql)

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

### Consents

Returns one row per session and consent category. Session values use the first consent `Update` when present; otherwise the initial session values are retained and the consent state is reported as not expressed.

```sql
select * from `project.nameless_analytics.consents`(start_date, end_date)
```

[View SQL code](table-functions/consents.sql)

### Attribution single touch

Calculates user first click, conversion-session last click and last non-direct click within the configured lookback window. The date range follows `session_date`, matching `sessions`; `lookback_days` only expands the search for earlier sessions. The last non-direct model falls back to the direct conversion session when no non-direct touchpoint exists.

```sql
select * from `project.nameless_analytics.attribution_single_touch`(start_date, end_date, conversion_event, lookback_days)
```

[View SQL code](table-functions/attribution_single_touch.sql)

### Attribution multi touch

Distributes conversion credit across touchpoints using linear, time-decay and position-based models within the configured lookback window. The date range follows `session_date`, matching `sessions`; `lookback_days` only expands the search for earlier sessions.

```sql
select * from `project.nameless_analytics.attribution_multi_touch`(start_date, end_date, conversion_event, lookback_days)
```

[View SQL code](table-functions/attribution_multi_touch.sql)

### Attribution comparison

Aggregates conversion credit and revenue by traffic dimensions across the single-touch and multi-touch models.

```sql
select * from `project.nameless_analytics.attribution_comparison`(start_date, end_date, conversion_event, lookback_days)
```

[View SQL code](table-functions/attribution_comparison.sql)

## Reporting fields

See [Reporting fields](https://namelessanalytics.com/reporting-fields) for every dimension and metric exposed by the table functions: what each field means and which table functions return it.

## Data governance & maintenance

Deleting a Nameless Analytics user requires removing the identifier from both Firestore and BigQuery. The exact legal process, retention period and verification requirements depend on the implementation.

### Cookies are not deleted

The deletion methods below remove server-side data but do not expire the `na_u` cookie in the visitor's browser. Because the cookie is `HttpOnly`, client-side JavaScript cannot remove it; the visitor can clear site data, or the implementation can expire it through a server response.

If the cookie remains, a later `page_view` can recreate the same `client_id` with a new user history. Events sent before that initialization are rejected as orphan events; see [Event sequence](../setup-guides/TROUBLESHOOTING-GUIDE.md#event-sequence).

### Delete user data script

The provided [`Users deletion tool`](users-deletion-tool.py) is a reference utility for deleting a `client_id` from BigQuery and Firestore.

Before running it:

1. configure `client_id`, project, dataset and service-account path;
2. install the `google-cloud-firestore` and `google-cloud-bigquery` Python packages;
3. verify that the credentials can execute BigQuery DML (BigQuery Job User and Data Editor) and read and delete Firestore documents (Cloud Datastore User).

The script deletes every row of the `client_id` from `events_raw`, and from `events` when the dataset has one, then deletes the Firestore document. It filters on `client_id` alone, so no row is left behind under another `user_date` or a wrong device clock; BigQuery scans only the `client_id` column to find them and rewrites only the partitions that held them.

BigQuery first, Firestore last: if a step fails, the run can be repeated. Rows streamed in the last minutes are still in BigQuery's streaming buffer, where DML cannot change them; the script then stops before deleting anything else and asks to run it again in about 90 minutes.

The operations are sequential, not atomic: confirm the result in both stores.

### Manual user data deletion

If deleting manually, remove the user from both stores.

#### BigQuery user data deletion

Delete by `client_id` alone, so no row is left behind:

```sql
delete from `project.nameless_analytics.events_raw`
where client_id = 'USER_CLIENT_ID';
```

Do the same in the `events` table, when the dataset has one. Rows still in the streaming buffer cannot be deleted: run it again later, then confirm that no rows remain.

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
