# P4F — Final product readiness

Start HEAD: `b27cd8021fbe7d2cb814baaa8805041bffd11a24`  
Worktree: `D:\oracly-p4f-clean` (detached). Primary checkout was not modified.  
Remote branch at start of certification: `b27cd8021fbe7d2cb814baaa8805041bffd11a24`.

## 1. Blocker found and closed

`ProductFeatureFlags.yildiznameNarrativeV1` shipped with `defaultValue: false`.  
`RemoteConfigDefaults` copies that default. `FeatureFlagRuntime` starts from it.  
`RemoteConfigService.beginSession` can replace it only after an accepted remote payload.  
No in-repo production payload sets the key.

A brand-new release user therefore opened Home → Yıldızname → primary leaf on the local archive (`StarMapPrimaryLeafOpen` returns before prepare).  
The flag comment called that archive the rollback. Phase 8 is the live Narrative V1 path. The production image already serves that contract (`oracly-api-00087-hut`, digest below). Phase 8C.2 replayed the two real provider responses through the corrected client parser, quality gate, artifact, and reopen with 0 new provider calls.

Leaving the flag off would ship the rollback as the product.  
The default is now `true`. Remote `false` still restores the local archive.  
`prepare()` still returns `legacyLocal` when birth evidence is not eligible. That is the fidelity fallback, not the default product.

Tests that assumed the old default now set the flag explicitly when they mean “rollback”.

## 2. Shipping feature matrix

Live entries come from `OraclyFeatureRegistry` plus `OraclyRouteGenerator`.  
Home discovery is `HomeReferenceModules`: Coffee, Palm, Astrology, Yıldızname, SoulMate, Tarot, then Dream.  
Reserved modules are not on a live or preview home band. `OraclyRoutes.achievements` and the generator default both open `OraclyAppShell`. Numerology, Moon Calendar, and Manifestation have no live route case.

| Feature | Live entry | Route / screen | Variant |
|---|---|---|---|
| Tarot | Home tile | `OraclyRoutes.tarot` → `TarotModuleNavigator` | Narrative V2 for single / three / five (`tarot_narrative_v2` default true). Seven is in the picker (`tarot_7_card` default true) and uses the quality-gated legacy interpreter. Celtic Cross and Crossroads are not in `TarotEntrySpreadChoice.offered()`. |
| Coffee | Home tile | `OraclyRoutes.coffee` → `CoffeeV2EntryGate` | Current coffee writer. `CoffeeEconomy.analysisCost == null`. |
| Palm | Home tile | `OraclyRoutes.palm` → `PalmReferenceScreen` | Current palm writer. Missing `_handSide` fails closed. `PalmEconomy.analysisCost == null`. |
| SoulMate | Home tile, premium mark | `OraclyRoutes.soulMate` → `SoulMateDrawScreen` | Premium required. `SoulMateEconomy.drawCost == null`. |
| OR | Reflect / chat | `OraclyRoutes.chat` → `CompanionReferenceScreen` | Text: Premium, or one unconsumed first-reading deepen. Voice: Premium only. |
| Dream | Home extension | `OraclyRoutes.dream` → `DreamReferenceScreen` | Frozen Dream writer. Text or voice. `DreamEconomy.analysisCost == null`. |
| Astrology | Home tile | `OraclyRoutes.astrology` → `AstrologyReferenceScreen` | Local sun-sign reading. No provider. |
| Yıldızname | Home tile | `OraclyRoutes.starMap` → `StarMapReferenceScreen` | Narrative V1 default on. Ineligible birth evidence stays on the local archive. |
| Daily Energy | Home daily ritual | Named route `dailyEnergy` opens the shell. The ritual card is the live path. | Local daily card. Not a provider reading. |
| Reading History | Remember | `ReadingHistoryScreen` | Archive of the user's own readings. |
| Discovery Journal | Remember | `DiscoveryJournalScreen` | User's own discovery records. |
| Daily Message | Explore | `DailyMessageScreen` | Local / catalogue message. `new_daily_engine` default true. |
| Personal Insights | Reflect | `PersonalInsightsScreen` | Observable history only. |
| Memory | Remember | No named route on the module. Profile / memory surface reads the same owner store. | No invented memory. |
| Premium | Account | `premiumScreenRoute` | Android monthly, yearly, lifetime. iOS monthly and yearly. No iOS lifetime. |
| Settings | Account | `SettingsReferenceScreen` | Profile, privacy, legal links. |
| Gems | Account | `GemsReferenceScreen` | Balance and ledger. `GemsRewardedAdCard` is not mounted. |
| Daily Rewards | Account | `DailyRewardsReferenceScreen` | `GemEconomy.dailyReward == 50`. |
| Favorite Moments | Result actions | `FavoriteMomentsScreen` | Explicit save. Live layout is Wrap. |
| Profile | Tab | `OraclyAppShell` profile tab | Owner-scoped name and archive. |
| Home | Shell | `OraclyAppShell` | Discovery modules above. |

