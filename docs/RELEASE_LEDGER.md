# ORACLY authoritative release ledger

This is the Phase R0 release-control baseline. It records verified state without promoting traffic, changing runtime endpoints, invoking paid providers, or repeating broad audits.

## Ledger identity

- **VERIFIED COMPLETE** — Last verified: 2026-09-03 20:17:55 +03:00 (Europe/Istanbul).
- **VERIFIED COMPLETE** — Branch: `roadmap/monetization-release-audit`.
- **VERIFIED COMPLETE** — HEAD: `b13675dbaea4ad6a697f84c1d4099495e0fe2a6e` (`Use personal memory guidance in OR context`, 2026-08-29 20:32:24 +03:00).
- **VERIFIED COMPLETE** — Backup exists at `C:\Dev\oracly_new_release_backup_20260902_192914`; its direct Git metadata identifies the same branch and HEAD. The backup contains sensitive local configuration and must not be committed or shared.
- **VERIFIED COMPLETE** — Completed phases: OR-V3 is accepted complete; Phase R0 inventory is complete when this ledger is written.
- **READY BUT NOT PROMOTED** — The repository contains extensive post-HEAD work which remains uncommitted and unpromoted.

## Verified quality baseline

- **VERIFIED COMPLETE** — OR-V3 final visual similarity: **90.16%**.
- **VERIFIED COMPLETE** — Full Flutter result accepted from the final log: **2,540 passed, 14 skipped, 0 failed**.
- **VERIFIED COMPLETE** — Analyzer result accepted from the final log: **0 errors, 0 warnings, 110 existing infos**.
- **VERIFIED COMPLETE** — No paid provider call was made for OR-V3 or R0.
- **VERIFIED COMPLETE** — No commit or push was made for OR-V3 or R0.
- **UNKNOWN — NEEDS VERIFICATION** — The current backend source changed after the latest E3H.1 deployment evidence; no fresh backend-wide build/test result proves the exact present working tree. R1 must build and test it.
- **VERIFIED COMPLETE** — The latest local deploy-asset secret scan ran once in R0 and returned `ok: true`, `hits: 0`; its scope is deploy assets, not the entire dirty tree.

## Local production-code state

- **READY BUT NOT PROMOTED** — Exhaustive file-level dirty tree at the pre-ledger R0 baseline (`git status --porcelain=v1 -uall`): **1,131 paths**: 565 modified, 16 deleted, 550 untracked, 0 staged. Nothing was cleaned, reset, staged, committed, or pushed. After adding this ledger, the total is 1,132 with 551 untracked.
- **READY BUT NOT PROMOTED** — Pre-ledger product-area grouping: Flutter `lib/` 462; Flutter `test/` 206; backend 222; tooling/evidence 195; Android 12; iOS 11; design assets 7; docs 4; root files 6; Linux 2; Windows 2; Cursor config 1; macOS 1. Untracked directories are expanded to individual files.
- **READY BUT NOT PROMOTED** — Major Flutter feature groups include Tarot 60, Companion/OR 44, Dream 39, Coffee 29, Premium/Soulmate 23, shared AI 20, Home 16, Palm 14, Onboarding 13, and smaller supporting areas.
- **READY BUT NOT PROMOTED** — Backend includes source 22, tests 18, scripts 16, plus 166 configuration, dependency-lock, temporary, and generated/evidence files exposed by exhaustive untracked-file enumeration.
- **VERIFIED COMPLETE** — R0 intentionally creates only this ledger. No production source is changed by R0.

## Flutter runtime endpoints

- **READY BUT NOT PROMOTED** — The checked-in E3F runtime file points AI to `https://e3f---oracly-api-uya7zqzwra-ew.a.run.app/v1/ai/complete` and billing to the same tagged host at `/v1/billing/verify`.
- **BLOCKED** — `tool/dart_defines.production.example.json` still uses `REPLACE_WITH_PRODUCTION_HOST` placeholders for AI and billing; it is not a shippable production configuration.
- **READY BUT NOT PROMOTED** — Runtime validation rejects insecure/private/localhost release endpoints. The generic production API fallback is `https://api.oracly.app`, but the AI and billing clients depend on their explicit runtime keys.
- **BLOCKED** — Flutter endpoints must not be changed until an isolated final backend release candidate has passed R1.

## Backend AI readiness

- **READY BUT NOT PROMOTED** — **Coffee**: local E3H.1 uses a two-stage reading pipeline (vision observer, then writer), schema-bound observations, evidence binding, quality validation and at most one repair. It fails closed unless allowlisted reading model configuration is present.
- **READY BUT NOT PROMOTED** — **Palm**: shares the Coffee E3H.1 two-stage pipeline and the same validation/configuration gates.
- **READY BUT NOT PROMOTED** — **Soulmate**: local `soulmate_draw` builds a bounded prompt and uses the image transport. Default configuration is `gpt-image-2`, `1024x1536`, high quality, with a 120-second image timeout; the Cloud Run request timeout is 180 seconds.
- **READY BUT NOT PROMOTED** — **OR**: local authenticated proxy and companion/oracle paths are covered by the accepted Flutter baseline, but this local version is not the 100%-traffic revision.
- **READY BUT NOT PROMOTED** — **Tarot**: local proxy-backed path is covered by the accepted Flutter baseline, but is not promoted.
- **READY BUT NOT PROMOTED** — **Dream**: local structured interpretation path is covered by the accepted Flutter baseline, but is not promoted.
- **UNKNOWN — NEEDS VERIFICATION** — The exact configured Soulmate image model on the current 100%-traffic revision was not established from safe revision metadata; source defaults do not prove deployed configuration.

## Temporary and release-only diagnostics

- **BLOCKED** — `backend/src/ai/reading/pipeline.ts` conditionally emits `_e3h` observations, sections, provider stages/call counts, repair state, and model names when `ORACLY_RELEASE_PHASE` is `e3h` or `e3h1`. Remove the response diagnostic before traffic.
- **BLOCKED** — `backend/src/errors.ts` emits `_e3h` error details when `ORACLY_RELEASE_PHASE` is exactly `e3h`. Remove the release-only error payload before traffic.
- **READY BUT NOT PROMOTED** — E3H/E3H.1 tests and local fixture sanitizers reference `_e3h`; they are test support, not proof that production responses are clean. Update them as required after stripping runtime diagnostics.
- **BLOCKED** — Temporary/generated E3H material (`backend/.tmp-e3c-firebase-meta.json`, `.tmp-e3h1`, `_write_e3h*`/fix-up scripts, private E3 evidence and logs) must be reviewed, excluded from deployment, and either ignored or deliberately retained before any commit.

## Cloud deployment and traffic

