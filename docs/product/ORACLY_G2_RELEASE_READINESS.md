# ORACLY — G2 Release Readiness Evidence Map

Phase **G2A — Controlled live quality / release readiness preflight**, extended by
**G2A.1 — Deployed backend compatibility closure** (§19)
Branch `fix/final-product-remediation-20260922` · Base `bcfab51a6dc9e03accb3f19f6d778a7ddc8b7f5d`

**G2A.1 correction, read this first:** independent verification found that G2A's
Tarot classification (§8, §15, §16 below) was insufficient — it treated Tarot as
only a stale-live-evidence problem. §19 proves it is actually a **deploy-compatibility
blocker**: the traffic-serving revision cannot correctly process the current
Flutter client's default request shape at all. The original §8/§15/§16 text is
left intact below for the record; §19 is the corrected, authoritative
classification for Tarot and for every other feature's deploy compatibility.

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
| Dream frozen writer (`gpt-6-astra`/medium/`4c3-astra`) deployed | **OPEN-LIVE → BACKEND DEPLOY** | Self-admitted not deployed; revision predates the binding file by 10 days (§5). G2A.1 (§19) confirms the gap is the entire Dream Phase 2–4C engine, not just the writer constant |
| Coffee live interpretation quality (current prompt) | **OPEN-LIVE** | Real evidence exists but predates a full writer-prompt rewrite (§6) |
| Palm live interpretation quality (current prompt) | **OPEN-LIVE** | Same rewrite, same gap (§6) |
| SoulMate live portrait quality (current prompt/response contract) | **OPEN-LIVE** | Prompt pipeline + response shape (`identity`) rewritten since capture (§6) |
| SoulMate render/decode compatibility | PROVEN-CODE | `e3e_soulmate_live_portrait_test.dart` decodes the real 1024×1536 PNG (§6) |
| SoulMate review-access backend gap | **GAP, NON-BLOCKING (process)** | Confirmed by code read: no review-access bypass exists (§9) |
| OR real reply + context retention | PROVEN-LIVE (local proxy only) | `or_real_gate_live_chat_test.dart`, gated, targets local dev proxy not deployed Cloud Run (§7) |
| OR idempotency vs real Firestore replay cache (G1-D14) | **OPEN-LIVE** | Never exercised against the real `response-replay-repository` (§7) |
| Tarot live interpretation quality (current prompt) | **OPEN-LIVE** — superseded, see below | 2026-09-06 evidence (`gpt-4o`) predates the writer-prompt rewrite (§8) |
| **Tarot Narrative V2 ↔ traffic revision (corrected in G2A.1)** | **DEPLOY-COMPATIBILITY BLOCKER — INCOMPATIBLE** | Deployed revision's `validateTarot` has no `mode` field at all; `narrative-tarot-contract.ts`/writer/result-parser don't exist in it (§19) |
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

**Verdict: FRESH CALL(S) REQUIRED — two real, independent provider executions**
(corrected in G2A.2, §20): one against the BASE turn's idempotency key, one
against the quality-regeneration turn's distinct `.q2.`-derived key. Both must
reach the provider — neither may be satisfied by a cache hit, since a cache
hit would prove nothing about whether the two keys collide. See §20 for the
exact required shape and why an earlier draft of this section wrongly allowed
the second execution to be "a cache hit."

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

**Superseded by §19 (G2A.1, call count and targets) and §20 (G2A.2, OR
semantics).** Left below for the historical record only — two corrections:
the call target must be a G2B0 candidate, not `00052-zqd` (§19), and OR's
second call is a required independent provider execution, never a cache hit
(§20; the "may resolve as a cache-hit" sentence in the OR row below was wrong
and is corrected there).

| Feature | Calls | Why current evidence is insufficient | Requires |
|---|---|---|---|
| Coffee | 1 | Writer prompt rewritten (`4078de99`) after the only real evidence was captured | image fixture, Firebase auth, App Check, deployed backend, provider |
| Palm | 1 | Same rewrite, same gap | image fixture, Firebase auth, App Check, deployed backend, provider |
| SoulMate | 1 | Entire prompt pipeline + response contract (`identity`) rewritten since capture | Firebase auth, App Check, deployed backend, provider (image gen), **real Premium entitlement** (sandbox purchase — review access does not work here, §9) |
| OR | 2 | (a) no evidence exists against the deployed production origin, only a local proxy; (b) G1-D14's idempotency key is untested against the real Firestore replay cache | Firebase auth, App Check, deployed backend, provider. ~~Call (b) may resolve as a cache-hit rather than a second real provider call~~ **— WRONG, corrected in §20: both calls must be independent real provider executions; a cache hit would prove nothing about key collision.** |
| Dream | **0 — blocked on deploy** | The frozen writer isn't deployed (§5); a live call today would test unknown legacy code, not the current contract. Deploy is the prerequisite, not a call | — |
| Tarot | 1 | 2026-09-06 evidence used `gpt-4o`, predating the writer-prompt rewrite already live in the current production build | Firebase auth, App Check, deployed backend, provider |
| Yıldızname | 0 | Already proven live for the exact frozen commit via the tagged candidate; feature flag defaults off, so nothing in this release depends on fresh evidence | — |

**TOTAL: 6 real provider calls (superseded — see §19 for the corrected total
of 7)** (Coffee 1, Palm 1, SoulMate 1, OR 2, Tarot 1),
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

---

## 19. G2A.1 — Deployed backend compatibility closure

Independent verification found that §8's Tarot classification understated the
problem: it treated Tarot as stale *live-quality evidence* when current source
shows a *deploy-compatibility* question — can the traffic-serving revision even
execute the current wire contract at all — that must be answered before any
G2B provider call is useful. This section answers it for every live feature,
by exact commit ancestry (`git merge-base --is-ancestor`), not date comparison
alone. Read-only throughout: `gcloud run/artifacts/builds` describe/list only,
git history, and the two already-run zero-cost `/health`+`/ready` checks.
Nothing new was deployed, mutated, called, or purchased.

