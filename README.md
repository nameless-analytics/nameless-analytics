# Nameless Analytics
## Build your own data warehouse analytics platform

A privacy-first digital analytics platform for power users, based on [Google Tag Manager](https://marketingplatform.google.com/about/tag-manager/), [Google Firestore](https://cloud.google.com/firestore) and [Google BigQuery](https://cloud.google.com/bigquery).


Collect, analyze, and activate website interaction data with a free real-time digital analytics suite that respects user privacy.


### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change



## Start from here

- [What is Nameless Analytics](#what-is-nameless-analytics)
- [Overview](#overview)
- [Quick start](#quick-start)
  - [Documentation](#documentation)
  - [Resources](#resources)
- [Client-side collection](#client-side-collection)
  - [Request payload data](#request-payload-data)
  - [Client-side ID management](#client-side-id-management)
  - [Sequential execution queue](#sequential-execution-queue)
  - [Smart consent management](#smart-consent-management)
  - [SPA & history management](#spa--history-management)
  - [Core libraries functioning](#core-libraries-functioning)
  - [Cross-domain architecture](#cross-domain-architecture)
    - [When link decoration does not happen](#when-link-decoration-does-not-happen)
  - [Parameter hierarchy](#parameter-hierarchy)
  - [Client-side cookies](#client-side-cookies)
  - [Debugging events](#debugging-events)
- [Server-side processing](#server-side-processing)
  - [Security & validation](#security--validation)
  - [Transparency](#transparency)
  - [Server-side ID management](#server-side-id-management)
  - [User ID lifecycle](#user-id-lifecycle)
  - [Data integrity](#data-integrity)
  - [Real-time forwarding](#real-time-forwarding)
  - [Self-monitoring & performance](#self-monitoring--performance)
  - [Bot protection](#bot-protection)
  - [Geolocation & privacy by design](#geolocation--privacy-by-design)
  - [Channel grouping logic](#channel-grouping-logic)
  - [Server-side cookies](#server-side-cookies)
  - [Streaming Protocol](#streaming-protocol)
  - [Debugging requests](#debugging-requests)
- [Storage](#storage)
  - [Firestore as last updated snapshot](#firestore-as-last-updated-snapshot)
    - [Known limitations: Firestore 1 MiB document limit](#known-limitations-firestore-1-mib-document-limit)
  - [BigQuery as historical timeline](#bigquery-as-historical-timeline)
- [Reporting](#reporting)
  - [Campaign taxonomy](#campaign-taxonomy)
- [AI support](#ai-support)
  - [Q&A agents](#qa-agents)
  - [Conversational analysis agent in BigQuery Studio](#conversational-analysis-agent-in-bigquery-studio)
- [Google Cloud costs](#google-cloud-costs)
  - [Data processing](#data-processing)
  - [Data storage](#data-storage)
  - [Data governance & deletion](#data-governance--deletion)
  - [Cost summary table](#cost-summary-table)
- [License](#license)



## What is Nameless Analytics
Nameless Analytics is a privacy-first, first-party data collection infrastructure designed for organizations and analysts that demand complete control over their digital analytics.

Built upon a transparent pipeline hosted entirely on a private Google Cloud Platform environment, the platform solves critical challenges in modern analytics:

1.  **Total Data Ownership**: Unlike commercial tools where data resides on third-party servers, Nameless Analytics pipelines every interaction directly to a private BigQuery warehouse. This ensures ownership of raw data, retention policies, and reporting.
2.  **Data Quality**: By leveraging a server-side, first-party architecture, the platform reduces the impact of common client-side restrictions (such as ad blockers and ITP), ensuring granular, unsampled data collection that is far more accurate than standard client-side tracking.
3.  **Real-Time Activation**: Identical event payloads can be streamed to external APIs, CRMs, or marketing automation tools the instant an event occurs, enabling real-time personalization.
4.  **Scaling and Cost-Efficiency**: Engineered to run effectively within the **Google Cloud Free Tier** for small to medium traffic, while scaling to a highly cost-efficient pay-per-use model for enterprise-grade deployments.



## Overview
The following diagram illustrates the real-time data flow from the user's browser, through the server-side processing layer, to the final storage and visualization destinations:

![Nameless Analytics schema](https://github.com/user-attachments/assets/e9ff1593-f7c9-442e-a600-798a51a02a1e)



## Quick start
Before starting, ensure you have the following resources under the same account or service account:
- A Client-side Google Tag Manager container
- A Server-side Google Tag Manager container running on:
  - [App Engine](https://www.simoahava.com/analytics/provision-server-side-tagging-application-manually/) (thanks to [Simo Ahava](https://www.simoahava.com/))
  - or [Cloud run](https://www.simoahava.com/analytics/cloud-run-server-side-tagging-google-tag-manager/) with `X-Gclb-Country` and `X-Gclb-City` headers configured (thanks to [Simo Ahava](https://www.simoahava.com/))
  - or [Stape](https://stape.io) with geo headers power up enabled
- A Google Cloud Project with an active billing account
- A Google BigQuery project + dedicated dataset
- A Google Firestore database enabled in Native Mode

Create the BigQuery tables and table functions using the provided [SQL scripts](tables/TABLES.md)

Download and import the `template.tpl` files from the repos:
- [Client-side Tracker Tag](https://github.com/nameless-analytics/client-side-tracker-tag)
- [Client-side Tracker Configuration Variable](https://github.com/nameless-analytics/client-side-tracker-configuration-variable)
- [Server-side Client Tag](https://github.com/nameless-analytics/server-side-client-tag)

Read the [setup guides](setup-guides/SETUP-GUIDES.md) for more details.


### Documentation
- [Setup guides](setup-guides/SETUP-GUIDES.md)
- [Troubleshooting](setup-guides/TROUBLESHOOTING-GUIDE.md)
- [Tables](tables/TABLES.md)
- [Streaming Protocol](streaming-protocol/STREAMING-PROTOCOL.md)


### Resources
- [Live Demo](https://namelessanalytics.com) (Open the dev console).
- [Changelog](CHANGELOG.md)
- [Roadmap](ROADMAP.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [License](LICENSE)



## Client-side collection
The **Client-side Tracker Tag** abstracts complex logic to ensure reliable data capture under any condition.


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

#### Page status code
When the "Add page status code" option is enabled, a `page_status_code` parameter will be added to the page_data object in the payload:

| **Parameter name** | **Sub-parameter** | **Type** | **Added**   | **Field description** |
|--------------------|-------------------|----------|-------------|-----------------------|
| page_status_code   |                   | Integer  | Client-side | Page status code      |

#### Add dataLayer data
When the "Add current dataLayer state" option is enabled, a `dataLayer` parameter will be added to the payload:

| **Parameter name** | **Sub-parameter** | **Type** | **Added**   | **Field description** |
|--------------------|-------------------|----------|-------------|-----------------------|
| dataLayer          |                   | JSON     | Client-side | DataLayer data        |

#### Ecommerce data
When **Add ecommerce data from dataLayer** is enabled, an `ecommerce` parameter will be added to the payload:

| **Parameter name** | **Sub-parameter** | **Type** | **Added**   | **Field description** |
|--------------------|-------------------|----------|-------------|-----------------------|
| ecommerce          |                   | JSON     | Client-side | Ecommerce data        |

</details>

#### Payload size limit
Requests are sent with the `keepalive` flag, so an event fired while the visitor is leaving completes even after the page is gone. In exchange, browsers cap the body of a `keepalive` request at **64 KiB**: a larger payload is rejected before it leaves the browser and **the event is lost**, with `🔴 Request not sent successfully` in the console and no request in the Network tab. The budget is shared with every other in-flight `keepalive` request and `navigator.sendBeacon()` call of the page, including other vendors' tags, so the usable ceiling is lower when several tags fire together.

A standard event weighs around 2.8 KB, far from the limit. The two optional parts that can approach it are [Add current dataLayer state](https://github.com/nameless-analytics/client-side-tracker-configuration-variable#add-current-datalayer-state), which grows with every push on the page, and `ecommerce` objects carrying very long item arrays. When either is enabled on a rich page, check the resulting size and prefer sending the parameters you actually need as event parameters.


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


### Sequential execution queue
Implements specific logic to handle high-frequency events (e.g., rapid clicks), ensuring requests are dispatched in strict FIFO order to preserve the narrative of the session.


### Smart consent management
Fully integrated with Google Consent Mode. Choose between respect or not respect consent mode:
- When Google Consent Mode is present and `respect_consent_mode` is enabled, the events are sent only if a user consents.
  - if `analytics_storage` is equal to `denied`, the Nameless Analytics Client-side Tracker waits until consent is granted. The tag automatically preserves the original acquisition context (source and campaign data and page referrer) using a temporary first-party cookie named `na_temp`. Once consent is granted (even multiple pages later), the tag retrieves the data from the cookie and correctly attributes the session, preventing incorrect "direct" or "internal" referral attribution.
  - if `analytics_storage` changes from `denied` to `granted`, all pending tags for the page will be fired in execution order
- When Google Consent Mode is not present and `respect_consent_mode` is enabled, none of the events are sent.
- When `respect_consent_mode` is disabled, all events are sent regardless of presence of Google Consent Mode.


### SPA & history management
Native support for Single Page Applications. See the [Page View Setup Guide](setup-guides/SETUP-GUIDES.md#how-to-track-page-views) for implementation examples.

The tracker counts the `page_view` events fired within the same physical page load. The first one is the real page view; every following one is a **virtual page view**, and from that moment the tag stops treating the visit as an arrival and starts treating it as internal navigation.

| On virtual page views | Behaviour |
| :--- | :--- |
| `page_referrer` | Set to the URL of the previous page view, so the SPA route change looks like internal navigation instead of inheriting the original external referrer. Events fired on a virtual page inherit that page's referrer |
| `source`, `campaign`, `campaign_id`, `campaign_term`, `campaign_content`, `campaign_click_id` | Reset to `null`, **unless the current URL still carries the corresponding parameter** (`utm_*`, a click ID such as `gclid` or `fbclid`, or an `na_*` cross-domain parameter). Since SPA routing usually drops the query string on the first route change, in practice they become `null` |

The consequence to keep in mind when querying: on virtual page views and on the events fired on them, `event_data.source` is `null`, `event_data.tld_source` is absent and the server therefore resolves `event_data.channel_grouping` to `direct` — see [Channel grouping logic](#channel-grouping-logic). This is **event-level** attribution only.

User and session attribution are not affected: `user_source`, `session_source`, their campaign fields and the two channel groupings are first-touch values, written once when the user or the session is created and never overwritten (see [Firestore as last updated snapshot](#firestore-as-last-updated-snapshot)). A session that starts from Google Ads keeps `session_channel_grouping = paid_search_engine` for its whole duration, no matter how many virtual page views follow.

So, for acquisition reporting always use the session or user fields. Use the event-level `source` and `channel_grouping` only to answer a different question: which events happened on the landing page, still carrying the acquisition context, and which happened after the visitor moved on.


### Core libraries functioning
The tracker relies on a main external library and a dependency library loaded by Nameless Analytics Client-side Tracker Tag.

To maximize data collection accuracy, Nameless Analytics supports **First-Party mode**, allowing you to host this library on your own domain or CDN instead of using external CDNs.

<details><summary>Main library</summary>

<br>

This is the core engine that supports the GTM tag by exposing utility functions for execution in a standard JavaScript environment. [Source code](https://github.com/nameless-analytics/client-side-tracker-tag/blob/main/lib/)

It handles the following background operations:

- **Payload Enrichment:** Formats timestamps into BigQuery-compatible date strings and captures browser environment metrics like screen resolution and viewport size.
- **Sequential Requests Queue:** Implements a Promise-based queue to ensure that HTTP requests are sent in the exact order they occurred (FIFO), preserving the timeline of user interactions.
- **Cross-domain Handshake:** Manages a global click listener that detects cross-domain links. It triggers a server-side handshake via the `get_user_data` function to retrieve the visitor's server-side identities. Before redirecting, the tracker combines the server-issued `session_id` with the current URL-decoration timestamp, Base64-encodes the resulting value and assigns it to the `na_id` URL parameter.
- **Server Identity Retrieval (`get_user_data`):** A dedicated function that performs an asynchronous POST request to the Server-side Client Tag to fetch the active `client_id` and `session_id`. This ensures that cross-domain tracking uses the authoritative IDs issued by the server.
- **Consent State Mapping:** Provides a function to read the current state of all Google Consent Mode types directly from the global GTM data object.

</details>

<details><summary>Dependency library</summary>

<br>

Parses the browser's `User-Agent` string and extracts granular information about the device vendor, model, operating system, and browser engine version. Source code: [ua-parser-js](https://github.com/faisalman/ua-parser-js). The tag is pinned to version **1.0.40**, the latest release under the MIT licence.

This data is mapped into the `event_data` object under `device_vendor`, `os_version`, `device_model`, etc.

</details>


### Cross-domain architecture
Nameless Analytics uses `HttpOnly` cookies for security, identifiers are invisible to client-side JavaScript and cannot be read directly to decorate links.

For retrieving the active `client_id` and `session_id` the Nameless Analytics Client-side Tracker Tag needs to perform a handshake with the server before redirecting and decorating outbound URLs with the `na_id` parameter in real time.

The `na_id` parameter is an ephemeral, Base64-encoded cross-domain value. Before encoding, its internal structure is:

```text
{session_id}.{decoration_timestamp_ms}
```

The encoded value is added to the destination URL using URLSearchParams. On the destination domain, the Client-side Tracker Tag decodes and validates the value before adding the original session_id to the event payload as cross_domain_id.
The value is accepted only on the first page view of the destination page and expires five minutes after URL decoration. Malformed values, timestamps in the future and expired values are rejected.

The value is validated **twice**, on both sides of the request:

| Where | What is checked |
| :--- | :--- |
| **Client-side Tracker Tag** | Base64 decoding, `{session_id}.{decoration_timestamp_ms}` structure, `session_id` format, timestamp not in the future, no more than five minutes elapsed |
| **Server-side Client Tag** | `session_id` format |

The required `session_id` format is 15 alphanumeric characters, an underscore, 15 alphanumeric characters — the same shape the server issues. A value rejected by the server is discarded and the event is processed as if no cross-domain ID were present: user and session are resolved from the local `na_u` and `na_s` cookies, which in the typical case — a visitor arriving from another domain with no active session on the destination — means a new session. The event itself is still processed and stored, and `🟠 Invalid cross-domain ID format` is logged in GTM Server Preview.

#### When link decoration does not happen
Link decoration is driven by a delegated `click` listener on the document, so it only runs when the visitor activates a link with a plain left click. In every case below the visitor still reaches the destination normally, but without `na_id`: the destination resolves identity from its own `na_u` and `na_s` cookies, which for a first visit means a **new user and a new session**.

| Case | Why | Workaround |
| :--- | :--- | :--- |
| Right-click → "Open link in new tab" / "Open in new window" | The context menu does not fire a `click` event | None |
| `Cmd`/`Ctrl`+click, `Shift`+click, `Alt`/`Option`+click, middle click | The tracker deliberately ignores modified clicks so the browser keeps its native behaviour (new tab, new window, download). Hijacking them would break the visitor's intent | None. This is a deliberate trade-off: correct navigation over attribution |
| Link copied and pasted, opened from bookmarks, history or an external app | No click on the source page | None |
| Navigation not driven by an `<a href>` (JS button, `window.open()`, form submit, server-side redirect) | There is no link for the listener to decorate | Decorate the URL server-side, or move the navigation to a real `<a href>` |
| `href` starting with `#`, `javascript:`, `tel:` or `mailto:` | Skipped by design | None |
| Another script calls `stopPropagation()` on the click | The event never reaches the document-level listener | Remove the `stopPropagation()`, or bind the other handler in the capture phase |
| Destination domain not listed in **Cross-domain domains**, or same domain as the source | Not a cross-domain link | Add the domain to the list |
| The main library is blocked (ad blocker, CSP, CDN failure) | The listener is never registered | Use [First-Party mode](setup-guides/SETUP-GUIDES.md#how-to-set-up-first-party-library-hosting) |
| Consent Mode missing while `respect_consent_mode` is enabled | The tracker aborts before decorating | None: this is the intended privacy behaviour |
| `analytics_storage` denied | No identity handshake is performed. The URL still receives the `na_*` acquisition parameters, but only if the `na_temp` cookie exists | None: this is the intended privacy behaviour |
| `get_user_data` fails, or `na_u` / `na_s` are missing server-side | No `session_id` to encode. The visitor is redirected to the original URL | Verify the endpoint is reachable and the visitor has valid cookies |

On links carrying `target="_blank"` the new tab is opened by the tracker itself, not by the browser. As browsers do for `target="_blank"`, the destination gets no `window.opener` reference back to the source page, unless the link explicitly declares `rel="opener"`.

A decorated link can also be **rejected on arrival**, with the same outcome. This happens when more than five minutes elapse between the click and the first `page_view` on the destination (link opened in a background tab, slow connection, machine suspended), when the `page_view` is not the first one of the physical page, or when the destination page runs an incompatible version of the tag. See the [Troubleshooting Guide](setup-guides/TROUBLESHOOTING-GUIDE.md#cross-domain-issues) for the corresponding console messages.

<details><summary>How the cross-domain handshake works</summary>

<br>

- When `respect_consent_mode` is disabled or `respect_consent_mode` is enabled and `analytics_storage` = granted:
  - **Handshake Initialization**: When a user clicks a link toward a configured cross-domain, the tracker intercepts the event, **pauses navigation**, and performs a real-time asynchronous POST call to the Server-side GTM endpoint with `event_name: 'get_user_data'`.
  - **Identity Extraction (`HttpOnly` bypass)**: The Server-side Client Tag receives the request. Since the call is directed to its own domain, it has access to the `HttpOnly` cookies (`na_u` and `na_s`). It securely extracts the `client_id` and `session_id`.
  - **Real-time Response**: Instead of streaming the data to BigQuery, the server immediately responds to the browser by providing both identifiers in a JSON payload.
  - **URL Decoration**: The tracker combines the server-issued `session_id` with the current timestamp using the `{session_id}.{decoration_timestamp_ms}` structure. The complete value is Base64-encoded and assigned to the `na_id` URL parameter before navigation continues.
  - **Cross-domain ID Validation**: On the destination domain, the Client-side Tracker Tag decodes `na_id` and validates its structure and timestamp. The value is accepted only on the first `page_view` and only within five minutes of URL decoration.
  - **Session Stitching**: If the value is valid, the decoded `session_id` is added to the event payload as `cross_domain_id` and sent to the destination domain's Server-side Client Tag. Invalid or expired values are ignored. If identifying parameters are missing but `na_*` acquisition parameters are present, the tracker instead initializes a local `na_temp` cookie to preserve attribution context.

  By intercepting the link click to perform a real-time server-side identity check, Nameless Analytics improves the reliability of the identifiers passed to the destination domain.

  While this can introduce very small latency, it eliminates session fragmentation and ensures reliable cross-domain attribution in environments with strict privacy restrictions.

- When `respect_consent_mode` is enabled and `analytics_storage` = denied:
  - **Handshake Bypass**: To protect user privacy and comply with consent policies, the server-side identity handshake is skipped. No identifiers (`client_id` or `session_id`) are retrieved or transferred.
  - **Acquisition Extraction**: The tracker reads the current marketing context (UTMs, Click IDs, and Referrer) directly from the `na_temp` first-party cookie.
  - **URL Decoration**: The target URL is decorated with specific acquisition parameters (e.g., `?na_source=google&na_campaign=summer_sale`) instead of the `na_id` parameter. Only non-null parameters are appended.
  - **Local Attribution Persistence**: Upon landing on the destination domain, the tracker detects the `na_` parameters and immediately initializes a local `na_temp` cookie.

  This ensures that the original marketing source is preserved across the entire domain ecosystem, even in a consent-denied state, without compromising privacy.


</details>


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


### Client-side cookies
The temporary attribution cookie `na_temp` is set by the Nameless Analytics Client-side Tracker when respect consent mode is enabled and consent for analytics_storage has been denied.

It expires when consent given or at browser session level, whichever happens first.

<details><summary>See temp cookie value</summary>

<br>

| Cookie Name | Default expiration | Example values | Value composition | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **na_temp** | Session | {<br> &nbsp; &nbsp; "source": "google", <br> &nbsp; &nbsp; "campaign": "summer_sale", <br> &nbsp; &nbsp; "campaign_id": "12345", <br> &nbsp; &nbsp; "campaign_click_id": "67890", <br> &nbsp; &nbsp; "campaign_content": "ad_group_1", <br> &nbsp; &nbsp; "campaign_term": "running_shoes", <br> &nbsp; &nbsp; "page_referrer": "https://www.google.com/" <br>}| JSON object of acquisition parameters | Temporarily stores acquisition parameters when `analytics_storage` is denied. |

This is the lifecycle of `na_temp` cookie:
- **Session Expiration**: `na_temp` is a standard session cookie. Unlike persistent cookies, it lives exclusively in the browser's temporary memory. It expires and is automatically deleted by the browser as soon as the **entire browser process is closed** (closing only a single tab or window will not delete the cookie). This ensures attribution remains consistent even if the user navigates your site across multiple tabs.
- **Conditional Deletion**: the cookie is not deleted immediately upon consent grant. Instead, it is forcefully removed during the **first `page_view` event (standard or virtual) that occurs while `analytics_storage` is already set to granted**. This ensures that if consent is granted mid-page, the original acquisition data remains available to attribute all subsequent events on that page before being purged on the next page transition.

</details>


### Debugging events
Real-time tracker logs and errors are logged to the **Browser Console**, ensuring immediate feedback during implementation.

For a detailed guide on resolving common sequence and integration issues, see the [Troubleshooting Guide](setup-guides/TROUBLESHOOTING-GUIDE.md).



## Server-side processing
The **Server-side Client Tag** sits between the public internet and your cloud infrastructure, verifying, claiming or rejecting every request.


### Security & validation
Validates request origins and authorized domains (CORS) before processing to prevent unauthorized usage.

Identifiers are validated before being trusted: the `na_u` and `na_s` cookies must match their expected format, and the `cross_domain_id` carried in the payload must match the format of a server-issued `session_id`. Requests carrying malformed cookies are rejected with `403`; a malformed `cross_domain_id` is discarded and the event is processed as if it had not been sent, leaving user and session to be resolved from the `na_u` and `na_s` cookies.


### Transparency
The data processed by the server is returned to the client within the request response. This provides full visibility into the collected information, allowing for real-time verification and ensuring the entire data pipeline remains transparent and auditable directly from the browser's network tab.


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
The `user_id` is a session-level parameter. It is taken from the payload when the session is created, and from that moment it is **frozen**: a regular event cannot change it, even if it carries a different value.

Two event names are the exception, and they are handled explicitly by the Server-side Client Tag:

| Event name | Effect on `user_id` |
| :--- | :--- |
| `login` | Overwrites the session `user_id` with the value carried by that event |
| `logout` | Clears the session `user_id`, setting it to `null` |

Because `login` writes whatever the payload carries at that moment, make sure the User ID is already available in the Configuration Variable when the `login` tag fires: otherwise the session is updated with an empty value. `logout` always clears the value, regardless of the payload.

The updated value is reflected in BigQuery starting from the same event, since the session record is written back to the payload after the Firestore update.

Renaming these two standard events breaks this behaviour silently: the session `user_id` will simply stop being updated.

#### Reporting resolves it differently from the raw data
In `events_raw` every event stores the `user_id` as it was at that moment, so the events fired after a `logout` carry `null`.

The [`events`](tables/TABLES.md#events) table function does not: it resolves `user_id` with `FIRST_VALUE(... IGNORE NULLS)` over the whole session, so **every row of a session carries the most recent non-null value**, including the events before the `login` and those after the `logout`. The `sessions`, `users` and `pages` functions read from `events` and inherit the same resolution.

The practical consequence: a `logout` clears the value in Firestore and in the raw table, but it does not make the session anonymous in the reports. A session where the visitor logged in is attributed to that `user_id` end to end. To see the value as it was at each single event, query `session_data` directly in `events_raw` instead of using the table functions.


### Data integrity
The server will reject any interaction (e.g., click, scroll) with a `403 Forbidden` status if it hasn't been preceded by a valid `page_view` event for that session. This ensures every session in BigQuery has a clear starting point and reliable attribution.


### Real-time forwarding
Supports instantaneous data streaming to external HTTP endpoints immediately after processing. The system allows for **custom HTTP headers** injection, enabling secure authentication with third-party services endpoints directly from the server.


### Self-monitoring & performance
The system transparently tracks pipeline health by measuring **ingestion latency** (the exact millisecond delay between the client hit and server processing) and **payload size**. This data allows for high-resolution monitoring of the real-time data flow directly within BigQuery.


### Bot protection
Actively detects and blocks automated traffic returning a `403 Forbidden` status. The system filters requests based on a predefined blacklist of 45 User-Agent strings.

<details><summary>See bot protection list</summary>

- **HTTP Libraries:** `curl`, `wget`, `python`, `requests`, `httpie`, `go-http-client`, `java`, `okhttp`, `libwww`, `perl`, `axios`, `node`, `fetch`, `php`, `guzzle`, `ruby`, `faraday`, `rest-client`.
- **AI Agents & LLMs:** `gptbot`, `chatgpt`, `anthropic`, `claude`, `perplexity`, `bytespider`, `ccbot`.
- **SEO & Marketing Bots:** `ahrefs`, `semrush`, `dotbot`, `mj12`, `rogerbot`, `bot`, `crawler`, `spider`, `scraper`.
- **Automation & Security:** `nmap`, `zgrab`, `masscan`, `shodan`, `headless`, `phantomjs`, `selenium`, `puppeteer`, `playwright`, `cypress`, `electron`.
</details>


### Geolocation & privacy by design
Automatically maps the incoming request IP to geographic data (Country, City) for regional analysis. The system is designed to **never persist the raw IP address** in BigQuery, ensuring native compliance with strict privacy regulations.

To enable this feature, your server must be configured to forward geolocation headers:

| Environment | Country header | City header |
| :--- | :--- | :--- |
| **App Engine** | `X-Appengine-Country` | `X-Appengine-City` |
| **Cloud Run** | `X-Gclb-Country: {client_region}` | `X-Gclb-City: {client_city}` |
| **Stape** | `X-GEO-Country` | `X-GEO-City` |

App Engine provides its headers with no configuration. On Cloud Run the two headers must be added as custom request headers on the Load Balancer, following [this guide](https://www.simoahava.com/analytics/cloud-run-server-side-tagging-google-tag-manager/#add-geolocation-headers-to-the-traffic) (thanks to [Simo Ahava](https://www.simoahava.com/) for helping us again). On Stape, enable the GEO Headers power-up.


### Channel grouping logic
Automatically categorizes traffic sources into predefined groups (e.g., Organic Search, Paid Social, AI, Email) using a server-side regex-based pattern matching system.

The Server-side Client Tag automatically processes attribution data for every incoming request. By analyzing the `source` and `campaign` parameters, it applies a regex-based logic to categorize the traffic into standard groups (e.g., Organic Search, Paid Social, Email, etc.).

This centralized processing ensures that:
- **Consistency**: All events within a session share the same attribution logic, regardless of the source (Website or Streaming Protocol).
- **Maintenance**: Updates to channel definitions only need to be applied once at the server level.

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

The same logic is also available as a BigQuery [User-Defined Function (UDF)](tables/user-defined-functions/get_custom_channel_grouping.sql) called `get_custom_channel_grouping`, used by the [reporting table functions](tables/TABLES.md#create-custom-functions) to calculate the `custom_channel_grouping`, `session_custom_channel_grouping`, and `user_custom_channel_grouping` fields on the fly at query time. By default, the UDF uses the same identical rules as the server-side logic. However, since the UDF lives in BigQuery, it can be freely customized to adapt the channel grouping to specific analysis needs (e.g., adding new source categories or redefining grouping rules) and any changes will be retroactively applied to all historical data.


### Server-side cookies
The server-side identity cookies `na_u` and `na_s` are HttpOnly, Secure and SameSite=Strict.

The platform automatically calculates the appropriate cookie domain by extracting the **Effective TLD+1** from the request origin. This ensures seamless identity persistence across subdomains without manual configuration.

Cookies are created or updated on every event to track the user's session and identity across the entire journey. The expiration of the client identifier cookie (`na_u`) is set to **400 days**, which is the maximum lifespan allowed by modern browsers (e.g., Chrome, Safari) for first-party cookies, ensuring long-term user recognition while remaining compliant with browser restrictions.

<details><summary>See user and session cookie values</summary>

<br>

| Cookie Name | Default expiration | Example values | Value composition | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **na_u**    | 400 days           | lZc919IBsqlhHks                                | Client ID                             | Used as client_id |
| **na_s**    | 30 minutes         | lZc919IBsqlhHks_1KMIqneQ7dsDJUa-WVTWEorF69ZEk3y | Client ID _ Session ID - Last Page ID | Used as session_id and to retrieve the current page_id for the **Streaming Protocol** requests. |

</details>


### Streaming Protocol
The Streaming Protocol is specifically designed for server-to-server communication, allowing you to send events directly from your backend or other offline sources.

Use the Streaming Protocol to:
- Attribute realtime events to a session by sending data from your backend when a purchase or subscription is completed.
- Attribute offline events to a session by sending data from your backend days after a session ended.

To protect against unauthorized data injection from external servers, the system supports an optional **API Key authentication** for the Streaming Protocol.

The Server-side Client Tag will automatically reject any request where `event_origin` is not set to "Streaming Protocol" and does not include a valid `X-Api-Key` header matching your configuration.


### Debugging requests
Developers can monitor the server-side logic in real-time through **GTM Server Preview Mode**.

For detailed information on server-side errors and validation issues, refer to the [Troubleshooting Guide](setup-guides/TROUBLESHOOTING-GUIDE.md).



## Storage
Nameless Analytics employs a complementary storage strategy to balance real-time intelligence with deep historical analysis:


### Firestore as last updated snapshot
It maintains **the latest available state for every user and session** (for example, a custom `user_level` parameter).

- **User data**: Stores the latest user profile state, including first/last session timestamps, original acquisition source, and persistent device metadata.
- **Session data**: Stores the latest session state, including real-time counters (total events, page views), landing/exit page details, and session-specific attribution.

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
Google Firestore imposes a hard limit of [1 MiB per document](https://firebase.google.com/docs/firestore/quotas#limits).
Nameless Analytics continuously appends new sessions to the user's document array to maintain cross-session context.
Due to how Firestore calculates document size (billing the repeated byte weight of all 29 keys for every single element in the array), the weight of a single session object fluctuates based on the length of inbound URLs, typically ranging from 1.1 KB to over 2 KB for extreme URLs. Consequently, a user document can safely store anywhere between **~300 and ~900 unique sessions** before hitting the limit.

Given the `na_u` cookie's maximum 400-day expiration, a user would need to return to the site and trigger a new session almost every day to exceed this quota. While this is mathematically possible for high-frequency SaaS applications, it is extremely unlikely for standard websites (e-commerce, blogs, corporate).

**Adding Custom Parameters:** If you customize the Server-side code to track additional custom parameters, keep in mind that:
  - **User parameters** (stored at the root of the document) are only written once and have a negligible impact on this limit.
  - **Session parameters** are appended inside the array and multiplied by every single session.
Adding custom Session parameters will increase the base byte weight of the session object, proportionally reducing the maximum number of sessions the document can store before hitting the 1 MiB limit.

> [!WARNING]
> **Warning:** To maintain strict data consistency, Nameless Analytics processes BigQuery inserts only after a successful Firestore update. If a user document exceeds the 1 MiB limit, the Firestore write will fail, causing the server to abort the request (403 Forbidden). Consequently, subsequent events for that specific user will not be recorded in either Firestore or BigQuery.


### BigQuery as historical timeline
It maintains **every single state transition** for every user and session (for example, all different `user_level` custom parameter values through time).

- **User data**: Stores the current user profile state at event occurs, including first/last session timestamps, original acquisition source, and persistent device metadata.
- **Session data**: Stores the current session state at event occurs, including real-time counters (total events, page views), landing/exit page details, and session-specific attribution.
- **Page data**: Stores the current page state at event occurs, including page name, timestamp, and page-specific attributes.
- **Event data**: Stores the current event state at event occurs, including event name, timestamp, and event-specific attributes.
- **dataLayer data**: Stores the current dataLayer state at event occurs, including dataLayer name, timestamp, and dataLayer-specific attributes.
- **Ecommerce data**: Stores the current ecommerce state at event occurs, including ecommerce metrics, timestamp, and ecommerce-specific attributes.
- **Consent data**: Stores the current consent state at event occurs, including consent status, timestamp, and consent-specific attributes.
- **Events Debug data**: Stores the current events debug state at event occurs, including metrics, timestamp, and specific attributes.

<details><summary>BigQuery schema example</summary>

<br>

![Nameless Analytics - BigQuery event_raw schema](https://github.com/user-attachments/assets/d23e3959-ab7a-453c-88db-a4bc2c7b32f4)

</details>



## Reporting
Nameless Analytics offers a set of BigQuery [SQL Table Functions](tables/TABLES.md) to query and explore the raw data at:

- [Users](tables/table-functions/users.sql) - [View schema](tables/TABLES.md#users)
- [Users RFM](tables/table-functions/users_rfm.sql) - [View schema](tables/TABLES.md#users-rfm)
- [Sessions](tables/table-functions/sessions.sql) - [View schema](tables/TABLES.md#sessions)
- [Pages](tables/table-functions/pages.sql) - [View schema](tables/TABLES.md#pages)
- [Events](tables/table-functions/events.sql) - [View schema](tables/TABLES.md#events)
- [Events Debug](tables/table-functions/events_debug.sql) - [View schema](tables/TABLES.md#events-debug)
- [Ecommerce Transactions](tables/table-functions/ec_transactions.sql) - [View schema](tables/TABLES.md#transactions)
- [Ecommerce Products](tables/table-functions/ec_products.sql) - [View schema](tables/TABLES.md#products)
- [Ecommerce Funnel](tables/table-functions/ec_funnel.sql) - [View schema](tables/TABLES.md#ecommerce-funnel)
- [Ecommerce Funnel Pivot](tables/table-functions/ec_funnel_pivot.sql) - [View schema](tables/TABLES.md#ecommerce-funnel-pivot)
- [Consents](tables/table-functions/consents.sql) - [View schema](tables/TABLES.md#consents)
- [Attribution Single Touch](tables/table-functions/attribution_single_touch.sql) - [View schema](tables/TABLES.md#attribution-single-touch)
- [Attribution Multi Touch](tables/table-functions/attribution_multi_touch.sql) - [View schema](tables/TABLES.md#attribution-multi-touch)
- [Attribution Comparison](tables/table-functions/attribution_comparison.sql) - [View schema](tables/TABLES.md#attribution-comparison)
- [Campaigns](tables/table-functions/campaigns.sql) - [View schema](tables/TABLES.md#campaigns)
- [Media Plan](tables/table-functions/media_plan.sql) - [View schema](tables/TABLES.md#media-plan)

The [Fields catalog explorer](https://datastudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_05l6ownl6d) lists every field exposed by these table functions, with its scope, type and description.


### Campaign taxonomy
Nameless Analytics does not store campaign dimensions separately: it parses them at query time from the campaign string, through the [`get_campaign_part`](tables/user-defined-functions/get_campaign_part.sql) UDF. The convention is a pipe-delimited string whose parts are read by position:

| Position | Extracted as | Example |
| :--- | :--- | :--- |
| 1 | `campaign_year` | `2026` |
| 2 | `campaign_country` | `IT` |
| 3 | `campaign_funnel_stage` | `Upper funnel` |
| 4 | `campaign_platform` | `Google Ads` |
| 5 | `campaign_type` | `Search ads` |
| 6 | `campaign_marketing_objective` | `Brand awareness` |
| 7 | `campaign_name` | `Nameless Analytics` |

```text
2026|IT|Upper funnel|Google Ads|Search ads|Brand awareness|Nameless Analytics
```

The same string is used as `utm_campaign` on landing URLs, so the taxonomy travels with the click and every session inherits it. Missing parts return `NULL`: a shorter string does not break the query, it simply produces empty dimensions.

Since parsing happens at query time, editing the UDF changes the taxonomy retroactively across all historical data, exactly like the [channel grouping](#channel-grouping-logic) function.



## AI support
### Q&A agents
Get expert help for implementation and technical documentation:

- **[Nameless Analytics QnA](https://notebooklm.google.com/notebook/73cd9ce3-9873-40cf-9d52-110d74dff5f9)**: Specialized Google Notebook LM trained on the platform docs.


### Conversational analysis agent in BigQuery Studio
In BigQuery Studio, it is possible to configure a Data Agent (powered by Gemini) for conversational analysis, allowing users to explore and query datasets using simple natural language. These agents leverage tables, views, and **table functions** as "knowledge sources" to learn the data schema and business logic.

Table functions are particularly strategic in this scenario: by accepting parameters, they allow encapsulating and centralizing complex metrics and business logic, providing the agent with a clean and reusable interface to filter results dynamically.

To maximize the accuracy of the agent's responses, it is crucial to enrich these sources with well-defined metadata descriptions at the schema level, provide contextual system instructions, and include a set of "golden queries" to train the model on the organization's specific use cases. To learn how to configure this agent with your data, check the [Setup Guide](setup-guides/SETUP-GUIDES.md#how-to-configure-a-conversational-analysis-agent-in-bigquery-studio).



## Google Cloud costs
Nameless Analytics is designed to achieve maximum performance with minimum overhead. By utilizing Google Cloud's serverless offerings, the platform can operate at **near-zero cost** for many users and scales predictably with traffic.


### Data processing
You can choose the compute environment that best fits your traffic and budget:

- **Cloud Run (Recommended)**: The most modern and cost-effective choice. It scales to zero when there's no traffic. The Google Cloud "Always Free" tier includes **2 million requests per month**, which covers most small-to-medium websites at no charge.
- **App Engine Standard**: Ideal for 24/7 uptime on a budget. Includes **28 free instance-hours per day** (F1 instances), allowing for a continuous single-server setup at **no cost**.
- **App Engine Flexible**: Best for enterprise-scale deployments (5-10M+ hits/month) requiring multi-zone redundancy. Typically starts at ~$120/month for a 3-instance minimum cluster.


### Data storage
Data will be stored in two different locations:

- **Google Firestore**: Manages real-time session states. Billing is based on **document operations** (Reads and Writes). Since every event requires 1 read and 1 write to manage session state, the total cost is approximately **$0.12 per 100,000 events** (Reads: $0.03/100k + Writes: $0.09/100k, excluding the daily free tier).

- **Google BigQuery**: Your long-term historical data warehouse. These estimates include **data storage** (~$0.02/GB) and **streaming ingestion**. Nameless Analytics leverages the **BigQuery Storage Write API**, which includes a **FREE tier of 2 TB per month** for ingestion. This means data ingestion costs are **$0** for all traffic tiers listed below.

Query processing (scanning data in BigQuery for analysis/reporting) is billed separately by Google Cloud based on usage. However, the first **1 TB per month** is always free.


### Data governance & deletion
To comply with GDPR and privacy regulations, Nameless Analytics provides a dedicated **[User Data Deletion Script](setup-guides/SETUP-GUIDES.md#data-governance--privacy-compliance)**.

This Python utility allows you to remove all data for a specific `client_id` from both BigQuery and Firestore in a single operation: the historical timeline and the real-time snapshot are both erased server-side.

The script does not remove the `na_u` cookie from the visitor's browser: it is a first-party cookie that the server cannot delete remotely, and it lasts up to 400 days. If that visitor returns to the site, the Server-side Client Tag reads the existing `na_u` and recreates the user under the **same `client_id`**, so data collected from that point on is associated with that identifier again. To complete the erasure client-side as well, the visitor must clear the site cookies.


### Cost summary table
This is an estimated monthly cost breakdown for the platform, based on **real-world Google Cloud pricing** and **measured event payload size** (~2.8 KB / event).

**Excluded costs:** BigQuery query processing (1 TB/month free tier)

| Traffic Tier | Monthly Events | Compute (Cloud Run / GAE / Stape) | Firestore Reads / Writes | BigQuery Ingest & Storage | **Estimated Total (Cloud Run / GAE / Stape)** |
|--------------|----------------|-----------------------------------|--------------------------|---------------------------|----------------------------------------|
| **Low** | < 500k | $0 / $0* / $20 | ~$0 | ~$0 | FREE – $20 |
| **Medium** | 1M – 2M | $0 – $1 / $0* / $20 | ~$0.5 – $1.5 | ~$0 | $1 – $3 / $1 – $2 / $21+ |
| **High** | 5M | ~$8 – $12 / $0* / $100 | ~$6 | ~$0.3 | $14 – $18 / $6 – $8 / $106+ |
| **Enterprise** | 10M | ~$20 – $40 / ~$120** / $100 | ~$12 | ~$0.6 | $33 – $53 / $133+ / $113+ |
| **Enterprise+** | 50M | ~$80 – $130 / ~$120** / $200 | ~$60 | ~$2.8 | $143 – $193 / $183+ / $263+ |

<br>

\* App Engine **Standard Environment (F1 instance)** – suitable for low/medium traffic<br>
\** App Engine **Flexible Environment (multi-instance cluster)** – suitable for high traffic<br>
\*** Stape.io **Personal ($0), Pro ($20), Business ($100), Enterprise ($200)** plans based on traffic

**Pricing sources** (verified April 2026): [Cloud Run](https://cloud.google.com/run/pricing) · [App Engine Standard](https://cloud.google.com/appengine/pricing#standard_instance_pricing) · [App Engine Flexible](https://cloud.google.com/appengine/pricing#flexible-environment) · [Firestore](https://cloud.google.com/firestore/pricing) · [BigQuery](https://cloud.google.com/bigquery/pricing) · [Stape.io](https://stape.io/pricing)



## License

This project is open-source and distributed under the **Apache License 2.0**.

See the [LICENSE](LICENSE) file for the full license text.

#

[Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_readme) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