## 3. Economy and access

| Feature | Free | Premium required | Base gem cost | Free wait | Paid acceleration | Rewarded ad | Store purchase | Unavailable |
|---|---|---|---|---|---|---|---|---|
| Tarot single | Yes | No | none | n/a | n/a | No | No | Interpretation failure stays an error. Local fallback is off when the proxy is configured. |
| Tarot three / five / seven | No | No | 20 (`GemEconomy.tarotReading`) | n/a | n/a | No | No | Insufficient gems blocks the paid spread. |
| Coffee | Yes | No | none | Yes, server wait | Only with a quote for this operation: cost + price token. Idempotency `coffee-v2:<id>:accelerate`. | No | No | Disabled gem label is not tappable until that quote exists. |
| Palm | Yes | No | none | Yes, server wait | Same quote rule as the shared wait screen. | No | No | Missing hand side is an error, not a result. |
| Dream | Yes | No | none | Organizing / reflection wait | No gem price | No | No | Safety or provider failure does not become a reading. |
| SoulMate | No | Yes | none | Portrait polling | No | No | Premium. Redraw re-checks Premium before clearing a saved portrait. | Inactive entitlement stays on the premium gate. |
| OR text | One matching first-reading deepen, else no | Yes for continued text | none | Send wait | No | No | Premium sheet | Lapsed Premium is re-checked before the turn. |
| OR voice | No | Yes | none | n/a | No | No | Premium | Mic does not use the free deepen. |
| Astrology | Yes | No | none | Local | No | No | No | No profile birth data does not invent a sign from a loading null. |
| Yıldızname | Yes | No | none | Narrative loading | No | No | No | Flag-off, ineligible evidence, or provider/quality failure does not paint a fake narrative. |
| Daily Energy | Yes | No | none | Local | No | No | No | Optional ritual. No streak. |

`allowsLocalFallback` is true only when the AI service is unconfigured, the environment is development, and the build is not release-locked. Production proxy configuration fails closed.

## 4. Feature certificates

### Tarot — PASS

- Entry / route: matrix above. Picker: `TarotEntrySpreadChoice.offered()`.
- Input: intention, spread, draw. Reduced motion follows the animation flag.
- Access: single free; deeper spreads 20 gems; premium not required (`TarotEconomy.requiresPremium` is false).
- Engine: `NarrativeTarotLiveGate.shouldUseNarrative` is flag-on and single/three/five only. Seven uses `TarotInterpretationService` quality gate (`AiOutputQualityTarot`) and does not enter Narrative V2.
- Failure: `_fallbackOrFail` throws when local fallback is off.
- Persistence: one save through the reading session path. History reopen does not call the provider again.
- Real evidence: G2B Narrative V2 three-card execution. `lib/features/tarot/narrative` is unchanged since G2 release head `e0638313`. Evidence remains valid.
- Tests: full Flutter suite, including tarot autosave and narrative tests.

### Coffee — PASS

