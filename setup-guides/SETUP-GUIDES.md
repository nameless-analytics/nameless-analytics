# Nameless Analytics | Setup guides
The Nameless Analytics Setup guides is a coockbook of guides to help you set up Nameless Analytics. 

For an overview of how Nameless Analytics works [start from here](https://github.com/nameless-analytics/nameless-analytics/#high-level-data-flow).

🚧 **Nameless Analytics is currently in beta and is subject to change.** 🚧



## Table of Contents
- [How to set up Nameless Analytics in GTM](#how-to-set-up-nameless-analytics-in-gtm)
- [How to track page views](#how-to-track-page-views)
- [How to trigger virtual page views](#how-to-trigger-virtual-page-views)
- [How to set up cross-domain tracking](#how-to-set-up-cross-domain-tracking)

## How to set up Nameless Analytics in GTM



## How to track page views



## How to trigger virtual page views
You can trigger a virtual page view in two ways: by updating the browser history (SPA route change) or by using a custom dataLayer event.


### Via browser history (Route change)
Virtual page views can be triggered upon history changes using `pushState` or `replaceState`. Ensure you update the page title and any relevant dataLayer parameters *before* the history change.

```javascript
document.title = 'Product name | Nameless Analytics';
dataLayer.push({
  page_category: 'Product page'
});
history.pushState('', '', '/product_name');
```


### Via custom dataLayer event
Virtual page views can be also triggered upon custom dataLayer events.

```javascript
dataLayer.push({
  event: 'virtual_page_view', // Or any custom events
  page_category: 'Product page', 
  page_title: 'Product name | Nameless Analytics', 
  page_location: '/product_name'
```



## How to set up cross-domain tracking
To configure cross domain tracking you need to: 

Enable cross-domain tracking in the Nameless Analytics Client-side Tracker Configuration Variable.

Add the domains to the list (one per row).

![Lookup Table for dynamic endpoints](https://github.com/user-attachments/assets/c8ab4d08-5069-4833-8465-5ca4ddea0863)

Create a **Regex Lookup Table** variable to dynamically switch the endpoint domain based on the current page hostname:

![Lookup Table for dynamic endpoints](https://github.com/user-attachments/assets/a7b54f23-18b5-4e54-ba80-216a06a51f2d)

Set this dynamic variable in the **Request endpoint domain** field. 

[Dynamic request endpoint domain](https://github.com/user-attachments/assets/859e11f1-1d5e-4b62-9d9f-03325c1517cc)


This ensures the `Domain` attribute in the `Set-Cookie` header will always match the request origin browser-side.

![Dynamic endpoint correct configuration](https://github.com/user-attachments/assets/10db0a72-c743-4504-b3aa-adcb487fb9ad)

Otherwise the Set-Cookie header will be blocked by the browser.

![Dynamic endpoint configuration error](https://github.com/user-attachments/assets/66d39b81-6bf3-4af4-8663-273d00ae9515)

---

Reach me at: [Email](mailto:hello@tommasomoretti.com) | [Website](https://tommasomoretti.com/?utm_source=github.com&utm_medium=referral&utm_campaign=nameless_analytics) | [Twitter](https://twitter.com/tommoretti88) | [LinkedIn](https://www.linkedin.com/in/tommasomoretti/)
