# ORACLY — General Final Product Audit

Phase **G0 — Product truth + shared core / cross-feature infrastructure**
Branch `fix/final-product-remediation-20260922` · Date 2026-09-28

Evidence comes from repo code and tests only. No provider, OpenAI, Cloud Run, Firebase, Play Console or App Store Connect call was made. Nothing was deployed or uploaded. Anything that needs a store, cloud or physical device is marked external or manual, never green.

---

## 1. CURRENT PRODUCT TRUTH — HEAD e71f937601e7a5aa84b1648b7310086a0932f39b

The audited base is `e71f9376`. The G0 commit that adds this document changes only the shared defects listed in §4, and no product surface.

Source of truth: `OraclyFeatureRegistry` (`lib/core/features/oracly_feature_registry.dart`), pinned by `test/general_audit/general_route_matrix_test.dart`.

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
- Per-entry journal delete for non-Tarot kinds (P1-JOURNAL-DELETE) is deferred to G1.

## 8. External actions and post-deploy / device checks

- **Play:** product availability plus a license-test purchase, restore and restart on a device.
- **App Store:** monthly + yearly products only, then a sandbox purchase and restore.
- **Backend:** deploy the Dream writer binding; verify `/health`, `/ready` and a fail-closed Dream request.
- **Legal:** confirm the hosted privacy, terms and data-deletion pages.
- **Device:** Android system back from each chamber (G0-D5), and warm share links from a messenger while the app runs (G0-D1). Also a TalkBack / VoiceOver pass and the TECNO matrix.
