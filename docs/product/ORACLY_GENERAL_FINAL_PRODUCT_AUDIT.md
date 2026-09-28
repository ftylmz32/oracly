# ORACLY — General Final Product Audit

Phase **G0 — Product truth + shared core / cross-feature infrastructure**
Branch `fix/final-product-remediation-20260922` · Date 2026-09-28

Evidence comes from repo code and tests only. No provider, OpenAI, Cloud Run, Firebase, Play Console or App Store Connect call was made. Nothing was deployed or uploaded. Anything that needs a store, cloud or physical device is marked external or manual, never green.

---

## 1. CURRENT PRODUCT TRUTH — HEAD e71f937601e7a5aa84b1648b7310086a0932f39b

The audited base is `e71f9376`. The G0 commit that adds this document changes only the shared defects listed in §4, and no product surface.

Source of truth: `OraclyFeatureRegistry` (`lib/core/modules/oracly_feature_registry.dart`), pinned by `test/general_audit/general_route_matrix_test.dart`.

| Status | Count | Features |
|---|---|---|
| **LIVE** | 16 | Tarot · Coffee · Palm · SoulMate (Premium) · OR (`aiChat`) · Daily Energy (Home ritual) · Dream · Astrology · Yıldızname (`starMap`) · Reading History · Discovery Journal · Daily Message · Personal Insights · Memory · Premium · Settings |
| **RESERVED** | 4 | Achievements · Numerology · Moon Calendar · Manifestation |
| **PREVIEW** | 0 | — |
| **INTERNAL / DEBUG** | — | `PremiumDevOverride`, `SoulMateDevAccess`: these need debug **and** development **and** the flag, so release can never enable them. Dev/debug `.env.example` is loaded only when `!kReleaseMode`. |

`home` and `profile` are shell tabs, not modules. Reserved modules have `canOpen == false`, no Home band or Universe realm, and no notification. The legacy reserved widgets (`AchievementsScreen`, `ProfileMenuSection`, `ProfileReferenceAchievementsSection`) are never instantiated from live code; a source-scan test pins this.

Frozen features: **Dream** (final frozen; writer `gpt-6-astra` / reasoning `medium` / revision `4c3-astra`), **Tarot** and **Yıldızname**. G0 changed none of their code, prompts or models.

---

## 2. Route matrix

Every route goes through the gate first. If the account-deletion gate is unresolved → `DeferredGateRouteHost` (it replays the same settings once the gate settles). If deletion is pending → the gate screen. Next, `ShareLinkParser`: a valid `oracly://share/<token>` → `ShareReopenScreen`. Only then does the switch below run.

Cold launch always starts at Splash (`initialRoute: '/'`, `home: SplashScreen`). `main.dart` captures the platform `defaultRouteName` into `ShareLinkInbox`, and Splash replays it only after the gate resolves. Warm links go through `ShareLinkHost` (§4 G0-D1). The only supported external deep link is the share link; every other external path is ignored while warm, and recovers to the shell when cold.

| Route | Feature | Live / reserved | Destination | Gate | Root vs nested | Deep-link | Fallback |
|---|---|---|---|---|---|---|---|
| `/` | Splash | live | `SplashScreen` | deletion gate | root | cold entry | — |
| `/onboarding` | Onboarding | live | `OnboardingScreen` | deletion gate | root | no | — |
| `/home` | Home tab | shell | `OraclyAppShell` | — | root; in-app uses `switchToTab` | no | the live shell |
| `/profile` | Profile tab | shell | `OraclyAppShell(initialTab: profile)` | — | root; in-app uses `switchToTab` | no | the live shell |
| `/tarot` | Tarot | live (frozen) | `TarotModuleNavigator` | — | tab stack | no | — |
| `/coffee` | Coffee | live | `CoffeeV2EntryGate(operationId)` | — | tab stack | no | invalid id → fresh entry |
| `/palm` | Palm | live | `PalmReferenceScreen(operationId)` | — | tab stack | no | invalid id → fresh entry |
| `/soul-mate` | SoulMate | live | `SoulMateDrawScreen(operationId)` | Premium, self-gated (locked preview) | tab stack | no | invalid id → fresh entry |
| `/dream` | Dream | live (frozen, free) | `DreamReferenceScreen` | — | tab stack | no | — |
| `/chat` | OR | live | `CompanionReferenceScreen` | full text + voice = Premium (in chamber) | **root** | cold shortcut via Splash only | fresh entry clears handoff |
| `/astrology` | Astrology | live | `AstrologyReferenceScreen` | — | tab stack | no | — |
| `/star-map` | Yıldızname | live (frozen) | `StarMapReferenceScreen` | — | tab stack | no | — |
| `/premium` | Premium | live | `premiumScreenRoute` | — | tab stack | no | honest unavailable + retry |
| `/gems`, `/daily-rewards` | Gems | live | reference screens | — | tab stack | no | — |
| `/reading-history`, `/discovery-journal`, `/my-story`, `/favorite-moments`, `/personal-insights`, `/daily-message` | Journey | live | canonical screens | — | tab stack | no | empty state |
| `/settings`, `/about`, `/help`, `/privacy` | Settings | live | canonical screens | — | tab stack | no | — |
| `/daily-energy` | Daily Energy | live, via Home ritual | `OraclyAppShell` | — | root | no | the live shell |
| `/achievements` | Achievements | **reserved** | `OraclyAppShell` | — | root | no | the live shell |
| `/numerology`, `/moon-calendar`, `/manifestation` | reserved | **reserved** | default → `OraclyAppShell` | — | root | no | the live shell |
| `/share` + unknown / malformed (`null`, `''`, `%%%`, 4096 chars) | — | — | `OraclyAppShell` | — | root | no | the live shell, never a throw |

**Unknown-route recovery.** When a name is pushed onto the root navigator, it builds the shell. The G0 fix makes sure no warm platform link can reach that path while a shell already exists.

**Reading operation ids.** `_readingOperationId` accepts only a `Map` with a `String` `operationId` that matches `^[a-f0-9]{32}$` after trimming; anything else is `null`, which gives a fresh entry. Coffee and Palm recovery also reject a snapshot whose `readingType` belongs to the other feature (existing test: "Coffee exact recovery rejects a Palm operation id").

---

## 3. Section verdicts

