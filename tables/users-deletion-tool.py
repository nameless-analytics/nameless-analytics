# ------------------------------------------------------------------------------------------------------------------------------------------------------
# NAMELESS ANALYTICS | Users deletion tool
# This script removes all data associated with a specific client_id from both BigQuery and Firestore.
# ------------------------------------------------------------------------------------------------------------------------------------------------------

from google.api_core.exceptions import GoogleAPICallError
from google.cloud import bigquery
from google.cloud import firestore


# --------------------------------------------------------------------------------------------------------------
# CONFIGURATION
# --------------------------------------------------------------------------------------------------------------

client_id = 'h56z1Uvp8j1B8Xb' # Set to the client_id you want to delete

# Project settings
project_id = 'PROJECT NAME' # Change this
dataset_id = 'nameless_analytics'

# Tables holding the user's events: events_raw, and the events table built from it when there is one
tables = ['events_raw', 'events']

# Path to your Google Cloud Service Account JSON key
credentials_path = './service_account.json' # Change this


# --------------------------------------------------------------------------------------------------------------


def delete_user_data():

    if not client_id:
        print("🔴 Error: client_id is required")
        print("Function execution end: 🖕")
        return

    print(f"👉 Delete data for client_id: {client_id}")


    # Delete BigQuery data first: the Firestore document is deleted only once BigQuery succeeded,
    # so a failed run can always be repeated.
    print("👉 Delete data from BigQuery")

    try:
        client = bigquery.Client.from_service_account_json(credentials_path)
    except Exception as e:
        print(f"  🔴 BigQuery Error: {e}")
        print("Function execution end: 🖕")
        return

    for table_id in tables:
        table = f"{project_id}.{dataset_id}.{table_id}"

        try:
            client.get_table(table)
        except GoogleAPICallError:
            print(f"  🟠 BigQuery: table '{table_id}' not found, skipped")
            continue

        # client_id alone: no date filter, so no row is left behind under another user_date
        # or a wrong device clock. BigQuery scans only the client_id column to find the rows.
        query = f"""
            DELETE FROM `{table}`
            WHERE client_id = @client_id
        """
        job_config = bigquery.QueryJobConfig(
            query_parameters=[bigquery.ScalarQueryParameter("client_id", "STRING", client_id)]
        )

        try:
            results = client.query(query, job_config=job_config).result()
        except Exception as e:
            if 'streaming buffer' in str(e).lower():
                print(f"  🔴 BigQuery: some of this user's rows in '{table_id}' are still in the streaming buffer and cannot be deleted yet")
                print("  👉 Nothing else was deleted. Run the script again in about 90 minutes.")
            else:
                print(f"  🔴 BigQuery Error on '{table_id}': {e}")
                print("  👉 The Firestore document was not deleted. Run the script again.")
            print("Function execution end: 🖕")
            return

        if results.num_dml_affected_rows and results.num_dml_affected_rows > 0:
            print(f"  🟢 BigQuery: {results.num_dml_affected_rows} records deleted from '{table_id}' for client_id '{client_id}'")
        else:
            print(f"  🟠 BigQuery: client_id '{client_id}' not found in '{table_id}'")


    # Delete Firestore data last
    print("👉 Delete data from Firestore")

    try:
        db = firestore.Client.from_service_account_json(credentials_path)
        doc_ref = db.collection('users').document(client_id)

        if doc_ref.get().exists:
            doc_ref.delete()
            print(f"  🟢 Firestore: Document '{client_id}' deleted successfully")
        else:
            print(f"  🟠 Firestore: Document '{client_id}' not found")

    except Exception as e:
        print(f"  🔴 Firestore Error: {e}")
        print("  👉 BigQuery data was deleted. Run the script again to delete the Firestore document.")
        print("Function execution end: 🖕")
        return

    print("Function execution end: 👍")


# --------------------------------------------------------------------------------------------------------------


if __name__ == "__main__":
    print("NAMELESS ANALYTICS")
    print("USER DELETION TOOL")

    delete_user_data()
