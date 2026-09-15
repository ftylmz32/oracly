// ignore_for_file: prefer_function_declarations_over_variables
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_feature_runner.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_runtime_diagnostics.dart';

class _Diagnostics implements ReadingRuntimeDiagnostics {
  final events = <ReadingRuntimeDiagnostic>[];
  @override void record(ReadingRuntimeDiagnostic event) => events.add(event);
}

void main() {
  test('privacy-safe default diagnostics never throw while redacting', () {
    expect(() => const DebugReadingRuntimeDiagnostics().record(const ReadingRuntimeDiagnostic(feature: 'coffee', operationId: null, stage: 'begin', exceptionType: 'Error', safeMessage: 'Bearer: secret-token')), returnsNormally);
  });
  Map<String, dynamic> waiting() => {
        'operationId': 'a' * 32,
        'readingType': 'coffee',
        'status': 'waiting',
        'createdAt': '2026-09-08T00:00:00.000Z',
        'readyAt': '2026-09-08T02:00:00.000Z',
        'serverNow': '2026-09-08T00:00:00.000Z',
        'waitFinished': false,
        'remainingMs': 7200000,
        'resultReady': false,
        'resultId': null,
        'accelerated': false,
      };

  test('waiting does not run the feature pipeline', () async {
    var calls = 0;
    final send = (String method, String path, Map<String, Object>? body) async {
      return ReadingOperationWire(
        statusCode: 200,
        json: {'success': true, 'data': waiting()},
      );
    };
    final runner = ReadingFeatureRunner(
      flow: ReadingLiveFlow(
        operations: ReadingOperationGateway(send: send),
        acceleration: ReadingAccelerationClient(send: send),
        send: send,
      ),
    );
    final state = await runner.submit(
      readingType: ReadingType.coffee,
      sourceRequestId: 'coffee-src-01',
      runPipeline: () async {
        calls += 1;
        return 'coffee-result-1';
      },
    );
    expect(state.kind, ReadingLiveKind.waiting);
    expect(calls, 0);
  });

  test('claim race allows one pipeline execution', () async {
    var claims = 0;
    var calls = 0;
    final send = (String method, String path, Map<String, Object>? body) async {
      if (path.endsWith('/claim')) {
        claims += 1;
        return ReadingOperationWire(
          statusCode: 200,
          json: {
            'success': true,
            'data': {
              'execute': claims == 1,
              'operation': {
                ...waiting(),
                'status': 'processing',
                'waitFinished': true,
                'remainingMs': 0,
              },
            },
          },
        );
      }
      return ReadingOperationWire(
        statusCode: 200,
        json: {
          'success': true,
          'data': {
            ...waiting(),
            'status': 'processing',
            'waitFinished': true,
            'remainingMs': 0,
          },
        },
      );
    };
    final flow = ReadingLiveFlow(
      operations: ReadingOperationGateway(send: send),
      acceleration: ReadingAccelerationClient(send: send),
      send: send,
    );
    final first = await flow.claimIfEligible('a' * 32);
    final second = await flow.claimIfEligible('a' * 32);
    expect(first.execute, isTrue);
    expect(second.execute, isFalse);
    expect(calls, 0);
  });

  test('pipeline exception remains diagnostically attributable', () async {
    final diagnostics = _Diagnostics();
    final send = (String method, String path, Map<String, Object>? body) async {
      if (path.endsWith('/claim')) return ReadingOperationWire(statusCode: 200, json: {'data': {'execute': true, 'operation': {...waiting(), 'status': 'processing', 'waitFinished': true, 'remainingMs': 0}}});
      if (path.endsWith('/fail')) return const ReadingOperationWire(statusCode: 200, json: {'data': {'refunded': false}});
      return ReadingOperationWire(statusCode: 200, json: {'data': {...waiting(), 'waitFinished': true, 'remainingMs': 0}});
    };
    final runner = ReadingFeatureRunner(diagnostics: diagnostics, flow: ReadingLiveFlow(operations: ReadingOperationGateway(send: send), acceleration: ReadingAccelerationClient(send: send), send: send));
    final state = await runner.submit(readingType: ReadingType.coffee, sourceRequestId: 'source-123', runPipeline: () => throw StateError('provider response invalid'));
    expect(state.kind, ReadingLiveKind.failed);
    expect(diagnostics.events.single.stage, 'pipeline');
    expect(diagnostics.events.single.exceptionType, 'StateError');
    expect(diagnostics.events.single.feature, 'coffee');
  });

  test('completion auth failure is classified with status and backend code', () async {
    final diagnostics = _Diagnostics();
    final send = (String method, String path, Map<String, Object>? body) async {
      if (path.endsWith('/claim')) return ReadingOperationWire(statusCode: 200, json: {'data': {'execute': true, 'operation': {...waiting(), 'status': 'processing', 'waitFinished': true, 'remainingMs': 0}}});
      if (path.endsWith('/complete')) return const ReadingOperationWire(statusCode: 401, json: {'error': {'code': 'app_check_required'}});
      if (path.endsWith('/fail')) return const ReadingOperationWire(statusCode: 200, json: {'data': {'refunded': false}});
      return ReadingOperationWire(statusCode: 200, json: {'data': {...waiting(), 'waitFinished': true, 'remainingMs': 0}});
    };
    final runner = ReadingFeatureRunner(diagnostics: diagnostics, flow: ReadingLiveFlow(operations: ReadingOperationGateway(send: send), acceleration: ReadingAccelerationClient(send: send), send: send));
    await runner.submit(readingType: ReadingType.palm, sourceRequestId: 'source-456', runPipeline: () async => 'result-1');
    expect(diagnostics.events.single.stage, 'complete');
    expect(diagnostics.events.single.httpStatus, 401);
    expect(diagnostics.events.single.backendCode, 'app_check_required');
  });

  test('missing deployed operation route is attributed at begin', () async {
    final diagnostics = _Diagnostics();
    final send = (String method, String path, Map<String, Object>? body) async => const ReadingOperationWire(statusCode: 404, json: {'error': {'code': 'route_not_found'}});
    final runner = ReadingFeatureRunner(diagnostics: diagnostics, flow: ReadingLiveFlow(operations: ReadingOperationGateway(send: send), acceleration: ReadingAccelerationClient(send: send), send: send));
    final state = await runner.submit(readingType: ReadingType.soulmate, sourceRequestId: 'source-789', runPipeline: () async => 'never');
    expect(state.kind, ReadingLiveKind.failed);
    expect(diagnostics.events.single.stage, 'begin');
    expect(diagnostics.events.single.httpStatus, 404);
    expect(diagnostics.events.single.backendCode, 'route_not_found');
  });
}
