"""python -m unittest discover -s tool/ios -p "test_*.py" """

import contextlib
import datetime
import io
import os
import plistlib
import re
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))

import signed_ipa_check as check  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FUTURE = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=200)
PAST = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=1)

ENTITLEMENTS = {
    'application-identifier': 'TEAMID1234.app.oracly',
    'aps-environment': 'production',
    'com.apple.developer.devicecheck.appattest-environment': 'production',
    'get-task-allow': False,
}
PROFILE = {
    'ExpirationDate': FUTURE,
    'Entitlements': dict(ENTITLEMENTS),
}
DETAILS = (
    'Executable=/x/Runner.app/Runner\nIdentifier=app.oracly\n'
    'Authority=Apple Distribution: Example (TEAMID1234)\n'
    'Authority=Apple Worldwide Developer Relations Certification Authority\n'
    'Authority=Apple Root CA\n'
)
FLUTTER_MANIFEST = {'NSPrivacyTracking': False}


def build_work(root, *, info_bundle='app.oracly', firebase=None, runner=b'..app.oracly/cup_map_storage..',
               entitlements=ENTITLEMENTS, profile=PROFILE, verify_exit=0, details=DETAILS):
    app = os.path.join(root, 'Payload', 'Runner.app')
    os.makedirs(os.path.join(app, 'Frameworks', 'Flutter.framework'))
    flutter = os.path.join(app, 'Frameworks', 'Flutter.framework')
    with open(os.path.join(flutter, 'PrivacyInfo.xcprivacy'), 'wb') as h:
        h.write(plistlib.dumps(FLUTTER_MANIFEST))
    with open(os.path.join(flutter, 'Info.plist'), 'wb') as h:
        h.write(plistlib.dumps({'CFBundleShortVersionString': '1.0'}))
    with open(os.path.join(app, 'Info.plist'), 'wb') as h:
        h.write(plistlib.dumps({'CFBundleIdentifier': info_bundle}))
    if firebase is not False:
        with open(os.path.join(app, 'GoogleService-Info.plist'), 'wb') as h:
            h.write(plistlib.dumps(firebase or {'BUNDLE_ID': 'app.oracly', 'PROJECT_ID': 'oracly-7f613'}))
    with open(os.path.join(app, 'Runner'), 'wb') as h:
        h.write(runner)
    with open(os.path.join(root, 'entitlements.plist'), 'wb') as h:
        h.write(plistlib.dumps(entitlements))
    with open(os.path.join(root, 'profile.plist'), 'wb') as h:
        h.write(plistlib.dumps(profile))
    with open(os.path.join(root, 'codesign_verify.txt'), 'w') as h:
        h.write(f'Runner.app: valid on disk\ncodesign_verify_exit={verify_exit}\n')
    with open(os.path.join(root, 'codesign_details.txt'), 'w') as h:
        h.write(details)


def run(**kwargs):
    with tempfile.TemporaryDirectory() as tmp:
        build_work(tmp, **kwargs)
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = check.main(tmp)
        return code, out.getvalue()


