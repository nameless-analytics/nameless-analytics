# ------------------------------------------------------------------------------------------------------------------------------------------------------
# NAMELESS ANALYTICS | Users deletion tool
# This script removes all data associated with a specific client_id from both BigQuery and Firestore.
# ------------------------------------------------------------------------------------------------------------------------------------------------------

from datetime import datetime
from google.cloud import bigquery
from google.cloud import firestore


# --------------------------------------------------------------------------------------------------------------
# CONFIGURATION
# --------------------------------------------------------------------------------------------------------------

client_id = 'h56z1Uvp8j1B8Xb' # Set to the client_id you want to delete

# Project settings
project_id = 'PROJECT NAME' # Change this
dataset_id = 'nameless_analytics'
table_id = 'events_raw'

# Path to your Google Cloud Service Account JSON key
credentials_path = './service_account.json' # Change this


# --------------------------------------------------------------------------------------------------------------


def delete_user_data():

    if not client_id:
        print("🔴 Error: client_id is required")
        print("Function execution end: 🖕")
        return

    print(f"👉 Delete data for client_id: {client_id}")

    try:
        db = firestore.Client.from_service_account_json(credentials_path)
        doc_ref = db.collection('users').document(client_id)
        doc = doc_ref.get()

        user_date = datetime.strptime(doc.to_dict()['user_date'], '%Y-%m-%d').date() if doc.exists else None

    except Exception as e:
        print(f"🔴 Firestore Error: {e}")
        print("Function execution end: 🖕")
        return

    print("👉 Delete data from Firestore")

    try:
        if doc.exists:
            doc_ref.delete()
            print(f"  🟢 Firestore: Document '{client_id}' deleted successfully")
        else:
            print(f"  🟠 Firestore: Document '{client_id}' not found")

    except Exception as e:
        print(f"  🔴 Firestore Error: {e}")
        print("Function execution end: 🖕")
        return


    # Delete BigQuery data
    print("👉 Delete data from BigQuery")

    try:
        client = bigquery.Client.from_service_account_json(credentials_path)

        user_date_filter = """
              AND user_date = @user_date
              AND event_date >= @user_date""" if user_date else ""

        query = f"""
            DELETE FROM `{project_id}.{dataset_id}.{table_id}`
            WHERE true
              AND client_id = @client_id{user_date_filter}
        """
        query_parameters = [
            bigquery.ScalarQueryParameter("client_id", "STRING", client_id),
        ]

        if user_date:
            query_parameters.append(bigquery.ScalarQueryParameter("user_date", "DATE", user_date))

        job_config = bigquery.QueryJobConfig(query_parameters=query_parameters)

        query_job = client.query(query, job_config=job_config)
        results = query_job.result()


        if results.num_dml_affected_rows > 0:
            print(f"  🟢 BigQuery: {results.num_dml_affected_rows} records deleted for client_id '{client_id}'")
        else:
            print(f"  🟠 BigQuery: client_id '{client_id}' not found")

        print("Function execution end: 👍")

    except Exception as e:
        print(f"  🔴 BigQuery Error: {e}")
        print("Function execution end: 🖕")
        return


# --------------------------------------------------------------------------------------------------------------


if __name__ == "__main__":
    print("NAMELESS ANALYTICS")
    print("USER DELETION TOOL")

    delete_user_data()