### A. Deployed source truth

`gcloud run revisions describe oracly-api-00052-zqd` carries no
`source_commit` label (unlike the Yıldızname candidate). But its image digest
— `sha256:c32ffe488aa9421c571de8d3d1421feaff310a607053455b7dad412528e2cb9e` —
was found, via `gcloud artifacts docker tags list`, to be the **exact** digest
of the tag `apple-iap-roots-9f37cff1` in the same Artifact Registry repo. That
short hash resolves to a real commit in this repo:

```
SOURCE COMMIT: 9f37cff166867da5cf4e62a34d4f531a8a04c774
  "Ship Apple PKI root certificates in the backend image"
  2026-09-17 15:04:47 +0300
IMAGE DIGEST: sha256:c32ff...b9e39 (full digest in repo evidence, not reprinted here)
CREATED: 2026-09-18T17:10:46Z
100% TRAFFIC: YES
```

This is an exact-digest match to a commit-named tag, not a signed provenance
attestation (`slsa_build_level: unknown` on the image) — strong, but stated
as inference, not cryptographic proof. `git merge-base --is-ancestor
9f37cff1 HEAD` confirms it is a real ancestor of the current branch tip. All
compatibility findings below compare **HEAD vs `9f37cff1`** using
`git diff`/`git log 9f37cff1..HEAD`, which is exact regardless of commit
dates.

### B. Tarot — INCOMPATIBLE (confirmed, not inferred)