- Entry: `CoffeeV2EntryGate`. Camera or gallery. Cancel keeps the prior retained image rules in the v2 flow. Hard validation rejects an unusable image before submit.
- Access: no base gem charge. Acceleration only when `canAccelerate` has a server quote, cost, and price token for the current operation.
- Engine: durable reading operation, server-owned completion, coffee parser/composer. Waiting copy is `ReadingLiveCopy`, not a bare spinner.
- Reopen: history screen opens the stored result. No new provider call.
- OR: `OracleContextMapper` coffee arm passes overall, symbols, and full interpretation.
- Owner: operation and journal records are owner-scoped with the rest of local data isolation.
- Real evidence: G2B coffee image, observe, write, parser, composer. Client request/parser files are not in the post-`e0638313` coffee diff (history screen and loading view only). Evidence remains valid.

### Palm — PASS

- Entry: hand choice, camera or gallery, image validation, trusted hand side.
- `PalmHand.fromWire` does not default a missing side to right. Analysis restore fail-closes.
- Access: no base gem charge. Acceleration uses the shared quote rule.
- Engine: observe/write, server hand metadata, parser/composer, result screen.
- OR: palm context reads the same title keys the result writes, in tr/en/ru.
- Real evidence: G2B.1 right-hand run. Post-G2 palm diff is the fail-closed hand side (stricter) plus loading view. The successful right-hand contract is unchanged. Evidence remains valid.

### Dream — PASS

- Entry: text or voice draft into the same narrative validation and submit.
- Access: no gem cost, no ad.
- Engine: frozen Dream writer, safety gate, professional result. Persistence happens before the result is shown. Close does not invent a second reading.
- OR: dream arm uses the user narrative, not a canned theme list.
- Real evidence: G2B.1 frozen writer run. Post-G2 dream diff is copy, selection, result actions, and voice draft. Writer/request files are not in that diff. Evidence remains valid.
- Backend hash tests compare frozen JSON to committed SHA-256. On this Windows checkout `core.autocrlf` expanded those files and the first vitest run failed 3 hash checks. Restoring the git blob bytes (LF) made those 3 pass. The blobs were not committed. The committed evidence is unchanged.

### SoulMate — PASS

- Entry: Home premium mark → `SoulMateDrawScreen`. Entitlement is refreshed. A saved portrait restores without a new generation.
- Submit is durable. Portrait bytes persist. Interpretation is required before OR/continuation. Redraw checks Premium before clearing the saved result.
- Access: Premium store purchase. No gem price. No ad.
- Real evidence: G2B-SM Play license monthly purchase, billing verify 200 / `subscription_active`, restart, real portrait, real interpretation, decode/render, reopen with 0 new provider executions. This phase did not purchase again. Billing store IDs were not changed here. Evidence remains valid.

### OR — PASS

- Fresh entry clears a stale handoff through the session resolver.
- `CompanionOrConversationAccess`: Premium, or one matching unconsumed first-reading deepen for text. Voice calls `ensurePremiumFresh`. A lapsed badge is not trusted.
- Engine: base request, q2 quality regeneration, distinct idempotency, persistence, retry, regenerate.
- Real evidence: G2B base and q2 runs. `oracle_context_mapper.dart` changed formatting plus palm title-locale parsing. The OR request fields for tarot, dream, astrology, coffee, and yıldızname are the same. Evidence remains valid.

### Astrology — PASS

- Local sun-sign reading from saved birth data. No AI provider call.
- The hub does not treat a still-loading profile as “no sign” in the yıldızname sense; astrology uses the resolved sign and does not open a second route.
- Personalization uses real stored data only.

### Yıldızname — PASS

- Effective flag: `true`.
- Source: `ProductFeatureFlags.yildiznameNarrativeV1.defaultValue`, copied by `RemoteConfigDefaults`, read by `YildiznameNarrativeLiveGate`.
- Remote override: yes. An accepted remote `false` restores the local archive.
- Brand-new user with eligible birth evidence: Narrative V1 host (`StarMapNarrativeLiveScreen`).
- Ineligible evidence: `legacyLocal` plan, local archive, provider calls 0.
- Path: birth evidence → eligibility → prepared request → live provider → loading → quality/grounding → artifact → history → reopen → OR birth-chart context → owner snapshot on the prepared transaction.
- Real evidence: Phase 8C responses, client-aligned in 8C.2 and replayed offline. Backend image unchanged (section 9). No new provider call in P4F.

