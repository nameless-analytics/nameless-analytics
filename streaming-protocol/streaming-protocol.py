# --------------------------------------------------------------------------------------------------------------
# NAMELESS ANALYTICS | STREAMING PROTOCOL
# This script sends a request to the Nameless Analytics Server-side endpoint.
# --------------------------------------------------------------------------------------------------------------

import requests
import secrets
from urllib.parse import urlparse
from datetime import datetime, timezone
from google.cloud import bigquery


# --------------------------------------------------------------------------------------------------------------
# CONFIGURATION
# --------------------------------------------------------------------------------------------------------------

# User cookies
na_s = '9XYP7ZNT84N750_Qt2ZyjBoG0ukJa-finVjkNftb1L8GD' # Modify this according to the current user's na_s cookie value

# Request settings
full_endpoint = 'https://gtm.tommasomoretti.com/tm/nameless' # Modify this according to your GTM Server-side endpoint 
origin = 'https://tommasomoretti.com' # Modify this according to website origin
api_key = '1234' # Modify this according to the API key set in the Nameless Analytics Server-side Client Tag
gtm_preview_header = 'ZW52LTEwMnxUWk9Pd1l1SW5YWFU0eFpzQlMtZHN3fDE5YzYyNTNkMjExODcxMzc1NTJmZQ==' # Modify this according to the GTM Server-side preview header

# Event data
client_id = na_s.split('_')[0]
session_id = na_s.split('_')[1].split('-')[0]
user_id = '[OPTIONAL_USER_ID]' # Add it if needed
event_name = 'purchase' # Modify this according to the event name to be sent
event_date = datetime.now(timezone.utc).strftime('%Y-%m-%d')
event_timestamp = int(datetime.now(timezone.utc).timestamp() * 1000)
event_id = f'{na_s}_{secrets.token_hex(8)}'
event_origin = "Streaming protocol"
user_agent = 'Nameless Analytics - Streaming protocol'
hostname = urlparse(origin).netloc


# BigQuery settings
project_id = 'tom-moretti' # Modify this according to your BigQuery project ID
dataset_id = 'nameless_analytics' # Modify this according to your BigQuery dataset ID
table_id = 'events_raw' # Modify this according to your BigQuery table ID
credentials_path = '/Users/tommasomoretti/Library/CloudStorage/GoogleDrive-tommasomoretti88@gmail.com/Il mio Drive/Lavoro/Nameless Analytics/worker_service_account.json' # Modify this according to your service account JSON file path


# --------------------------------------------------------------------------------------------------------------


def run_protocol():
    print(f'👉 Retrieve page data from BigQuery for page_id: {na_s}')

    page_date_from_bq = ""
    page_data_from_bq = {}

    try:
        client = bigquery.Client.from_service_account_json(credentials_path)
        query = f"""
            SELECT page_date, page_data
            FROM `{project_id}.{dataset_id}.{table_id}`
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
            return
        else:
            print("  🟢 Page data retrieved from BigQuery")
            build_payload(page_date_from_bq, page_data_from_bq)

    except Exception as e:
        print("🔴 Error retrieving data from BigQuery: ", e)
        return


# --------------------------------------------------------------------------------------------------------------


def build_payload(page_date_from_bq, page_data_from_bq):
    payload = {
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
            "hostname": hostname,
            # "source": None,
            # "campaign": None,
            # "campaign_id": None,
            # "campaign_click_id": None,
            # "campaign_term": None,
            # "campaign_content": None,
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

    send_request(payload)


# --------------------------------------------------------------------------------------------------------------


def send_request(payload):
    print('👉 Send request to ' + full_endpoint)
    
    try:
        headers = {
            'x-Api-Key': api_key,
            'X-Gtm-Server-Preview': gtm_preview_header,
            'Content-Type': 'application/json',
            'Origin': origin,
            'User-Agent': user_agent,
            'Cookie': f'na_u={client_id}; na_s={na_s}' 
        }
    
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


# --------------------------------------------------------------------------------------------------------------


if __name__ == "__main__":
    print("NAMELESS ANALYTICS")
    print("STREAMING PROTOCOL")
    run_protocol()