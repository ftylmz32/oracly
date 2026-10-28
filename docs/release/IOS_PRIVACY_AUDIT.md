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