| # | Area | Verdict | Evidence |
|---|---|---|---|
| 1 | Home / shell (P1-HOME-SHELL) | **CLOSED** | Every in-app Home, Profile, Explore, Daily Energy and Achievements helper switches the live tab ×5. No push, one shell, root `canPop == false`, and back isn't swallowed. Warm share ×3 and warm malformed links: one shell (`general_shell_navigation_test`, `general_warm_link_app_test`). |
| 2 | Feature entry routing | **PASS** | Coffee, Palm, Dream and SoulMate never open Tarot; Yıldızname never opens Astrology (`general_route_matrix_test`). OR fresh entry clears the handoff buffer and the companion reading context (`or_fresh_entry_clears_handoff_test`). |
| 3 | Reading operation ids | **PASS** | §2, plus route-matrix tests for accept / reject across Coffee, Palm and SoulMate. |
| 4 | Account-deletion gate | **PASS** | Gate first in both `onGenerateRoute` and `onUnknownRoute`; Splash is the forced cold entry (`account_deletion_deep_link_gate_test`, `light_mode_release_gate_test`). |
| 5 | Share / deep link | **FIXED (G0-D1)** | Warm share links now open the share screen. Malformed or unsupported links stay put and push nothing. Public payload carries no reading body (`test/features/share_reopen`). |
| 6 | Premium gate truth | **PASS** | Only SoulMate is navigation-gated. OR full text + voice gate in chamber. Tarot, Coffee, Palm, Dream, Astrology, Yıldızname, Daily and Journal are free (`general_premium_gate_matrix_test`). |
| 7 | Platform plans | **PASS + docs fixed** | iOS queries and shows monthly + yearly only, and lifetime normalizes to yearly. Android keeps lifetime. Stale docs that told iOS to create lifetime are corrected. |
| 8 | Premium access authority | **PASS** | `isPremium = entitlement.allowsPremiumFeatures ‖ reviewAccessActive`. `ensureFresh` requires `ownerAccessReady`, and any exception → false. |
| 9 | Premium navigation red team | **PASS** | SoulMate direct route: **BLOCKED**, because the screen gates itself; saved portraits stay readable. OR bypass: **BLOCKED**, because compose uses `ensureFresh` and voice uses `isPremium`. |
| 10 | Store config honesty (fakes) | **PASS** | Prices come from the store only; empty catalog → honest unavailable; restore timeout never grants (`premium_store_commerce`, `premium_restore_resilience`, `premium_restore_timeout_honesty`, `premium_purchase_honesty_p0`, `premium_entitlement_sync_r3/_r31`, `http_billing_entitlement_verifier`). |
| 11 | Gems ↔ Premium isolation | **PASS** | Premium and review-access code never touch gems; gems reference Premium only to hide the rewarded ad. `DreamEconomy.analysisCost == null`, and billable non-Tarot operations throw `UnsupportedError`. |
| 12 | `OraclyErrorState` retry | **FIXED (G0-D2)** | 43 → 44 px; announced twice → once. |
| 13 | Error state matrix | **PASS** | Shared error state at 390 px width, text scale 1 and 2 without overflow, one labelled button, iOS and labelled tap-target guidelines (`general_error_state_accessibility_test`, 19 tests). Premium uses its own states. |
| 14 | Error sanitization | **FIXED (G0-D4)** | `AiErrorSanitizer` now hides bearer / JWT / API-key / authorization, JSON parse, unexpected token, `*Exception`, Cloud Run and `run.app`. |
| 15 | Release runtime config | **FIXED (G0-D3)** | A locked release accepts only an `https` dotted DNS host. Localhost, LAN, `10.0.2.2`, `http`, `REPLACE_*` and `<REQUIRED_REAL_HOST>` all resolve to unconfigured. A release with no defines is unconfigured. |
| 16 | Flutter `ORACLY_AI_MODEL` ≠ Dream writer | **DOCUMENTED** | `docs/RELEASE_RUNTIME_CONFIG.md`: the generic Flutter model hint is unchanged; the Dream writer is bound server-side (`backend/src/ai/dream-writer-model.ts`) and fails closed. |
| 17 | Reserved feature leakage | **PASS** | No band, realm, notification or navigation; opening a reserved module pushes nothing (`general_reserved_feature_test`). |
| 18 | Journal cross-feature reopen | **PASS** | Journal and favorites openers dispatch by kind; a missing source gives a calm `sourceUnavailable`, never a Tarot fallback (`discovery_journal_opener_test`). |
| 19 | History / clear isolation | **PASS** | The Dream clear, favorites clear and memory reset touch only their own data; the discovery clear keeps SoulMate, Premium, review access and gems (`general_privacy_clear_isolation_test`). |
| 20 | Owner switch A/B baseline | **PASS** | `UserLocalDataWipe` removes every owner-A key family and keeps `settings_*` (`general_owner_isolation_smoke_test`). |
| 21 | Cold start | **PASS** | Splash-forced entry, route recovery, gem wallet hydration, Premium restart credential race (`cold_start_route_recovery_test`, `gem_wallet_cold_start_hydration_test`, `premium_restart_credential_race_test`). |
| 22 | Navigation stack red team | **FIXED (G0-D5)** | Home → Dream / Coffee / Palm / OR / Premium → back each time; Profile → Settings → back → Profile → back → Home; ×3 repeated taps never stack a duplicate; OR (root) pushes once (`general_navigation_stack_test`). |
| 23 | Analytics / crash privacy | **PASS** | `ProductAnalyticsParams` allowlists keys and blocks `*id`, token, text, narrative and note keys, as well as sentence-like values. Crash context holds only a fixed feature/stage. Service APIs take enums, durations and length buckets only (`analytics_integrity_p4_test`, `general_error_sanitization_test`). |

---

## 4. Shared defects found and fixed in G0

Each fix went red → narrow fix → green.

