# iOS privacy manifest and signing audit — release candidate

Branch `rc/ios-fincan-20261028`, audited 28 Oct 2026 on Windows from source.
Nothing here was checked on a Mac, in a signed archive or on an iPhone; those
checks are listed at the end and now run as build gates.

## 1. Required-reason APIs

| Code | Required-reason API use | Covered by |
| --- | --- | --- |
| Runner Swift (`AppDelegate.swift`, `SceneDelegate.swift`) | none (`isExcludedFromBackup` is not a required-reason key) | — |
| Dart app code (`lib/`) | none directly: no `stat`, `lastModified`, disk space, uptime or keyboard APIs | — |
| `dart:io` file access (Fincan Haritası photos, maps file) | file timestamps, boot time inside the engine | `Flutter.framework/PrivacyInfo.xcprivacy`: FileTimestamp `0A2A.1`, `C617.1`; SystemBootTime `35F9.1`; tracking false |
| `shared_preferences` (`NSUserDefaults`) | user defaults | the plugin's own manifest |

**Decision: no `Runner/PrivacyInfo.xcprivacy`.** Nothing in the Runner
target calls a required-reason API, so it has no reason to declare, and a
data-collection list written here without a full audit would be a guess.
Data collection is declared in App Store Connect → App Privacy, as for
earlier builds.

## 2. Plugin manifests (pub cache, versions in `pubspec.lock`)

With manifest (12, all valid plists per `tool/ios/privacy_manifests.py`):
`camera_avfoundation`, `firebase_messaging`, `flutter_local_notifications`,
`flutter_secure_storage`, `flutter_timezone`, `image_picker_ios`,
`in_app_purchase_storekit`, `permission_handler_apple`, `share_plus`,
`shared_preferences_foundation`, `url_launcher_ios`, plus the Flutter engine.

Without manifest: `audioplayers_darwin`, `firebase_app_check`,
`firebase_auth`, `firebase_core`, `flutter_image_compress_common`,
`flutter_tts`, `path_provider_foundation` (no native code; FFI),
`speech_to_text`. Their native sources contain no required-reason API (the
only match, `user.metadata.creationDate` in `firebase_auth`, is the account
creation date, not a file timestamp), and none is on Apple's list of SDKs that
must ship a manifest. The Firebase iOS SDK pods under the FlutterFire plugins
ship their own manifests upstream; which pod versions are embedded is known
only after `pod install` on the Mac.

## 3. Fincan Haritası and the privacy policy

In-app text matches the code: opt-in switch off by default, three photos,
marks and notes kept only in the app's own storage, excluded from backups,
removed per reading, by clearing history and by account wipe
(`user_local_data_wipe.dart`, `privacy_discovery_clear.dart`).

**Gap:** the published policy (`docs/privacy-policy.md` on `main`, 18 Sep)
describes coffee photos only as temporary device staging and its "Local
storage" list does not mention Fincan Haritası. The text to add is drafted in
`docs/product/coffee/FINCAN_HARITASI_RELEASE_READINESS.md` §7 and needs
legal review and publishing on `main` before release. App Privacy answers do
not change (the photos are kept on device only).

## 4. `aps-environment = development`

`Runner.entitlements` has `development`; Builds 9 and 10 used the same file
and `test/ios_push_entitlements_test.dart` pins it on purpose. Apple's
documented behavior: the exported App Store build takes `aps-environment`
from the distribution provisioning profile (`production`). Unchanged here.

That holds only if: the App ID `app.oracly` has Push Notifications and App
Attest enabled, and the App Store provisioning profile Codemagic uses was
generated after both capabilities were enabled.

**Gate:** `ios-release` now runs `tool/ios/signed_entitlements.py` on the
signed IPA before publishing: `aps-environment` and App Attest must be
`production`, `get-task-allow` false, bundle `app.oracly`; on a mismatch the
IPA is deleted and the build fails, so nothing is uploaded. The same step
validates every embedded privacy manifest (`tool/ios/privacy_manifests.py`);
`ios-compile-check` runs the manifest check on the unsigned app.

## 5. Not verifiable here (Mac / signed build / device)

- Embedded framework list and the Firebase pods' manifests (gate above).
- Signed entitlements of a real archive (gate above).
- Xcode privacy report and App Store Connect processing (ITMS-91053/91061).
- Backup exclusion, StoreKit sandbox, App Check on an iPhone.

## 6. `ios-signed-qa-check` — signed IPA, no upload

Manual Codemagic workflow on `chore/ios-signed-qa-check-20261028`. Same
preparation and signing as `ios-release` (integration `ORACLY Codemagic`,
`ios_signing: app_store / app.oracly`, `xcode-project use-profiles`), but no
`triggering`, no `publishing`, and the export options are pinned to
`destination=export` before `flutter build ipa`, so neither Codemagic nor
xcodebuild uploads. Outputs are artifacts only: the IPA, build logs and
`signed_ipa_check.txt`.

`tool/ios/signed_ipa_check.py` then requires: bundle `app.oracly`;
`codesign --verify --deep --strict` passing; an Apple/iPhone Distribution
leaf certificate chaining to Apple Root CA; signed `aps-environment` and App
Attest `production`, `get-task-allow` false; an unexpired App Store profile
(no device list) for `app.oracly` with production push and App Attest; the
bundled Firebase config for `app.oracly` / `oracly-7f613`; the
`app.oracly/cup_map_storage` bridge in `Runner`; valid privacy manifests
(section 4). It lists embedded SDK versions and prints no serials, profile
UUIDs, team names or Firebase keys.

Any missing signing file, wrong export method, capability or profile fails the
build: that is a BLOCKED for the Apple portal / Codemagic identities, which this
workflow never changes. A PASS is a signed-build check only, not App Review,
TestFlight or an iPhone test.

## 7. `ios-adhoc-qa-check` — Ad Hoc IPA for registered iPhones

Same as section 6 with `ios_signing: ad_hoc / app.oracly` and an Ad Hoc
export method (`ad-hoc` / `release-testing`), still pinned to
`destination=export`, no trigger, no publishing; artifacts are the IPA,
`flutter_build_adhoc_ipa.log` and `adhoc_ipa_check.txt`.
`signed_ipa_check.py --ad-hoc` applies every section-6 check except that the
profile must list registered devices (count printed, never the UDIDs) and
must not provision all devices. Starting the build with
`ORACLY_QA_DEVICE_UDIDS=<udid>[,<udid>]` also requires those devices.

Prerequisites, none verifiable from this machine (no Apple Developer or
Codemagic API access; the iPhone is paired by Bluetooth, not USB): the test
iPhone's UDID registered under Devices; an Ad Hoc distribution profile for
`app.oracly` with Push Notifications and App Attest, created after the
device was registered; that profile uploaded to Codemagic's code signing
identities. Without them the build fails at signing setup: BLOCKED.

The Ad Hoc build uses the production dart-defines, so on the iPhone it talks
to the production API (App Check App Attest) like a store build.
