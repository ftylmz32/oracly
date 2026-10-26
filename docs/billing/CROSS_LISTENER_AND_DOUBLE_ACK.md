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

## Update — reading-commerce fix applied (local QA, 26 Oct 2026, not deployed)

Changes are confined to `lib/features/reading_commerce/services/`. Tests are in `test/features/reading_commerce/reading_commerce_owner_safety_test.dart`: 19 tests, all 7 targeted mutations caught.

1. **Product filter.** `ReadingCommerceBuyer` passes on only coffee, palm and the coffee pack. Premium and unknown products never reach the reading tracker, its storage or its listeners.
2. **Owner binding.** A reading purchase sends the signed-in owner tag (SHA-256 of the uid, the same tag Premium uses) as `applicationUserName`.
   - Android echoes it back as `obfuscatedAccountId`.
   - A purchase tagged for another account is never verified, credited or finished in the current session. It is kept only in its owner's bucket and returned to that owner.
   - When nobody is signed in, nothing is verified; the store keeps the purchase.
3. **Secure storage.** Unfinished purchases live in secure storage, one bucket per owner tag (`or_reading_purchases_v2_<tag>`). A session reads only its own bucket.
   - The old plain-text `reading_commerce_unfinished_v1` is removed on first use.
   - Its entries carry no owner and are never handed to whoever is signed in.
4. **Recovery.** Nothing is finished without a backend grant, so an unfinished purchase stays with the store even when the account wipe clears secure storage.
   - On Android, at start, the monitor reads Play's unfinished reading purchases and routes each to its owner.
   - StoreKit redelivers unfinished transactions on its own.

### Remaining limits

- **iOS:** the owner tag is sent to StoreKit, but reading it back needs the `in_app_purchase_storekit` types (a pubspec change, out of scope). An iOS event therefore carries no tag and is credited to the signed-in account, as before.
- **Legacy entries:** purchases made before this fix carry no tag. When Play redelivers one, it goes to the signed-in account, as before. Reading commerce is closed on prod (`ORACLY_READING_COMMERCE_ENABLED` is not set; the entry link is QA-only), so such purchases can exist only on QA devices.
- **Account wipe:** an account switch deletes the local copy; recovery then relies on the store, as Premium does.
- **Double server ack:** not addressed in this change.
