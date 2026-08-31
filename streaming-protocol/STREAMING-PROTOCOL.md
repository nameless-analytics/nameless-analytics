# Nameless Analytics | Streaming Protocol

The Nameless Analytics Streaming Protocol is a specialized implementation for sending data directly to the [Nameless Analytics Server-side Client Tag](https://github.com/nameless-analytics/server-side-client-tag/).

For an overview of how Nameless Analytics works [start from here](../README.md#overview).


### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change



## Table of Contents

- [Overview](#overview)
- [Request requirements](#request-requirements)
- [Payload](#payload)
- [Reference implementations](#reference-implementations)
  - [Install](#install)
  - [Configure](#configure)
  - [Run and verify](#run-and-verify)



## Overview

Use the Streaming Protocol to send conversions, backend interactions and offline events to an existing Nameless Analytics user and session. The Server-side Client Tag validates the request, retrieves the user and session context from Firestore, and writes the enriched event to BigQuery.

The protocol does not create website context: send `page_view` through the Client-side Tracker Tag first. Do not use the Streaming Protocol for `page_view` or the `get_user_data` cross-domain handshake.

Streaming Protocol events are stored in the session but excluded from the default `session_duration_sec` and `time_on_page` calculations, which remain based on website activity.


## Request requirements

| Component | Required value |
|:---|:---|
| Method | `POST` |
| `Content-Type` | `application/json` |
| `Origin` | Your website origin, for example `https://example.com`. It must match the Server-side Client Tag configuration when authorized-origin filtering is enabled |
| `User-Agent` | Exactly `Nameless Analytics - Streaming Protocol` |
| `X-Api-Key` | The key configured in the Server-side Client Tag |
| `Cookie` | `na_u={client_id}; na_s={client_id}_{session_id}-{page_id}` using the original website identifiers |
| `X-Gtm-Server-Preview` | Optional preview header for GTM Server debugging |

Each identifier segment contains 15 alphanumeric characters. If you changed the cookie prefix in the Server-side Client Tag, use the corresponding cookie names instead of `na_u` and `na_s`.

> [!IMPORTANT]
> Store the full `na_s` value together with the date of the page view you want to attach the backend event to. `page_date` cannot be derived from the cookie and is required to query the correct `events_raw` partition.

Treat `X-Api-Key` as a server-side secret and load it from an environment variable or secret manager in production. `Origin` is an additional filter, not a substitute for authentication.

The JSON body must follow these rules:

| Field | Requirement |
|:---|:---|
| `page_date`, `event_date` | Real calendar dates in `YYYY-MM-DD` format |
| `page_id` | The 15-character segment after `-` in `na_s` |
| `page_data` | Non-empty object containing `page_title`, `page_hostname`, `page_url`, `page_path` and a positive integer `page_load_timestamp` |
| `event_timestamp` | Positive Unix timestamp in milliseconds |
| `event_id` | `{page_id}_{random_id}`, where both segments contain 15 alphanumeric characters |
| `event_name` | Non-empty backend or offline event name; not `page_view` or `get_user_data` |
| `event_origin` | Exactly `Streaming Protocol` |
| `event_data` | Non-empty object with `event_type: "event"` and the required nullable attribution fields shown below |
| `user_data`, `session_data` | Optional JSON object or `null`; an empty object is allowed |
| `gtm_data` | Optional JSON object or `null`; values must be strings, integers or `null` |
| `consent_data` | Optional non-empty JSON object or `null`; values must be strings or `null` |
| `ecommerce` | Optional JSON object or `null`; an empty object is allowed |
| `datalayer` | Optional JSON array or `null`; an empty array is allowed |

Except for `session_data.user_id`, `user_data` and `session_data` must not contain the server-managed names documented as reserved parameters in the [Server-side Client Tag](https://github.com/nameless-analytics/server-side-client-tag/#user-data). Requests containing them are rejected with `400 Bad Request` before storage.

Unknown top-level fields are rejected. Put custom parameters inside the appropriate scoped object. Invalid cookies or payloads return `400`; authentication and User-Agent failures return `401` or `403`. See the [Troubleshooting Guide](../setup-guides/TROUBLESHOOTING-GUIDE.md) for individual responses.


## Payload

This is a minimal valid `purchase` request body:

```json
{
  "page_date": "2026-04-08",
  "page_id": "WVTWEorF69ZEk3y",
  "page_data": {
    "page_title": "Checkout",
    "page_hostname": "example.com",
    "page_url": "https://example.com/checkout",
    "page_path": "/checkout",
    "page_load_timestamp": 1775606400000
  },
  "event_date": "2026-04-08",
  "event_timestamp": 1775606400000,
  "event_id": "WVTWEorF69ZEk3y_XIkjlUOkXKn99IV",
  "event_name": "purchase",
  "event_origin": "Streaming Protocol",
  "event_data": {
    "event_type": "event",
    "source": "direct",
    "campaign": null,
    "campaign_id": null,
    "campaign_click_id": null,
    "campaign_term": null,
    "campaign_content": null
  },
  "ecommerce": {
    "transaction_id": "T_12345",
    "value": 25.5,
    "currency": "EUR",
    "items": [
      {
        "item_id": "SKU_001",
        "item_name": "Product Name",
        "price": 25.5,
        "quantity": 1
      }
    ]
  }
}
```

Do not include `client_id` or `session_id` in the body: the server derives them from the cookies. Send only the partial `page_id` and `event_id`; the server adds the user and session prefix before storage. It also calculates `channel_grouping` from the `source` and campaign values supplied in `event_data`. See [Server-side ID Management](../README.md#server-side-id-management) for the resulting full identifiers.


## Reference implementations

The included [Python](streaming-protocol.py) and [JavaScript](streaming-protocol.js) scripts are proofs of concept. They query `events_raw` with the full `na_s` cookie and `page_date`, rebuild the required page context and send the request.

The Streaming Protocol does not perform this BigQuery lookup for you. A production caller must either reproduce it or persist the required `page_data` when the website event is collected. Keep API keys and Google Cloud credentials outside the source code.


### Install

Python:

```bash
pip install requests google-cloud-bigquery
```

Node.js:

```bash
npm install @google-cloud/bigquery
```


### Configure

Edit the selected script:

| Setting | Value |
|:---|:---|
| `na_s` | Full session cookie captured from the website event. The script derives `na_u` from it |
| `page_date` | Date of that page view in `YYYY-MM-DD` format |
| `full_endpoint` | GTM Server endpoint, for example `https://gtm.example.com/tm/nameless` |
| `origin` | Website origin allowed by the Server-side Client Tag |
| `api_key` | API key configured in the Server-side Client Tag |
| `gtm_preview_header` | Optional GTM Server preview header |
| `project_id`, `dataset_id`, `table_id` | BigQuery location of `events_raw` |
| `credentials_path` | Service account key with BigQuery Data Viewer and BigQuery Job User access |
| `event_name`, `user_id`, `ecommerce_data` | Event, optional user ID and business data to send |

For production, prefer workload identity or secret-managed credentials over a service account key file.


### Run and verify

Run one implementation from the `streaming-protocol` directory:

```bash
python streaming-protocol.py
```

```bash
node streaming-protocol.js
```

A correct run retrieves the page context, sends the request and ends with:

```text
NAMELESS ANALYTICS
STREAMING PROTOCOL
👉 Retrieve page data from BigQuery for page_id: [PAGE ID] on [PAGE DATE]
  🟢 Page data retrieved from BigQuery
👉 Send request to [FULL ENDPOINT]
   🟢 Request processed successfully
Function execution end: 👍
```

In the JSON response, confirm `status_code: 200`, `response: "🟢 Request processed successfully"` and these `processing` results:

| Step | Expected result |
|:---|:---|
| `claim_request` | `success` |
| `firestore` | `success` |
| `bigquery` | `success` |
| `custom_endpoint` | `success` or `skipped` when disabled |

If the response differs, the request was not fully processed. Use the `processing` object to identify the failed step, then see the [Troubleshooting Guide](../setup-guides/TROUBLESHOOTING-GUIDE.md).

#

[Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_streaming_protocol) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
