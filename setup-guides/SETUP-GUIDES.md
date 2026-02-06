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
1.  **Download Templates**: Get the latest GTM container templates from the [`gtm-containers/`](../gtm-containers/) directory.
2.  **Import to GTM**: In your GTM container, go to **Admin > Import Container**. Select the JSON file and choose **Merge** (with the 'Overwrite conflicting' or 'Rename' option).
3.  **Configure Variables**: Update the **Nameless Analytics Client-side Tracker Configuration Variable** with your Server-side GTM endpoint.
4.  **Publish**: Preview your changes and publish the container.



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
```



## How to set up cross-domain tracking
### One client-side GTM container for both sites
To configure cross domain tracking you need to: 

Enable cross-domain tracking in the Nameless Analytics Client-side Tracker Configuration Variable and add the domains to the list (one per row).

![Lookup Table for dynamic endpoints](https://github.com/user-attachments/assets/c8ab4d08-5069-4833-8465-5ca4ddea0863)

Create a **Regex Lookup Table** variable to dynamically switch the endpoint domain based on the current page hostname:

![Lookup Table for dynamic endpoints](https://github.com/user-attachments/assets/a7b54f23-18b5-4e54-ba80-216a06a51f2d)

Set this dynamic variable in the **Request endpoint domain** field. 

![Dynamic request endopoint domain](https://github.com/user-attachments/assets/3d052798-20d9-4578-ab00-35ff4edca695)

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



## One server-side GTM container for both sites

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



## Two server-side GTM containers, one per site
_Section coming soon. This configuration is recommended for multi-region setups or strict data residence requirements._



## How to setup and customize ecommerce tracking
_Section coming soon. Nameless Analytics supports standard GA4 ecommerce schemas. Detailed mapping guides will be provided in the next beta update._

---

Reach me at: [Email](mailto:hello@namelessanalytics.com) | [Website](https://namelessanalytics.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics_setup_guides) | [Twitter](https://x.com/nmlssanalytics) | [LinkedIn](https://www.linkedin.com/company/nameless-analytics/)
