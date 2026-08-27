# Nameless Analytics | Troubleshooting Guide
The Nameless Analytics Troubleshooting Guide identifies, explains, and resolves common issues encountered during implementation.
For an overview of how Nameless Analytics works [start from here](../README.md#overview).


### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change



## Table of Contents

- [Troubleshooting tip](#troubleshooting-tip)
- [Server responses](#server-responses)
  - [400 Bad Request](#400-bad-request)
  - [401 Unauthorized](#401-unauthorized)
  - [403 Forbidden](#403-forbidden)
  - [405 Method Not Allowed](#405-method-not-allowed)
  - [500 Internal Server Error](#500-internal-server-error)
  - [Custom endpoint forwarding failed](#custom-endpoint-forwarding-failed)
- [Browser-side issues](#browser-side-issues)
  - [Configuration variable and libraries](#configuration-variable-and-libraries)
  - [Google Consent Mode](#google-consent-mode)
  - [Event sequence](#event-sequence)
  - [Request never sent](#request-never-sent)
  - [Cross-domain decoration](#cross-domain-decoration)
- [Data and reporting](#data-and-reporting)
  - [Missing geolocation data](#missing-geolocation-data)
  - [Unexpected channel grouping](#unexpected-channel-grouping)



## Troubleshooting tip
The guide is split in three parts. **Server responses** covers everything the Server-side Client Tag answers with, grouped by HTTP status, so the status code you see in the Network tab takes you straight to the cause. **Browser-side issues** covers what can go wrong in the browser before a response exists. **Data and reporting** covers values that arrive wrong rather than requests that fail.

Use the **Browser console** to check tags execution status and event data sent to the server.

Use the **GTM Server Preview Mode** to check incoming events and how the Server-side Client Tag responds to them.

Inspect a network request to see the data sent by client from Preview and data response by server from Preview.



## Server responses
Every refusal carries the HTTP status that matches its cause, so the status alone tells you which family of problem you are looking at.

Whatever the status, the browser console closes with the same generic line:

```text
[event_name] > 🔴 Request refused
```
- **Issue:** The Server-side Client Tag refused the request. The console cannot tell you why: the reason is in the server response and in the GTM server debug view.
- **Solution:** Read the status code of the request in the Network tab, then look up that status below. The `processing` object of the response reports how far the request got.


### 400 Bad Request
The request never became a valid event: the body, the payload schema, the cookies or the event sequence do not allow it to be processed. Nothing is written to Firestore or BigQuery.

Server logs show:

```text
🔴 Invalid JSON request body
```
- **Issue:** the request body is not a JSON object. This covers a missing or empty body, malformed JSON, and JSON that parses correctly but is not an object — an array, a number, a string or `null`. The most common cause is not an implementation bug: opening the endpoint URL directly in a browser sends a `GET` with no body, and uptime checks or crawlers hitting the path do the same.
- **Solution:** send a `POST` whose body is a JSON object. If you are implementing a custom backend, check that the payload is serialised as an object and not wrapped in an array.
- **Result:** the response carries `claim_request: failed`, with Firestore, BigQuery and custom endpoint forwarding all `skipped`.

Server logs show:

```text
🔴 Invalid payload schema: [details]
```
- **Issue:** the body is valid JSON, but one or more fields are missing or have an invalid type, format, or relationship. The details identify every detected problem, for example an invalid date, a string timestamp, a malformed identifier, an array where an object is required, or an unsupported top-level parameter.
- **Solution:** compare the payload with the documented schema. Required dates must be real `YYYY-MM-DD` dates, timestamps must be positive integers, `page_id` and `event_id` must use their partial 15-character identifier format, and the required data containers and their system fields must have the documented types. Put custom parameters inside the appropriate scoped data object rather than at the payload root.
- **Result:** the request is refused before Firestore, BigQuery, or custom endpoint forwarding is called. The minimal `get_user_data` request is validated separately and requires only `event_name` and `event_origin`.

Server logs show:

```text
🔴 Invalid cookie format
```
- **Issue:** The `na_u` or `na_s` cookie does not match the expected alphanumeric format (15 characters for `na_u`, or the specific `client_id_session_id-page_id` structure for `na_s`).
- **Solution:** Ensure cookies haven't been manually tampered with. If using the **Streaming Protocol**, verify that you are passing the cookies in the exact format generated by the website tracker.

Server logs show:

```text
🔴 Invalid event_name. Can't send page_view from Streaming Protocol
```
- **Issue:** Sequence error: `page_view` cannot be sent via Streaming Protocol.
- **Solution:** Use the website tracker for `page_view` events.

Server logs show:

```text
🔴 Orphan event: missing user cookie. Trigger a page_view event first to create a new user and a new session
🔴 Orphan event: missing session cookie. Trigger a page_view event first to create a new session
```
- **Issue:** A user leaves a tab open for more than 30 minutes (default session timeout). When they return and click, the session cookie (`na_s`) has expired.
- **Solution:** This is expected defensive behavior to ensure data integrity. Nameless Analytics rejects these to avoid "zombie" sessions without attribution.

Server logs show:

```text
🔴 Orphan event: user doesn't exist in Firestore. Trigger a page_view event first to create a new user and a new session
🔴 Orphan event: session doesn't exist in Firestore. Trigger a page_view event first to create a new session
```
- **Issue:** Firestore does not contain a record for this user or session.
- **Solution:** Ensure the first event triggered on every page load is always a `page_view` to initialize the user and session profile in Firestore.

Server logs show:

```text
🔴 User cookie not found. No cross-domain URL decoration will be applied
🔴 Session cookie not found. No cross-domain URL decoration will be applied
```
- **Issue:** The server could not find the required user or session cookie while handling a `get_user_data` cross-domain handshake.
- **Solution:** Ensure the visitor has valid `na_u` and `na_s` cookies before clicking a configured cross-domain link.
- **Result:** the visitor reaches the destination without `na_id`, which starts a new session there. See [Cross-domain decoration](#cross-domain-decoration).


### 401 Unauthorized
The request identified itself as a Streaming Protocol call but the credentials do not match.

Server logs show:

```text
🔴 Invalid API key
```
- **Issue:** The `X-Api-Key` header for Streaming Protocol is missing or incorrect.
- **Solution:** Ensure your request includes the `X-Api-Key` header with the correct value as configured in the Client Tag.
- **Result:** the response carries a `WWW-Authenticate: ApiKey` header. This is the only status that means "your credentials are wrong": a missing key **configuration** answers `403` instead, see below.


### 403 Forbidden
The Server-side Client Tag acts as a security gateway. The request is well formed but is not allowed to proceed, either because it comes from somewhere it should not or because the destination refused the write.

Server logs show:

```text
🔴 Request origin not authorized
```
- **Issue:** The request came from a domain that is not in the **Authorized domains** table, or it carried no `Origin` header at all. The header is missing on server-to-server calls, so a Streaming Protocol implementation that does not set it is refused here as soon as the option is enabled.
- **Solution:** Add the domain to the **Authorized domains** table in the Server-side Client Tag configuration, as a bare host name without protocol (e.g., `example.com`, not `https://example.com`, which the field validation rejects). Only the Effective TLD+1 is compared, so one entry covers all subdomains. In a cross-domain setup list every domain involved, and make sure your backend sends the `Origin` header.

Server logs show:

```text
🔴 Request IP not authorized
```
- **Issue:** The request came from an IP address listed in the **Banned IPs** table.
- **Solution:** Remove the IP from the list if it's a false positive.

Server logs show:

```text
🔴 Missing User-Agent header. Request from bot
🔴 Invalid User-Agent header value. Request from bot
```
- **Issue:** The request was identified as an automated bot, a scraper, or originated from a common HTTP library.
- **Solution:** Nameless Analytics blocks requests from non-browser environments to ensure data quality. Testing must be performed from a standard, modern browser.

  The system currently blocks any User-Agent containing the following keywords:
  - **HTTP Libraries:** `curl`, `wget`, `python`, `requests`, `httpie`, `go-http-client`, `java`, `okhttp`, `libwww`, `perl`, `axios`, `node`, `fetch`, `php`, `guzzle`, `ruby`, `faraday`, `rest-client`.
  - **AI Agents & LLMs:** `gptbot`, `chatgpt`, `anthropic`, `claude`, `perplexity`, `bytespider`, `ccbot`.
  - **SEO & Marketing Bots:** `ahrefs`, `semrush`, `dotbot`, `mj12`, `rogerbot`, `bot`, `crawler`, `spider`, `scraper`.
  - **Automation & Security:** `nmap`, `zgrab`, `masscan`, `shodan`, `headless`, `phantomjs`, `selenium`, `puppeteer`, `playwright`, `cypress`, `electron`.

  If you are using the **Streaming Protocol**, the `User-Agent` must be exactly `Nameless Analytics - Streaming Protocol`. This is a separate check from the blacklist above: it runs **even when Enable Bot protection is off**, and the value must match exactly — any prefix or suffix is rejected with this same message.

Server logs show:

```text
🔴 Add API key for Streaming Protocol is not enabled.
```
- **Issue:** the request declares `event_origin: "Streaming Protocol"` but **"Add API key for Streaming Protocol" is not enabled** in the Server-side Client Tag. The API key is mandatory for this origin: with the option off there is no key to compare against, so every Streaming Protocol request is refused, whether or not it carries an `X-Api-Key` header. Requests with `event_origin: "Website"` are not affected and keep working.
- **Solution:** open the Server-side Client Tag, enable **Add API key for Streaming Protocol**, set a key, publish the container, and send that same value in the `X-Api-Key` header of your backend requests.
- **Result:** this is a configuration problem, not a credentials one, which is why it answers `403` and not the `401` above.

Server logs show:

```text
🔴 User or session data not created to Firestore
🔴 User or session data not added to Firestore
🔴 User or session data not updated to Firestore
```
- **Issue:** The Firestore write operation failed.
- **Solution:** Verify the Google Cloud Project permissions and quotas. Ensure the **Service Account** running your GTM Server (e.g., the Cloud Run or App Engine default service account) has the `roles/datastore.user` role. Also, verify that Firestore is initialized in **Native Mode**, as Datastore Mode is not supported.
- **Result:** BigQuery and the custom endpoint are marked `skipped`. Nothing is written to BigQuery, on purpose, so the two stores cannot drift apart.


### 405 Method Not Allowed
The endpoint accepts `POST` only. This is the very first check the tag performs, before the body is read.

Server logs show:

```text
🔴 Request method not correct
```
- **Issue:** The incoming request was not sent using the correct HTTP method.
- **Solution:** The server expects the data via `POST`. Ensure your client-side implementation is correctly configured to use POST requests.


### 500 Internal Server Error
Something failed that the tag could not handle: either a service answered with an error it cannot recover from, or the processing chain threw an unexpected exception.

Server logs show:

```text
🔴 Payload data not inserted into BigQuery
```
- **Issue:** The streaming insert to BigQuery failed.
- **Solution:** Check BigQuery dataset/table permissions. Ensure the service account has `roles/bigquery.dataEditor`. Ensure you have created the schema using the provided SQL scripts.

Server logs show:

```text
🔴 Firestore request failed
🔴 BigQuery request failed
🔴 Custom endpoint request failed
🔴 Request processing failed
```

- **Issue:** these four messages are different from the handled failures listed above and under `403`. Those are failures where the write was attempted and the service answered with an error. These four are raised when the processing chain throws an **unexpected** exception at a given stage, so the tag never gets an answer to report. The underlying error object is printed on the line right after the message in GTM Server Preview.
- **Solution:** read that error object first, it carries the actual cause. Typical ones are a Firestore document that exceeded the [1 MiB limit](../README.md#known-limitations-firestore-1-mib-document-limit), a payload whose types do not match the BigQuery schema, a service temporarily unreachable, or an unreachable custom endpoint URL. `🔴 Request processing failed` is the fallback for an exception raised outside the three stages.

The stage that failed is also readable in the `processing` object of the response, which reports `success`, `failed`, `skipped` or `pending` for each step: everything after the failing stage is marked `skipped`, and the event is not stored.


### Custom endpoint forwarding failed
Logged by the server, but the response is still `200`: the event itself was stored.

Server logs show:

```text
🔴 Request not sent successfully. Error: [result]
```

- **Direction:** Nameless Analytics Server-side Client → Custom Endpoint.
- **Issue:** The incoming analytics event already passed Firestore and BigQuery, but the subsequent outbound forwarding request received a non-success HTTP response or could not reach the configured Custom Endpoint. This is a **server-side forwarding error**, not the browser error described in [Request never sent](#request-never-sent).
- **Result:** The analytics event is stored in Firestore and BigQuery. The Server-side Client returns `200` with `🟢 Request processed successfully`, while the response reports `custom_endpoint: failed`. Only the optional forwarding was lost.
- **Solution:** Inspect `[result]`, verify the Custom Endpoint URL and authentication headers, and ensure the server-side environment has permission and network access to reach it. Do not resend the original analytics event solely because this forwarding failed.



## Browser-side issues
Problems that stop the tag before a server response exists. They are visible only in the browser console, and the request usually never appears in the Network tab.

Every one of these paths closes with the same line:

```text
[event_name] > 🔴 Request aborted
```
> [!NOTE]
> **`🔴 Request aborted` never tells you the cause.** It is the closing line of every path that stops the tag before the request is sent — invalid configuration variable, libraries not loaded, `inject_script` permission denied, Consent Mode missing, consent denied, event out of sequence. Always read the line above it.


### Configuration variable and libraries
The tracker requires its core libraries and a valid configuration to initiate.

Browser console shows:

```text
[event_name] > 🔴 Tracker configuration error: event has invalid Nameless Analytics Client-side Tracker Configuration Variable
```
- **Issue:** The tag is missing the required config variable or it's incorrectly set.
- **Solution:** Check the "Configuration Variable" field in the tag and ensure it points to a valid NA Config Variable.
- **Result:** this check runs before anything else, so its message is printed even when console logs are disabled: the log setting lives in the configuration variable, and cannot be read when the variable is invalid.

Browser console shows:

```text
[event_name] > 🔴 Main library not loaded from: [URL]
[event_name] > 🔴 UA parser library not loaded from: [URL]
```
- **Issue:** The browser couldn't fetch the core tracker scripts, often due to ad-blockers blocking `jsdelivr.net`.
- **Solution:** Verify the library URL or check for ad-blockers. For a robust setup, use **First-Party mode** by hosting scripts on your own sub-domain (e.g., `https://gtm.yourdomain.com/lib/nameless-analytics_vX.X.X.min.js`). Note that the file name is built by the tag from the library version: you configure only the domain and the path, never the file name. See [How to set up first-party library hosting](SETUP-GUIDES.md#how-to-set-up-first-party-library-hosting).

Browser console shows:

```text
[event_name] > 🔴 Permission denied: unable to load Main library from [URL]
[event_name] > 🔴 Permission denied: unable to load UA parser library from [URL]
```
- **Issue:** The GTM Sandbox is blocking the external script loading.
- **Solution:** Ensure the library URL is added to the **Inject Scripts** permission in the template settings.


### Google Consent Mode
Nameless Analytics is deeply integrated with GCM. If consent isn't handled correctly, data might be lost or delayed.

Browser console shows:

```text
[event_name] > 🔴 analytics_storage denied
```
- **Issue:** Tracking is blocked by Google Consent Mode.
- **Solution:** This is expected behavior for users who opt-out. If events never fire even after consent is granted, the tracker automatically queues events if `analytics_storage` is pending. If they never release, verify that your Consent Management Platform (CMP) correctly triggers a `gtag('consent', 'update', ...)` call.

Browser console shows:

```text
[event_name] > 🔴 Google Consent Mode not found
```
- **Issue:** If "Respect Google Consent Mode" is enabled but GCM isn't active, the tag aborts.
- **Solution:** Ensure that a Google Consent Mode default consent command (e.g., via a CMP or a Custom HTML tag) is executed *before* the GTM container loads.


### Event sequence
An **Orphan Event** is any interaction (click, scroll, etc.) fired before the `page_view` that establishes the session context. The tracker catches most of these in the browser, before the request leaves; the ones that reach the server are refused with `400`, see [400 Bad Request](#400-bad-request).

Browser console shows:

```text
[event_name] > CHECKING EVENT
[event_name] >   🔴 Event fired before a page view event. The first event on any page must be page_view.
[event_name] > REQUEST STATUS
[event_name] >   🔴 Request aborted
```

- **Issue:** An interaction event is fired before the `page_view` event has been dispatched.
- **Solution:** Nameless Analytics utilizes an internal fetch queue to manage requests, which prevents most race conditions. However, every event must be preceded by a `page_view` event. Ensure the page view is the first event sent at every page load.


### Request never sent
The request failed before the browser could read a Nameless Analytics response.

Browser console shows:

```text
[event_name] > 🔴 Request not sent successfully
```

- **Direction:** Client-side Tracker → Nameless Analytics Server-side Client.
- **Issue:** The browser did not complete the tracker request with a readable Nameless Analytics JSON response. The request may have failed before leaving the browser, may not have reached the server, or the browser may have been unable to read the response because of a network, DNS, CORS, or response-format problem. This message is **not related to Custom Endpoint forwarding**.
- **Result:** The browser alone cannot determine whether the event was stored. If no request appears in the Network tab, it did not leave the browser. If a request appears, inspect its response and the GTM Server Preview logs to determine how far processing progressed.
- **Solution:** Check the browser Network tab, client-side connectivity, local firewalls, DNS, CORS configuration, and the server-side endpoint.

- **Issue:** The payload is larger than 64 KB. Requests are sent with the `keepalive` flag, so they survive the page being closed, but browsers cap the body of a `keepalive` request at **64 KiB**: above that the request is rejected before leaving the browser and the event is lost. The line above in the console (`[event_name] > 🔴 TypeError: Failed to fetch`) confirms it, and the request never appears in the Network tab.
- **Solution:** Reduce the payload. The usual causes are [Add current dataLayer state](https://github.com/nameless-analytics/client-side-tracker-configuration-variable#add-current-datalayer-state) on a page with a large `dataLayer` and very long `ecommerce` item arrays. Inspect the size with the snippet below, then disable the dataLayer state, or send only the parameters you need as event parameters.

  ```javascript
  // Size in KB of the current dataLayer, the heaviest optional part of the payload
  Math.round(new Blob([JSON.stringify(window.dataLayer)]).size / 1024 * 10) / 10
  ```

  Note that the 64 KiB budget is shared with every other in-flight `keepalive` request and `navigator.sendBeacon()` call of the page, including those of other vendors' tags, so the effective ceiling is lower than 64 KiB when several tags fire together.

Browser console shows:

```text
[event_name] > 🔴 [error]
```

- **Issue:** A generic JavaScript error occurred during the fetch request.
- **Solution:** Check the preceding browser-console error and the corresponding request in the Network tab. This error is followed by `[event_name] > 🔴 Request not sent successfully`.


### Cross-domain decoration
Problems with the handshake that decorates outbound links, and with the `na_id` value once it reaches the destination.

Browser console shows:

```text
cross-domain > 🔴 Error while fetching user data: [error]
```

- **Issue:** The cross-domain listener failed to retrieve user data from the server.
- **Solution:** Verify that the Server-side Client Tag endpoint is reachable and correctly configured.

Server logs show:

```text
🟠 Invalid cross-domain ID format. Value ignored.
```

- **Issue:** The `cross_domain_id` received in the payload does not match the format of a valid `session_id` (15 alphanumeric characters, an underscore, 15 alphanumeric characters).
- **Result:** The value is discarded and a new session is created. The event is still processed and stored normally.
- **Solution:** If you are generating `na_id` manually, verify that the `session_id` you encode is a real one issued by the server. See [Cross-domain architecture](../README.md#cross-domain-architecture).

The server can also refuse the handshake because the identity cookies are missing: see `🔴 User cookie not found` and `🔴 Session cookie not found` under [400 Bad Request](#400-bad-request).

> [!NOTE]
> **Caveat:** the handshake is driven by a `click` listener, so it only runs on a plain left click on an `<a href>`. The decoration does **not** run when the link is opened through the right-click menu (“Open in new tab” / “Open in new window”), with a keyboard modifier (`Cmd`/`Ctrl`+click, `Shift`+click, `Alt`+click) or with the middle mouse button, and when the navigation does not come from a link at all (JS button, `window.open()`, form submit, pasted URL, bookmark).

Modified clicks are ignored **on purpose**: intercepting them would cancel the browser's native behaviour and force the destination into the current tab, against the visitor's intent. The trade-off is a new session on the destination instead of a broken navigation.

No console message is logged in these cases, because the tracker never takes over the click: the absence of `cross-domain > ASK USER DATA` in the console of the source page is the signal. See [When link decoration does not happen](../README.md#when-link-decoration-does-not-happen) for the complete list.

On the destination domain, the `na_id` value is validated on the first `page_view`. Each outcome below leaves `cross_domain_id` as `null` and the event is processed anyway, resolving identity from the destination's own cookies.

| Browser console shows | Issue |
|:---|:---|
| `[page_view] > 🔴 Invalid cross-domain ID: unable to decode na_id` | The `na_id` URL parameter is not a valid Base64-encoded value |
| `[page_view] > 🔴 Invalid cross-domain ID: invalid format` | The decoded value does not follow the expected `{session_id}.{decoration_timestamp_ms}` structure |
| `[page_view] > 🔴 Invalid cross-domain ID: invalid session_id format` | The structure is correct but the `session_id` is not 15 alphanumeric characters, an underscore, 15 alphanumeric characters |
| `[page_view] > 🟠 Expired cross-domain ID` | More than five minutes elapsed between URL decoration and the first `page_view` on the destination page |
| `[page_view] > 🔴 Invalid cross-domain ID` | The decoded value contains an invalid timestamp or a timestamp in the future |



If no cross-domain ID validation message is displayed at all, verify that:
- cross-domain tracking is enabled
- the destination URL contains the `na_id` parameter
- the Client-side Tracker Tag fires on the first `page_view`
- the current event is the first `page_view` of the current physical page
- all involved domains use compatible versions of the main library and the Client-side Tracker Tag.



## Data and reporting
The request succeeded, but a value arrived wrong or missing.


### Missing geolocation data
- **Issue:** The `country` and `city` fields are `null` in BigQuery.
- **Solution:** Nameless Analytics relies on server-provided headers. Ensure your environment is configured to forward geolocation:
  - **App Engine:** Forward `X-Appengine-Country` and `X-Appengine-City`.
  - **Cloud Run:** Configure the Load Balancer to include `X-Gclb-Country: {client_region}` and `X-Gclb-City: {client_city}`. Note that `{client_region}` holds the country code, not the region.
  - **Stape:** Enable the "GEO Headers" power-up, which provides `X-GEO-Country` and `X-GEO-City`.


### Unexpected channel grouping
- **Issue:** Events are categorized as `referral` instead of expected channels like `paid_search` or `organic_social`.
- **Solution:** Nameless Analytics uses a server-side regex system based on `source` and `campaign`. Verify your traffic sources against the [standard grouping rules](../README.md#channel-grouping-logic). If a source is not in the list, it will default to `referral` (or `affiliate` if a campaign is present).

#

[Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_troubleshooting_guide) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
