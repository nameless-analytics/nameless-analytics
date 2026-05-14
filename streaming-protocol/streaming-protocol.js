// --------------------------------------------------------------------------------------------------------------
// NAMELESS ANALYTICS | STREAMING PROTOCOL
// This script sends a request to the Nameless Analytics Server-side endpoint.
// --------------------------------------------------------------------------------------------------------------

const crypto = require('crypto');
const { BigQuery } = require('@google-cloud/bigquery');

// --------------------------------------------------------------------------------------------------------------
// CONFIGURATION
// --------------------------------------------------------------------------------------------------------------

// User cookies
const na_s = 'THar5XDi2SYUiR2_QqQrCtRqZvObDt7-Tk94Ptz7ByIA65h'; // Modify this according to the current user's na_s cookie value

// Request settings
const full_endpoint = 'https://gtm.tommasomoretti.com/tm/nameless'; // Modify this according to your GTM Server-side endpoint 
const origin = 'https://tommasomoretti.com'; // Modify this according to website origin
const api_key = '1234'; // Modify this according to the API key set in the Nameless Analytics Server-side Client Tag
// const gtm_preview_header = 'ZW52LTEwMnxUWk9Pd1l1SW5YWFU0eFpzQlMtZHN3fDE5ZGMwMDhhYTZiYTE5NmZkNDkxZA=='; // Modify this according to the GTM Server-side preview header

// Event data
const client_id = na_s.split('_')[0];
const session_id = na_s.split('_')[1].split('-')[0];
const user_id = '[OPTIONAL_USER_ID]'; // Add it if needed
const event_name = 'purchase'; // Modify this according to the event name to be sent
const ecommerce_data = {
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
}; // Add ecommerce data here if needed

// BigQuery settings
const project_id = 'tom-moretti'; // Modify this according to your BigQuery project ID
const dataset_id = 'nameless_analytics'; // Modify this according to your BigQuery dataset ID
const table_id = 'events_raw'; // Modify this according to your BigQuery table ID
const credentials_path = '/Users/tommasomoretti/Library/CloudStorage/GoogleDrive-tommasomoretti88@gmail.com/Il mio Drive/Lavoro/Nameless Analytics/worker_service_account.json'; // Modify this according to your service account JSON file path


// --------------------------------------------------------------------------------------------------------------
// RETRIVE PAGE DATA FROM BIGQUERY
// --------------------------------------------------------------------------------------------------------------

async function get_page_data_from_bq() {
    console.log(`👉 Retrieve page data from BigQuery for page_id: ${na_s}`);

    let page_date_from_bq = "";
    const page_data_from_bq = {};

    try {
        const bigquery = new BigQuery({
            projectId: project_id,
            keyFilename: credentials_path
        });

        const query = `
            SELECT page_date, page_data
            FROM \`${project_id}.${dataset_id}.${table_id}\`
            WHERE page_id = @na_s
            LIMIT 1
        `;

        const options = {
            query: query,
            params: { na_s: na_s }
        };

        const [rows] = await bigquery.query(options);

        let row_found = false;
        if (rows && rows.length > 0) {
            const row = rows[0];
            row_found = true;

            if (row.page_date) {
                page_date_from_bq = typeof row.page_date.value !== 'undefined' 
                    ? row.page_date.value 
                    : String(row.page_date);
            }

            if (row.page_data) {
                for (const item of row.page_data) {
                    const name = item.name;
                    const value_struct = item.value;
                    if (name && typeof value_struct === 'object' && value_struct !== null) {
                        const types = ['string', 'int', 'float', 'json', 'bool'];
                        for (const val_type of types) {
                            const val = value_struct[val_type];
                            if (val !== null && val !== undefined) {
                                if (name !== 'page_status_code') {
                                    page_data_from_bq[name] = val;
                                }
                                break;
                            }
                        }
                    }
                }
            }
        }

        if (!row_found) {
            console.log("  🔴 Page ID not found in BigQuery. Request aborted");
            return;
        } else {
            console.log("  🟢 Page data retrieved from BigQuery");
            await build_payload(page_date_from_bq, page_data_from_bq);
        }

    } catch (e) {
        console.log("🔴 Error retrieving data from BigQuery: ", e);
        return;
    }
}


