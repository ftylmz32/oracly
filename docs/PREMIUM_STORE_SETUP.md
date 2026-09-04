# ORACLY Premium store setup

**Status:** code-side Play / StoreKit port exists. Products are not created in any store console from this repository.

## Product IDs (must match store consoles)

| Plan | Product ID | Type |
|------|------------|------|
| Monthly | `app.oracly.premium.monthly` | Auto-renewing subscription |
| Yearly | `app.oracly.premium.yearly` | Auto-renewing subscription |
| Lifetime | `app.oracly.premium.lifetime` | Non-consumable |

Application id: `app.oracly`

## Android (Google Play)

1. Play Console → app `app.oracly` → Monetize → Products
2. Create the three product IDs above
3. Activate products; use license testers for test purchases
4. Upload a build that includes `com.android.vending.BILLING` (already in AndroidManifest)
5. Install from Play (internal testing track) — sideloaded APKs cannot complete real billing

## iOS (App Store)

1. App Store Connect → app with matching bundle id
2. Create the same product IDs (Subscriptions + Non-Consumable)
3. StoreKit capability on the Runner target
4. Sandbox Apple ID for device testing

## Flutter release

No OpenAI or store secrets in the client. Prices come from the store query.

When products are live, `StorePremiumPurchase.prepare()` sets `isConfigured` and the Premium CTA unlocks. Until then the UI stays on the honest unavailable plaque.

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
with 401 rather than allowing the request through. Purchase-token ownership is currently
tracked in an in-process map (`backend/src/billing/entitlement-binding.ts`); it is not yet
durable across restarts or safe with more than one backend instance (tracked P1 — see
`docs/RELEASE_LEDGER.md`). Minimum client security: never grant from a UI tap; never grant on
cancel/error/pending.

## Gems

Premium membership does not mutate the gem wallet. Gem spend cannot grant Premium.