### Daily Energy, history, journal, message, insights, memory, premium, settings, gems, rewards, favorites, profile, home — PASS

- Each opens the screen in the matrix.
- Daily Energy is the home ritual, not the unused named route.
- Gems ad card is not in the gems screen tree.
- Favorites persist per owner. Live control is Wrap.
- Premium and settings do not grant another user's data.
- Reserved Achievements, Numerology, Moon Calendar, and Manifestation are not reachable as products.

## 5. Real-evidence provenance

Production read on 2026-09-29 (no traffic change):

- `gcloud run services describe oracly-api --region=europe-west1`: only `oracly-api-00087-hut` has `percent: 100`.
- Revision image: `europe-west1-docker.pkg.dev/oracly-7f613/oracly/oracly-api@sha256:e35475982cea3cc8a527df1cc81a812f5621bff752966fe39b19d676eefc4cfc`.
- Condition status True.
- `GET /health` → 200 `{"status":"ok"}`.
- `GET /ready` → 200, required capabilities true (auth, App Check, text, vision, image generation, reading staging, reading durability, Google billing, Apple billing).
- `git diff --name-only e0638313 HEAD -- backend/src` is empty.

| Evidence | Backend image | Flutter contract since `e0638313` | Valid |
|---|---|---|---|
| Coffee G2B | same digest | request/parser unchanged | YES |
| Palm G2B.1 | same digest | success path unchanged; missing hand now fails closed | YES |
| Dream G2B.1 | same digest | writer unchanged | YES |
| Tarot Narrative V2 | same digest | `lib/features/tarot/narrative` unchanged | YES |
| OR G2B base + q2 | same digest | request fields unchanged; palm handoff parsing tightened | YES |
| SoulMate G2B-SM purchase + portrait | same digest | store IDs unchanged; no second purchase | YES |

`oracly-api-00052-zqd` is not in the current traffic list. It is not receiving traffic. Rollback was not executed in this phase.

## 6. Persistence and reopen

| Feature | Fresh completion | Restart / reopen | New provider call |
|---|---|---|---|
| Tarot | Session save once | History opens the stored reading | No |
| Coffee | Server-owned operation + journal | History screen | No |
| Palm | Server-owned operation + hand side | Reopen keeps the stored hand | No |
| Dream | Saved before result | Journal reopen | No |
| SoulMate | Portrait bytes + interpretation | Restore, 0 generations | No |
| Yıldızname | Artifact after quality pass | Same id and hash | No |

Missing archived media does not replace stored prose with a success invention. History, journal, favorites, memory, and insights read the signed-in owner's store.

## 7. Owner isolation

`UserLocalDataIsolation` wipes local private data before the new owner id is committed. Incomplete wipe does not advance the epoch. Profile rename and economy mutations stay on the owner gate from P4D.2 / P4E. Yıldızname prepare captures the owner snapshot once and does not recapture it mid-flight. Verdict: PASS. Covered by `user_data_isolation_test`, P4C.1, P4D.2, P4E owner-switch, and Phase 8 owner tests inside the full Flutter suite.

## 8. Result quality

| Feature | Transport | Quality gate |
|---|---|---|
| Tarot Narrative V2 | Proxy complete | Narrative validator, formatter, reflective guard. Quality failure does not return success when fallback is off. |
| Tarot seven | Legacy interpreter | `AiOutputQualityTarot` then fail closed. |
| Coffee | Server-owned completion | Coffee writer/composer. |
| Palm | Server-owned completion | Palm writer/composer plus hand side. |
| Dream | Frozen writer | Safety acceptance. |
| SoulMate | Image generation + interpretation | Portrait decode and interpretation sections. |
| OR | Base complete | q2 regeneration, distinct idempotency. |
| Yıldızname | Narrative V1 complete | Grounding validator. Rejection is a failure, not a local essay. |

