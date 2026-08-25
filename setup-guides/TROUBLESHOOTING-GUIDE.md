# Nameless Analytics | Troubleshooting Guide
The Nameless Analytics Troubleshooting Guide identifies, explains, and resolves common issues encountered during implementation.

### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change



## Table of Contents

- [Troubleshooting Tip](#troubleshooting-tip)
- [Orphan Events & Sequence Issues](#orphan-events--sequence-issues)
- [Validation Errors (403 Forbidden)](#validation-errors-403-forbidden)
- [Google Consent Mode](#google-consent-mode)
- [Library Loading & Configuration Issues](#library-loading--configuration-issues)
- [Storage & Cloud Permissions](#storage--cloud-permissions)
- [BigQuery & Data Analysis Issues](#bigquery--data-analysis-issues)
  - [BigQuery Advanced Runtime](#bigquery-advanced-runtime)
  - [Missing Geolocation Data](#missing-geolocation-data)
  - [Unexpected Channel Grouping](#unexpected-channel-grouping)
- [Network & Custom Endpoint Issues](#network--custom-endpoint-issues)
- [Cross-domain Issues](#cross-domain-issues)
  - [Link Not Decorated (`na_id` Missing)](#link-not-decorated-na_id-missing)
  - [Invalid or Expired `na_id`](#invalid-or-expired-na_id)



## Troubleshooting Tip
Use the **Browser console** to check tags execution status and event data sent to the server.

Use the **GTM Server Preview Mode** to check incoming events and how the Server-side Client Tag responds to them.

Inspect a network request to see the data sent by client from Preview and data response by server from Preview.



## Orphan Events & Sequence Issues
An **Orphan Event** is any interaction (click, scroll, etc.) that reaches the server without a valid session context established by a preceding `page_view` event or the request is without a valid user and session cookie.


Browser console shows: 

```text
[event_name] >   🔴 Event fired before a page view event. The first event on any page must be page_view.
[event_name] > REQUEST STATUS
[event_name] >   🔴 Request aborted
```

- **Issue:** An interaction event is fired before the `page_view` event has been dispatched.
- **Solution:** Nameless Analytics utilizes an internal fetch queue to manage requests, which prevents most race conditions. However, every event must be preceded by a `page_view` event. Ensure the page view is the first event sent at every page load.

> **`🔴 Request aborted` is not specific to orphan events.** It is the closing line of every path that stops the tag before the request is sent — invalid configuration variable, libraries not loaded, `inject_script` permission denied, Consent Mode missing, consent denied. Always read the cause in the line above it, not in the abort line itself.

Server logs show: 

`🔴 Orphan event: missing user cookie. Trigger a page_view event first to create a new user and a new session`

`🔴 Orphan event: missing session cookie. Trigger a page_view event first to create a new session`

- **Issue:** A user leaves a tab open for more than 30 minutes (default session timeout). When they return and click, the session cookie (`na_s`) has expired.
- **Solution:** This is expected defensive behavior to ensure data integrity. Nameless Analytics rejects these to avoid "zombie" sessions without attribution.

Server logs show: 

`🔴 Orphan event: user doesn't exist in Firestore. Trigger a page_view event first to create a new user and a new session`

`🔴 Orphan event: session doesn't exist in Firestore. Trigger a page_view event first to create a new session`

- **Issue:** Firestore does not contain a record for this user or session.
- **Solution:** Ensure the first event triggered on every page load is always a `page_view` to initialize the user and session profile in Firestore.



## Validation Errors (403 Forbidden)
The Server-side Client Tag acts as a security gateway. If a request doesn't meet strict criteria, it is rejected with a `403 Forbidden` status.


Browser console shows: 

`[event_name] > 🔴 Request refused`

- **Issue:** The Server-side Client Tag refused the request due to a validation failure.
- **Solution:** Check the server-side GTM preview mode "Inbound Request" logs for the specific cause (Origin, IP, Bot protection, etc.).

Server logs show: 

`🔴 Request origin not authorized`

- **Issue:** The request came from a domain that is not in the **Authorized domains** table, or it carried no `Origin` header at all. The header is missing on server-to-server calls, so a Streaming Protocol implementation that does not set it is refused here as soon as the option is enabled.
- **Solution:** Add the domain to the **Authorized domains** table in the Server-side Client Tag configuration, as a bare host name without protocol (e.g., `example.com`, not `https://example.com`, which the field validation rejects). Only the Effective TLD+1 is compared, so one entry covers all subdomains. In a cross-domain setup list every domain involved, and make sure your backend sends the `Origin` header.

Server logs show: 

`🔴 Request IP not authorized`

- **Issue:** The request came from an IP address listed in the **Banned IPs** table.
- **Solution:** Remove the IP from the list if it's a false positive.

Server logs show: 

`🔴 Missing User-Agent header. Request from bot`

`🔴 Invalid User-Agent header value. Request from bot`

- **Issue:** The request was identified as an automated bot, a scraper, or originated from a common HTTP library.
- **Solution:** Nameless Analytics blocks requests from non-browser environments to ensure data quality. Testing must be performed from a standard, modern browser. 
  
  The system currently blocks any User-Agent containing the following keywords:
  - **HTTP Libraries:** `curl`, `wget`, `python`, `requests`, `httpie`, `go-http-client`, `java`, `okhttp`, `libwww`, `perl`, `axios`, `node`, `fetch`, `php`, `guzzle`, `ruby`, `faraday`, `rest-client`.
  - **AI Agents & LLMs:** `gptbot`, `chatgpt`, `anthropic`, `claude`, `perplexity`, `bytespider`, `ccbot`.
  - **SEO & Marketing Bots:** `ahrefs`, `semrush`, `dotbot`, `mj12`, `rogerbot`, `bot`, `crawler`, `spider`, `scraper`.
  - **Automation & Security:** `nmap`, `zgrab`, `masscan`, `shodan`, `headless`, `phantomjs`, `selenium`, `puppeteer`, `playwright`, `cypress`, `electron`.

  If you are using the **Streaming Protocol**, the `User-Agent` must be exactly `Nameless Analytics - Streaming Protocol`. This is a separate check from the blacklist above: it runs **even when Enable Bot protection is off**, and the value must match exactly — any prefix or suffix is rejected with this same message.

Server logs show: 

`🔴 Invalid API key`

- **Issue:** The `X-Api-Key` header for Streaming Protocol is missing or incorrect.
- **Solution:** Ensure your request includes the `X-Api-Key` header with the correct value as configured in the Client Tag.

Server logs show: 

`🔴 Add API key for Streaming Protocol is not enabled.`

- **Issue:** the request declares `event_origin: "Streaming Protocol"` but **"Add API key for Streaming Protocol" is not enabled** in the Server-side Client Tag. The API key is mandatory for this origin: with the option off there is no key to compare against, so every Streaming Protocol request is refused with `403`, whether or not it carries an `X-Api-Key` header. Requests with `event_origin: "Website"` are not affected and keep working.
- **Solution:** open the Server-side Client Tag, enable **Add API key for Streaming Protocol**, set a key, publish the container, and send that same value in the `X-Api-Key` header of your backend requests.

Server logs show: 

`🔴 Invalid cookie format`

- **Issue:** The `na_u` or `na_s` cookie does not match the expected alphanumeric format (15 characters for `na_u`, or the specific `client_id_session_id-page_id` structure for `na_s`).
- **Solution:** Ensure cookies haven't been manually tampered with. If using the **Streaming Protocol**, verify that you are passing the cookies in the exact format generated by the website tracker.

Server logs show: 

`🔴 Request method not correct`

- **Issue:** The incoming request was not sent using the correct HTTP method.
- **Solution:** The server expects the data via `POST`. Ensure your client-side implementation is correctly configured to use POST requests.

Server logs show: 

`🔴 Invalid event_origin parameter value. Accepted values: Website`

`🔴 Invalid event_origin parameter value. Accepted values: Website or Streaming Protocol`

- **Issue:** The `event_origin` parameter is missing or incorrect.
- **Solution:** Ensure the client-side tracker or your streaming implementation is correctly setting the origin to "Website" or "Streaming Protocol".

Server logs show: 

`🔴 Invalid event_name. Can't send page_view from Streaming Protocol`

- **Issue:** Sequence error: `page_view` cannot be sent via Streaming Protocol.
- **Solution:** Use the website tracker for `page_view` events.

Server logs show: 

`🔴 Missing required parameters: [parameters]`

- **Issue:** The server rejected the JSON payload because it's missing one or more mandatory top-level fields: `page_id`, `page_date`, `page_data`, `event_origin`, `event_date`, `event_timestamp`, `event_name`, `event_id`, `event_data`.
- **Solution:** If you are using the standard GTM tags, this shouldn't happen. If implementing a custom tracker or using the **Streaming Protocol**, verify that the JSON payload includes all the mandatory root fields listed above.



## Google Consent Mode
Nameless Analytics is deeply integrated with GCM. If consent isn't handled correctly, data might be lost or delayed.


Browser console shows: 

`[event_name] > 🔴 analytics_storage denied`

- **Issue:** Tracking is blocked by Google Consent Mode.
- **Solution:** This is expected behavior for users who opt-out. If events never fire even after consent is granted, the tracker automatically queues events if `analytics_storage` is pending. If they never release, verify that your Consent Management Platform (CMP) correctly triggers a `gtag('consent', 'update', ...)` call.

Browser console shows: 

`[event_name] > 🔴 Google Consent Mode not found`

- **Issue:** If "Respect Google Consent Mode" is enabled but GCM isn't active, the tag aborts.
- **Solution:** Ensure that a Google Consent Mode default consent command (e.g., via a CMP or a Custom HTML tag) is executed *before* the GTM container loads.



## Library Loading & Configuration Issues
The tracker requires its core libraries and a valid configuration to initiate.


Browser console shows: 

`[event_name] > 🔴 Tracker configuration error: event has invalid Nameless Analytics Client-side Tracker Configuration Variable`

- **Issue:** The tag is missing the required config variable or it's incorrectly set.
- **Solution:** Check the "Configuration Variable" field in the tag and ensure it points to a valid NA Config Variable.

Browser console shows: 

`[event_name] > 🔴 Main library not loaded from: [URL]`

`[event_name] > 🔴 UA parser library not loaded from: [URL]`

- **Issue:** The browser couldn't fetch the core tracker scripts, often due to ad-blockers blocking `jsdelivr.net`.
- **Solution:** Verify the library URL or check for ad-blockers. For a robust setup, use **First-Party mode** by hosting scripts on your own sub-domain (e.g., `https://gtm.yourdomain.com/lib/nameless-analytics_vX.X.X.min.js`). Note that the file name is built by the tag from the library version: you configure only the domain and the path, never the file name. See [How to set up First-Party Library Hosting](SETUP-GUIDES.md#how-to-set-up-first-party-library-hosting).

Browser console shows: 

`[event_name] > 🔴 Permission denied: unable to load Main library from [URL]`

`[event_name] > 🔴 Permission denied: unable to load UA parser library from [URL]`

- **Issue:** The GTM Sandbox is blocking the external script loading.
- **Solution:** Ensure the library URL is added to the **Inject Scripts** permission in the template settings.



## Storage & Cloud Permissions
Errors occurring when the server attempts to persist data to Firestore or BigQuery.


Server logs show: 

`🔴 User or session data not created to Firestore`

`🔴 User or session data not added to Firestore`

`🔴 User or session data not updated to Firestore`

- **Issue:** The Firestore write operation failed.
- **Solution:** Verify the Google Cloud Project permissions and quotas. Ensure the **Service Account** running your GTM Server (e.g., the Cloud Run or App Engine default service account) has the `roles/datastore.user` role. Also, verify that Firestore is initialized in **Native Mode**, as Datastore Mode is not supported.

Server logs show: 

`🔴 Payload data not inserted into BigQuery`

- **Issue:** The streaming insert to BigQuery failed.
- **Solution:** Check BigQuery dataset/table permissions. Ensure the service account has `roles/bigquery.dataEditor`. Ensure you have created the schema using the provided SQL scripts. 

Server logs show: 

`🔴 Firestore request failed`

`🔴 BigQuery request failed`

`🔴 Custom endpoint request failed`

`🔴 Request processing failed`

- **Issue:** these four messages are different from the ones above. The messages above are **handled** failures: the write was attempted and the service answered with an error. These four are raised when the processing chain throws an **unexpected** exception at a given stage, so the tag never gets an answer to report. They are the only responses returned with `status_code: 500`, and the underlying error object is printed on the line right after the message in GTM Server Preview.
- **Solution:** read that error object first, it carries the actual cause. Typical ones are a Firestore document that exceeded the [1 MiB limit](../README.md#known-limitations-firestore-1-mib-document-limit), a payload whose types do not match the BigQuery schema, a service temporarily unreachable, or an unreachable custom endpoint URL. `🔴 Request processing failed` is the fallback for an exception raised outside the three stages.

The stage that failed is also readable in the `processing` object of the response, which reports `success`, `failed`, `skipped` or `pending` for each step: everything after the failing stage is marked `skipped`, and the event is not stored.

> **A failing custom endpoint does not fail the event.** If Firestore and BigQuery succeeded and only the forwarding failed, the response is still `200` with `🟢 Request processed successfully`, and the failure is visible only as `custom_endpoint: failed` in the `processing` object. The event is stored: nothing needs to be resent, only the forwarding was lost.



## BigQuery & Data Analysis Issues
Common issues related to missing data or unexpected values in reporting.

### BigQuery Advanced Runtime
If you experience slow query performance or errors with SQL Table Functions, ensure that **BigQuery Advanced Runtime** is enabled for your project (see [TABLES.md](../tables/TABLES.md) for the DDL command).

- **Issue:** the setup script fails on the last statement with a permission error mentioning `ALTER PROJECT`.
- **Solution:** enabling the Advanced Runtime requires the project level `bigquery.projects.update` permission, which a dataset level role does not grant. The statement runs last on purpose, so dataset and tables are already created and the platform works normally: ask a project administrator to run that single statement, or skip it and accept the default runtime.

### Missing Geolocation Data
- **Issue:** The `country` and `city` fields are `null` in BigQuery.
- **Solution:** Nameless Analytics relies on server-provided headers. Ensure your environment is configured to forward geolocation:
  - **App Engine:** Forward `X-Appengine-Country` and `X-Appengine-City`.
  - **Cloud Run:** Configure the Load Balancer to include `X-Gclb-Country: {client_region}` and `X-Gclb-City: {client_city}`. Note that `{client_region}` holds the country code, not the region.
  - **Stape:** Enable the "GEO Headers" power-up, which provides `X-GEO-Country` and `X-GEO-City`.

### Unexpected Channel Grouping
- **Issue:** Events are categorized as `referral` instead of expected channels like `paid_search` or `organic_social`.
- **Solution:** Nameless Analytics uses a server-side regex system based on `source` and `campaign`. Verify your traffic sources against the [standard grouping rules](../README.md#channel-grouping-logic). If a source is not in the list, it will default to `referral` (or `affiliate` if a campaign is present).



## Network & Custom Endpoint Issues
Technical issues preventing communication between the browser and the GTM Server, or between the server and external destinations.


Browser console shows: 

`[event_name] > 🔴 Request not sent successfully`

- **Issue:** The network request from the browser failed to reach the server.
- **Solution:** Check for client-side connectivity issues, local firewalls, or DNS misconfigurations for your server-side endpoint.

- **Issue:** The payload is larger than 64 KB. Requests are sent with the `keepalive` flag, so they survive the page being closed, but browsers cap the body of a `keepalive` request at **64 KiB**: above that the request is rejected before leaving the browser and the event is lost. The line above in the console (`[event_name] > 🔴 TypeError: Failed to fetch`) confirms it, and the request never appears in the Network tab.
- **Solution:** Reduce the payload. The usual causes are [Add current dataLayer state](https://github.com/nameless-analytics/client-side-tracker-configuration-variable#add-current-datalayer-state) on a page with a large `dataLayer` and very long `ecommerce` item arrays. Inspect the size with the snippet below, then disable the dataLayer state, or send only the parameters you need as event parameters.

  ```javascript
  // Size in KB of the current dataLayer, the heaviest optional part of the payload
  Math.round(new Blob([JSON.stringify(window.dataLayer)]).size / 1024 * 10) / 10
  ```

  Note that the 64 KiB budget is shared with every other in-flight `keepalive` request and `navigator.sendBeacon()` call of the page, including those of other vendors' tags, so the effective ceiling is lower than 64 KiB when several tags fire together.

Browser console shows: 

`[event_name] > 🔴 [error]`

- **Issue:** A generic JavaScript error occurred during the fetch request.
- **Solution:** Check the browser console for details.

Browser console shows: 

`[event_name] > 🔴 Request aborted`

- **Issue:** A generic issue stopped the tag execution.
- **Solution:** Check the previous logs in the console to find the specific cause.

Server logs show: 

`🔴 Request not sent successfully. Error: [result]`

- **Issue:** Forwarding to the custom endpoint failed.
- **Solution:** Verify the custom endpoint URL and ensure your server-side environment has the necessary network access.


## Cross-domain Issues

### Link Not Decorated (`na_id` Missing)

Browser console shows:

```text
cross-domain > 🔴 Error while fetching user data: [error]
```

- **Issue:** The cross-domain listener failed to retrieve user data from the server.
- **Solution:** Verify that the Server-side Client Tag endpoint is reachable and correctly configured.

Server logs show:

```text
🔴 User cookie not found. No cross-domain URL decoration will be applied
```

```text
🔴 Session cookie not found. No cross-domain URL decoration will be applied
```

- **Issue:** The server could not find the required user or session cookie while handling the `get_user_data` request.
- **Solution:** Ensure the visitor has valid `na_u` and `na_s` cookies before clicking a configured cross-domain link.

Server logs show:

```text
🟠 Invalid cross-domain ID format. Value ignored.
```

- **Issue:** The `cross_domain_id` received in the payload does not match the format of a valid `session_id` (15 alphanumeric characters, an underscore, 15 alphanumeric characters).
- **Result:** The value is discarded and a new session is created. The event is still processed and stored normally.
- **Solution:** If you are generating `na_id` manually, verify that the `session_id` you encode is a real one issued by the server. See [Cross-domain Architecture](../README.md#cross-domain-architecture).

**Caveat:** the handshake is driven by a `click` listener, so it only runs on a plain left click on an `<a href>`. The decoration does **not** run when the link is opened through the right-click menu (“Open in new tab” / “Open in new window”), with a keyboard modifier (`Cmd`/`Ctrl`+click, `Shift`+click, `Alt`+click) or with the middle mouse button, and when the navigation does not come from a link at all (JS button, `window.open()`, form submit, pasted URL, bookmark).

Modified clicks are ignored **on purpose**: intercepting them would cancel the browser's native behaviour and force the destination into the current tab, against the visitor's intent. The trade-off is a new session on the destination instead of a broken navigation.

No console message is logged in these cases, because the tracker never takes over the click: the absence of `cross-domain > ASK USER DATA` in the console of the source page is the signal. See [When link decoration does not happen](../README.md#when-link-decoration-does-not-happen) for the complete list.

### Invalid or Expired `na_id`

The destination domain may display one of the following browser console messages.

#### Unable to Decode `na_id`

```text
[page_view] > 🔴 Invalid cross-domain ID: unable to decode na_id
```

- **Issue:** The `na_id` URL parameter is not a valid Base64-encoded value.
- **Result:** The value is ignored and `cross_domain_id` remains `null`.

#### Invalid Format

```text
[page_view] > 🔴 Invalid cross-domain ID: invalid format
```

- **Issue:** The decoded value does not follow the expected `{session_id}.{decoration_timestamp_ms}` structure.
- **Result:** The value is ignored and `cross_domain_id` remains `null`.

#### Invalid `session_id` Format

```text
[page_view] > 🔴 Invalid cross-domain ID: invalid session_id format
```

- **Issue:** The decoded value has the expected `{session_id}.{decoration_timestamp_ms}` structure, but the `session_id` does not match the required format: 15 alphanumeric characters, an underscore, 15 alphanumeric characters.
- **Result:** The value is ignored and `cross_domain_id` remains `null`.

#### Expired Cross-domain ID

```text
[page_view] > 🟠 Expired cross-domain ID
```

- **Issue:** More than five minutes elapsed between URL decoration and execution of the first `page_view` on the destination page.
- **Result:** The expired `session_id` is ignored and `cross_domain_id` remains `null`.

#### Invalid Cross-domain ID

```text
[page_view] > 🔴 Invalid cross-domain ID
```

- **Issue:** The decoded value contains an invalid timestamp or a timestamp in the future.
- **Result:** The value is ignored and `cross_domain_id` remains `null`.

#### Valid Cross-domain ID

```text
[page_view] > 🟢 Valid cross-domain ID
```

- **Result:** The value was decoded and validated successfully. The original `session_id` is added to the event payload as `cross_domain_id`.

If no cross-domain ID validation message is displayed, verify that:
- cross-domain tracking is enabled
- the destination URL contains the `na_id` parameter
- the Client-side Tracker Tag fires on the first `page_view`
- the current event is the first `page_view` of the current physical page
- all involved domains use compatible versions of the main library and the Client-side Tracker Tag.

# 

[Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_troubleshooting_guide) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)

