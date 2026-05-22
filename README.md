# Nameless Analytics
## Build your own Data Warehouse Analytics platform

A privacy-first digital analytics platform for power users, based on [Google Tag Manager](https://marketingplatform.google.com/intl/it/about/tag-manager/), [Google Firestore](https://cloud.google.com/firestore) and [Google BigQuery](https://cloud.google.com/bigquery).


Collect, analyze, and activate website interaction data with a free real-time digital analytics suite that respects user privacy.

### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change



## Start from here

- [What is Nameless Analytics](#what-is-nameless-analytics)
- [Quick Start](#quick-start)
- [Overview](#overview)
  - [Quick Start](#quick-start)
  - [Documentation](#documentation)
  - [Resources](#resources)
- [Client-Side Collection](#client-side-collection)
  - [Request payload data](#request-payload-data)
  - [ID Management](#id-management)
  - [Sequential Execution Queue](#sequential-execution-queue)
  - [Smart Consent Management](#smart-consent-management)
  - [SPA & History Management](#spa-history-management)
  - [Core Libraries Functioning](#core-libraries-functioning)
  - [Cross-domain Architecture](#cross-domain-architecture)
  - [Parameter hierarchy](#parameter-hierarchy)
  - [Debugging events](#debugging-events)
- [Server-Side Processing](#server-side-processing)
  - [Security and Validation](#security-and-validation)
  - [Transparency](#transparency)
  - [ID Management](#id-management-1)
  - [Data Integrity](#data-integrity)
  - [Real-time Forwarding](#real-time-forwarding)
  - [Self-Monitoring & Performance](#self-monitoring-performance)
  - [Bot protection](#bot-protection)
  - [Geolocation & Privacy by Design](#geolocation-privacy-by-design)
  - [Channel Grouping logic](#channel-grouping-logic)
  - [Cookies](#cookies)
  - [Streaming Protocol](#streaming-protocol)
  - [Debugging requests](#debugging-requests)
- [Storage](#storage)
  - [Firestore as Last updated Snapshot](#firestore-as-last-updated-snapshot)
  - [BigQuery as Historical Timeline](#bigquery-as-historical-timeline)
- [Reporting](#reporting)
- [AI support](#ai-support)
  - [Q&A Agents](#qa-agents)
  - [Conversational Analysis Agent in BigQuery Studio](#conversational-analysis-agent-in-bigquery-studio)
- [Google Cloud costs](#google-cloud-costs)
  - [Data processing](#data-processing)
  - [Data storage](#data-storage)
  - [Data Governance & Deletion](#data-governance-deletion)
  - [Cost Summary Table](#cost-summary-table)

## What is Nameless Analytics
Nameless Analytics is a privacy-first, first-party data collection infrastructure designed for organizations and analysts that demand complete control over their digital analytics. 

(Don't) read the [manifesto](MANIFESTO.md).

Built upon a transparent pipeline hosted entirely on a private Google Cloud Platform environment, the platform solves critical challenges in modern analytics:

1.  **Total Data Ownership**: Unlike commercial tools where data resides on third-party servers, Nameless Analytics pipelines every interaction directly to a private BigQuery warehouse. This ensures ownership of raw data, retention policies, and reporting.
2.  **Data Quality**: By leveraging a server-side, first-party architecture, the platform reduces the impact of common client-side restrictions (such as ad blockers and ITP), ensuring granular, unsampled data collection that is far more accurate than standard client-side tracking.
3.  **Real-Time Activation**: Identical event payloads can be streamed to external APIs, CRMs, or marketing automation tools the instant an event occurs, enabling real-time personalization.
4.  **Scaling and Cost-Efficiency**: Engineered to run effectively within the **Google Cloud Free Tier** for small to medium traffic, while scaling to a highly cost-efficient pay-per-use model for enterprise-grade deployments.



## Overview
The following diagram illustrates the real-time data flow from the user's browser, through the server-side processing layer, to the final storage and visualization destinations:

![Nameless Analytics schema](https://github.com/user-attachments/assets/e9ff1593-f7c9-442e-a600-798a51a02a1e)

## Quick Start
Before starting, ensure you have the following resources under the same account or service account:
- A Client-side Google Tag Manager container
- A Server-side Google Tag Manager container running on:
  - [App Engine](https://www.simoahava.com/analytics/provision-server-side-tagging-application-manually/) (thanks to [Simo Ahava](https://www.simoahava.com/))
  - or [Cloud run](https://www.simoahava.com/analytics/cloud-run-server-side-tagging-google-tag-manager/) with `X-Gclb-Country` and `X-Gclb-Region` headers configured (thanks to [Simo Ahava](https://www.simoahava.com/))
  - or [Stape](https://stape.io) with geo headers power up enabled
- A Google Cloud Project with an active billing account
- A Google BigQuery project + dataset, raw tables and table functions created using the provided [SQL scripts](tables/TABLES.md)
- A Google Firestore database enabled in Native Mode

Download and import the .tpl files from the repos:
- [Client-side Tracker Tag](https://github.com/nameless-analytics/client-side-tracker-tag)
- [Client-side Tracker Configuration Variable](https://github.com/nameless-analytics/client-side-tracker-configuration-variable)
- [Server-side Client Tag](https://github.com/nameless-analytics/server-side-client-tag)

Read the [setup guides](setup-guides/SETUP-GUIDES.md) for more details.


### Documentation
- [Setup guides](setup-guides/SETUP-GUIDES.md)
- [Troubleshooting](setup-guides/TROUBLESHOOTING-GUIDE.md)
- [Tables](tables/TABLES.md)
- [Streaming protocol](streaming-protocol/STREAMING-PROTOCOL.md)


### Resources
- [Live Demo](https://namelessanalytics.com) (Open the dev console).
- [Changelog](CHANGELOG.md)
- [Roadmap](ROADMAP.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Manifesto](MANIFESTO.md)



## Client-Side Collection
The **Client-Side Tracker Tag** abstracts complex logic to ensure reliable data capture under any condition.


### Request payload data
The request data is sent via a POST request in JSON format. It is structured into several logical objects: `user_data`, `session_data`, `page_data`, `event_data`, `consent_data`, and `gtm_data`.

<details><summary>Example of the final enriched payload as processed and returned by the server (standard parameters only)</summary>

</br>

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
    "user_campaign_content": null,
    "user_campaign_term": null,
    "user_device_type": "desktop",
    "user_country": "IT",
    "user_city": "venice",
    "user_language": "it-IT",
    "user_first_session_timestamp": 1764955391487,
    "user_last_session_timestamp": 1768661707758
  },
  "session_date": "2026-01-20",
  "session_id": "lZc919IBsqlhHks_1KMIqneQ7dsDJU",
  "session_data": {
    "session_number": 2,
    "cross_domain_session": "No",
    "session_channel_grouping": "gtm_debugger",
    "session_source": "tagassistant.google.com",
    "session_tld_source": "google.com",
    "session_campaign": null,
    "session_campaign_id": null,
    "session_campaign_click_id": null,
    "session_campaign_content": null,
    "session_campaign_term": null,
    "session_device_type": "desktop",
    "session_country": "IT",
    "session_city": "venice",
    "session_language": "it-IT",
    "session_hostname": "tommasomoretti.com",
    "session_browser_name": "Chrome",
    "session_landing_page_category": "Homepage",
    "session_landing_page_location": "/",
    "session_landing_page_title": "Tommaso Moretti | Freelance digital data analyst",
    "session_exit_page_category": "Homepage",
    "session_exit_page_location": "/",
    "session_exit_page_title": "Tommaso Moretti | Freelance digital data analyst",
    "session_start_timestamp": 1768661707758,
    "session_end_timestamp": 1768661707758
  },
  "page_date": "2026-01-20",
  "page_id": "lZc919IBsqlhHks_1KMIqneQ7dsDJU-WVTWEorF69ZEk3y",
  "page_data": {
    "page_title": "Tommaso Moretti | Freelance digital data analyst",
    "page_hostname_protocol": "https",
    "page_hostname": "tommasomoretti.com",
    "page_location": "/",
    "page_fragment": null,
    "page_query": "gtm_debug=1765021707758",
    "page_extension": null,
    "page_referrer": "https://tagassistant.google.com/",
    "page_timestamp": 1768661707758,
    "page_category": "Homepage",
    "page_language": "it"
  },
  "event_date": "2026-01-20",
  "event_timestamp": 1768661707758,
  "event_id": "lZc919IBsqlhHks_1KMIqneQ7dsDJU-WVTWEorF69ZEk3y_XIkjlUOkXKn99IV",
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
    "tld_source": "google.com"
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
| user_date          |                               | String   | Server-Side | User data collection date                     |
| client_id          |                               | String   | Server-Side | Unique client identifier                      |
| user_data          | user_channel_grouping         | String   | Server-Side | User channel grouping                         |
|                    | user_source                   | String   | Server-Side | User source                                   |
|                    | user_tld_source               | String   | Server-Side | User top-level domain source                  |
|                    | user_campaign                 | String   | Server-Side | User campaign name                            |
|                    | user_campaign_id              | String   | Server-Side | User campaign ID                              |
|                    | user_campaign_click_id        | String   | Server-Side | User campaign click identifier                |
|                    | user_campaign_content         | String   | Server-Side | User campaign content                         |
|                    | user_campaign_term            | String   | Server-Side | User campaign term                            |
|                    | user_device_type              | String   | Server-Side | User device type                              |
|                    | user_city                     | String   | Server-Side | User city                                     |
|                    | user_country                  | String   | Server-Side | User country                                  |
|                    | user_language                 | String   | Server-Side | User language                                 |
|                    | user_first_session_timestamp  | Integer  | Server-Side | Timestamp of user's first session             |
|                    | user_last_session_timestamp   | Integer  | Server-Side | Timestamp of user's last session              |
| session_date       |                               | String   | Server-Side | Session date                                  |
| session_id         |                               | String   | Server-Side | Unique session identifier                     |
| session_data       | session_number                | Integer  | Server-Side | Session number for the user                   |
|                    | cross_domain_session          | String   | Server-Side | Indicates if the session is cross-domain      |
|                    | session_channel_grouping      | String   | Server-Side | Channel grouping for the session              |
|                    | session_source                | String   | Server-Side | Session source                                |
|                    | session_tld_source            | String   | Server-Side | Session top-level domain source               |
|                    | session_campaign              | String   | Server-Side | Session campaign name                         |
|                    | session_campaign_id           | String   | Server-Side | Session campaign ID                           |
|                    | session_campaign_click_id     | String   | Server-Side | Session campaign click ID                     |
|                    | session_campaign_term         | String   | Server-Side | Session campaign term                         |
|                    | session_campaign_content      | String   | Server-Side | Session campaign content                      |
|                    | session_device_type           | String   | Server-Side | Device type used in session                   |
|                    | session_country               | String   | Server-Side | Session country                               |
|                    | session_language              | String   | Server-Side | Session language                              |
|                    | session_hostname              | String   | Server-Side | Website hostname for session                  |
|                    | session_browser_name          | String   | Server-Side | Browser name used in session                  |
|                    | session_landing_page_category | String   | Server-Side | Landing page category                         |
|                    | session_landing_page_location | String   | Server-Side | Landing page path                             |
|                    | session_landing_page_title    | String   | Server-Side | Landing page title                            |
|                    | session_city                  | String   | Server-Side | Session geolocation city                      |
|                    | session_exit_page_category    | String   | Server-Side | Exit page category                            |
|                    | session_exit_page_location    | String   | Server-Side | Exit page path                                |
|                    | session_exit_page_title       | String   | Server-Side | Exit page title                               |
|                    | session_start_timestamp       | Integer  | Server-Side | Session start timestamp                       |
|                    | session_end_timestamp         | Integer  | Server-Side | Session end timestamp                         |
|                    | user_id                       | String   | Client-Side | Unique user identifier (if logged in)         |
| page_date          |                               | String   | Client-Side | Page data date                                |
| page_id            |                               | String   | Client-Side | Unique page identifier                        |
| page_data          | page_title                    | String   | Client-Side | Page title                                    |
|                    | page_hostname_protocol        | String   | Client-Side | Page hostname protocol (http/https)           |
|                    | page_hostname                 | String   | Client-Side | Page hostname                                 |
|                    | page_location                 | String   | Client-Side | Page path                                     |
|                    | page_fragment                 | String   | Client-Side | URL fragment                                  |
|                    | page_query                    | String   | Client-Side | URL query string                              |
|                    | page_extension                | String   | Client-Side | Page file extension                           |
|                    | page_referrer                 | String   | Client-Side | Referrer URL                                  |
|                    | page_timestamp                | Integer  | Client-Side | Page view timestamp                           |
|                    | page_category                 | String   | Client-Side | Page category                                 |
|                    | page_language                 | String   | Client-Side | Page language                                 |
| event_date         |                               | String   | Client-Side | Event date                                    |
| event_timestamp    |                               | Integer  | Client-Side | Event timestamp                               |
| event_id           |                               | String   | Client-Side | Unique event identifier                       |
| event_name         |                               | String   | Client-Side | Event name                                    |
| event_origin       |                               | String   | Client-Side | Event origin (Website or Streaming protocol)  |
| event_data         | event_type                    | String   | Client-Side | Event classification (automatically set to `page_view` or `event`) |
|                    | channel_grouping              | String   | Server-Side | Channel grouping for the event (see [detailed logic](#channel-grouping-logic)) |
|                    | source                        | String   | Client-Side | Event traffic source                          |
|                    | campaign                      | String   | Client-Side | Event campaign                                |
|                    | campaign_id                   | String   | Client-Side | Event campaign ID                             |
|                    | campaign_click_id             | String   | Client-Side | Event campaign click ID                       |
|                    | campaign_term                 | String   | Client-Side | Event campaign term                           |
|                    | campaign_content              | String   | Client-Side | Event campaign content                        |
|                    | user_agent                    | String   | Client-Side | Browser user agent string                     |
|                    | browser_name                  | String   | Client-Side | Browser name                                  |
|                    | browser_language              | String   | Client-Side | Browser language                              |
|                    | browser_version               | String   | Client-Side | Browser version                               |
|                    | device_type                   | String   | Client-Side | Device type                                   |
|                    | device_vendor                 | String   | Client-Side | Device manufacturer                           |
|                    | device_model                  | String   | Client-Side | Device model                                  |
|                    | os_name                       | String   | Client-Side | Operating system name                         |
|                    | os_version                    | String   | Client-Side | Operating system version                      |
|                    | screen_size                   | String   | Client-Side | Screen resolution                             |
|                    | viewport_size                 | String   | Client-Side | Browser viewport size                         |
|                    | country                       | String   | Server-Side | Event geolocation country                     |
|                    | city                          | String   | Server-Side | Event geolocation city                        |
|                    | tld_source                    | String   | Client-Side | Event top-level domain source                 |
| consent_data       | consent_type                  | String   | Client-Side | Consent update type                           |
|                    | respect_consent_mode          | String   | Client-Side | Whether Consent Mode is respected             |
|                    | ad_user_data                  | String   | Client-Side | Ad user data consent                          |
|                    | ad_personalization            | String   | Client-Side | Ad personalization consent                    |
|                    | ad_storage                    | String   | Client-Side | Ad storage consent                            |
|                    | analytics_storage             | String   | Client-Side | Analytics storage consent                     |
|                    | functionality_storage         | String   | Client-Side | Functionality storage consent                 |
|                    | personalization_storage       | String   | Client-Side | Personalization storage consent               |
|                    | security_storage              | String   | Client-Side | Security storage consent                      |
| gtm_data           | cs_hostname                   | String   | Client-Side | Client-side container hostname                |
|                    | cs_container_id               | String   | Client-Side | Client-side container ID                      |
|                    | cs_tag_name                   | String   | Client-Side | Client-side tag name                          |
|                    | cs_tag_id                     | Integer  | Client-Side | Client-side tag ID                            |
|                    | ss_hostname                   | String   | Server-Side | Server-side container hostname                |
|                    | ss_container_id               | String   | Server-Side | Server-side container ID                      |
|                    | ss_tag_name                   | String   | Server-Side | Server-side tag name                          |
|                    | ss_tag_id                     | Integer  | Server-Side | Server-side tag ID                            |
|                    | processing_event_timestamp    | Integer  | Server-Side | Event processing timestamp                    |
|                    | content_length                | Integer  | Server-Side | Request content length                        |
</details>

<details><summary>Request payload additional data parameters</summary>

#### Page status code
When the "Add page status code" option is enabled, a `page_status_code` parameter will be added to the page_data object in the payload: 
  
| **Parameter name** | **Sub-parameter** | **Type** | **Added**   | **Field description** |
|--------------------|-------------------|----------|-------------|-----------------------|
| page_status_code   |                   | Integer  | Client-Side | Page status code      | 
  
#### Add dataLayer data
When the "Add current dataLayer state" option is enabled, a `dataLayer` parameter will be added to the payload: 
  
| **Parameter name** | **Sub-parameter** | **Type** | **Added**   | **Field description** |
|--------------------|-------------------|----------|-------------|-----------------------|
| dataLayer          |                   | JSON     | Client-Side | DataLayer data        |
    
#### Ecommerce data
When "Add ecommerce data" is enabled, an `ecommerce` parameter will be added to the payload:
  
| **Parameter name** | **Sub-parameter** | **Type** | **Added**   | **Field description** |
|--------------------|-------------------|----------|-------------|-----------------------|
| ecommerce          |                   | JSON     | Client-Side | Ecommerce data        |
    
#### Cross-domain data
When "Enable cross-domain tracking" is enabled, the `cross_domain_session` and the `cross_domain_id` parameters will be added to the payload in `session_data` and `event_data`   respectively:
  
| **Parameter name** | **Sub-parameter**    | **Type** | **Added**   | **Field description**   |
|--------------------|----------------------|----------|-------------|-------------------------|
| session_data       | cross_domain_session | String   | Server-Side | Is cross domain session |
| event_data         | cross_domain_id      | String   | Client-Side | Cross domain id (populated from `na_id` URL parameter) |
  
</details>


### ID Management
The tracker automatically generates and manages unique identifiers for pages, and events.
  
<details><summary>See page ID and event ID values</summary>

</br>

| Parameter name | Renewed            | Example values                                                 | Value composition                           |
|----------------|--------------------|----------------------------------------------------------------|---------------------------------------------|
| **page_id**    | at every page_view | lZc919IBsqlhHks_1KMIqneQ7dsDJU-WVTWEorF69ZEk3y                 | Client ID _ Session ID - Page ID            |
| **event_id**   | at every event     | lZc919IBsqlhHks_1KMIqneQ7dsDJU-WVTWEorF69ZEk3y_XIkjlUOkXKn99IV | Client ID _ Session ID - Page ID _ Event ID |

</details>


### Sequential Execution Queue
Implements specific logic to handle high-frequency events (e.g., rapid clicks), ensuring requests are dispatched in strict FIFO order to preserve the narrative of the session.


### Smart Consent Management
Fully integrated with Google Consent Mode. Choose between respect or not respect consent mode:
- When Google Consent Mode is present and `respect_consent_mode` is enabled, the events are sent only if a user consents. 
  - `analytics_storage` is equal to `denied`, the Nameless Analytics Client-side Tracker waits until consent is granted. The tag automatically preserves the original acquisition context (source and campaign data and page referrer) using a temporary first-party cookie named `na_temp`. Once consent is granted (even multiple pages later), the tag retrieves the data from the cookie and correctly attributes the session, preventing incorrect "direct" or "internal" referral attribution.    
  - `analytics_storage` changes from `denied` to `granted`, all pending tags for that page will be fired in execution order
- When Google Consent Mode not present and `respect_consent_mode` is enabled, none of the events are sent. 
- When `respect_consent_mode` is disabled, all events are sent regardless of presence of Google Consent Mode.

<details> <summary>See temp cookie value</summary>

</br>

| Cookie Name | Default expiration | Example values | Value composition | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **na_temp** | Session | {<br> &nbsp; &nbsp; "source": "google", <br> &nbsp; &nbsp; "campaign": "summer_sale", <br> &nbsp; &nbsp; "campaign_id": "12345", <br> &nbsp; &nbsp; "campaign_click_id": "67890", <br> &nbsp; &nbsp; "campaign_content": "ad_group_1", <br> &nbsp; &nbsp; "campaign_term": "running_shoes", <br> &nbsp; &nbsp; "page_referrer": "https://www.google.com/" <br>}| JSON object of acquisition parameters | Temporarily stores acquisition parameters when `analytics_storage` is denied. |

This is the lifecycle of `na_temp` cookie: 
- **Session Expiration**: `na_temp` is a standard session cookie. Unlike persistent cookies, it lives exclusively in the browser's temporary memory and is never written to the user's hard drive. It expires and is automatically deleted by the browser as soon as the **entire browser process is closed** (closing only a single tab or window will not delete the cookie). This ensures attribution remains consistent even if the user navigates your site across multiple tabs.
- **Conditional Deletion**: the cookie is not deleted immediately upon consent grant. Instead, it is forcefully removed during the **first `page_view` event (standard or virtual) that occurs while `analytics_storage` is already set to granted**. This ensures that if consent is granted mid-page, the original acquisition data remains available to attribute all subsequent events on that page before being purged on the next page transition.

</details>


### SPA & History Management
Native support for Single Page Applications. See the [Page View Setup Guide](setup-guides/SETUP-GUIDES.md#how-to-track-page-views) for implementation examples.


### Core Libraries Functioning
The tracker relies on a main external library and a dependency library loaded by Nameless Analytics Client-side Tracker Tag.

To maximize data collection accuracy, Nameless Analytics supports **First-Party mode**, allowing you to host this library on your own domain or CDN instead of using external CDNs.

<details><summary>Main library</summary>

</br>

This is the core engine that supports the GTM tag by exposing utility functions for execution in a standard JavaScript environment. Source code: [nameless-analytics.js](https://github.com/nameless-analytics/client-side-tracker-tag/blob/main/lib/nameless-analytics.js)

It handles the following background operations:

- **Payload Enrichment:** Formats timestamps into BigQuery-compatible date strings and captures browser environment metrics like screen resolution and viewport size.
- **Sequential Requests Queue:** Implements a Promise-based queue to ensure that HTTP requests are sent in the exact order they occurred (FIFO), preserving the timeline of user interactions.
- **Cross-domain Handshake:** Manages a global click listener that detects cross-domain links. It triggers a server-side "handshake" via the `get_user_data` function to retrieve the visitor's server-side identities before redirecting and decorating outbound URLs with the `na_id` parameter.
- **Server Identity Retrieval (`get_user_data`):** A dedicated function that performs an asynchronous POST request to the Server-Side Client Tag to fetch the active `client_id` and `session_id`. This ensures that cross-domain tracking uses the authoritative IDs issued by the server.
- **Consent State Mapping:** Provides a function to read the current state of all Google Consent Mode types directly from the global GTM data object.

</details>

<details><summary>Dependency library</summary>

</br>

Parses the browser's `User-Agent` string and extracts granular information about the device vendor, model, operating system, and browser engine version. Source code: [ua-parser.min.js](https://github.com/faisalman/ua-parser-js)

This data is mapped into the `event_data` object under `device_vendor`, `os_version`, `device_model`, etc.

</details>


### Cross-domain Architecture
Nameless Analytics uses `HttpOnly` cookies for security, identifiers are invisible to client-side JavaScript and cannot be read directly to decorate links. 

For retrieving the active `client_id` and `session_id` the Nameless Analytics Client-Side Tracker Tag needs to perform a handshake with the server before redirecting and decorating outbound URLs with the `na_id` parameter in real time.

Since link decoration happens dynamically upon clicking, cross-domain tracking **will not work** if the user opens the link via right-click menu like "Open link in new tab".

<details><summary>How the cross-domain handshake works</summary>

</br>

- When `respect_consent_mode` is disabled or `respect_consent_mode` is enable and `analytics_storage` = granted:
  - **Handshake Initialization**: When a user clicks a link toward a configured cross-domain, the tracker intercepts the event, **pauses navigation**, and performs a real-time asynchronous POST call to the Server-side GTM endpoint with `event_name: 'get_user_data'`.
  - **Identity Extraction (`HttpOnly` bypass)**: The Server-side Client Tag receives the request. Since the call is directed to its own domain, it has access to the `HttpOnly` cookies (`na_u` and `na_s`). It securely extracts the `client_id` and `session_id`.
  - **Real-time Response**: Instead of streaming the data to BigQuery, the server immediately responds to the browser by providing both identifiers in a JSON payload. 
  - **URL Decoration**: The tracker receives the response and decorates the destination URL with the session ID value (e.g., `https://destination.com/?na_id={session_id}`) before allowing the redirect to proceed.
  - **Session Stitching**: On the destination domain, the tracker detects the `na_id` parameter and sends it to its own server. If identifying parameters are missing but `na_*` acquisition parameters are present, it instead initializes a local `na_temp` cookie to preserve attribution context.
  
  By intercepting the link click to perform a real-time server-side identity check, Nameless Analytics ensures that the identifiers passed to the destination domain are 100% correct. 

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

System-critical parameters like `client_id`, `session_id`, `page_id` and `event_id` and the standard parameters are protected and cannot be overwritten in any ways.

User, session, and event parameters follow this hierarchy of overriding:

<details><summary>See user and sessions parameters hierarchy</summary>

</br>

| **Priority** | **Level**                           | **Source**                                                    |
|--------------|-------------------------------------|---------------------------------------------------------------|
| **High**     | User and sessions parameters        | Nameless Analytics Server-side Client Tag                     |
| **Low**      | Shared user and sessions parameters | Nameless Analytics Client-side Tracker Configuration Variable |

</details>

<details> <summary>See event parameters hierarchy</summary>

</br>

| **Priority** | **Level**                  | **Source**                                                    |
|--------------|----------------------------|---------------------------------------------------------------|
| **4 (High)** | Event parameters           | Nameless Analytics Server-side Client Tag                     |
| **3**        | Event parameters           | Nameless Analytics Client-side Tracker Tag                    |
| **2**        | Shared event parameters    | Nameless Analytics Client-side Tracker Configuration Variable |
| **1 (Low)**  | dataLayer event parameters | Nameless Analytics Client-side Tracker Tag                    |

</details>


### Debugging events
Real-time tracker logs and errors are logged to the **Browser Console**, ensuring immediate feedback during implementation. 

For a detailed guide on resolving common sequence and integration issues, see the [Troubleshooting Guide](setup-guides/TROUBLESHOOTING-GUIDE.md).



## Server-Side Processing
The **Server-Side Client Tag** sits between the public internet and your cloud infrastructure, verifying, claiming or rejecting every request.


### Security and Validation
Validates request origins and authorized domains (CORS) before processing to prevent unauthorized usage.


### Transparency
The data processed by the server is returned to the client within the request response. This provides full visibility into the collected information, allowing for real-time verification and ensuring the entire data pipeline remains transparent and auditable directly from the browser's network tab.


### ID Management
The Nameless Analytics Server-side Client Tag automatically generates and manages unique identifiers for users and sessions.

<details><summary>See client ID and session ID values</summary>

</br>

| Parameter name | Renewed                       | Example values                 | Value composition             |
|----------------|-------------------------------|--------------------------------|-------------------------------|
| **client_id**  | when `na_u` cookie is created | lZc919IBsqlhHks                | Client ID                     |
| **session_id** | when `na_s` cookie is created | lZc919IBsqlhHks_1KMIqneQ7dsDJU | Client ID _ Random Session ID |

</details>


### Data Integrity
The server will reject any interaction (e.g., click, scroll) with a `403 Forbidden` status if it hasn't been preceded by a valid `page_view` event for that session. This ensures every session in BigQuery has a clear starting point and reliable attribution.


### Real-time Forwarding
Supports instantaneous data streaming to external HTTP endpoints immediately after processing. The system allows for **custom HTTP headers** injection, enabling secure authentication with third-party services endpoints directly from the server.


### Self-Monitoring & Performance
The system transparently tracks pipeline health by measuring **ingestion latency** (the exact millisecond delay between the client hit and server processing) and **payload size**. This data allows for high-resolution monitoring of the real-time data flow directly within BigQuery.


### Bot protection
Actively detects and blocks automated traffic returning a `403 Forbidden` status. The system filters requests based on a predefined blacklist of 45 User-Agent strings.

<details><summary>See bot protection list</summary>

#### AI Agents & LLMs 
`gptbot`, `chatgpt`, `anthropic`, `claude`, `perplexity`, `bytspider`, `ccbot`.

#### SEO & Marketing Bots 
`ahrefs`, `semrush`, `dotbot`, `mj12`, `rogerbot`, `bot`, `crawler`, `spider`, `scraper`.

#### HTTP Libraries 
`curl`, `wget`, `python`, `requests`, `httpie`, `go-http-client`, `java`, `okhttp`, `libwww`, `perl`, `axios`, `node`, `fetch`, `php`, `guzzle`, `ruby`, `faraday`, `rest-client`.

#### Automation & Security 
`nmap`, `zgrab`, `masscan`, `shodan`, `headless`, `phantomjs`, `selenium`, `puppeteer`, `playwright`, `cypress`, `electron`.
</details>


### Geolocation & Privacy by Design
Automatically maps the incoming request IP to geographic data (Country, City) for regional analysis. The system is designed to **never persist the raw IP address** in BigQuery, ensuring native compliance with strict privacy regulations. 

To enable this feature, your server must be configured to forward geolocation headers. The platform natively supports **Google App Engine** (via `X-Appengine` headers) and **Google Cloud Run** (via `X-Gclb` headers). For Cloud Run, ensure the Load Balancer is [properly configured](https://www.simoahava.com/analytics/cloud-run-server-side-tagging-google-tag-manager/#add-geolocation-headers-to-the-traffic) (thanks to [Simo Ahava](https://www.simoahava.com/) for helping us again).


### Channel Grouping logic
Automatically categorizes traffic sources into predefined groups (e.g., Organic Search, Paid Social, AI, Email) using a server-side regex-based pattern matching system. 

The Server-side Client Tag automatically processes attribution data for every incoming request. By analyzing the `source` and `campaign` parameters, it applies a regex-based logic to categorize the traffic into standard groups (e.g., Organic Search, Paid Social, Email, etc.).

This centralized processing ensures that:
- **Consistency**: All events within a session share the same attribution logic, regardless of the source (Website or Streaming Protocol).
- **Maintenance**: Updates to channel definitions only need to be applied once at the server level.

<details><summary>See channel grouping rules</summary>

The following table describes how the channel grouping is determined based on the `source` and `campaign` parameters of the event. 

| Channel grouping | Source category | Campaign |
| :--- | :--- | :--- |
| `direct` | **Direct** | Any |
| `gtm_debugger` | **GTM Debugger** | Any |
| `paid_search_engine` | **Search Engine** | Yes |
| `organic_search_engine` | **Search Engine** | No |
| `paid_social` | **Social** | Yes |
| `organic_social` | **Social** | No |
| `paid_shopping` | **Shopping** | Yes |
| `organic_shopping` | **Shopping** | No |
| `paid_video` | **Video** | Yes |
| `organic_video` | **Video** | No |
| `ai` | **AI** | Yes |
| `email` | **Email** | Yes |
| `referral` | None of the above | No |
| `affiliate` | None of the above | Yes |

The channel grouping logic uses the following Source categories based on the source name:

| Source category | Source |
| :--- | :--- |
| **Direct** | `null`, `direct` |
| **GTM Debugger** | `tagassistant.google.com` |
| **Search Engine** | `360.cn`, `alice`, `aol`, `yahoo`, `ask`, `bing`, `google`, `yandex`, `baidu`, `ecosia`, `duckduckgo`, `sogou`, `naver`, `seznam` |
| **Social** | `facebook`, `twitter`, `instagram`, `pinterest`, `linkedin`, `reddit`, `vk.com`, `tiktok`, `snapchat`, `tumblr`, `wechat`, `whatsapp` |
| **Shopping** | `amazon`, `ebay`, `etsy`, `shopify`, `stripe`, `walmart`, `mercadolibre`, `alibaba`, `naver.shopping` |
| **Video** | `youtube`, `vimeo`, `netflix`, `twitch`, `dailymotion`, `hulu`, `disneyplus`, `wistia`, `youku` |
| **AI** | `chatgpt`, `gemini`, `bard`, `claude`, `alexa`, `siri`, `assistant`, `ai` |
| **Email** | `email`, `e-mail`, `newsletter`, `mailchimp`, `sendgrid`, `sparkpost` |

</details>


### Cookies
All cookies are issued with `HttpOnly`, `Secure`, and `SameSite=Strict` flags. This multi-layered approach prevents client-side access (XSS protection) and Cross-Site Request Forgery (CSRF).

The platform automatically calculates the appropriate cookie domain by extracting the **Effective TLD+1** from the request origin. This ensures seamless identity persistence across subdomains without manual configuration. 

Cookies are created or updated on every event to track the user's session and identity across the entire journey. The expiration of the client identifier cookie (`na_u`) is set to **400 days**, which is the maximum lifespan allowed by modern browsers (e.g., Chrome, Safari) for first-party cookies, ensuring long-term user recognition while remaining compliant with browser restrictions.

<details> <summary>See user and session cookie values</summary>

</br>

| Cookie Name | Default expiration | Example values | Value composition | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **na_u**    | 400 days           | lZc919IBsqlhHks                                | Client ID                             | Used as client_id |
| **na_s**    | 30 minutes         | lZc919IBsqlhHks_1KMIqneQ7dsDJU-WVTWEorF69ZEk3y | Client ID _ Session ID - Last Page ID | Used as session_id and to retrieve the current page_id for the **Streaming Protocol** requests. |

</details>


### Streaming Protocol
The Streaming Protocol is specifically designed for server-to-server communication, allowing you to send events directly from your backend or other offline sources.

Use the Streaming Protocol to:
- Attribute realtime events to a session by sending data from your backend when a purchase or subscription is completed.
- Attribute offline events to a session by sending data from your backend days after a session ended.

To protect against unauthorized data injection from external servers, the system supports an optional **API Key authentication** for the Streaming protocol.

The Server-Side Client Tag will automatically reject any request where `event_origin` is not set to "Streaming protocol" and does not include a valid `x-api-key` header matching your configuration.


### Debugging requests
Developers can monitor the server-side logic in real-time through **GTM Server Preview Mode**. 

For detailed information on server-side errors and validation issues, refer to the [Troubleshooting Guide](setup-guides/TROUBLESHOOTING-GUIDE.md).

## Storage
Nameless Analytics employs a complementary storage strategy to balance real-time intelligence with deep historical analysis:


### Firestore as Last updated Snapshot
It maintains **the latest available state for every user and session** (for example, a custom `user_level` parameter).

- **User data**: Stores the latest user profile state, including first/last session timestamps, original acquisition source, and persistent device metadata.
- **Session data**: Stores the latest session state, including real-time counters (total events, page views), landing/exit page details, and session-specific attribution.

<details><summary>Firestore document structure example</summary>

</br>

![Nameless Analytics - Firestore collection schema](https://github.com/user-attachments/assets/d27c3ca6-f039-4702-853e-81e71ed033c2)

Firestore ensures data integrity by managing how parameters are updated across hits:

| Scope | Type | Parameters | Logic |
| :--- | :--- | :--- | :--- |
| **User** | **First-Touch** | `user_date`, `user_source`, `user_tld_source`, `user_campaign`, `user_campaign_id`, `user_campaign_click_id`, `user_campaign_term`, `user_campaign_content`, `user_channel_grouping`, `user_device_type`, `user_country`, `user_language`,   `user_first_session_timestamp` | Recorded at first visit, **never overwritten**. |
| **User** | **Last-Touch** | `user_last_session_timestamp` | Updated at the start of every new session. |
| **Session** | **First-Touch** | `session_date`, `session_number`, `session_start_timestamp`, `session_source`, `session_tld_source`, `session_campaign`, `session_campaign_id`, `session_campaign_click_id`, `session_campaign_term`, `session_campaign_content`,   `session_channel_grouping`, `session_device_type`, `session_country`, `session_language`, `session_hostname`, `session_browser_name`, `session_landing_page_category`, `session_landing_page_location`, `session_landing_page_title`, `user_id` | Set at session start, persists throughout   the session. |
| **Session** | **Last-Touch** | `session_exit_page_category`, `session_exit_page_location`, `session_exit_page_title`, `session_end_timestamp` | **Updated on every hit** to reflect the latest state. |
| **Session** | **Progressive** | `cross_domain_session` | Flags as 'Yes' if any hit in the session is cross-domain. |

</details>
  

### BigQuery as Historical Timeline
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
  
</br>
  
![Nameless Analytics - BigQuery event_raw schema](https://github.com/user-attachments/assets/d23e3959-ab7a-453c-88db-a4bc2c7b32f4)
  
</details>



## Reporting
Nameless Analytics offers a set of BigQuery [SQL Table Functions](tables/TABLES.md) to query and explore the raw data at:
- [User level](tables/users.sql) - [View schema](tables/TABLES.md#users)
- [Session level](tables/sessions.sql) - [View schema](tables/TABLES.md#sessions)
- [Page level](tables/pages.sql) - [View schema](tables/TABLES.md#pages)
- [Event level](tables/events.sql) - [View schema](tables/TABLES.md#events)
- [Ecommerce Transaction level](tables/ec_transactions.sql) - [View schema](tables/TABLES.md#transactions)
- [Ecommerce Product level](tables/ec_products.sql) - [View schema](tables/TABLES.md#products)
- [Ecommerce Funnel](tables/sql/ec_funnel.sql) - [View schema](tables/TABLES.md#ecommerce-funnel)
- [Ecommerce Funnel Pivot](tables/sql/ec_funnel_pivot.sql) - [View schema](tables/TABLES.md#ecommerce-funnel-pivot)
- [Session Consent level](tables/consents.sql) - [View schema](tables/TABLES.md#consents)

This is a reporting example made in Looker Studio based on the SQL functions above: [Link](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_ebkun2sknd).


## AI support
### Q&A Agents
Get expert help for implementation and technical documentation: 

- **[Nameless Analytics QnA](https://notebooklm.google.com/notebook/73cd9ce3-9873-40cf-9d52-110d74dff5f9)**: Specialized Google Notebook LM trained on the platform docs.


### Conversational Analysis Agent in BigQuery Studio
In BigQuery Studio, it is possible to configure a Data Agent (powered by Gemini) for conversational analysis, allowing users to explore and query datasets using simple natural language. These agents leverage tables, views, and **table functions** as "knowledge sources" to learn the data schema and business logic. 

Table functions are particularly strategic in this scenario: by accepting parameters, they allow encapsulating and centralizing complex metrics and business logic, providing the agent with a clean and reusable interface to filter results dynamically. 

To maximize the accuracy of the agent's responses, it is crucial to enrich these sources with well-defined metadata descriptions at the schema level, provide contextual system instructions, and include a set of "golden queries" to train the model on the organization's specific use cases. To learn how to configure this agent with your data, check the [Setup Guide](setup-guides/SETUP-GUIDES.md#how-to-configure-a-conversational-analysis-agent-in-bigquery-studio).



## Google Cloud costs
Nameless Analytics is designed to achieve maximum performance with minimum overhead. By utilizing Google Cloud's serverless offerings, the platform can operate at **near-zero cost** for many users and scales predictably with traffic.


### Data processing
You can choose the compute environment that best fits your traffic and budget:

* **Cloud Run (Recommended)**: The most modern and cost-effective choice. It scales to zero when there's no traffic. The Google Cloud "Always Free" tier includes **2 million requests per month**, which covers most small-to-medium websites at no charge.
* **App Engine Standard**: Ideal for 24/7 uptime on a budget. Includes **28 free instance-hours per day** (F1 instances), allowing for a continuous single-server setup at **no cost**.
* **App Engine Flexible**: Best for enterprise-scale deployments (5-10M+ hits/month) requiring multi-zone redundancy. Typically starts at ~$120/month for a 3-instance minimum cluster.


### Data storage
Data will be stored in two different locations:

* **Google Firestore**: Manages real-time session states. Billing is based on **document operations** (Reads and Writes). Since every event requires 1 read and 1 write to manage session state, the total cost is approximately **$0.12 per 100,000 events** (Reads: $0.03/100k + Writes: $0.09/100k, excluding the daily free tier).

* **Google BigQuery**: Your long-term historical data warehouse. These estimates include **data storage** (~$0.02/GB) and **streaming ingestion**. Nameless Analytics leverages the **BigQuery Storage Write API**, which includes a **FREE tier of 2 TB per month** for ingestion. This means data ingestion costs are **$0** for all traffic tiers listed below.

Query processing (scanning data in BigQuery for analysis/reporting) is billed separately by Google Cloud based on usage. However, the first **1 TB per month** is always free.

### Data Governance & Deletion
To comply with GDPR and privacy regulations, Nameless Analytics provides a dedicated **[User Data Deletion Script](setup-guides/SETUP-GUIDES.md#data-governance--privacy-compliance)**. 

This Python utility allows you to remove all data for a specific `client_id` from both BigQuery and Firestore in a single operation, ensuring a complete "Right to be Forgotten" implementation.


### Cost Summary Table
This is an estimated monthly cost breakdown for the platform, based on **real-world Google Cloud pricing** and **measured event payload size** (~2.8 KB / event).

**Excluded costs:** BigQuery query processing (1 TB/month free tier)

| Traffic Tier | Monthly Events | Compute (Cloud Run / GAE / Stape) | Firestore Reads / Writes | BigQuery Ingest & Storage | **Estimated Total (Cloud Run / GAE / Stape)** |
|--------------|----------------|-----------------------------------|--------------------------|---------------------------|----------------------------------------|
| **Low** | < 500k | $0 / $0* / $20 | ~$0 | ~$0 | FREE – $20 |
| **Medium** | 1M – 2M | $0 – $1 / $0* / $20 | ~$0.5 – $1.5 | ~$0 | $1 – $3 / $1 – $2 / $21+ |
| **High** | 5M | ~$8 – $12 / $0* / $100 | ~$6 | ~$0.3 | $14 – $18 / $6 – $8 / $106+ |
| **Enterprise** | 10M | ~$20 – $40 / ~$120** / $100 | ~$12 | ~$0.6 | $33 – $53 / $133+ / $113+ |
| **Enterprise+** | 50M | ~$80 – $130 / ~$120** / $200 | ~$60 | ~$2.8 | $143 – $193 / $183+ / $263+ |

</br>

\* App Engine **Standard Environment (F1 instance)** – suitable for low/medium traffic  
\** App Engine **Flexible Environment (multi-instance cluster)** – suitable for high traffic  
\*** Stape.io **Personal ($0), Pro ($20), Business ($100), Enterprise ($200)** plans based on traffic

**Pricing sources** (verified April 2026): [Cloud Run](https://cloud.google.com/run/pricing) · [App Engine Standard](https://cloud.google.com/appengine/pricing#standard_instance_pricing) · [App Engine Flexible](https://cloud.google.com/appengine/pricing#flexible-environment) · [Firestore](https://cloud.google.com/firestore/pricing) · [BigQuery](https://cloud.google.com/bigquery/pricing) · [Stape.io](https://stape.io/pricing)  
**Note on Cloud Run**: cost varies significantly based on vCPU allocation per instance and average request duration. Estimates above assume 0.25 vCPU and ~300ms average processing time. Use the [Google Cloud Pricing Calculator](https://cloud.google.com/products/calculator) for workload-specific projections.

## License

This project is distributed under the **Nameless Analytics Source-Available License 1.0**.

- **Transparency:** The source code is publicly available for inspection and security audits.
- **Usage:** You can freely download, install, and use it for personal, business, or client projects.
- **Modifications:** Distribution of modified versions or public forks of Nameless Analytics is strictly prohibited.

---

Reach me at: [Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_readme) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
