/// Safe diagnostics for support — version/build; OS only on explicit share.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/app_string_tables.dart';
import 'package:oracly_new/core/telemetry/app_release_info.dart';
import 'package:oracly_new/features/help/services/support_diagnostics.dart';

void main() {
  test('DIAGNOSTIC — display shows version and build only', () {
    final lines = SupportDiagnostics.displayLines();
    expect(lines, contains('app_version: ${AppReleaseInfo.version}'));
    expect(lines, contains('build: ${AppReleaseInfo.buildNumber}'));
    final joined = lines.join('\n').toLowerCase();
    expect(joined, isNot(contains('os:')));
    expect(joined, isNot(contains('platform:')));
  });

  test('DIAGNOSTIC — share text adds device/OS after explicit copy', () {
    final share = SupportDiagnostics.shareText();
    expect(share, contains('app_version: ${AppReleaseInfo.version}'));
    expect(share, contains('build: ${AppReleaseInfo.buildNumber}'));
    expect(share, contains('platform: ${AppReleaseInfo.platform}'));
    expect(share, contains('os:'));
    expect(share, contains('device_category:'));
    expect(
      AppStringTables.lookup('tr', 'help.diagnostics_copy'),
      'Tanılama bilgisini kopyala',
    );
  });

  test('NO SECRETS — share text never includes credentials or API URLs', () {
    final share = SupportDiagnostics.shareText();
    expect(SupportDiagnostics.looksSafe(share), isTrue);
    for (final marker in SupportDiagnostics.forbiddenMarkers) {
      expect(
        share.toLowerCase(),
        isNot(contains(marker.toLowerCase())),
        reason: 'must not contain $marker',
      );
    }
    expect(share.toLowerCase(), isNot(contains('http://')));
    expect(share.toLowerCase(), isNot(contains('https://')));
    expect(share, isNot(contains('Authorization')));
    expect(share, isNot(contains('proxyUrl')));
  });

  test('NO SECRETS — display lines are also scrubbed of secrets', () {
    final display = SupportDiagnostics.displayLines().join('\n');
    expect(SupportDiagnostics.looksSafe(display), isTrue);
  });
}
