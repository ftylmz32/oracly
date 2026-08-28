/// Help support — real categories, privacy-safe payloads.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/app_string_tables.dart';
import 'package:oracly_new/core/telemetry/app_release_info.dart';
import 'package:oracly_new/features/help/copy/help_copy.dart';
import 'package:oracly_new/features/help/models/support_category.dart';
import 'package:oracly_new/features/help/services/support_report_payload.dart';

void main() {
  test('SUPPORT — all predefined categories are labeled and wired', () {
    expect(SupportCategory.values, hasLength(6));
    for (final category in SupportCategory.values) {
      expect(HelpCopy.category(category).trim(), isNotEmpty);
      expect(category.errorCategory, isNot(contains(' ')));
      expect(category.feature.trim(), isNotEmpty);
      expect(AppStringTables.all.containsKey(category.labelKey), isTrue);
    }
    expect(AppStringTables.lookup('tr', 'help.report'), contains('Sorun'));
    expect(AppStringTables.lookup('tr', 'help.contact'), contains('Ulaş'));
    expect(AppStringTables.lookup('tr', 'help.title'), 'Yardım');
  });

  test('SUPPORT — report payload includes feature category version', () {
    final payload = SupportReportPayload.fromCategory(SupportCategory.tarot);
    final map = payload.toSafeMap();
    expect(map['feature'], 'tarot');
    expect(map['error_category'], 'tarot');
    expect(map['app_version'], AppReleaseInfo.version);
    expect(map['build'], AppReleaseInfo.buildNumber);
    expect(payload.toMailtoUri().scheme, 'mailto');
    expect(payload.toMailtoUri().path, SupportReportPayload.supportEmail);
  });

  test('PRIVACY — payload never carries reading or personal content', () {
    for (final category in SupportCategory.values) {
      final payload = SupportReportPayload.fromCategory(category);
      final blob = '${payload.body}\n${payload.toSafeMap()}';
      expect(blob.toLowerCase(), isNot(contains('narrative')));
      expect(blob.toLowerCase(), isNot(contains('imagebase64')));
      expect(blob.toLowerCase(), isNot(contains('password')));
      expect(blob, isNot(contains('card')));
      expect(payload.toSafeMap().keys, everyElement(isNot(contains('text'))));
      expect(payload.toSafeMap().keys, everyElement(isNot(contains('note'))));
      expect(payload.body, contains('No reading text'));
    }
  });

  test('PRIVACY — contact mail stays metadata-only', () {
    final payload = SupportReportPayload.generalContact();
    expect(payload.feature, 'general');
    expect(payload.errorCategory, 'contact');
    expect(payload.body, isNot(contains('@')));
    expect(payload.toSafeMap().containsKey('email'), isFalse);
  });
}
