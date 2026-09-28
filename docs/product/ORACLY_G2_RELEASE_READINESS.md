# ORACLY — G2 Release Readiness Evidence Map

Phase **G2A — Controlled live quality / release readiness preflight**
Branch `fix/final-product-remediation-20260922` · Base `bcfab51a6dc9e03accb3f19f6d778a7ddc8b7f5d`

G0, G1, Dream, Tarot, Yıldızname and the Coffee/Palm/SoulMate/OR/Astrology shared
seams are FINAL FROZEN. This phase does not reopen any of that. It answers one
question honestly: **what is already proven, and what genuinely still needs
real evidence before this ships** — real provider evidence, store evidence,
device evidence, or a backend deploy.

Zero real provider calls were made. Zero store transactions. Nothing was
deployed or mutated. The only network activity in this phase was: two
unauthenticated `GET`s (`/health`, `/ready`) against the already-configured
production origin, three unauthenticated `GET`s against the already-configured
public legal-document URLs, and read-only `gcloud run services/revisions
describe` calls (list/describe only — no `deploy`, no `update-traffic`, no
`services update`).

---

## Classification key

| Tag | Meaning |
|---|---|
| **PROVEN-CODE** | Proven by unit/widget/integration tests against fakes. Never used alone to claim live quality. |
| **PROVEN-LIVE** | Proven by an actual real-provider call whose evidence still matches the CURRENT frozen contract. |
| **PROVEN-STORE** | Proven by a completed Play Console / App Store Connect action. |
| **PROVEN-DEVICE** | Proven by a real physical-device run against current code. |
| **OPEN-LIVE** | Needs a real provider call; none currently valid. |
| **OPEN-STORE** | Needs a store action (purchase, restore, listing). |
| **OPEN-DEVICE** | Needs a real physical device. |
| **OPEN-EXTERNAL** | Needs something outside this repo entirely (macOS/Xcode, legal sign-off, a deploy decision). |
| **NON-BLOCKING** | A known, bounded limitation that does not gate release. |

---

## 1. Evidence matrix

| Domain | Status | Evidence |
|---|---|---|
| Release runtime config (reject localhost/LAN/HTTP/placeholder) | PROVEN-CODE | `ReleaseEndpointPolicy` tests across 5 files (§3) |
| Production origin configured, non-placeholder, HTTPS | PROVEN-CODE + PROVEN-LIVE | `tool/dart_defines.production.json` present; `/health`+`/ready` = 200 (§4) |
| Production backend alive/ready | PROVEN-LIVE | `/ready` capabilities all `true` (§4) |
| Dream frozen writer (`gpt-6-astra`/medium/`4c3-astra`) deployed | **OPEN-LIVE → BACKEND DEPLOY** | Self-admitted not deployed; revision predates the binding file by 10 days (§5) |
| Coffee live interpretation quality (current prompt) | **OPEN-LIVE** | Real evidence exists but predates a full writer-prompt rewrite (§6) |
| Palm live interpretation quality (current prompt) | **OPEN-LIVE** | Same rewrite, same gap (§6) |
| SoulMate live portrait quality (current prompt/response contract) | **OPEN-LIVE** | Prompt pipeline + response shape (`identity`) rewritten since capture (§6) |
| SoulMate render/decode compatibility | PROVEN-CODE | `e3e_soulmate_live_portrait_test.dart` decodes the real 1024×1536 PNG (§6) |
| SoulMate review-access backend gap | **GAP, NON-BLOCKING (process)** | Confirmed by code read: no review-access bypass exists (§9) |
| OR real reply + context retention | PROVEN-LIVE (local proxy only) | `or_real_gate_live_chat_test.dart`, gated, targets local dev proxy not deployed Cloud Run (§7) |
| OR idempotency vs real Firestore replay cache (G1-D14) | **OPEN-LIVE** | Never exercised against the real `response-replay-repository` (§7) |
| Tarot live interpretation quality (current prompt) | **OPEN-LIVE** | 2026-09-06 evidence (`gpt-4o`) predates the writer-prompt rewrite that IS in the current production build (§8) |
| Yıldızname Narrative V1 correctness for the frozen commit | PROVEN-LIVE (candidate, not production traffic) | Physical-device E2E in Phase 8C against tagged candidate `oracly-api-y8c1-169c514a`, 0 backend source diff vs frozen (§8) |
| Yıldızname Narrative V1 serving real production traffic | OPEN-EXTERNAL (deploy/promote decision) | Still 0% traffic; NON-BLOCKING because the client flag defaults `false` (§8) |
| Stale `/active` pointer | NON-BLOCKING CLEANUP | Owner+type-scoped; self-corrects; no cross-owner leak (§10) |
| Legal pages (privacy/terms/data-deletion) | **PROVEN-LIVE** | Configured GitHub URLs return 200; code test pins the exact URLs (§11) |
| Android store readiness | OPEN-STORE | Product availability, license-test purchase, restore, restart (§12) |
| iOS store readiness | OPEN-STORE | Monthly+yearly products, sandbox purchase, restore (§12) |
| Android release build | PROVEN-CODE (buildable today) | Signing, dart-defines, App Check all present and non-debug (§13) |
| iOS release build | OPEN-EXTERNAL | Structural: needs macOS + Xcode + Apple credentials, none in this worktree (§13) |
| Device checklist (back/share/deep-link/mic/TTS/a11y/TECNO) | Mixed PROVEN-CODE / OPEN-DEVICE | See minimal checklist (§14) |

