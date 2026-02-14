# Nameless Analytics | Setup guides
The Nameless Analytics Setup guides is a guide to help you set up Nameless Analytics. 

For an overview of how Nameless Analytics works [start from here](https://github.com/nameless-analytics/nameless-analytics/#high-level-data-flow).

### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change 🚧



## Table of Contents
- [How to set up Nameless Analytics in GTM](#how-to-set-up-nameless-analytics-in-gtm)
- [How to track page views](#how-to-track-page-views)
- [How to set up cross-domain tracking](#how-to-set-up-cross-domain-tracking)
- [How to setup and customize ecommerce tracking](#how-to-setup-and-customize-ecommerce-tracking)



## How to set up Nameless Analytics in GTM

Setting up Nameless Analytics involves a dual-container strategy that combines the flexibility of Client-side GTM with the security and precision of Server-side GTM. This architecture allows you to capture granular interactions in the browser while offloading complex processing and sensitive data handling to your own private server environment.

The implementation is streamlined through pre-configured templates that include all the necessary Tags, Triggers, and Variables to get your first-party analytics pipeline running in minutes.

**Encountering issues during setup?** Check the [Configuration Troubleshooting](TROUBLESHOOTING.md#library-loading--configuration-issues) section if your tags aren't firing.

### Phase 1: Prerequisites Check
Before proceeding, ensure your Google Cloud environment is fully provisioned:
- **BigQuery**: Dataset and tables must be created according to the [SQL schemas](../tables/TABLES.md).
- **Firestore**: A database instance should be initialized in Native Mode.
- **Server-side GTM**: Your instance (Cloud Run or App Engine) must be active and mapped to a custom first-party domain.

### Phase 2: Asset Acquisition
Download the primary container templates from the [`gtm-containers/`](../gtm-containers/) directory. These JSON files contain the standardized logic for event capture, sequential execution queuing, and server-side orchestration.

### Phase 3: Container Integration & Merging
Integrate the templates into your GTM environment with the following steps:
1. Navigate to **Admin > Import Container** in both your Client-side and Server-side workspaces.
2. **File Selection**: Upload the corresponding JSON template and merge it with your existing container.

### Phase 4: Global Configuration (Client-side)
Configure the tracker to establish a secure handshake with your server:
1. In your Client-side workspace, locate the **Nameless Analytics Client-side Tracker Configuration Variable**.
2. **Request Endpoint Domain**: Update this field with your dedicated Server-side GTM URL (e.g., `https://gtm.yourdomain.com`).
3. **Library Settings**: (Optional) If you are using First-Party mode for the core libraries, update the library paths here.

### Phase 5: Pipeline Validation & QA
1. **Synchronized Preview**: Launch **Preview Mode** for both the Web and Server containers simultaneously.
2. **Client Audit**: Navigate to your website and verify the tracker initialization via the browser console logs.
3. **Server Audit**: In the Server-side GTM preview, ensure that incoming requests are correctly intercepted and parsed by the **Nameless Analytics Server-side Client Tag**.
4. **Data Verification**: Confirm that the event stream is successfully reaching BigQuery and that session snapshots are updating in Firestore.



## How to track page views
Ensure that the `page_view` event is the **first** event triggered on every page load. Triggering other events before it will result in [Orphan Events](TROUBLESHOOTING.md#orphan-events--sequence-issues). 

Page view tags can be triggered in many ways:

### Via GTM standard page view trigger
Using any standard GTM trigger (such as **All Pages**).


### Via browser history (Route change)
Using history changes `pushState` or `replaceState`.

This is the preferred method for SPAs since the page referrer for virtual page views is maintained even if a page is reloaded and page information is retrieved automatically from the history state.


```javascript
document.title = 'Product name | Nameless Analytics';
dataLayer.push({
  page_category: 'Product page'
});
history.pushState('', '', '/product_name');
```

> Make sure to update the page title and any relevant dataLayer parameters before the history change otherwise the Page Title and Page Category will not be set correctly.

### Via custom dataLayer event
Using custom dataLayer events.


```javascript
dataLayer.push({
  event: 'page_view', // Or any custom events
  page_category: 'Product page', 
  page_title: 'Product name | Nameless Analytics', 
  page_location: '/product_name'
});
```

> Make sure to [override the page parameters](https://github.com/nameless-analytics/client-side-tracker-configuration-variable#page-data) in the Nameless Analytics Client-side Tracker Configuration Variable otherwise the updated page data will not set set correctly.



## How to set up cross-domain tracking
Nameless Analytics utilizes server-side **HttpOnly cookies** for maximum security and data integrity. 

Since these cookies are inaccessible to client-side JavaScript, the tracker employs a real-time 'handshake' mechanism via a specific event called **`get_user_data`**. 

When a user clicks an outbound link to a tracked domain, the tracker intercepts the click and sends an asynchronous `get_user_data` request to the Server-side GTM endpoint. The server extracts the `client_id` and `session_id` from the secure cookies and returns them to the tracker, which then decorates the destination URL with the **`na_id`** parameter (e.g., `https://destination.com/?na_id=...`). This ensures 100% accurate session stitching even across different domains.

To ensure proper DNS resolution, the IP addresses of the Google App Engine, Cloud Run or Stape instances running the server-side GTM container must be correctly associated with each respective domain.

Follow these guides for:
- Google App Engine [standard](https://cloud.google.com/appengine/docs/standard/mapping-custom-domains) and [flexible](https://cloud.google.com/appengine/docs/flexible/mapping-custom-domains) environments
- [Google Cloud Run](https://cloud.google.com/run/docs/mapping-custom-domains)
- [Stape](https://help.stape.io/hc/en-us/articles/4405367809681-How-to-setup-custom-domain-for-server-side-Google-Tag-Manager)

> If IDs are not passing between domains, verify your [Cross-domain Troubleshooting](TROUBLESHOOTING.md#network--custom-endpoint-issues) steps.



### One client-side GTM container for both sites
To configure cross domain tracking you need to: 

1. Enable cross-domain tracking in the Nameless Analytics Client-side Tracker Configuration Variable and add the domains to the list (one per row).

    ![Lookup Table for dynamic endpoints](https://github.com/user-attachments/assets/c8ab4d08-5069-4833-8465-5ca4ddea0863)

2. Create a **Regex Lookup Table** variable to dynamically switch the endpoint domain based on the current page hostname:

    ![Lookup Table for dynamic endpoints](https://github.com/user-attachments/assets/a7b54f23-18b5-4e54-ba80-216a06a51f2d)

3. Set this dynamic variable in the **Request endpoint domain** field. 

    ![Dynamic request endopoint domain](https://github.com/user-attachments/assets/3d052798-20d9-4578-ab00-35ff4edca695)


### Two client-side GTM containers, one per site
To configure cross-domain tracking across separate containers, follow these steps:

1. **Enable Cross-Domain Tracking**: In each Nameless Analytics Client-side Tracker Configuration Variable, enable the cross-domain option and add the counterparty domain to the domain list.

    - For **namelessanalytics.com**, the counterparty domain will be `tommasomoretti.com`.
    - For **tommasomoretti.com**, the counterparty domain will be `namelessanalytics.com`.


2. **Configure Request Endpoints**: Set the **Request endpoint domain** field for each container to point to its respective server-side GTM subdomain.

    - For **namelessanalytics.com**, the endpoint will be `gtm.namelessanalytics.com`.
    - For **tommasomoretti.com**, the endpoint will be `gtm.tommasomoretti.com`.


### One server-side GTM container for both sites
If **Accept requests from authorized domains only** option is enabled in **Nameless Analytics Server-side Client** configuration, ensure that all domains involved in the cross-domain setup are explicitly added to the **Authorized domains** list. This prevents requests from being blocked when the tracker switches domains.

The container must be configured as well. Add the domains in the Admin > Container settings of the Server-side Google Tag Manager.

![Add multiple domains to server-side GTM](https://github.com/user-attachments/assets/53eb03cd-8fdf-437b-b0e2-aa92d7bcef4e)

To select a domain for the preview mode, click the icon near the preview button and select a domain.

This ensures the `Domain` attribute in the `Set-Cookie` header will always match the request origin browser-side.

![Dynamic endpoint correct configuration](https://github.com/user-attachments/assets/10db0a72-c743-4504-b3aa-adcb487fb9ad)

Otherwise the Set-Cookie header will be blocked by the browser.

![Dynamic endpoint configuration error](https://github.com/user-attachments/assets/66d39b81-6bf3-4af4-8663-273d00ae9515)



### Two server-side GTM containers, one per site
_Section coming soon. This configuration is recommended for multi-region setups or strict data residence requirements._



## How to setup and customize ecommerce tracking
Nameless Analytics supports full ecommerce tracking following the standard GA4 schema.

### Ecommerce Tracking Initialization
The system is designed to automatically capture ecommerce data from your website's `dataLayer`, provided it follows the standard GA4 format.

**1. DataLayer Requirement**
Your website must push ecommerce events to the `dataLayer` using the standard structure (e.g., `view_item`, `add_to_cart`, `begin_checkout`, `purchase`). The tracker will automatically look for the `ecommerce` object within the event that triggers the tag.

**2. Tracker Configuration**
In your GTM Client-side Tracker Tag configuration:
- Ensure the **"Send ecommerce data"** checkbox is enabled. 
- This tells the tracker to capture the `ecommerce` object from the current dataLayer state and include it in the payload sent to the server.

**3. Server-side Processing**
The Nameless Analytics Server-side Client Tag receives the request, extracts the `ecommerce` data and stores it directly in the `ecommerce` column of your BigQuery `events_raw` table. 

No additional mapping is required if you follow the standard schema. If ecommerce data uses a non-standard schema, you can still track ecommerce by modifying the extraction paths in the BigQuery SQL Table Functions.


### Advanced Ecommerce Reporting
Once data is in BigQuery, you can leverage built-in Table Functions for deep analysis. These functions process the raw JSON and flatten it into structured reporting tables:

- **[Transactions](../tables/TABLES.md#transactions)**: Provides a high-level view of orders: revenue, tax, shipping, and transaction IDs.
- **[Products](../tables/TABLES.md#products)**: Flattens the items array to show performance per product (quantity sold, item revenue, variants, etc.).
- **[Shopping stages (Open Funnel)](../tables/TABLES.md#shopping-stages-open-funnel)**: Analyzes the Open Funnel from item view to purchase.
- **[Shopping stages (Closed Funnel)](../tables/TABLES.md#shopping-stages-closed-funnel)**: Analyzes the Closed Funnel from item view to purchase.

---

Reach me at: [Email](mailto:hello@namelessanalytics.com) | [Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_setup_guides) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
