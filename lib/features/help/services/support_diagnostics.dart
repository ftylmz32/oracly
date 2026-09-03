/// Safe support diagnostics — version/build always; OS only when sharing.
library;

import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/telemetry/app_release_info.dart';
import '../../../core/telemetry/crash_report_sanitizer.dart';
import 'support_diagnostics_io.dart'
    if (dart.library.html) 'support_diagnostics_stub.dart' as os;
import '../../ai/production/ai_runtime_config.dart';

abstract final class SupportDiagnostics {
  SupportDiagnostics._();

  static String get appVersion => AppReleaseInfo.version;
  static String get build => AppReleaseInfo.buildNumber;
  static String get platform => AppReleaseInfo.platform;

  static List<String> runtimeIdentityLines() {
    final config = AiRuntimeConfig.resolve();
    if (!kDebugMode && !config.environment.isStaging) return const [];
    return [
      'environment: ${config.safeEnvironmentLabel}',
      'build_mode: ${kReleaseMode ? 'release' : kProfileMode ? 'profile' : 'debug'}',
      'ai_host: ${config.safeHostLabel}',
      'transport: ${config.safeTransportLabel}',
      'application_id: ${AppReleaseInfo.applicationId}',
      'version: ${AppReleaseInfo.version}+${AppReleaseInfo.buildNumber}',
    ];
  }

  /// Human OS label for share only — never device id or hostname.
  static String get osLabel {
    if (kIsWeb) return 'web';
    final raw = os.operatingSystemLabel();
    if (raw == null || raw.trim().isEmpty) return platform;
    return CrashReportSanitizer.scrub(raw);
  }

  /// On-screen lines — version and build only.
  static List<String> displayLines() => [
        'app_version: $appVersion',
        'build: $build',
        ...runtimeIdentityLines(),
      ];

  /// Clipboard payload after explicit user action — adds Device/OS safely.
  static String shareText() {
    final text = [
      'ORACLY diagnostics',
      'app_version: $appVersion',
      'build: $build',
      'platform: $platform',
      'os: $osLabel',
      'device_category: ${AppReleaseInfo.deviceCategory}',
      'locale: ${OraclyL10n.code}',
      ...runtimeIdentityLines(),
      '',
      '(Safe metadata only — no secrets.)',
    ].join('\n');
    return CrashReportSanitizer.scrub(text);
  }

  /// Forbidden substrings for support-safe copy — used by tests and scrubbing.
  static const forbiddenMarkers = <String>[
    'sk-',
    'bearer',
    'authorization',
    'api_key',
    'apikey',
    'openai.com',
    'ORACLY_AI_PROXY',
    'OPENAI_API_KEY',
    'proxy_url',
    'proxyUrl',
    '127.0.0.1:8787',
    'password',
    'credential',
  ];

  static bool looksSafe(String text) {
    final lower = text.toLowerCase();
    for (final marker in forbiddenMarkers) {
      if (lower.contains(marker.toLowerCase())) return false;
    }
    return true;
  }
}
