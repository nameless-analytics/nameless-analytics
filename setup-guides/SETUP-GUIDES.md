# Nameless Analytics | Setup guides
The Nameless Analytics Setup guides provide instructions for configuring the platform across both client-side and server-side environments.
For an overview of how Nameless Analytics works [start from here](../README.md#overview).

### 🚧 Nameless Analytics and the documentation are currently in beta and subject to change



## Table of Contents

- [How to set up Nameless Analytics in GTM](#how-to-set-up-nameless-analytics-in-gtm)
- [How to track page views](#how-to-track-page-views)
- [How to track standard events](#how-to-track-standard-events)
- [How to track custom events](#how-to-track-custom-events)
- [How to set up User ID and user properties](#how-to-set-up-user-id-and-user-properties)
- [How to respect user consents](#how-to-respect-user-consents)
- [How to set up cross-domain tracking](#how-to-set-up-cross-domain-tracking)
- [How to set up and customize ecommerce tracking](#how-to-set-up-and-customize-ecommerce-tracking)
- [How to send events via Streaming Protocol](#how-to-send-events-via-streaming-protocol)
- [How to set up First-Party Library Hosting](#how-to-set-up-first-party-library-hosting)
- [How to configure Real-time Forwarding](#how-to-configure-real-time-forwarding)
- [How to enforce Security & Bot Protection](#how-to-enforce-security--bot-protection)
- [How to configure a Conversational Analysis Agent in BigQuery Studio](#how-to-configure-a-conversational-analysis-agent-in-bigquery-studio)
- [Data Governance & Privacy compliance](#data-governance--privacy-compliance)



## How to set up Nameless Analytics in GTM
Setting up Nameless Analytics involves using a dual GTM containers strategy, combining a client-side container with a server-side one. The implementation is streamlined through three custom templates.

**Encountering issues during setup?** Check the [Troubleshooting guide](TROUBLESHOOTING-GUIDE.md).


### 1. Prerequisites
Before proceeding, ensure the Google Cloud environment is fully provisioned:
- **BigQuery**: Dataset, `events_raw` and `calendar_dates` tables must be created according to the [SQL schemas](../tables/TABLES.md).
- **Firestore**: A database instance (Native Mode) should be initialized (usually the `(default)` instance).
- **Server-side GTM**: The instance (Cloud Run, App Engine or Stape) must be active and mapped to a custom first-party domain.


### 2. Template Integration
Download and import the `.tpl` files into GTM Client-side and Server-side environments with the following steps: 
1. Navigate to **Templates**
2. Click **New** in the Tag Templates or Variable Templates section
3. Click the **three dots menu** (top right) and select **Import**
4. Upload the corresponding `.tpl` file and **Save**


### 3a. Client-side Container Configuration
Create a new:
1. GTM variable using the template **Nameless Analytics Client-side Tracker Configuration Variable** 
  - Under **Endpoint Domain Name**, set the endpoint domain name of Server-side GTM (e.g., `gtm.yourdomain.com`)
  - Under **Endpoint Path**, set the **path** of your dedicated Server-side GTM URL (e.g., `/na/collect`)
2. GTM tag using the template **Nameless Analytics Client-side Tracker Tag**
  - Under **Event name**, select **standard event name** and then **page view**
  - Under **Configuration variable settings**, add the created **Nameless Analytics Client-side Tracker Configuration Variable**
  - Use **All Pages** as trigger for the tag


### 3b. Server-side Container Configuration
Create a new:
1. GTM client tag using the template **Nameless Analytics Server-side Client Tag**
  - Under **Request Endpoint Path**, set the **path** of your dedicated Server-side GTM URL (e.g., `/na/collect`)
  - Under **Google BigQuery Project ID**, set the **ID** of your BigQuery project
  - Under **Google BigQuery Dataset ID**, set the **ID** of your BigQuery dataset
  - Under **Google BigQuery Table ID**, set the **ID** of your BigQuery table


### 4. Pipeline Validation & QA
1. Launch **Preview Mode** for both the Web and Server containers simultaneously.
2. Interacting with the website verify tracker initialization via JavaScript console logs.
3. In the Server-side GTM preview, verify that incoming requests are correctly received and processed by the **Nameless Analytics Server-side Client Tag**
4. For every claimed event, verify that user and session data are successfully written or updated to Firestore and to BigQuery.



## How to track page views
Page view tracking is not only used to track the number of page views on a website, they are responsible for creating and updating sessions and users in Firestore, releasing cookies and more. 

For this reason, the `page_view` event must be the **first** event triggered on every page load. Triggering other events before it will result in [orphan events](TROUBLESHOOTING-GUIDE.md#orphan-events--sequence-issues). 

Page view tags can be triggered in many ways:


### Via GTM standard page view trigger
Using any standard GTM trigger (such as **All Pages**).


### Via browser history (Route change)
Using history changes `pushState` or `replaceState`. Make sure to update the page title and any relevant dataLayer parameters before the history change otherwise the Page Title and Page Category will not be set correctly.

This is the preferred method for SPAs since the page referrer for virtual page views is maintained even if a page is reloaded and page information is retrieved automatically from the history state.


```javascript
document.title = 'Product name | Nameless Analytics';
dataLayer.push({
  page_category: 'Product page'
});
history.pushState('', '', '/product_name');
```


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

Make sure to [override the page parameters](https://github.com/nameless-analytics/client-side-tracker-configuration-variable#page-data) in the Nameless Analytics Client-side Tracker Configuration Variable otherwise the updated page data will not be set correctly.



## How to track standard events
Nameless Analytics supports several standard events to measure common user interactions and performance metrics. To track these, push the specific event to the `dataLayer` and map any required variables in Google Tag Manager using the **Nameless Analytics Client-side Tracker Tag**.

### Consent Update
Fired when a user updates their privacy consent preferences. No custom parameters are required.

Setup:
- **Create the Trigger**: Create a Custom Event Trigger matching the event name `consent_update` (or whatever your Consent Management Platform calls it).
- **Configure the Tag**: Create a new **Nameless Analytics Client-side Tracker Tag**, select the `consent_update` event and assign the trigger to it.


### Page Load Time
Measures the time it takes for a page to fully load. 

Setup:
- **Create the Trigger**: Create a Trigger for when the page has fully loaded using the **Window Loaded** event.
- **Create a Variable**: Create a Custom JavaScript Variable for `total_page_load_time`.
- **Configure the Tag**: Create a new **Nameless Analytics Client-side Tracker Tag**, select the `page_load_time` event and assign the trigger to it.
- **Map the Parameter**: Expand the **Event Parameters** section within the tag configuration and add the `total_page_load_time` parameter, assigning the Custom JavaScript Variable you created as its value.

Custom JavaScript Variable code for total_page_load_time:

```javascript
function() {
  if (!window.performance) return;

  try {
    if (performance.getEntriesByType) {
      var navEntries = performance.getEntriesByType("navigation");
      if (navEntries && navEntries.length > 0) {
        var nav = navEntries[0];
        if (nav.loadEventEnd > 0) {
          return Math.round(nav.loadEventEnd - nav.startTime);
        }
      }
    }
  } catch (e) {}

  try {
    if (performance.timing) {
      var t = performance.timing;
      if (t.loadEventEnd > 0) {
        return t.loadEventEnd - t.navigationStart;
      }
    }
  } catch (e) {}

  return;
}
```


### Page Closed
Fired when a user leaves or closes the page.

Setup:
- **Enable scroll depth trigger**: Enable **scroll depth trigger** built-in feature in GTM.
- **Create the Trigger**: Create a Custom Event Trigger matching the event name `scrollDepth`.
- **Configure the Tag**: Create a new **Nameless Analytics Client-side Tracker Tag**, select the `page_closed` event and assign the trigger to it.


### Search Results View
Fired when a user views a search results page.

Setup:
- **Push dataLayer**: push the `search_result_view` event to the `dataLayer` along with `search_term` parameter.

```javascript
dataLayer.push({
  event: 'search_result_view',
  search_term: 'analytics'
});
```

- **Create the Trigger**: Create a Custom Event Trigger matching the event name `search_result_view`.
- **Create a Variable**: Create a Data Layer Variable for the `search_term`.
- **Configure the Tag**: Create a new **Nameless Analytics Client-side Tracker Tag**, select the `search_result_view` event and assign the trigger to it.
- **Map the Parameter**: Expand the **Event Parameters** section within the tag configuration and add the `search_term` parameter, assigning the DataLayer Variable you created as its value.


### Search Result Click
Fired when a user clicks on a specific search result.

Setup:
- **Push dataLayer**: push the `search_result_click` event to the `dataLayer` along with `search_term` and `search_results_name` parameters.

```javascript
dataLayer.push({
  event: 'search_result_click',
  search_term: 'analytics',
  search_results_name: 'Introduction to Web Analytics'
});
```

- **Create the Trigger**: Create a Custom Event Trigger matching the event name `search_result_click`.
- **Create Variables**: Create two Data Layer Variables for `search_term` and `search_results_name`.
- **Configure the Tag**: Create a new **Nameless Analytics Client-side Tracker Tag**, select the `search_result_click` event and assign the trigger to it.
- **Map the Parameter**: Expand the **Event Parameters** section within the tag configuration and add both the `search_term` and `search_results_name` parameters, assigning the DataLayer Variables you created as their values.


### Authentication
Fired when a user logs in, logs out, or signs up. 
For these events, the `user_id` must be mapped within the Nameless Analytics Client-side Tracker Configuration Variable, under the **Session Data** section using the **User ID** field.

```javascript
dataLayer.push({
  event: 'login', // Or 'logout', 'sign_up'
  user_id: 'ABC-12345'
});
```

Setup:
- **Create the Trigger**: Create a Custom Event Trigger matching the event name (e.g., `login`, `logout`, or `sign_up`).
- **Create a Variable**: Create a Data Layer Variable for the `user_id`.
- **Configure the Tag**: Create a new **Nameless Analytics Client-side Tracker Tag**, select the `login` event (or `logout` or `sign_up`) and assign the trigger to it.
- **Map the Parameter**: Open the **Nameless Analytics Client-side Tracker Configuration Variable**. Under the **Session Data** section, map the `user_id` field to the DataLayer Variable you created.



## How to track custom events
You can track any custom interaction (e.g., button clicks, form submissions, file downloads) by pushing a custom event to the `dataLayer` and mapping its variables in Google Tag Manager.

### 1. Fire a custom event
Push a custom event and its associated context parameters to the `dataLayer`:

```javascript
dataLayer.push({
  event: 'generate_lead',
  lead_type: 'b2b_consulting',
  lead_value: 500
});
```

### 2. Configure the GTM Tag
- **Create the Trigger**: Create a Custom Event Trigger matching your event name (e.g., `generate_lead`).
- **Create DataLayer Variables**: Create Data Layer Variables for the custom parameters (e.g., `lead_type` and `lead_value`).
- **Configure the Tag**: Create a new **Nameless Analytics Client-side Tracker Tag** and assign the trigger to it.
- **Map the Parameters**: Expand the **Event Parameters** section within the tag configuration and add your custom parameters in the table, assigning the DataLayer Variables you created as their values.

When the tag fires, it will automatically use the `event` key as the final `event_name` in BigQuery and map all the configured parameters into the `event_data` array column.



## How to set up User ID and user properties
To track authenticated users across devices and enrich their profiles with custom metadata (e.g., subscription tier, company size), use the `user_id` and custom User Properties. 

User ID will be applied at session level and will be stored in Firestore as well as in the BigQuery `session_data` array for each event.

User Properties will be applied at user level and will be stored in Firestore as well as in the BigQuery `user_data` array for each event.


### 1. Expose user data to the dataLayer
When a user logs in or is identified, push their unique ID and any relevant profile properties to the `dataLayer` prior to firing any tags:

```javascript
dataLayer.push({
  user_id: 'USR-987654321',
  user_tier: 'Premium'
});
```

### 2. Configure Nameless Analytics Client-side Tracker Configuration Variable
1. Create Data Layer Variables for `user_id` and any custom properties you exposed (e.g., `user_tier`).
2. Open the **Nameless Analytics Client-side Tracker Configuration Variable**.
3. Under **Session parameters** section, map the `user_id` field to the `user_id` DataLayer Variable.
4. Under **User parameters** section, map your custom metadata (e.g., `user_tier`) to their respective DataLayer Variables.



## How to respect user consents
Nameless Analytics natively integrates with Google Consent Mode to ensure privacy compliance while maximizing data attribution accuracy.


### 1. Enable Consent Initialization
Ensure that your Consent Management Platform (CMP) or custom HTML script triggers the default `gtag('consent', 'default', ...)` command **before** the Google Tag Manager container loads.


### 2. Configure the Tracker Variable
In your GTM Client-side workspace, locate the **Nameless Analytics Client-side Tracker Configuration Variable**.
Under the "Consent Settings" section, ensure the **Respect Google Consent Mode** option is enabled.

When this option is enabled:
- If `analytics_storage` is `granted`, tracking proceeds normally.
- If `analytics_storage` is `denied`, the tracker halts all request transmissions and waits for the user's consent update.
- If Consent Mode is entirely missing from the page, the tag aborts execution to prevent accidental non-compliant tracking.


### 3. Preserving Acquisition Data (The na_temp cookie)
Nameless Analytics features a "Smart Consent Management" system to prevent attribution loss (like turning organic traffic into "direct" traffic) while users navigate your site before accepting cookies.

When a user lands on the site and `analytics_storage` is `denied`, the Client-side Tracker intercepts the acquisition parameters (UTMs, Referrer, etc.) and temporarily stores them in a first-party session cookie named `na_temp`. 

Once the user accepts the cookie policy and the CMP fires the `gtag('consent', 'update', {'analytics_storage': 'granted'})` event:
1. The tracker reads the original acquisition data from the `na_temp` cookie.
2. It enriches the pending session with the correct original source.
3. It flushes all newly authorized events to the server.
4. The `na_temp` cookie is securely deleted on the next available page view.

This mechanism is designed to support consent-aware attribution while preserving the original acquisition context when analytics consent is granted.



## How to set up cross-domain tracking
Nameless Analytics utilizes server-side **HttpOnly cookies** for maximum security and data integrity. 

Since these cookies are inaccessible to client-side JavaScript, the tracker employs a real-time 'handshake' mechanism via a specific event called **`get_user_data`**. 

When a user clicks an outbound link to a tracked domain, the tracker intercepts the click and sends an asynchronous `get_user_data` request to the Server-side GTM endpoint. The server extracts the `client_id` and `session_id` from the secure cookies and returns them to the tracker, which then decorates the destination URL with the **`na_id`** parameter (e.g., `https://destination.com/?na_id=...`). This improves session stitching reliability across tracked domains.

To ensure proper DNS resolution, the IP addresses of the Google App Engine, Cloud Run or Stape instances running the server-side GTM container must be correctly associated with each respective domain.

Follow these guides for:
- Google App Engine [standard](https://cloud.google.com/appengine/docs/standard/mapping-custom-domains) and [flexible](https://cloud.google.com/appengine/docs/flexible/mapping-custom-domains) environments
- [Google Cloud Run](https://cloud.google.com/run/docs/mapping-custom-domains)
- [Stape](https://help.stape.io/hc/en-us/articles/4405367809681-How-to-setup-custom-domain-for-server-side-Google-Tag-Manager)


### One client-side GTM container for multiple sites
To configure cross domain tracking you need to: 

1. Enable cross-domain tracking in the Nameless Analytics Client-side Tracker Configuration Variable and add the domains to the list (one per row).

    ![Lookup Table for dynamic endpoints](https://github.com/user-attachments/assets/c8ab4d08-5069-4833-8465-5ca4ddea0863)

2. Create a **Regex Lookup Table** variable to dynamically switch the endpoint domain based on the current page hostname:

    ![Lookup Table for dynamic endpoints](https://github.com/user-attachments/assets/a7b54f23-18b5-4e54-ba80-216a06a51f2d)

3. Set this dynamic variable in the **Request endpoint domain** field. 

    ![Dynamic request endpoint domain](https://github.com/user-attachments/assets/3d052798-20d9-4578-ab00-35ff4edca695)


### Two client-side GTM containers, one per site
To configure cross-domain tracking across separate containers, follow these steps:

1. **Enable Cross-Domain Tracking**: In each Nameless Analytics Client-side Tracker Configuration Variable, enable the cross-domain option and add the counterparty domain to the domain list.

    - For **namelessanalytics.com**, the counterparty domain will be `tommasomoretti.com`.
    - For **tommasomoretti.com**, the counterparty domain will be `namelessanalytics.com`.


2. **Configure Request Endpoints**: Set the **Request endpoint domain** field for each container to point to its respective server-side GTM subdomain.

    - For **namelessanalytics.com**, the endpoint will be `gtm.namelessanalytics.com`.
    - For **tommasomoretti.com**, the endpoint will be `gtm.tommasomoretti.com`.


### One server-side GTM container for multiple sites
If **Accept requests from authorized top-level domains only** option is enabled in **Nameless Analytics Server-side Client** configuration, ensure that all domains involved in the cross-domain setup are explicitly added to the **Authorized top-level domains** list. This prevents requests from being blocked when the tracker switches domains.

The endpoint path must be unique for all domains.

![Authorized top-level domains](https://github.com/user-attachments/assets/d6172c1a-4171-46e5-9c57-c6ad0157b082)

The container must be configured as well. Add the domains in the Admin > Container settings of the Server-side Google Tag Manager.

![Add multiple domains to server-side GTM](https://github.com/user-attachments/assets/53eb03cd-8fdf-437b-b0e2-aa92d7bcef4e)

To select a domain for the preview mode, click the icon near the preview button and select a domain.

This ensures the `Domain` attribute in the `Set-Cookie` header will always match the request origin browser-side.

![Dynamic endpoint correct configuration](https://github.com/user-attachments/assets/10db0a72-c743-4504-b3aa-adcb487fb9ad)

Otherwise the Set-Cookie header will be blocked by the browser.

![Dynamic endpoint configuration error](https://github.com/user-attachments/assets/66d39b81-6bf3-4af4-8663-273d00ae9515)


### Two server-side GTM containers, one per site
No special configuration is required as requests per domain are handled independently by two separate Nameless Analytics Server-side Client Tags.



## How to set up and customize ecommerce tracking
Nameless Analytics supports full ecommerce tracking following the standard GA4 schema.

### Ecommerce Tracking Initialization
The system is designed to automatically capture ecommerce data from your website's `dataLayer`, provided it follows the standard GA4 format. 

If ecommerce data uses a non-standard schema, you can still track ecommerce by modifying the extraction paths in the BigQuery SQL Table Functions.

### 1. DataLayer Requirement
Your website must push ecommerce events to the `dataLayer` using the standard structure (e.g., `view_item`, `add_to_cart`, `begin_checkout`, `purchase`). The tracker will automatically look for the `ecommerce` object within the event that triggers the tag.

### 2. Tracker Configuration
In your GTM Client-side Tracker Tag configuration:
- Ensure the **"Add ecommerce data"** checkbox is enabled. 
- This tells the tracker to capture the `ecommerce` object from the current dataLayer state and include it in the payload sent to the server.

### 3. Server-side Processing
The Nameless Analytics Server-side Client Tag receives the request, extracts the `ecommerce` data and stores it directly in the `ecommerce` column of your BigQuery `events_raw` table. 

If ecommerce data uses a non-standard schema, you can still track ecommerce by modifying the JSON extraction paths in the BigQuery [transactions](../tables/TABLES.md#transactions) and [products](../tables/TABLES.md#products) Table Functions.


### Advanced Ecommerce Reporting
Once data is in BigQuery, you can leverage built-in Table Functions for deep analysis. These functions process the raw JSON and flatten it into structured reporting tables:

- **[Transactions](../tables/TABLES.md#transactions)**: Provides a high-level view of orders: revenue, tax, shipping, and transaction IDs.
- **[Products](../tables/TABLES.md#products)**: Flattens the items array to show performance per product (quantity sold, item revenue, variants, etc.).
- **[Ecommerce Funnel](../tables/TABLES.md#ecommerce-funnel)**: Analyzes the ecommerce funnel from item view to purchase.



## How to send events via Streaming Protocol
The Streaming Protocol is specifically designed for server-to-server communication, allowing you to attribute offline or backend interactions (e.g., status changes, recurring payments, or CRM updates) to a user's session without a browser. For implementation examples and technical details, refer to the [Streaming Protocol documentation](../streaming-protocol/STREAMING-PROTOCOL.md).



## How to set up First-Party Library Hosting
To maximize data collection accuracy and prevent ad-blockers or Intelligent Tracking Prevention (ITP) algorithms from blocking the tracker execution, Nameless Analytics allows you to serve its core dependencies directly from your own domain rather than relying on public CDNs (like `jsdelivr.net`).

By doing so, the browser will treat the tracker scripts as critical, first-party website assets, significantly reducing the chances of them being blocked by privacy extensions.

### 1. Download the core libraries
Download the raw code of the two required JavaScript files:
1. **[nameless-analytics.js](https://github.com/nameless-analytics/client-side-tracker-tag/blob/main/lib/nameless-analytics.js)**: The main execution engine.
2. **[ua-parser.min.js](https://github.com/faisalman/ua-parser-js/blob/master/dist/ua-parser.min.js)**: The dependency used for precise User-Agent parsing.

### 2. Host the libraries on your infrastructure
Upload both `.js` files to your own server or Content Delivery Network (CDN). 
Ensure they are served over HTTPS and from the exact same primary domain as your website (for example: `https://www.yourdomain.com/assets/js/nameless-analytics.js`).

### 3. Update the GTM Configuration
1. Open your Client-side Google Tag Manager workspace.
2. Navigate to the **Nameless Analytics Client-side Tracker Configuration Variable**.
3. Expand the **Advanced settings** section.
4. Replace the default CDN URLs with the absolute URLs of your newly hosted first-party scripts.

### 4. Authorize the new domain in the template permissions
Google Tag Manager blocks script injections from unauthorized domains by default to protect the site from XSS.
1. In your GTM workspace, go to the **Templates** section.
2. Open the **Nameless Analytics Client-Side Tracker Tag** template.
3. Switch to the **Permissions** tab.
4. Expand the **Injects scripts** permission.
5. Add your new custom domain URL pattern (e.g., `https://www.yourdomain.com/*`) so that GTM allows the template to fetch the scripts from it.
6. Save the template and publish the container.

> **Note on Content Security Policy (CSP)**: If your website enforces a strict CSP, ensuring these libraries are loaded from your own origin will also prevent CSP violation errors that normally occur when pulling scripts from third-party networks.



## How to configure Real-time Forwarding
Nameless Analytics supports instantaneous data streaming to external HTTP endpoints immediately after an event is processed. This is ideal for activating your data in real-time across CRMs, marketing automation tools, or custom backend services.

The payload forwarded to the custom endpoint is the exact same enriched JSON that is stored in BigQuery, including server-side metadata like geolocation and channel grouping.

### Configuration Steps
1. Open the **Nameless Analytics Server-side Client Tag**.
2. Scroll down to **Advanced settings** and check **Send data to custom endpoint**.
3. Enter your **Destination URL** (e.g., `https://api.yourcrm.com/v1/events`).
4. If your API requires authentication, check **Add custom request headers**.
5. Populate the headers table with the required keys and values (e.g., `Authorization: Bearer your_token` or `x-api-key: your_key`).
6. Save the tag and publish the container.

> **Security Tip**: Since this request originates from your private server-side environment, sensitive credentials like API keys remain invisible to the user's browser, ensuring a secure server-to-server communication.



## How to enforce Security & Bot Protection
The Nameless Analytics Server-side Client Tag acts as a security gateway, allowing you to control which requests are processed and which are discarded.

### 1. Authorized top-level domains (CORS-like Protection)
To prevent unauthorized websites from sending data to your endpoint, you can restrict access to specific top-level domains.
1. Open the **Nameless Analytics Server-side Client Tag**.
2. Scroll down to **Advanced settings** and check **Accept requests from authorized top-level domains only**.
3. Add your domains to the **Authorized top-level domains** list (e.g., `https://www.yourdomain.com`).
4. Ensure you include all production, staging, and development domains.

### 2. Bot & Automated Traffic Protection
Nameless Analytics includes a built-in filter to block requests from known bots, scrapers, and automated libraries (e.g., curl, python-requests, chatgpt).
1. Scroll down to **Advanced settings** and check **Enable bot protection**.
2. All identified automated requests will be rejected with a `403 Forbidden` status. See the full list of blocked agents in the [main README](../README.md#bot-protection).

### 3. IP Blacklisting
If you identify specific IP addresses that are spamming your endpoint, you can manually block them.
1. Scroll down to **Advanced settings** and check **Add banned IPs**.
2. Add the target IP addresses to the **Banned IPs** list.



## How to configure a Conversational Analysis Agent in BigQuery Studio
In BigQuery Studio, you can configure a Data Agent (powered by Gemini) for conversational analysis, allowing users to query data in natural language. In order for the agent to provide accurate answers (in the form of text, tables, or charts) leveraging pre-calculated business logic, it must be properly configured by setting both raw tables and table functions as its knowledge sources.

### Knowledge Sources Configuration
During the agent creation in the BigQuery Studio Agent Catalog, ensure to:
1. **Select the Raw Tables:** Add the `events_raw` and `calendar_dates` tables to provide direct access to granular data and the time dimension.
2. **Select the Table Functions:** Add all the table functions provided in the project (such as `users`, `sessions`, `pages`, `events`, etc.). The agent will leverage their parameterized interface to query aggregated metrics and pre-calculated logic (e.g., session duration, acquisition channel).

### Best Practices for Accuracy
- **Metadata:** Carefully populate the parameter descriptions (metadata) within the functions and tables to help the agent understand the meaning of the various fields.
- **System Instructions:** Provide clear and contextual instructions to the agent on how to interpret and cross-reference the data.
- **Golden Queries:** Include real examples of questions and their corresponding verified SQL queries. This step is essential to train the model to understand your specific business context and ensure it always returns syntactically and logically correct queries.



## Data Governance & Privacy compliance
To comply with GDPR "Right to be Forgotten" (RTBF) requests, data must be removed from both the historical timeline (**BigQuery**) and the real-time snapshots (**Firestore**).

The most efficient way to handle these requests is using the provided automation:
**[User Data Deletion Script](../tables/TABLES.md#delete-user-data-script)**: A Python utility to delete a specific `client_id` from both BigQuery and Firestore in a single operation. This is the recommended method.

Alternatively, you can perform [manual deletions](../tables/TABLES.md#manual-user-data-deletion).


---

Reach me at: [Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_setup_guides) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
