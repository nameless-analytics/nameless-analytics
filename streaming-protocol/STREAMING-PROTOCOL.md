# Nameless Analytics | Streaming Protocol

The Nameless Analytics Streaming Protocol is a robust implementation for sending data to the [Nameless Analytics Server-side Client Tag](https://github.com/nameless-analytics/nameless-analytics-server-side-client-tag).

For an overview of how Nameless Analytics works [start from here](https://github.com/nameless-analytics/nameless-analytics/#high-level-data-flow).

🚧 **Nameless Analytics is currently in beta and is subject to change.** 🚧



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
### BigQuery Enrichment
Automatically retrieves page_data from your BigQuery `events_raw` table based on the `na_s` cookie, allowing you to enrich server-side events with historical page data.

### Automatic Type Handling
Correctly maps BigQuery data types (`string`, `int`, `float`, `json`) to the JSON payload.


### Error Handling
Includes robust error handling for API responses and database queries.
 

### Security
Supports API Key authentication for secure server-side ingestion.



## Implementation
### Installation
 
1.  Clone the repository.
2.  Install the required dependencies:
    ```bash
    pip install requests google-cloud-bigquery
    ```
 

### Configuration
 
Open `streaming-protocol.py` and configure the following settings:
 
1.  **User Cookies**:
    *   Set `na_u` cookie value
    *   Set `na_s` cookie value.
2.  **Request Settings**:
    *   `full_endpoint`: Your GTM Server-side URL (e.g., `https://gtm.yourdomain.com/tm/nameless`).
    *   `origin`: The allowed origin domain (e.g., `https://yourdomain.com`).
    *   `api_key`: The API key matching your Client Tag configuration.
    *   `gtm_preview_header`: (Optional) Your GTM Preview header for debugging.
3.  **BigQuery Settings**:
    *   `bq_project_id`: Your Google Cloud Project ID.
    *   `bq_dataset_id`: Your BigQuery Dataset ID.
    *   `bq_table_id`: Your BigQuery Table ID (e.g., `events_raw`).
    *   `bq_credentials_path`: Path to your Google Cloud Service Account JSON key.


### Usage 
Run the script using Python:
 
```bash
python streaming-protocol.py
```
 å
The script will:
1.  Connect to BigQuery to fetch the latest page context for the given session.
2.  Construct a robust event payload.
3.  Send the event to your GTM Server-side endpoint via the Streaming Protocol.
4.  Print the server response (or any errors) to the console.

---

Reach me at: [Email](mailto:hello@tommasomoretti.com) | [Website](https://tommasomoretti.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics) | [Twitter](https://twitter.com/tommoretti88) | [LinkedIn](https://www.linkedin.com/in/tommasomoretti/)