---

## 2. Method

Health/ready and legal-URL checks used the exact origin/URLs already present in
the gitignored `tool/dart_defines.production.json` — nothing invented. Cloud
Run state came from `gcloud run services describe` / `gcloud run revisions
describe` (list + describe verbs only, the account's own existing
authenticated `gcloud` session, project `oracly-7f613`) — read-only, no
mutation. All other findings come from `git log`/`git show` on this repo and
reading the cited source/doc/test files directly.

---

## 3. Production runtime config

`docs/RELEASE_RUNTIME_CONFIG.md` is unchanged and accurate. `ReleaseEndpointPolicy`
rejection of localhost/`127.0.0.1`/`10.0.2.2`/LAN ranges/plain HTTP/placeholder
hosts is pinned by `test/core/config/oracly_runtime_config_test.dart`,
`test/core/config/e2_staging_dart_defines_test.dart`,
`test/core/legal/legal_policy_readiness_test.dart`,
`test/core/security/tls_security_contract_r6_test.dart`,
`test/general_audit/general_runtime_honesty_test.dart`.

`tool/dart_defines.production.json` — **PRESENT** (gitignored, 665 bytes).
`android/key.properties` — **PRESENT** (gitignored, 383 bytes).

Sanitized contents (no raw values printed): `APP_ENV=production`;
`ORACLY_AI_PROXY_URL` and `ORACLY_BILLING_VERIFY_URL` are both `https://`,
non-placeholder, non-local/LAN, on the same Cloud Run host, paths
`/v1/ai/complete` and `/v1/billing/verify` respectively; `ORACLY_PRIVACY_POLICY_URL`,
`ORACLY_TERMS_OF_USE_URL`, `ORACLY_DATA_DELETION_URL` are all `https://github.com/...`
blob links into this repo's own `docs/*.md` on `main` (confirmed to exist there —
§11).

---

## 4. Production health/ready (zero-cost, unauthenticated)

```
GET /health → 200 {"status":"ok"}
GET /ready  → 200 {"status":"ready","capabilities":{
  "alive":true,"authenticationConfigured":true,"appCheckConfigured":true,
  "textProviderConfigured":true,"visionConfigured":true,
  "imageGenerationConfigured":true,"readingStagingConfigured":true,
  "readingDurabilityConfigured":true,"billingGoogleConfigured":true,
  "billingAppleConfigured":true}}
```

**HEALTH: PASS. READY: PASS.** This proves the service is alive and every
capability flag is on. It does **not** prove which model/reasoning/revision is
bound to any specific feature — `/ready` reports booleans, not model names.

---

## 5. Dream deploy truth — NOT PROVEN (self-admitted not deployed)

