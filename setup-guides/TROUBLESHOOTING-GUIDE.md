# Nameless Analytics | Troubleshooting Guide

Use this guide to identify the cause of a failed request or an unexpected value. For an overview of the platform, [start here](../README.md#overview).

### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change

## Table of Contents

- [Quick diagnosis](#quick-diagnosis)
- [Server responses](#server-responses)
  - [How to read processing status](#how-to-read-processing-status)
  - [400 Bad Request](#400-bad-request)
  - [401 Unauthorized](#401-unauthorized)
  - [403 Forbidden](#403-forbidden)
  - [405 Method Not Allowed](#405-method-not-allowed)
  - [500 Internal Server Error](#500-internal-server-error)
  - [Custom endpoint forwarding failed](#custom-endpoint-forwarding-failed)
- [Browser-side issues](#browser-side-issues)
  - [Configuration and libraries](#configuration-and-libraries)
  - [Google Consent Mode](#google-consent-mode)
  - [Event sequence](#event-sequence)
  - [Request never sent](#request-never-sent)
  - [Cross-domain decoration](#cross-domain-decoration)
- [Data and reporting](#data-and-reporting)
  - [Missing geolocation data](#missing-geolocation-data)
  - [Unexpected channel grouping](#unexpected-channel-grouping)

## Quick diagnosis

Start from what you can see:

| What you see | Where to look |
|:---|:---|
| No request in the browser Network tab | Browser console and [Browser-side issues](#browser-side-issues) |
| A request with HTTP `400`, `401`, `403`, `405` or `500` | Response body, GTM Server Preview and the matching status below |
| HTTP `200` with `custom_endpoint: failed` | [Custom endpoint forwarding failed](#custom-endpoint-forwarding-failed) |
| A successful request but wrong or missing values | [Data and reporting](#data-and-reporting) |

The browser console shows client-side failures. GTM Server Preview shows whether the request reached the Server-side Client Tag and why it was accepted or refused. The Network tab connects the two: inspect its HTTP status and JSON response first.

## Server responses

A non-success response ends with:

```text
[event_name] > 🔴 Request refused
```

This line is only a summary. The actual cause is in the response message and GTM Server Preview.

### How to read processing status

The response `processing` object shows the outcome of each stage. Earlier stages may already have completed when a later one fails.

| Failure point | Firestore | BigQuery | Custom endpoint |
|:---|:---:|:---:|:---:|
| Validation or authorization | `skipped` | `skipped` | `skipped` |
| Firestore | `failed` | `skipped` | `skipped` |
| BigQuery | `success` | `failed` | `skipped` |
| Custom endpoint | `success` | `success` | `failed` |
| Unexpected exception | Check `processing` | Check `processing` | Check `processing` |

Do not retry an event only because custom endpoint forwarding failed: Firestore and BigQuery have already completed.

### 400 Bad Request

The request could not become a valid event. Firestore, BigQuery and custom forwarding are not executed.

| Server log | Meaning and action |
|:---|:---|
| `🔴 Invalid JSON request body` | The parsed body is not a JSON object. Send a JSON object using `POST`. A malformed or empty body can fail before this structured message is returned. |
| `🔴 Invalid payload schema: [details]` | Required fields are missing or invalid, or an unsupported top-level field was sent. Follow the details in the response and compare the payload with the documented schema. Put custom parameters inside the appropriate scoped data object. |
| `🔴 Invalid cookie format` | `na_u` or `na_s` does not use the expected format. Check that the cookies were issued by Nameless Analytics and were not modified. Streaming Protocol requests must pass the original website cookie values. |
| `🔴 Invalid event_name. Can't send page_view from Streaming Protocol` | `page_view` is reserved for website tracking. Send only supported offline or server-side events through the Streaming Protocol. |
| `🔴 Orphan event: missing user cookie. Trigger a page_view event first to create a new user and a new session` | The event has no user context. Ensure `page_view` is the first event and verify that the expected cookie exists. |
| `🔴 Orphan event: missing session cookie. Trigger a page_view event first to create a new session` | The event has no active session. The session may have expired or the event may have fired before `page_view`. |
| `🔴 Orphan event: user doesn't exist in Firestore. Trigger a page_view event first to create a new user and a new session` | The browser has an identifier that is not present in Firestore. Trigger `page_view` first to initialize the user. |
| `🔴 Orphan event: session doesn't exist in Firestore. Trigger a page_view event first to create a new session` | The requested session is not present in Firestore. Trigger `page_view` first to create the session. |
| `🔴 User cookie not found. No cross-domain URL decoration will be applied` | The cross-domain handshake could not find the user cookie. The navigation continues without `na_id`. |
| `🔴 Session cookie not found. No cross-domain URL decoration will be applied` | The cross-domain handshake could not find an active session. The navigation continues without `na_id`. |

### 401 Unauthorized

```text
🔴 Invalid API key
```

The Streaming Protocol request has a missing or incorrect `X-Api-Key`. Send the same value configured in the Server-side Client Tag.

### 403 Forbidden

The request is not allowed to proceed, or Firestore refused a handled write operation.

| Server log | Meaning and action |
|:---|:---|
| `🔴 Request origin not authorized` | The `Origin` header is missing or its Effective TLD+1 is not listed under **Authorized domains**. Add the bare domain name and ensure custom server-to-server requests send `Origin`. |
| `🔴 Request IP not authorized` | The source IP is listed under **Banned IPs**. Remove it if the match is not intentional. |
| `🔴 Missing User-Agent header. Request from bot` | No User-Agent was received. Use a normal browser for website events or the required Streaming Protocol User-Agent for backend events. |
| `🔴 Invalid User-Agent header value. Request from bot` | The User-Agent matches a blocked automation signature, or a Streaming Protocol request is not using exactly `Nameless Analytics - Streaming Protocol`. |
| `🔴 Add API key for Streaming Protocol is not enabled.` | The payload declares `Streaming Protocol`, but API-key validation is not configured. Enable **Add API key for Streaming Protocol**, publish the container and send the configured key in `X-Api-Key`. |
| `🔴 User or session data not created to Firestore` | Firestore could not create the user or session. |
| `🔴 User or session data not added to Firestore` | Firestore could not add a new session. |
| `🔴 User or session data not updated to Firestore` | Firestore could not update the existing state. |

For the three Firestore messages, verify the project, quotas, Firestore Native Mode and that the runtime service account has `roles/datastore.user`. BigQuery and custom forwarding are not attempted for that request. Although the current response is `403`, these messages describe a storage failure, not invalid caller credentials.

<details>
<summary>Blocked User-Agent signatures</summary>

- **HTTP Libraries:** `curl`, `wget`, `python`, `requests`, `httpie`, `go-http-client`, `java`, `okhttp`, `libwww`, `perl`, `axios`, `node`, `fetch`, `php`, `guzzle`, `ruby`, `faraday`, `rest-client`.
- **AI Agents & LLMs:** `gptbot`, `chatgpt`, `anthropic`, `claude`, `perplexity`, `bytespider`, `ccbot`.
- **SEO & Marketing Bots:** `ahrefs`, `semrush`, `dotbot`, `mj12`, `rogerbot`, `bot`, `crawler`, `spider`, `scraper`.
- **Automation & Security:** `nmap`, `zgrab`, `masscan`, `shodan`, `headless`, `phantomjs`, `selenium`, `puppeteer`, `playwright`, `cypress`, `electron`.

If you are using the **Streaming Protocol**, its exact User-Agent check runs even when general bot protection is disabled.

</details>

### 405 Method Not Allowed

```text
🔴 Request method not correct
```

The endpoint accepts `POST` only. This check runs before the request body is read, so opening the endpoint directly in a browser normally produces this response.

### 500 Internal Server Error

```text
🔴 Payload data not inserted into BigQuery
```

The BigQuery insert failed after Firestore completed. Verify the project, dataset, table schema, quotas and that the runtime service account has `roles/bigquery.dataEditor`. Custom forwarding is skipped.

An unexpected exception uses one of these messages:

```text
🔴 Firestore request failed
🔴 BigQuery request failed
🔴 Custom endpoint request failed
🔴 Request processing failed
```

Read the error immediately following the message in GTM Server Preview, then inspect `processing` to see which earlier stages completed. Common causes are a schema mismatch, an unavailable service or an unreachable custom endpoint.

### Custom endpoint forwarding failed

```text
🔴 Request not sent successfully. Error: [result]
```

The event was already stored in Firestore and BigQuery, but the optional outbound request received a non-success response or could not reach the Custom Endpoint. The Server-side Client Tag still returns HTTP `200` with `custom_endpoint: failed`.

Check the endpoint URL, authentication headers and network access. Do not resend the original analytics event solely because forwarding failed, as this may duplicate the BigQuery event.

## Browser-side issues

Configuration, library, consent and event-sequence failures usually end with:

```text
[event_name] > 🔴 Request aborted
```

Always read the preceding line: `Request aborted` is only the final outcome, not the cause.

### Configuration and libraries

| Browser log | Meaning and action |
|:---|:---|
| `[event_name] > 🔴 Tracker configuration error: event has invalid Nameless Analytics Client-side Tracker Configuration Variable` | The tag has no valid configuration variable. Select a valid Nameless Analytics configuration in the tag. This message can appear even when normal logs are disabled. |
| `[event_name] > 🔴 Unable to send request. Unauthorized domain: [hostname]` | The configuration has no endpoint for the current website. Add the hostname and its server-side endpoint to the configuration variable. |
| `[event_name] > 🔴 Invalid server-side endpoint domain: [domain]` | The configured endpoint domain contains an invalid protocol, path or host value. Enter only a valid domain name; configure the path separately. |
| `[event_name] > 🔴 Main library not loaded from: [URL]` | The main tracker library could not be downloaded. Check the URL, Content Security Policy and ad blockers; first-party hosting avoids third-party CDN blocking. |
| `[event_name] > 🔴 UA parser library not loaded from: [URL]` | The UA parser could not be downloaded. Check the URL, Content Security Policy and ad blockers. |
| `[event_name] > 🔴 Permission denied: unable to load Main library from [URL]` | The template lacks permission to load the main library URL. Add it to the template's **Inject Scripts** permission. |
| `[event_name] > 🔴 Permission denied: unable to load UA parser library from [URL]` | The template lacks permission to load the UA parser URL. Add it to the template's **Inject Scripts** permission. |

See [first-party library hosting](SETUP-GUIDES.md#how-to-set-up-first-party-library-hosting) for the recommended setup.

### Google Consent Mode

| Browser log | Meaning and action |
|:---|:---|
| `[event_name] > 🔴 analytics_storage denied` | Tracking is correctly paused because analytics consent is denied. If consent is later granted but events remain blocked, verify that the CMP sends a Consent Mode `update`. |
| `[event_name] > 🔴 Google Consent Mode not found` | **Respect Google Consent Mode** is enabled, but no Consent Mode default was available. Initialize consent before the GTM container loads. |

### Event sequence

| Browser log | Meaning and action |
|:---|:---|
| `[event_name] > 🔴 Event fired before a page view event. The first event on any page must be page_view.` | An interaction fired before its page context existed. Ensure `page_view` is the first Nameless Analytics event on every page load. |

### Request never sent

```text
[event_name] > 🔴 Request not sent successfully
```

The browser did not receive a readable Nameless Analytics response. Check the Network tab:

- if no request appears, inspect connectivity, the endpoint configuration and payload size;
- if the request appears, inspect its HTTP response, CORS headers and GTM Server Preview;
- if the response is not Nameless Analytics JSON, verify that the correct endpoint handled the request.

Large `dataLayer` states or ecommerce item arrays can exceed the browser's `keepalive` request limit. Reduce the payload and send only the parameters you need.

A preceding generic message such as `[event_name] > 🔴 [error]` contains the browser error that triggered this final line.

### Cross-domain decoration

```text
cross-domain > Google Consent Mode not found. Cross-domain decoration aborted.
```

Cross-domain tracking respects the same consent configuration as normal events. Initialize Consent Mode before GTM, or disable consent enforcement only when appropriate for your implementation.

```text
cross-domain > 🔴 Error while fetching user data: [error]
```

The source page could not complete the identity handshake. Verify that the endpoint is reachable, the involved domains are authorized and valid `na_u` and `na_s` cookies exist. Navigation continues without identity decoration.

The server may also log:

```text
🟠 Invalid cross-domain ID format. Value ignored.
```

The supplied session identifier is invalid. It is ignored and the event is still processed using the destination's own identity context.

On the destination, these messages all mean that `na_id` was ignored and a new or local session context was used:

| Browser log | Meaning |
|:---|:---|
| `[page_view] > 🔴 Invalid cross-domain ID: unable to decode na_id` | The URL value is not valid Base64. |
| `[page_view] > 🔴 Invalid cross-domain ID: invalid format` | The decoded token has an invalid structure. |
| `[page_view] > 🔴 Invalid cross-domain ID: invalid session_id format` | The embedded session ID is invalid. |
| `[page_view] > 🟠 Expired cross-domain ID` | The five-minute decoration window elapsed. |
| `[page_view] > 🔴 Invalid cross-domain ID` | The timestamp is invalid or in the future. |

Decoration runs only on normal link clicks. Modified clicks, browser “Open in new tab” actions and programmatic navigation may reach the destination without `na_id`; this preserves native browser navigation.

If no validation message appears, verify that cross-domain tracking is enabled, the destination URL contains `na_id`, and the Client-side Tracker Tag fires on the first `page_view`.

## Data and reporting

The request succeeded, but a value is missing or unexpected.

### Missing geolocation data

If `country` or `city` is `null`, verify that the server environment forwards one of the supported header pairs:

- App Engine: `X-Appengine-Country` and `X-Appengine-City`;
- Cloud Run load balancer: `X-Gclb-Country` and `X-Gclb-City`;
- Stape GEO Headers: `X-GEO-Country` and `X-GEO-City`.

### Unexpected channel grouping

Channel grouping is derived from `source` and `campaign`. Verify the incoming values against the [channel grouping rules](../README.md#channel-grouping-logic). An unknown source becomes `referral`, or `affiliate` when a campaign is present.

#

[Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_troubleshooting_guide) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
