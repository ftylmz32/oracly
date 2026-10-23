# ORACLY Premium store setup

**Status:** code-side Play / StoreKit port exists. A supplied Android screen (24 Oct 2026) shows local store price labels for monthly, yearly and lifetime; it does **not** by itself verify product-ID matching, charge success, or receipt/entitlement lifecycle. Store-console state must be verified separately.

## Product IDs (must match store consoles)

| Plan | Product ID | Type | Platforms |
|------|------------|------|-----------|
| Monthly | `app.oracly.premium.monthly` | Auto-renewing subscription | Android · iOS |
| Yearly | `app.oracly.premium.yearly` | Auto-renewing subscription | Android · iOS |
| Lifetime | `app.oracly.premium.lifetime` | Non-consumable | **Android only** |

Platform truth lives in `PremiumPlanAvailability`: on iOS the app queries only monthly + yearly,
never shows lifetime, and normalizes a stale lifetime selection to yearly.

Application id: `app.oracly`

## Android (Google Play)

1. Play Console → app `app.oracly` → Monetize → Products
2. Create the three product IDs above
3. Activate products; use license testers for test purchases
4. Upload a build that includes `com.android.vending.BILLING` (already in AndroidManifest)
5. Prefer installing from the Play internal testing track when validating distribution. A Play Console license tester can also complete a license-test purchase on a sideloaded build, including a debug-signed build, when the package name matches `app.oracly`, the app exists in Play, and the products are published. That path is for license-test purchases. It is not a claim that a sideloaded build can take a real-money charge.

## iOS (App Store)

1. App Store Connect → app with matching bundle id
2. Create the monthly and yearly subscription IDs only — do **not** create lifetime on iOS
3. StoreKit capability on the Runner target
4. Sandbox Apple ID for device testing

## Flutter release

No OpenAI or store secrets in the client. Prices come from the store query.

When the store returns one or more queried products, `StorePremiumPurchase.prepare()` sets `isConfigured`. The Premium plan selector must display **only** actual returned products on Android and iOS (no fallback-price or missing-product cards). A missing catalog must not enable the purchase CTA. Actual purchase, restore, refund and cross-account tests are required before release.

Public legal documents (store policy) are configured only via real HTTPS URLs:

- `ORACLY_PRIVACY_POLICY_URL`
- `ORACLY_TERMS_OF_USE_URL`

Do not invent placeholder domains. Until set, Privacy Policy / Terms taps fail honestly in-app.

## Entitlement

Grant happens only after `PurchaseStatus.purchased` / `restored` and `completePurchase`. The
client calls the backend `POST /v1/billing/verify` (`backend/src/routes/billing.ts`), which
performs real server-side Apple/Google receipt verification (`backend/src/billing/apple-store.ts`,
`backend/src/billing/google-play.ts`) and requires an authenticated Firebase identity whenever
auth is required — including when Firebase/JWT configuration is missing, which fails closed
with 401 rather than allowing the request through. Purchase-token ownership uses `backend/src/billing/entitlement-repository.ts`:
production/staging require a durable Firestore transaction and fail closed on an unavailable repository;
development may opt into in-memory bindings. This is a **source-code assessment**, not proof
that live deployment credentials, Firestore permissions, or end-to-end payment verification work.
Minimum client security: never grant from a UI tap; never grant on cancel/error/pending.

## Gems

Premium membership does not mutate the gem wallet. Gem spend cannot grant Premium.