`gcloud run services describe oracly-api` shows `oracly-api-00052-zqd` serving
**100%** of traffic, created **2026-09-18T17:10:46Z**. Its full env-key list
(confirmed by direct describe) contains **no** `OPENAI_DREAM_MODEL` or
`OPENAI_DREAM_REASONING_EFFORT` key at all.

`backend/src/ai/dream-writer-model.ts` (the file that defines
`FROZEN_DREAM_WRITER_MODEL = 'gpt-6-astra'` / `FROZEN_DREAM_REASONING_EFFORT =
'medium'` and fail-closes on any mismatch in a locked env) was introduced by
commit `fc06a744` on **2026-09-28 14:16:34** — **10 days after** the live
revision was built. The deployed container cannot contain this file.

`docs/product/dream/DREAM_PHASE4C3_PRODUCTION_BINDING.md` states this
explicitly in its own words: *"Status: bound in code and deploy script; not
deployed. No provider call was made in this phase."* and *"Not deployed.
Nothing was run with `gcloud`: no traffic change, no candidate revision and no
live env var change."*

**Verdict: NOT PROVEN** (self-admitted, and independently confirmed from both
the infra side and the code-history side). Whatever Dream code the production
revision actually runs today predates the frozen-writer contract entirely —
it is not "the old writer," it is untracked legacy behavior. **This is a
BACKEND DEPLOY blocker**, not a live-call gap: no live call can prove the
current contract until the binding is actually deployed.

---

## 6. Coffee / Palm / SoulMate live quality — OPEN-LIVE (fresh call required, all three)

Real, authenticated live-provider evidence exists for all three, captured
**2026-09-03/04** (`docs/RELEASE_LEDGER.md` R3.1B/R3.2; `tool/e3e_private/evidence/*`,
all gitignored). Coffee scored 9.2→9.8/10, Palm 9.8/10 (honestly left `fateLine`
empty), SoulMate exercised the real `gpt-image-2` 1024×1536 path with no fake
fallback.

Commit `4078de99` ("Canonicalize production source after SM-RL2/SMUX1
reconciliation", **2026-09-15** — before G0/G1, whose branch was cut
2026-09-22) rewrote the actual writer prompts used on that exact call path:

- **Coffee** — `coffeeWriterSystem()` in `backend/src/ai/reading/writer-prompts.ts`,
  invoked unconditionally at `pipeline.ts:498`. New section-ownership rules, a
  shared `WRITER_CONTRACT` block, new anti-repetition repair codes.
- **Palm** — `palmWriterSystem()`, same file, invoked at `pipeline.ts:538`. New
  per-line-section rules, expanded ban list.
- **SoulMate** — `backend/src/ai/soulmate-prompt.ts` near-totally replaced
  (120→136 lines), plus brand-new modules
  (`soulmate-portrait-prompt-builder.ts`, `soulmate-visual-profile.ts`,
  `soulmate-portrait-identity.ts`, `soulmate-uniqueness-index.ts`). The old
  prompt derived a visual profile from `birthDate` and a fixed 8-pose array;
  the new one derives a deterministic seed from `accountKey`. The client
  (`proxy_soul_mate_draw.dart`) changed in the same commit to parse a new
  `portrait.identity` field — a genuine response-shape change.

None of these three files changed again after 2026-09-22 — **the staleness
predates G0/G1 entirely**; it is not something this remediation work caused,
and G1's recovery/UI/state-machine fixes did not touch any of them.

**Verdict: FRESH CALL REQUIRED for all three** — the score/quality the old
evidence reports no longer describes the prompt that is actually live today.

SoulMate render/decode compatibility (separate from prompt quality) **is**
still proven: `e3e_soulmate_live_portrait_test.dart` decodes the real
1024×1536 PNG artifact through the current production `SoulMatePortraitReveal`
widget with no overflow — the image *format* is fine; the prompt *content* is
what's stale.

---

## 7. OR live quality — real evidence exists, but incomplete

