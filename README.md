# Nameless Analytics

## Build your own data warehouse analytics platform

A first-party digital analytics platform built with [Google Tag Manager](https://marketingplatform.google.com/about/tag-manager/), [Google Firestore](https://cloud.google.com/firestore) and [Google BigQuery](https://cloud.google.com/bigquery).


### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change



## Start from here

- [What is Nameless Analytics](#what-is-nameless-analytics)
- [Overview](#overview)
- [Quick start](#quick-start)
  - [Documentation](#documentation)
- [Client-side collection](#client-side-collection)
  - [Request payload data](#request-payload-data)
  - [Campaign taxonomy](#campaign-taxonomy)
  - [Client-side ID management](#client-side-id-management)
  - [Smart consent management](#smart-consent-management)
  - [SPA & history management](#spa--history-management)
  - [Cross-domain architecture](#cross-domain-architecture)
  - [Parameter hierarchy](#parameter-hierarchy)
- [Server-side processing](#server-side-processing)
  - [Security & validation](#security--validation)
  - [Server-side ID management](#server-side-id-management)
  - [User ID lifecycle](#user-id-lifecycle)
  - [Bot protection](#bot-protection)
  - [Channel grouping logic](#channel-grouping-logic)
  - [Server-side cookies](#server-side-cookies)
  - [Streaming Protocol](#streaming-protocol)
- [Storage](#storage)
  - [Firestore as last updated snapshot](#firestore-as-last-updated-snapshot)
  - [BigQuery as historical timeline](#bigquery-as-historical-timeline)
- [Reporting](#reporting)
- [AI support](#ai-support)
- [Google Cloud costs](#google-cloud-costs)
- [License](#license)



## What is Nameless Analytics
Nameless Analytics is a first-party analytics pipeline built with Google Tag Manager, Firestore and BigQuery. It collects website events through infrastructure you control and keeps the raw history available for your own reporting and activation.

Its main characteristics are:

- ownership of the raw data, retention and reporting model;
- server-side validation and enrichment before storage;
- unsampled event-level data in BigQuery;
- optional real-time forwarding to external systems;
- no persistence of the visitor's raw IP address in the analytics tables.



## Overview
The browser tracker builds the event, the Server-side Client Tag validates and enriches it, Firestore maintains the current user/session state and BigQuery stores the historical event timeline.

![Nameless Analytics schema](https://namelessanalytics.com/img/Nameless%20Analytics%20schema.png)



## Quick start
You need a web GTM container, a server GTM container, a Google Cloud project, a BigQuery dataset and Firestore in Native Mode.

1. Create the raw tables and reporting functions with the provided [SQL resources](tables/TABLES.md).
2. Import the three templates: [Client-side Tracker Tag](https://github.com/nameless-analytics/client-side-tracker-tag), [Client-side Tracker Configuration Variable](https://github.com/nameless-analytics/client-side-tracker-configuration-variable) and [Server-side Client Tag](https://github.com/nameless-analytics/server-side-client-tag).
3. Configure matching client/server endpoint paths and send `page_view` as the first event.
4. Verify Firestore and BigQuery processing in GTM Preview.

Follow the [Setup Guides](setup-guides/SETUP-GUIDES.md) for the complete procedure.


### Documentation
- [Setup guides](setup-guides/SETUP-GUIDES.md)
- [Troubleshooting](setup-guides/TROUBLESHOOTING-GUIDE.md)
- [Tables](tables/TABLES.md)
- [Streaming Protocol](streaming-protocol/STREAMING-PROTOCOL.md)
- [Live Demo](https://namelessanalytics.com) (Open the dev console).
- [Changelog](CHANGELOG.md)
- [Roadmap](ROADMAP.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [License](LICENSE)



## Client-side collection
The Client-side Tracker Tag builds the browser event, applies consent and page context, and sends requests sequentially to the configured server endpoint.


### Request payload data
The request data is sent via a POST request in JSON format. It is structured into several logical objects: `user_data`, `session_data`, `page_data`, `event_data`, `consent_data`, and `gtm_data`.

<details><summary>Example of the final enriched payload as processed and returned by the server (standard parameters only)</summary>

<br>

```json
{
  "user_date": "2026-01-20",
  "client_id": "lZc919IBsqlhHks",
  "user_data": {
    "user_channel_grouping": "gtm_debugger",
    "user_source": "tagassistant.google.com",
    "user_tld_source": "google.com",
    "user_campaign": null,
    "user_campaign_id": null,
    "user_campaign_click_id": null,
    "user_campaign_term": null,
    "user_campaign_content": null,
    "user_device_type": "desktop",
    "user_country": "IT",
    "user_city": "venice",
    "user_language": "it-IT",
    "user_first_session_timestamp": 1764955391487,
    "user_last_session_timestamp": 1768661707758
  },
  "session_date": "2026-01-20",
  "session_id": "lZc919IBsqlhHks_1KMIqneQ7dsDJUa",
  "session_data": {
    "session_number": 2,
    "cross_domain_session": "No",
    "session_channel_grouping": "gtm_debugger",
    "session_source": "tagassistant.google.com",
    "session_tld_source": "google.com",
    "session_campaign": null,
    "session_campaign_id": null,
    "session_campaign_click_id": null,
    "session_campaign_term": null,
    "session_campaign_content": null,
    "session_device_type": "desktop",
    "session_country": "IT",
    "session_city": "venice",
    "session_language": "it-IT",
    "session_hostname": "tommasomoretti.com",
    "session_browser_name": "Chrome",
    "session_landing_page_category": "Homepage",
    "session_landing_page_url": "https://tommasomoretti.com/",
    "session_landing_page_path": "/",
    "session_landing_page_title": "Tommaso Moretti | Freelance digital data analyst",
    "session_exit_page_category": "Homepage",
    "session_exit_page_url": "https://tommasomoretti.com/",
    "session_exit_page_path": "/",
    "session_exit_page_title": "Tommaso Moretti | Freelance digital data analyst",
    "session_start_timestamp": 1768661707758,
    "session_end_timestamp": 1768661707758
  },
  "page_date": "2026-01-20",
  "page_id": "lZc919IBsqlhHks_1KMIqneQ7dsDJUa-WVTWEorF69ZEk3y",
  "page_data": {
    "page_title": "Tommaso Moretti | Freelance digital data analyst",
    "page_hostname_protocol": "https",
    "page_hostname": "tommasomoretti.com",
    "page_url": "https://tommasomoretti.com/",
    "page_path": "/",
    "page_fragment": null,
    "page_query": "gtm_debug=1765021707758",
    "page_extension": null,
    "page_referrer": "https://tagassistant.google.com/",
    "page_load_timestamp": 1768661707758,
    "page_category": "Homepage",
    "page_language": "it"
  },
  "event_date": "2026-01-20",
  "event_timestamp": 1768661707758,
  "event_id": "lZc919IBsqlhHks_1KMIqneQ7dsDJUa-WVTWEorF69ZEk3y_XIkjlUOkXKn99IV",
  "event_name": "page_view",
  "event_origin": "Website",
  "event_data": {
    "event_type": "page_view",
    "channel_grouping": "gtm_debugger",
    "source": "tagassistant.google.com",
    "campaign": null,
    "campaign_id": null,
    "campaign_click_id": null,
    "campaign_term": null,
    "campaign_content": null,
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)Chrome/142.0.0.0 Safari/537.36",
    "browser_name": "Chrome",
    "browser_language": "it-IT",
    "browser_version": "142.0.0.0",
    "device_type": "desktop",
    "device_vendor": "Apple",
    "device_model": "Macintosh",
    "os_name": "Mac OS",
    "os_version": "10.15.7",
    "screen_size": "1512x982",
    "viewport_size": "1512x823",
    "country": "IT",
    "city": "venice",
    "tld_source": "google.com",
    "cross_domain_id": null
  },
  "consent_data": {
    "consent_type": "Update",
    "respect_consent_mode": "Yes",
    "ad_user_data": "Denied",
    "ad_personalization": "Denied",
    "ad_storage": "Denied",
    "analytics_storage": "Granted",
    "functionality_storage": "Denied",
    "personalization_storage": "Granted",
    "security_storage": "Denied"
  },
  "gtm_data": {
    "cs_hostname": "tommasomoretti.com",
    "cs_container_id": "GTM-PW7349P",
    "cs_tag_name": null,
    "cs_tag_id": 277,
    "ss_hostname": "gtm.tommasomoretti.com",
    "ss_container_id": "GTM-KQG9ZNG",
    "ss_tag_name": "NA",
    "ss_tag_id": null,
    "processing_event_timestamp": 1765023618275,
    "content_length": 1605
  }
}
```

| **Parameter name** | **Sub-parameter**             | **Type** | **Added**   | **Field description**                         |
|--------------------|-------------------------------|----------|-------------|-----------------------------------------------|
| user_date          |                               | String   | Server-side | User data collection date                     |
| client_id          |                               | String   | Server-side | Unique client identifier                      |
| user_data          | user_channel_grouping         | String   | Server-side | User channel grouping                         |
|                    | user_source                   | String   | Server-side | User source                                   |
|                    | user_tld_source               | String   | Server-side | User top-level domain source                  |
|                    | user_campaign                 | String   | Server-side | User campaign name                            |
|                    | user_campaign_id              | String   | Server-side | User campaign ID                              |
|                    | user_campaign_click_id        | String   | Server-side | User campaign click identifier                |
|                    | user_campaign_term            | String   | Server-side | User campaign term                            |
|                    | user_campaign_content         | String   | Server-side | User campaign content                         |
|                    | user_device_type              | String   | Server-side | User device type                              |
|                    | user_country                  | String   | Server-side | User country                                  |
|                    | user_city                     | String   | Server-side | User city                                     |
|                    | user_language                 | String   | Server-side | User language                                 |
|                    | user_first_session_timestamp  | Integer  | Server-side | Timestamp of user's first session             |
|                    | user_last_session_timestamp   | Integer  | Server-side | Timestamp of user's last session              |
| session_date       |                               | String   | Server-side | Session date                                  |
| session_id         |                               | String   | Server-side | Unique session identifier                     |
| session_data       | session_number                | Integer  | Server-side | Session number for the user                   |
|                    | cross_domain_session          | String   | Server-side | `Yes` if any hit in the session carried a valid cross-domain ID, `No` otherwise |
|                    | session_channel_grouping      | String   | Server-side | Channel grouping for the session              |
|                    | session_source                | String   | Server-side | Session source                                |
|                    | session_tld_source            | String   | Server-side | Session top-level domain source               |
|                    | session_campaign              | String   | Server-side | Session campaign name                         |
|                    | session_campaign_id           | String   | Server-side | Session campaign ID                           |
|                    | session_campaign_click_id     | String   | Server-side | Session campaign click ID                     |
|                    | session_campaign_term         | String   | Server-side | Session campaign term                         |
|                    | session_campaign_content      | String   | Server-side | Session campaign content                      |
|                    | session_device_type           | String   | Server-side | Device type used in session                   |
|                    | session_country               | String   | Server-side | Session country                               |
|                    | session_city                  | String   | Server-side | Session geolocation city                      |
|                    | session_language              | String   | Server-side | Session language                              |
|                    | session_hostname              | String   | Server-side | Website hostname for session                  |
|                    | session_browser_name          | String   | Server-side | Browser name used in session                  |
|                    | session_landing_page_category | String   | Server-side | Landing page category                         |
|                    | session_landing_page_url      | String   | Server-side | Landing page URL                              |
|                    | session_landing_page_path     | String   | Server-side | Landing page path                             |
|                    | session_landing_page_title    | String   | Server-side | Landing page title                            |
|                    | session_exit_page_category    | String   | Server-side | Exit page category                            |
|                    | session_exit_page_url         | String   | Server-side | Exit page URL                                 |
|                    | session_exit_page_path        | String   | Server-side | Exit page path                                |
|                    | session_exit_page_title       | String   | Server-side | Exit page title                               |
|                    | session_start_timestamp       | Integer  | Server-side | Session start timestamp                       |
|                    | session_end_timestamp         | Integer  | Server-side | Session end timestamp                         |
|                    | user_id                       | String   | Client-side | Unique user identifier (if logged in)         |
| page_date          |                               | String   | Client-side | Page data date                                |
| page_id            |                               | String   | Client-side | Unique page identifier                        |
| page_data          | page_title                    | String   | Client-side | Page title                                    |
|                    | page_hostname_protocol        | String   | Client-side | Page hostname protocol (http/https)           |
|                    | page_hostname                 | String   | Client-side | Page hostname                                 |
|                    | page_url                      | String   | Client-side | Page full URL                                 |
|                    | page_path                     | String   | Client-side | Page path                                     |
|                    | page_fragment                 | String   | Client-side | URL fragment                                  |
|                    | page_query                    | String   | Client-side | URL query string                              |
|                    | page_extension                | String   | Client-side | Page file extension                           |
|                    | page_referrer                 | String   | Client-side | Referrer URL                                  |
|                    | page_load_timestamp           | Integer  | Client-side | Page load timestamp                           |
|                    | page_category                 | String   | Client-side | Page category                                 |
|                    | page_language                 | String   | Client-side | Page language                                 |
| event_date         |                               | String   | Client-side | Event date                                    |
| event_timestamp    |                               | Integer  | Client-side | Event timestamp                               |
| event_id           |                               | String   | Client-side | Unique event identifier                       |
| event_name         |                               | String   | Client-side | Event name                                    |
| event_origin       |                               | String   | Client-side | Event origin (Website or Streaming Protocol)  |
| event_data         | event_type                    | String   | Client-side | Event classification (automatically set to `page_view` or `event`) |
|                    | channel_grouping              | String   | Server-side | Channel grouping for the event (see [detailed logic](#channel-grouping-logic)) |
|                    | source                        | String   | Client-side | Event traffic source                          |
|                    | campaign                      | String   | Client-side | Event campaign                                |
|                    | campaign_id                   | String   | Client-side | Event campaign ID                             |
|                    | campaign_click_id             | String   | Client-side | Event campaign click ID                       |
|                    | campaign_term                 | String   | Client-side | Event campaign term                           |
|                    | campaign_content              | String   | Client-side | Event campaign content                        |
|                    | user_agent                    | String   | Client-side | Browser user agent string                     |
|                    | browser_name                  | String   | Client-side | Browser name                                  |
|                    | browser_language              | String   | Client-side | Browser language                              |
|                    | browser_version               | String   | Client-side | Browser version                               |
|                    | device_type                   | String   | Client-side | Device type                                   |
|                    | device_vendor                 | String   | Client-side | Device manufacturer                           |
|                    | device_model                  | String   | Client-side | Device model                                  |
|                    | os_name                       | String   | Client-side | Operating system name                         |
|                    | os_version                    | String   | Client-side | Operating system version                      |
|                    | screen_size                   | String   | Client-side | Screen resolution                             |
|                    | viewport_size                 | String   | Client-side | Browser viewport size                         |
|                    | country                       | String   | Server-side | Event geolocation country                     |
|                    | city                          | String   | Server-side | Event geolocation city                        |
|                    | tld_source                    | String   | Client-side | Event top-level domain source                 |
|                    | cross_domain_id               | String   | Client-side | Session ID decoded and validated from the `na_id` URL parameter. Set only on the first `page_view` of the destination page, `null` on every other event |
| consent_data       | consent_type                  | String   | Client-side | Consent update type                           |
|                    | respect_consent_mode          | String   | Client-side | Whether Consent Mode is respected             |
|                    | ad_user_data                  | String   | Client-side | Ad user data consent                          |
|                    | ad_personalization            | String   | Client-side | Ad personalization consent                    |
|                    | ad_storage                    | String   | Client-side | Ad storage consent                            |
|                    | analytics_storage             | String   | Client-side | Analytics storage consent                     |
|                    | functionality_storage         | String   | Client-side | Functionality storage consent                 |
|                    | personalization_storage       | String   | Client-side | Personalization storage consent               |
|                    | security_storage              | String   | Client-side | Security storage consent                      |
| gtm_data           | cs_hostname                   | String   | Client-side | Client-side container hostname                |
|                    | cs_container_id               | String   | Client-side | Client-side container ID                      |
|                    | cs_tag_name                   | String   | Client-side | Client-side tag name                          |
|                    | cs_tag_id                     | Integer  | Client-side | Client-side tag ID                            |
|                    | ss_hostname                   | String   | Server-side | Server-side container hostname                |
|                    | ss_container_id               | String   | Server-side | Server-side container ID                      |
|                    | ss_tag_name                   | String   | Server-side | Server-side tag name                          |
|                    | ss_tag_id                     | Integer  | Server-side | Server-side tag ID                            |
|                    | processing_event_timestamp    | Integer  | Server-side | Event processing timestamp                    |
|                    | content_length                | Integer  | Server-side | Request content length                        |
</details>

<details><summary>Request payload additional data parameters</summary>

| Parameter | Type | Added when |
|:---|:---|:---|
| `page_data.page_status_code` | Integer | **Add page status code** is enabled |
| `datalayer` | JSON | **Add current dataLayer state** is enabled |
| `ecommerce` | JSON | **Add ecommerce data from dataLayer** is enabled |

</details>

### Campaign taxonomy
Campaign naming is optional. When `utm_campaign` follows the seven-part pattern below, the tracker stores the complete value as `campaign` and the reporting queries expose each part as a separate dimension.

| Position | Extracted as | Example |
| :--- | :--- | :--- |
| 1 | `campaign_year` | `2026` |
| 2 | `campaign_country` | `IT` |
| 3 | `campaign_funnel_stage` | `Upper funnel` |
| 4 | `campaign_platform` | `Google Ads` |
| 5 | `campaign_type` | `Search ads` |
| 6 | `campaign_marketing_objective` | `Brand awareness` |
| 7 | `campaign_name` | `Nameless Analytics` |

Separate the values with a pipe and use the full string in the landing URL:

```text
utm_campaign=2026|IT|Upper funnel|Google Ads|Search ads|Brand awareness|Nameless Analytics
```

The extracted dimensions are available at user, session and event scope and are reused by the reporting queries for users, sessions, pages, events, ecommerce, attribution, campaign performance and media plans. For example, the first part is exposed as `user_campaign_year`, `session_campaign_year` or `campaign_year`, depending on the scope.

Extraction is positional: missing parts return `NULL`, while values in the wrong position are assigned to the wrong dimension. The original campaign string remains unchanged. See the [`get_campaign_part`](tables/user-defined-functions/get_campaign_part.sql) function for the mapping used by BigQuery.

### Client-side ID management
The tracker automatically generates and manages unique identifiers for pages and events: a random 15 character identifier for every page, and one for every event.

The values sent in the payload are **partial**. The tracker cannot read `client_id` and `session_id`, which live in the `HttpOnly` cookies `na_u` and `na_s`, so it sends only the segments it owns. The Server-side Client Tag prefixes both with `{client_id}_{session_id}-` before storing the event, so the value written to BigQuery — and returned to the browser in the response — is always the full one. See [Server-side ID management](#server-side-id-management).

<details><summary>See page ID and event ID values</summary>

<br>

| Parameter name | Renewed            | Sent in the payload             | Stored in BigQuery                                              | Value composition                           |
|----------------|--------------------|---------------------------------|-----------------------------------------------------------------|---------------------------------------------|
| **page_id**    | at every page_view | WVTWEorF69ZEk3y                 | lZc919IBsqlhHks_1KMIqneQ7dsDJUa-WVTWEorF69ZEk3y                 | Client ID _ Session ID - Page ID            |
| **event_id**   | at every event     | WVTWEorF69ZEk3y_XIkjlUOkXKn99IV | lZc919IBsqlhHks_1KMIqneQ7dsDJUa-WVTWEorF69ZEk3y_XIkjlUOkXKn99IV | Client ID _ Session ID - Page ID _ Event ID |

</details>


### Smart consent management
When **Respect Google Consent Mode** is enabled, events are sent only after `analytics_storage` is granted. Pending events retain their original order, and acquisition data can be held temporarily in the first-party session cookie `na_temp` until consent is available. If Consent Mode is missing, tracking remains blocked.

When the option is disabled, events are sent independently of Consent Mode. Your CMP configuration and legal basis remain implementation-specific; see [How to respect user consents](setup-guides/SETUP-GUIDES.md#how-to-respect-user-consents).


### SPA & history management
In a Single Page Application, changing route does not reload the document. Fire a new `page_view` whenever the application displays a new meaningful page: the first `page_view` of the physical load creates the initial context, while every later one is a virtual page view that replaces the current page context.

For virtual page views, the previous tracked page becomes `page_referrer`. Event-level acquisition is recalculated from the new URL and normally becomes direct when the route no longer contains campaign parameters. User- and session-level acquisition remain unchanged, so use those scopes for acquisition reporting.

See [How to track page views](setup-guides/SETUP-GUIDES.md#how-to-track-page-views) for History Change and custom `dataLayer` implementations. Page fields can be mapped through the [Configuration Variable](https://github.com/nameless-analytics/client-side-tracker-configuration-variable#override-default-page-parameters).

The tracker sends events through a FIFO queue and can load its JavaScript dependencies from your own domain. See [First-party library hosting](setup-guides/SETUP-GUIDES.md#how-to-set-up-first-party-library-hosting).


### Cross-domain architecture

The identity cookies are `HttpOnly`, so the browser cannot read them directly. On a normal click toward a configured domain, the tracker asks the Server-side Client Tag for the active session and decorates the destination with a short-lived `na_id`.

Before encoding, the value has this structure:

```text
{session_id}.{decoration_timestamp_ms}
```

The destination accepts it only on the first `page_view`, within five minutes, and only when the session identifier contains two groups of 15 alphanumeric characters separated by an underscore. Invalid or expired values are ignored: the event is still processed using the destination's local cookies, which normally creates a new user or session.

When `analytics_storage` is denied, the identity handshake is skipped. If available, only acquisition values stored in `na_temp` are transferred through `na_*` parameters.

Link decoration depends on how navigation is triggered, consent state and a successful identity handshake. Navigation still continues when decoration cannot be applied. See [Cross-domain troubleshooting](setup-guides/TROUBLESHOOTING-GUIDE.md#cross-domain-decoration) when a link is not decorated or the transferred identity is rejected.

### Parameter hierarchy
Since parameters can be set at multiple levels (Client side variable + Client-side tag, Server-side tag), Nameless Analytics follows a strict hierarchy of importance. A parameter set at a higher level will always override one with the same name at a lower level.

System-critical parameters like `client_id`, `session_id`, `page_id` and `event_id` and the standard parameters are protected and cannot be overwritten in any way.

User, session, and event parameters follow this hierarchy of overriding:

<details><summary>See user and sessions parameters hierarchy</summary>

<br>

| **Priority** | **Level**                           | **Source**                                                    |
|--------------|-------------------------------------|---------------------------------------------------------------|
| **High**     | User and sessions parameters        | Nameless Analytics Server-side Client Tag                     |
| **Low**      | Shared user and sessions parameters | Nameless Analytics Client-side Tracker Configuration Variable |

</details>

<details><summary>See event parameters hierarchy</summary>

<br>

| **Priority** | **Level**                  | **Source**                                                    |
|--------------|----------------------------|---------------------------------------------------------------|
| **4 (High)** | Event parameters           | Nameless Analytics Server-side Client Tag                     |
| **3**        | Event parameters           | Nameless Analytics Client-side Tracker Tag                    |
| **2**        | Shared event parameters    | Nameless Analytics Client-side Tracker Configuration Variable |
| **1 (Low)**  | dataLayer event parameters | Nameless Analytics Client-side Tracker Tag                    |

</details>


Client-side validation and request errors are written to the browser console. See the [Troubleshooting Guide](setup-guides/TROUBLESHOOTING-GUIDE.md) for the corresponding actions.

## Server-side processing

The Server-side Client Tag validates each request, resolves identity and session state in Firestore, inserts the enriched event into BigQuery and optionally forwards it to an external HTTPS endpoint. The response exposes the result of each processing stage.

Geolocation can be read from supported infrastructure headers, but the visitor's raw IP address is not written to the analytics payload or BigQuery.


### Security & validation

The tag can restrict browser requests by authorized origin, reject listed IP addresses and filter selected User-Agent signatures. Authorized-origin filtering should be enabled in production, but `Origin` can be reproduced by non-browser callers and is not authentication.

Malformed JSON, unsupported fields, invalid identifiers and cookies are rejected before storage. Invalid cookie formats return `400`. A malformed cross-domain ID is ignored rather than rejecting the event, so the destination falls back to its local identity context.

Streaming Protocol requests have separate API-key and User-Agent requirements. See the [Server-side Client Tag reference](https://github.com/nameless-analytics/server-side-client-tag#client-settings) and [Troubleshooting Guide](setup-guides/TROUBLESHOOTING-GUIDE.md).

### Server-side ID management
The Nameless Analytics Server-side Client Tag automatically generates and manages unique identifiers for users and sessions.

It also completes the identifiers generated upstream: the `page_id` and `event_id` carried by the payload are partial values, and the tag prefixes both with `{client_id}_{session_id}-` resolved from the `na_u` and `na_s` cookies. This applies identically to website requests and to [Streaming Protocol](#streaming-protocol) requests, so the same event always ends up with the same identifier shape in BigQuery.

<details><summary>See client ID and session ID values</summary>

<br>

| Parameter name | Renewed                       | Example values                 | Value composition             |
|----------------|-------------------------------|--------------------------------|-------------------------------|
| **client_id**  | when `na_u` cookie is created | lZc919IBsqlhHks                | Client ID                     |
| **session_id** | when `na_s` cookie is created | lZc919IBsqlhHks_1KMIqneQ7dsDJUa | Client ID _ Random Session ID |

</details>


### User ID lifecycle

`user_id` is session-scoped and normally remains unchanged after the session is created.

| Event | Effect |
|:---|:---|
| `login` | Replaces the session `user_id` with the value carried by the event |
| `logout` | Clears the session `user_id` |

These names are reserved for this behavior. Ensure `user_id` is available before `login` fires.

In `events_raw`, each event retains the value valid at that moment. The reporting functions resolve the most recent non-null session value, so a session that contained a login remains associated with that user in aggregated reports.

### Bot protection
When enabled, bot protection rejects User-Agent values matching the maintained signature list. A missing User-Agent is always rejected, and Streaming Protocol requests must use their exact dedicated value even when the optional blacklist is disabled.

<details><summary>See bot protection list</summary>

- **HTTP Libraries:** `curl`, `wget`, `python`, `requests`, `httpie`, `go-http-client`, `java`, `okhttp`, `libwww`, `perl`, `axios`, `node`, `fetch`, `php`, `guzzle`, `ruby`, `faraday`, `rest-client`.
- **AI Agents & LLMs:** `gptbot`, `chatgpt`, `anthropic`, `claude`, `perplexity`, `bytespider`, `ccbot`.
- **SEO & Marketing Bots:** `ahrefs`, `semrush`, `dotbot`, `mj12`, `rogerbot`, `bot`, `crawler`, `spider`, `scraper`.
- **Automation & Security:** `nmap`, `zgrab`, `masscan`, `shodan`, `headless`, `phantomjs`, `selenium`, `puppeteer`, `playwright`, `cypress`, `electron`.
</details>


### Channel grouping logic
The server derives `channel_grouping` from `source` and the presence of `campaign`. User and session channel values are captured when their respective scopes are created; event-level values reflect the individual event.

<details><summary>See channel grouping rules</summary>

The following table describes how the channel grouping is determined based on the `source` and `campaign` parameters of the event.

The rules are evaluated **in the order below** and the first match wins. The order matters for sources that belong to two categories: `gemini.google.com` matches both **AI** and **Search Engine**, and is classified as `ai` because AI is checked first.

| # | Channel grouping | Source category | Campaign |
| :--- | :--- | :--- | :--- |
| 1 | `direct` | **Direct** | Any |
| 2 | `gtm_debugger` | **GTM Debugger** | Any |
| 3 | `ai` | **AI** | Any |
| 4 | `paid_search_engine` | **Search Engine** | Yes |
| 4 | `organic_search_engine` | **Search Engine** | No |
| 5 | `paid_social` | **Social** | Yes |
| 5 | `organic_social` | **Social** | No |
| 6 | `paid_shopping` | **Shopping** | Yes |
| 6 | `organic_shopping` | **Shopping** | No |
| 7 | `paid_video` | **Video** | Yes |
| 7 | `organic_video` | **Video** | No |
| 8 | `email` | **Email** | Any |
| 9 | `referral` | None of the above | No |
| 9 | `affiliate` | None of the above | Yes |

The channel grouping logic uses the following Source categories based on the source name. Matching is case-insensitive and works on substrings, so `google` also catches `news.google.com`. The only exception is the `.ai` rule, which matches the top-level domain and therefore catches `perplexity.ai` but not a source literally named `ai`.

| Source category | Source |
| :--- | :--- |
| **Direct** | `null`, `direct` |
| **GTM Debugger** | `tagassistant.google.com` |
| **Search Engine** | `360.cn`, `alice`, `aol`, `ar.search.yahoo.com`, `ask`, `bing`, `google`, `yahoo`, `yandex`, `baidu`, `ecosia`, `duckduckgo`, `sogou`, `naver`, `seznam` |
| **Social** | `facebook`, `twitter`, `t.co`, `bsky.app`, `instagram`, `pinterest`, `linkedin`, `reddit`, `vk.com`, `tiktok`, `snapchat`, `tumblr`, `wechat`, `whatsapp` |
| **Shopping** | `amazon`, `ebay`, `etsy`, `shopify`, `stripe`, `walmart`, `mercadolibre`, `alibaba`, `naver.shopping` |
| **Video** | `youtube`, `vimeo`, `netflix`, `twitch`, `dailymotion`, `hulu`, `disneyplus`, `wistia`, `youku` |
| **AI** | `chatgpt`, `gemini`, `bard`, `claude`, `alexa`, `siri`, `assistant`, plus any source on a `.ai` domain |
| **Email** | `email`, `e-mail`, `newsletter`, `mailchimp`, `sendgrid`, `sparkpost` |

</details>

The equivalent BigQuery [`get_custom_channel_grouping`](tables/user-defined-functions/get_custom_channel_grouping.sql) UDF powers customizable reporting fields. Changes to that UDF apply to historical results at query time without rewriting raw events.


### Server-side cookies
The identity cookies are issued as `HttpOnly`, `Secure` and `SameSite=Strict` on the Effective TLD+1 derived from the request origin. `na_u` lasts 400 days; `na_s` uses the configured session duration and is refreshed by valid events.

<details><summary>See user and session cookie values</summary>

<br>

| Cookie Name | Default expiration | Example values | Value composition | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **na_u**    | 400 days           | lZc919IBsqlhHks                                | Client ID                             | Used as client_id |
| **na_s**    | 30 minutes         | lZc919IBsqlhHks_1KMIqneQ7dsDJUa-WVTWEorF69ZEk3y | Client ID _ Session ID - Last Page ID | Used as session_id and to retrieve the current page_id for the **Streaming Protocol** requests. |

</details>


### Streaming Protocol

The Streaming Protocol sends backend or offline events into an existing Nameless Analytics user and session. It requires the configured API key, dedicated User-Agent, website cookies and page context; it cannot create a `page_view`.

See the [Streaming Protocol reference](streaming-protocol/STREAMING-PROTOCOL.md) for the complete request contract and examples. Website events do not use this API key.

## Storage
Firestore holds the current operational state; BigQuery holds the event history.


### Firestore as last updated snapshot
Each user document contains the latest user values and an array of session summaries. First-touch fields remain fixed, while exit information and session end time follow the latest valid event.

<details><summary>Firestore document structure example</summary>

<br>

![Nameless Analytics - Firestore collection schema](https://github.com/user-attachments/assets/d27c3ca6-f039-4702-853e-81e71ed033c2)

Firestore ensures data integrity by managing how parameters are updated across hits:

| Scope | Type | Parameters | Logic |
| :--- | :--- | :--- | :--- |
| **User** | **First-Touch** | `user_date`, `user_source`, `user_tld_source`, `user_campaign`, `user_campaign_id`, `user_campaign_click_id`, `user_campaign_term`, `user_campaign_content`, `user_channel_grouping`, `user_device_type`, `user_country`, `user_city`, `user_language`,   `user_first_session_timestamp` | Recorded at first visit, **never overwritten**. |
| **User** | **Last-Touch** | `user_last_session_timestamp` | Updated at the start of every new session. |
| **Session** | **First-Touch** | `session_date`, `session_number`, `session_start_timestamp`, `session_source`, `session_tld_source`, `session_campaign`, `session_campaign_id`, `session_campaign_click_id`, `session_campaign_term`, `session_campaign_content`,   `session_channel_grouping`, `session_device_type`, `session_country`, `session_city`, `session_language`, `session_hostname`, `session_browser_name`, `session_landing_page_category`, `session_landing_page_url`, `session_landing_page_path`, `session_landing_page_title` | Set at session start, persists throughout the session. |
| **Session** | **Last-Touch** | `session_exit_page_category`, `session_exit_page_url`, `session_exit_page_path`, `session_exit_page_title`, `session_end_timestamp` | **Updated on every hit** to reflect the latest state. |
| **Session** | **Progressive** | `cross_domain_session` | Flags as 'Yes' if any hit in the session is cross-domain. |
| **Session** | **Event-driven** | `user_id` | Set at session start, then overwritten by `login` and cleared by `logout`. See [User ID lifecycle](#user-id-lifecycle). |

</details>

#### Known limitations: Firestore 1 MiB document limit
Firestore has a hard [1 MiB document limit](https://firebase.google.com/docs/firestore/quotas#limits). The session array grows whenever a user starts a new session, and custom session parameters increase every stored entry.

If the document reaches the limit, the Firestore update fails and BigQuery is not attempted for that event. High-frequency applications should monitor document size and adapt the snapshot model before reaching this boundary.


### BigQuery as historical timeline
`events_raw` stores the enriched state attached to every event, including user, session, page, event, consent, ecommerce, dataLayer and GTM metadata. Unlike Firestore, earlier values remain available for historical analysis.

<details><summary>BigQuery schema example</summary>

<br>

![Nameless Analytics - BigQuery event_raw schema](https://github.com/user-attachments/assets/d23e3959-ab7a-453c-88db-a4bc2c7b32f4)

</details>

User deletion must remove the identifier from both Firestore and BigQuery. The provided deletion utility handles both stores, but it cannot remove the `HttpOnly` cookie from the visitor's browser. See [Data governance and maintenance](tables/TABLES.md#data-governance--maintenance).



## Reporting

BigQuery table functions transform `events_raw` into reporting-ready datasets:

| Area | Resources |
|:---|:---|
| Behavior | [Users](tables/TABLES.md#users), [Sessions](tables/TABLES.md#sessions), [Pages](tables/TABLES.md#pages), [Events](tables/TABLES.md#events) |
| Ecommerce | [Transactions](tables/TABLES.md#transactions), [Products](tables/TABLES.md#products), [Funnels](tables/TABLES.md#ecommerce-funnel) and [RFM](tables/TABLES.md#users-rfm) |
| Acquisition | [Attribution](tables/TABLES.md#attribution-comparison), [Campaigns](tables/TABLES.md#campaigns) and [Media Plan](tables/TABLES.md#media-plan) |
| Validation | [Events Debug](tables/TABLES.md#events-debug) and [Consents](tables/TABLES.md#consents) |

See [Reporting Tables](tables/TABLES.md) for setup, parameters and SQL source, or use the [Fields catalog explorer](https://datastudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_05l6ownl6d) to browse fields.

## AI support

- [Nameless Analytics QnA](https://notebooklm.google.com/notebook/73cd9ce3-9873-40cf-9d52-110d74dff5f9) answers implementation and documentation questions.
- BigQuery conversational analysis can use selected tables and routines as knowledge sources. Follow the [Setup Guide](setup-guides/SETUP-GUIDES.md#how-to-configure-a-conversational-analysis-agent-in-bigquery-studio) and review generated SQL before use.

## Google Cloud costs

The main cost drivers are the tagging-server runtime, one Firestore read/write cycle per event, BigQuery ingestion and storage, and the queries run for reporting. Actual cost depends on region, traffic, retention, query design and hosting provider, so fixed estimates quickly become outdated.

Review current [Cloud Run](https://cloud.google.com/run/pricing), [App Engine](https://cloud.google.com/appengine/pricing), [Firestore](https://cloud.google.com/firestore/pricing) and [BigQuery](https://cloud.google.com/bigquery/pricing) pricing for your deployment. Configure budgets, alerts and BigQuery query limits before production use.

## License

This project is open-source and distributed under the **Apache License 2.0**.

See the [LICENSE](LICENSE) file for the full license text.

#

[Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_readme) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
