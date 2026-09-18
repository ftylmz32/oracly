# ORACLY Privacy Policy

**Effective date: September 18, 2026**

## What ORACLY is

ORACLY is a personal-reflection and entertainment application. It may include tarot, coffee-cup readings, palm readings, astrology, dream interpretation, SoulMate experiences, daily ritual features, journal/history, and the OR/Luna assistant.

ORACLY is not a medical, legal, financial, psychological, emergency, or other professional advice service. AI-generated readings are for reflection and entertainment.

## Information processed

Depending on the features you use, ORACLY may process:

| Category | Examples | Where it may be processed |
|---|---|---|
| Content you provide | Questions, chat messages, dream descriptions, intentions, profile/preferences, astrology details you enter | Device; ORACLY backend; AI providers when a feature requires it |
| Images you submit | Coffee-cup and palm photos; SoulMate-related portrait generation inputs/outputs | Device staging; ORACLY backend / Google Cloud Storage; AI providers for the requested feature |
| Account identifiers | Anonymous Firebase Authentication user ID; App Check / request authentication material | Device; Firebase / Google Cloud |
| Reading and operation processing data | Feature usage needed to run a reading; operation status and in-progress/recently delivered results | Device and ORACLY backend (Firestore, bounded short-term retention) |
| Local history and personalization | Saved-reading history/journal, favorites, profile/personalization, and OR/Luna memory summaries | Device only |
| Notification data | Device push-notification tokens when notifications are enabled | Device; ORACLY backend |
| Purchase / entitlement data | Product IDs, store transaction / purchase tokens, Premium entitlement status, Gem wallet state | Device; ORACLY backend; Google Play Billing / Apple App Store |
| Technical / operational metadata | Request and operation identifiers used for reliability, abuse prevention, and debugging | ORACLY backend / infrastructure logs |

ORACLY does **not** collect payment-card numbers in the app. Payments are handled by Google Play or the Apple App Store.

ORACLY does **not** sell personal information.

## Images and content submitted for readings

When you request a coffee, palm, SoulMate, or similar reading:

- images and text you submit are transmitted to ORACLY’s backend so the requested feature can run;
- staged coffee/palm input images are treated as temporary provider inputs (application cleanup targets removal within about **24 hours**; Google Cloud Storage lifecycle is configured as a safety net for the `reading-staging/` prefix);
- SoulMate portrait objects are retained for a bounded window (about **30 days** metadata and GCS safety-net lifecycle under `soulmate-portraits/`), and are removed sooner when account deletion succeeds or when cleanup paths run;
- delivered reading payloads and related operation records are retained for a bounded operational window (typically up to about **30 days** for successful deliveries; shorter windows apply to some failure/transient records). Exact windows follow ORACLY’s retention configuration.

Physical removal of Firestore documents with TTL fields may occur after the configured expiry window; it is not always instantaneous at the moment a feature finishes.

## AI processing / service providers

Some features use artificial-intelligence services to analyze text or images and generate responses. Data needed for a requested feature may be sent securely (HTTPS/TLS) to ORACLY’s backend and to AI service providers acting for ORACLY. Current production AI completion uses OpenAI-compatible services via ORACLY’s API.

ORACLY may also use:

- **Google Firebase / Google Cloud** — authentication, App Check, Firestore, Cloud Storage, Cloud Run / Tasks, and related infrastructure;
- **Google Play Billing / Apple App Store** — purchase processing and receipt verification inputs.

These providers process information under their own terms, only as needed for the relevant service. Processing may occur in regions where those providers operate (including outside your country).

## Account / anonymous identifiers

ORACLY typically uses **anonymous Firebase Authentication**. The Firebase user identifier binds Premium entitlements, server readings, Gems, notification tokens, and deletion.

You remain responsible for the security of your device and any app-store account used for purchases.

## Purchase verification

