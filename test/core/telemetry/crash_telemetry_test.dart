import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/telemetry/crash_report.dart';
import 'package:oracly_new/core/telemetry/crash_report_queue.dart';
import 'package:oracly_new/core/telemetry/crash_report_sanitizer.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CrashReportSanitizer', () {
    test('uses type codes not raw user-facing messages', () {
      expect(
        CrashReportSanitizer.safeErrorCode(
          StateError('Bu fal hastalığımı gösteriyor mu?'),
        ),
        'StateError',
      );
    });

    test('scrubs api keys from stack traces', () {
      final cleaned = CrashReportSanitizer.scrub(
        'Error at main sk-live-secret-key-123 in foo.dart',
      );
      expect(cleaned.toLowerCase(), isNot(contains('sk-live')));
      expect(cleaned, contains('[redacted]'));
    });
  });

  group('CrashReportQueue', () {
    test('keeps only bounded number of reports', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      final queue = CrashReportQueue(storage);

      for (var i = 0; i < CrashReportQueue.maxItems + 3; i++) {
        await queue.enqueue(
          CrashReport(
            timestamp: DateTime.utc(2026, 1, 1, 0, 0, i),
            version: '1.0.0',
            buildNumber: '1',
            platform: 'android',
            deviceCategory: 'mobile',
            errorCode: 'test_$i',
            stackTrace: 'stack_$i',
            fatal: false,
          ),
        );
      }

      final items = queue.peek();
      expect(items.length, CrashReportQueue.maxItems);
      expect(items.first.errorCode, 'test_3');
      expect(items.last.errorCode, 'test_${CrashReportQueue.maxItems + 2}');
    });
  });
}
