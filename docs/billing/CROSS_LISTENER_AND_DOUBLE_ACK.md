# Premium vs reading-commerce purchase listeners; double server ack

**Date:** 26 Oct 2026. Tests and analysis only; no source changed. The reading-commerce source is identical in release `5c1090a0` and QA `45312536`.

## Finding from the device test

The app has two listeners on `InAppPurchase.purchaseStream`: the Premium session and `ReadingCommerceBuyer`. The reading chain (`ReadingCommerceBuyer` → `ReadingPurchaseMonitor` → `ReadingPurchaseTracker` → `DiskReadingPurchases`) has no product filter. It therefore also handles Premium events.

## What the tests prove

Tests: `test/features/reading_commerce/premium_event_cross_listener_test.dart` and `backend/tests/reading-commerce-premium-product.test.ts`.

| Question | Result |
|---|---|
| Wrong reading entitlement from a Premium event? | **No.** The backend refuses every Premium product (monthly, yearly, lifetime; Android and iOS) with 400 before the store verifier is asked, and stores nothing. The client maps that to `rejected`. |
| Affects the Google Play acknowledgement? | **No, today.** The reading path calls `completePurchase` only on a backend `granted`, which cannot happen for Premium. This coupling exists only through that backend refusal. |
| Leftover or persistent records? | **Yes, bounded.** The Premium event is saved under `reading_commerce_unfinished_v1`, as a raw token in plain SharedPreferences. With the 400 it is removed. While verify is `unavailable` (QA debug App Check, offline) it stays. A Premium PENDING event is never revisited by `resume`, so it lingers until a final store event arrives. |
| Repeated work on relaunch? | **Yes while unavailable.** One reading verify call per app start, until the backend can answer. It then clears itself. |
| Account switch mixing? | **Yes, data hygiene.** The account wipe does not clear `reading_commerce_unfinished_v1`. Account A's token is re-sent under account B, and is refused, so no grant results. For real reading products this same gap applies; that is not tested here. |
| UI side effect | The monitor reports the Premium event to reading listeners as `failed:app.oracly.premium.yearly`. |
| Legitimate reading purchases | Still granted and completed normally next to a Premium event. |

## Double server acknowledgement (real device: two `billing_acknowledge`)

Test: `backend/tests/billing-concurrent-ack.test.ts`.

- **Server side, reproduced.** Verify requests that read Play before either has acknowledged both acknowledge (2 Play calls); both answer `active` + `acknowledged`. Sequential requests acknowledge exactly once. There is no per-token single-flight in the route.
- **Client side, not reproduced.** In the Premium test harness, one purchase makes 2 verify calls, sequentially (maximum overlap 1), and a relaunch makes 1. The real app made 3 per purchase, 2 of them at the same second.
  - Likely cause, unproven: the post-purchase verify (`PremiumGrantPolicy.applyStoreOutcome`) runs outside the controller's `_inFlight` guard, so it can overlap a reconcile started by another caller (provider start, Premium screen `load()`).
- **Impact.** One extra, idempotent Play acknowledge call. No second charge and no second binding were observed.

## Source change proposals (not applied; reading-commerce is frozen)

1. Reading listener: accept only `app.oracly.reading.*` product ids at `ReadingCommerceBuyer.updates`. Leave the Premium stream untouched.
2. Wipe `reading_commerce_unfinished_v1` on account change, and keep tokens in secure storage as Premium does.
3. Backend: a per-token single-flight around the acknowledge step, or re-read Play right before acknowledging. This is optional because acknowledgement is idempotent.
