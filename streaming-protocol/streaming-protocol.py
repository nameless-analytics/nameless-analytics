# NAMELESS ANALYTICS STREAMING PROTOCOL 
# PYTHON EXAMPLE CODE  

import requests
import secrets
import sys
from datetime import datetime, timezone
from google.cloud import bigquery


# --------------------------------------------------------------------------------------------------------------


# User cookies
na_u = '[YOUR_NA_U_COOKIE_VALUE]' # Modify this according to the current user's na_u cookie value
na_s = '[YOUR_NA_S_COOKIE_VALUE]' # Modify this according to the current user's na_s cookie value


# Request settings
full_endpoint = 'https://gtm.yourdomain.com/tm/nameless' # Modify this according to your GTM Server-side endpoint 
origin = 'https://yourdomain.com' # Modify this according to website origin
api_key = '[YOUR_API_KEY]' # Modify this according to the API key set in the Nameless Analytics Server-side Client Tag
gtm_preview_header = '[YOUR_GTM_SERVER_PREVIEW_HEADER]' # Modify this according to the GTM Server-side preview header



# Event settings
user_id = '[OPTIONAL_USER_ID]' # Add it if needed
event_name = 'purchase' # Modify this according to the event name to be sent

# BigQuery settings
bq_project_id = '[YOUR_BQ_PROJECT_ID]' # Modify this according to your BigQuery project ID
bq_dataset_id = '[YOUR_BQ_DATASET_ID]' # Modify this according to your BigQuery dataset ID
bq_table_id = 'events_raw' # Modify this according to your BigQuery table ID
bq_credentials_path = '[PATH_TO_YOUR_SERVICE_ACCOUNT_JSON]' # Modify this according to your service account JSON file path


# --------------------------------------------------------------------------------------------------------------


print("NAMELESS ANALYTICS")
print("STREAMING PROTOCOL")

# Retrieve page data from BigQuery, for events. If not found no hit will be sent.
print(f'👉 Retrieve page data from BigQuery for page_id: {na_s}')

page_date_from_bq = ""
page_data_from_bq = {}

try:
    client = bigquery.Client.from_service_account_json(bq_credentials_path)
    query = f"""
        SELECT page_date, page_data
        FROM `{bq_project_id}.{bq_dataset_id}.{bq_table_id}`
        WHERE page_id = @na_s
        LIMIT 1
    """
    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("na_s", "STRING", na_s),
        ]
    )

    query_job = client.query(query, job_config=job_config)
    results = query_job.result()

    row_found = False
    for row in results:
        row_found = True

        if row.page_date:
            page_date_from_bq = row.page_date.strftime('%Y-%m-%d') if hasattr(row.page_date, 'strftime') else str(row.page_date)
            
        if row.page_data:
            for item in row.page_data:
                name = item.get('name')
                value_struct = item.get('value')
                if name and isinstance(value_struct, dict):
                    for val_type in ['string', 'int', 'float', 'json', 'bool']:
                        val = value_struct.get(val_type)
                        if val is not None:
                            page_data_from_bq[name] = val
                            break
    
    if not row_found:
        print("  🔴 Page ID not found in BigQuery. Request aborted")
        sys.exit()
    else:
        print("  🟢 Page data retrieved from BigQuery")

except Exception as e:
    print("🔴 Error retrieving data from BigQuery: ", e)
    sys.exit()


# --------------------------------------------------------------------------------------------------------------


# Event data
event_date = datetime.now(timezone.utc).strftime('%Y-%m-%d')
event_timestamp = int(datetime.now(timezone.utc).timestamp() * 1000)
event_id = f'{na_s}_{secrets.token_hex(8)}'
event_origin = "Streaming protocol"
user_agent = 'Nameless Analytics - Streaming protocol'

payload = {
    "user_data": {
        "user_source": "Streaming protocol"
    },

    "session_data": {
        "session_source": "Streaming protocol",
      "user_id": user_id,
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
        "event_type": "event"
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
      "ss_hostname": None,
      "ss_container_id": None,
      "ss_tag_name": None,
      "ss_tag_id": None,
      "processing_event_timestamp": None,
      "content_length": None
    }
}

print('👉 Send request to ' + full_endpoint)

headers = {
    'X-Gtm-Server-Preview': gtm_preview_header,
    'x-Api-Key': api_key,

    'Content-Type': 'application/json',
    'Origin': origin,
    'User-Agent': user_agent,
    'Cookie': f'na_u={na_u}; na_s={na_s}' 
}

try:
    response = requests.post(full_endpoint, json=payload, headers=headers)
    
    try:
        response_json = response.json()
        message = response_json.get("response", response.text)
        if isinstance(message, str):
            try:
                message = message.encode('latin1').decode('utf-8')
            except:
                pass
        print("  ", message)
    except:
        print("  ", response.text)

    if response.status_code == 200:
        print("Function execution end: 👍")
    else:
        print("Function execution end: 🖕")

except Exception as e:
    print(f"Error while fetch: {e}")