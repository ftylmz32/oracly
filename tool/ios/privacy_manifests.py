"""Lists and validates the privacy manifests inside a built Runner.app.

Usage (macOS, after `flutter build ios` or on an unzipped IPA):
  python3 tool/ios/privacy_manifests.py build/ios/iphoneos/Runner.app

Fails when a manifest is not a valid plist, declares an unknown required-
reason category or a category without reasons, when Flutter.framework has no
manifest, or when an embedded framework named on Apple's list of commonly
used SDKs (which must ship their own manifest) has none inside it. Every
other framework without one is listed, not failed. Runner itself has no
manifest by design (docs/release/IOS_PRIVACY_AUDIT.md): app code calls no
required-reason API.
"""

import os
import plistlib
import sys

CATEGORIES = {
    'NSPrivacyAccessedAPICategoryFileTimestamp',
    'NSPrivacyAccessedAPICategorySystemBootTime',
    'NSPrivacyAccessedAPICategoryDiskSpace',
    'NSPrivacyAccessedAPICategoryActiveKeyboards',
    'NSPrivacyAccessedAPICategoryUserDefaults',
}

# Apple, "Upcoming third-party SDK requirements": the SDKs this app can embed.
APPLE_LISTED = {
    'Flutter', 'FirebaseAuth', 'FirebaseCore', 'FirebaseCoreExtension',
    'FirebaseCoreInternal', 'FirebaseInstallations', 'FirebaseMessaging',
    'GoogleDataTransport', 'GoogleUtilities', 'nanopb', 'FBLPromises',
    'Promises', 'GTMSessionFetcher', 'flutter_local_notifications',
    'image_picker_ios', 'share_plus', 'url_launcher_ios',
}


def manifest_errors(path: str) -> list:
    try:
        with open(path, 'rb') as handle:
            data = plistlib.load(handle)
    except Exception:  # noqa: BLE001 - an unreadable manifest is an error
        return ['not a valid plist']
    if not isinstance(data, dict):
        return ['top level is not a dictionary']
    errors = []
    for entry in data.get('NSPrivacyAccessedAPITypes', []) or []:
        category = entry.get('NSPrivacyAccessedAPIType') if isinstance(entry, dict) else None
        reasons = entry.get('NSPrivacyAccessedAPITypeReasons') if isinstance(entry, dict) else None
        if category not in CATEGORIES:
            errors.append(f'unknown category {category!r}')
        elif not reasons:
            errors.append(f'{category} has no reasons')
    return errors


def check(app: str) -> int:
    if not os.path.isdir(app):
        print(f'STOP: {app} is not a directory')
        return 1
    manifests = []
    for root, _dirs, files in os.walk(app):
        if 'PrivacyInfo.xcprivacy' in files:
            manifests.append(os.path.join(root, 'PrivacyInfo.xcprivacy'))
    failed = False
    for path in sorted(manifests):
        rel = os.path.relpath(path, app)
        errors = manifest_errors(path)
        print(f"{'BAD ' if errors else 'ok  '} {rel}" + (f" ({'; '.join(errors)})" if errors else ''))
        failed |= bool(errors)

    frameworks_dir = os.path.join(app, 'Frameworks')
    frameworks = sorted(
        name[:-len('.framework')]
        for name in (os.listdir(frameworks_dir) if os.path.isdir(frameworks_dir) else [])
        if name.endswith('.framework')
    )
    for name in frameworks:
        inside = os.path.join(frameworks_dir, f'{name}.framework') + os.sep
        has = any(path.startswith(inside) for path in manifests)
        if has:
            continue
        if name in APPLE_LISTED:
            print(f'STOP {name}.framework is on Apple\'s SDK list and has no privacy manifest')
            failed = True
        else:
            print(f'note {name}.framework has no privacy manifest (not on Apple\'s SDK list)')
    if 'Flutter' not in frameworks:
        print('STOP Flutter.framework is not embedded')
        failed = True
    print(f'{len(manifests)} privacy manifests, {len(frameworks)} embedded frameworks')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(check(sys.argv[1]) if len(sys.argv) == 2 else 2)