- **VERIFIED COMPLETE** — Read-only inspection used project `oracly-7f613`, Cloud Run service `oracly-api`, region `europe-west1`.
- **VERIFIED COMPLETE** — Service URL: `https://oracly-api-uya7zqzwra-ew.a.run.app`; concurrency 20; request timeout 180 seconds.
- **VERIFIED COMPLETE** — Current traffic is **100%** to `oracly-api-00002-wel` (tag `staging`). Despite its tag, this is the revision serving the untagged service URL.
- **READY BUT NOT PROMOTED** — Healthy isolated revisions at 0%: `00004-rek` (`e3e`), `00007-nir` (`e3f`), `00011-man` (`e3g`), `00015-cab` (`e3h`), and latest `00016-cop` (`e3h1`).
- **VERIFIED COMPLETE** — `00002`, `00015`, and `00016` have different immutable image digests. E3H/E3H.1 add reading vision/writer/reasoning configuration names absent from `00002`; all inspected revisions reference the server-side OpenAI secret without exposing its value.
- **UNKNOWN — NEEDS VERIFICATION** — An exact source-level diff between production `00002` and E3H.1 `00016` cannot be reconstructed from Cloud Run metadata alone. R1 must assemble a reproducible candidate from the present source.
- **VERIFIED COMPLETE** — R0 made no Cloud Run, Firebase, IAM, secret, tag, or traffic mutation.

## Firebase Auth and App Check

- **VERIFIED COMPLETE** — Firebase Authentication (`identitytoolkit.googleapis.com`) and App Check (`firebaseappcheck.googleapis.com`) APIs are enabled.
- **READY BUT NOT PROMOTED** — Backend production/staging policy fails closed with authentication and App Check required and development bypasses disabled; current and E3H.1 revision metadata contain the expected Auth/App Check configuration names.
- **UNKNOWN — NEEDS VERIFICATION** — R0 did not expose or live-exercise production tokens, registered app IDs, enforcement metrics, or end-user sign-in. Effective console registration/enforcement must be confirmed without printing tokens.

## Billing readiness

- **READY BUT NOT PROMOTED** — Flutter and backend request contracts agree: required `platform` (`android` or `ios`), `productId`, and `purchaseToken`; optional `transactionId`.
- **READY BUT NOT PROMOTED** — Backend implements server-side Google Play and Apple verification, known-product checks, entitlement status/expiry handling, and purchase-token/account binding. Tests/fixtures alone are not treated as production verification.
- **VERIFIED COMPLETE** — Code catalog IDs align: `app.oracly.premium.monthly`, `app.oracly.premium.yearly`, and `app.oracly.premium.lifetime`.
- **BLOCKED** — The production Flutter billing URL is still a placeholder and inspected Cloud Run environment names did not establish Play/Apple billing credentials/configuration.
- **EXTERNAL ACTION REQUIRED** — Create/verify products, prices, agreements, tax/banking, service credentials/API access, and tester availability in Google Play Console and App Store Connect.
- **UNKNOWN — NEEDS VERIFICATION** — No real sandbox purchase/restore/renewal/cancel/refund lifecycle is evidenced against the final candidate.

## Android release readiness

- **VERIFIED COMPLETE** — Android namespace and application ID are `app.oracly`; Flutter version is `1.0.0+1`.
- **READY BUT NOT PROMOTED** — Release signing validation is wired and ignored `android/key.properties` exists; an existing release APK and mapping outputs are present.
- **BLOCKED** — No release AAB is present. Current generated binaries predate this ledger and do not prove the final R1 source.
- **UNKNOWN — NEEDS VERIFICATION** — Keystore ownership/backup, signing certificate fingerprints, upload-vs-app-signing arrangement, and final signed artifact verification were not safely established.
- **EXTERNAL ACTION REQUIRED** — Confirm Play application ownership, product setup, store listing, Data safety/content declarations, testers/tracks, app signing, and upload the final post-R1 AAB.

## iOS release readiness

- **BLOCKED** — Xcode project still uses placeholder bundle ID `com.example.oraclyNew` (tests: `com.example.oraclyNew.RunnerTests`) and no development team was established.
- **READY BUT NOT PROMOTED** — Automatic signing and a local `GoogleService-Info.plist` path are wired, but this does not constitute distributable signing.
- **EXTERNAL ACTION REQUIRED** — Choose/register the production bundle ID, Apple team, certificates/profiles, capabilities, App Store record, products, agreements, tax/banking, privacy declarations, and review metadata.
- **EXTERNAL ACTION REQUIRED** — Final CocoaPods/Xcode archive, signing, export, device validation, and App Store upload require macOS with Xcode and authorized Apple credentials.

## Security and secret status

- **VERIFIED COMPLETE** — Existing backend deploy-asset scanner was run exactly once in R0 via `npm.cmd run scan:secrets`: zero hits. No value from `.env`, JWTs, Firebase debug tokens, provider keys, or service-account JSON was printed into this ledger.
- **BLOCKED** — The scanner's scope is deploy assets only; it is not a full-repository secret audit.
- **READY BUT NOT PROMOTED** — `.env`, `backend/.env`, Android key properties, and Firebase mobile config files are gitignored.
- **BLOCKED** — Commit-risk material includes untracked/modified runtime define files, `.env.example` files, hook/config files, `backend/.tmp-e3c-firebase-meta.json`, private E3 evidence, logs/screenshots, build outputs/mappings, generated reports, and the backup's local `.env`. Review filenames and contents without publishing credentials.
- **BLOCKED** — Do not add the external backup directory or generated/private evidence wholesale to source control.

## Reliability backlog

- **BLOCKED** — Account deletion: prevent duplicate submit and define safe cancellation behavior while deletion is in flight; add deterministic interaction coverage.
- **BLOCKED** — Notifications: initialize and set the real device timezone before local scheduling; current timezone initialization alone does not prove correct local-zone behavior.
- **BLOCKED** — Birth chart: make the latest-record read resilient to transient/corrupt storage reads and verify recovery behavior.
- **BLOCKED** — Camera: distinguish permanent denial and provide a settings route for Coffee/Palm capture flows; another feature's settings path is not proof.
- **BLOCKED** — Startup storage: verify promotion from ephemeral to durable storage and surfaced/recoverable failure behavior across cold starts; fallback tests do not close all device failure modes.
- **BLOCKED** — Fourteen environment-gated/live AI tests remain skipped across local E2E/provider/user-flow suites and OR real-gate chat. Run only when final isolated endpoints and explicit no-cost/sandbox authorization make them safe.

## Legal and store-listing readiness

- **READY BUT NOT PROMOTED** — In-app Privacy Policy and Terms launch wiring exists and requires public HTTPS runtime URLs.
- **BLOCKED** — Production Privacy Policy and Terms URLs are still placeholders/TBD; no live public documents were verified.
- **NOT STARTED** — A public web account-deletion URL was not found or verified.
- **READY BUT NOT PROMOTED** — Store metadata is drafted in `docs/project_execution/STORE_METADATA_DRAFT.md`.
- **EXTERNAL ACTION REQUIRED** — Publish and verify Privacy Policy, Terms, and account-deletion pages; insert them into runtime configuration and both store listings; complete store declarations and review assets.

## Release blockers

### P0 — must clear before any traffic

- **BLOCKED** — Strip all runtime `_e3h`/release-only diagnostics and assemble one reproducible final Coffee/Palm/Soulmate backend.
- **BLOCKED** — Build, test, secret-scan, and deploy that backend as a new isolated 0%-traffic revision; verify auth/App Check and no paid-provider invocation.
- **BLOCKED** — Establish final production AI/billing/legal endpoint configuration without changing Flutter endpoints during R1.
- **BLOCKED** — Complete backend billing configuration and real store sandbox verification before monetized release.
- **BLOCKED** — Resolve platform identity/signing blockers and produce final signed store artifacts after backend release-candidate validation.
- **BLOCKED** — Publish required legal/account-deletion URLs before store submission or traffic promotion.

