# Nameless Analytics | Streaming Protocol
The Nameless Analytics Streaming Protocol is a specialized implementation for sending data directly to the [Nameless Analytics Server-side Client Tag](https://github.com/nameless-analytics/server-side-client-tag).

For an overview of how Nameless Analytics works [start from here](../README.md#high-level-data-flow).

### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change 🚧



## Table of Contents

- [Features](#features)
  - [Session enrichment](#session-enrichment)
  - [BigQuery enrichment](#bigquery-enrichment)
  - [Automatic type handling](#automatic-type-handling)
  - [Error handling](#error-handling)
  - [Security](#security)
- [JSON Payload Structure](#json-payload-structure)
  - [Example Payload](#example-payload)
- [Implementation](#implementation)
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Usage](#usage)

## Features
### Session enrichment
The Streaming Protocol is designed for secondary interactions (conversions, backend events, offline data). **`page_view` events are not allowed** via the Streaming Protocol and must be sent through the standard website tracker to correctly initialize the session context.

Events sent via the Streaming Protocol are recorded in BigQuery but **do not extend the session duration** (`session_duration_sec`). By default, duration calculation remains based exclusively on on-site events (`event_origin = 'Website'`).


### BigQuery enrichment
Automatically retrieves page_data from the BigQuery `events_raw` table based on the `na_s` cookie, allowing for enriching server-side events with the correct page context.


### Automatic type handling
Correctly maps BigQuery data types (`string`, `int`, `float`, `json` and `bool`) to the JSON payload.


### Error handling
Includes robust error handling for API responses and database queries.
 

### Security
Supports API Key authentication for secure server-side ingestion.


## Validation Requirements
To ensure requests are accepted by the server, following requirements must be met:

### Mandatory Headers
- **User-Agent**: To bypass bot protection, you must use following User-Agent: `Nameless Analytics - Streaming protocol`.
- **API Key**: The `x-api-key` header must match your Server-side Client Tag configuration.

### Mandatory Root Fields
The server validates the presence of following top-level fields:
`client_id`, `user_date`, `session_id`, `session_date`, `page_id`, `page_date`, `page_data`, `event_origin`, `event_date`, `event_timestamp`, `event_name`, `event_id`, `event_data`.

### Data Formats
- **Dates**: Must be strings in `YYYY-MM-DD` format (e.g., `2026-04-08`).
- **Timestamps**: Must be an integer representing Unix timestamp in **milliseconds** (e.g., `1712604000000`).


## JSON Payload Structure
The Streaming Protocol requires a POST request with a JSON body. While the server validates mandatory root fields, `event_type` is an optional but recommended field within `event_data` to maintain consistency with the BigQuery schema.

### Example Payload
```json
{
  "user_date": "2026-04-08",
  "client_id": "lZc919IBsqlhHks",
  "user_data": {},

  "session_date": "2026-04-08",
  "session_id": "lZc919IBsqlhHks_1KMIqneQ7dsDJU",
  "session_data": {
    "user_id": "abcd"
  },
        
  "page_date": "2026-04-08",
  "page_id": "lZc919IBsqlhHks_1KMIqneQ7dsDJU-WVTWEorF69ZEk3y",
  "page_data": {}, // Automatically enriched if page_id exists in BigQuery

  "event_date": "2026-04-08",
  "event_timestamp": 1712604000000,
  "event_id": "lZc919IBsqlhHks_1KMIqneQ7dsDJU-WVTWEorF69ZEk3y_XIkjlUOkXKn99IV",
  "event_name": "purchase",
  "event_origin": "Streaming protocol",
  "event_data": {
    "event_type": "event",
    "hostname": "yourdomain.com",
    "source": "backend",
    "campaign": "conversion_optimization"
  },

  "ecommerce": {
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

  "consent_data": {
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

> **Note on `event_type`**: In the standard website tracker, this is automatically set to `page_view` or `event`. For the Streaming Protocol, you should manually set it to `event` (as `page_view` is restricted to the website tracker).

> **Note on `event_origin`**: This must be set to `Streaming protocol` to allow API Key authentication and distinguish server-side events.

> **Note on `channel_grouping`**: You don't need to provide this parameter. The [Server-side Client Tag](https://github.com/nameless-analytics/server-side-client-tag) will automatically calculate it based on the `source` and `campaign` parameters provided in the `event_data` object.

> **Note on ID Management**: `client_id` and `session_id` are automatically extracted from the `na_s` cookie.



## Implementation
### Installation
 
1.  Clone the repository.
2.  Install the required dependencies:

    ```bash
    pip install requests google-cloud-bigquery
    ```
 

### Configuration
 
Open `streaming-protocol.py` and configure the following settings:
 
1. User Cookies:
    - Set the `na_s` cookie value (the user unique identifier `na_u` will be automatically derived from it).
2. Request Settings:
    - `full_endpoint`: Your GTM Server-side URL (e.g., `https://gtm.yourdomain.com/tm/nameless`).
    - `origin`: The allowed origin domain (e.g., `https://yourdomain.com`).
    - `api_key`: The API key matching your Client Tag configuration.
    - `gtm_preview_header`: (Optional) Your GTM Preview header for debugging.
3. BigQuery Settings:
    - `bq_project_id`: Your Google Cloud Project ID.
    - `bq_dataset_id`: Your BigQuery Dataset ID.
    - `bq_table_id`: Your BigQuery Table ID (e.g., `events_raw`).
    - `bq_credentials_path`: Path to your Google Cloud Service Account JSON key.


### Usage 
Run the script using Python:
 
```bash
python streaming-protocol.py
```
 
The script will:
1.  Connect to BigQuery to fetch the latest page context for the given session.
2.  Construct a robust event payload.
3.  Send the event to your GTM Server-side endpoint via the Streaming Protocol.
4.  Print the server response (or any errors) to the console.

---

Reach me at: [Email](mailto:hello@namelessanalytics.com) | [Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_streaming_protocol) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