`test/features/companion/or_real_gate_live_chat_test.dart` is a genuine
real-network test (not a fixture replay): it calls a real local Fastify proxy
(`http://127.0.0.1:8787`, via `test/support/ai_e2e_probe.dart`), which forwards
to real OpenAI if `OPENAI_API_KEY` is set locally. It is gated behind
`Platform.environment['ORACLY_E2E'] == '1'` and self-skips otherwise — **not
run by default**. It proves: a real non-trivial reply, proxy-only enforcement
(no bearer/key leakage, no direct-to-provider calls), and turn-history
round-trip.

Two things it does **not** prove:

1. **It targets the local dev proxy, never the deployed Cloud Run origin.**
   No OR evidence exists against `oracly-api-00052-zqd` specifically.
2. **G1-D14's idempotency-key change is untested against the real replay
   cache.** G1-D14 changed quality-regeneration to derive its own key
   (suffixed, e.g. `...q2`) so it no longer collides with the original turn's
   cached rejection. `g1_or_retry_persistence_test.dart` only tests key
   *derivation* against a fake AI — it never touches
   `backend/src/middleware/response-replay-repository.ts` (the real
   Firestore-backed `sha256(identity\0key)` / 10-minute-TTL cache). Only a
   real network round-trip against the real replay cache can prove the new
   key doesn't collide.

**Verdict: FRESH CALL(S) REQUIRED** — one real chat turn against the deployed
production origin, and one real duplicate-submission round-trip to prove the
replay-cache key scheme behaves as designed in production (see §15 for the
exact minimal shape).

---

## 8. Tarot / Yıldızname / Dream — live evidence validity