### P1 — reliability and submission hardening

- **BLOCKED** — Close the six reliability items above and convert skipped coverage into explicitly controlled release evidence where applicable.
- **BLOCKED** — Perform final device smoke tests, purchase lifecycle tests, startup/permission edge cases, and store-listing review against final artifacts.
- **BLOCKED** — Review and curate the dirty tree and generated evidence before any commit.

## External user/account actions

- **EXTERNAL ACTION REQUIRED** — Google Play Console: app ownership, app signing, products/prices, billing API/service access, testers/tracks, Data safety, content rating, declarations, listing, and final AAB upload.
- **EXTERNAL ACTION REQUIRED** — Apple Developer/App Store Connect: identifiers, team/signing, products/prices, agreements/tax/banking, API credentials, privacy declarations, listing, TestFlight/review, and macOS archive/upload.
- **EXTERNAL ACTION REQUIRED** — Firebase console: verify Android/iOS registrations, SHA fingerprints, App Check providers/enforcement, Auth providers, authorized domains, and production monitoring.
- **EXTERNAL ACTION REQUIRED** — Public web hosting: publish Privacy Policy, Terms, and account-deletion instructions at stable HTTPS URLs.

## Exact ordered release roadmap

1. **READY BUT NOT PROMOTED** — R1: strip E3H diagnostics, assemble final Coffee/Palm/Soulmate backend, build/test/scan, and deploy one new 0%-traffic candidate with no paid calls and no Flutter endpoint change.
2. **BLOCKED** — Compare the candidate reproducibly with current source and `00002`; verify health, auth/App Check failure modes, logs, limits, and zero traffic.
3. **BLOCKED** — Close P0 reliability/security/configuration gaps and rerun proportionate backend/targeted Flutter checks; avoid repeating accepted OR-V3 broad checks unless source-impact requires it.
4. **EXTERNAL ACTION REQUIRED** — Complete Firebase, billing, legal, Play, and Apple console/account configuration.
5. **BLOCKED** — Create final production Flutter runtime defines, produce Android AAB and macOS iOS archive, scan artifacts, and run physical-device/store-sandbox validation.
6. **BLOCKED** — Conduct a human release review, approve an explicit rollback target, then perform a separately authorized canary/traffic promotion with monitoring.
7. **BLOCKED** — Only after acceptance, curate intended source/evidence, exclude secrets/generated files, and obtain separate authorization for commit/push.

## Evidence and log paths

- **VERIFIED COMPLETE** — Flutter final: `tool/or_v3_evidence/final/full_flutter_tests.txt`.
- **VERIFIED COMPLETE** — Analyzer final: `tool/or_v3_evidence/final/dart_analyze.txt`.
- **VERIFIED COMPLETE** — Companion suite: `tool/or_v3_evidence/final/companion_tests.txt`.
- **VERIFIED COMPLETE** — Similarity: `tool/or_v3_evidence/final/per_region_measurement_report.json` and `tool/or_v3_evidence/comparison/similarity_report.json`.
- **READY BUT NOT PROMOTED** — Older AI/backend deployment evidence: `tool/e3e_private/evidence/`, including `e3h_report_bundle.txt`; treat the directory as private/generated evidence.
- **READY BUT NOT PROMOTED** — Existing build evidence/artifacts: `build_debug.txt`, `build/app/outputs/flutter-apk/app-debug.apk`, `build/app/outputs/flutter-apk/app-release.apk`, and release mapping outputs. No AAB exists.
- **UNKNOWN — NEEDS VERIFICATION** — No single fresh backend test/build log proves the exact current dirty source; R1 must create authoritative backend candidate logs.

## Do not repeat

- **VERIFIED COMPLETE** — Do not rerun the accepted OR-V3 full Flutter suite, analyzer, companion visual audit, or 90.16% similarity work merely to rediscover this baseline.
- **VERIFIED COMPLETE** — Do not rerun the R0 deploy-asset secret scanner; it already returned zero hits once. R1 must run its own scan after diagnostic removal and assembly.
- **VERIFIED COMPLETE** — Do not repeat broad branch/HEAD/dirty-tree/backup/Cloud Run traffic discovery unless a known mutation occurs.
- **VERIFIED COMPLETE** — Do not call paid AI providers, change Flutter endpoints, promote traffic, commit, or push without a later phase explicitly authorizing it.

## R0 closure and next authorized phase

- **VERIFIED COMPLETE** — Only `docs/RELEASE_LEDGER.md` was intentionally created or changed in R0.
- **VERIFIED COMPLETE** — No production source changed in R0.
- **VERIFIED COMPLETE** — No cloud mutation occurred in R0.
- **VERIFIED COMPLETE** — No paid provider call occurred in R0.
- **VERIFIED COMPLETE** — No commit or push occurred in R0.
- **READY BUT NOT PROMOTED** — Next authorized phase is exactly: “Strip temporary E3H diagnostics, assemble the final Coffee/Palm/Soulmate production backend, build/test/scan it, and deploy one isolated 0%-traffic release-candidate Cloud Run revision without paid AI calls or Flutter endpoint changes.”
- **BLOCKED** — Do not execute R1 as part of R0.

## OR-V4 real-device visual repair — 2026-09-03

- **READY BUT NOT PROMOTED** — Implemented the phone-driven OR repair: owned Luna v2 runtime derivative, shared hero/avatar identity, soft-edge portrait composition, bounded assistant bubbles, naturally sized dedicated-route composer, correct bottom safe-area handling, and compact intro fit.
- **VERIFIED COMPLETE** — Exact production files intentionally changed in OR-V4: `lib/core/constants/app_assets.dart`, `lib/assets/images/companion/luna_portrait_hero_v2_runtime.png`, `companion_luna_hero_portrait.dart`, `companion_luna_intro_card.dart`, `companion_reference_tokens.dart`, `companion_reference_message_bubble.dart`, `companion_reference_input_bar.dart`, `companion_reference_composer_dock.dart`, and `companion_reference_or_shell.dart`.
- **VERIFIED COMPLETE** — The art master `art_masters/or/luna_portrait_hero_v2.png` was not overwritten. The deterministic 720x1280 runtime derivative is 1,275,178 bytes and is registered through `AppAssets`; hero and avatar use the same derivative.
- **VERIFIED COMPLETE** — Real TECNO phone evidence shows a readable persisted assistant glass bubble (not strips), visible Luna avatar/timestamp, all five shortcuts, bottom composer/privacy, keyboard-safe layout, and normal long-thread scrolling. Evidence: `tool/or_v4_evidence/phone_conversation_720x1576.png`, `phone_keyboard_final_720x1576.png`, and `phone_or_idle_final_720x1576.png`.
- **VERIFIED COMPLETE** — Focused OR gate: 54 passed, 0 skipped, 0 failed. D2 persistence retry retained one initial provider call and zero additional calls on persistence retry.
- **BLOCKED** — Companion directory was run exactly once: 414 passed, 1 skipped, 1 failed. The only failure was the pre-existing standalone shell-clearance expectation; after context separation, the focused responsive file rerun passed 24/24. The directory was not rerun a second time under the cost-control instruction.
- **VERIFIED COMPLETE** — Touched companion-reference directory and `app_assets.dart` analysis: 0 errors, 0 warnings.
- **BLOCKED** — Full visual acceptance is not claimed. `oracly_e3f` booted and produced a genuine 1080x2400 app frame, but repeatedly went offline before the required OR emulator state matrix. Clean emulator idle 320x568/390x844, conversation, keyboard, long-thread, loading, provider-error, and save-failed captures remain required.
- **READY BUT NOT PROMOTED** — Supporting comparison evidence: `tool/or_v4_evidence/reference_vs_phone_side_by_side.png`, `reference_phone_overlay_50.png`, `reference_phone_diff_heatmap.png`, and `DEFECT_TO_FIX_MAP.md`. MAE is not used as the acceptance gate.
- **VERIFIED COMPLETE** — No full Flutter suite, paid provider call, cloud mutation, traffic/DNS/billing/backend-AI/dependency change, commit, push, or deployment occurred in OR-V4.
- **BLOCKED** — Exact remaining visible differences: phone framing is denser than the reference; the reference shows all three prompt cards simultaneously while the phone exposes the third by horizontal scroll; a stable AVD must confirm final mask blending and every requested transient/error state.

