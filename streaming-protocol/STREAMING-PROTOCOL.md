# Nameless Analytics | Streaming Protocol

The Nameless Analytics Streaming Protocol is a robust implementation for sending data to the [Nameless Analytics Server-side Client Tag](https://github.com/nameless-analytics/server-side-client-tag).

For an overview of how Nameless Analytics works [start from here](../README.md#high-level-data-flow).

### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change 🚧



## Table of Contents
- [Features](#features)
  - [BigQuery Enrichment](#bigquery-enrichment)
  - [Automatic Type Handling](#automatic-type-handling)
  - [Error Handling](#error-handling)
  - [Security](#security)
- [Implementation](#implementation)
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Usage](#usage)

    

## Features
### Session enrichment
The Streaming Protocol is designed for secondary interactions (conversions, backend events, offline data). **`page_view` events are not allowed** via the Streaming Protocol and must be sent through the standard website tracker to correctly initialize the session context.

> ⚠️ **Note on session duration**: Events sent via the Streaming Protocol are recorded in BigQuery but **do not extend the session duration** (`session_duration_sec`). By default, duration calculation remains based exclusively on on-site events (`event_origin = 'Website'`).


### BigQuery enrichment
Automatically retrieves page_data from your BigQuery `events_raw` table based on the `na_s` cookie, allowing you to enrich server-side events to send with the correct page data.


### Automatic type handling
Correctly maps BigQuery data types (`string`, `int`, `float`, `json` and `bool`) to the JSON payload.


### Error handling
Includes robust error handling for API responses and database queries.
 

### Security
Supports API Key authentication for secure server-side ingestion.


## JSON Payload Structure
The Streaming Protocol requires a POST request with a JSON body. While the server validates mandatory root fields, `event_type` is an optional but recommended field within `event_data` to maintain consistency with the BigQuery schema.

### Example Payload
```json
{
        "user_date": event_date,
        "client_id": client_id,
        "user_data": {
        },

        "session_date": event_date,
        "session_id": f"{client_id}_{session_id}",
        "session_data": {
            # "user_id": user_id, # Optional
        },
        
        "page_date": page_date_from_bq,
        "page_id": na_s,
        "page_data": page_data_from_bq,

        "event_date": event_date,
        "event_timestamp": event_timestamp,
        "event_id": event_id,
        "event_name": event_name,
        "event_origin": event_origin,
        "event_data": {
            "event_type": "event",
            # "channel_grouping": None,
            # "source": None,
            # "campaign": None,
            # "campaign_id": None,
            # "campaign_click_id": None,
            # "campaign_term": None,
            # "campaign_content": None,
            "hostname": hostname,
            # "user_agent": user_agent,
            # "browser_name": None,
            # "browser_language": None,
            # "browser_version": None,
            # "device_type": None,
            # "device_vendor": None,
            # "device_model": None,
            # "os_name": None,
            # "os_version": None,
            # "screen_size": None,
            # "viewport_size": None
        },

        "ecommerce": {
            # Add ecommerce data here
        },

        "consent_data": {
            "consent_type": None,
            "respect_consent_mode": None,
            "ad_user_data": None,
            "ad_personalization": None,
            "ad_storage": None,
            "analytics_storage": None,
            "functionality_storage": None,
            "personalization_storage": None,
            "security_storage": None
        },
        "gtm_data": {
            "cs_hostname": None,
            "cs_container_id": None,
            "cs_tag_name": None,
            "cs_tag_id": None,
        }
    }
```

> **Note on `event_type`**: In the standard website tracker, this is automatically set to `page_view` or `event`. For the Streaming Protocol, you should manually set it to `event` (as `page_view` is restricted to the website tracker).




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
    - Set `na_u` cookie value
    - Set `na_s` cookie value.
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
