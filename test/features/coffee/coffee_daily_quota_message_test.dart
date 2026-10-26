/// Büyük Final Aşama 01 / F1 — what the app shows for a coffee reading the
/// server closed with `daily_quota` after the user accelerated it with gems.
/// The payload is the exact public status shape the backend's
/// toPublicStatus emits for that operation (see
/// backend/tests/coffee-daily-quota-accelerated.test.ts).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/features/reading_operation/copy/reading_live_copy.dart';
import 'package:oracly_new/features/reading_operation/models/reading_failure_code.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_codec.dart';

Map<String, dynamic> _failedQuota() => {
  'operationId': 'a' * 32,
  'readingType': 'coffee',
  'status': 'failed',
  'durable': true,
  'createdAt': '2026-10-23T21:17:00.000Z',
  'readyAt': '2026-10-23T21:17:00.000Z',
  'serverNow': '2026-10-23T21:17:08.000Z',
  'waitFinished': true,
  'remainingMs': 0,
  'resultReady': false,
  'resultId': null,
  'accelerated': true,
  'failureCode': 'daily_quota',
};

void main() {
  test('the failed operation decodes as daily_quota, with no result', () {
    final snap = const ReadingOperationCodec().parse(_failedQuota());
    expect(snap, isNotNull);
    expect(snap!.status, ReadingOperationStatus.failed);
    expect(snap.failureCode, ReadingFailureCode.dailyQuota);
    expect(snap.resultReady, isFalse);
    expect(snap.resultId, isNull);
  });

  for (final refunded in [true, false]) {
    test('the coffee quota message is shown (gems refunded: $refunded), '
        'never a generic failure or success', () {
      final line = ReadingLiveCopy.failureLine(
        wasRefunded: refunded,
        code: ReadingFailureCode.dailyQuota,
        type: ReadingType.coffee,
      );
      expect(line, ResilienceCopy.coffeeDailyQuota);
      expect(line, isNotEmpty);
      expect(line, isNot(ReadingLiveCopy.failed));
      expect(line, isNot(ReadingLiveCopy.refunded));
    });
  }
}