## OR-V4.1 final phone layout fix — 2026-09-03

- **VERIFIED COMPLETE** — The persistent lower interaction area is measured by normal layout: quick prompts, feature shortcuts, composer, privacy caption, and device safe area consume their rendered height, while the conversation receives the remaining viewport. No device-specific bottom-clearance constant was introduced.
- **VERIFIED COMPLETE** — Restored lazy conversations follow the measured maximum extent until it stabilizes. When a message arrives, the pre-growth scroll position determines whether to follow the reply; manual upward scrolling and the existing new-reply affordance are preserved.
- **VERIFIED COMPLETE** — Genuine persisted TECNO KN8 evidence shows the newest assistant bubble fully clear of the lower interaction area. Complete text, Luna avatar, timestamp, all three message actions, and both follow-up actions are visible: `tool/or_v4_evidence/or_v4_1_phone_conversation_final.png`.
- **VERIFIED COMPLETE** — Real-phone keyboard evidence shows the restored assistant bubble remains complete above the resized interaction area: `tool/or_v4_evidence/or_v4_1_phone_keyboard.png`.
- **VERIFIED COMPLETE** — Actual `oracly_e3f` rendering at 1080px / density 405 (426.7 logical pixels) shows all three reference prompt cards simultaneously at unchanged accessible typography: `tool/or_v4_evidence/or_v4_1_prompts_426.png`. The emulator density override was reset after capture.
- **VERIFIED COMPLETE** — At narrower widths, the third prompt remains horizontally reachable and the edge gradient/chevron makes scrolling visible; this behavior is covered by the focused layout regression.
- **VERIFIED COMPLETE** — Luna retains the OR-V4 identity/artwork and face brightness. The added transparent lower gradient removes the portrait's horizontal cutoff by blending it into the black-purple nebula; the 426.7dp rendered evidence confirms no rectangular lower panel.
- **VERIFIED COMPLETE** — Focused OR-V4.1 layout plus D2 regression: 15 passed, 0 skipped, 0 failed. D2 persistence retry retained one initial generation and zero additional provider calls. Evidence: `tool/or_v4_evidence/or_v4_1_focused_tests.txt`.
- **VERIFIED COMPLETE** — Final complete companion-directory run occurred exactly once after the focused gate passed: 418 passed, 1 skipped, 0 failed. Evidence: `tool/or_v4_evidence/or_v4_1_companion_tests.txt`.
- **VERIFIED COMPLETE** — Touched companion-reference directory plus OR-V4.1 test analysis returned no issues. Evidence: `tool/or_v4_evidence/or_v4_1_touched_analysis.txt`.
- **VERIFIED COMPLETE** — The final debug APK built successfully and was installed with phone data preserved. The existing future Kotlin-plugin migration warning did not fail Gradle or prevent artifact creation. Evidence: `tool/or_v4_evidence/or_v4_1_debug_build.txt`.
- **VERIFIED COMPLETE** — No full Flutter-suite rerun, paid provider call, backend/cloud/billing/endpoint/dependency change, deploy, traffic mutation, commit, or push occurred in OR-V4.1.
- **VERIFIED COMPLETE** — During the final evidence-only continuation, no production source changed; only this ledger, `tool/or_v4_evidence/OR_V4_1_REPORT.md`, and curated screenshot evidence/log records were completed.
- **BLOCKED** — The single skipped companion test remains part of the existing environment-gated/live-AI backlog; it is not represented as complete.
- **VERIFIED COMPLETE** — OR-V4.1 ends here. No next phase is authorized.

## R1 production AI backend consolidation — 2026-09-03 21:39:12 +03:00

