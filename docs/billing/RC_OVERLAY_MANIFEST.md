# rc_1b overlay manifest (store AAB 26093014 source) → integration QA branch

Source: `D:\oracly_rc_1b` (read only), HEAD `5c1090a0`, uncommitted diff hash `8fa28060`, AAB sha256 `6cf1403e…`, AAB versionCode `26093014`.
Target: branch `qa/billing-store-integration-20261024` from `e089745b`. Copied 24 Oct 2026 by path-by-path three-way comparison (base `5c1090a0`). Hashes are sha256 over LF-normalised content.

Actions: `take_rc` = QA side unchanged from base, rc content copied verbatim; `add` = rc untracked file imported by tracked rc sources; `merge3_clean` = both sides changed, `git merge-file` without conflict.

| Path | Kind | Action | rc sha256 | result sha256 |
|---|---|---|---|---|
| `backend/src/reading/reading-commerce-verify.ts` | tracked | take_rc | `e9d2ee3b59345793` | `e9d2ee3b59345793` |
| `backend/src/reading/reading-consumable-play.ts` | tracked | take_rc | `95c78694908b595b` | `95c78694908b595b` |
| `backend/src/reading/reading-consumable-verifier.ts` | tracked | take_rc | `4a3bd3ba32c89109` | `4a3bd3ba32c89109` |
| `backend/src/routes/reading-commerce.ts` | tracked | take_rc | `6a145e2780552d49` | `6a145e2780552d49` |
| `backend/tests/e2e-live-provider-guard.test.ts` | tracked | take_rc | `489da2acee08711c` | `489da2acee08711c` |
| `backend/tests/e2e/coffee-v3-e2e-harness.ts` | tracked | take_rc | `ebe25ebb040d9c0f` | `ebe25ebb040d9c0f` |
| `backend/tests/e2e/live-provider-guard.ts` | tracked | take_rc | `4796efb823d67eb8` | `4796efb823d67eb8` |
| `backend/tests/reading-commerce.test.ts` | tracked | take_rc | `ac4c79be74c8e092` | `ac4c79be74c8e092` |
| `lib/core/config/oracly_runtime_keys.dart` | tracked | take_rc | `0fbe509ac5aa7a4a` | `0fbe509ac5aa7a4a` |
| `lib/core/l10n/tables/table_dream_read.dart` | tracked | take_rc | `4af192eaa8b20830` | `4af192eaa8b20830` |
| `lib/features/coffee/coffee_v2/presentation/coffee_v2_intro_view.dart` | tracked | take_rc | `b2fecc6c27bfae21` | `b2fecc6c27bfae21` |
| `lib/features/coffee/coffee_v2/presentation/coffee_v2_step_view.dart` | tracked | take_rc | `e069cbe198d7d484` | `e069cbe198d7d484` |
| `lib/features/coffee/coffee_v3/presentation/coffee_v3_intro_view.dart` | tracked | take_rc | `61c604df6d4952e4` | `61c604df6d4952e4` |
| `lib/features/coffee/coffee_v3/presentation/coffee_v3_step_view.dart` | tracked | take_rc | `7b60db6c82deb802` | `7b60db6c82deb802` |
| `lib/features/reading_commerce/copy/reading_commerce_copy.dart` | tracked | take_rc | `05f49807b37c826c` | `05f49807b37c826c` |
| `lib/features/star_map/narrative/live/yildizname_live_persist.dart` | tracked | take_rc | `3b725db9dcd80782` | `3b725db9dcd80782` |
| `linux/flutter/generated_plugin_registrant.cc` | tracked | take_rc | `7a88e3e7f24fa8c9` | `7a88e3e7f24fa8c9` |
| `linux/flutter/generated_plugin_registrant.h` | tracked | take_rc | `00f93bb5b1faefde` | `00f93bb5b1faefde` |
| `linux/flutter/generated_plugins.cmake` | tracked | take_rc | `3b46ea97afd0ce12` | `3b46ea97afd0ce12` |
| `macos/Flutter/GeneratedPluginRegistrant.swift` | tracked | take_rc | `85c7351d8ddf25ce` | `85c7351d8ddf25ce` |
| `pubspec.yaml` | tracked | merge3_clean | `1d64e8ce39244f6e` | `979918a45189a38b` |
| `test/core/voice/or_voice_humanization_test.dart` | tracked | take_rc | `440bcfb765cbcb6a` | `440bcfb765cbcb6a` |
| `test/e2e/coffee_v3_live_acceptance_test.dart` | tracked | take_rc | `a9527e5b7672e3aa` | `a9527e5b7672e3aa` |
| `test/e2e/coffee_v3_three_view_e2e_test.dart` | tracked | take_rc | `6f51594547f62659` | `6f51594547f62659` |
| `test/features/reading_commerce/reading_purchase_tracker_test.dart` | tracked | take_rc | `fd176daf6eb0d03e` | `fd176daf6eb0d03e` |
| `windows/flutter/generated_plugin_registrant.cc` | tracked | take_rc | `1ab2b1c778bf0ce6` | `1ab2b1c778bf0ce6` |
| `windows/flutter/generated_plugin_registrant.h` | tracked | take_rc | `dbc11635d7b1ba18` | `dbc11635d7b1ba18` |
| `windows/flutter/generated_plugins.cmake` | tracked | take_rc | `d69277416c87bf26` | `d69277416c87bf26` |
| `backend/src/reading/reading-voided-sync.ts` | untracked | add | `63867f38e38e935a` | `63867f38e38e935a` |
| `backend/tests/reading-voided-sync.test.ts` | untracked | add | `0b645f1078b61b7b` | `0b645f1078b61b7b` |
| `lib/features/reading_commerce/presentation/reading_billing_qa_entry_link.dart` | untracked | add | `056f2aa5ed6e1803` | `056f2aa5ed6e1803` |
| `test/features/reading_commerce/reading_billing_qa_entry_link_test.dart` | untracked | add | `4889f0fdc8b2f1c6` | `4889f0fdc8b2f1c6` |

## Not copied

- Ignored inputs the AAB was built with: `android/key.properties` (signing secret), `android/app/google-services.json`, `tool/dart_defines.production.json`, `ios/Runner/GoogleService-Info.plist`. Secrets/config, never committed.
- Untracked non-source: `tool/dart_defines.internal.json`, `tool/dart_defines.test_backend.json` (env config), `tool/e2e/*.sh`, `tool/qa/coffee_v2/*`, `backend/scripts/*one-shot*`/`luna-three-chat-preview.ts` (paid-call scripts), `backend/docs/qa/coffee-writer-r1-prototype-*` (model outputs), root screenshots/xml, test failure PNGs, tool caches, `assets/flutter_assets/...` (not in pubspec assets).

## Version policy

`pubspec.yaml` keeps the rc value `1.0.0+26093013` verbatim; the store AAB was built with build-number override `26093014`. Any QA test build must pass an explicit `--build-number` above `26093014` so it can never be confused with, or replace, the store artifact. No build was made.

## Source boundary

Integration tree = rc_1b working tree + exactly the 69 files changed `5c1090a0..e089745b` (verified file by file; 0 other differences, 0 frozen-area differences). The AAB itself cannot be byte-compared with source; ignored inputs above and the build toolchain are outside this proof.
