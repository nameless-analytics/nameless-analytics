# Nameless Analytics | Setup Guides

Use these guides to install Nameless Analytics, configure tracking and enable optional features. For the platform architecture and data model, [start with the main README](../README.md#overview). For errors during implementation, use the [Troubleshooting Guide](TROUBLESHOOTING-GUIDE.md).

### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change

## Table of Contents

- [How to set up Nameless Analytics in GTM](#how-to-set-up-nameless-analytics-in-gtm)
  - [1. Prerequisites](#1-prerequisites)
  - [2. Template integration](#2-template-integration)
  - [3a. Client-side container configuration](#3a-client-side-container-configuration)
  - [3b. Server-side container configuration](#3b-server-side-container-configuration)
  - [4. Pipeline validation & QA](#4-pipeline-validation--qa)
- [How to track page views](#how-to-track-page-views)
  - [Via GTM standard page view trigger](#via-gtm-standard-page-view-trigger)
  - [Via browser history (route change)](#via-browser-history-route-change)
  - [Via custom dataLayer event](#via-custom-datalayer-event)
- [How to track standard events](#how-to-track-standard-events)
  - [Consent update](#consent-update)
  - [Page load time](#page-load-time)
  - [Page closed](#page-closed)
  - [Search results view](#search-results-view)
  - [Search result click](#search-result-click)
  - [Authentication](#authentication)
  - [New lead](#new-lead)
  - [Newsletter sign up](#newsletter-sign-up)
- [How to track custom events](#how-to-track-custom-events)
  - [1. Fire a custom event](#1-fire-a-custom-event)
  - [2. Configure the GTM tag](#2-configure-the-gtm-tag)
- [How to set up user ID and user properties](#how-to-set-up-user-id-and-user-properties)
  - [1. Expose user data to the dataLayer](#1-expose-user-data-to-the-datalayer)
  - [2. Configure Nameless Analytics Client-side Tracker Configuration Variable](#2-configure-nameless-analytics-client-side-tracker-configuration-variable)
- [How to respect user consents](#how-to-respect-user-consents)
  - [1. Enable consent initialization](#1-enable-consent-initialization)
  - [2. Configure the tracker variable](#2-configure-the-tracker-variable)
  - [3. Preserving acquisition data (the na_temp cookie)](#3-preserving-acquisition-data-the-na_temp-cookie)
- [How to set up cross-domain tracking](#how-to-set-up-cross-domain-tracking)
  - [One client-side GTM container for multiple sites](#one-client-side-gtm-container-for-multiple-sites)
  - [Two client-side GTM containers, one per site](#two-client-side-gtm-containers-one-per-site)
  - [One server-side GTM container for multiple sites](#one-server-side-gtm-container-for-multiple-sites)
  - [Two server-side GTM containers, one per site](#two-server-side-gtm-containers-one-per-site)
- [How to set up and customize ecommerce tracking](#how-to-set-up-and-customize-ecommerce-tracking)
  - [Ecommerce tracking initialization](#ecommerce-tracking-initialization)
  - [1. dataLayer requirement](#1-datalayer-requirement)
  - [2. Tracker configuration](#2-tracker-configuration)
  - [3. Server-side processing](#3-server-side-processing)
  - [Advanced ecommerce reporting](#advanced-ecommerce-reporting)
- [How to send events via Streaming Protocol](#how-to-send-events-via-streaming-protocol)
- [How to set up first-party library hosting](#how-to-set-up-first-party-library-hosting)
  - [1. Download the core libraries](#1-download-the-core-libraries)
  - [2. Host the libraries on your infrastructure](#2-host-the-libraries-on-your-infrastructure)
  - [3. Update the GTM configuration](#3-update-the-gtm-configuration)
  - [4. Authorize the new domain in the template permissions](#4-authorize-the-new-domain-in-the-template-permissions)
- [How to configure real-time forwarding](#how-to-configure-real-time-forwarding)
  - [Configuration steps](#configuration-steps)
- [How to enforce security & bot protection](#how-to-enforce-security--bot-protection)
  - [1. Authorized domains (CORS-like protection)](#1-authorized-domains-cors-like-protection)
  - [2. Bot & automated traffic protection](#2-bot--automated-traffic-protection)
  - [3. IP blacklisting](#3-ip-blacklisting)
- [How to configure a conversational analysis agent in BigQuery Studio](#how-to-configure-a-conversational-analysis-agent-in-bigquery-studio)
  - [Knowledge sources configuration](#knowledge-sources-configuration)
  - [Best practices for accuracy](#best-practices-for-accuracy)
- [Data governance & privacy compliance](#data-governance--privacy-compliance)

## How to set up Nameless Analytics in GTM

Nameless Analytics uses a client-side GTM container, a server-side GTM container and three custom templates.

### 1. Prerequisites

Prepare the following before importing the templates:

- **BigQuery:** create the dataset, `events_raw` and `calendar_dates` with the provided [SQL setup](../tables/TABLES.md).
- **Firestore:** initialize a Native Mode database, normally the `(default)` database.
- **Server-side GTM:** deploy the tagging server and map it to a first-party domain.
- **Runtime permissions:** grant the tagging server service account `roles/datastore.user` and `roles/bigquery.dataEditor` on the selected project.

### 2. Template integration

Import each `.tpl` file from **Templates** → **New** → three-dot menu → **Import**:

| Repository | GTM container | Template type |
|:---|:---|:---|
| `client-side-tracker-configuration-variable` | Web | Variable template |
| `client-side-tracker-tag` | Web | Tag template |
| `server-side-client-tag` | Server | Client template |

Save each template after import.

### 3a. Client-side container configuration

1. Create a variable from **Nameless Analytics Client-side Tracker Configuration Variable**.
2. Under **Server-side endpoint settings**, enter:
   - **Endpoint domain name:** the bare tagging-server domain, such as `gtm.example.com`, without protocol or trailing slash;
   - **Endpoint path:** a dedicated path such as `/na/collect`, beginning with `/` and without a trailing slash.
3. Create a **Nameless Analytics Client-side Tracker Tag**.
4. Select **Standard event name** → `page_view`, assign the configuration variable and use **All Pages** as the trigger.

### 3b. Server-side container configuration

1. Create a client from **Nameless Analytics Server-side Client Tag**.
2. Under **Client settings**, set **Endpoint path** to the same dedicated path used in the web configuration.
3. Under **Google BigQuery settings**, enter the project, dataset and `events_raw` table IDs.
4. Save and publish the server container.

The client-side and server-side paths must match exactly. Do not share the Nameless Analytics path with another server-container client.

### 4. Pipeline validation & QA

Open Preview Mode for both containers, load the website and verify one `page_view`:

1. the browser console shows the tracker initialization;
2. the request appears in the Network tab and returns Nameless Analytics JSON;
3. GTM Server Preview shows that the Server-side Client Tag claimed the request;
4. the response reports `firestore: success` and `bigquery: success`;
5. the user/session exists in Firestore and the event exists in BigQuery.

Use the [Troubleshooting Guide](TROUBLESHOOTING-GUIDE.md) if any stage fails.

## How to track page views

`page_view` creates the user and session context, sets the server cookies and records the page. It must be the first Nameless Analytics event on every physical page load; earlier interactions become [orphan events](TROUBLESHOOTING-GUIDE.md#event-sequence).

Additional `page_view` events on the same physical page are virtual page views. They update page context and referrer without replacing the existing user/session acquisition. See [SPA & History Management](../README.md#spa--history-management) for reporting implications.

### Via GTM standard page view trigger

Use the standard **All Pages** trigger for traditional page loads.

### Via browser history (route change)

For SPAs, fire the page-view tag on History Change after updating the title and page-level data:

```javascript
document.title = 'Product name | Nameless Analytics';
dataLayer.push({ page_category: 'Product page' });
history.pushState('', '', '/product-name');
```

### Via custom dataLayer event

Push a custom `page_view` event when your application controls route changes:

```javascript
dataLayer.push({
  event: 'page_view',
  page_category: 'Product page',
  page_title: 'Product name | Nameless Analytics'
});
```

Map or [override the page parameters](https://github.com/nameless-analytics/client-side-tracker-configuration-variable/#page-data) in the configuration variable before firing the tag.

## How to track standard events

For each event, create a GTM trigger, create any required Data Layer Variables, then create a **Nameless Analytics Client-side Tracker Tag** using the same configuration variable as `page_view`. Select the corresponding **Standard event name** and map the listed **Event parameters**.

### Consent update

Use `consent_update` with the custom event emitted by your CMP. It requires no event parameters; Consent Mode values are collected separately.

### Page load time

Fire `page_load_time` on **Window Loaded** and map `total_page_load_time` in milliseconds.

<details>
<summary>Example Custom JavaScript Variable</summary>

```javascript
function() {
  var entries = performance.getEntriesByType && performance.getEntriesByType('navigation');
  if (entries && entries[0] && entries[0].loadEventEnd > 0) {
    return Math.round(entries[0].loadEventEnd - entries[0].startTime);
  }
}
```

</details>

### Page closed

Fire `page_closed` from your page-exit logic, commonly a `visibilitychange` listener. The tracker uses a keepalive request, but delivery during page closure is not guaranteed by the browser.

### Search results view

Fire `search_result_view` and map `search_term`:

```javascript
dataLayer.push({ event: 'search_result_view', search_term: 'analytics' });
```

### Search result click

Fire `search_result_click` and map `search_term` and `search_results_name`:

```javascript
dataLayer.push({
  event: 'search_result_click',
  search_term: 'analytics',
  search_results_name: 'Introduction to Web Analytics'
});
```

### Authentication

Use the reserved events `login`, `logout` and `sign_up`. Map `user_id` under the configuration variable's **Session parameters**:

```javascript
dataLayer.push({
  event: 'login', 
  user_id: 'ABC-12345'
});
```

`login` sets the session `user_id`; `logout` clears it. Renaming either event prevents this lifecycle logic from running. See [User ID lifecycle](../README.md#user-id-lifecycle).

### New lead

Fire `new_lead` from the relevant form or application event. Add form name, lead type or other context as optional event parameters.

### Newsletter sign up

Fire `newsletter_sign_up` from the confirmed subscription event. No parameters are required.

## How to track custom events

Use a custom event for interactions that do not map to a standard name.

### 1. Fire a custom event

```javascript
dataLayer.push({
  event: 'file_downloaded',
  file_name: 'nameless-analytics-guide.pdf',
  file_type: 'pdf'
});
```

### 2. Configure the GTM tag

1. Create a Custom Event trigger for `file_downloaded`.
2. Create Data Layer Variables for `file_name` and `file_type`.
3. Create a **Nameless Analytics Client-side Tracker Tag** and select **Custom event name**.
4. Enter the event name or map GTM's built-in `{{Event}}` variable.
5. Add the custom fields under **Event parameters**.

The resulting `event_name` is stored in BigQuery and custom parameters are stored in `event_data`. Standard event names cannot be entered as custom names; select them from **Standard event name** instead. When using `{{Event}}`, ensure the trigger cannot resolve to an unwanted GTM internal event such as `gtm.click`.

## How to set up user ID and user properties

`user_id` is session-scoped. Custom user properties are user-scoped. Both are persisted in Firestore and included in the corresponding BigQuery parameter arrays.

### 1. Expose user data to the dataLayer

Push the values before the event that should use them:

```javascript
dataLayer.push({
  user_id: 'USR-987654321',
  user_tier: 'Premium'
});
```

### 2. Configure Nameless Analytics Client-side Tracker Configuration Variable

1. Create Data Layer Variables for the exposed values.
2. Map `user_id` under **Session parameters**.
3. Add profile properties such as `user_tier` under **User parameters**.

Avoid unnecessary or sensitive fields. Every custom property grows the Firestore user document and may accelerate the [1 MiB document limit](TROUBLESHOOTING-GUIDE.md#firestore-1-mib-document-limit).

## How to respect user consents

Nameless Analytics can follow the `analytics_storage` state exposed through Google Consent Mode. Your CMP configuration, legal basis and regional requirements remain implementation-specific.

### 1. Enable consent initialization

Configure the CMP or consent implementation to set a Consent Mode default before the GTM container loads, then issue an `update` when the visitor makes a choice.

### 2. Configure the tracker variable

Enable **Respect Google Consent Mode** under **Consent Settings**:

- `granted`: events are sent normally;
- `denied`: events are held until a later consent update;
- `analytics_storage` missing or unset: the request is aborted and no event is sent;
- Consent Mode missing: the tag aborts without sending data.

### 3. Preserving acquisition data (the na_temp cookie)

While `analytics_storage` is denied, the tracker preserves source, campaign and referrer in the first-party session cookie `na_temp` and keeps it across real and virtual page views. After consent is granted, pending events can use these values; the next page view processed with granted consent removes the cookie and recalculates event-level acquisition.

`na_temp` is client-readable. Do not place sensitive information in campaign parameters or referrer query strings.

## How to set up cross-domain tracking

Cross-domain tracking keeps the current Nameless Analytics session when a visitor follows a configured link to another site. The source site requests the current server-issued identity, decorates the destination URL with a short-lived `na_id`, and the destination validates it on its first `page_view`.

Enable **Enable cross-domain tracking**, add the destination domains under **Cross-domain domains**, and ensure each site has a valid server endpoint. Invalid or expired values are ignored without rejecting the event. See [Cross-domain architecture](../README.md#cross-domain-architecture) and [Cross-domain troubleshooting](TROUBLESHOOTING-GUIDE.md#cross-domain-decoration) for the internal flow and limitations.

Map each first-party tagging domain according to your hosting provider: [App Engine standard](https://cloud.google.com/appengine/docs/standard/mapping-custom-domains), [App Engine flexible](https://cloud.google.com/appengine/docs/flexible/mapping-custom-domains), [Cloud Run](https://cloud.google.com/run/docs/mapping-custom-domains) or [Stape](https://help.stape.io/hc/en-us/articles/4405367809681-How-to-setup-custom-domain-for-server-side-Google-Tag-Manager).

### One client-side GTM container for multiple sites

1. Add every destination under **Cross-domain domains**.
2. Use a Regex Lookup Table to select the correct **Endpoint domain name** from the current hostname.
3. Keep the same **Endpoint path** for all sites served by the same server container.

![Cross-domain domains list](https://github.com/user-attachments/assets/c8ab4d08-5069-4833-8465-5ca4ddea0863)

![Lookup Table for dynamic endpoints](https://github.com/user-attachments/assets/a7b54f23-18b5-4e54-ba80-216a06a51f2d)

### Two client-side GTM containers, one per site

In each container, enable cross-domain tracking, add the other site under **Cross-domain domains**, and point **Endpoint domain name** to that site's own tagging domain.

### One server-side GTM container for multiple sites

1. Add every tagging URL under Server container → Admin → Container Settings.
2. If **Accept requests from authorized domains only** is enabled, add every participating site under **Authorized domains**.
3. Use the same Nameless Analytics endpoint path for all sites.

This allows requests and `Set-Cookie` responses to use the appropriate first-party domain.

![Add multiple domains to server-side GTM](https://github.com/user-attachments/assets/53eb03cd-8fdf-437b-b0e2-aa92d7bcef4e)

### Two server-side GTM containers, one per site

Configure each site and tagging server independently. Cross-domain decoration carries the session between them; no shared server-container configuration is required.

## How to set up and customize ecommerce tracking

Nameless Analytics can capture GA4-style ecommerce objects from the current Data Layer event and expose them through the ecommerce reporting functions.

### Ecommerce tracking initialization

Use the standard GA4 ecommerce object where possible. A custom schema can still be stored, but the provided reporting functions must be adapted to its JSON paths.

### 1. dataLayer requirement

Push the `ecommerce` object with the event that fires the tracker tag, for example `view_item`, `add_to_cart`, `begin_checkout` or `purchase`.

### 2. Tracker configuration

Under the client tag's **Advanced settings**, enable **Add ecommerce data from dataLayer**. The tag reads the ecommerce object associated with the current GTM event.

### 3. Server-side processing

The server stores the ecommerce object as JSON in `events_raw.ecommerce`. For non-standard schemas, update the extraction paths in the [Transactions](../tables/TABLES.md#transactions) and [Products](../tables/TABLES.md#products) functions.

### Advanced ecommerce reporting

- [Transactions](../tables/TABLES.md#transactions) reports order-level values;
- [Products](../tables/TABLES.md#products) flattens ecommerce items;
- [Ecommerce Funnel](../tables/TABLES.md#ecommerce-funnel) reports progression from view to purchase.

Revenue, RFM and ROAS currently aggregate numeric values without currency conversion. Normalize amounts to one reporting currency before sending them, or separate reporting by currency.

## How to send events via Streaming Protocol

Use the Streaming Protocol for offline or backend events that must be attributed to an existing website session. Configure its `X-Api-Key`, required User-Agent and `Origin`, and do not use it for `page_view`. See the [Streaming Protocol documentation](../streaming-protocol/STREAMING-PROTOCOL.md) for payload and implementation examples.

## How to set up first-party library hosting

First-party hosting reduces dependency on public CDNs and can reduce blocking by browser extensions. It does not bypass browser policy: the hosting origin must still be allowed by the site's Content Security Policy and the GTM template permission.

### 1. Download the core libraries

Download:

1. [nameless-analytics_vX.X.X.min.js](https://github.com/nameless-analytics/client-side-tracker-tag/blob/main/lib/) using the version expected by the installed client template;
2. [ua-parser.pack.min.js](https://cdn.jsdelivr.net/npm/ua-parser-js@1.0.40/dist/ua-parser.pack.min.js), currently pinned to `ua-parser-js@1.0.40`.

### 2. Host the libraries on your infrastructure

Upload both files over HTTPS to a first-party domain or subdomain and preserve their original filenames. The tag builds the final URLs from the configured domain and directory.

### 3. Update the GTM configuration

Under **Advanced settings** in the configuration variable:

1. enable **Load JavaScript libraries in first-party mode**;
2. set **Custom library domain name** without protocol or trailing slash;
3. set **Custom library path** beginning with `/` and without a trailing slash.

For example, domain `www.example.com` and path `/assets/js` produce `https://www.example.com/assets/js/nameless-analytics_vX.X.X.min.js`.

### 4. Authorize the new domain in the template permissions

Open the Client-side Tracker Tag template → **Permissions** → **Inject Scripts** and allow the hosting URL pattern, for example `https://www.example.com/*`. Ensure the same origin is allowed by the site's CSP `script-src` directive, then publish the template and container.

## How to configure real-time forwarding

After Firestore and BigQuery complete, Nameless Analytics can forward the enriched event to an external HTTPS endpoint as JSON with `Content-Type: application/json`. Forwarding receives the event before BigQuery-specific encoding; a forwarding failure does not roll back the stored event.

### Configuration steps

1. Open the **Nameless Analytics Server-side Client Tag**.
2. Under **Advanced settings**, enable **Send data to custom endpoint**.
3. Enter the HTTPS destination in **Full endpoint domain path**.
4. If needed, enable **Add custom request headers** and configure each header under **Custom request headers**.
5. Publish the server container and verify `processing.custom_endpoint` in the response.

Credentials configured here are not sent to the visitor's browser, but they remain visible to authorized GTM editors and container exports. Limit access and rotate them according to the destination's security policy.

## How to enforce security & bot protection

These controls improve traffic quality and restrict normal browser requests. They do not replace API authentication, rate limiting or an edge security layer.

### 1. Authorized domains (CORS-like protection)

Enable **Accept requests from authorized domains only** under **Client settings** → **Security rules**, then add bare domain names under **Authorized domains**. The current comparison uses Effective TLD+1, so one entry covers all subdomains. Include production, staging and every cross-domain participant.

Requests without `Origin` are rejected when this option is enabled. The browser tracker sends it automatically; custom backend and Streaming Protocol clients must add it explicitly. Because non-browser callers can spoof `Origin`, treat this as a browser-origin filter rather than authentication.

### 2. Bot & automated traffic protection

Enable **Enable Bot protection** to reject User-Agents matching the built-in automation list. This is a heuristic and can produce false positives. A missing User-Agent is always rejected; Streaming Protocol requests must use exactly `Nameless Analytics - Streaming Protocol` even when general bot protection is disabled. See [Enable Bot protection](https://github.com/nameless-analytics/server-side-client-tag/#enable-bot-protection) for the maintained signature list.

### 3. IP blacklisting

Enable **Reject requests by IP** and add IPv4 or IPv6 addresses under **Banned IPs**. Use this for known unwanted sources; use an edge rate limiter or WAF for broader abuse protection.

## How to configure a conversational analysis agent in BigQuery Studio

BigQuery Conversational Analytics can use Nameless Analytics tables and routines as knowledge sources. This feature is optional and may execute chargeable queries. See Google's [current data-agent documentation](https://docs.cloud.google.com/bigquery/docs/create-data-agents) before enabling it.

### Knowledge sources configuration

Start with `events_raw`, `calendar_dates` and only the reporting routines needed for the intended use case. Adding every available source can make the agent context harder to interpret and increase query complexity.

### Best practices for accuracy

- describe important tables, fields and parameters in business language;
- define filters, reporting timezone, currency and metric semantics in the agent instructions;
- use verified queries—previously called golden queries—to demonstrate approved calculations;
- review generated SQL and configure BigQuery cost controls before sharing the agent.

These inputs guide and ground the agent; they do not train a new model on the dataset.

## Data governance & privacy compliance

To process a user deletion request, remove the identifier from both Firestore and BigQuery. The provided [User Data Deletion Script](../tables/TABLES.md#delete-user-data-script) is a reference utility, not an atomic transaction: verify its project IDs and target `client_id`, then confirm deletion independently in both stores. See [manual deletion](../tables/TABLES.md#manual-user-data-deletion) for the alternative procedure.

Server-side deletion does not remove the `na_u` cookie from the visitor's browser. If that cookie remains, a later `page_view` can recreate the same `client_id` with a new history. See [Cookies are not deleted](../tables/TABLES.md#cookies-are-not-deleted).

Configure retention and access controls for the raw dataset, and avoid sending unnecessary personal or sensitive data through URLs, `dataLayer`, ecommerce objects or custom parameters.

#

[Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_setup_guides) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