- **READY BUT NOT PROMOTED** — R1 produced exactly one isolated Cloud Run release candidate from source fingerprint `6965e8a24b6360e0d438b2fadb7c803d065f78e4eb9cb4f5e15484c45698e0a7`: revision `oracly-api-r1-6965e8a24b63`, tag `r1-6965e8a24b63`, URL `https://r1-6965e8a24b63---oracly-api-uya7zqzwra-ew.a.run.app`, traffic 0%.
- **VERIFIED COMPLETE** — Removed the Coffee/Palm `_e3h` success response and the `ORACLY_RELEASE_PHASE=e3h` error-detail branch. `backend/src` and production `dist` contain zero `_e3h`, `ORACLY_RELEASE_PHASE`, or `withE3hDiagnostics` references; typed public error codes remain.
- **VERIFIED COMPLETE** — R1 production files changed: `backend/src/ai/reading/pipeline.ts`, `backend/src/errors.ts`, `backend/src/config.ts`, `backend/src/ai/human-quality.ts`, `backend/src/ai/reading/types.ts`, `backend/src/ai/reading/locale-vocab.ts`, `backend/Dockerfile`, `backend/package.json`, and `backend/package-lock.json`. Scoped regression coverage changed in `backend/tests/e3h-reading-pipeline.test.ts`. All pre-existing dirty-tree changes were preserved.
- **VERIFIED COMPLETE** — Coffee final contract remains observer → evidence-bound writer with strict structured output, known evidence IDs, TR/EN/RU quality rules, stage cache/idempotency, at most one text-only writer repair, no observer rerun during repair, typed unusable-image failure, and no fake/local production reading.
- **VERIFIED COMPLETE** — Palm retains the same two-stage guarantees plus trusted-hand normalization and rejection of untrusted identity/handedness inference.
- **VERIFIED COMPLETE** — Soulmate retains the real `gpt-image-2` path at `1024x1536`, `high`, with a 120-second image timeout; base64, magic-byte/MIME, and size validation remain active and no fake/local fallback exists.
- **VERIFIED COMPLETE** — Production configuration is explicit and fail-closed: Coffee/Palm observer and writer `gpt-5.6-sol`, reasoning `low`, explicit allowlist `gpt-4o,gpt-4o-mini,gpt-5.6-sol`; default text `gpt-4o`; Auth required; development Auth/App Check bypasses false. Reading models are no longer silently added to the allowlist.
- **VERIFIED COMPLETE** — Focused Coffee/Palm result: 50 passed, 0 failed. Focused Soulmate result: 15 passed, 0 failed. Evidence: `tool/r1_evidence/01_coffee_palm_focused.txt`, `02_soulmate_focused.txt`.
- **VERIFIED COMPLETE** — Production TypeScript build passed with 0 application source maps. Backend full suite ran exactly once after focused gates: 207 passed, 1 environment-gated live-eval skipped, 0 failed. Evidence: `tool/r1_evidence/03_production_typescript_build.txt`, `04_backend_full_suite.txt`.
- **VERIFIED COMPLETE** — Final post-change R1 deploy-asset secret scan returned `ok: true`, `hits: 0`. Evidence: `tool/r1_evidence/05_r1_secret_scan.txt`.
- **VERIFIED COMPLETE** — Production container built on Node 22, matching the locked Google Auth runtime requirement. It runs as `oracly` UID 100, contains 0 forbidden application/evidence/credential files, starts locally, returns `/health` 200, and fails closed with `/ready` 503 when launched without secrets/configuration. Evidence: `tool/r1_evidence/06_container_build.txt`, `07_container_security_local_runtime.json`.
- **READY BUT NOT PROMOTED** — Immutable image tag: `europe-west1-docker.pkg.dev/oracly-7f613/oracly/oracly-api:r1-20260903-6965e8a24b63`; registry manifest-list digest `sha256:0a4469286793d5221460cd6f83c8007aad8b1a7540b2cceb890219042d413689`; Cloud Run runtime digest `sha256:6815baf2a7eade95158a6b12cfc6663ad46b6ceb71bf766c88ccb8032ff04fd6`.
- **VERIFIED COMPLETE** — Candidate runtime uses the existing `oracly-api-runtime` service account, CPU 1, memory 1Gi, concurrency 20, timeout 180 seconds, min 0, max 1. `OPENAI_API_KEY` is only the existing `OPENAI_API_KEY:latest` Secret Manager reference; `ORACLY_RELEASE_PHASE` is absent.
- **VERIFIED COMPLETE** — Tagged `/health` returned 200. Tagged `/ready` returned 200 with expected Auth, App Check, text, vision, and image-generation booleans and no secrets. A validly shaped request without authentication returned HTTP 401 `unauthorized` before provider access and contained no `_e3h`. Evidence: `tool/r1_evidence/11_tagged_endpoint_checks.json`.
- **VERIFIED COMPLETE** — Before deploy, `oracly-api-00002-wel` had 100% traffic. After deploy, it still has 100%; `oracly-api-r1-6965e8a24b63` has 0%; no other revision was promoted. Evidence: `tool/r1_evidence/09_traffic_before.yaml`, `12_revision_and_traffic_after.json`.
- **VERIFIED COMPLETE** — 27 recent R1 revision log entries contained 0 secret-key, bearer-token, prompt, or image/base64 pattern hits and 0 unexpected error entries. Raw logs were not stored. Evidence: `tool/r1_evidence/13_sanitized_log_scan.json`.
- **VERIFIED COMPLETE** — R1 made zero OpenAI/provider calls, made no Flutter/endpoint/DNS/billing/store/IAM/API/Secret Manager value/service-account/Artifact Registry structure change, did not promote traffic, and made no commit or push.
- **BLOCKED** — The locked production dependency audit reports 2 unresolved findings (1 moderate, 1 high). Dependency upgrades were not authorized in R1; explicit review/remediation and proportionate rebuild remain required in R2.
- **BLOCKED** — One environment-gated backend live-eval test remains skipped; valid Firebase Auth/App Check token verification and any paid AI smoke test remain separately authorized future work.
- **BLOCKED** — R2 must compare the R1 candidate against current production `00002`, resolve authorized security/configuration blockers, and define a separately approved canary/rollback plan. R1 does not authorize Flutter endpoint wiring, paid smoke tests, traffic promotion, DNS, store work, commit, or push.
- **VERIFIED COMPLETE** — Full sanitized R1 report and evidence index: `tool/r1_evidence/R1_REPORT.md`. R1 stops here; R2 was not started.

## R2 controlled dependency remediation and isolated candidate — 2026-09-03 22:03:28 +03:00

- **READY BUT NOT PROMOTED** — R2 remediated the authorized production dependency findings and deployed exactly one isolated candidate: revision `oracly-api-r2-093d4a80c17d`, tag `r2-093d4a80c17d`, URL `https://r2-093d4a80c17d---oracly-api-uya7zqzwra-ew.a.run.app`, traffic 0%.
- **VERIFIED COMPLETE** — Production/R1 baseline comparison: `oracly-api-00002-wel` remained 100%; R1 remained 0%. Both use the same runtime service account, CPU 1, memory 1Gi, concurrency 20, timeout 180 seconds, max 1, effective min 0, and only the existing `OPENAI_API_KEY:latest` secret reference. Exact safe configuration and behavior differences are recorded in `tool/r2_evidence/R2_REPORT.md`.
- **VERIFIED COMPLETE** — Before remediation, production audit identified Fastify 5.11.3 as moderate and both installed fast-uri lines as one high vulnerable package. Direct Fastify is now exact `5.12.1`; AJV-nested fast-uri is `3.1.6`; shared fast-uri is `4.1.3` under explicit supplemental authorization. No override was added; Node remains 22.
- **VERIFIED COMPLETE** — `package.json` changed only the Fastify declaration from `^5.4.0` to exact `5.12.1`. R2 lock changes are limited to the root Fastify requirement; Fastify version/artifact/integrity and its `process-warning` metadata range; and the two authorized fast-uri version/artifact/integrity triplets. No other resolved dependency version changed; `lockfileVersion` remains 3.
- **VERIFIED COMPLETE** — Final `npm ls` resolves Fastify 5.12.1, fast-uri v3 3.1.6, and fast-uri v4 4.1.3. Final production-only audit reports 0 total vulnerabilities, including 0 moderate and 0 high. Evidence: `tool/r2_evidence/08_final_npm_ls.txt`, `09_final_production_audit.json`.
- **VERIFIED COMPLETE** — Focused request/auth/security: 41 passed; Coffee/Palm: 50 passed; Soulmate: 15 passed; all with 0 failed. Production TypeScript build passed with 0 application source maps. Backend full suite ran exactly once after focused gates: 207 passed, 1 environment-gated live-eval skipped, 0 failed.
- **VERIFIED COMPLETE** — R2 secret scan returned `ok: true`, 0 hits. Production container build passed; it runs as `oracly` UID 100, has 72 application-owned files, 0 application `.ts`, 0 `.map`, 0 forbidden leakage, and 0 sensitive Docker-history hits. Local `/health` returned 200; secrets-free `/ready` failed closed with 503.
- **VERIFIED COMPLETE** — Both Docker stages pin the verified official multi-architecture base `node:22-alpine@sha256:c610fcdfb1d5b4740dd70c284ed3cb16bb857e0f7166196e36a5501df7a3aa32`; local Docker and Cloud Run accepted it.
- **READY BUT NOT PROMOTED** — R2 source fingerprint: `093d4a80c17da7aac2db9d88a1af4af1d78ed6403c0e96d2c1f9904a752b21ae`. Image tag: `europe-west1-docker.pkg.dev/oracly-7f613/oracly/oracly-api:r2-20260903-093d4a80c17d`; registry manifest-list digest `sha256:7fc416a9790b59dd2c6ac8ce7dbba60d0446fcc2342bfb3ade02800ff63a1687`; Cloud Run runtime digest `sha256:e8525da266e8205afe277ceca62cb125fe80db12284b177c4d4bf70eb165b6ac`.
- **VERIFIED COMPLETE** — R2 runtime retains the existing service account and secret reference, CPU 1, memory 1Gi, concurrency 20, timeout 180 seconds, min 0, max 1. Tagged `/health` returned 200; `/ready` returned 200 with expected capability booleans and no secrets; missing and invalid Auth returned 401 before provider access; `_e3h` was absent.
- **VERIFIED COMPLETE** — Sanitized recent-log scan inspected 21 entries: secret/token/image hits 0, prompt hits 0, unexpected errors 0, `ai_complete`/provider-operation events 0. Raw logs were not stored.
- **VERIFIED COMPLETE** — After deployment, production `oracly-api-00002-wel` remains 100%, R1 remains 0%, and R2 remains 0%. No traffic restoration was required.
- **VERIFIED COMPLETE** — R2 made zero OpenAI/provider calls and no valid Firebase Auth/App Check live request. No Flutter/endpoint, DNS, IAM, Secret Manager value, billing, store, legal, commit, push, or traffic-promotion action occurred.
- **READY BUT NOT PROMOTED** — A staged 1%/5%/25%/50% canary proposal and exact rollback target `oracly-api-00002-wel` are documented at `tool/r2_evidence/CANARY_ROLLBACK_PLAN.md`. The rollback command was not executed and automatic 100% promotion is not proposed.
- **BLOCKED** — Valid Auth/App Check live validation, paid AI smoke tests, Flutter endpoint wiring, canary/traffic promotion, and all later release work require separate authorization. One environment-gated backend live-eval remains skipped.
- **VERIFIED COMPLETE** — R2 evidence index and full sanitized report: `tool/r2_evidence/R2_REPORT.md`. R2 stops here; canary, promotion, Auth/App Check live validation, paid smoke, Flutter wiring, and R3 were not started.

