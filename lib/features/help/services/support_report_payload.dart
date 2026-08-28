/// Safe support payload — feature, error category, version. No reading text.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/telemetry/app_release_info.dart';
import '../models/support_category.dart';

class SupportReportPayload {
  const SupportReportPayload({
    required this.feature,
    required this.errorCategory,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.locale,
  });

  final String feature;
  final String errorCategory;
  final String appVersion;
  final String buildNumber;
  final String platform;
  final String locale;

  static const supportEmail = 'destek@oracly.app';

  factory SupportReportPayload.fromCategory(SupportCategory category) {
    return SupportReportPayload(
      feature: category.feature,
      errorCategory: category.errorCategory,
      appVersion: AppReleaseInfo.version,
      buildNumber: AppReleaseInfo.buildNumber,
      platform: AppReleaseInfo.platform,
      locale: OraclyL10n.code,
    );
  }

  factory SupportReportPayload.generalContact() {
    return SupportReportPayload(
      feature: 'general',
      errorCategory: 'contact',
      appVersion: AppReleaseInfo.version,
      buildNumber: AppReleaseInfo.buildNumber,
      platform: AppReleaseInfo.platform,
      locale: OraclyL10n.code,
    );
  }

  String get subject => 'ORACLY support · $errorCategory';

  /// Body is structured metadata only — never narrative, cards, or photos.
  String get body => [
        'feature: $feature',
        'error_category: $errorCategory',
        'app_version: $appVersion',
        'build: $buildNumber',
        'platform: $platform',
        'locale: $locale',
        '',
        '(No reading text or personal notes are included.)',
      ].join('\n');

  Uri toMailtoUri() {
    return Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
  }

  Map<String, String> toSafeMap() => {
        'feature': feature,
        'error_category': errorCategory,
        'app_version': appVersion,
        'build': buildNumber,
        'platform': platform,
        'locale': locale,
      };
}
