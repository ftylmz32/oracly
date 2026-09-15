/// iOS push-notification structural readiness — no signing/account required.
///
/// Covers what can be verified from source alone: the Runner target wires a
/// real Push Notifications entitlement, the entitlement cannot silently
/// disappear from a build config, no fake Team ID/profile was introduced
/// while Apple Developer enrollment is pending, and the real (non-backup)
/// Firebase plist stays the one actually built into the project.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final pbxPath = 'ios/Runner.xcodeproj/project.pbxproj';

  test('Runner.entitlements exists and declares aps-environment', () {
    final file = File('ios/Runner/Runner.entitlements');
    expect(file.existsSync(), isTrue);
    final xml = file.readAsStringSync();
    expect(xml, contains('<key>aps-environment</key>'));
    // Xcode's own default for a not-yet-archived project. Xcode rewrites
    // this to `production` automatically at archive/export time based on
    // the distribution certificate/profile actually selected then — the
    // source-controlled value here is never a permanent lock either way.
    expect(xml, contains('<string>development</string>'));
  });

  test(
    'every Runner target build config (Debug/Release/Profile) references '
    'the entitlements file — the capability cannot silently disappear from '
    'one config while surviving in another',
    () {
      final pbx = File(pbxPath).readAsStringSync();
      final matches = RegExp(
        r'CODE_SIGN_ENTITLEMENTS = Runner/Runner\.entitlements;',
      ).allMatches(pbx).length;
      // Exactly the three Runner app configs — RunnerTests must not carry it.
      expect(matches, 3);
    },
  );

  test('no fake Team ID or provisioning profile was fabricated', () {
    final pbx = File(pbxPath).readAsStringSync();
    // Absent entirely — pending real Apple Developer enrollment/signing.
    // The pre-existing generic `CODE_SIGN_IDENTITY[sdk=iphoneos*] = "iPhone
    // Developer"` category default is not a concrete team/profile and is
    // deliberately left untouched (not asserted here).
    expect(pbx.contains('DEVELOPMENT_TEAM'), isFalse);
    expect(pbx.contains('PROVISIONING_PROFILE'), isFalse);
  });

  test('bundle id remains app.oracly on every Runner app config', () {
    final pbx = File(pbxPath).readAsStringSync();
    final runnerBundleIds = RegExp(
      r'PRODUCT_BUNDLE_IDENTIFIER = app\.oracly;',
    ).allMatches(pbx).length;
    expect(runnerBundleIds, 3);
  });

  test(
    'the Xcode project never references the placeholder-bundle backup '
    'Firebase plist — only the real GoogleService-Info.plist is built in',
    () {
      final pbx = File(pbxPath).readAsStringSync();
      expect(pbx.contains('GoogleService-Info.plist.bak'), isFalse);
      expect(pbx.contains('GoogleService-Info.plist in Resources'), isTrue);

      final real = File('ios/Runner/GoogleService-Info.plist');
      expect(real.existsSync(), isTrue);
      expect(real.readAsStringSync(), contains('<string>app.oracly</string>'));
    },
  );

  test(
    'no UIBackgroundModes remote-notification capability was added — '
    'ORACLY only sends visible, tap-to-open reading-completion pushes, '
    'never silent/background-woken delivery',
    () {
      final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(infoPlist.contains('UIBackgroundModes'), isFalse);

      final bootstrap = File(
        'lib/core/notifications/reading_push_bootstrap.dart',
      ).readAsStringSync();
      expect(bootstrap, isNot(contains('onBackgroundMessage')));
    },
  );
}
