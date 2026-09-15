import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/reading_operation/models/reading_acceleration.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';

void main() {
  test('timeout is reconcile, not a local gem restore', () async {
    final client = ReadingAccelerationClient(
      send: (method, path, body) async {
        expect(method, 'POST');
        expect(path, '/v1/reading-operations/${'a' * 32}/accelerate');
        expect(body, {'idempotencyKey': 'accel-key-01'});
        expect(body!.containsKey('amount'), isFalse);
        return null;
      },
    );
    final result = await client.accelerate(
      operationId: 'a' * 32,
      idempotencyKey: 'accel-key-01',
    );
    expect(result.outcome, ReadingAccelerationOutcome.reconcile);
    expect(result.balance, isNull);
  });

  test('generic 409 preserves balance and is not insufficient Gems', () async {
    final snapshots = <int>[];
    final client = ReadingAccelerationClient(
      onAuthoritativeBalance: (balance) async => snapshots.add(balance),
      send: (method, path, body) async => const ReadingOperationWire(
        statusCode: 409,
        json: {
          'success': false,
          'error': {'code': 'invalid_request'},
        },
      ),
    );
    final result = await client.accelerate(
      operationId: 'g' * 32,
      idempotencyKey: 'generic-conflict-01',
    );
    expect(result.outcome, ReadingAccelerationOutcome.reconcile);
    expect(result.outcome, isNot(ReadingAccelerationOutcome.insufficientGems));
    expect(result.balance, isNull);
    expect(snapshots, isEmpty);
  });

  test('parses insufficient gems and authoritative balance', () async {
    var calls = 0;
    final client = ReadingAccelerationClient(
      send: (method, path, body) async {
        calls += 1;
        if (method == 'POST') {
          return const ReadingOperationWire(
            statusCode: 409,
            json: {
              'success': false,
              'error': {'code': 'insufficient_gems'},
            },
          );
        }
        return const ReadingOperationWire(
          statusCode: 200,
          json: {
            'success': true,
            'data': {'balance': 4},
          },
        );
      },
    );
    final denied = await client.accelerate(
      operationId: 'b' * 32,
      idempotencyKey: 'accel-key-02',
    );
    expect(denied.outcome, ReadingAccelerationOutcome.insufficientGems);
    expect(denied.balance, 4);
    final balance = await client.fetchBalance();
    expect(balance?.balance, 4);
    expect(calls, 3);
  });

  test('idempotent success does not invent a second debit locally', () async {
    final snapshots = <int>[];
    final client = ReadingAccelerationClient(
      onAuthoritativeBalance: (balance) async => snapshots.add(balance),
      send: (method, path, body) async {
        return const ReadingOperationWire(
          statusCode: 200,
          json: {
            'success': true,
            'data': {
              'outcome': 'accelerated',
              'idempotent': true,
              'balance': 30,
              'canonicalCost': 10,
            },
          },
        );
      },
    );
    final result = await client.accelerate(
      operationId: 'c' * 32,
      idempotencyKey: 'accel-key-01',
    );
    expect(result.outcome, ReadingAccelerationOutcome.accelerated);
    expect(result.idempotent, isTrue);
    expect(result.balance, 30);
    expect(result.canonicalCost, 10);
    expect(snapshots, [30]);
  });

  test('authoritative 95 minus Coffee cost 10 publishes 85', () async {
    final snapshots = <int>[];
    final client = ReadingAccelerationClient(
      onAuthoritativeBalance: (balance) async => snapshots.add(balance),
      send: (method, path, body) async => const ReadingOperationWire(
        statusCode: 200,
        json: {
          'success': true,
          'data': {
            'outcome': 'accelerated',
            'idempotent': false,
            'balance': 85,
            'canonicalCost': 10,
            'priceToken': 'abcdef1234567890abcdef12',
          },
        },
      ),
    );
    final result = await client.accelerate(
      operationId: 'h' * 32,
      idempotencyKey: 'coffee-balance-95-85',
    );
    expect(result.balance, 85);
    expect(result.canonicalCost, 10);
    expect(snapshots, [85]);
  });

  test('balance fetch publishes the authoritative wallet snapshot', () async {
    var snapshot = -1;
    final client = ReadingAccelerationClient(
      onAuthoritativeBalance: (balance) async => snapshot = balance,
      send: (method, path, body) async => const ReadingOperationWire(
        statusCode: 200,
        json: {
          'data': {'balance': 17},
        },
      ),
    );

    expect((await client.fetchBalance())?.balance, 17);
    expect(snapshot, 17);
  });
}