## R3 authenticated release-candidate E2E — 2026-09-03 22:23:02 +03:00

- **BLOCKED** — R3 targeted only `oracly-api-r2-093d4a80c17d`. Baseline matched R2: digest `sha256:e8525da266e8205afe277ceca62cb125fe80db12284b177c4d4bf70eb165b6ac`, source fingerprint `093d4a80c17da7aac2db9d88a1af4af1d78ed6403c0e96d2c1f9904a752b21ae`, health/ready 200, clean production audit evidence, production 100%, R1 0%, R2 0%.
- **VERIFIED COMPLETE** — Licensed/sanitized E3F fixtures passed visual/file gates. One temporary anonymous user and App Check debug token were created in the ignored private area. Six trust responses matched the requested codes, but invalid-operation validation precedes token verification and did not independently prove App Check validity.
- **BLOCKED** — The sole Coffee HTTP attempt returned 401 `app_check_required` before provider execution and was not resent. Palm, Soulmate, parser/quality gates, and replays were not started.
- **VERIFIED COMPLETE** — Provider usage was exactly 0/7 stages, repairs 0, actual estimated incremental/cumulative cost 0 TRY. Cleanup succeeded: debug token revoked, anonymous user deleted, tokens wiped. Secret scan returned 0 hits.
- **VERIFIED COMPLETE** — No production source/dependency, deploy, traffic, Flutter/DNS, IAM, billing, secret, service-account, API, endpoint, commit, or push change occurred. With no cloud mutation, the verified allocation remains production 100%, R1 0%, R2 0%.
- **BLOCKED** — R2 is not canary-eligible. Valid App Check acceptance, paid contracts, replay proof, and recent-log verification remain incomplete. Evidence: `tool/r3_evidence/R3_REPORT.md`, `tool/r3_evidence/R3_EVIDENCE_INDEX.json`.
- **VERIFIED COMPLETE** — R3 stops here. R4/canary/promotion/additional paid attempts are not authorized.

## R3.1 App Check preflight repair — 2026-09-03

- **VERIFIED COMPLETE** — The genuine zero-provider payload was proven locally: supported `coffee_analysis` plus a six-byte JPEG-shaped input returned `invalid_image` with exactly 0 transport calls. Invalid operation is no longer treated as Auth/App Check proof.
- **BLOCKED** — R2 App Check configuration is internally inconsistent: project `oracly-7f613` actually has project number `1075374196330`, while R2 is configured with `831058176790` and an app ID from that other project. A genuine current-project token cannot pass R2 audience/app allowlisting.
- **NOT STARTED** — No new anonymous user/debug token, live preflight, Coffee request, provider stage, or replay was started after this deterministic pre-credential blocker. Estimated R3.1 cost: 0 TRY.
- **VERIFIED COMPLETE** — Final traffic remains production `oracly-api-00002-wel` 100%, R1 0%, R2 0%. No production source, deploy, traffic, provider, Palm/Soulmate, commit, or push action occurred.
- **BLOCKED** — R3.1 requires a separately authorized configuration-only candidate with the correct project number/app allowlist before one new credential session can safely be attempted. Evidence: `tool/r3_evidence/R3_1_REPORT.md`, `tool/r3_evidence/R3_1_EVIDENCE.json`.
- **VERIFIED COMPLETE** — R3.1 stops here; R3.2, R4, Palm, Soulmate, canary, and promotion were not started.

## R3.1A Firebase configuration correction gate — 2026-09-03

- **VERIFIED COMPLETE** — Project identity agrees across Google Cloud and local Firebase files: `oracly-7f613`, project number `1075374196330`.
- **BLOCKED** — Android Firebase identity does not agree: Firebase Management API binds active App ID `1:1075374196330:android:2d4c11d195dedad9ef2c13` to `com.example.oracly_new`, while local `google-services.json` and Gradle use `app.oracly`. The explicit disagreement STOP gate prevented deployment and credentials.
- **VERIFIED COMPLETE** — iOS Firebase App ID `1:1075374196330:ios:d49b5b67036096efef2c13` and bundle `com.example.oraclyNew` agree between Firebase, plist, and Xcode; the placeholder bundle remains a release blocker.
- **NOT STARTED** — No configuration-only revision, credential session, live preflight, Coffee/replay, Palm/Soulmate, provider call, or traffic mutation occurred.
- **BLOCKED** — Resolve/register the authoritative Firebase Android app for package `app.oracly` and obtain its authentic client configuration before R3.1A can resume. Evidence: `tool/r3_evidence/R3_1A_REPORT.md`, `tool/r3_evidence/R3_1A_EVIDENCE.json`.
- **VERIFIED COMPLETE** — R3.1A stops here; later phases and promotion were not started.

## R3.1B Firebase Android registration and authenticated Coffee gate — 2026-09-03