| ID | Defect | Fix |
|---|---|---|
| **G0-D1** | A warm deep link while the app runs: `WidgetsApp` registered its route observer before `ShareLinkHost`, so the platform URI became a raw `pushNamed(uri.path)`. `/share/<token>` then hit the unknown-name fallback and stacked a **second `OraclyAppShell`**, and the share never opened. Warm `/chat` also bypassed OR's handoff clearing. | `ShareLinkHost` now wraps `MaterialApp`, so it registers first. It owns every warm link: a share goes to the inbox → `ShareLinkOpener` (or the gate/Splash drain); anything else is consumed and nothing is pushed. |
| **G0-D2** | `OraclyErrorState` Retry was 43 px tall (below 44), and its label was announced twice: the wrapper label plus `PremiumButton`'s own text. | A 44×44 `ConstrainedBox`. The labelled `Semantics(button: true)` wrapper stays, which is the contract frozen Yıldızname tests pin, and now uses `excludeSemantics` + `onTap`, so there's one node with a working screen-reader activation. `PremiumButton` is untouched. |
| **G0-D3** | The release endpoint policy accepted the documented template `https://<REQUIRED_REAL_HOST>/…`, because `Uri.parse` percent-encodes it instead of throwing. | A locked build requires a dotted public DNS host. |
| **G0-D4** | `AiErrorSanitizer` let bearer / JWT, JSON parse, unexpected token, Cloud Run / `run.app`, "API key" and `FormatException` text reach users. | Narrow regex additions only. |
| **G0-D5** | Android system back from any chamber pushed on a tab stack (Dream, Coffee, Palm, Premium, Settings, …) **exited the app**. The shell's `PopScope.canPop` was computed only at build time, and nested tab pushes don't rebuild the shell. So `handlePopRoute` returned `false` and called `SystemNavigator.pop`. | The shell listens to `NavigationNotification` from its tab navigators and rebuilds only when root-pop permission changes. This is the same mechanism Flutter's `NavigatorPopHandler` uses. |

Docs: `PREMIUM_STORE_SETUP.md`, `PREMIUM_MASTER_CHECKPOINT.md` and `RELEASE_LEDGER.md` now say lifetime is Android-only. `RELEASE_RUNTIME_CONFIG.md` separates the Flutter model hint from the Dream writer.

---

## 5. Stale blocker reconciliation

Sources: `docs/project_execution/FINAL_RELEASE_MASTER_CHECKPOINT.md`, `RELEASE_BLOCKERS.md` and `PREMIUM_MASTER_CHECKPOINT.md`, all dated 2026-08-25. `docs/RELEASE_LEDGER.md` is historical.

