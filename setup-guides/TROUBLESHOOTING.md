# Nameless Analytics | Troubleshooting Guide

This guide helps you identify, understand, and resolve the most common issues encountered during the implementation of Nameless Analytics.

🚧 **Nameless Analytics is currently in beta and is subject to change.** 🚧

---

## Table of Contents
- [Orphan Events & Sequence Issues](#orphan-events--sequence-issues)
- [Server-Side Validation Errors (403 Forbidden)](#server-side-validation-errors-403-forbidden)
- [Google Consent Mode Challenges](#google-consent-mode-challenges)
- [Library Loading Issues](#library-loading-issues)
- [Data Inconsistency & Parameter Overriding](#data-inconsistency--parameter-overriding)

---

## Orphan Events & Sequence Issues

An **Orphan Event** is any interaction (click, scroll, etc.) that reaches the server without a valid session context established by a preceding `page_view` event.

### Symptom
- Browser console shows: `[event_name] > 🔴 Event fired before a page view event.`
- Server logs show: `🔴 Orphan event: missing user cookie` or `🔴 Orphan event: session doesn't exist in Firestore`.

### Common Causes & Solutions
1. **Race Conditions in GTM:**
   - **Issue:** An event tag (e.g., "Click Contact") fires before the "Page View" tag finishes setting up the session.
   - **Solution:** Ensure your Page View tag is triggered on `Consent Initialization` or `Initialization`, while interaction events are triggered on `Window Loaded` or custom events that occur later in the lifecycle.

2. **Expired Sessions:**
   - **Issue:** A user leaves a tab open for more than 30 minutes (default session timeout). When they return and click, the session cookie (`na_s`) has expired.
   - **Solution:** This is expected defensive behavior to ensure data integrity. Nameless Analytics rejects these to avoid "zombie" sessions without attribution.

3. **Missing `page_view` on SPAs:**
   - **Issue:** In Single Page Applications, a route change occurs but a Virtual Page View isn't triggered.
   - **Solution:** Follow the [Virtual Page View Setup Guide](SETUP-GUIDES.md#how-to-trigger-virtual-page-views) to ensure every state change initializes a new `page_id`.

---

## Server-Side Validation Errors (403 Forbidden)

The Server-Side Client Tag acts as a security gateway. If a request doesn't meet strict criteria, it is rejected with a `403 Forbidden` status.

### 1. Unauthorized Origin
- **Message:** `🔴 Request origin not authorized`
- **Fix:** Add the domain (e.g., `https://example.com`) to the **Authorized domains** list in the Server-Side Client Tag configuration.

### 2. Bot Detection
- **Message:** `🔴 Invalid User-Agent header value. Request from bot`
- **Fix:** Nameless Analytics blocks ~20 common bot/headless patterns (Puppeteer, Selenium, etc.). Ensure you are testing from a standard browser. If using the **Streaming Protocol**, ensure you send the mandatory UA: `nameless analytics - streaming protocol`.

### 3. Missing API Key (Streaming Protocol)
- **Message:** `🔴 Invalid API key`
- **Fix:** If "Add API key for Streaming protocol" is enabled, ensure your server-to-server request includes the `x-api-key` header with the correct value.

---

## Google Consent Mode Challenges

Nameless Analytics is deeply integrated with GCM. If consent isn't handled correctly, data might be lost or delayed.

### Symptom
- Console shows: `[event_name] > 🔴 analytics_storage denied` or `🔴 Google Consent Mode not found`.

### Common Scenarios
1. **Consent Granted Late:**
   - **Behavior:** The tracker automatically queues events if `analytics_storage` is pending. It releases them once consent is granted.
   - **Troubleshooting:** If events never fire even after consent, verify that your Consent Management Platform (CMP) correctly triggers a `gtag('consent', 'update', ...)` call.

2. **GCM Not Initialized:**
   - **Behavior:** If "Respect Google Consent Mode" is enabled but GCM isn't active, the tag aborts.
   - **Fix:** Ensure you have a default consent state defined *before* the GTM container loads.

---

## Library Loading Issues

The tracker requires `nameless-analytics.js` and `ua-parser.min.js` to function.

### Symptom
- Console shows: `🔴 Main library not loaded from: [URL]` or `🔴 Permission denied`.

### Solutions
1. **GTM Permissions:** Ensure the URLs for these libraries are added to the **Inject Scripts** permission in the GTM Template settings.
2. **Ad-Blockers:** Some ad-blockers block `jsdelivr.net` or scripts containing "analytics". 
   - **Premium Fix:** Use the "First-Party mode" by hosting these scripts on your own sub-domain (e.g., `https://gtm.yourdomain.com/lib/nameless-analytics.js`).

---

## Data Inconsistency & Parameter Overriding

If you see unexpected values in BigQuery, check the parameter hierarchy.

### Hierarchy Rules (High to Low Priority)
1. **Server-Side Tag Fields:** Highest priority. Hardcoded values here override everything.
2. **Client-Side Tag Fields:** Specific tag settings.
3. **Configuration Variable Fields:** Shared settings for all tags.
4. **dataLayer:** Parameters found in the `dataLayer.push()` event.

### Troubleshooting Tip
Use the **GTM Server Preview Mode**. Check the "Inbound Request" to see what the browser sent, and the "Tags Fired" section to see how the Server-Side Client Tag modified the payload before sending it to BigQuery/Firestore.

---

Reach me at: [Email](mailto:hello@tommasomoretti.com) | [Website](https://tommasomoretti.com) | [Twitter](https://twitter.com/tommoretti88) | [LinkedIn](https://www.linkedin.com/in/tommasomoretti/)