- **VERIFIED COMPLETE** — Registered exactly one Firebase Android app for `app.oracly`: `1:1075374196330:android:200bc15b1e43a8a2ef2c13`; downloaded its authentic `google-services.json`. The old placeholder registration was not changed.
- **VERIFIED COMPLETE** — Focused config test passed 1/1, touched test analysis had 0 issues, and debug APK built. Reproducible non-secret deployment metadata/script and focused test were corrected; iOS and Flutter runtime endpoints were untouched.
- **READY BUT NOT PROMOTED** — Configuration-only revision `oracly-api-r31b-200bc15b` uses the exact R2 manifest/runtime image digests, correct project number and Android-only allowlist. Health/ready are 200; production remains 100%, R1/R2/R3.1B remain 0%.
- **VERIFIED COMPLETE** — Real Auth/App Check claims matched and supported-operation preflight reached deterministic `invalid_image` with 0 transport/provider calls before Coffee.
- **BLOCKED** — The single Coffee request succeeded at HTTP/contract level and passed grounding/safety/no-diagnostic checks, but sanitized scoring was average 9.2 with minimum 7 due to three absent/non-string public sections. No retry or replay occurred.
- **UNKNOWN — NEEDS VERIFICATION** — Coffee used 2–3 upstream stages; repair usage is not exposed after R1 diagnostic removal. Conservative accounting is 3 stages / approximately 4 TRY, within cap.
- **VERIFIED COMPLETE** — Credential cleanup and scans passed. Play Integrity still requires the real Play App Signing SHA-256 certificate; iOS placeholder remains deferred; Palm/Soulmate remain untested. Evidence: `tool/r3_evidence/R3_1B_REPORT.md`, `tool/r3_evidence/R3_1B_EVIDENCE.json`.
- **VERIFIED COMPLETE** — R3.1B stops here; R3.2, R4, canary, promotion and Flutter wiring were not started.

## R3.2 evaluator correction and authenticated Palm/Soulmate smoke — 2026-09-03 23:25:30 +03:00

- **VERIFIED COMPLETE** — Private Coffee completeness now requires `visualObservation`, `overall`, and `takeaway`; honest empty evidence-dependent sections do not reduce completeness. Provider-free evaluator regressions passed 9/9 with transport spy 0.
- **VERIFIED COMPLETE** — Stored R3.1B Coffee was reclassified without another request: Grounding 10, Completeness 10, Natural Turkish 9, Safety 10, Contract 10; average 9.8, minimum 9. The former result was a harness false-negative.
- **VERIFIED COMPLETE** — Palm contract was audited: `visualObservation`, `overall`, and `takeaway` are mandatory; line sections are evidence-dependent. One authenticated Palm operation returned HTTP 200, passed average 9.8/minimum 9, honestly left `fateLine` empty, and used no retry/replay/fake fallback.
- **VERIFIED COMPLETE** — One authenticated Soulmate operation returned HTTP 200 and a valid decoded PNG (1024×1536, 2,441,789 bytes). Local non-AI inspection confirmed a recognizable natural portrait, intact anatomy, no corruption, and suitable composition. The decoded file remains only in gitignored private evidence.
- **VERIFIED COMPLETE** — Real Auth/App Check preflight returned HTTP 200 `invalid_image` with 0 provider events. Temporary credentials were deleted/wiped; deploy and private-evidence secret scans found 0 hits.
- **UNKNOWN — NEEDS VERIFICATION** — Exact Palm repair usage is not exposed. Conservative new-stage accounting is Palm 2–3 plus Soulmate 1, total 3–4; Coffee 0. The 4-stage / 20 TRY ceiling was respected. Deterministic idempotency tests passed 5/5; no live replay occurred.
- **READY BUT NOT PROMOTED** — Final traffic remains production `oracly-api-00002-wel` 100%, R1 0%, R2 0%, R3.1B 0%. R3 is complete and `oracly-api-r31b-200bc15b` is eligible only for a separately authorized promotion review.
- **EXTERNAL ACTION REQUIRED** — Play Integrity still requires the real Play App Signing SHA-256 certificate.
- **BLOCKED** — iOS bundle ID/signing remains placeholder-blocked and requires separate macOS/iOS release work.
- **VERIFIED COMPLETE** — R3.2 stops here. No backend/Flutter production source, dependency/configuration, deploy, traffic mutation, commit, or push occurred. R4, canary, Flutter wiring, Play configuration, and promotion were not started. Evidence: `tool/r3_evidence/R3_2_REPORT.md`, `tool/r3_evidence/R3_2_EVIDENCE.json`.

## R4B Android signing, manifest hardening and local AAB — 2026-09-03 23:47:03 +03:00

- **VERIFIED COMPLETE** — Existing external keystore `C:\OraclyKeys\oracly-upload-key.jks`, alias `oracly`, is readable and contains a usable private-key entry. Store/key access signed and verified a temporary proof without exposing credentials. It is an Oracly-scoped, non-debug 2048-bit RSA certificate valid 2026-08-28 through 2054-01-13; upload SHA-256 is `E7:89:56:1F:AC:94:0D:25:24:42:F9:8E:1D:6C:7D:BA:4E:EF:C0:BB:36:1F:17:CF:FF:F5:43:09:D6:00:7A:D5`.
- **BLOCKED** — No recoverable encrypted keystore backup/custody plan is documented. Confirm and test recovery before any Play upload. The keystore and `android/key.properties` are ignored, with 0 signing-secret files found in current tracking or Git history.
- **VERIFIED COMPLETE** — Manifest blame traced required `camera.any` and legacy `WRITE_EXTERNAL_STORAGE` to `camera_android_camerax 0.7.4+6`; `READ_EXTERNAL_STORAGE` was implied. Minimal merger directives remove both broad storage permissions and set `camera.any required=false`; dependency-owned exported components were preserved and AD_ID remains absent.
- **VERIFIED COMPLETE** — Focused Android/Firebase/App Check/release-policy/final-manifest verification passed 22/22; changed-test analysis had 0 issues. Full Flutter suite was not run.
- **READY BUT NOT PROMOTED** — One signed, minified, resource-shrunk internal RC AAB exists at `build/app/outputs/bundle/release/app-release.aab`: 110,533,113 bytes, SHA-256 `3C1AE727F3E84C9BCFD828463805BCC74F0435057573D0E7203BB7962BF17EA9`, package `app.oracly`, version `1.0.0+1`, min/target/compile SDK 24/36/36. Signature verification passed and matches the upload certificate; R8 mapping/resource outputs exist.
- **READY BUT NOT PROMOTED** — Packaged Firebase App ID is `1:1075374196330:android:200bc15b1e43a8a2ef2c13`; release-lock policy selects Play Integrity and prevents debug-provider activation. Internal AI/billing endpoints target only the isolated R3.1B tag, with image timeout 120 seconds. Sideloading cannot prove Play Integrity.
- **VERIFIED COMPLETE** — AAB/private-define scans found 0 private-key/signing-property/OpenAI-key/JWT/secret filenames and 0 placeholders. Public upload certificate is retained only in gitignored private evidence; private keystore/passwords were never copied.
- **EXTERNAL ACTION REQUIRED** — Before internal-track upload: establish tested encrypted keystore recovery/custody; confirm intended upload certificate and unused versionCode 1; create/confirm the Play app and Play App Signing; complete legal/runtime billing prerequisites. After upload, obtain the real Play App Signing SHA-256 and configure/test Firebase Play Integrity under separate authorization.
- **VERIFIED COMPLETE** — R4B stops here. No Play upload, Firebase/Cloud Run/traffic/DNS/IAM/billing/Secret Manager change, provider call, commit or push occurred; iOS was untouched. Evidence: `tool/r4b_evidence/R4B_REPORT.md`, `tool/r4b_evidence/R4B_EVIDENCE.json`.

