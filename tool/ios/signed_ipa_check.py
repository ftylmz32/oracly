"""All checks on a signed, unzipped ORACLY IPA.

Usage (macOS, the workflow prepares the inputs):
  python3 tool/ios/signed_ipa_check.py WORK            App Store IPA (ios-signed-qa-check)
  python3 tool/ios/signed_ipa_check.py WORK --ad-hoc   Ad Hoc IPA (ios-adhoc-qa-check)
WORK holds:
  Payload/Runner.app         the unzipped app
  entitlements.plist         codesign -d --entitlements - --xml Runner.app
  profile.plist              security cms -D -i Runner.app/embedded.mobileprovision
  codesign_verify.txt        codesign --verify --deep --strict output + exit code line
  codesign_details.txt       codesign -dvv Runner.app (stderr)

Ad Hoc: the profile must list registered devices (only their count is
printed). If ORACLY_QA_DEVICE_UDIDS is set (comma separated), each of those
UDIDs must be in the profile; their values are never printed.

Prints one line per check and a version list of embedded SDKs; prints no
certificate serials, profile UUIDs, device UDIDs, Firebase API keys or team
names. Exits 1 when any check fails.
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


def check_profile(profile, now=None, ad_hoc=False, expected_devices=()):
    """Distribution profile, not expired, production push and App Attest, no
    get-task-allow, issued for app.oracly. App Store: no device list. Ad Hoc:
    a non-empty device list (never all devices) holding expected_devices."""
    now = now or datetime.datetime.now(datetime.timezone.utc)
    problems = []
    devices = profile.get('ProvisionedDevices') or []
    if profile.get('ProvisionsAllDevices'):
        problems.append('profile provisions all devices (enterprise, not App Store / Ad Hoc)')
    if not ad_hoc and devices:
        problems.append('profile lists devices or all devices (not an App Store profile)')
    if ad_hoc:
        if not devices:
            problems.append('Ad Hoc profile lists no registered devices')
        registered = {str(d).strip().lower() for d in devices}
        missing = [d for d in expected_devices if d.strip().lower() not in registered]
        if missing:
            problems.append(f'{len(missing)} expected test device(s) not in the Ad Hoc profile')
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


def expected_devices_from_env():
    raw = os.environ.get('ORACLY_QA_DEVICE_UDIDS', '')
    return tuple(d.strip() for d in raw.split(',') if d.strip())


def main(work, ad_hoc=False):
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
        profile = _plist(os.path.join(work, 'profile.plist'))
        if ad_hoc:
            expected = expected_devices_from_env()
            results.append(('Ad Hoc provisioning profile', check_profile(
                profile, ad_hoc=True, expected_devices=expected)))
            count = len(profile.get('ProvisionedDevices') or [])
            note = f'{len(expected)} expected UDID(s) checked' if expected else 'no expected UDID given'
            print(f'info Ad Hoc profile registers {count} device(s); {note}')
        else:
            results.append(('App Store provisioning profile', check_profile(profile)))
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
    if failed:
        print('RESULT: FAIL')
    elif ad_hoc:
        print('RESULT: PASS (Ad Hoc IPA checks only; not yet installed on an iPhone)')
    else:
        print('RESULT: PASS (signed IPA checks only, not App Store approval)')
    return 1 if failed else 0


if __name__ == '__main__':
    args = sys.argv[1:]
    if len(args) == 1:
        sys.exit(main(args[0]))
    if len(args) == 2 and args[1] == '--ad-hoc':
        sys.exit(main(args[0], ad_hoc=True))
    sys.exit(2)