class SignedIpaCheckTest(unittest.TestCase):
    def test_good_signed_ipa_passes_and_says_it_is_not_approval(self):
        code, out = run()
        self.assertEqual(code, 0, out)
        self.assertIn('not App Store approval', out)
        self.assertIn('Flutter 1.0', out)

    def test_each_failure_fails_the_run(self):
        cases = {
            'bundle id': dict(info_bundle='app.other'),
            'codesign --verify': dict(verify_exit=1),
            'Distribution certificate': dict(details=DETAILS.replace('Apple Distribution', 'Apple Development')),
            'Apple Root CA': dict(details=DETAILS.replace('Authority=Apple Root CA\n', '')),
            "aps-environment is 'development'": dict(entitlements={**ENTITLEMENTS, 'aps-environment': 'development'}),
            'get-task-allow is true': dict(entitlements={**ENTITLEMENTS, 'get-task-allow': True}),
            'profile has expired': dict(profile={**PROFILE, 'ExpirationDate': PAST}),
            'lists devices': dict(profile={**PROFILE, 'ProvisionedDevices': ['00008110-000']}),
            'profile capability aps-environment': dict(profile={
                **PROFILE, 'Entitlements': {**ENTITLEMENTS, 'aps-environment': 'development'}}),
            'profile capability com.apple.developer.devicecheck.appattest-environment': dict(profile={
                **PROFILE, 'Entitlements': {
                    k: v for k, v in ENTITLEMENTS.items()
                    if k != 'com.apple.developer.devicecheck.appattest-environment'}}),
            'not bundled': dict(firebase=False),
            'another project': dict(firebase={'BUNDLE_ID': 'app.oracly', 'PROJECT_ID': 'other'}),
            'storage bridge': dict(runner=b'no channel here'),
        }
        for needle, kwargs in cases.items():
            with self.subTest(needle):
                code, out = run(**kwargs)
                self.assertEqual(code, 1, out)
                self.assertIn(needle, out)
                self.assertIn('RESULT: FAIL', out)

    def test_profile_listing_allowed_values_passes(self):
        profile = {**PROFILE, 'Entitlements': {
            **ENTITLEMENTS,
            'com.apple.developer.devicecheck.appattest-environment': ['development', 'production']}}
        self.assertEqual(run(profile=profile)[0], 0)

    def test_output_has_no_secret_like_values(self):
        _, out = run(firebase={'BUNDLE_ID': 'app.oracly', 'PROJECT_ID': 'oracly-7f613',
                               'API_KEY': 'AIzaSyFAKEFAKEFAKE'})
        self.assertNotIn('AIza', out)
        self.assertNotIn('TEAMID1234', out)

    def test_missing_app_stops(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                self.assertEqual(check.main(tmp), 1)


class WorkflowCannotUploadTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        try:
            import yaml
        except ImportError:  # pragma: no cover
            raise unittest.SkipTest('PyYAML not installed')
        with open(os.path.join(REPO, 'codemagic.yaml'), encoding='utf-8') as h:
            cls.workflows = yaml.safe_load(h)['workflows']
        cls.qa = cls.workflows['ios-signed-qa-check']
        cls.scripts = [s['script'] for s in cls.qa['scripts']]

    def test_no_trigger_or_publishing_anywhere_in_the_qa_workflow(self):
        self.assertNotIn('triggering', self.qa)
        self.assertNotIn('publishing', self.qa)

    def test_no_workflow_starts_on_its_own(self):
        for name, workflow in self.workflows.items():
            self.assertNotIn('triggering', workflow, name)

    def test_no_upload_or_submission_command(self):
        forbidden = re.compile(
            r'altool|notarytool|iTMSTransporter|app-store-connect\s+publish|\bpilot\b|fastlane|'
            r'testflight|submit|curl|wget|destination\s+string\s+upload', re.I)
        for script in self.scripts:
            self.assertIsNone(forbidden.search(script), script[:80])

    def test_export_is_pinned_to_local_before_the_build(self):
        names = [s['name'] for s in self.qa['scripts']]
        force = names.index('Force local export (never upload from xcodebuild)')
        build = names.index('Build signed IPA (artifact only)')
        self.assertLess(force, build)
        self.assertIn('Add :destination string export', self.scripts[force])

    def test_signs_with_the_existing_app_store_identity(self):
        signing = self.qa['environment']['ios_signing']
        self.assertEqual(signing, {'distribution_type': 'app_store', 'bundle_identifier': 'app.oracly'})
        self.assertEqual(self.qa['integrations'], self.workflows['ios-release']['integrations'])

    def test_checks_run_on_the_built_ipa_and_only_artifacts_leave(self):
        names = [s['name'] for s in self.qa['scripts']]
        self.assertEqual(names[-1], 'Check the signed IPA')
        self.assertIn('signed_ipa_check.py', self.scripts[-1])
        self.assertEqual(self.qa['artifacts'], [
            'build/ios/ipa/*.ipa', 'flutter_build_ipa.log', 'signed_ipa_check.txt',
            '/tmp/xcodebuild_logs/*.log'])

    def test_release_workflow_keeps_its_upload_gate(self):
        names = [s['name'] for s in self.workflows['ios-release']['scripts']]
        self.assertIn('Verify signed IPA (distribution entitlements, privacy manifests)', names)


if __name__ == '__main__':
    unittest.main()
