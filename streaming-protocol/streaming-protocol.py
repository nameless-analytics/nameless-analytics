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
na_s = 'LJbTg3PQxcGKyJp_Y1Jo5rGYHZlQGjM-UHQHSc1QpLoOara' # Modify this according to the current user's na_s cookie value

# Request settings
full_endpoint = 'https://gtm.tommasomoretti.com/tm/nameless' # Modify this according to your GTM Server-side endpoint 
origin = 'https://tommasomoretti.com' # Modify this according to website origin
api_key = '1234' # Modify this according to the API key set in the Nameless Analytics Server-side Client Tag
gtm_preview_header = 'ZW52LTEwMnxUWk9Pd1l1SW5YWFU0eFpzQlMtZHN3fDE5ZTI3NTBkMzYxOGUyZGY1ZDM4Mg==' # Modify this according to the GTM Server-side preview header

# Event data
client_id = na_s.split('_')[0]
session_id = na_s.split('_')[1].split('-')[0]
user_id = '[OPTIONAL_USER_ID]' # Add it if needed
event_name = 'purchase' # Modify this according to the event name to be sent
ecommerce_data = {
    "transaction_id": "T_12345",
    "value": 72.05,
    "tax": 3.60,
    "shipping": 5.99,
    "currency": "USD",
    "coupon": "SUMMER_SALE",
    "customer_type": "new",
    "items": [
    {
      "item_id": "SKU_12345",
      "item_name": "Stan and Friends Tee",
      "affiliation": "Google Merchandise Store",
      "coupon": "SUMMER_FUN",
      "discount": 2.22,
      "item_brand": "Google",
      "item_category": "Apparel",
      "item_category2": "Adult",
      "item_category3": "Shirts",
      "item_category4": "Crew",
      "item_category5": "Short sleeve",
      "item_list_id": "related_products",
      "item_list_name": "Related Products",
      "item_variant": "green",
      "price": 10.01,
      "quantity": 3
    },
    {
      "item_id": "SKU_12346",
      "item_name": "Google Grey Women's Tee",
      "affiliation": "Google Merchandise Store",
      "coupon": "SUMMER_FUN",
      "discount": 3.33,
      "index": 1,
      "item_brand": "Google",
      "item_category": "Apparel",
      "item_category2": "Adult",
      "item_category3": "Shirts",
      "item_category4": "Crew",
      "item_category5": "Short sleeve",
      "item_list_id": "related_products",
      "item_list_name": "Related Products",
      "item_variant": "gray",
      "location_id": "ChIJIQBpAG2ahYAR_6128GcTUEo",
      "price": 21.01,
      "promotion_id": "P_12345",
      "promotion_name": "Summer Sale",
      "quantity": 2
    }]
  } # Add ecommerce data here if needed

# BigQuery settings
project_id = 'tom-moretti' # Modify this according to your BigQuery project ID
dataset_id = 'nameless_analytics' # Modify this according to your BigQuery dataset ID
table_id = 'events_raw' # Modify this according to your BigQuery table ID
credentials_path = '/Users/tommasomoretti/Library/CloudStorage/GoogleDrive-tommasomoretti88@gmail.com/Il mio Drive/Lavoro/Nameless Analytics/worker_service_account.json' # Modify this according to your service account JSON file path


# --------------------------------------------------------------------------------------------------------------
# RETRIVE PAGE DATA FROM BIGQUERY
# --------------------------------------------------------------------------------------------------------------


def get_page_data_from_bq():
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
                                if name != 'page_status_code':
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
# BUILD PAYLOAD
# --------------------------------------------------------------------------------------------------------------


def build_payload(page_date_from_bq, page_data_from_bq):
    payload = {
        "user_data": {}, # Optional

        "session_data": {
            # "user_id": user_id, # Optional
        }, # Optional
        
        "page_date": page_date_from_bq, # Automatically retrieved from BigQuery if page_id exists in BigQuery
        "page_id": na_s.split('-')[1], # Extracted from na_s cookie
        "page_data": page_data_from_bq, # Automatically retrieved from BigQuery if page_id exists in BigQuery

        "event_date": datetime.now(timezone.utc).strftime('%Y-%m-%d'),
        "event_timestamp": int(datetime.now(timezone.utc).timestamp() * 1000),
        "event_id": f"{na_s.split('-')[1]}_{secrets.token_hex(8)}", # Automatically generated based on na_s cookie
        "event_name": event_name,
        "event_origin": "Streaming protocol", # Do not modify
        "event_data": {
            "event_type": "event", # Do not modify
            "hostname": urlparse(origin).netloc, # Website domain origin
            "source": 'direct', # Do not modify
            "campaign": None, # Do not modify
            "campaign_id": None, # Do not modify
            "campaign_click_id": None, # Do not modify
            "campaign_term": None, # Do not modify
            "campaign_content": None, # Do not modify
            # "user_agent": user_agent, # Optional
            # "browser_name": None, # Optional
            # "browser_language": None, # Optional
            # "browser_version": None, # Optional
            # "device_type": None, # Optional
            # "device_vendor": None, # Optional
            # "device_model": None, # Optional
            # "os_name": None, # Optional
            # "os_version": None, # Optional
            # "screen_size": None, # Optional
            # "viewport_size": None # Optional
        },

        "ecommerce": ecommerce_data,

        "gtm_data": {},            
        
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
        }
    }

    send_request(payload)


# --------------------------------------------------------------------------------------------------------------
# SEND REQUEST
# --------------------------------------------------------------------------------------------------------------

def send_request(payload):
    print('👉 Send request to ' + full_endpoint)
    
    try:
        headers = {
            'X-Api-Key': api_key,
            'X-Gtm-Server-Preview': gtm_preview_header,
            'Content-Type': 'application/json',
            'Origin': origin,
            'User-Agent': 'Nameless Analytics - Streaming protocol',
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
            print("  ", response)

        if response.status_code == 200:
            print("Function execution end: 👍")
        else:
            print("Function execution end: 🖕")
    except Exception as e:
        print(f"Error while fetch: {e}")


# --------------------------------------------------------------------------------------------------------------
# RUN PROTOCOL
# --------------------------------------------------------------------------------------------------------------

if __name__ == "__main__":
    print("NAMELESS ANALYTICS")
    print("STREAMING PROTOCOL")
    get_page_data_from_bq()