`git log 9f37cff1..HEAD -- backend/src` shows 9 Tarot-narrative commits
postdate the deployed source, ending in `3488248c` ("cut classical readings to
narrative v2") and `c342ab8f` ("isolate narrative writer model"), both
2026-09-25 — 8 days after the deploy. The diff for `validate-request.ts`
proves the shape of the gap directly:

```ts
// HEAD — does not exist at 9f37cff1:
function validateTarot(payload) {
  if (payload.mode === undefined || payload.mode === null) {
    return validateLegacyTarot(payload);
  }
  if (payload.mode === 'narrative_v2') {
    return validateNarrativeTarotPayload(payload);   // ← this whole function is new
  }
  fail(ErrorCode.invalidRequest);
}
```

At `9f37cff1`, `validateTarot` has no `mode` branch at all — it unconditionally
reads `payload.cards`/`spreadLabel` (today's `validateLegacyTarot`).
`narrative-tarot-contract.ts`, `narrative-tarot-model.ts` (the dedicated
`gpt-5.6-sol`/reasoning-`none` resolver), `narrative-tarot-result.ts` (the
narrative result parser), `narrative-tarot-prompts.ts`, and the Phase 6F.1
attempt-aware transport wiring in `narrative-tarot-attempt.ts`/`routes/ai.ts`
are **all** part of the 52-file diff — none exist in the deployed image.

| Component | 00052 | Introduced |
|---|---|---|
| `mode` field recognition in `validateTarot` | ABSENT | — (new in HEAD) |
| `narrative-tarot-contract.ts` (`validateNarrativeTarotPayload`) | ABSENT | between 9f37cff1 and HEAD |
| `narrative-tarot-model.ts` (frozen `gpt-5.6-sol`/reasoning `none`) | ABSENT | `c342ab8f`, 2026-09-25 |
| `narrative-tarot-result.ts` (result parser) | ABSENT | between 9f37cff1 and HEAD |
| `narrative-tarot-prompts.ts` / prompt rules | ABSENT | between 9f37cff1 and HEAD |
| Attempt-aware transport (`narrative-tarot-attempt.ts`, `ai.ts` dispatch) | ABSENT | between 9f37cff1 and HEAD |
| Legacy Tarot path (`mode` unset → `validateLegacyTarot`) | PRESENT | unchanged since 9f37cff1 |

Client source: `ProductFeatureFlags.tarotNarrativeV2` defaults `true`, and the
live request path (`NarrativeTarotLiveRequestFactory` → `NarrativeTarotWireContract`
→ `generateNarrativeTarotReading`) always sends `mode: 'narrative_v2'`. The
deployed validator has no code path that recognizes that field — it would
either reject the request as malformed (if the new payload shape lacks the
old `cards` array the legacy validator expects) or, worse, silently process
it as a near-empty legacy reading. Neither is a working Tarot reading.

**TAROT NARRATIVE V2 ↔ TRAFFIC REVISION: INCOMPATIBLE.**
**TAROT DEPLOY BLOCKER: YES.** A live call against `00052-zqd` today would not
be release evidence — it would just demonstrate the incompatibility. This
supersedes §8/§15/§16's "1 fresh call" framing for Tarot: the correct first
action is a candidate deploy (§I below), not a call against current traffic.

### C. Dream — confirmed, and the gap is larger than §5 stated

15 Dream commits (`50eebc5e` … `fc06a744`) postdate `9f37cff1` — not just the
frozen-writer binding, but the entire Phase 2–4C engine: multilingual request
identity, the Phase 3 safety firewall (`dream-safety.ts`, `assertDreamInputSafe`),
symbol/lexical-collision closure, history-claim grounding, premium narrative
quality, and the live-gate calibration itself. `service.ts`'s `dream()` method
at `9f37cff1` is a bare `transport.complete({model, jsonMode:true, messages:
dreamMessages(...)})` with no safety gate, no acceptance filter, no writer
binding — categorically different code from HEAD's version. **DEPLOY
REQUIRED** (confirmed, deeper than §5 alone showed). No call made; none
proposed here.

### D/E/F/G/H. Coffee, Palm, SoulMate, OR, billing, reading-operations — COMPATIBLE

`git diff --name-only 9f37cff1 HEAD -- backend/src` returns exactly 52 files —
all Dream-, Tarot-narrative-, or Yıldızname-specific, plus 9 shared files
(`ai/service.ts`, `ai/validate-request.ts`, `ai/openai-transport.ts`,
`ai/prompts.ts`, `ai/request-fingerprint.ts`, `config.ts`, `errors.ts`,
`routes/ai.ts`, `types.ts`, `routes/account-deletion.ts`). Reading each shared
diff line-by-line:

- **`routes/ai.ts`**: every new block is gated on `operation === 'tarot_reading'
  && mode === 'narrative_v2'`, `operation === 'yildizname_reading'`, or
  `operation === 'dream_analysis'`. The base dispatch/replay path every other
  operation uses is untouched.
- **`ai/service.ts`**: adds `yildiznameReading()` and a `mode === 'narrative_v2'`
  branch inside `tarotReading()`; `coffee()`, `palm()`, `soulmateDraw()`,
  `soulmateInterpretation()`, and the legacy Tarot branch are byte-for-byte
  unchanged.
- **`ai/validate-request.ts`**: the only operation-type changes are the new
  Tarot `mode` branch and the new `yildizname_reading` case; `validateDream`
  gained one field (`history`) — Dream-only, moot since Dream isn't deployed
  regardless.
- **`ai/request-fingerprint.ts`**: `coffee_analysis`/`palm_analysis`/
  `soulmate_draw`/`soulmate_interpretation`/legacy `tarot_reading`/`tts` cases
  are untouched; only `dream_analysis` (refactored to a helper, same behavior)
  and two new cases (`narrative_v2`, `yildizname_reading`) changed.
- **`ai/openai-transport.ts`**: request-body construction (`buildChatCompletionBody`)
  is an extraction, not a behavior change — same fields, same call sites.
  Error-mapping (`mapHttpFailure`) gained more precise classification and
  non-secret diagnostic fields (`httpStatus`, `requestId`, `providerMessage`)
  but the success path and existing error codes for Coffee/Palm/SoulMate/OR
  are unaffected.
- **`ai/prompts.ts`**: `dreamMessages`/`DREAM_SYSTEM` moved to `dream-prompts.ts`
  (re-exported) — Dream-only; `coffeeMessages` and everything below is
  unchanged.
- **`config.ts`**: only adds new keys (`openaiTarotNarrativeModel`,
  `openaiYildiznameNarrativeModel`, `openaiDreamModel`, and their reasoning
  counterparts) — nothing existing changed shape.
- **`errors.ts`** / **`types.ts`**: additive only (`dreamSafetyBlocked` error
  code, `yildizname_reading` operation).
- **`routes/account-deletion.ts`**: now requires an `expectedTargetUid` body
  field as an anti-race check (unrelated to the six features audited here;
  noted for completeness, not scored as a blocker in this phase).

No file under `backend/src/reading/`, `backend/src/billing/`, or
`backend/src/middleware/` (staged images, active pointer, claim/result,
acceleration, `response-replay-repository.ts`, purchase-binding persistence)
appears anywhere in the 52-file diff — **all of it is byte-identical between
the deployed commit and HEAD.** Commit `4078de99` (2026-09-15, the Coffee/
Palm/SoulMate writer-prompt rewrite §6 already found) is confirmed an
ancestor of `9f37cff1` (2026-09-17) — so the deployed revision already runs
the *current* Coffee/Palm/SoulMate prompts. §6's "stale evidence" finding
stands (the evidence predates the prompt), but it is a live-quality gap, not
a deploy-compatibility one.

| Feature | CURRENT CLIENT ↔ 00052 | Basis |
|---|---|---|
| Coffee | **COMPATIBLE** | prompt + wire path untouched since 9f37cff1; evidence still stale (§6) for quality only |
| Palm | **COMPATIBLE** | same |
| SoulMate (durable op, portrait pipeline, `identity` response shape) | **COMPATIBLE** | `soulmate-*.ts` untouched since 9f37cff1 (post-4078de99); evidence still stale (§6) for quality only |
| OR (chat/oracle transport, response-replay repository, auth/App Check) | **COMPATIBLE** | untouched since 9f37cff1; G1-D14's idempotency-key scheme is a client-side string the server hashes opaquely — no server-side awareness needed, so it is compatible but its *correctness* is still unproven live (§7) |
| Billing (`/v1/billing/verify`, `purchaseBindings` fields: `productId`/`status`/`kind`/`expiryAtMs`/`verifiedAtMs`) | **COMPATIBLE** | zero files under `backend/src/billing/` changed since 9f37cff1 |
| Reading operations (waiting/processing/ready/failed, staged images, active pointer, exact-operation recovery, result fetch, acceleration quote/claim) | **COMPATIBLE** | zero files under `backend/src/reading/` changed since 9f37cff1 |

### I. Correct next sequence — G2B0 before G2B

Because Tarot (a default-on, non-optional live feature) is deploy-incompatible,
and Dream and Yıldızname require code absent from traffic, **no G2B provider
call should be spent against `oracly-api-00052-zqd`.** The correct sequence:

**G2B0 (not performed here — classification only):** deploy the current
backend source as a **0%-traffic tagged candidate** (the same pattern already
used for the Yıldızname candidate `y8c1-169c514a`). No traffic-percent change.
Then re-run the zero-cost `/health` and `/ready` checks against the candidate's
own tagged URL, and read back its safe (non-secret) config/model metadata the
same way §A did for `00052`. Only after that passes does G2B spend any real
provider call — all against the **candidate**, not `00052` — for every feature,
including Coffee/Palm/SoulMate/OR, so every piece of live evidence in this
release comes from one consistent, current source tree. Production traffic
promotion is then a separate, later, explicit decision — not implied by
running G2B against the candidate.

### J. Revised live-call budget

```
PRE-DEPLOY (against 00052-zqd): 0

POST-CANDIDATE (after G2B0):
  Coffee     1   (§6 — stale writer-prompt evidence)
  Palm       1   (§6 — same)
  SoulMate   1   (§6 — stale prompt/identity evidence; BLOCKED until a real
                  sandbox/test Premium entitlement exists for the test
                  identity — do not call this executable before then)
  OR         2   (§7, corrected in §20 — two INDEPENDENT real provider
                  executions against the candidate: one on the base turn's
                  idempotency key, one on the quality-regeneration turn's
                  distinct `.q2.`-derived key. Both must reach the provider;
                  neither may be a cache hit, or the collision test proves
                  nothing. See §20.)
  Dream      1   (§C — now meaningful only once the candidate carries the
                  frozen gpt-6-astra/medium binding)
  Tarot      1   (§B — now meaningful only once the candidate carries the
                  Narrative V2 contract)
  Yıldızname 0   (already proven live against 169c514a, itself an ancestor
                  of HEAD with zero further Yıldızname backend changes since —
                  confirmed by `git log 169c514a..HEAD -- backend/src/ai/
                  narrative-yildizname-*.ts`, empty)

TOTAL: 7
```

### K. Corrected release blocker classification

| Blocker | Class | Status |
|---|---|---|
| Tarot Narrative V2 cannot run on traffic revision | **DEPLOY-COMPATIBILITY BLOCKER** | Confirmed §B — supersedes §16's "live-quality" framing |
| Dream engine (not just the writer) absent from traffic revision | **DEPLOY-COMPATIBILITY BLOCKER** | Confirmed §C — deeper than §5/§16 stated |
| Yıldızname engine absent from traffic revision | **DEPLOY-COMPATIBILITY BLOCKER (non-blocking for this release)** | Confirmed §A; non-blocking only because the client flag defaults off |
| Coffee/Palm/SoulMate/OR live-quality evidence stale | **LIVE-QUALITY EVIDENCE BLOCKER** (not a compatibility problem) | Confirmed compatible §D–H; §6/§7 quality gap stands |
| Everything else in §16 (store, device, iOS build, review-access, stale pointer) | unchanged | See §16 |

A stale-quality call must never be spent against a backend already known to
be running the wrong contract — this is why Tarot/Dream/Yıldızname move to
G2B0 (deploy-candidate) rather than G2B (call the current 100%-traffic
revision).

No production code was changed in G2A.1. No defect was found in current
source — every gap found is deployment staleness, which is exactly what this
phase exists to surface before any release ships.

**Raw evidence artifact (G2A.2):** the Cloud Run → image digest → Artifact
Registry tag → source commit mapping above is pinned as a sanitized,
independently-checkable JSON file at
`docs/product/g2/evidence/G2A2_DEPLOYED_BACKEND_SOURCE_EVIDENCE.json`, so a
reviewer on GitHub can verify the exact digest/tag/commit correspondence
without re-running `gcloud`. It carries no secrets — only the revision name,
traffic percent, creation time, image digest, the matching tag, the resolved
commit, and the same `/health`/`/ready` bodies already shown above. A repeat
observation taken while writing this (2026-09-28T23:25:41Z) found **zero
drift** from the observation above: same revision, same 100% traffic, same
image digest, same tag match, same `/health`/`/ready` responses.

---

## 20. G2A.2 — OR live-proof semantics correction

§7's and §19.J's wording ("call (b) may resolve as a cache-hit... if the
design works") was wrong and is corrected here. A cache hit on the second
request would prove the replay cache works — it says nothing about whether
the *new* `.q2.`-derived quality-regeneration key collides with the *base*
turn's key, which is the actual thing G1-D14 needs proven. Terminology from
here on distinguishes an **HTTP request** (a call to `/v1/ai/complete`) from a
**provider execution** (that request actually reaching OpenAI, not served
from the Firestore replay cache).

**The required post-candidate OR proof is exactly two independent provider
executions:**

- **Provider execution #1 — base turn.** One controlled real turn sent
  against the tagged candidate, using its own (base) idempotency key. The
  provider **must** execute — this is a fresh key with nothing cached yet, so
  there is no cache-hit possibility here regardless.
- **Provider execution #2 — quality regeneration.** A quality-regeneration of
  that same turn, sent under its distinct `.q2.`-derived idempotency key (the
  G1-D14 fix). The provider **must independently execute again** — if this
  request instead returned a cache hit against execution #1's cached entry,
  that would mean the keys collided, i.e. G1-D14 failed. A cache hit here is
  not an acceptable outcome; it is the failure mode this test exists to catch.

Both are counted in the 7-call budget as OR's 2 executions. Neither may be
skipped, and neither may be satisfied by a cache hit.

**Optional replay check (not one of the 7 executions).** After execution #1
or #2 has completed, an additional HTTP request may be sent reusing that
*same, already-completed* idempotency key, solely to prove the replay cache
itself works as designed. Expected outcome: a cache hit, 0 additional
provider executions. This is a separate, optional proof of the *replay*
mechanism, distinct from the *collision* proof above, and does not add to the
call budget.

**Corrected post-candidate minimum real provider executions:**

```
Coffee     1
Palm       1
SoulMate   1   (blocked until a real sandbox/test Premium entitlement exists)
OR         2   (both independent executions — base key, then distinct .q2. key)
Dream      1
Tarot      1
Yıldızname 0
TOTAL      7
```

This is the same total as §19.J (7) — only OR's internal semantics were
wrong, not the count. §19.J and §15 are corrected above with pointers to this
section; the number itself does not change.

---

## 21. G2A.2 — Static reconfirmation (documentation only, no code changed)

Independently re-verified in this phase, by exact git object identity
(`git rev-parse <commit>:<path>`, not date comparison), against the resolved
deployed commit `9f37cff166867da5cf4e62a34d4f531a8a04c774` and current HEAD:

| Claim | Result |
|---|---|
| `backend/src/reading` tree identical (deployed commit vs HEAD) | **IDENTICAL** — same tree SHA `9a93cc4e…` both sides |
| `backend/src/billing` tree identical | **IDENTICAL** — same tree SHA `4bdec111…` both sides |
| `backend/src/middleware` tree identical | **IDENTICAL** — same tree SHA `354cde88…` both sides |
| `backend/src/ai/reading/writer-prompts.ts` blob identical (Coffee/Palm) | **IDENTICAL** — same blob SHA `de485806…` both sides |
| `backend/src/ai/reading/pipeline.ts` blob identical (Coffee/Palm) | **IDENTICAL** — same blob SHA `fc3da331…` both sides |
| `soulmate-prompt.ts` / `soulmate-portrait-prompt-builder.ts` / `soulmate-visual-profile.ts` / `soulmate-portrait-identity.ts` blobs identical | **IDENTICAL** — each pair matches exactly |
| Narrative Tarot backend contract (`narrative-tarot-contract.ts`) absent from resolved deployed commit | **CONFIRMED ABSENT** — `git cat-file -e 9f37cff1:...` fails (path does not exist at that commit) |
| Dream Phase 2–4C files (e.g. `dream-safety.ts`) absent from resolved deployed commit | **CONFIRMED ABSENT** — same check, fails |
| `ProductFeatureFlags.tarotNarrativeV2` default | **TRUE** — `lib/core/feature_flags/product_feature_flags.dart:21` |
| Current Narrative Tarot wire payload includes `mode=narrative_v2` | **CONFIRMED** — `NarrativeTarotWireContract.mode = 'narrative_v2'`, sent as the `mode` field in `payloadFor()` (`lib/features/tarot/narrative/transport/narrative_tarot_wire_contract.dart:11,17`) |
| All `backend/src/ai/narrative-yildizname-*.ts` blobs identical between candidate commit `169c514a1f51e42cab84d26d075199ffe130fc6d` and HEAD | **IDENTICAL** — `git ls-tree` diff of both trees for that filename pattern is empty |
| `ProductFeatureFlags.yildiznameNarrativeV1` default | **FALSE** — `lib/core/feature_flags/product_feature_flags.dart:60` |

No source was modified to produce this table. All twelve rows are direct git
object/source observations.

---

## 22. G2A.2 test-claim honesty

The 25-test result cited in G2A.1 (§19.B, "TARGETED PARITY TESTS") —
`narrative-tarot-6d1-contract.test.ts`, `narrative-tarot-6d1-fingerprint.test.ts`,
`narrative-tarot-6f1-attempt.test.ts`, `narrative-tarot.test.ts`,
`tarot-reading.test.ts`, 25 passed — was run once, in the G2A.1 phase of this
same session, and is **not re-run in G2A.2**. It is labeled here as
**PREVIOUSLY RUN (this session, G2A.1)**, not independently re-verified in
this phase. No test rerun was required or performed for this phase's
evidence/docs-only changes.

No real provider calls, deploys, traffic mutations, store transactions,
device runs, or Secret Manager reads were made in G2A.2.

---

## 23. G2B0 — current backend deployed as a 0%-traffic tagged candidate

User-authorized deploy. Full evidence:
`docs/product/g2/evidence/G2B0_CANDIDATE_DEPLOY_EVIDENCE.json`.

**Deploy-tooling defect fixed first.** `backend/scripts/deploy-cloud-run.sh`
was missing all six frozen model bindings (Coffee/Palm reading vision/writer/
reasoning, Tarot Narrative V2, Yıldızname narrative — Dream's was already
present) and used replace-semantics flags (`--env-vars-file`/`--set-secrets`)
that would have silently deleted reading-durability, billing/Apple IAP and
review-access configuration on the next real update, since the script never
lists them. Fixed to `--update-env-vars`/`--update-secrets` (merge semantics)
plus the six bindings, committed as `aa735bcb7a1be89cffb62d77537b50c896eb1b2c`
("fix(deploy): bind frozen release candidate models") with a new deterministic
regression (`backend/tests/deploy-cloud-run-contract.test.ts`) and two
existing Dream Phase 4C.3 tests updated for the intentional allowlist
addition. Full backend suite 1661 passed/1 skipped/0 failed; TSC clean.

**Build.** Local Docker Desktop's daemon was not running in this environment,
so the image was built via `gcloud builds submit` (Cloud Build) — a
mechanism already established in this project's own build history — from a
`git archive aa735bcb… -- backend` export into a clean scratch directory,
**not** the live working tree (which holds ~700+ files of unrelated
pre-existing uncommitted changes under `backend/`). This guarantees no
uncommitted source entered the image. Build `43b08112-7c1a-45d4-b447-20889882f90e`,
pushed to `europe-west1-docker.pkg.dev/oracly-7f613/oracly/oracly-api:g2b0-aa735bcb7a1b`,
digest `sha256:e35475982cea3cc8a527df1cc81a812f5621bff752966fe39b19d676eefc4cfc`.

**Deploy.** One `gcloud run deploy --no-traffic --tag=g2b0-aa735bcb7a1b`
against that exact image, reusing the existing runtime service account,
resource limits (1 CPU/1Gi/concurrency 20/timeout 180s/min 0/max 1) and
ingress, merging in only the frozen-model env keys. Result: new revision
`oracly-api-00085-hef`, 0% traffic. `oracly-api-00052-zqd` (production)
verified still 100% both immediately after deploy and again after all
candidate checks — no traffic mutation occurred anywhere.

**Validation, against the candidate's own tagged URL only:**

| Check | Result |
|---|---|
| `/health` | 200, `{"status":"ok"}` |
| `/ready` | 200, all capabilities `true` — **including `readingDurabilityConfigured` and `billingAppleConfigured`**, proving the merge-semantics fix preserved everything the old replace-semantics mechanism would have deleted |
| Frozen model readback | All 6 bindings present with the exact required values (Coffee/Palm `gpt-5.6-sol`/`low`; Tarot `gpt-5.6-sol`/`none`; Yıldızname `gpt-5.6-sol`/`none`; Dream `gpt-6-astra`/`medium`); allowlist now `gpt-4o,gpt-4o-mini,gpt-5.6-sol` |
| Durability/billing/review-access keys | All 14 pre-existing non-secret keys still present (bucket, task queue, target URL, audience, service account, Apple IAP fields, review-access hash) |
| Secret references | `OPENAI_API_KEY` and `APPLE_IAP_PRIVATE_KEY` both still secret-backed; neither value was ever read; `APPLE_IAP_PRIVATE_KEY` was never even touched by this deploy (merge semantics) |
| Unauthenticated probe | `POST /v1/ai/complete` with no auth → `401 {"success":false,"error":{"code":"unauthorized"}}` — rejected before any provider call |

**Known gap, disclosed honestly:** the revision's `source_commit` *label*
reads `169c514a1f51e42cab84d26d075199ffe130fc6d` (the prior Yıldızname
candidate's label) because this deploy didn't pass `--update-labels` and
Cloud Run inherited it from the previous latest-revision template. Cloud Run
revisions have no update/patch command (`gcloud run revisions` offers only
`delete`/`describe`/`list`), so this cannot be corrected without creating a
second candidate revision — which would violate "exactly one candidate
revision deployed." The label is therefore **known-stale and not trusted**;
the authoritative source identity is the image digest this deploy's own
build+push produced (`sha256:e35475…c4cfc`), which the revision readback
above confirms is exactly what's running.

**This proves deploy-time compatibility only.** No provider was called
(other than the 401-rejected probe, which never reached one). **G2B live
quality is NOT proven** — that is the next, not-yet-started phase.

Real provider executions: 0. Store transactions: 0. Production traffic
mutations: 0. Production runtime source (`backend/src`) unchanged.

---

## 24. G2B — budget terminology correction and live provider evidence

G2A.2 §20 counted **7 provider executions**. That number mixed a top-level
feature with the provider stages inside it. From G2B onward the authoritative
accounting uses three different words:

| Term | Meaning |
|---|---|
| **Feature operation** | One user-facing reading or controlled turn the product owner asked for |
| **HTTP request** | One call to a backend route |
| **Raw provider execution** | One completion that actually reaches the model provider, not a cache replay |

This is an evidence-terminology correction. It is not a product defect.

**Coffee and Palm.** The current pipeline is an observer completion, then a
writer completion, then a repair completion only when the binding gate rejects
the writer. A fresh reading is therefore **2 or 3 raw provider executions**.
The client may use more than one HTTP request (observe, then write). Repair,
when it happens, is inside the write request and is not a separate HTTP call.
If logs do not show whether repair ran, the honest count is the range **2–3**,
not an invented exact number.

**Dream.** One provider completion, then parse, output safety, and acceptance.
No automatic second provider call. **Exactly 1** raw provider execution.

**Tarot Narrative V2.** Attempt 1 is normally one provider execution. Attempt 2
exists only for a legitimate retryable provider or quality failure, and the
idempotency key carries `:nv2:a2`. **1 or 2** raw provider executions. No
attempt 3.

**OR (G1-D14).** Exactly two independent executions: the base turn key, then
`OrOperationId.runQualityAttempt(2)` (`<turn>.q2.<nonce>`). A cache hit on the
second key is a failure of the proof.

**Yıldızname.** 0 in this slice. Frozen narrative blobs stay as they are.

**SoulMate.** Not in this slice.

**Pre-SoulMate raw provider budget:** minimum **8** (Coffee 2, Palm 2, Dream 1,
Tarot 1, OR 2), maximum **11** (Coffee 3, Palm 3, Dream 1, Tarot 2, OR 2).
Hard cap **11**.

### Live run against `oracly-api-00085-hef` (2026-09-29)

Candidate only. Production `oracly-api-00052-zqd` stayed at 100%. Candidate
traffic stayed at 0%. Image digest unchanged
(`sha256:e35475982cea3cc8a527df1cc81a812f5621bff752966fe39b19d676eefc4cfc`).
`/health` and `/ready` were 200 before and after.

Auth was the physical device's existing Firebase anonymous session, with a
real App Check token from the Android debug provider (Play Integrity returned
no token on this sideload). No auth bypass and no placeholder tokens.

Durable Coffee/Palm staging was **not** used. The candidate's
`READING_TASK_TARGET_URL` is the stable production host, so a staged operation
would have scheduled the worker there. Coffee and Palm used the current
observe/write client contract on the candidate `/v1/ai/complete` URL only.
The derived reading origin host matched the candidate tag.

| Operation | Feature ops | Raw provider executions | Result |
|---|---|---|---|
| Coffee | 1 | 2–3 (observe + write HTTP 200; repair not logged) | Client parser and composer accepted |
| Palm | 1 | 1 (observer only) | Observer `bindFailure=unusable`; writer not called |
| Dream | 1 | 1 | `invalid_response`; client parser rejected; no second call |
| Tarot Narrative V2 | 1 reading, attempt 1 only | 1 | Result V2 parser, quality validator, and Flutter quality gate accepted |
| OR | 2 | 2 | Base key and `.q2.` key both executed; reply hashes differ; no cache collision |
| Yıldızname | 0 | 0 | `narrative-yildizname-*.ts` blobs still match `169c514a` |
| SoulMate | 0 | 0 | Deferred |

Provable raw executions: **7–8**. Hard cap was not exceeded. No local fallback.
No raw provider error was shown as user copy. No store transaction. No new
deploy. No production source change.

Full sanitized record:
`docs/product/g2/evidence/G2B_LIVE_PROVIDER_EVIDENCE.json`.

**G2B pre-SoulMate verdict: FAIL.** Coffee, Tarot, and OR passed. Palm and
Dream did not clear the current acceptance gates. SoulMate remains a separate
sandbox-entitlement closure. Do not promote this candidate.

---

## 25. G2B.1 — Palm and Dream live-evidence closure

The G2B failure record above stays. The two failures do not mean the same thing.

**Dream.** The single live case was `tr-negated-fear` on `gpt-6-astra`. Frozen
corpus evidence already rejects that pair for `emotion_contradiction`
(`DREAM_PHASE4C2_MODEL_AB.md`, and the Phase 4C.2a reclassification, where it
remains Astra's remaining reject). The live `invalid_response` matches that
known result. It was a QA case-selection error, not a new runtime defect.
Dream production code was not changed.

**Palm.** `palm_sample.jpg` and `palm.jpg` are the same blob
(`56289c378daaba77034418eafe205e7c02d0460c`). The observer rejected it as
unusable (`bindFailure=unusable`). That is the current image-quality gate.
The same image was not sent again, and the gate was not weakened.

### G2B.1 live run (2026-09-29)

Same candidate, still at 0% traffic. Production `oracly-api-00052-zqd` stayed
at 100%. Digest unchanged. `/health` and `/ready` were 200 before and after.
Coffee, Tarot, OR, and Yıldızname were not called again.

**Dream case `tr-history`.** One provider execution. The request was built
with `DreamProviderEvidence.context` plus `DreamHistoryBuilder` from the
corpus priors only: symbols `Deniz` / `Huzur`, emotion `Huzur`, history
`symbol:sea` recurring, prior count 2, no memory summary. HTTP 200 success.
Candidate logs: `parsedOk=true`, no failure stage. A success body is returned
only after parse, output safety, Phase 2, Phase 4A, and Phase 4B. The client
output-safety check and premium-delivery check both passed. No second call.

**Palm source.** `tool/e3e_private/fixtures/e3f/palm_e3f.jpg`
(sha256 `8dd1661e946b4005b8b8d05614362c5f5ef61302989955aaa0f4f81256be6714`),
763×1200. Provenance documents one open right palm. It is not the rejected
fixture. The current client image heuristic did not hard-fail. Wire hand was
`right`. Observe and write both returned HTTP 200 with `parsedOk=true`. The
client parser and composer accepted the reading. Repair was not logged, so
the raw count is **2–3**.

| Slice | Feature ops | New raw provider executions | Result |
|---|---|---|---|
| Dream `tr-history` | 1 | 1 | PASS |
| Palm E3F right hand | 1 | 2–3 | PASS |
| Coffee, Tarot, OR, Yıldızname | reused | 0 | prior PASS kept |

New G2B.1 raw executions: **3–4**. Phase hard cap 4 was not exceeded.
Prior G2B range remains **7–8**. Cumulative range: **10–12**.

No local fallback. No raw provider error in user copy. No deploy, traffic
change, store transaction, or SoulMate call. Production source unchanged.

Sanitized record:
`docs/product/g2/evidence/G2B1_PALM_DREAM_CLOSURE.json`.

**G2B.1 verdict: PASS.**
**G2B pre-SoulMate verdict: PASS.** Coffee, Tarot, OR, Dream, and Palm live
evidence may be frozen. Do not promote this candidate. SoulMate is the next
separate sandbox-entitlement closure.

---

## 26. G2B-SM — license-test Premium and candidate-only SoulMate

G2B0 (`oracly-api-00085-hef`) still points `READING_TASK_TARGET_URL` at the
stable production host. SoulMate was not run there. A new 0% revision was
created from the same immutable image, changing only the worker target so
the durable task returns to its own tag.

| | |
|---|---|
| Revision | `oracly-api-00086-koy` |
| Tag | `g2bsm-aa735bcb7a1b` |
| Traffic | 0% |
| Image digest | `sha256:e35475982cea3cc8a527df1cc81a812f5621bff752966fe39b19d676eefc4cfc` |
| Source commit label | `aa735bcb7a1be89cffb62d77537b50c896eb1b2c` |
| Worker target | `https://g2bsm-aa735bcb7a1b---oracly-api-uya7zqzwra-ew.a.run.app/internal/reading-tasks/process` |
| OIDC audience | unchanged stable service URL `https://oracly-api-uya7zqzwra-ew.a.run.app` |

Production `oracly-api-00052-zqd` stayed at 100%. The old G2B0 candidate
stayed at 0%. `/health` and `/ready` on the new tag were 200.

The device build was an in-place upgrade of `app.oracly` with
`APP_ENV=staging`, the G2B-SM proxy and billing URLs, and the App Check
debug provider. `ORACLY_DEV_PREMIUM` was absent. Review access was not used.

Play Billing returned all three catalog products. Restore found no existing
entitlement. One Google Play license-test monthly purchase was completed
after the sheet showed “Test kartı, her zaman onaylanır” and stated that no
payment would be taken. Candidate `billing_verify` returned
`subscription_active`. After a force-stop, Premium was still active. No
second store transaction occurred.

One durable SoulMate operation used the QA identity “QA Fixture C”, birth
date 1996-06-15, feminine, empty intention. Every worker event for that
operation, including OIDC verification, the entitlement-gated portrait, and
the interpretation, is on `oracly-api-00086-koy`. Production did not process
it. Portrait provider executions: 1 (`gpt-image-2`, configured 1024×1536,
high). Interpretation provider executions: 1 (resolved `gpt-4o`). The result
rendered and, after another force-stop, reopened with no new provider call.

Raw provider executions in this phase: **2**. Hard cap 8 was not exceeded.

Sanitized record:
`docs/product/g2/evidence/G2BSM_STORE_SOULMATE_CLOSURE.json`.

**G2B-SM verdict: PASS.** Do not promote this candidate.

---

## 27. G2C — Android release artifact and TECNO audit

G2C spent no provider calls, no store transactions, and made no Cloud Run
change. Historical device smokes are not current blockers:

| Old smoke | Status |
|---|---|
| `tool/device_premium_gate/PREMIUM27_SMOKE.json` | SUPERSEDED BY G2B-SM |
| `tool/device_soulmate_gate/SOULMATE21_SMOKE.json` | SUPERSEDED BY G2B-SM |
| `tool/device_palm_gate/PALM20_SMOKE.json` | Provider quality SUPERSEDED BY G2B.1. Camera OS path closed in G2C. |
| `tool/device_coffee_gate/COFFEE20_SMOKE.json` | Provider quality SUPERSEDED BY G2B. Camera and photo picker closed in G2C. |
| `tool/device_yildizname_gate/YILDIZNAME22_SMOKE.json` | Historical UI note. Does not reopen frozen Yıldızname evidence. |

The production define file already pointed at the stable service
`oracly-api-uya7zqzwra-ew.a.run.app` for AI and billing. Legal URLs are the
public GitHub documents and returned HTTP 200. Release signing uses the
upload keystore. There is no debug-signing fallback. R8 minify and resource
shrinking are on.

Built from committed source `e920da1a` (the dirty worktree was not compiled
in):

| Artifact | Size | SHA-256 |
|---|---|---|
| `app-release.aab` | 121,756,641 | `1f08494a85df1deacdadf8a4021140e3ea2161b409aef1ade6a61fa19d3fd41` |
| `app-release.apk` | 123,351,764 | `ccc7dee474d5e8ec5ab97fbbef4f9642d0e538249ed78af1109e1b29df7119e5` |

Both signatures verify. Certificate SHA-256
`e789561fac940d252442f98e1d6c7dba4eefc0bb361f17cffff54309d6007ad5`
is the upload certificate, not the Android debug certificate. The merged
manifest is `app.oracly` `1.0.0` / `26091306`, minSdk 24, targetSdk 36,
not debuggable, no cleartext, billing present, camera and microphone
optional, no storage or advertising-id permissions. Repo versionCode
`26091306` has no trustworthy Play Console counterpart in the repo, so
upload eligibility stays unknown. It was not bumped.

The TECNO installation was left in place (`1.0.0` / `26092906`, same upload
certificate). Navigation covered Home, OR, Coffee, Palm, Astrology,
Yıldızname, Tarot, Dream, Premium, the saved SoulMate result, Profile, and
Settings. Android back returned. One input-timeout ANR occurred during rapid
automation after Tarot; there was no Flutter crash and no overflow. The
process was restarted without clearing data. The saved SoulMate result
reopened from the journal.

Palm and Coffee reached the real camera permission boundary and the in-app
chamber camera, then returned without an analysis submit. Both photo pickers
opened and were cancelled. The SoulMate share sheet opened with a public
caption and share link; nothing was sent. An invalid `oracly://share` view
opened the app and stayed on Home. Exact-operation completion remains an FCM
data route and was not re-delivered. Dream microphone reached “Dinliyorum”
and was cancelled. Settings voice preview was started, then the app was
backgrounded and resumed on the same screen. TalkBack is installed; its
first-run tutorial blocked an in-app screen-reader pass, and the previous
accessibility settings were restored. The phone stayed portrait when a
rotation was requested, then the setting was restored.

**Android store readiness: PROVEN-STORE + PROVEN-DEVICE**, by G2B-SM.
**G2C verdict: PASS.** Android release ready: yes. No Android-blocking item
remains. iOS archive, sandbox purchase, and VoiceOver stay IOS-EXTERNAL.
Production traffic was not promoted.

Sanitized record:
`docs/product/g2/evidence/G2C_ANDROID_RELEASE_DEVICE_AUDIT.json`.

---

## 28. G2C.1 — Android release version-code closure

G2C classified Play upload eligibility as unknown because no Play Console
versionCode was in the repo. Earlier verified Internal Testing evidence
establishes an active release at `1.0.0` / `26091501`. The TECNO QA
installation is `1.0.0` / `26092906`. The repo value `26091306` is older
than both, so it cannot be the next upload.

The release number was advanced deterministically:

`max(26091501, 26092906) + 1 = 26092907`

`pubspec.yaml` is now `1.0.0+26092907`. versionName stayed `1.0.0`. No
feature or runtime source changed. A new signed AAB and APK were rebuilt
from that number with the existing production defines. Both carry package
`app.oracly`, versionName `1.0.0`, and versionCode `26092907`. The upload
certificate is unchanged. The merged manifest stays hardened. Targeted
release tests passed with 0 failures. No live Play Console query was made.
No provider call, store transaction, device install, deploy, or traffic
change occurred.

versionCode upload eligibility is **CLOSED** against the confirmed Play
state: `26092907 > 26091501`. It is also newer than the TECNO QA build.

Sanitized record:
`docs/product/g2/evidence/G2C1_ANDROID_VERSION_CLOSURE.json`.

---

## 29. G2D — production backend promotion

This section supersedes earlier statements that production still serves
`oracly-api-00052-zqd`, that Tarot / Dream / Coffee / Palm / SoulMate / OR
are blocked on a backend deploy, and that Yıldızname remains a 0% candidate.
Those sections stay as the historical record.

G2D promoted one new revision from the already-built immutable image. The
image was not rebuilt. No production source, Android artifact, or pubspec
changed. Provider executions and store transactions stayed at 0.

| Item | Result |
|---|---|
| Production revision | `oracly-api-00087-hut` at 100% |
| Previous production | `oracly-api-00052-zqd` at 0%, retained for rollback |
| G2B0 `00085` and G2B-SM `00086` | remain 0%; `00086` was not promoted |
| Image digest | `sha256:e35475982cea3cc8a527df1cc81a812f5621bff752966fe39b19d676eefc4cfc` |
| Image source commit | `aa735bcb7a1be89cffb62d77537b50c896eb1b2c` |
| Release repo head | `e06383135b75b57e3a9e34271e7d9f17407458a1` |
| Worker target | stable service URL |
| Cutover | one atomic 100% switch; no canary split |
| Rollback | not required, not executed |
| Stable `/health` and `/ready` | 200, required capabilities true |
| Unauthenticated AI and billing | 401 |

**CLOSED:** production backend promotion; Tarot, Dream, and Yıldızname
backend deployment; Coffee/Palm, SoulMate, and OR current backend;
Android backend/API release compatibility. The Android release
`1.0.0+26092907` already points at the stable host.

Yıldızname client flag `yildizname_narrative_v1` stays default false.
That activation is non-blocking.

**Remaining external:** iOS archive/signing, iOS sandbox purchase/restore,
VoiceOver.

**Remaining non-blocking:** FCM delivery not freshly reproven; background
during an active provider wait not freshly reproven; TalkBack human
in-app pass; Yıldızname client flag remains off.

Sanitized record:
`docs/product/g2/evidence/G2D_PRODUCTION_PROMOTION_EVIDENCE.json`.
