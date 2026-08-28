# PREMIUM + COMMERCE Master Checkpoint

**PREMIUM MASTER STATUS = BLOCKED — EXTERNAL**

**Date:** 2026-08-25  
**Gate:** PREMIUM 29 — Final release gate  
**External blocker:** Google Play Billing product catalog not available on device (products do not load → store stays unconfigured).

Do **not** claim COMPLETE. Real-money / license-test purchase was **not** run.

---

## Product honesty (PREMIUM 01–02)

| Item | Truth |
|------|--------|
| Live screen | `PremiumReferenceScreen` (`lib/features/premium/presentation/reference/`) |
| Service | `PremiumService` + `PremiumStatusController` |
| Port | `StorePremiumPurchase` (mobile) / `UnavailablePremiumPurchase` (tests / desktop / empty catalog) |
| Product IDs (canonical) | `app.oracly.premium.monthly` · `yearly` · `lifetime` via `PremiumStoreCatalog` |
| Prices | Store-supplied only — never hardcoded TL |
| Entitlement | `PremiumEntitlementState` — UI cannot invent membership |
| Debug | `PremiumDevOverride` / `SoulMateDevAccess` — **debug only**; never release entitlement |

---

## Feature gate matrix (PREMIUM 08)

Canonical: `lib/features/premium/services/premium_feature_gates.dart`

| Capability | Free | Premium |
|------------|------|---------|
| Tarot / Coffee / Palm / Astrology / Yıldızname / Daily / Journal | Open | Open |
| OR chamber preview | Allowed | — |
| OR full text + voice | Locked | Entitlement `active` |
| SoulMate generation | Locked (debug QA override only) | Entitlement `active` |
| Gems wallet | Independent | Independent |

Navigation gate for SoulMate: `OraclyFeatureRegistry.requiresPremium` + `PremiumAccess`.

---

## What this pass changed (surgical)

1. **Late / delayed grant recovery** — unsolicited store grants drained on `preparePurchase` (no silent `completePurchase` without entitlement).
2. **Pending no longer permanent busy** — pending store outcome settles with message; user can retry.
3. **Paywall states** — loading · error+retry · store plans · active · honest unavailable+retry.
4. **Feature gate matrix** file + tests.
5. **Analytics** — viewed / plan selected / purchase+restore start+complete/cancel/fail via existing `operationResult` (no payment secrets).
6. **CTA** — configured CTA `Premium'e Geç`; unavailable keeps explore + retry.
7. **Yearly subtitle** — removed invented “better value” discount language.

Preserved: repositories, product IDs, Gem isolation, Profile/OR/SoulMate entitlement wiring.

---

## Task board

| Task | Status |
|------|--------|
| 01–02 Baseline / catalog | DONE |
| 03 Product loading | DONE (honest empty / unavailable) |
| 04–06 Purchase / duplicate / restore | DONE in code+tests; **store BLOCKED** |
| 07 Entitlement model | DONE |
| 08 Feature gate matrix | DONE |
| 09 Gems isolation | DONE (tests) |
| 10 Honest free UX | DONE |
| 11–15 Visual / value / plans / CTA / states | DONE (polish of live chamber) |
| 16–18 OR / SoulMate / Profile | DONE (central entitlement) |
| 19 Transaction recovery | PARTIAL (late grant wired; full Play pending needs store) |
| 20 Error copy | DONE |
| 21–23 A11y / responsive / perf | PARTIAL (existing systems; no full device matrix) |
| 24 Security | DONE (release override closed; secrets out of Flutter) |
| 25 Analytics | DONE where infra exists |
| 26 Focused tests | **111 passed** |
| 27 Real store verification | **BLOCKED — EXTERNAL PLAY BILLING SETUP** |
| 28 Device gate | PARTIAL — OR/Home evidence of honest unavailable; no purchase |
| 29 Final | **BLOCKED — EXTERNAL** |

---

## Verification

| Check | Result |
|-------|--------|
| Focused `test/features/premium` + honesty + copy | **111 passed** |
| flutter analyze (touched Premium paths) | **0 errors** (1 pre-existing info elsewhere) |
| TECNO KN8 | Device present; store products **not** loaded; honest unavailable copy observed on OR paywall (`raw.xml`); fake prices/success **not** shown |
| Real test purchase | **NOT RUN** |

Artifacts: `tool/device_premium_gate/PREMIUM27_SMOKE.json`, `raw.xml`

---

## Blockers to COMPLETE

1. Create / activate Play Console products for the three catalog IDs (or confirm they exist and are available to the internal test account).
2. Redeploy release/profile APK and run PREMIUM 27 license-test purchase on TECNO (no production money).
3. Confirm OR unlock + Profile sync + restore + restart persistence after real grant.
4. Optional: full a11y/responsive pass on Premium chamber after store opens.

---

## Definition of COMPLETE (unmet)

- [x] Catalog IDs real (placeholders ready for console)
- [x] Purchase/restore/entitlement architecture honest
- [x] Gems isolated
- [x] OR / SoulMate / Profile use central entitlement
- [x] Focused tests pass
- [ ] **Real store products load on device**
- [ ] **Real test purchase + restore verified**

---

**PREMIUM MASTER STATUS = BLOCKED — EXTERNAL**

End of checkpoint. STOP.
