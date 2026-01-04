# Nameless Analytics 

An open-source web analytics platform for power users, based on [Google Tag Manager](https://marketingplatform.google.com/intl/it/about/tag-manager/), [Google Firestore](https://cloud.google.com/firestore) and [Google BigQuery](https://cloud.google.com/bigquery).

Collect, analyze, and activate your website data with a free real-time digital analytics suite that respects user privacy.

</br></br> 



## Start from here
- [What is Nameless Analytics](#what-is-nameless-analytics)
- [Technical Architecture](#technical-architecture)
  - [High-Level Data Flow](#high-level-data-flow)
  - [Client-Side Collection](#client-side-collection)
  - [Server-Side Processing](#server-side-processing)
  - [Storage](#storage)
  - [Reporting](#reporting)
  - [Support & AI](#support--ai)
- [Pricing & Cloud Costs](#pricing--cloud-costs)
- [Quick Start](#quick-start)
  - [Repository structure](#repository-structure)
  - [Project configuration](#project-configuration)
- [External Resources](#external-resources)

</br></br>



## What is Nameless Analytics 
Nameless Analytics is an open-source, first-party data collection infrastructure designed for organizations and analysts that demand complete control over their digital analytics. It's built upon a transparent pipeline that is built entirely on your own Google Cloud Platform environment.

At a high level, the platform solves critical challenges in modern analytics:

1.  **Total Data Ownership**: Unlike commercial tools where data resides on third-party servers, Nameless Analytics pipelines every interaction directly to your BigQuery warehouse. You own the raw data, the retention policies and the reporting.
2.  **Data Quality**: By leveraging a server-side, first-party architecture, the platform bypasses common client-side restrictions (such as ad blockers and ITP), ensuring granular, unsampled data collection that is far more accurate than standard client-side tags.
3.  **Real-Time Activation**: Stream identical event payloads to external APIs, CRMs, or marketing automation tools the instant an event occurs, enabling true real-time personalization.
4.  **Scaling and Cost-Efficiency**: Engineered to run effectively within the **Google Cloud Free Tier** for small to medium traffic, while scaling to a highly cost-efficient pay-per-use model for enterprise-grade deployments.

</br></br>


## Technical Architecture
The platform is built on a modern architecture that separates data capture, processing, and storage to ensure maximum flexibility and performance.

### Components
- Client-side tracker tag: [nameless-analytics-client-side-tracker-tag](https://github.com/nameless-analytics/nameless-analytics-client-side-tracker-tag)
- Client-side tracker configuration variable: [nameless-analytics-client-side-tracker-configuration-variable](https://github.com/nameless-analytics/nameless-analytics-client-side-tracker-configuration-variable)
- Server-side client tag: [nameless-analytics-server-side-client-tag](https://github.com/nameless-analytics/nameless-analytics-server-side-client-tag)
- Reporting tables: [reporting-tables](reporting-tables/)
- GTM default containers: [gtm-containers](gtm-containers/)

</br>


### High-Level Data Flow
The following diagram illustrates the real-time data flow from the user's browser, through the server-side processing layer, to the final storage and visualization destinations:

<img src="https://github.com/user-attachments/assets/ea15a5f1-b456-4d85-a116-42e54c4073cd" alt="Nameless Analytics schema"/>

</br>


### Client-Side Collection
The **Client-Side Tracker** (GTM Web) is the system's intelligent agent in the browser. It abstracts complex logic to ensure reliable data capture under any condition.

#### Sequential Execution Queue
Implements specific logic to handle high-frequency events (e.g., rapid clicks), ensuring requests are dispatched in strict FIFO order to preserve the narrative of the session.

#### Smart Consent Management
Fully integrated with Google Consent Mode. It can track every event or automatically queue events (`analytics_storage` pending) and release them only when consent is granted, preventing data loss.

#### SPA & History Management
Native support for Single Page Applications, automatically detecting history changes to trigger virtual page views.

#### Cross-domain Architecture
Implements a robust "handshake" protocol to stitch sessions across different top-level domains. Since Nameless Analytics uses `HttpOnly` cookies for security, identifiers are invisible to client-side JavaScript and cannot be read directly to decorate links.

<details><summary>How the cross-domain handshake works</summary>

1. **Pre-flight Request**: When a user clicks a link pointing to a configured cross-domain, the tracker intercepts the click and sends a synchronous `get_user_data` request to the Server-side GTM endpoint.
2. **Identity Retrieval**: The server receives the request (along with the `HttpOnly` cookies), extracts the `client_id` and `session_id`, and returns them in the JSON response.
3. **URL Decoration**: The tracker receives the IDs and decorates the outbound destination URL with a `na_id` parameter (e.g., `https://destination.com/?na_id=...`).
4. **Session Stitching**: On the destination site, the tracker detects the `na_id` parameter, sends it to the server, and the server sets the same `HttpOnly` cookies for the new domain, effectively merging the session.

</details>

#### Debugging & Visibility
Real-time tracker logs and errors are sent to the **Browser Console**, ensuring immediate feedback during implementation.

#### ID Management
The tracker automatically generates and manages unique identifiers for pages, and events.

| Cookie Name  | Renewed            | Example values                                                 | Value composition                                |
|--------------|--------------------|----------------------------------------------------------------|--------------------------------------------------|
| **page_id**  | at every page_view | lZc919IBsqlhHks_1KMIqneQ7dsDJU-WVTWEorF69ZEk3y                 | Client ID _ Session ID - Last Page ID            |
| **event_id** | at every event     | lZc919IBsqlhHks_1KMIqneQ7dsDJU-WVTWEorF69ZEk3y_XIkjlUOkXKn99IV | Client ID _ Session ID - Last Page ID _ Event ID |

#### Request payload data
The request data is sent via a POST request in JSON format. It is structured into several logical objects: `user_data`, `session_data`, `page_data`, `event_data`, and metadata like `consent_data` or `gtm_data`.

#### Parameter Hierarchy & Overriding
Since parameters can be set at multiple levels (Variables, Tags, and Server-side logic), Nameless Analytics follows a strict hierarchy of importance. A parameter set at a higher level will always override one with the same name at a lower level.

##### 1. User & Session Parameters
| Priority | Level | Source |
| :--- | :--- | :--- |
| **High** | Server-side | [Server-side Client Tag](https://github.com/nameless-analytics/nameless-analytics-server-side-client-tag) logic |
| **Low** | Client-side | [Configuration Variable](https://github.com/nameless-analytics/nameless-analytics-client-side-tracker-configuration-variable) |

##### 2. Event Parameters
| Priority | Level | Source |
| :--- | :--- | :--- |
| **1 (Max)** | Server-side | [Server-side Client Tag](https://github.com/nameless-analytics/nameless-analytics-server-side-client-tag) override |
| **2** | Client-side Tag | [Specific Event Parameters](https://github.com/nameless-analytics/nameless-analytics-client-side-tracker-tag) |
| **3** | Configuration | [Shared Event Parameters](https://github.com/nameless-analytics/nameless-analytics-client-side-tracker-configuration-variable) |
| **4** | dataLayer | Values captured from the `dataLayer.push()` |
| **5 (Min)** | Native | Standard parameters (e.g., `page_location`, `page_title`) |

> **Note**: System-critical parameters like `page_id`, `event_id`, `client_id`, and `session_id` are protected and cannot be overwritten by custom tags or variables.

<details><summary>Request payload example with only standard parameters and no customization at all</summary>

</br>

```json
{
  "user_date": "2025-12-05",
  "client_id": "lZc919IBsqlhHks",
  "user_data": {
    "user_campaign_id": null,
    "user_country": "IT",
    "user_device_type": "desktop",
    "user_channel_grouping": "gtm_debugger",
    "user_source": "tagassistant.google.com",
    "user_first_session_timestamp": 1764955391487,
    "user_campaign_content": null,
    "user_campaign": null,
    "user_campaign_click_id": null,
    "user_tld_source": "google.com",
    "user_language": "it-IT",
    "user_campaign_term": null,
    "user_last_session_timestamp": 1765022517600
  },
  "session_date": "2025-12-06",
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
    "session_campaign_term": null,
    "session_campaign_content": null,
    "session_device_type": "desktop",
    "session_country": "IT",
    "session_language": "it-IT",
    "session_hostname": "tommasomoretti.com",
    "session_browser_name": "Chrome",
    "session_landing_page_category": "Homepage",
    "session_landing_page_location": "/",
    "session_landing_page_title": "Tommaso Moretti | Freelance digital data analyst",
    "session_exit_page_category": "Homepage",
    "session_exit_page_location": "/",
    "session_exit_page_title": "Tommaso Moretti | Freelance digital data analyst",
    "session_start_timestamp": 1765022517600,
    "session_end_timestamp": 1765023618088
  },
  "page_date": "2025-12-06",
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
    "page_timestamp": 1765023618088,
    "page_category": "Homepage",
    "page_language": "it"
  },
  "event_date": "2025-12-06",
  "event_timestamp": 1765023618088,
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

</br>

| **Parameter name** | **Sub-parameter**             | **Type** | **Added**   | **Field description**                         |
|--------------------|-------------------------------|----------|-------------|-----------------------------------------------|
| user_date          |                               | String   | Server-Side | User data collection date                     |
| client_id          |                               | String   | Server-Side | Unique client identifier                      |
| user_data          | user_campaign_id              | String   | Server-Side | User campaign ID                              |
|                    | user_country                  | String   | Server-Side | User country                                  |
|                    | user_device_type              | String   | Server-Side | User device type                              |
|                    | user_channel_grouping         | String   | Server-Side | User channel grouping                         |
|                    | user_source                   | String   | Server-Side | User source                                   |
|                    | user_first_session_timestamp  | Integer  | Server-Side | Timestamp of user's first session             |
|                    | user_campaign_content         | String   | Server-Side | User campaign content                         |
|                    | user_campaign                 | String   | Server-Side | User campaign name                            |
|                    | user_campaign_click_id        | String   | Server-Side | User campaign click identifier                |
|                    | user_tld_source               | String   | Server-Side | User top-level domain source                  |
|                    | user_language                 | String   | Server-Side | User language                                 |
|                    | user_campaign_term            | String   | Server-Side | User campaign term                            |
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
|                    | session_exit_page_category    | String   | Server-Side | Exit page category                            |
|                    | session_exit_page_location    | String   | Server-Side | Exit page path                                |
|                    | session_exit_page_title       | String   | Server-Side | Exit page title                               |
|                    | session_start_timestamp       | Integer  | Server-Side | Session start timestamp                       |
|                    | session_end_timestamp         | Integer  | Server-Side | Session end timestamp                         |
|                    | total_events                  | Integer  | Server-Side | Total number of events in current session     |
|                    | total_page_views              | Integer  | Server-Side | Total number of page views in current session |
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
| event_origin       |                               | String   | Client-Side | Event origin (e.g., Website)                  |
| event_data         | event_type                    | String   | Client-Side | Event type                                    |
|                    | channel_grouping              | String   | Client-Side | Channel grouping for the event                |
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
|                    | ss_tag_id                     | String   | Server-Side | Server-side tag ID                            |
|                    | processing_event_timestamp    | Integer  | Server-Side | Event processing timestamp                    |
|                    | content_length                | Integer  | Server-Side | Request content length                        |
</details>

<details><summary>Request payload additional data parameters</summary>

#### Add dataLayer data
When the "Add current dataLayer state" option in the Nameless Analytics Client-side Tracker Configuration Variable is enabled, a `dataLayer` parameter will be added to the standard payload: 

| **Parameter name** | **Sub-parameter** | **Type** | **Added**   | **Field description** |
|--------------------|-------------------|----------|-------------|-----------------------|
| dataLayer          |                   | JSON     | Client-Side | DataLayer data        |

#### Ecommerce data
When "Add ecommerce data" in the Nameless Analytics Client-side Tracker Tag is enabled, an `ecommerce` parameter will be added to the standard payload:

| **Parameter name** | **Sub-parameter** | **Type** | **Added**   | **Field description** |
|--------------------|-------------------|----------|-------------|-----------------------|
| ecommerce          |                   | JSON     | Client-Side | Ecommerce data        |

#### Cross-domain data
When "Enable cross-domain tracking" in the Nameless Analytics Client-side Tracker Configuration Variable is enabled, the `cross_domain_session` and `cross_domain_id` parameters will be added to the standard payload:

| **Parameter name** | **Sub-parameter**    | **Type** | **Added**   | **Field description**   |
|--------------------|----------------------|----------|-------------|-------------------------|
| event_data         | cross_domain_id      | String   | Client-Side | Cross domain id         |
| session_data       | cross_domain_session | String   | Server-Side | Is cross domain session |

</details>

</br>


### Server-Side Processing
The **Server-Side Client Tag** serves as the security gateway and data orchestrator. It sits between the public internet and your cloud infrastructure, sanitizing every request.

#### Security & Validation
Validates request origins and authorized domains (CORS) before processing to prevent unauthorized usage.

#### Bot Protection
Actively detects and blocks automated traffic returning a `403 Forbidden` status. The system filters requests based on a predefined blacklist of over 20 User-Agents, including `HeadlessChrome`, `Puppeteer`, `Selenium`, `Playwright`, as well as common HTTP libraries like `Axios`, `Go-http-client`, `Python-requests`, `Java/OkHttp`, `Curl`, and `Wget`.

#### Data Integrity & Priority
Enforces a strict parameter hierarchy (Server Overrides > Tag Metadata > Config Variable > dataLayer) and **prevents "orphan events"**. The server will reject any interaction (e.g., click, scroll) with a `403 Forbidden` status if it hasn't been preceded by a valid `page_view` event for that session. This ensures every session in BigQuery has a clear starting point and reliable attribution.

#### Geolocation & Privacy by Design
Automatically maps the incoming request IP to geographic data (Country, City) for regional analysis. The system is designed to **never persist the raw IP address** in BigQuery, ensuring native compliance with strict privacy regulations.

To enable this feature, your server must be configured to forward geolocation headers. The platform natively supports **Google App Engine** (via `X-Appengine` headers) and **Google Cloud Run** (via `X-Gclb` headers). For Cloud Run, ensure the Load Balancer is [properly configured](https://www.simoahava.com/analytics/cloud-run-server-side-tagging-google-tag-manager/#add-geolocation-headers-to-the-traffic).

#### Real-time Forwarding
Supports instantaneous data streaming to external HTTP endpoints immediately after processing. The system allows for **custom HTTP headers** injection, enabling secure authentication with third-party services endpoints directly from the server.

#### Self-Monitoring & Performance
The system transparently tracks pipeline health by measuring **ingestion latency** (the exact millisecond delay between the client hit and server processing) and **payload size** (`content_length`). This data allows for high-resolution monitoring of the real-time data flow directly within BigQuery.

#### Debugging & Visibility
Developers can monitor the server-side logic in real-time through **GTM Server Preview Mode**.

#### ID Management
The tracker automatically generates and manages unique identifiers for users and sessions.

| Cookie Name    | Renewed                       | Example values                 | Value composition |
|----------------|-------------------------------|--------------------------------|-------------------|
| **client_id**  | when `na_u` cookie is created | lZc919IBsqlhHks                | Client ID         |
| **session_id** | when `na_s` cookie is created | lZc919IBsqlhHks_1KMIqneQ7dsDJU | Session ID        |

#### Cookies
All cookies are issued with `HttpOnly`, `Secure`, and `SameSite=Strict` flags. This multi-layered approach prevents client-side access (XSS protection) and Cross-Site Request Forgery (CSRF).

| Cookie Name | Default expiration | Example values                                 | Value composition                     |
|-------------|--------------------|------------------------------------------------|---------------------------------------|
| **na_u**    | 400 days           | lZc919IBsqlhHks                                | Client ID                             |
| **na_s**    | 30 minutes         | lZc919IBsqlhHks_1KMIqneQ7dsDJU-WVTWEorF69ZEk3y | Client ID _ Session ID - Last Page ID |

The platform automatically calculates the appropriate cookie domain by extracting the **Effective TLD+1** from the request origin. This ensures seamless identity persistence across subdomains without manual configuration. 
  
Cookies are created or updated on every event to track the user's session and identity across the entire journey.

</br>


### Storage
Nameless Analytics employs a complementary storage strategy to balance real-time intelligence with deep historical analysis:

#### Firestore as Last updated Snapshot
It mantains the latest available state for every user and session. For example, the current user_level.

- **User data**: Stores the latest user profile state, including first/last session timestamps, original acquisition source, and persistent device metadata.
- **Session data**: Stores the latest session state, including real-time counters (total events, page views), landing/exit page details, and session-specific attribution.

<details><summary>Firestore document structure example</summary>

</br>

<img alt="Nameless Analytics - Firestore collection schema" src="https://github.com/user-attachments/assets/d27c3ca6-f039-4702-853e-81e71ed033c2" />

</br>

Firestore ensures data integrity by managing how parameters are updated across hits:

| Scope | Type | Parameters | Logic |
| :--- | :--- | :--- | :--- |
| **User** | **First-Touch** | `user_date`, `user_source`, `user_tld_source`, `user_campaign`, `user_campaign_id`, `user_campaign_click_id`, `user_campaign_term`, `user_campaign_content`, `user_channel_grouping`, `user_device_type`, `user_country`, `user_language`, `user_first_session_timestamp` | Recorded at first visit, **never overwritten**. |
| **User** | **Last-Touch** | `user_last_session_timestamp` | Updated at the start of every new session. |
| **Session** | **First-Touch** | `session_date`, `session_number`, `session_start_timestamp`, `session_source`, `session_tld_source`, `session_campaign`, `session_campaign_id`, `session_campaign_click_id`, `session_campaign_term`, `session_campaign_content`, `session_channel_grouping`, `session_device_type`, `session_country`, `session_language`, `session_hostname`, `session_browser_name`, `session_landing_page_category`, `session_landing_page_location`, `session_landing_page_title`, `user_id` | Set at session start, persists throughout the session. |
| **Session** | **Last-Touch** | `session_exit_page_category`, `session_exit_page_location`, `session_exit_page_title`, `session_end_timestamp`, `total_events`, `total_page_views` | **Updated on every hit** to reflect the latest state. |
| **Session** | **Progressive** | `cross_domain_session` | Flags as 'Yes' if any hit in the session is cross-domain. |

</details>

#### BigQuery as Historical Timeline
It mantains **every single state transition** for every user and session. For example, all different user_level values through time.

- **User data**: Stores the current user profile state at event occurs, including first/last session timestamps, original acquisition source, and persistent device metadata.
- **Session data**: Stores the current session state at event occurs, including real-time counters (total events, page views), landing/exit page details, and session-specific attribution.
- **Page data**: Stores the current page state at event occurs, including page name, timestamp, and page-specific attributes.
- **Event data**: Stores the current event state at event occurs, including event name, timestamp, and event-specific attributes.
- **dataLayer data**: Stores the current dataLayer state at event occurs, including dataLayer name, timestamp, and dataLayer-specific attributes.
- **Ecommerce data**: Stores the current ecommerce state at event occurs, including ecommerce metrics, timestamp, and ecommerce-specific attributes.
- **Consent data**: Stores the current consent state at event occurs, including consent status, timestamp, and consent-specific attributes.
- **GTM Performance data**: Stores the current GTM performance state at event occurs, including GTM performance metrics, timestamp, and GTM performance-specific attributes.

<details><summary>BigQuery schema example</summary>

</br>

<img alt="Nameless Analytics - BigQuery event_raw schema" src="https://github.com/user-attachments/assets/d23e3959-ab7a-453c-88db-a4bc2c7b32f4" />

</br>

A suite of SQL Table Functions transforms raw data into business-ready views for [Users](reporting-tables/users.sql), [Sessions](reporting-tables/sessions.sql), [Pages](reporting-tables/pages.sql), [Events](reporting-tables/events.sql), [Consents](reporting-tables/consents.sql), [GTM Performance](reporting-tables/gtm_performances.sql), and specialized Ecommerce views like [Transactions](reporting-tables/ec_transactions.sql), [Products](reporting-tables/ec_products.sql), and Funnels ([Open](reporting-tables/ec_shopping_stages_open_funnel.sql) / [Closed](reporting-tables/ec_shopping_stages_closed_funnel.sql)).

</details>

</br>


### Reporting

SQL Table Functions can be used as sources for dashboards, such as this one, which demonstrates the platform's potential with a pre-built template covering all key metrics.

#### Overview
- [**Executive Summary**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_ebkun2sknd): High-level KPIs including total users, sessions, revenue, and conversion rates, along with sparkline trends for immediate health checks.

#### Acquisition
- [**Traffic Sources**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_rmpwib9hod): Breakdown of traffic by source, medium, and channel grouping. Powered by [sessions.sql](reporting-tables/sessions.sql).
- [**Device Performance**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_cmywmb9hod): Analysis of user volume and revenue split across devices. Logic defined in [sessions.sql](reporting-tables/sessions.sql).
- [**Geographic Distribution**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_enanrb9hod): Map and table views showing user sessions and revenue by Country (using server-side enrichment).

#### Behaviour
- [**Page Performance**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_oqvpz41sgd): Detailed metrics for individual pages. Powered by [pages.sql](reporting-tables/pages.sql).
- [**Landing Pages**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_it3ayf1hod): Effectiveness of entry points. Logic in [sessions.sql](reporting-tables/sessions.sql).
- [**Exit Pages**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_ep50zf1hod): Identification of high-drop-off pages. Logic in [sessions.sql](reporting-tables/sessions.sql).
- [**Event Tracking**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_y779jg1hod): Granular view of tracked interaction events. Powered by [events.sql](reporting-tables/events.sql).

#### Ecommerce
- [**Customer Analysis**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_jc2z2lhwgd): Customer loyalty and frequency. Based on [users.sql](reporting-tables/users.sql).
- [**Sales Performance**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_zlu0hdkugd): Revenue trends over time. Powered by [ec_transactions.sql](reporting-tables/ec_transactions.sql).
- [**Product Performance**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_x89r79gvgd): Item-level reporting. Powered by [ec_products.sql](reporting-tables/ec_products.sql).
- [**Shopping Funnel**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_o8lq2jfvgd): Conversion funnel analysis. Based on [Open](reporting-tables/ec_shopping_stages_open_funnel.sql) and [Closed](reporting-tables/ec_shopping_stages_closed_funnel.sql) funnel logic.

#### Compliance (Consent)
- [**Consent Overview**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_sba934crpd): Stats on opt-in rates. Powered by [consents.sql](reporting-tables/consents.sql).
- [**Consent Details**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_nn21ghetpd): Granular consent types over time. Logic in [consents.sql](reporting-tables/consents.sql).

#### Debugging & Tech
- [**Web Hits Latency**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_zlobch0knd): Pipeline latency monitoring. Using [gtm_performances.sql](reporting-tables/gtm_performances.sql).
- [**Server-to-Server Hits**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_yiouuvwgod): Dedicated view for non-browser events sent via Measurement Protocol.
- [**Raw Data Inspector**](https://lookerstudio.google.com/u/0/reporting/d4a86b2c-417d-4d4d-9ac5-281dca9d1abe/page/p_unnkswttkd): Full table view of individual raw events for granular troubleshooting and verification.

</br>


### Support & AI
Get expert help for implementation, technical documentation, and advanced SQL queries.
- **[OpenAI GPT](https://chatgpt.com/g/g-6860ef949f94819194c3bc2c08e2f395-nameless-analytics-qna)**: Specialized GPTs trained on the platform docs.
- **[Gemini Gem](https://gemini.google.com/gem/12aygokOBFvZrvu0kU8YD4nxbvaipcPuI)**: Specialized Gem trained on the platform docs

</br></br>



## Pricing & Cloud Costs
Nameless Analytics is designed to achieve maximum performance with minimum overhead. By utilizing Google Cloud's serverless offerings, the platform can operate at **zero cost** for many users and scales predictably with traffic.

### Data processing
You can choose the compute environment that best fits your traffic and budget:

*   **Cloud Run (Recommended)**: The most modern and cost-effective choice. It scales to zero when there's no traffic. The Google Cloud "Always Free" tier includes **2 million requests per month**, which covers most small-to-medium websites at no charge.
*   **App Engine Standard**: Ideal for 24/7 uptime on a budget. Includes **28 free instance-hours per day** (F1 instances), allowing for a continuous single-server setup at **zero cost**.
*   **App Engine Flexible**: Best for enterprise-scale deployments (5-10M+ hits/month) requiring multi-zone redundancy. Typically starts at ~$120/month for a 3-instance minimum cluster.

### Data storage
*   **Google Firestore**: Manages real-time session states. Billing is primarily based on **document operations** (Reads and Writes). The free tier includes **50,000 reads and 20,000 writes per day**. Since data is frequently overwritten or deleted, physical storage usage typically remains within the **1 GB free limit**.
*   **Google BigQuery**: Your long-term historical data warehouse. These estimates include **data storage** and **streaming ingestion** (the cost to land data into the warehouse). **Note**: Query processing (scanning data for analysis/dashboards) is billed separately by Google Cloud based on usage; however, the first **1 TB per month** is always free.

### Cost Summary Table (Monthly estimates)
| Traffic Tier | Monthly Hits | Processing (Compute) | Firestore Ops | BQ Ingest & Storage | Estimated Total |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Low** | < 500k | $0 (Free Tier) | $0 (Free Tier) | $0 (Free Tier) | **FREE** |
| **Medium** | 1M - 2M | $0 - $1 | ~$3 - $4 | < $1 | **$3 - $6** |
| **High** | 5M | ~$8 - $12 | ~$10 - $12 | ~$1 - $2 | **$19 - $26** |
| **Enterprise** | 10M+ | ~$20 - $130+ | ~$22+ | ~$3+ | **$45 - $155+** |

</br>

> **Note on Estimates**: Calculations are based on standard US/EU regional pricing. "Data" costs reflect Firestore operations and BigQuery streaming ingestion. These totals **exclude** BigQuery query processing costs, which vary based on dashboard usage and analytical query volume (1 TB/mo free Tier typically covers standard dashboard usage).


</br></br>



## Quick Start
### Project configuration
Before starting the setup, ensure you have:
- A Google Cloud Project with an active billing account
- A Google BigQuery project
- A Google Firestore database
- A Google Tag Manager (Web) container
- A Google Tag Manager (Server-side) container running on [App Engine](https://www.simoahava.com/analytics/provision-server-side-tagging-application-manually/) or [Cloud run](https://www.simoahava.com/analytics/cloud-run-server-side-tagging-google-tag-manager/)

### Google Cloud Setup
- Google Cloud BigQuery: Create tables and table functions in BigQuery using the provided [SQL scripts](reporting-tables/)
- Google Cloud Firestore: Enable in **Native Mode**
- Google Cloud IAM: Grant your GTM SS Service Account `BigQuery Data Editor`, `BigQuery Job User`, and `Cloud Datastore User`

### Google Tag Manager Setup
- Import: [Client-side GTM Template](gtm-containers/gtm-client-side-container-template.json)
- Import: [Server-side GTM Template](gtm-containers/gtm-server-side-container-template.json)

</br>



## External Resources
- [Live Demo](https://namelessanalytics.com) (Open the dev console).
- [Changelog](CHANGELOG.md)
- [Roadmap](ROADMAP.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [MIT License](LICENSE)

---
Reach me at: [Email](mailto:hello@tommasomoretti.com) | [Website](https://tommasomoretti.com) | [Twitter](https://twitter.com/tommoretti88) | [LinkedIn](https://www.linkedin.com/in/tommasomoretti/)