**Tarot.** `test/features/tarot/tarot_real_ai_e2e_fixture_test.dart` holds a
verbatim real backend response captured **2026-09-06**, on **`gpt-4o`** — a
model that matches neither the deployed revision's `OPENAI_READING_WRITER_MODEL
= gpt-5.6-sol` nor any frozen Tarot contract. The same `4078de99` commit
(2026-09-15) that rewrote Coffee/Palm/SoulMate also **added**
`backend/src/ai/tarot-prompts.ts`, and a later isolation
(`narrative-tarot-model.ts`, commit `c342ab8f`, **2026-09-25**) formalized
Tarot's own frozen writer. All of this postdates the 2026-09-06 evidence but
predates the production build (2026-09-18) — meaning **the currently-deployed
legacy Tarot path already runs the rewritten prompt, and the only evidence on
file predates that rewrite.** The test itself only proves client-side
parse/render of a fixed historical string, not current provider quality.
**Verdict: STALE — FRESH CALL REQUIRED.** (Tarot's Narrative V2 cut, commit
`3488248c` same day, is a separate, not-yet-wired path — see below.)

**Yıldızname.** Every doc that reports "0 real provider calls" for Yıldızname
(`YILDIZNAME_PHASE8C2C_CONTRACT_PARITY.md`, `_PHASE8C2_CLIENT_CONTRACT_ALIGNMENT.md`,
`_PHASE8A_LIVE_ELIGIBILITY.md`) is describing **offline source/lexical parity
checks**, not the live E2E runs. The live E2E runs that actually happened (this
session's own Phase 8C.2a/8C.2b/8C.2c work, budget-respecting, real App Check
+ Firebase Auth, against the tagged 0%-traffic candidate revision
`oracly-api-y8c1-169c514a`, `source_commit=169c514a…`) **are** real
live-provider evidence, and the parity docs independently confirm the
candidate's backend source diff vs the frozen contract is **0**. So: **the
frozen commit's behavior is PROVEN-LIVE** — just not against production
traffic, because that revision is still tagged at 0%, not promoted. This is
**NOT a release blocker for this build**, because
`ProductFeatureFlags.yildiznameNarrativeV1` defaults `false` client-side
regardless of backend traffic — no real user reaches this path today. Treat
production promotion as a future, deliberate deploy decision, not a gap in
this evidence map.

**Dream.** `docs/product/dream/DREAM_PHASE4C_LIVE_QUALITY_VALIDATION.md`
records 36/36 real writer calls (2026-09-27) — but against **`gpt-4o` /
writer revision `4b`**, the *pre-Astra* writer, not the frozen `gpt-6-astra`
contract this repo now defines (and which, per §5, isn't deployed at all).
**Verdict: STALE for the current frozen contract** — consistent with, and
explained by, §5.

---

## 9. SoulMate review-access backend gap — confirmed NO

Read directly: `backend/src/reading/soulmate-entitlement-guard.ts`.
`FirestoreSoulmateEntitlementGuard.isPremiumActive` reads only the
`purchaseBindings` collection (real `/v1/billing/verify`-populated records:
`status`, `kind`, `expiryAtMs`/`verifiedAtMs`) and requires
`isKnownProduct(productId)` plus `status === 'active'` (lifetime: revocation
flips it; subscription: `now < expiryAtMs`; grace: recent snapshot only,
bounded by `SOULMATE_GRACE_TRUST_WINDOW_MS`). **There is no review-access
branch anywhere in this file or its factory** (`createSoulmateEntitlementGuard`
fails closed with no Firestore project/instance).

**Answer: NO** — a reviewer using client-side Review Access, with no real or
sandbox purchase, is refused by the server for a new SoulMate draw.

**Release impact:** does not block the app's overall review — every other
live feature (Coffee, Palm, Tarot, Dream, OR, Astrology, Yıldızname) is free
or already review-access-compatible. It only blocks a reviewer from
generating a **new** SoulMate portrait without buying anything.

**Safest strategy given current architecture: (B) the reviewer account uses a
real sandbox/test purchase.** Reasoning: the guard's fail-closed design (no
Firestore ⇒ refuse, unknown product ⇒ refuse, missing status ⇒ refuse) is a
correctness property — a purchase-truth authority that also accepts review
access would need real changes to `isBindingCurrentlyActive`, weakening a
security-relevant, tested path (`test/` has entitlement-lapse coverage
building on this exact function) for a review-only convenience. (C) making
SoulMate inaccessible to reviewers risks a rejected review for hiding
functionality. (A) is real backend work with real risk, appropriate for a
later G-phase decision, not this preflight. **Not implemented — this is a
classification only, per instruction.**

---

## 10. Stale `/active` pointer — NON-BLOCKING CLEANUP

`reading-flow.ts` `remember()` writes the `ACTIVE` pointer (keyed
`sha256(ownerUserId, readingType)`) only while `waiting`/`processing`, and
never clears it on completion. `active()` reads it back through
`operations.get(ownerUserId, operationId)` — **owner+type scoped** at both the
pointer key and the record lookup. After completion, the next `/active` read
for that owner+type returns the stale finished operation (not null) until the
next fresh operation overwrites the pointer via `tx.set`.

Because the pointer and the lookup are both scoped to the requesting owner,
**no foreign-owner data can leak through it** — the worst case is a client
re-observing its own already-finished operation, which the client already
handles as a harmless recovery observation (confirmed by G1's own client-side
recovery logic and the audit's existing characterization).

**Verdict: NON-BLOCKING CLEANUP.**

---

## 11. Legal URLs — PROVEN LIVE

```
GET https://github.com/ftylmz32/oracly/blob/main/docs/privacy-policy.md   → 200
GET https://github.com/ftylmz32/oracly/blob/main/docs/terms-of-use.md    → 200
GET https://github.com/ftylmz32/oracly/blob/main/docs/data-deletion.md  → 200
```

All three files exist on `origin/main`. `test/core/legal/legal_policy_readiness_test.dart`
independently pins these exact URLs from `tool/dart_defines.production.json`
and proves they survive `ReleaseEndpointPolicy.sanitize` under
`releaseLocked: true`, plus that the Settings "Data Deletion" tile routes
through the same authoritative config (never a hardcoded literal).

**PRIVACY POLICY: PROVEN LIVE. TERMS: PROVEN LIVE. DATA DELETION: PROVEN LIVE.**

---

## 12. Store readiness

Historical Play Console work (Internal testing, Data Safety, Ads=No, App
Access, Content Rating, Target Audience 18+) is **done** and not reopened.

**Android — outstanding:** product catalog availability to the test account;
a verified license-test purchase; restore; restart/reconcile on a device.

**iOS — outstanding:** create monthly + yearly products only (**no lifetime**
— enforced in code, see below); a sandbox purchase; restore. (No distinct
"restart" line exists in the audit doc for iOS; it's folded into
restore/lapse.)

iOS lifetime exclusion is enforced in `lib/features/premium/services/premium_plan_availability.dart`:
`isPurchasable()` returns `false` for lifetime on iOS, `normalizeSelection()`
falls a stale lifetime choice back to yearly, and `storeQueryIds()` restricts
the actual store query to `{monthly, yearly}` on iOS (Android still gets all
three).

---

## 13. Release build readiness

**Android — buildable today with zero external mutation.**
`android/app/build.gradle.kts` loads `key.properties` and refuses
`assembleRelease`/`bundleRelease` without a complete signing config (no debug
fallback); `key.properties` is present and gitignored. `tool/dart_defines.production.json`
(gitignored) and its tracked `.example.json` template both exist. Release App
Check uses the real provider (`AndroidPlayIntegrityProvider` /
`AppleAppAttestWithDeviceCheckFallbackProvider`) whenever the build is
release-locked — never the debug provider. `android_release_hardening_test.dart`
pins R8 minify/shrink-resources on; `android_release_bundle_manifest_test.dart`
would check the actual merged manifest but self-skips because no release build
has been produced in this worktree yet (that's the build action itself, not a
missing blocker).

**iOS — structural blocker, not a config gap.** Archiving/signing needs
macOS + Xcode + Apple Developer certificates/provisioning profiles, none of
which can exist in this Windows worktree. **OPEN-EXTERNAL.**

---

## 14. Minimal device checklist

Nine historical `tool/*_smoke.py` UI-automation scripts exist (astrology34,
coffee20, palm20, premium27, profile14, soulmate21, tarot20, yildizname22,
hardening44) but were last touched **2026-08-29** — a month before G0
(2026-09-28) and before the G0-D1/G0-D5 navigation fixes existed. They do not
validate current code and are not counted as current evidence.

| Item | Status | Evidence |
|---|---|---|
| Android system back per chamber | Covered (widget test) | `general_navigation_stack_test.dart`, `general_shell_navigation_test.dart` (G0-D5) |
| Warm messenger share link — routing | Covered (widget test) | `general_warm_link_app_test.dart` |
| Warm messenger share link — real OS intent delivery | **OPEN-DEVICE** | not testable without a real device |
| Background during a wait | **OPEN-DEVICE** | no test found |
| Exact-operation push deep link | **OPEN-DEVICE** | no test found |
| Camera/gallery picker (business logic) | Covered (mock) | `coffee_v2_guided_capture_test.dart` |
| Camera/gallery picker (real OS picker/permission) | **OPEN-DEVICE** | — |
| Microphone | **OPEN-DEVICE** | no test found |
| TTS stop/dispose during an active turn | **OPEN-DEVICE**, flagged risk | doc §9.9 "not proven on a device" |
| TalkBack / VoiceOver (real screen reader) | Widget semantics covered; real pass **OPEN-DEVICE** | `general_error_state_accessibility_test.dart` (19 tests) |
| Dynamic text scale | Covered at widget level (1× and 2×, no overflow) | same file |
| TECNO device matrix | **OPEN-DEVICE**, explicit open item | doc §5 P1-DEVICE-MATRIX |

---

## 15. G2B minimal live-call plan

| Feature | Calls | Why current evidence is insufficient | Requires |
|---|---|---|---|
| Coffee | 1 | Writer prompt rewritten (`4078de99`) after the only real evidence was captured | image fixture, Firebase auth, App Check, deployed backend, provider |
| Palm | 1 | Same rewrite, same gap | image fixture, Firebase auth, App Check, deployed backend, provider |
| SoulMate | 1 | Entire prompt pipeline + response contract (`identity`) rewritten since capture | Firebase auth, App Check, deployed backend, provider (image gen), **real Premium entitlement** (sandbox purchase — review access does not work here, §9) |
| OR | 2 | (a) no evidence exists against the deployed production origin, only a local proxy; (b) G1-D14's idempotency key is untested against the real Firestore replay cache | Firebase auth, App Check, deployed backend, provider. Call (b) may resolve as a cache-hit rather than a second real provider call if the design works — budget for 2 requests, expect ≤2 actual provider calls |
| Dream | **0 — blocked on deploy** | The frozen writer isn't deployed (§5); a live call today would test unknown legacy code, not the current contract. Deploy is the prerequisite, not a call | — |
| Tarot | 1 | 2026-09-06 evidence used `gpt-4o`, predating the writer-prompt rewrite already live in the current production build | Firebase auth, App Check, deployed backend, provider |
| Yıldızname | 0 | Already proven live for the exact frozen commit via the tagged candidate; feature flag defaults off, so nothing in this release depends on fresh evidence | — |

**TOTAL: 6 real provider calls** (Coffee 1, Palm 1, SoulMate 1, OR 2, Tarot 1),
plus one prerequisite backend deploy (Dream) before any Dream call would be
meaningful.

No call is proposed "to be safe" — every row above cites the exact commit or
gap that makes the existing evidence stale or absent.

---

## 16. Release blocker table

| Blocker | Category | Status | Evidence | Next action |
|---|---|---|---|---|
| Dream frozen writer not deployed | BACKEND DEPLOY | **BLOCKING** | §5 — self-admitted + 10-day commit gap | Deploy `OPENAI_DREAM_MODEL=gpt-6-astra` / `OPENAI_DREAM_REASONING_EFFORT=medium`, re-check `/ready`, then 1 live call |
| Coffee live quality stale | LIVE PROVIDER | **BLOCKING** | §6 | 1 G2B call |
| Palm live quality stale | LIVE PROVIDER | **BLOCKING** | §6 | 1 G2B call |
| SoulMate live quality stale | LIVE PROVIDER | **BLOCKING** | §6 | 1 G2B call (needs sandbox purchase) |
| Tarot live quality stale | LIVE PROVIDER | **BLOCKING** | §8 | 1 G2B call |
| OR idempotency unproven vs real replay cache | LIVE PROVIDER | **BLOCKING** | §7 | 2 G2B requests |
| Android store evidence | STORE | OPEN | §12 | Product availability, license-test purchase, restore, restart |
| iOS store evidence | STORE | OPEN | §12 | Monthly+yearly products, sandbox purchase, restore |
| iOS release build | EXTERNAL | OPEN | §13 | macOS + Xcode + Apple credentials (not in this repo) |
| Device checklist (§14) | DEVICE | OPEN | §14 | Physical-device pass, minimal list only |
| SoulMate review-access backend gap | STORE (process) | NON-BLOCKING | §9 | Use sandbox purchase for the reviewer account |
| Stale `/active` pointer | CODE | NON-BLOCKING | §10 | Leave as-is; self-corrects |
| Yıldızname not promoted to production traffic | BACKEND DEPLOY | NON-BLOCKING | §8 | Future promotion decision; flag defaults off |

## Non-blocking cleanup

- Stale `/active` pointer (§10) — cosmetic recovery-observation only, no leak.
- SoulMate review-access (§9) — process decision, not a defect; sandbox
  purchase is the safe path today.
- Yıldızname candidate not yet promoted (§8) — by design, flag defaults off.

---

## 17. No code changes in G2A

Every finding above is either already-correct code (confirmed, not touched),
a genuinely external gap (store/device/deploy), or stale *evidence* rather
than a *defect*. Nothing here reopens Dream/Tarot/Yıldızname internals or any
G0/G1 seam. No regression was written and no production file was changed in
this phase.

---

## 18. Verification

Targeted release/config suites run to support the classifications above (no
production code changed, so the full 6k-test/6k-backend sweep was not
re-run):

| Suite | Result |
|---|---|
| `test/core/config/` (release runtime config) | pass |
| `test/core/legal/legal_policy_readiness_test.dart` | pass |
| `test/core/security/tls_security_contract_r6_test.dart` | pass |
| `test/general_audit/general_runtime_honesty_test.dart` | pass |
| `test/android_release_hardening_test.dart`, `android_release_manifest_test.dart` | pass |
| `test/general_audit/` (G0+G1 regression reference) | pass (unchanged from prior audit) |

No real provider calls. No store transactions. Not deployed.
