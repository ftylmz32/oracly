"""Gate for a signed App Store IPA: its entitlements must be distribution ones.

Usage (macOS, after `flutter build ipa`):
  codesign -d --entitlements - --xml Payload/Runner.app > ent.plist
  python3 tool/ios/signed_entitlements.py ent.plist

Runner.entitlements keeps aps-environment=development on purpose; the App
Store distribution profile turns it into `production` when the archive is
exported. This proves that happened before anything is uploaded. Prints only
entitlement names and these non-secret values; exits 1 on any mismatch.
"""

import plistlib
import sys

BUNDLE_SUFFIX = '.app.oracly'
EXPECTED = {
    'aps-environment': 'production',
    'com.apple.developer.devicecheck.appattest-environment': 'production',
}


def problems(entitlements: dict) -> list:
    found = []
    for key, want in EXPECTED.items():
        got = entitlements.get(key)
        if got != want:
            found.append(f'{key} is {got!r}, expected {want!r}')
    app_id = entitlements.get('application-identifier')
    if not isinstance(app_id, str) or not app_id.endswith(BUNDLE_SUFFIX):
        found.append(f'application-identifier does not end with {BUNDLE_SUFFIX}')
    if entitlements.get('get-task-allow') is True:
        found.append('get-task-allow is true (development signature)')
    return found


def main(path: str) -> int:
    try:
        with open(path, 'rb') as handle:
            entitlements = plistlib.load(handle)
    except Exception:  # noqa: BLE001 - any unreadable input fails the gate
        print('STOP: signed entitlements could not be read as a plist')
        return 1
    if not isinstance(entitlements, dict):
        print('STOP: signed entitlements are not a dictionary')
        return 1
    found = problems(entitlements)
    for line in found:
        print(f'STOP: {line}')
    if found:
        return 1
    print('Signed entitlements OK: aps-environment and App Attest are production')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]) if len(sys.argv) == 2 else 2)