| Old ID | Old claim | Current verdict | Current evidence | Action |
|---|---|---|---|---|
| P0-TEST | 12 failing assertions | **CLOSED** | Full Flutter green in this pass (§6) | none |
| P1-HOME-SHELL | `/home` can nest a second shell | **CLOSED** | In-app helpers switch tabs; warm links can no longer raw-push (G0-D1); cold links go through Splash | none |
| P1-JOURNAL-DELETE | Journal lacks in-journal delete | **OPEN-CODE** (non-blocking) | Tarot entries can be deleted from Reading History detail. Other kinds are deletable per feature in the Privacy center and by account wipe, so deletion is never blocked. There's no per-entry delete for Coffee, Palm, Dream or SoulMate. | Decide in G1 per-feature seams |
| P1-FEATURE-MASTERS | Feature masters NOT COMPLETE | **SUPERSEDED** | Dream final frozen; Tarot and Yıldızname frozen; the rest belong to the G1 live-feature seam audit | G1 |
| P1-DEVICE-MATRIX | TECNO matrix incomplete | **OPEN-MANUAL** | Needs a physical device on the current build | Device pass |
| P2-ANALYZE-INFOS | ~93 infos/warnings | **CLOSED** (warnings) | `flutter analyze`: 0 errors / 0 warnings; infos reported in §6 | none |
| P2-FIREBASE-BOOT | Firebase awaited before first frame | **OBSOLETE** | `main.dart` calls `runApp` first; Firebase Auth and App Check start in `_deferredStartup` | none |
| P2-A11Y | Accessibility matrix partial | **OPEN-MANUAL** | The shared error state is now pinned (G0-D2). A screen reader and dynamic type on devices are still manual. | Device pass |
| EXT-PLAY | Play products not loading on device | **OPEN-EXTERNAL** | Done in Play Console (historical-complete): Internal testing, Data Safety, Ads = No, App Access, Content Rating, Target Audience 18+. Still needed: products available to the test account plus a verified license-test purchase and restore. | Store |
| EXT-PROXY | Production AI proxy not configured | **OPEN-EXTERNAL** | The local production defines hold an `https` dotted, non-placeholder host. Live `/health`, `/ready` and the Dream writer deploy (`DREAM_PHASE4C3_PRODUCTION_BINDING.md`: "not deployed") were not verified, because G0 makes no network calls. | Deploy + health check |
| EXT-SIGNING | `android/key.properties` missing | **CLOSED** (local) | Present locally and gitignored; not read | none |
| EXT-DEFINES | Production defines missing | **CLOSED** (local) | `tool/dart_defines.production.json` is present and gitignored. All URL keys are `https`, dotted, non-local and non-placeholder (checked as booleans only; values not printed). | none |
| EXT-LEGAL-URL | Privacy / Terms URLs not set | **OPEN-EXTERNAL** | Privacy, terms and data-deletion URL defines are set (`https`, dotted). That the hosted pages are live and final is unverified. | Legal + URL check |
| MANUAL-SCREENSHOTS / PERMISSIONS / UPGRADE / VOICE-E2E | Manual checks | **OPEN-MANUAL** | Needs devices and a store build | Device pass |
| PREMIUM 27 / 29 | Real store purchase not run | **OPEN-EXTERNAL** | Code and fakes are green (§3 #10) | Store |

---

## 6. Verification

| Suite | Result |
|---|---|
| G0 (`test/general_audit/`, 11 files) | 58 passed |
| G0 + targeted shared (navigation, shell, share, deletion gate, light-mode gate, premium, gems, privacy, journal, config, analytics, cold start, OR handoff, review access) | 602 passed |
| Premium (`test/features/premium` + purchase honesty) | 291 passed |
| Dream | 493 passed · 2 skipped |
| Tarot | 1457 passed · 1 skipped |
| Yıldızname | 871 passed |
| Full Flutter | 6200 passed · 16 skipped · 0 failed |
| Full backend (`vitest`) | 1652 passed · 1 skipped · 0 failed |
| `flutter analyze` | 0 errors · 0 warnings · 218 infos |
| Backend `tsc --noEmit` | pass |

One backend run failed a single timing-sensitive Tarot test (`narrative-tarot-6d1-fingerprint`, a 429 duplicate window) while it ran concurrently with the full Flutter suite. G0 changed no backend code; the file passes 5/5 alone, and the full rerun above is green.

## 7. Known limitations

- `lib/shared/navigation/oracly_navigation.dart` exceeds 150 lines. It was already over the limit before G0 (175 lines); the fix brings it to 188. A split is left for a dedicated shell refactor so the defect fix stays narrow.
- Three G0 test files (route matrix, shell navigation, premium matrix) run 162–175 lines. That follows the existing test convention (341 of 1023 test files exceed 150); all production files touched in G0 other than the shell stay within 150.
- The legacy reserved widgets remain as unreachable dead code, pinned by a source scan.
- Per-entry journal delete for non-Tarot kinds (P1-JOURNAL-DELETE) was deferred to G1; G1 decides it in §9.8.

## 8. External actions and post-deploy / device checks

- **Play:** product availability plus a license-test purchase, restore and restart on a device.
- **App Store:** monthly + yearly products only, then a sandbox purchase and restore.
- **Backend:** deploy the Dream writer binding; verify `/health`, `/ready` and a fail-closed Dream request.
- **Legal:** confirm the hosted privacy, terms and data-deletion pages.
- **Device:** Android system back from each chamber (G0-D5), and warm share links from a messenger while the app runs (G0-D1). Also a TalkBack / VoiceOver pass and the TECNO matrix.

---

## 9. G1 — LIVE FEATURE PRODUCT SEAMS

Base `1fcd3da17dc512f74d8fd12615dfcd5886341680` (G0, frozen). Scope: Coffee, Palm, SoulMate, OR and Astrology, from entry to completion, failure, retry, reopen and account switch, plus their seams with Premium, Gems, the Discovery Journal, saved results, Reading Operations, navigation and privacy.

Evidence comes from code and tests with fakes only: an in-memory reading backend, a transport that drops calls the way a dead network does, synthetic images, synthetic entitlements and local storage. There were no provider, OpenAI or image-generation calls, no store transactions and no deploys, and no AI prompt or model changed. Dream, Tarot and Yıldızname internals were not touched, and their suites are run as frozen regressions.

G1 tests live in `test/general_audit/g1/`. Every defect below went failing regression → narrow fix → green, and each regression was also run against the `HEAD` version of the production files to confirm it fails there.

### 9.1 Defects found and fixed

| ID | Feature | Defect (what the user saw) | Fix | Regression |
|---|---|---|---|---|
| **G1-D1** | Coffee (legacy + V2), Palm, SoulMate | A dropped network call, a 429 or a 5xx while waiting was read as "no operation". Coffee and Palm stopped polling and left the user on a spinner nothing would ever update; SoulMate stopped polling while still showing "drawing", and an exact (deep-linked) SoulMate showed "unavailable". | `ReadingLiveState.unreachable` separates "the server couldn't answer" from "the operation is gone". Every observer keeps polling on it. | `g1_coffee_entry_recovery_test`, `g1_palm_entry_recovery_test`, `g1_soulmate_durable_recovery_test` |
| **G1-D2** | Coffee (legacy + V2), Palm | A ready operation whose result couldn't be fetched yet, or whose payload failed to parse, froze the wait. | The fetch is retried on the next poll. After 10 misses, Coffee V2 shows its failure state with a working Retry. A Palm payload that can't be read becomes an honest error. | same files, plus `g1_coffee_v2_recovery_test` |
| **G1-D3** | Coffee legacy, Palm | Exact recovery of an operation that no longer exists, or that belongs to the other feature, left an unrelated saved reading on screen. | A missing or foreign target settles back to a fresh entry, or keeps observing if an analysis is already running. | `g1_coffee_entry_recovery_test`, `g1_palm_entry_recovery_test` |
| **G1-D4** | Coffee V2 | A failed reading whose photos had been released reopened as an endless "preparing" spinner. A restored result the user had deleted was fetched back from the server. | The terminal failure is handed off as a failure. The deleted-result branch acknowledges the operation instead of re-fetching it. | `g1_coffee_v2_recovery_test` |
| **G1-D5** | Palm | A poll that was already scheduled when the user left the wait could pull them back into it. | The poll carries the controller generation and drops itself if the user has moved on. | `g1_palm_entry_recovery_test` |
| **G1-D6** | Coffee (legacy + V2), Palm | The speed-up button was active before any price had been quoted for the current operation, so a tap could charge an amount the user never saw. | `canAccelerate` and the shown cost require a server quote for the current operation. The Gem cost stays server-quoted only; nothing is hardcoded. | `g1_coffee_acceleration_test`, `g1_palm_acceleration_test`, `acceleration_controller_wiring_test` |
| **G1-D7** | Coffee (legacy + V2), Palm | A finished reading never refreshed the Discovery Journal. The listener compared the previous and next values of one `ChangeNotifier`, which are the same instance, so it never fired. | Each screen remembers the last reading id it refreshed for and refreshes when a new one is shown. | `g1_coffee_journal_test`, `g1_palm_journal_test` |
| **G1-D8** | Coffee legacy, Palm | "Reinterpret" was offered in production, but production completes readings on the server and the button called a client analysis path that always fails. That's a dead affordance. | `canReinterpret` hides the action when completion is server-owned. | `g1_coffee_journal_test`, `g1_palm_journal_test` |
| **G1-D9** | SoulMate | After Premium lapsed, a saved portrait's "retry interpretation" still generated a new paid interpretation. | The repair re-checks Premium with `allowsFresh`. The saved portrait stays readable. | `g1_soulmate_entitlement_test` |
| **G1-D10** | SoulMate | Two taps during a slow Premium check submitted two draws. | The draw lock is taken before the entitlement await. | `g1_soulmate_entitlement_test` |
| **G1-D11** | SoulMate | After opening a deep-linked result and tapping Redraw, polling kept watching the old operation and showed the old portrait again. | A new submission stops observing the deep-link target. | `g1_soulmate_durable_recovery_test` |
| **G1-D12** | SoulMate | Repairing the interpretation of a restored portrait created a second Journal row, and the Retry button stayed on screen after the two allowed attempts were spent. | The restored result carries its saved id, so the repair updates the same row; Retry is hidden once no attempt remains. | `g1_soulmate_entitlement_test`, `soul_mate_release_gate_test` #18 |
| **G1-D13** | OR | The free first-reading deepen wasn't spent when the reading context was cleared during the reply, or when the reply showed but saving it locally failed. Either way the user got a second free turn. | The deepen is spent against the context the question was asked under, as soon as a usable reply is on screen. | `g1_or_access_test` |
| **G1-D14** | OR | A quality re-generation reused the turn's idempotency key. The server's 10-minute replay cache would return the very reply the quality gate had just rejected, so the retry was wasted and ended in "unavailable". | Each re-generation runs under its own key derived from the turn key. A user retry of the same failed turn still reuses the turn key. | `g1_or_retry_persistence_test` |
| **G1-D15** | OR | Text compose trusted a cached Premium flag. OR text is not billed on the server, so after a mid-session lapse the chat kept answering until something else refreshed entitlement. | A text send re-checks Premium (`ensureFresh`) before a paid turn; the one free first-reading deepen still works. Voice already re-checked. | `g1_or_premium_lapse_test` |
| **G1-D16** | Cross-feature | On account switch the reading sender stayed bound to owner A. It fails closed for anyone else, so owner B's Coffee, Palm, SoulMate and wallet calls all looked like a dead network. OR also kept A's reading handoff, and a reply still in flight could land in B's chamber. | `afterAccountSwitch` rebuilds the sender (and with it every reading controller and the wallet) and calls `CompanionController.resetForAccountSwitch`. **Hardened in Audit.1 (§9.12):** the reset also clears the process-wide `OrChatHandoffBuffer`, and an OR reply that returns after the owner changed is never written to local storage. | `g1_owner_switch_cross_feature_test`, `g1_or_handoff_test`, `g1_or_account_switch_persistence_test`, `g1_or_account_switch_journey_test` |
| **G1-D17** | Astrology | Any finished reading refreshes the shared profile, which replaced the whole Astrology hub with the loading view. | A background refresh keeps showing the profile already known. The first load and a profile failure behave as before. | `g1_astrology_flow_test` |

G1 also tried to make "Clear discovery history" remove Coffee, Palm and Tarot reinterpret version chains. The frozen Dream suite pins the opposite contract (`dream_phase1_clear_durability_test` and `dream_phase1_privacy_clear_test` expect those chains to survive a Discovery clear), so the change was reverted. It's recorded in §9.9 instead.

### 9.2 Coffee

| Seam | Verdict | Evidence |
|---|---|---|
| Journey | Entry goes through `CoffeeV2EntryGate`; the legacy controller is still used for saved readings and recovery. Capture → wait → server processing → ready or failed, all polled from the server. | `test/features/coffee` |
| Economy | The base reading is free: `CoffeeEconomy.analysisCost == null`. The optional speed-up is a server-quoted Gem price, shown only after a quote for the current operation (G1-D6). A double tap charges once (`acceleration_controller_wiring_test`). | `g1_coffee_acceleration_test` |
| Entitlement | Not Premium-gated. | G0 `general_premium_gate_matrix_test` |
| Persistence | Server-owned completion → local store → Journal refresh (G1-D7). | `g1_coffee_journal_test` |
| Recovery | Exact recovery by operation id, cold recovery through `/active`, a wrong-type (Palm) id rejected, outages and unfetched results retried (G1-D1–D4). | `g1_coffee_entry_recovery_test`, `g1_coffee_v2_recovery_test` |
| Journal | Reopen by id; a missing source shows calm "unavailable" and pushes nothing. | `discovery_journal_opener_test` |
| Owner isolation | Wiped on account switch; the rebuilt sender binds to the new owner (G1-D16). | `g1_owner_switch_cross_feature_test`, G0 `general_owner_isolation_smoke_test` |
| OR handoff | "Ask OR" passes a typed Coffee context; OR fresh entry clears it. | `or_typed_handoff_ask_oracle_test`, G0 `or_fresh_entry_clears_handoff_test` |
| Reinterpret | Not reachable in production, and hidden there (G1-D8). | `g1_coffee_journal_test` |

### 9.3 Palm

| Seam | Verdict | Evidence |
|---|---|---|
| Journey | Choose a hand → photo intake → wait → processing → ready or failed. The chosen hand survives recovery. | `test/features/palm`, `g1_palm_entry_recovery_test` |
| Economy | The base reading is free: `PalmEconomy.analysisCost == null`. The speed-up is server-quoted and shown only after a quote (G1-D6). | `g1_palm_acceleration_test` |
| Entitlement | Not Premium-gated. | G0 `general_premium_gate_matrix_test` |
| Persistence and Journal | Saved on completion; the Journal refreshes (G1-D7); a missing source shows "unavailable". | `g1_palm_journal_test`, `discovery_journal_opener_test` |
| Recovery | Exact, cold and wrong-type (Coffee) handling; outages and unfetched results retried; leaving the wait is respected (G1-D1–D5). | `g1_palm_entry_recovery_test` |
| Owner isolation | Same as Coffee (G1-D16). | `g1_owner_switch_cross_feature_test` |
| Reinterpret | Not reachable in production, and hidden there (G1-D8). | `g1_palm_journal_test` |

### 9.4 SoulMate

| Seam | Verdict | Evidence |
|---|---|---|
| Free preview | A non-Premium user sees an honest locked preview, not the draw form. | `soul_mate_release_gate_test` #1 |
| Free generation bypass | Blocked. Draw and interpretation repair both re-check Premium with `allowsFresh` (G1-D9, G1-D10); the direct route is self-gated. | `g1_soulmate_entitlement_test`, G0 §3 #9 |
| Economy | Premium only, no Gem price: `SoulMateEconomy.drawCost == null`. | `g1_soulmate_entitlement_test` |
| Durable operation | The client only creates the operation and saves its input, then observes. Portrait, interpretation and persistence happen server-side. | `soul_mate_durable_test` |
| Recovery | Exact target, a foreign active operation ignored for an exact target, cold recovery, outages keep observing (G1-D1), redraw after a deep link (G1-D11). A legacy stuck operation shows a controlled retry that starts a new durable operation. | `soul_mate_durable_test`, `g1_soulmate_durable_recovery_test` |
| Portrait ready, interpretation failed | Only reachable for older saved local entries. The portrait shows; repair is bounded at 2 attempts, updates the same row, and leaves no dead Retry (G1-D12). | `soul_mate_release_gate_test` #18, `g1_soulmate_entitlement_test` |
| Premium lapse | A saved portrait stays readable. Redraw and repair need Premium again. | `g1_soulmate_entitlement_test` |
| Journal | Reopens only when the saved record matches, has an authoritative interpretation and has portrait bytes. | `soul_mate_journal_test` |

### 9.5 OR

| Seam | Verdict | Evidence |
|---|---|---|
| Free chamber | Opens for everyone; free users see the gate when they compose. | `companion_or_conversation_access_test` |
| Free compose bypass | Blocked. Text needs Premium or the one matching first-reading deepen, and now re-checks a stale Premium flag (G1-D15). | `g1_or_premium_lapse_test` |
| First-reading deepen | One free text turn for the first-session Tarot reading. Spent after a usable reply for that context, including when saving fails or the context is cleared (G1-D13). Not spent by an unusable reply. | `first_reading_or_deepen_test`, `g1_or_access_test` |
| Premium text, review access | Allowed; `isPremium` includes an active reviewer grant. | `review_access_gate_test` |
| Voice | Premium only, re-checked with `ensureFresh`; the free deepen never unlocks voice. | `companion_voice_conversation_access_test` |
| Send, retry, double send | One operation id per send intent, reused by retry, with one request for a double tap. Quality re-generation uses its own key (G1-D14). | `or_persist_reliability_d2_test`, `g1_or_retry_persistence_test` |
| Fallback | No fake assistant text. An exhausted quality gate becomes an honest invalid-response failure. | `companion_ai_bridge.dart`, `g1_or_access_test` |
| Handoff and fresh context | Typed handoff; fresh entry clears it. An account switch clears the applied context and the pending static buffer, drops a reply still in flight from the screen, and refuses to write it to storage (G1-D16, Audit.1). | `g1_or_handoff_test`, `g1_owner_switch_cross_feature_test`, `g1_or_account_switch_journey_test`, G0 `or_fresh_entry_clears_handoff_test` |
| Owner-bound persistence | Every conversation write of a send is checked against the owner captured when the send started (§9.12). | `g1_or_account_switch_persistence_test` |
| Persistence | A local save failure keeps the reply visible and offers a retry that doesn't call the provider again. | `or_persist_reliability_d2_test` |

### 9.6 Astrology

| Seam | Verdict | Evidence |
|---|---|---|
| Sign restore, corrupt sign, select | The selected sign restores. An unknown stored id falls back to the default sign (Aries) and the hub still renders; this was already correct, and G1 adds coverage rather than a fix. | `astrology_persistence_test`, `g1_astrology_flow_test` |
| Profile failure | Non-blocking: the local sun-sign reading always shows. | `g1_astrology_flow_test` |
| Profile refresh | Keeps the hub on screen (G1-D17). A first load that stalls offers Retry after the failsafe window. | `g1_astrology_flow_test`, `astrology_reference_loading_retry_test` |
| Detail routing | Opens the detail reading for the selected sign; Yıldızname never opens Astrology. | `astrology_reference_layout_test`, G0 `general_route_matrix_test` |
| Journal | Astrology creates no Journal entries. `LocalAstrologyRepository.save` has no callers, so there is nothing to reopen and nothing to delete. The selected sign is device-scoped and is wiped on account switch. | code |

### 9.7 Cross-feature seams

| Seam | Verdict | Evidence |
|---|---|---|
| Owner switch A → B → A | The local wipe removes owner A's key families (G0). G1 adds a rebuilt sender and a reset OR (G1-D16); Audit.1 adds the static handoff clear and owner-bound OR persistence (§9.12). | `g1_owner_switch_cross_feature_test`, `g1_or_account_switch_journey_test`, G0 `general_owner_isolation_smoke_test` |
| Failure, exit, return | Leaving a wait never cancels the server operation. Returning observes the same operation; nothing is submitted twice. | `soul_mate_durable_test`, `g1_palm_entry_recovery_test`, `test/features/coffee` |
| System back | The G0 regression (`general_navigation_stack_test`, `general_shell_navigation_test`) passes unchanged on the G1 code. | §9.11 |
| Shared error state | The G0 regression (`general_error_state_accessibility_test`) passes unchanged. | §9.11 |

### 9.8 Journal per-entry delete (old P1-JOURNAL-DELETE)

Decision: **SAFELY DEFERRED** (non-blocking). The Journal has no delete UI, and there is no narrow, complete canonical per-entry delete to wire:

- The Coffee store delete doesn't remove the archived image, the reinterpret version root or a favorite. The Palm store delete misses the version root and a favorite.
- The Tarot delete lives in the frozen Reading History detail screen. Dream delete needs the frozen Dream owner guard. `SoulMateResultService.clear()` is not wired to any UI.

Wiring a delete button to these would leave data behind, which is worse than not offering one. The user is never blocked from deleting: the Privacy center clears each area, and account deletion wipes everything. A per-entry delete needs complete per-feature deletes first.

### 9.9 Known limitations (G1)

- **SoulMate review access vs the server.** Review access is stateless on the backend (a hash compare), and the durable SoulMate guard reads only purchase bindings. A reviewer using review access, with no purchase, is refused by the server for a new draw. Fixing it needs a backend design and a deploy. Until then, reviewers can use a sandbox purchase.
- **Stale `/active` pointer.** The backend never clears a feature's active-operation pointer, so recovery can keep reporting a finished operation. The client handles it correctly; it's a backend cleanup item (P3).
- **OR voice.** Text-to-speech can continue briefly after leaving the chamber, and disposing the voice-turn controller while a turn is active is not proven on a device.
- **Coffee V2.** It polls the feature's active pointer rather than the record's own operation id, and its final review is silent if `begin` fails. Its gate providers are cached for the session, and a `setSlot` `StateError` is not handled.
- **Palm photo archive.** Under server completion, the Palm photo is not archived locally.
- **Discovery clear keeps reinterpret version chains** for Coffee, Palm and Tarot. That's the contract pinned by the frozen Dream suite. The text is unreachable in the UI, because its reading records are gone, and account deletion removes it. Removing it needs a product decision and a matching update to those frozen pins.
- **Astrology.** The hub waits for the first profile load before showing (it has a failsafe Retry). Astrology creates no Journal entries.
- **Journal owner filtering.** The Journal doesn't filter by owner itself; it relies on the account-switch wipe.
- **Coffee legacy.** An error-snackbar branch compares a notifier with itself and never fires; errors show inline, so nothing is lost.
- **File size.** The production files touched here that exceed 150 lines were already over the limit before G1 (for example `coffee_reading_controller.dart`, `companion_controller.dart`, `soul_mate_draw_screen.dart`, `palm_reading_controller_capture.dart`). Splitting them is left to dedicated refactors so each fix stays narrow. Two G1 support files (`g1_soulmate_support.dart`, `g1_or_support.dart`) and `g1_support.dart` also exceed 150 lines, following the existing test convention.

### 9.10 Not proven live / external

Everything above is proven with fakes. None of it proves live quality, and none of it is marked green for live:

- The real provider, meaning Coffee, Palm and SoulMate output quality and OR reply quality.
- The real server replay cache and duplicate-gate timing against a real network.
- Real store purchase, restore and lapse, and review access on a store build.
- Device behavior: system back, backgrounding during a wait, push-notification deep links into an exact operation, the microphone and text-to-speech.

### 9.11 Verification (G1)

| Suite | Result |
|---|---|
| G1 (`test/general_audit/g1`) | 44 passed. 30 of them were first shown failing against `HEAD` production files. |
| G0 + G1 (`test/general_audit`) | 102 passed |
| Coffee (`test/features/coffee`) | 215 passed |
| Palm (`test/features/palm`) | 87 passed |
| SoulMate (`soul_mate_*` + `e3e_soulmate_live_portrait` + `soul_mate_experience_final`) | 126 passed |
| Premium (`test/features/premium` + purchase honesty) | 291 passed |
| OR (`test/features/companion`) | 460 passed, 1 skipped |
| Astrology (`test/features/astrology` + percentage honesty) | 24 passed |
| Gems (`test/features/gems`) | 92 passed |
| Journal, Favorites, Personal Discovery | 139 passed |
| Reading Operations (`test/features/reading_operation`) | 69 passed |
| Privacy (`test/features/privacy`) | 33 passed |
| Navigation (`test/core/navigation`) | 4 passed |
| Dream (frozen) | 493 passed, 2 skipped |
| Tarot (frozen) | 1457 passed, 1 skipped |
| Yıldızname (frozen) | 871 passed |
| Full Flutter | 6244 passed, 16 skipped, 0 failed (G0: 6200 + 44 G1) |
| Full backend (`npx vitest run`) | 1652 passed, 1 skipped |
| `flutter analyze` | 0 errors, 0 warnings, 218 infos (unchanged from G0) |
| TSC (`npx tsc --noEmit -p .`) | clean |

### 9.12 G1 Audit.1 — OR account-switch persistence and pending handoff

Base `2d16e8aa69fddac6ebb8f538103e0828241907b3`. Independent verification found one owner-isolation seam left inside G1-D16, with two forms. Both are closed.

**A. A pending handoff survived the switch.** `OrChatHandoffBuffer` is process-wide. The G1 reset cleared the controller's applied context but not this buffer, so a handoff owner A had offered, but that no OR screen had taken yet, could be taken by owner B's chamber (`CompanionReferenceScreen` takes it on open). Now `CompanionController.resetForAccountSwitch()` clears the buffer itself. All four `PrivacyDataRefresh.afterAccountSwitch` callers (the switch epoch listener, sign-out cleanup, deletion confirm and the deletion pending screen) therefore get it, and none of them can forget it.

**B. An in-flight reply could be written back after the wipe.** `CompanionExperienceService.send()` saves the finished conversation itself before returning to the controller, and the conversation store is shared, not owner-bound. The G1 generation bump only kept the reply off the screen. A reply returning after the wipe had cleared `ai_conversations` would write owner A's messages back for owner B to load.

The fix is `CompanionOwnerGuard` (`lib/features/companion/services/companion_owner_guard.dart`) at the service boundary:

- **Snapshot.** `send()` captures a `CompanionOwnerSnapshot` when the send starts. It holds the live authenticated uid (the Firebase gateway's current user, falling back to `AuthService.currentUserId`, the same rule the reading sender uses), the committed local owner (`UserLocalDataIsolation.ownerKey`), the account-switch epoch, and whether the account-deletion gate allows owner-bound work.
- **Writable only when settled.** The snapshot is writable only when auth and the local owner agree, the deletion gate is clear, and identity could be read. During a switch, Firebase is already the next owner while the local owner is still the previous one, so that wipe window is never writable. Watching the epoch alone would miss it, because the epoch bumps only after the wipe has finished and the new owner is committed.
- **Re-checked before every write.** The snapshot is checked again right before the user-turn write and right before the assistant write, and it must still equal the current capture. So an old owner-A send is refused in every later state: auth B with local A (wipe running), auth B with local B (switch done), and A→B→A (the epoch differs).
- **Standalone saves.** Persistence retry, fresh start and abandon go through `persistConversation`, which requires a settled owner at call time.
- **No owner.** When nobody is signed in and no owner has been committed, the data stays device-local. That's the existing boot contract: `UserLocalDataIsolation` adopts pre-owner data for the first owner. A no-owner snapshot is invalid as soon as any owner appears.
- **What a refused send does.** It throws a typed, retryable `authPending` failure and writes nothing. If the switch refresh has already reset the controller, the controller drops it silently, so B sees no A reply and no unrelated error. If the refusal lands in the wipe window, before the reset, the old session shows the calm auth-pending message, and the reset replaces it moments later.
- **Wiring.** Production wires the guard in `companionExperienceServiceProvider`. It reads auth and storage at every check rather than capturing them, because the controller keeps one service for its whole lifetime.

This is a guard, not a database transaction. The service-boundary check and the repository's own internal read-then-write gap left one further seam, closed in Audit.2 (§9.13). What remains:

- **The OR surfaced-theme record** (`discoverySurfaceMemory`, written by the profile-observation hook while the prompt is built) is not bound to the send snapshot. It stores a theme name and a time, not conversation text.
- **Session bootstrap** (`CompanionSessionBootstrap.loadOrCreate`) can still write a welcome-only conversation without the guard. It contains no user content.

Mutation proof. Each mutation was applied to the production file, run, and then restored byte-for-byte (hash checked); no mutation was committed.

| Mutation | Result |
|---|---|
| M1: remove `OrChatHandoffBuffer.clear()` from `resetForAccountSwitch` | Killed. The static-buffer test and the journey test fail. |
| M2: remove the owner check before the assistant write | Killed. The wipe-window, completed-switch and journey tests fail, because A's text is written back. |
| M3: guard ignores live auth (local owner + epoch only) | Killed. The wipe-window test and the guard unit test fail. |

Verification (Audit.1):

| Suite | Result |
|---|---|
| Audit.1 focused (persistence, journey, cross-feature switch, G1 handoff) | 9 passed |
| G1 (`test/general_audit/g1`) | 50 passed (44 + 6 Audit.1) |
| G0 + G1 (`test/general_audit`) | 108 passed |
| OR (`test/features/companion`) | 460 passed, 1 skipped |
| Privacy · auth isolation (`test/core/auth`) · Reading Operations | 33 · 258 · 69 passed |
| Premium (+ purchase honesty) · Gems | 291 · 92 passed |
| Coffee · Palm · SoulMate · Astrology | 215 · 87 · 126 · 24 passed |
| Dream · Tarot · Yıldızname (frozen) | 493 + 2 skipped · 1457 + 1 skipped · 871 passed |
| Full Flutter | 6250 passed, 16 skipped, 0 failed |
| Full backend | 1652 passed, 1 skipped |
| `flutter analyze` | 0 errors, 0 warnings, 218 infos (unchanged) |
| TSC | clean |

No provider calls, store transactions or deploys; no AI model or prompt changed. The Discovery-clear reinterpret-chain contract (§9.9) and the Journal delete deferral (§9.8) are unchanged.

### 9.13 G1 Audit.2 — Owner-safe durable OR conversation writes

Base `ccc01f41cf932fb72664ef9e6eaf8cb1f1f1153f` (Audit.1, frozen). Independent verification found two residual defects inside the gap Audit.1 (§9.12) had already named as open. Both are closed.

**A. The guard's re-check and the repository's write weren't at the same point.** `CompanionOwnerGuard` re-checked the send's owner snapshot right before calling `_save`, but `LocalAiConversationRepository.save` then did its own `await getAll()` — a real microtask yield — before calling `setStringList`. An owner change landing inside that one gap, after the service-level check had already passed, would still reach the write.

**B. `setStringList` returning `false` was read as success.** `LocalStorage.setStringList` returns `Future<bool>` and can resolve `false` without throwing — the exact contract `storage_result.dart`'s `requireDurable` extension exists for, already used by `LocalDreamRepository` and others. `LocalAiConversationRepository.save` and `.delete` awaited it and discarded the result, so a real write failure looked identical to a successful one, and `CompanionExperienceService.send()` had no way to know its `persisted: true` was false.

The fix stays inside the same two files:

- **`LocalAiConversationRepository.saveGuarded`** (new). The same read-modify-write as `save`, except the `canWrite` callback it's given is checked immediately after `getAll()` resolves and immediately before the write starts, with nothing else awaited in that gap. `save` and `delete` keep their existing shape; only `saveGuarded` re-validates ownership, because only the OR path needs a check inside the repository itself.
- **`CompanionExperienceService._save`** is now the one write boundary for every conversation mutation — the user-turn save, the assistant-reply save, and `persistConversation`'s retry / fresh-start / abandon callers all go through it. It calls `saveGuarded` when the concrete repository is `LocalAiConversationRepository` (always true in production), passing `() => owner == null || guard.stillValid(owner)` as `canWrite`. A repository without that internal gap (isolated-test fakes) gets the same check run immediately before its plain `save` instead, since there's no repository-internal read to guard.
- **`_writeAll`** (new, shared by `save`, `delete` and `saveGuarded`) applies `.requireDurable(_key)` to every write, so a `false` return throws instead of being discarded. `send()`'s existing try/catch around each save already treats a thrown error as a persistence failure and never reports `persisted: true` on that path — it just wasn't reachable before, because the boolean was never checked.

This is still a guard, not a database transaction, and Audit.1's honesty about that stands unchanged: the physical `SharedPreferences` write is never made atomic with auth state, only checked as late as Dart's single-threaded event loop allows — immediately before the call that starts the write, with no unrelated await in between. What Audit.1 named as open beyond the closed gap — the OR surfaced-theme record and session-bootstrap's unguarded welcome-only write (§9.12) — are unchanged and still true.

Mutation proof. Each mutation was applied to `local_ai_conversation_repository.dart`, run against `test/general_audit/g1/g1_audit2_or_write_guard_test.dart`, and then restored byte-for-byte (`cmp` checked); no mutation was committed.

| Mutation | Result |
|---|---|
| M1: `saveGuarded` checks `canWrite` before `getAll()` instead of after it | Killed. All three race tests fail — the stale write survives whatever changed during the read. |
| M2: `_writeAll` ignores the `setStringList` boolean | Killed. All four false-return tests fail — a refused write is reported as a success. |
| M3: `saveGuarded` drops the final `canWrite` check entirely | Killed. The wipe-window race test (and the other two) fail — an owner change mid-read no longer blocks the write. |

Verification (Audit.2):

| Suite | Result |
|---|---|
| Audit.2 (`g1_audit2_or_write_guard_test.dart`) | 8 passed |
| G1 (`test/general_audit/g1`) | 58 passed (50 + 8 Audit.2) |
| G0 + G1 (`test/general_audit`) | 116 passed |
| OR (`test/features/companion`) | 460 passed, 1 skipped |
| Auth isolation (`test/core/auth`) · Privacy (`test/features/privacy`) | 258 · 33 passed |
| Dream · Tarot · Yıldızname (frozen) | unchanged (folded into the full run below) |
| Full Flutter | 6258 passed, 16 skipped, 0 failed (Audit.1's 6250 + 8 Audit.2) |
| Full backend | 1652 passed, 1 skipped, 0 failed |
| `flutter analyze` | 0 errors, 0 warnings, 218 infos (unchanged) |
| TSC | clean |

No provider calls, store transactions or deploys; no AI model or prompt changed.