// --------------------------------------------------------------------------------------------------------------
// BUILD PAYLOAD
// --------------------------------------------------------------------------------------------------------------

async function build_payload(page_date_from_bq, page_data_from_bq) {
    const now = new Date();
    const event_date = now.toISOString().split('T')[0];
    const event_timestamp = now.getTime();
    const event_id_suffix = crypto.randomBytes(8).toString('hex');

    const payload = {
        "user_data": {}, // Optional

        "session_data": {
            // "user_id": user_id, // Optional
        }, // Optional
        
        "page_date": page_date_from_bq, // Automatically retrieved from BigQuery if page_id exists in BigQuery
        "page_id": na_s.split('-')[1], // Extracted from na_s cookie
        "page_data": page_data_from_bq, // Automatically retrieved from BigQuery if page_id exists in BigQuery

        "event_date": event_date,
        "event_timestamp": event_timestamp,
        "event_id": `${na_s.split('-')[1]}_${event_id_suffix}`, // Automatically generated based on na_s cookie
        "event_name": event_name,
        "event_origin": "Streaming protocol", // Do not modify
        "event_data": {
            "event_type": "event", // Do not modify
            "hostname": new URL(origin).hostname, // Website domain origin
            "source": null, // Do not modify
            "campaign": null, // Do not modify
            "campaign_id": null, // Do not modify
            "campaign_click_id": null, // Do not modify
            "campaign_term": null, // Do not modify
            "campaign_content": null, // Do not modify
            // "user_agent": user_agent, // Optional
            // "browser_name": null, // Optional
            // "browser_language": null, // Optional
            // "browser_version": null, // Optional
            // "device_type": null, // Optional
            // "device_vendor": null, // Optional
            // "device_model": null, // Optional
            // "os_name": null, // Optional
            // "os_version": null, // Optional
            // "screen_size": null, // Optional
            // "viewport_size": null // Optional
        },

        "ecommerce": ecommerce_data,

        "gtm_data": {},            
        
        "consent_data": {
            "consent_type": null,
            "respect_consent_mode": null,
            "ad_user_data": null,
            "ad_personalization": null,
            "ad_storage": null,
            "analytics_storage": null,
            "functionality_storage": null,
            "personalization_storage": null,
            "security_storage": null
        }
    };

    await send_request(payload);
}


// --------------------------------------------------------------------------------------------------------------
// SEND REQUEST
// --------------------------------------------------------------------------------------------------------------

async function send_request(payload) {
    console.log('👉 Send request to ' + full_endpoint);
    
    try {
        const headers = {
            'x-api-key': api_key,
            // 'X-Gtm-Server-Preview': gtm_preview_header,
            'Content-Type': 'application/json',
            'Origin': origin,
            'User-Agent': 'Nameless Analytics - Streaming protocol',
            'Cookie': `na_u=${client_id}; na_s=${na_s}` 
        };
    
        const response = await fetch(full_endpoint, {
            method: 'POST',
            body: JSON.stringify(payload),
            headers: headers
        });
        
        try {
            const response_json = await response.json();
            const message = response_json.response || JSON.stringify(response_json);
            console.log("  ", message);
        } catch (err) {
            console.log("  ", response.status, response.statusText);
        }

        if (response.status === 200) {
            console.log("Function execution end: 👍");
        } else {
            console.log("Function execution end: 🖕");
        }
    } catch (e) {
        console.log(`Error while fetch: ${e}`);
    }
}


// --------------------------------------------------------------------------------------------------------------
// RUN PROTOCOL
// --------------------------------------------------------------------------------------------------------------

if (require.main === module) {
    console.log("NAMELESS ANALYTICS");
    console.log("STREAMING PROTOCOL");
    get_page_data_from_bq();
}
