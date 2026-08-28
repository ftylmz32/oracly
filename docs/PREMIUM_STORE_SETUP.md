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

## Entitlement

Grant happens only after `PurchaseStatus.purchased` / `restored` and `completePurchase`. Local prefs store membership; there is no server receipt verifier yet. Minimum client security: never grant from a UI tap; never grant on cancel/error/pending.

## Gems

Premium membership does not mutate the gem wallet. Gem spend cannot grant Premium.