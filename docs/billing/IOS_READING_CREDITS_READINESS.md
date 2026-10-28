# iOS paid Coffee / Palm reading credits — readiness

Branch `feat/coffee-v3-fincan-haritasi-20261027`. Local evidence only: no
iOS build, no device, no sandbox purchase, no App Store Connect access, no
deploy. **Not release-ready until the open items below are done.**

## Products (same IDs on both stores; the server is the only grant table)

| Product ID | Type | Grants | Proposed price (not a charge) |
| --- | --- | --- | --- |
| `app.oracly.reading.coffee` | Consumable | 1 Coffee reading | ₺69.99 |
| `app.oracly.reading.palm` | Consumable | 1 Palm reading | ₺49.99 |
| `app.oracly.reading.coffee.pack3` | Consumable | 3 Coffee readings | ₺179.99 |

Source: `backend/src/reading/reading-commerce-catalog.ts`,
`lib/features/reading_commerce/models/reading_commerce_view.dart`. The app
shows only the price string StoreKit returns; a product StoreKit does not
return is not offered.

**App Store Connect status: NOT PROVEN.** Nothing on this machine can read
App Store Connect. The last recorded state (16 Oct, `OPEN_BLOCKERS.md` 0c)
is that the App Store had none of the three. Google Play: the three were
confirmed separately with the Play Developer API.

### Creating them (account holder / admin, App Store Connect)

1. Agreements, Tax and Banking: Paid Applications agreement active.
2. App → Monetization → In-App Purchases → `+` → **Consumable**, three
   times, Product ID exactly as above, a reference name, a price, a Turkish
   (and if offered, English) display name and description, and a review
   screenshot of the reading-rights screen.
3. Each must reach "Ready to Submit"; the first in-app purchases are
   submitted **together with an app version**.
4. App Information → App Store Server Notifications → **Version 2**,
   Production and Sandbox URL:
   `https://<production API host>/v1/reading-entitlements/apple-notifications`.

## What the app and server do (code in this branch)

- **StoreKit 2** (plugin default): the purchase is launched with
  `appAccountToken` = `ReadingOwnerToken.forUid(uid)` and the server
  receives the signed transaction (JWS).
- **Server verify** (`POST /v1/reading-entitlements/verify`, Firebase auth
  + App Check): the JWS is verified with Apple's `SignedDataVerifier`
  against the Apple root CAs (Production first, Sandbox only on a proven
  environment mismatch); bundle, product and `Consumable` type must match;
  a revoked transaction grants nothing.
- **Owner (new)**: the JWS `appAccountToken` must equal the token derived
  from the authenticated Firebase uid (`readingOwnerToken`, byte-identical
  to Flutter; shared test vector). Missing → `owner_unproven`; another
  account → `purchase_bound_to_other_account`. Nothing is bound or
  consumed, so the real owner can still claim it. Play: a tag for another
  account is refused; untagged legacy Play purchases are accepted as before.
- **Once only**: the ledger keys a purchase by transaction id and by token
  in one Firestore transaction; a repeat returns `idempotent: true`.
- **Finish after grant**: the app finishes the StoreKit transaction only
  after `granted: true`; otherwise StoreKit redelivers it (lost connection,
  server down). Pending (Ask to Buy) is never sent as a purchase.
- **Refunds (new)**: `POST /v1/reading-entitlements/apple-notifications`
  verifies the App Store Server Notification V2 and its transaction, and for
  `REFUND` / `REVOKE` of a reading product takes the credit back from the
  purchase record's owner (idempotent). Unverifiable → 400, nothing changes.
  `CONSUMPTION_REQUEST` is not answered (Apple then decides without it).
- **QA server**: an iOS Sandbox transaction counts as the counterpart of a
  Play license-test purchase (`ORACLY_READING_BILLING_QA`).

## Production configuration (read-only check, 28 Oct; nothing changed)

| Item | Production now | Needed |
| --- | --- | --- |
| Serving code | `oracly-api-00104-roc`, source `5c1090a0` | This branch's backend (owner check, notifications, paid V3 entry `de859a39`, paid fulfillment `427b342a`) — a separately authorized deploy |
| `ORACLY_READING_COMMERCE_ENABLED` | absent (= off) | `true` |
| `ORACLY_COFFEE_V3_ENABLED` | `true` | `true` |
| `APPLE_BUNDLE_ID`, `APPLE_APP_APPLE_ID`, `APPLE_IAP_ISSUER_ID`, `APPLE_IAP_KEY_ID`, `APPLE_IAP_PRIVATE_KEY`, `APPLE_ROOT_CA_DIR` | set | set (iOS verifier admits only with all of them) |
| `APPLE_IAP_ENVIRONMENT` | `Production` | `Production` (Sandbox fallback is automatic) |
| `AI_DAILY_SPEND_CAP_USD` / `AI_SPEND_KILL_SWITCH` / `OPENAI_VISION` | `5` / `false` / `true` | purchasable only while the day's spend is under the cap |
| App Store Server Notifications URL | unknown | the URL above |

A production sandbox purchase (App Review, TestFlight) is a real credit for
that account — the intended review path, not a bypass.

## How App Review reaches Fincan Haritası (no free reading, no fake path)

1. Review build made with the production defines
   (`ORACLY_COFFEE_V3_ENABLED=true`) and working iOS App Check (App Attest).
2. App language **Türkçe** (Settings → Dil) — Coffee V3 is Turkish-only.
3. Home → Kahve Falı → "Başlayalım" → buy "Kahve Falı" with the sandbox
   account → "Kahve hakkını kullan".
4. Take the three photos; on "Son bir kontrol" turn on "Fincan Haritası için
   fotoğraflarımı sakla"; submit; wait for the real reading.
5. Under the reading: "Haritayı aç".

## Open before any PASS

- [ ] The three consumables exist in App Store Connect and StoreKit returns
      them on a device (sandbox).
- [ ] A real iOS build (Xcode) and a sandbox purchase of each product:
      verify → grant → finish, a repeat, a refund notification.
- [ ] App Store Server Notifications V2 URL configured.
- [ ] Production deploy of this backend and `ORACLY_READING_COMMERCE_ENABLED`
      (separate authorization).
- [ ] iOS App Check (App Attest) passing on the review build — the
      commerce routes require it.
