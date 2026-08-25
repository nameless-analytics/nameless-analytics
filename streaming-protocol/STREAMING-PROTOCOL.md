# Nameless Analytics | Streaming Protocol
The Nameless Analytics Streaming Protocol is a specialized implementation for sending data directly to the [Nameless Analytics Server-side Client Tag](https://github.com/nameless-analytics/server-side-client-tag).

For an overview of how Nameless Analytics works [start from here](../README.md#overview).

### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change 🚧



## Table of Contents

- [Introduction](#introduction)
  - [BigQuery enrichment](#bigquery-enrichment)
  - [Automatic type handling](#automatic-type-handling)
  - [Error handling](#error-handling)
  - [Security](#security)
- [Validation requirements](#validation-requirements)
  - [Mandatory headers](#mandatory-headers)
  - [Mandatory fields](#mandatory-fields)
  - [Data formats](#data-formats)
- [JSON Payload Structure](#json-payload-structure)
  - [Example Payload](#example-payload)
- [Implementation](#implementation)
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Usage](#usage)



## Introduction
The Streaming Protocol is designed for secondary interactions (conversions, backend events, offline data).

These events are sent to the Server-side Client Tag, which enriches them and writes them to BigQuery just like standard tracking events.

Events sent via the Streaming Protocol **do not extend the session duration** (`session_duration_sec`). By default, duration calculation remains based exclusively on on-site events (`event_origin = 'Website'`).

**`page_view` events are not allowed** via the Streaming Protocol and must be sent through the standard website tracker to correctly initialize the session context.


### BigQuery enrichment
Automatically retrieves page_data from the BigQuery `events_raw` table based on the `na_s` cookie (`page_id` is equal to `na_s`) and on the date of that page view. This ensures that offline or backend events are seamlessly tied to the user's original session and page, inheriting source, campaign, and user metadata without breaking the journey.

> **Store the page date alongside the cookie.** The lookup filters on `event_date`, the partition key of `events_raw`: without it BigQuery has no way to narrow the search and every single event would scan the whole table. The date works as a partition filter because a page always carries the date of the event that created it, so the `page_view` that opened the page is guaranteed to sit in that partition. `page_date` cannot be derived from the `na_s` cookie, so when you save the cookie value for later use you must also save the date of the page view you want the conversion to be attached to, and pass it as `page_date` in `YYYY-MM-DD` format.


### Automatic type handling
Correctly maps BigQuery data types (`string`, `int`, `float`, `json` and `bool`) to the JSON payload.


### Error handling 
Includes robust error handling for API responses and database queries.
 

### Security
Supports API Key authentication for secure server-side ingestion.



## Validation requirements
To ensure requests are accepted by the server, following requirements must be met:

### Mandatory headers
- **User-Agent**: You must use the following User-Agent: `Nameless Analytics - Streaming Protocol`. Any deviation will result in a 403 error.
- **API Key**: The `X-Api-Key` header must match your Server-side Client Tag configuration.
- **Cookie**: The HTTP request must include the `Cookie` header containing `na_u={client_id}; na_s={na_s_cookie}`. This is the **only** source of truth used by the server to identify the user and session. **Note**: `na_u` must be exactly 15 alphanumeric characters, and `na_s` must follow the `client_id_session_id-page_id` structure (15 characters for each segment). Any deviation will result in a `403 Invalid cookie format` error.


### Mandatory fields
The JSON payload must include the following top-level fields:
`page_id`, `page_date`, `page_data`, `event_origin`, `event_date`, `event_timestamp`, `event_name`, `event_id`, `event_data`.


### Data formats
- **Dates**: Must be strings in `YYYY-MM-DD` format (e.g., `2026-04-08`).
- **Timestamps**: Must be an integer representing Unix timestamp in **milliseconds** (e.g., `1712604000000`).



## JSON Payload Structure
The Streaming Protocol requires a POST request with a JSON body.

### Example Payload
```json
{
  "user_data": {}, // Optional

  "session_data": { // Optional
    "user_id": "abcd" // Optional
  },
         
  "page_date": "2026-04-08", // Automatically retrieved from BigQuery if page_id exists in BigQuery
  "page_id": "WVTWEorF69ZEk3y", // Extracted from na_s cookie
  "page_data": {}, // Automatically retrieved from BigQuery if page_id exists in BigQuery

  "event_date": "2026-04-08",
  "event_timestamp": 1712604000000,
  "event_id": "WVTWEorF69ZEk3y_XIkjlUOkXKn99IV", // Automatically generated based on na_s cookie
  "event_name": "purchase",
  "event_origin": "Streaming Protocol", // Do not modify
  "event_data": {
    "event_type": "event", // Do not modify
    "source": "direct", // Do not modify
    "campaign": null, // Do not modify
    "campaign_id": null, // Do not modify
    "campaign_click_id": null, // Do not modify
    "campaign_term": null, // Do not modify
    "campaign_content": null // Do not modify
  },

  "ecommerce": { // Optional
    "transaction_id": "T_12345",
    "value": 25.50,
    "currency": "EUR",
    "items": [
      {
        "item_id": "SKU_001",
        "item_name": "Product Name",
        "price": 25.50,
        "quantity": 1
      }
    ]
  },

  "gtm_data": {}, // Optional

  "consent_data": { // Optional
    "consent_type": "Update",
    "respect_consent_mode": "Yes",
    "ad_user_data": "Granted",
    "ad_personalization": "Granted",
    "ad_storage": "Granted",
    "analytics_storage": "Granted",
    "functionality_storage": "Granted",
    "personalization_storage": "Granted",
    "security_storage": "Granted"
  }
}
```

> **Note on `event_type`**: For the Streaming Protocol, set always `event_type` to `event`, as `page_view` is restricted to the website tracker, since **`page_view` events are not allowed** via the Streaming Protocol.

> **Note on `event_origin`**: This must be set to `Streaming Protocol` to allow API Key authentication and distinguish server-side events.

> **Note on `channel_grouping`**: You don't need to provide this parameter. The [Server-side Client Tag](https://github.com/nameless-analytics/server-side-client-tag) will automatically calculate it based on the `source` and `campaign` parameters provided in the `event_data` object.

> **Note on ID Management**: The tracking of `client_id` and `session_id` is exclusively handled through the HTTP `Cookie` header. Do not include them in the JSON payload, as the server will securely extract and assign them from the cookies context.



## Implementation

> **💡 Reference Implementations**: The provided scripts (`streaming-protocol.py` and `streaming-protocol.js`) act as **Proof of Concept (PoC)** to demonstrate the end-to-end data flow. In a production environment, developers should implement this logic dynamically (e.g., via AWS Lambda, Node.js backends, etc.) utilizing Environment Variables or Secret Managers for keys, rather than hardcoding them.

### Installation
 
1.  Clone the repository.
2.  Install the required dependencies:

    **For Python:**
    ```bash
    pip install requests google-cloud-bigquery
    ```

    **For Node.js:**
    ```bash
    npm install @google-cloud/bigquery
    ```
 

### Configuration
 
Open `streaming-protocol.py` or `streaming-protocol.js` and configure the following settings:
 
1. User Cookies and page date:
    - Set the `na_s` cookie value (the user unique identifier `na_u` will be automatically derived from it).
    - Set `page_date` to the date of the page view you want the event to be attached to, in `YYYY-MM-DD` format. It must be stored together with the cookie value at collection time: it is not derivable from `na_s`, and the BigQuery lookup uses it as the partition filter.
2. Request Settings:
    - `full_endpoint`: Your GTM Server-side URL (e.g., `https://gtm.yourdomain.com/tm/nameless`).
    - `origin`: The allowed origin domain (e.g., `https://yourdomain.com`).
    - `api_key`: The API key matching your Client Tag configuration.
    - `gtm_preview_header`: (Optional) Your GTM Preview header for debugging.
3. BigQuery Settings:
    - `project_id`: Your Google Cloud Project ID.
    - `dataset_id`: Your BigQuery Dataset ID.
    - `table_id`: Your BigQuery Table ID (e.g., `events_raw`).
    - `credentials_path`: Path to your Google Cloud Service Account JSON key. *(Ensure this Service Account has at least the `BigQuery Data Viewer` and `BigQuery Job User` IAM roles).*
4. Event Settings:
    - `event_name`: Define the name of the conversion/event (e.g., `purchase`).
    - `ecommerce_data`: Provide relevant ecommerce or transaction data.


### Usage 
Run the script using your preferred language:
 
**Python:**
```bash
python streaming-protocol.py
```

**Node.js:**
```bash
node streaming-protocol.js
```
 
The script will:
1.  Connect to BigQuery to fetch the latest page context for the given session.
2.  Construct a robust event payload.
3.  Send the event to your GTM Server-side endpoint via the Streaming Protocol.
4.  Print the server response (or any errors) to the console.

**Expected Output:**
```text
NAMELESS ANALYTICS
STREAMING PROTOCOL
👉 Retrieve page data from BigQuery for page_id: [PAGE ID] on [PAGE DATE]
  🟢 Page data retrieved from BigQuery
👉 Send request to [FULL ENDPOINT]
   🟢 Request processed successfully
Function execution end: 👍
```

The last line before the outcome is the `response` field of the server reply, printed as is. `🟢 Request processed successfully` is the message of a fully processed event: the server returns it with `status_code: 200` only after Firestore, BigQuery and, when enabled, the custom endpoint have all completed. Any other value means the event was not stored — look it up in the [Troubleshooting Guide](../setup-guides/TROUBLESHOOTING-GUIDE.md).

Do not match on `🟢 Request claimed successfully`: that message belongs to the `get_user_data` cross-domain handshake, which the Streaming Protocol never performs.

# 

[Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_streaming_protocol) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)

