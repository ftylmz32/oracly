"""All checks on a signed, unzipped ORACLY IPA (ios-signed-qa-check).

Usage (macOS, the workflow prepares the inputs):
  python3 tool/ios/signed_ipa_check.py WORK
WORK holds:
  Payload/Runner.app         the unzipped app
  entitlements.plist         codesign -d --entitlements - --xml Runner.app
  profile.plist              security cms -D -i Runner.app/embedded.mobileprovision
  codesign_verify.txt        codesign --verify --deep --strict output + exit code line
  codesign_details.txt       codesign -dvv Runner.app (stderr)

Prints one line per check and a version list of embedded SDKs; prints no
certificate serials, profile UUIDs, Firebase API keys or team names. Exits 1
when any check fails.
"""

import datetime
import os
import plistlib
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))

import privacy_manifests  # noqa: E402
import signed_entitlements  # noqa: E402

BUNDLE_ID = 'app.oracly'
FIREBASE_PROJECT = 'oracly-7f613'
CUP_MAP_CHANNEL = b'app.oracly/cup_map_storage'
DISTRIBUTION_AUTHORITIES = ('Apple Distribution:', 'iPhone Distribution:')
PROFILE_PRODUCTION = {
    'aps-environment': 'production',
    'com.apple.developer.devicecheck.appattest-environment': 'production',
}


def _plist(path):
    with open(path, 'rb') as handle:
        return plistlib.load(handle)


def check_bundle(app):
    info = _plist(os.path.join(app, 'Info.plist'))
    got = info.get('CFBundleIdentifier')
    return [] if got == BUNDLE_ID else [f'bundle id is {got!r}, expected {BUNDLE_ID!r}']


def check_signature(verify_text, details_text):
    problems = []
    if not re.search(r'^codesign_verify_exit=0$', verify_text, re.M):
        problems.append('codesign --verify --deep --strict failed')
    authorities = re.findall(r'^Authority=(.*)$', details_text, re.M)
    if not authorities or not authorities[0].startswith(DISTRIBUTION_AUTHORITIES):
        problems.append('leaf signing certificate is not an Apple/iPhone Distribution certificate')
    if 'Authority=Apple Root CA' not in details_text:
        problems.append('signature does not chain to Apple Root CA')
    return problems


def check_profile(profile, now=None):
    """App Store distribution profile: no device list, not expired, production
    push and App Attest, no get-task-allow, issued for app.oracly."""
    now = now or datetime.datetime.now(datetime.timezone.utc)
    problems = []
    if profile.get('ProvisionedDevices') or profile.get('ProvisionsAllDevices'):
        problems.append('profile lists devices or all devices (not an App Store profile)')
    expires = profile.get('ExpirationDate')
    if not isinstance(expires, datetime.datetime):
        problems.append('profile has no expiration date')
    else:
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=datetime.timezone.utc)
        if expires <= now:
            problems.append('profile has expired')
    ent = profile.get('Entitlements') or {}
    for key, want in PROFILE_PRODUCTION.items():
        # A profile may list the allowed values instead of a single one.
        got = ent.get(key)
        if got != want and not (isinstance(got, list) and want in got):
            problems.append(f'profile capability {key} is {ent.get(key)!r}, expected {want!r}')
    if ent.get('get-task-allow') is True:
        problems.append('profile allows get-task-allow (development profile)')
    app_id = ent.get('application-identifier')
    if not isinstance(app_id, str) or not app_id.endswith('.' + BUNDLE_ID):
        problems.append(f'profile is not issued for {BUNDLE_ID}')
    return problems


def check_firebase(app):
    path = os.path.join(app, 'GoogleService-Info.plist')
    if not os.path.isfile(path):
        return ['GoogleService-Info.plist is not bundled']
    data = _plist(path)
    problems = []
    if data.get('BUNDLE_ID') != BUNDLE_ID:
        problems.append('Firebase config is for another bundle id')
    if data.get('PROJECT_ID') != FIREBASE_PROJECT:
        problems.append('Firebase config is for another project')
    return problems


def check_cup_map_bridge(app):
    with open(os.path.join(app, 'Runner'), 'rb') as handle:
        return [] if CUP_MAP_CHANNEL in handle.read() else [
            'Fincan Haritası storage bridge (app.oracly/cup_map_storage) not in Runner']


def sdk_versions(app):
    frameworks = os.path.join(app, 'Frameworks')
    rows = []
    for name in sorted(os.listdir(frameworks)) if os.path.isdir(frameworks) else []:
        info = os.path.join(frameworks, name, 'Info.plist')
        if name.endswith('.framework') and os.path.isfile(info):
            data = _plist(info)
            rows.append((name[:-len('.framework')], data.get('CFBundleShortVersionString', '?')))
    return rows


def main(work):
    app = os.path.join(work, 'Payload', 'Runner.app')
    if not os.path.isdir(app):
        print('STOP: Payload/Runner.app missing')
        return 1

    def read(name):
        with open(os.path.join(work, name), encoding='utf-8', errors='replace') as handle:
            return handle.read()

    results = []
    try:
        results.append(('bundle id app.oracly', check_bundle(app)))
        results.append(('distribution signature', check_signature(
            read('codesign_verify.txt'), read('codesign_details.txt'))))
        results.append(('signed entitlements', signed_entitlements.problems(
            _plist(os.path.join(work, 'entitlements.plist')))))
        results.append(('App Store provisioning profile', check_profile(
            _plist(os.path.join(work, 'profile.plist')))))
        results.append(('Firebase iOS config', check_firebase(app)))
        results.append(('Fincan Haritası bridge', check_cup_map_bridge(app)))
    except (OSError, plistlib.InvalidFileException, ValueError) as error:
        print(f'STOP: input not readable ({type(error).__name__})')
        return 1

    failed = False
    for label, problems in results:
        print(f"{'FAIL' if problems else 'ok  '} {label}")
        for problem in problems:
            print(f'     - {problem}')
        failed |= bool(problems)

    print('--- privacy manifests')
    failed |= privacy_manifests.check(app) != 0
    print('--- embedded SDK versions')
    for name, version in sdk_versions(app):
        print(f'     {name} {version}')
    print('RESULT: FAIL' if failed else 'RESULT: PASS (signed IPA checks only, not App Store approval)')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]) if len(sys.argv) == 2 else 2)
