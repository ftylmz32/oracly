"""python -m unittest discover -s tool/ios -p "test_*.py" """

import contextlib
import io
import os
import plistlib
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))

import privacy_manifests  # noqa: E402
import signed_entitlements  # noqa: E402

DIST = {
    'application-identifier': 'TEAMID1234.app.oracly',
    'aps-environment': 'production',
    'com.apple.developer.devicecheck.appattest-environment': 'production',
    'get-task-allow': False,
}
FLUTTER_MANIFEST = {
    'NSPrivacyTracking': False,
    'NSPrivacyAccessedAPITypes': [{
        'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryFileTimestamp',
        'NSPrivacyAccessedAPITypeReasons': ['0A2A.1', 'C617.1'],
    }],
}


def quiet(fn, *args):
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        code = fn(*args)
    return code, out.getvalue()


class SignedEntitlementsTest(unittest.TestCase):
    def run_gate(self, entitlements, raw=None):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, 'ent.plist')
            with open(path, 'wb') as handle:
                handle.write(raw if raw is not None else plistlib.dumps(entitlements))
            return quiet(signed_entitlements.main, path)

    def test_distribution_signature_passes(self):
        code, out = self.run_gate(DIST)
        self.assertEqual(code, 0, out)

    def test_development_aps_environment_fails(self):
        code, out = self.run_gate({**DIST, 'aps-environment': 'development'})
        self.assertEqual(code, 1)
        self.assertIn("aps-environment is 'development'", out)

    def test_missing_push_entitlement_fails(self):
        ent = dict(DIST)
        del ent['aps-environment']
        self.assertEqual(self.run_gate(ent)[0], 1)

    def test_development_app_attest_fails(self):
        ent = {**DIST, 'com.apple.developer.devicecheck.appattest-environment': 'development'}
        self.assertEqual(self.run_gate(ent)[0], 1)

    def test_debuggable_signature_fails(self):
        self.assertEqual(self.run_gate({**DIST, 'get-task-allow': True})[0], 1)

    def test_other_bundle_fails(self):
        self.assertEqual(self.run_gate({**DIST, 'application-identifier': 'T.app.other'})[0], 1)

    def test_unreadable_input_fails(self):
        code, out = self.run_gate(None, raw=b'not a plist')
        self.assertEqual(code, 1)
        self.assertIn('could not be read', out)


class PrivacyManifestsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.app = os.path.join(self.tmp.name, 'Runner.app')
        os.makedirs(os.path.join(self.app, 'Frameworks'))

    def tearDown(self):
        self.tmp.cleanup()

    def framework(self, name, manifest=None, at=''):
        base = os.path.join(self.app, 'Frameworks', f'{name}.framework', at)
        os.makedirs(base, exist_ok=True)
        if manifest is not None:
            with open(os.path.join(base, 'PrivacyInfo.xcprivacy'), 'wb') as handle:
                handle.write(manifest if isinstance(manifest, bytes) else plistlib.dumps(manifest))

    def test_listed_sdks_with_manifests_pass(self):
        self.framework('Flutter', FLUTTER_MANIFEST)
        self.framework('FirebaseCore', {'NSPrivacyTracking': False}, at='FirebaseCore_Privacy.bundle')
        self.framework('audioplayers_darwin')
        code, out = quiet(privacy_manifests.check, self.app)
        self.assertEqual(code, 0, out)
        self.assertIn('note audioplayers_darwin.framework has no privacy manifest', out)

    def test_listed_sdk_without_manifest_fails(self):
        self.framework('Flutter', FLUTTER_MANIFEST)
        self.framework('FirebaseMessaging')
        code, out = quiet(privacy_manifests.check, self.app)
        self.assertEqual(code, 1)
        self.assertIn('FirebaseMessaging.framework is on Apple', out)

    def test_flutter_without_manifest_fails(self):
        self.framework('Flutter')
        self.assertEqual(quiet(privacy_manifests.check, self.app)[0], 1)

    def test_invalid_plist_fails(self):
        self.framework('Flutter', FLUTTER_MANIFEST)
        self.framework('share_plus', b'<plist><dict><key>x</key>')
        code, out = quiet(privacy_manifests.check, self.app)
        self.assertEqual(code, 1)
        self.assertIn('not a valid plist', out)

    def test_unknown_category_or_missing_reasons_fails(self):
        self.framework('Flutter', {'NSPrivacyAccessedAPITypes': [
            {'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryMadeUp',
             'NSPrivacyAccessedAPITypeReasons': ['X.1']},
            {'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryUserDefaults',
             'NSPrivacyAccessedAPITypeReasons': []},
        ]})
        code, out = quiet(privacy_manifests.check, self.app)
        self.assertEqual(code, 1)
        self.assertIn('unknown category', out)
        self.assertIn('has no reasons', out)

    def test_missing_flutter_framework_fails(self):
        self.framework('FirebaseCore', {'NSPrivacyTracking': False})
        self.assertEqual(quiet(privacy_manifests.check, self.app)[0], 1)


if __name__ == '__main__':
    unittest.main()
