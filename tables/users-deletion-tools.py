# ------------------------------------------------------------------------------------------------------------------------------------------------------
# NAMELESS ANALYTICS | GDPR Deletion Script
# This script removes all data associated with a specific client_id from both BigQuery and Firestore.
# ------------------------------------------------------------------------------------------------------------------------------------------------------


import sys
import os
from google.cloud import bigquery
from google.cloud import firestore


# --------------------------------------------------------------------------------------------------------------
# CONFIGURATION
# --------------------------------------------------------------------------------------------------------------

client_id = '9XYP7ZNT84N750' # Set to the client_id you want to delete

# Project settings
project_id = 'tom-moretti'
dataset_id = 'nameless_analytics'
table_id = 'events_raw'

# Path to your Google Cloud Service Account JSON key
credentials_path = '/Users/tommasomoretti/Library/CloudStorage/GoogleDrive-tommasomoretti88@gmail.com/Il mio Drive/Lavoro/Nameless Analytics/worker_service_account.json'


# --------------------------------------------------------------------------------------------------------------


def delete_user_data():

    if not client_id:
        print("🔴 Error: client_id is required")
        print("Function execution end: 🖕")
        return

    print(f"👉 Delete data for client_id: {client_id}")

    # 1. BIGQUERY DELETION
    print("👉 Delete data from BigQuery")
    
    try:
        client = bigquery.Client.from_service_account_json(credentials_path)
        query = f"""
            DELETE FROM `{project_id}.{dataset_id}.{table_id}`
            WHERE client_id = '{client_id}'
        """

        query_job = client.query(query)
        results = query_job.result()


        if results.num_dml_affected_rows > 0:
            print(f"  🟢 BigQuery: {results.num_dml_affected_rows} records deleted for client_id '{client_id}'")
        else:
            print(f"  🟠 BigQuery: client_id '{client_id}' not found")

    except Exception as e:
        print(f"  🔴 BigQuery Error: {e}")
        print("Function execution end: 🖕")
        return 


    # 2. FIRESTORE DELETION
    print("👉 Delete data from Firestore")

    try:
        db = firestore.Client.from_service_account_json(credentials_path)
        doc_ref = db.collection('users').document(client_id)
        

        if doc_ref.get().exists:
            doc_ref.delete()
            print(f"  🟢 Firestore: Document '{client_id}' deleted successfully")
        else:
            print(f"  🟠 Firestore: Document '{client_id}' not found")

        print("Function execution end: 👍")

    except Exception as e:
        print(f"  🔴 Firestore Error: {e}")
        print("Function execution end: 🖕")
        return


# --------------------------------------------------------------------------------------------------------------


if __name__ == "__main__":
    print("NAMELESS ANALYTICS")
    print("USER DELETION TOOL")

    delete_user_data()