## R4C product truth audit and release pause — 2026-09-04

- **BLOCKED** — Verdict: NOT READY. Only `emulator-5554`, not TECNO, was connected. Installed `app.oracly` 1.0.0+1 is debug-signed, uses development localhost `10.0.2.2:8787` for AI, has no remote billing URL, and enables the debug-only Premium override.
- **BLOCKED** — OR/Luna is wired to `chat`/`oracle`, but this installed runtime does not reach production or R3.1B. OR-V4 visual and persistence evidence did not prove a live conversation.
- **BLOCKED** — Primary Tarot uses `LocalInterpretationExecutor`; its nominal AI executor is a local-fallback stub. Same-body fallback sections and deterministic local synthesis explain repetition, weak synthesis and inconclusive prose. Backend `oracle` is follow-up only.
- **READY BUT NOT PROMOTED** — R3.1B/R3.2 Coffee/Palm/Soulmate proof remains isolated. The R4B AAB points to that tag but is not installed through Play and cannot yet prove Play Integrity.
- **EXTERNAL ACTION REQUIRED** — Play app/products, App Signing SHA-256, Play Integrity, license purchase/restore/refund testing and tested keystore recovery remain mandatory.
- **BLOCKED** — Dream release E2E, TR/EN/RU quality parity, notification timezone, birth-chart transient read, startup storage, account deletion duplicate submit/cancel, camera permanent-denial routing and device fault coverage remain.
- **VERIFIED COMPLETE** — Diagnostic only: no tests/builds, provider calls, credentials, source/dependency edits, cloud/store/traffic mutation, commit or push. Evidence: `tool/r4c_product_audit/R4C_PRODUCT_TRUTH_REPORT.md`, `tool/r4c_product_audit/R4C_FEATURE_MATRIX.json`.
- **BLOCKED** — Release work pauses here. Repairs, Play upload and closed testing were not started.

## R5A OR runtime recovery and explicit environment contract — 2026-09-04 01:18:13 +03:00

- **VERIFIED COMPLETE** — Removed silent debug localhost selection. LOCAL now requires explicit `APP_ENV=local` and is debug-only; INTERNAL is pinned to the R3.1B HTTPS AI/billing host and ignores endpoint overrides; PRODUCTION remains explicit HTTPS and fail-closed.
- **VERIFIED COMPLETE** — Canonical OR no longer returns a local/template assistant fallback. Transport/configuration failures remain visible in-chat without erasing the conversation or fabricating an assistant response.
- **VERIFIED COMPLETE** — OR `chat`/`oracle` requests now include a stable payload/context-derived idempotency key. Auth, App Check, request schema, parsing, failure states, duplicate-send protection and persistence-only retry were verified provider-free. Normal OR has no gem debit; paid-feature ledgers retain success-only, exactly-once settlement.
- **VERIFIED COMPLETE** — Safe debug/INTERNAL diagnostics expose only environment, build mode, AI host, transport class, application ID and version/build; no credentials or private content.
- **VERIFIED COMPLETE** — Focused results: runtime/transport 44 passed; OR lifecycle/idempotency 32 passed; post-fix relevant rerun 26 passed; all 0 failed. Touched analysis: 0 issues. No full suite was run.
- **READY BUT NOT PROMOTED** — INTERNAL debug QA APK: `build/app/outputs/flutter-apk/app-debug.apk`, `app.oracly` 1.0.0+1, SHA-256 `B7D98DEBA538F15CA9A2DC2E9411FF83BDABA40400C030D81D7CC40D0A01FDCB`, R3.1B host, Android Debug signer. QA sideload only; not Play Internal Testing.
- **BLOCKED** — Only `emulator-5554` (Google `sdk_gphone64_x86_64`, Android 14/API 34) was connected. TECNO KN8 was unavailable; artifact installation and real-phone proof remain pending.
- **VERIFIED COMPLETE** — R5A artifact/evidence scan found 0 forbidden secret patterns. Provider calls, deploys, cloud/Firebase/IAM/DNS/billing/traffic mutations, dependencies, backend/Tarot, commit and push remained untouched.
- **READY BUT NOT PROMOTED** — R5A evidence: `tool/r5a_or_runtime/R5A_REPORT.md`, `tool/r5a_or_runtime/R5A_EVIDENCE.json`. Next recommendation is a separately authorized TECNO INTERNAL verification (R5B); R5A stops here.

## R5A.1 lockfile restoration and real operation-ID lifecycle — 2026-09-04 01:47:01 +03:00

- **BLOCKED** — Historical R5A status is corrected to **VERIFIED WITH DEFECTS FOUND DURING CLOSURE**: closure review found the unintended 56-line lockfile removal and payload-derived OR idempotency. Its environment contract and fail-closed fallback removal remain valid.
- **VERIFIED COMPLETE** — Restored exactly seven original lock records/56 lines without dependency resolution, upgrades or `pubspec.yaml` changes: `flutter_secure_storage` 9.2.4, Linux 1.2.3, macOS 3.1.3, platform interface 1.1.2, web 1.2.1, Windows 3.1.2 and `js` 0.6.7. All declared direct dependencies are present in the lockfile.
- **VERIFIED COMPLETE** — OR `chat`/`oracle` now use namespaced opaque per-submission IDs with 128 bits from `Random.secure`, deterministic test injection, persisted `pending/completed/abandoned` state, retry/restart reuse, pre-allocation double-tap blocking and fresh IDs for later identical submissions. No private input or identity contributes to an ID; persistence-only retry remains zero transport/provider calls.
- **VERIFIED COMPLETE** — Focused final gate: 51 passed, 0 failed; OR lifecycle file 19/19; touched analysis 0 issues; full Flutter suite not run. All network/provider behavior was faked and provider-call count was 0.
- **READY BUT NOT PROMOTED** — Rebuilt INTERNAL debug QA APK: `build/app/outputs/flutter-apk/app-debug.apk`, 238,049,913 bytes, SHA-256 `BE25CF1A9E8EC94B1759BC9D40EB4FD686B647C2DB3F2FCC2136E6B0511F33C2`, Android Debug signer. It is for QA sideload only and is not suitable for Play upload. Expanded artifact scan found 0 non-native forbidden secret-pattern files.
- **BLOCKED** — Backend idempotency remains a process-local memory map with a 10-minute TTL and is lost across instance restart, scale-out routing and revision replacement. Client persistence is best-effort duplicate suppression, not end-to-end exactly-once. Durable shared server-side idempotency is a P1 blocker before shared paid-AI exactly-once reliance.
- **VERIFIED COMPLETE** — R5A.1 changed no backend source, prompt/model, Tarot or unrelated feature; made no provider/OpenAI call, dependency resolution/upgrade, cloud/Firebase/traffic/Play mutation, commit or push.
- **READY BUT NOT PROMOTED** — Detailed corrected evidence: `tool/r5a_or_runtime/R5A_REPORT.md` and `tool/r5a_or_runtime/R5A_EVIDENCE.json`. R5B remains a separately authorized phase. STOP after R5A.1.
