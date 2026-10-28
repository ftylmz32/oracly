"""python -m unittest discover -s tool/ios -p "test_*.py" """

import contextlib
import io
import os
import re
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(__file__))

import signed_ipa_check as check  # noqa: E402
from test_signed_qa_check import PROFILE, REPO, build_work  # noqa: E402

UDID_A = '00008110-001A2B3C4D5E6F70'
UDID_B = '00008120-0011223344556677'
AD_HOC = {**PROFILE, 'ProvisionedDevices': [UDID_A, UDID_B]}


def run_ad_hoc(profile=AD_HOC, env=None):
    with tempfile.TemporaryDirectory() as tmp:
        build_work(tmp, profile=profile)
        out = io.StringIO()
        with mock.patch.dict(os.environ, env or {}), contextlib.redirect_stdout(out):
            if env is None:
                os.environ.pop('ORACLY_QA_DEVICE_UDIDS', None)
            code = check.main(tmp, ad_hoc=True)
        return code, out.getvalue()


class AdHocProfileTest(unittest.TestCase):
    def test_ad_hoc_profile_with_registered_devices_passes(self):
        code, out = run_ad_hoc()
        self.assertEqual(code, 0, out)
        self.assertIn('ok   Ad Hoc provisioning profile', out)
        self.assertIn('registers 2 device(s); no expected UDID given', out)
        self.assertIn('RESULT: PASS (Ad Hoc IPA checks only; not yet installed on an iPhone)', out)

    def test_profile_without_devices_is_blocked(self):
        code, out = run_ad_hoc(profile=PROFILE)
        self.assertEqual(code, 1)
        self.assertIn('Ad Hoc profile lists no registered devices', out)

    def test_enterprise_all_devices_profile_fails(self):
        code, out = run_ad_hoc(profile={**AD_HOC, 'ProvisionsAllDevices': True})
        self.assertEqual(code, 1)
        self.assertIn('provisions all devices', out)

    def test_expected_device_present_passes_any_case(self):
        code, out = run_ad_hoc(env={'ORACLY_QA_DEVICE_UDIDS': f' {UDID_A.lower()} '})
        self.assertEqual(code, 0, out)
        self.assertIn('1 expected UDID(s) checked', out)

    def test_expected_device_missing_fails_without_printing_any_udid(self):
        other = '00008130-00AABBCCDDEEFF00'
        code, out = run_ad_hoc(env={'ORACLY_QA_DEVICE_UDIDS': f'{UDID_A},{other}'})
        self.assertEqual(code, 1)
        self.assertIn('1 expected test device(s) not in the Ad Hoc profile', out)
        for udid in (UDID_A, UDID_B, other):
            self.assertNotIn(udid, out)
            self.assertNotIn(udid.lower(), out)

    def test_development_signed_ad_hoc_still_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            build_work(tmp, profile=AD_HOC, details='Authority=Apple Development: X\nAuthority=Apple Root CA\n')
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(check.main(tmp, ad_hoc=True), 1)

    def test_app_store_mode_still_rejects_a_device_list(self):
        with tempfile.TemporaryDirectory() as tmp:
            build_work(tmp, profile=AD_HOC)
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                self.assertEqual(check.main(tmp), 1)
            self.assertIn('not an App Store profile', out.getvalue())


class AdHocWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        try:
            import yaml
        except ImportError:  # pragma: no cover
            raise unittest.SkipTest('PyYAML not installed')
        with open(os.path.join(REPO, 'codemagic.yaml'), encoding='utf-8') as h:
            cls.workflows = yaml.safe_load(h)['workflows']
        cls.wf = cls.workflows['ios-adhoc-qa-check']
        cls.names = [s['name'] for s in cls.wf['scripts']]
        cls.scripts = [s['script'] for s in cls.wf['scripts']]

    def test_no_trigger_publishing_or_upload_path(self):
        self.assertNotIn('triggering', self.wf)
        self.assertNotIn('publishing', self.wf)
        forbidden = re.compile(
            r'altool|notarytool|iTMSTransporter|app-store-connect\s+publish|\bpilot\b|fastlane|'
            r'testflight|submit|curl|wget|destination\s+string\s+upload', re.I)
        for script in self.scripts:
            self.assertIsNone(forbidden.search(script), script[:80])

    def test_signs_ad_hoc_for_app_oracly(self):
        self.assertEqual(self.wf['environment']['ios_signing'],
                         {'distribution_type': 'ad_hoc', 'bundle_identifier': 'app.oracly'})

    def test_export_is_local_ad_hoc_before_the_build(self):
        force = self.names.index('Force local export (never upload from xcodebuild)')
        build = self.names.index('Build Ad Hoc IPA (artifact only)')
        self.assertLess(force, build)
        self.assertIn('Add :destination string export', self.scripts[force])
        self.assertIn('ad-hoc|release-testing) ;;', self.scripts[force])
        self.assertNotIn('app-store', self.scripts[force].split('case')[1])

    def test_checks_run_in_ad_hoc_mode_and_only_artifacts_leave(self):
        self.assertEqual(self.names[-1], 'Check the Ad Hoc IPA')
        self.assertIn('signed_ipa_check.py "$WORK" --ad-hoc', self.scripts[-1])
        self.assertEqual(self.wf['artifacts'], [
            'build/ios/ipa/*.ipa', 'flutter_build_adhoc_ipa.log', 'adhoc_ipa_check.txt',
            '/tmp/xcodebuild_logs/*.log'])

    def test_app_store_qa_workflow_is_untouched(self):
        qa = self.workflows['ios-signed-qa-check']
        self.assertEqual(qa['environment']['ios_signing']['distribution_type'], 'app_store')
        self.assertIn('signed_ipa_check.py "$WORK" | tee signed_ipa_check.txt', qa['scripts'][-1]['script'])


if __name__ == '__main__':
    unittest.main()
