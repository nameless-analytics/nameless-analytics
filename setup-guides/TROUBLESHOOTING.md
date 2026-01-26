# Nameless Analytics | Troubleshooting Guide

This guide helps you identify, understand, and resolve the most common issues encountered during the implementation of Nameless Analytics.

🚧 **Nameless Analytics is currently in beta and is subject to change.** 🚧



## Table of Contents
- [Troubleshooting Tip](#troubleshooting-tip)
- [Orphan Events & Sequence Issues](#orphan-events--sequence-issues)
- [Validation Errors (403 Forbidden)](#validation-errors-403-forbidden)
- [Google Consent Mode](#google-consent-mode)
- [Library Loading & Configuration Issues](#library-loading--configuration-issues)
- [Storage & Cloud Permissions](#storage--cloud-permissions)
- [Network & Custom Endpoint Issues](#network--custom-endpoint-issues)



## Troubleshooting Tip
Use the **Browser console** to check tags execution status and event data sent to the server.

Use the **GTM Server Preview Mode** to check incoming events and how the Server-Side Client Tag responds to them.

Inspect a network request to see the data sent by client from Preview and data response by server from Preview.



## Orphan Events & Sequence Issues
An **Orphan Event** is any interaction (click, scroll, etc.) that reaches the server without a valid session context established by a preceding `page_view` event or the requests is without a valid user and session cookie.


### Event error messages
Browser console shows: 

`[event_name] > 🔴 Event fired before a page view event. The first event on a page view ever must be page_view. Request aborted`

- **Issue:** An interaction event is fired before the `page_view` event has been dispatched.
- **Solution:** Nameless Analytics utilizes an internal fetch queue to manage requests, which prevents most race conditions. However, every events must be preceded by a `page_view` event. Ensure the page view is the first event sent at every page load.

Server logs show: 

`🔴 Orphan event: missing user cookie. Trigger a page_view event first to create a new user and a new session`

`🔴 Orphan event: missing session cookie. Trigger a page_view event first to create a new session`

- **Issue:** A user leaves a tab open for more than 30 minutes (default session timeout). When they return and click, the session cookie (`na_s`) has expired.
- **Solution:** This is expected defensive behavior to ensure data integrity. Nameless Analytics rejects these to avoid "zombie" sessions without attribution.

Server logs show: 

`🔴 Orphan event: user doesn't exist in Firestore. Trigger a page_view event first to create a new user and a new session`

`🔴 Orphan event: session doesn't exist in Firestore. Trigger a page_view event first to create a new session`

- **Issue:** Firestore does not contain a record for this user or session.
- **Solution:** Ensure the first event triggered on every page load is always a `page_view` to initialize the user and session profile in Firestore.



## Validation Errors (403 Forbidden)
The Server-Side Client Tag acts as a security gateway. If a request doesn't meet strict criteria, it is rejected with a `403 Forbidden` status.


### Error messages
Browser console shows: 

`[event_name] > 🔴 Request refused`

- **Issue:** The server-side Client Tag refused the request due to a validation failure.
- **Solution:** Check the server-side GTM preview mode "Inbound Request" logs for the specific cause (Origin, IP, Bot protection, etc.).

Server logs show: 

`🔴 Request origin not authorized`

- **Issue:** The request came from an unauthorized domain.
- **Solution:** Add the domain (e.g., `https://example.com`) to the **Authorized domains** list in the Server-Side Client Tag configuration.

Server logs show: 

`🔴 Request IP not authorized`

- **Issue:** The request came from an IP address listed in the **Banned IPs** section.
- **Solution:** Remove the IP from the list if it's a false positive.

Server logs show: 

`🔴 Missing User-Agent header. Request from bot`

`🔴 Invalid User-Agent header value. Request from bot`

- **Issue:** The request was identified as an automated bot or scraper, or the `User-Agent` header is missing.
- **Solution:** Nameless Analytics blocks common bot patterns. Ensure you are testing from a standard browser. If using the **Streaming Protocol**, ensure you send the mandatory UA: `nameless analytics - streaming protocol`.

Server logs show: 

`🔴 Invalid API key`

- **Issue:** The `x-api-key` header for Streaming protocol is missing or incorrect.
- **Solution:** Ensure your request includes the `x-api-key` header with the correct value as configured in the Client Tag.

Server logs show: 

`🔴 Request method not correct`

- **Issue:** The incoming request was not sent using the correct HTTP method.
- **Solution:** The server expects the data via `POST`. Ensure your client-side implementation is correctly configured to use POST requests.

Server logs show: 

`🔴 Invalid event_origin parameter value. Accepted values: Website`

`🔴 Invalid event_origin parameter value. Accepted values: Website or Streaming protocol`

- **Issue:** The `event_origin` parameter is missing or incorrect.
- **Solution:** Ensure the client-side tracker or your streaming implementation is correctly setting the origin to "Website" or "Streaming protocol".

Server logs show: 

`🔴 Invalid event_name. Can't send page_view from Streaming protocol`

- **Issue:** Sequence error: `page_view` cannot be sent via Streaming protocol.
- **Solution:** Use the website tracker for `page_view` events.

Server logs show: 

`🔴 Missing required parameters: [parameters]`

- **Issue:** The server rejected the JSON payload because it's missing one or more mandatory top-level fields: `page_date`, `page_id`, `page_data`, `event_origin`, `event_date`, `event_timestamp`, `event_name`, `event_id`, `event_data`.
- **Solution:** If you are using the standard GTM tags, this shouldn't happen. If implementing a custom tracker or using the **Streaming Protocol**, verify that the JSON payload includes all the fields listed above with valid values.



## Google Consent Mode
Nameless Analytics is deeply integrated with GCM. If consent isn't handled correctly, data might be lost or delayed.


### Error messages
Browser console shows: 

`[event_name] > 🔴 analytics_storage denied`

- **Issue:** Tracking is blocked by Google Consent Mode.
- **Solution:** This is expected behavior for users who opt-out. If events never fire even after consent is granted, the tracker automatically queues events if `analytics_storage` is pending. If they never release, verify that your Consent Management Platform (CMP) correctly triggers a `gtag('consent', 'update', ...)` call.

Browser console shows: 

`[event_name] > 🔴 Google Consent Mode not found`

- **Issue:** If "Respect Google Consent Mode" is enabled but GCM isn't active, the tag aborts.
- **Solution:** Ensure that a Google Consent Mode default consent command (e.g., via a CMP or a Custom HTML tag) is executed *before* the GTM container loads.



## Library Loading & Configuration Issues
The tracker requires its core libraries and a valid configuration to initiate.


### Error messages
Browser console shows: 

`[event_name] > 🔴 Tracker configuration error: event has invalid Nameless Analytics Client-Side tracker configuration variable`

- **Issue:** The tag is missing the required config variable or it's incorrectly set.
- **Solution:** Check the "Configuration Variable" field in the tag and ensure it points to a valid NA Config Variable.

Browser console shows: 

`[event_name] > 🔴 Main library not loaded from: [URL]`

`[event_name] > 🔴 UA parser library not loaded from: [URL]`

- **Issue:** The browser couldn't fetch the core tracker scripts, often due to ad-blockers blocking `jsdelivr.net`.
- **Solution:** Verify the library URL or check for ad-blockers. For a robust setup, use **First-Party mode** by hosting scripts on your own sub-domain (e.g., `https://gtm.yourdomain.com/lib/nameless-analytics.js`).

Browser console shows: 

`[event_name] > 🔴 Permission denied: unable to load Main library from [URL]`

`[event_name] > 🔴 Permission denied: unable to load UA parser library from [URL]`

- **Issue:** The GTM Sandbox is blocking the external script loading.
- **Solution:** Ensure the library URL is added to the **Inject Scripts** permission in the template settings.



## Storage & Cloud Permissions
Errors occurring when the server attempts to persist data to Firestore or BigQuery.


### Error messages
Server logs show: 

`🔴 User or session data not created in Firestore`

`🔴 User or session data not added in Firestore`

`🔴 User or session data not updated in Firestore`

- **Issue:** The Firestore write operation failed.
- **Solution:** Check GCP project permissions and quotas. Ensure the service account running your GTM Server has `roles/datastore.user`. Also verify Firestore is in **Native Mode**.

Server logs show: 

`🔴 Payload data not inserted into BigQuery`

- **Issue:** The streaming insert to BigQuery failed.
- **Solution:** Check BigQuery dataset/table permissions. Ensure the service account has `roles/bigquery.dataEditor`. Ensure you have created the schema using the provided SQL scripts.



## Network & Custom Endpoint Issues
Technical issues preventing communication between the browser and the GTM Server, or between the server and external destinations.


### Error messages
Browser console shows: 

`[event_name] > 🔴 Request not sent successfully`

- **Issue:** The network request from the browser failed to reach the server.
- **Solution:** Check for client-side connectivity issues, local firewalls, or DNS misconfigurations for your server-side endpoint.

Browser console shows: 

`[event_name] > 🔴 [error]`

- **Issue:** A generic JavaScript error occurred during the fetch request.
- **Solution:** Check the browser console for details.

Browser console shows: 

`[event_name] > 🔴 Request aborted`

- **Issue:** A generic issue stopped the tag execution.
- **Solution:** Check the previous logs in the console to find the specific cause.

Server logs show: 

`🔴 Request not sent successfully. Error: [result]`

- **Issue:** Forwarding to the custom endpoint failed.
- **Solution:** Verify the custom endpoint URL and ensure your server-side environment has the necessary network access.

Browser console shows: 

`cross-domain > 🔴 Error while fetch user data: [error]`

- **Issue:** The cross-domain listener failed to retrieve IDs from the server.
- **Solution:** Verify the server-side client is reachable.

Server logs show: 

`🔴 User cookie not found. No cross-domain link decoration will be applied`

`🔴 Session cookie not found. No cross-domain link decoration will be applied`

- **Issue:** Required user or session cookie is missing on the server for ID retrieval.
- **Solution:** Ensure the visitor has valid `na_u` and `na_s` cookies.

---

Reach me at: [Email](mailto:hello@tommasomoretti.com) | [Website](https://tommasomoretti.com) | [Twitter](https://twitter.com/tommoretti88) | [LinkedIn](https://www.linkedin.com/in/tommasomoretti/)
