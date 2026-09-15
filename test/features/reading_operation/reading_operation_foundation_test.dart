import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_clock.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_codec.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';

void main() {
  const clock = ReadingOperationClock();
  const codec = ReadingOperationCodec();

  test('countdown uses server sync and monotonic elapsed, not device now', () {
    final readyAt = DateTime.utc(2026, 9, 8, 1);
    final serverNow = DateTime.utc(2026, 9, 8, 0);
    final remaining = clock.displayRemaining(
      readyAt: readyAt,
      serverNowAtSync: serverNow,
      elapsedSinceSync: const Duration(minutes: 15),
    );
    expect(remaining, const Duration(minutes: 45));
    expect(
      clock.displayRemaining(
        readyAt: readyAt,
        serverNowAtSync: serverNow,
        elapsedSinceSync: const Duration(hours: 2),
      ),
      Duration.zero,
    );
    expect(
      clock.offsetFromServer(
        serverNow: serverNow,
        observedLocalNow: DateTime.utc(2026, 9, 8, 3),
      ),
      const Duration(hours: -3),
    );
  });

  test('parser keeps wait finished distinct from result ready', () {
    final waiting = codec.parse({
      'operationId': 'a' * 32,
      'readingType': 'coffee',
      'status': 'waiting',
      'createdAt': '2026-09-08T00:00:00.000Z',
      'readyAt': '2026-09-08T02:00:00.000Z',
      'serverNow': '2026-09-08T02:00:00.000Z',
      'waitFinished': true,
      'remainingMs': 0,
      'resultReady': false,
      'resultId': null,
    });
    expect(waiting, isNotNull);
    expect(waiting!.status, ReadingOperationStatus.waiting);
    expect(waiting.waitFinished, isTrue);
    expect(waiting.resultReady, isFalse);
    expect(waiting.operationFailed, isFalse);

    expect(
      codec.parse({
        'operationId': 'b' * 32,
        'readingType': 'palm',
        'status': 'ready',
        'createdAt': '2026-09-08T00:00:00.000Z',
        'readyAt': '2026-09-08T02:00:00.000Z',
        'serverNow': '2026-09-08T02:00:00.000Z',
        'waitFinished': true,
        'remainingMs': 0,
        'resultReady': true,
        'resultId': null,
      }),
      isNull,
    );
    expect(
      codec.parse({
        'operationId': 'c' * 32,
        'readingType': 'soulmate',
        'status': 'failed',
        'createdAt': '2026-09-08T00:00:00.000Z',
        'readyAt': '2026-09-08T02:00:00.000Z',
        'serverNow': '2026-09-08T02:00:00.000Z',
        'waitFinished': true,
        'remainingMs': 0,
        'resultReady': false,
        'resultId': null,
        'failureCode': 'unavailable',
      })?.failureCode.name,
      'unavailable',
    );
    expect(
      codec.parse({
        'operationId': 'c' * 32,
        'readingType': 'soulmate',
        'status': 'waiting',
        'createdAt': '2026-09-08T00:00:00.000Z',
        'readyAt': '2026-09-08T02:00:00.000Z',
        'serverNow': '2026-09-08T02:00:00.000Z',
        'waitFinished': true,
        'remainingMs': 0,
        'resultReady': false,
        'resultId': null,
        'failureCode': 'unavailable',
      }),
      isNull,
    );
  });

  test('gateway create and fetch do not treat transport loss as failed', () async {
    final gateway = ReadingOperationGateway(
      send: (method, path, body) async {
        if (method == 'POST') {
          expect(body, {
            'readingType': 'soulmate',
            'sourceRequestId': 'source-req1',
            'language': 'tr',
          });
          expect(body!.containsKey('readyAt'), isFalse);
          return ReadingOperationWire(
            statusCode: 200,
            json: {
              'success': true,
              'data': {
                'operationId': 'd' * 32,
                'readingType': 'soulmate',
                'status': 'waiting',
                'createdAt': '2026-09-08T00:00:00.000Z',
                'readyAt': '2026-09-08T08:00:00.000Z',
                'serverNow': '2026-09-08T00:00:00.000Z',
                'waitFinished': false,
                'remainingMs': 28800000,
                'resultReady': false,
                'resultId': null,
              },
            },
          );
        }
        return const ReadingOperationWire(statusCode: 503, json: null);
      },
    );
    final created = await gateway.create(
      readingType: ReadingType.soulmate,
      sourceRequestId: 'source-req1',
    );
    expect(created.snapshot?.status, ReadingOperationStatus.waiting);
    expect(created.isTransportFailure, isFalse);
    final fetched = await gateway.fetch('d' * 32);
    expect(fetched.isTransportFailure, isTrue);
    expect(fetched.snapshot, isNull);
  });
}
