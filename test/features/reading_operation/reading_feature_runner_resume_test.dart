/// Regression coverage for a real-device-confirmed bug: once `submit`
/// staged a Coffee/Palm operation but the operation's own server-owned
/// wait had not elapsed yet, NOTHING in the client ever re-attempted the
/// claim — an operation that later became genuinely eligible (its wait
/// simply ran out) could sit `waiting` forever, even though the server
/// would happily let it be claimed. Confirmed live: create -> 200,
/// staged-image -> 200, then the app just spun until the generic "slow
/// response" failsafe fired, because nothing ever called claim again.
///
/// `ReadingFeatureRunner.resume` is the fix's core: re-check an
/// already-created (and, for Coffee/Palm, already-staged) operation and
/// claim + execute it if eligible now, without re-staging or creating a
/// second operation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';

import '../../support/fake_reading_operation_backend.dart';

void main() {
  test('server-owned Coffee never runs the client pipeline and observes the same completed operation', () async {
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(
      backend: backend,
      serverOwnedCompletion: true,
    );
    var clientProviderCalls = 0;
    final waiting = await runner.submit(
      readingType: ReadingType.coffee,
      sourceRequestId: 'coffee-server-owned-01',
      imageBytes: List<int>.filled(9000, 1),
      mimeType: 'image/jpeg',
      runPipeline: () async {
        clientProviderCalls++;
        return 'must-not-run';
      },
    );
    expect(waiting.kind, ReadingLiveKind.waiting);
    expect(clientProviderCalls, 0);
    backend.completeServerSide(
      waiting.snapshot!.operationId,
      resultId: 'coffee_server_result_01',
    );
    final completed = await runner.resume(
      readingType: ReadingType.coffee,
      sourceRequestId: 'coffee-server-owned-01',
      runPipeline: () async {
        clientProviderCalls++;
        return 'must-not-run';
      },
    );
    expect(completed.kind, ReadingLiveKind.ready);
    expect(completed.snapshot?.operationId, waiting.snapshot?.operationId);
    expect(clientProviderCalls, 0);
  });

  test(
      'submit on a not-yet-eligible operation returns waiting and never '
      'runs the pipeline (baseline — unchanged by the fix)', () async {
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend);
    var calls = 0;

    final state = await runner.submit(
      readingType: ReadingType.coffee,
      sourceRequestId: 'coffee-resume-01',
      runPipeline: () async {
        calls += 1;
        return 'result-1';
      },
    );

    expect(state.kind, ReadingLiveKind.waiting);
    expect(calls, 0);
  });

  test(
      'THE BUG: resuming while still not eligible stays waiting and still '
      'never runs the pipeline — no duplicate/early execution', () async {
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend);
    var calls = 0;
    Future<String> runPipeline() async {
      calls += 1;
      return 'result-1';
    }

    final begun = await runner.submit(
      readingType: ReadingType.coffee,
      sourceRequestId: 'coffee-resume-02',
      runPipeline: runPipeline,
    );
    expect(begun.kind, ReadingLiveKind.waiting);

    final resumed = await runner.resume(
      readingType: ReadingType.coffee,
      sourceRequestId: 'coffee-resume-02',
      runPipeline: runPipeline,
    );

    expect(resumed.kind, ReadingLiveKind.waiting);
    expect(calls, 0);
  });

  test(
      'THE FIX: once the operation becomes eligible, resume (with the SAME '
      'sourceRequestId) claims and executes it — the missing other half of '
      'submit', () async {
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend);
    var calls = 0;
    Future<String> runPipeline() async {
      calls += 1;
      return 'result-1';
    }

    final begun = await runner.submit(
      readingType: ReadingType.coffee,
      sourceRequestId: 'coffee-resume-03',
      runPipeline: runPipeline,
    );
    expect(begun.kind, ReadingLiveKind.waiting);
    expect(calls, 0);

    // The wait elapses server-side — no client action shortens it.
    backend.immediatelyEligible = true;

    final resumed = await runner.resume(
      readingType: ReadingType.coffee,
      sourceRequestId: 'coffee-resume-03',
      runPipeline: runPipeline,
    );

    expect(resumed.kind, ReadingLiveKind.ready);
    expect(calls, 1);
    expect(resumed.snapshot?.operationId, begun.snapshot?.operationId);
  });

  test(
      'resume on an already-ready operation is a safe no-op (idempotent, '
      'never re-executes)', () async {
    final backend = FakeReadingOperationBackend();
    final runner = fakeImmediateReadingFeatureRunner(backend: backend);
    var calls = 0;
    Future<String> runPipeline() async {
      calls += 1;
      return 'result-1';
    }

    final first = await runner.submit(
      readingType: ReadingType.coffee,
      sourceRequestId: 'coffee-resume-04',
      runPipeline: runPipeline,
    );
    expect(first.kind, ReadingLiveKind.ready);
    expect(calls, 1);

    final second = await runner.resume(
      readingType: ReadingType.coffee,
      sourceRequestId: 'coffee-resume-04',
      runPipeline: runPipeline,
    );

    expect(second.kind, ReadingLiveKind.ready);
    expect(calls, 1);
  });

  test('resume on a failed operation returns failed without re-running',
      () async {
    final backend = FakeReadingOperationBackend();
    final runner = fakeImmediateReadingFeatureRunner(backend: backend);
    var calls = 0;
    Future<String> failingPipeline() async {
      calls += 1;
      throw StateError('pipeline boom');
    }

    final first = await runner.submit(
      readingType: ReadingType.coffee,
      sourceRequestId: 'coffee-resume-05',
      runPipeline: failingPipeline,
    );
    expect(first.kind, ReadingLiveKind.failed);
    expect(calls, 1);

    final second = await runner.resume(
      readingType: ReadingType.coffee,
      sourceRequestId: 'coffee-resume-05',
      runPipeline: failingPipeline,
    );

    expect(second.kind, ReadingLiveKind.failed);
    expect(calls, 1);
  });
}
