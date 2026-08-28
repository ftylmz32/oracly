/// Safe crash metadata — no user content fields.
library;

import 'app_release_info.dart';
import 'crash_report_sanitizer.dart';

class CrashReport {
  const CrashReport({
    required this.timestamp,
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.deviceCategory,
    required this.errorCode,
    required this.stackTrace,
    required this.fatal,
    this.feature,
    this.stage,
    this.operation,
    this.networkClass,
  });

  final DateTime timestamp;
  final String version;
  final String buildNumber;
  final String platform;
  final String deviceCategory;
  final String errorCode;
  final String stackTrace;
  final bool fatal;
  final String? feature;
  final String? stage;
  final String? operation;
  final String? networkClass;

  Map<String, Object> toMetadata() => {
        'timestamp': timestamp.toUtc().toIso8601String(),
        'version': version,
        'build': buildNumber,
        'platform': platform,
        'device_category': deviceCategory,
        'error_code': errorCode,
        'fatal': fatal,
        if (feature != null) 'feature': feature!,
        if (stage != null) 'stage': stage!,
        if (operation != null) 'operation': operation!,
        if (networkClass != null) 'network_class': networkClass!,
      };

  Map<String, Object> toQueueJson() => {
        ...toMetadata(),
        'stack_trace': stackTrace,
      };

  factory CrashReport.fromQueueJson(Map<String, Object?> json) {
    return CrashReport(
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now().toUtc(),
      version: json['version'] as String? ?? AppReleaseInfo.version,
      buildNumber: json['build'] as String? ?? AppReleaseInfo.buildNumber,
      platform: json['platform'] as String? ?? AppReleaseInfo.platform,
      deviceCategory:
          json['device_category'] as String? ?? AppReleaseInfo.deviceCategory,
      errorCode: json['error_code'] as String? ?? 'unknown',
      stackTrace: CrashReportSanitizer.scrub(json['stack_trace'] as String?),
      fatal: json['fatal'] == true,
      feature: json['feature'] as String?,
      stage: json['stage'] as String?,
      operation: json['operation'] as String?,
      networkClass: json['network_class'] as String?,
    );
  }
}