Premium purchases are verified **server-side** against Google Play or Apple before entitlement is granted. ORACLY stores purchase-binding and entitlement-related records needed to prevent duplicate entitlements, support restore flows, and handle fraud/dispute integrity. Card data is not collected by ORACLY.

## Notifications

If you enable notifications, ORACLY may register a device push token with its backend to deliver reminders you opted into. Tokens are removed on account deletion and on supported logout/switch/cleanup paths. Notification preference state may also be stored locally on the device.

## Local storage

On your device, ORACLY may store:

- discovery / reading history and favorites;
- profile and personalization / memory summaries;
- settings, onboarding, daily-ritual state, and similar preferences;
- cached Premium / entitlement state;
- secure storage entries used for sensitive local values.

Local data remains on the device until you clear it with in-app controls, use account deletion, or uninstall the app (device-local remainder).

## Server storage

Server-side storage may include:

- reading operations, results, inputs, staged-image metadata, provider checkpoints, SoulMate portrait metadata;
- Gem balances and related ledger/idempotency records;
- notification token registrations;
- purchase bindings (and anonymized ownership history after deletion);
- short-lived AI response-replay bodies (about **10 minutes**);
- account-deletion receipts (hashed tombstones, about **30 days**).

## Retention

Retention varies by record type. Operational defaults currently include:

- staged reading images: up to about **24 hours**;
- SoulMate portraits: up to about **30 days** (unless deleted earlier);
- delivered reading results / many operation records: up to about **30 days**;
- some failed/transient records: shorter windows (about **7 days** where configured);
- AI response replay: about **10 minutes**;
- Gem wallet / ledger: for the life of the account, then hard-deleted on successful account deletion;
- purchase bindings: anonymized on deletion; not TTL-deleted (needed for fraud/rebind integrity);
- deletion receipts: about **30 days**.

Firestore TTL and GCS lifecycle act as safety nets; physical deletion can lag acceptance of a logical delete.

## Account deletion

In the app:

1. Open **Settings**
2. Under **Privacy**, open **Privacy** (screen title: **My Data**)
3. Choose **Permanently delete account**
4. Confirm

When the flow succeeds, ORACLY:

1. requests authenticated **server-side** deletion (accepted before the Firebase identity is destroyed);
2. deletes the Firebase authentication identity;
3. clears user-bound **local** data on the device;
4. starts a fresh anonymous session so the app remains usable.

Server deletion removes supported user-owned records (readings/operations, staged inputs and attributable objects, Gems, notification tokens, and related collections) and **anonymizes** purchase bindings rather than erasing all purchase-integrity history. OR/Luna memory, personalization, and reading-history/favorites data are stored only on your device and are cleared as part of the device-local wipe, not server deletion. Store purchase records held by Apple or Google remain under those platforms’ rules.

Deletion receipts may be retained temporarily (about 30 days) as hashed proof that deletion was accepted. Legacy short-lived residues without an owner key (if any) become inaccessible and are removed by TTL.

If you cannot use the app, see the [Data Deletion](https://github.com/ftylmz32/oracly/blob/main/docs/data-deletion.md) page.

## Security

ORACLY uses HTTPS/TLS for communication with its backend. Authentication and App Check protect sensitive routes. No method is perfectly secure; we use reasonable safeguards appropriate to the service.

ORACLY does **not** claim end-to-end encryption of readings or chat content.

## Children

ORACLY is intended for users aged **18 and over** and is not directed to children.

## International processing

Backend infrastructure for ORACLY is operated on Google Cloud. AI and store providers may process data in other regions. By using ORACLY, you understand that processing may occur outside your country of residence where those providers operate.

## Changes to this policy

We may update this Privacy Policy as ORACLY or legal/platform requirements change. The current version remains at this public URL with its effective date.

## Contact

For privacy questions or deletion help:

**Email:** destek@oracly.app

Do not send passwords, payment-card details, purchase tokens, API keys, or authentication tokens.

**App:** ORACLY
