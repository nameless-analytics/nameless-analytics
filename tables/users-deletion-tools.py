import sys
import os
from google.cloud import bigquery
from google.cloud import firestore

# ------------------------------------------------------------------------------------------------------------------------------------------------------
# NAMELESS ANALYTICS | GDPR Deletion Script
# This script removes all data associated with a specific client_id from both BigQuery and Firestore.
# ------------------------------------------------------------------------------------------------------------------------------------------------------

# --- CONFIGURATION ---
# Path to your Google Cloud Service Account JSON key
# This service account requires permissions: BigQuery Data Editor & Cloud Datastore User (or Owner)
CREDENTIALS_PATH = '/Users/tommasomoretti/Library/CloudStorage/GoogleDrive-tommasomoretti88@gmail.com/Il mio Drive/Lavoro/Nameless Analytics/worker_service_account.json'

# Project settings
PROJECT_ID = 'tom-moretti'
DATASET_ID = 'nameless_analytics'
TABLE_ID = 'events_raw'
# ---------------------

def delete_user_data(client_id):
    if not client_id:
        print("🔴 Error: client_id is required.")
        return

    # Set credentials environment variable
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = CREDENTIALS_PATH

    print(f"\n--- PROCESSO DI ELIMINAZIONE UTENTE: {client_id} ---")

    # 1. BIGQUERY DELETION
    try:
        bq_client = bigquery.Client(project=PROJECT_ID)
        bq_query = f"""
            DELETE FROM `{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}`
            WHERE client_id = '{client_id}'
        """
        print(f"⏳ Eliminazione da BigQuery ({DATASET_ID}.{TABLE_ID})...")
        query_job = bq_client.query(bq_query)
        query_job.result() # Wait for completion
        print(f"🟢 BigQuery: Record eliminati correttamente.")
    except Exception as e:
        print(f"🔴 BigQuery Error: {e}")

    # 2. FIRESTORE DELETION
    try:
        db = firestore.Client(project=PROJECT_ID)
        doc_ref = db.collection('users').document(client_id)
        
        # Check if exists before deleting for better feedback
        if doc_ref.get().exists:
            print(f"⏳ Eliminazione da Firestore (collection: users)...")
            doc_ref.delete()
            print(f"🟢 Firestore: Documento utente eliminato correttamente.")
        else:
            print(f"🟡 Firestore: Documento '{client_id}' non trovato nella collection 'users'.")
    except Exception as e:
        print(f"🔴 Firestore Error: {e}")

    print("--- Operazione conclusa ---\n")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("\n❌ Utilizzo: python gdpr-delete-user.py [CLIENT_ID]")
        print("Esempio: python gdpr-delete-user.py LPqJP8hpxpGedIA_sKWExPWU8qZLi1\n")
    else:
        target_id = sys.argv[1]
        delete_user_data(target_id)
