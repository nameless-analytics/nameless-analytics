# Nameless Analytics | Setup guides
The Nameless Analytics Setup guides is a coockbook of guides to help you set up Nameless Analytics. 

For an overview of how Nameless Analytics works [start from here](https://github.com/nameless-analytics/nameless-analytics/#high-level-data-flow).

> Nameless Analytics is currently in beta and is subject to change.



## Table of Contents
- [How to trigger virtual page views](#how-to-trigger-virtual-page-views)



## How to trigger virtual page views
You can trigger a virtual page view in two ways: by updating the browser history (SPA route change) or by using a custom dataLayer event.

### Via browser history (Route change)
When using `pushState` or `replaceState` ensure you update the page title and any relevant dataLayer parameters *before* the history change.

```javascript
document.title = 'Product name | Nameless Analytics';
dataLayer.push({
  page_category: 'Product page'
});
history.pushState('', '', '/product_name');
```

### Via custom dataLayer event
If you prefer to trigger the virtual page view manually (or if you need to override browser properties), push the `virtual_page_view` event.

```javascript
dataLayer.push({
  event: 'virtual_page_view', // Or any custom events
  page_category: 'Product page', 
  page_title: 'Product name | Nameless Analytics', 
  page_location: '/product_name'
});
```

