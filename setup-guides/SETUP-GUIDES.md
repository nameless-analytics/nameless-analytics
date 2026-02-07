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

**Encountering issues during setup?** Check the [Configuration Troubleshooting](TROUBLESHOOTING.md#library-loading--configuration-issues) section if your tags aren't firing or the [Validation Errors](TROUBLESHOOTING.md#validation-errors-403-forbidden) if you see 403 Forbidden errors.

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
Page views can be triggered in many ways:


### Via GTM standard page view trigger
Use every trigger in GTM to trigger a page view like `gtm.js`.


### Via browser history (Route change)
Page views can be triggered upon history changes using `pushState` or `replaceState`. 

This is the preferred method for SPAs since the page referrer for virtual page views is maintained even if a page is reloaded and page information is retrieved automatically from the history state.

Ensure you **update the page title and any relevant dataLayer parameters before the history change**.

```javascript
document.title = 'Product name | Nameless Analytics';
dataLayer.push({
  page_category: 'Product page'
});
history.pushState('', '', '/product_name');
```


### Via custom dataLayer event
Page views can be also triggered upon custom dataLayer events.

Make sure to [override the page parameters](https://github.com/nameless-analytics/client-side-tracker-configuration-variable#page-data) in the Nameless Analytics Client-side Tracker Configuration Variable otherwise the updated page data will not set set correctly.

```javascript
dataLayer.push({
  event: 'page_view', // Or any custom events
  page_category: 'Product page', 
  page_title: 'Product name | Nameless Analytics', 
  page_location: '/product_name'
});
```

> [!WARNING]
> Ensure that the `page_view` event is the **first** event triggered on every page load. Triggering other events before it will result in [Orphan Events](TROUBLESHOOTING.md#orphan-events--sequence-issues).



## How to set up cross-domain tracking
### One client-side GTM container for both sites
To configure cross domain tracking you need to: 

Enable cross-domain tracking in the Nameless Analytics Client-side Tracker Configuration Variable and add the domains to the list (one per row).

![Lookup Table for dynamic endpoints](https://github.com/user-attachments/assets/c8ab4d08-5069-4833-8465-5ca4ddea0863)

Create a **Regex Lookup Table** variable to dynamically switch the endpoint domain based on the current page hostname:

![Lookup Table for dynamic endpoints](https://github.com/user-attachments/assets/a7b54f23-18b5-4e54-ba80-216a06a51f2d)

Set this dynamic variable in the **Request endpoint domain** field. 

![Dynamic request endopoint domain](https://github.com/user-attachments/assets/3d052798-20d9-4578-ab00-35ff4edca695)

> [!TIP]
> If IDs are not passing between domains, verify your [Cross-domain Troubleshooting](TROUBLESHOOTING.md#network--custom-endpoint-issues) steps.


### Two client-side GTM containers, one per site
To configure cross domain tracking you need to: 

Enable cross-domain tracking in each Nameless Analytics Client-side Tracker Configuration Variable and add the counterparty domain to the list.

For namelessanalytics.com the domain will be domain is tommasomoretti.com

![Counterparty domain](https://github.com/user-attachments/assets/6a8a277b-8689-49c3-9f8f-73b4d50c2f31)

For tommasomoretti.com the counterparty domain is namelessanalytics.com

![Counterparty domain](https://github.com/user-attachments/assets/7cce9ce6-6293-4585-8eec-704f02a67389)

Set the Request endpoint domain field for each container.

For namelessanalytics.com the domain will be domain is gtm.namelessanalytics.com

![Request endpoint domain](https://github.com/nameless-analytics/nameless-analytics/assets/placeholder) <!-- TODO: Add image asset URL -->


For tommasomoretti.com the domain will be domain is gtm.tommasomoretti.com

![Request endpoint domain](https://github.com/nameless-analytics/nameless-analytics/assets/placeholder) <!-- TODO: Add image asset URL -->



### One server-side GTM container for both sites

To ensure proper DNS resolution, the IP addresses of the Google App Engine or Cloud Run instances running the server-side GTM container must be correctly associated with each respective domain name.

Follow these guides for:
- [Google App Engine standard environment](https://cloud.google.com/appengine/docs/standard/mapping-custom-domains)
- [Google App Engine flexible environment](https://cloud.google.com/appengine/docs/flexible/mapping-custom-domains)
- [Google Cloud Run](https://cloud.google.com/run/docs/mapping-custom-domains)

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
_Section coming soon. Nameless Analytics supports standard GA4 ecommerce schemas. Detailed mapping guides will be provided in the next beta update._

---

Reach me at: [Email](mailto:hello@namelessanalytics.com) | [Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_setup_guides) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
