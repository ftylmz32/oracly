/// Production crash telemetry — metadata only, privacy gated.
library;

import '../data/datasources/local_storage.dart';
import '../monitoring/crashlytics.dart';
import 'app_release_info.dart';
import 'crash_feature_context.dart';
import 'crash_report.dart';
import 'crash_report_queue.dart';
import 'crash_report_sanitizer.dart';

typedef CrashTelemetryEnabled = bool Function();

class CrashTelemetryService {
  CrashTelemetryService({
    required CrashlyticsService sink,
    required LocalStorage storage,
    CrashTelemetryEnabled? isEnabled,
  })  : _sink = sink,
        _queue = CrashReportQueue(storage),
        _isEnabled = isEnabled ?? (() => true);

  final CrashlyticsService _sink;
  final CrashReportQueue _queue;
  final CrashTelemetryEnabled _isEnabled;

  Future<void> initialize() async {
    await _sink.initialize();
    await flushQueue();
  }

  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
    String? operation,
  }) async {
    if (!_isEnabled()) return;
    final report = _buildReport(
      errorCode: CrashReportSanitizer.safeErrorCode(error),
      stack: stack,
      fatal: fatal,
      operation: operation,
      networkClass: CrashReportSanitizer.networkClass(error),
    );
    await _dispatch(
      report: report,
      error: error,
      stack: stack,
      fatal: fatal,
    );
  }

  Future<void> recordSevere({
    required String operation,
    required String errorCategory,
    StackTrace? stack,
  }) async {
    if (!_isEnabled()) return;
    final trace = stack ?? StackTrace.current;
    final report = _buildReport(
      errorCode: errorCategory,
      stack: trace,
      fatal: false,
      operation: operation,
    );
    await _dispatch(
      report: report,
      error: StateError(errorCategory),
      stack: trace,
      fatal: false,
    );
  }

  Future<void> flushQueue() async {
    if (!_isEnabled()) return;
    final pending = _queue.peek();
    if (pending.isEmpty) return;
    final remaining = <CrashReport>[];
    for (final report in pending) {
      if (await _upload(report)) continue;
      remaining.add(report);
    }
    await _queue.replaceAll(remaining);
  }

  CrashReport _buildReport({
    required String errorCode,
    required StackTrace stack,
    required bool fatal,
    String? operation,
    String? networkClass,
  }) {
    final ctx = CrashFeatureContext.snapshot();
    return CrashReport(
      timestamp: DateTime.now().toUtc(),
      version: AppReleaseInfo.version,
      buildNumber: AppReleaseInfo.buildNumber,
      platform: AppReleaseInfo.platform,
      deviceCategory: AppReleaseInfo.deviceCategory,
      errorCode: errorCode,
      stackTrace: CrashReportSanitizer.safeStack(stack),
      fatal: fatal,
      feature: ctx['feature'],
      stage: ctx['stage'],
      operation: operation,
      networkClass: networkClass,
    );
  }

  Future<void> _dispatch({
    required CrashReport report,
    required Object error,
    required StackTrace stack,
    required bool fatal,
  }) async {
    if (!await _upload(report, error: error, stack: stack, fatal: fatal)) {
      await _queue.enqueue(report);
    }
  }

  Future<bool> _upload(
    CrashReport report, {
    Object? error,
    StackTrace? stack,
    bool fatal = false,
  }) async {
    try {
      _sink.recordReport(
        report,
        error: error,
        stack: stack,
        fatal: fatal,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
