/// Shared fakes for Coffee V3 client tests. Builds on the SAME shared
/// `FakeReadingOperationBackend` + `RecordingStagedTransport` every other
/// reading-operation / Coffee V2 test uses; only adds V3 observability
/// (full call log, backend V3-create rejection, server-side failure).
library;

import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';

import 'coffee_v2_test_support.dart';
import 'fake_reading_operation_backend.dart';

class RecordedCall {
  const RecordedCall(this.method, this.path, this.body);
  final String method;
  final String path;
  final Map<String, Object>? body;
}

class CoffeeV3TestTransport {
  CoffeeV3TestTransport(this.backend, {List<String>? chronology})
      : staged = RecordingStagedTransport(backend, chronology: chronology);

  final FakeReadingOperationBackend backend;
  final RecordingStagedTransport staged;
  final List<RecordedCall> calls = [];

  /// Simulates the backend's `ORACLY_COFFEE_V3_ENABLED=false`: any create
  /// carrying `coffeeCaptureContract` is refused with 400 invalid_request.
  bool rejectV3Create = false;

  /// Create fails at the transport level (no response) once.
  bool dropNextCreate = false;

  Future<ReadingOperationWire?> send(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    calls.add(RecordedCall(method, path, body == null ? null : Map.of(body)));
    final isCreate = method == 'POST' && path == '/v1/reading-operations';
    if (isCreate && dropNextCreate) {
      dropNextCreate = false;
      return null;
    }
    if (isCreate &&
        rejectV3Create &&
        (body?.containsKey('coffeeCaptureContract') ?? false)) {
      return const ReadingOperationWire(
        statusCode: 400,
        json: {
          'error': {'code': 'invalid_request'},
        },
      );
    }
    return staged.send(method, path, body);
  }

  List<RecordedCall> get creates => calls
      .where((c) => c.method == 'POST' && c.path == '/v1/reading-operations')
      .toList();

  List<RecordedCall> get stageCalls =>
      calls.where((c) => c.path.endsWith('/staged-image')).toList();

  List<String> get stagedSlots =>
      [for (final c in stageCalls) c.body?['slot'] as String];

  List<RecordedCall> get gemCalls => calls
      .where((c) => c.path.contains('/accelerate') || c.path.contains('/gems'))
      .toList();

  List<RecordedCall> get featureWideRecoveries => calls
      .where((c) => c.path.startsWith('/v1/reading-flow/active'))
      .toList();

  List<RecordedCall> get exactFetches => calls
      .where(
        (c) =>
            c.method == 'GET' &&
            RegExp(r'^/v1/reading-operations/[a-f0-9]{32}$').hasMatch(c.path),
      )
      .toList();

  /// Terminally fails an operation server-side (not refunded).
  Future<void> failServerSide(String operationId) async {
    await backend.send('POST', '/v1/reading-operations/$operationId/fail', {});
  }
}

/// Any provider touch throws — V3 client flows are zero-provider.
class NoProviderAi implements OraclyAiService {
  int calls = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('provider must not be touched: ${invocation.memberName}');
  }
}

/// A server-style completed `m2_public_v1` Coffee result (Slice 3 shape).
Map<String, dynamic> m2PublicV1Result(String overall) => {
      'coffeeResultContract': 'm2_public_v1',
      'visualObservation': '',
      'overall': overall,
      'love': '',
      'career': '',
      'money': '',
      'nearFuture': '',
      'takeaway': '',
      'symbols': <Object>[],
    };

const coffeeV3TestMessages = coffeeV2TestMessages;