HTTP 200 is not acceptance. The Phase 8C responses were HTTP 200 and were rejected until the client contract matched; the offline replay after that fix is the acceptance record.

## 9. Wrong-feature firewall

| Case | Result |
|---|---|
| Coffee / Palm / SoulMate route | Distinct route cases. None build `TarotModuleNavigator`. |
| Yıldızname route | `StarMapReferenceScreen`, not astrology. |
| Operation id | Completion is bound to the operation. A foreign id is not a result. |
| Coffee result used as Palm, or the reverse | Separate parsers and contexts. |
| Completed operation missing required metadata | Palm missing hand side fails closed. Narrative schema rejection fails closed. |
| Provider or quality failure shown as success | Production `allowsLocalFallback` is false. Yıldızname caches approved results only. |
| Expired Premium | OR and SoulMate re-check entitlement. |
| Owner A result visible to owner B | Isolation wipe plus owner snapshot. |
| Retry duplicates a charge or a reading | Acceleration idempotency key. Narrative single-flight `_busy`. Tarot save once. |
| Result screen with no authoritative body | Empty cards throw. Narrative host shows the error state when prepare fails. |

Verdict: PASS.

## 10. Loading, error, retry

Coffee and Palm use `ReadingWaitCountdownClock` during the free wait, processing copy while the server is in progress, and overdue copy after the window. The accelerate control is disabled without a quote. Back does not complete the operation locally. Provider errors shown to the user go through resilience copy, not raw provider bodies. 320-width and large-text favorite/target tests are in the Flutter suite (P4C Wrap and P4E.4 contract).

## 11. Device evidence

G2C physical TECNO pass covered Home, OR, Coffee, Palm, Astrology, Yıldızname, Tarot, Dream, Premium, saved SoulMate, Profile, Settings, Android back, camera intent, photo picker, share, deep link, microphone, and background/resume, with no Flutter crash.

Post-G2C navigation structure is the same route table. Coffee and Palm camera/gallery entry screens were not replaced. SoulMate still decodes a stored portrait. Tarot, Dream mic, OR, Profile, and Settings routes are the same screens. The live favorite control remains Wrap.

Invalidated seam: Yıldızname primary leaf. G2C observed the flag-off local archive. Shipping is now Narrative V1. That seam is covered by `phase8b_primary_route_test`, `phase8b1_primary_failure_route_test`, and the narrative suite inside the full Flutter run. No new physical-device pass was required.

## 12. Final test evidence

Candidate tree (this commit's code, before the markdown file):

- `flutter test`: 6391 passed, 16 skipped, 0 failed. Completed.
- `flutter analyze --no-fatal-infos`: 0 errors, 0 warnings, 212 infos.
- Backend `vitest run`: 1661 passed, 1 skipped, 0 failed after the frozen JSON was read as the git blob. First Windows checkout run failed 3 hash checks on CRLF expansion only.
- Backend `tsc -p tsconfig.json --noEmit`: exit 0.

Skips are the existing `ORACLY_E2E=1`, release-manifest, and shadow-corpus gates.

## 13. Release artifact

Built from the final commit of this phase. Not uploaded.

Recorded in the commit message trail only after the build. See the P4F report for versionName, versionCode, signing, `debuggable`, and certificate. The previous AAB `1.0.0+26092907` from G2C is not this commit's artifact.

## 14. External tasks after product readiness

- iOS archive and signing
- iOS sandbox purchase and restore
- VoiceOver
- A fresh FCM delivery proof
- Background during an active provider wait
- TalkBack human pass

These are platform checks. They are not open product blockers.

## 15. Product Owner statements

- Coffee: YES
- Palm: YES
- Tarot: YES
- Dream: YES
- SoulMate: YES
- OR: YES
- Astrology: YES
- Yıldızname: YES
