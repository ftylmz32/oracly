/// Soulmate generation reliability ? no paid calls.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/soulmate_client_timeout.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_generation_policy.dart';
import 'package:oracly_new/features/premium/services/soul_mate_generation_runner.dart';
import 'package:oracly_new/features/premium/services/soul_mate_generation_session.dart';
import 'package:oracly_new/features/premium/services/soul_mate_paid_draw.dart';
import 'package:oracly_new/features/premium/services/soul_mate_result_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/false_return_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('A normal success keeps one portrait and one logical id', () async {
    final harness = await _Harness.open();
    final result = await harness.succeedOnce();
    expect(result.hasPortrait, isTrue);
    expect(harness.ids, [harness.ids.single]);
    expect(harness.calls, 1);
    final session = SoulMateGenerationSessionStore.read(harness.storage);
    expect(session?.phase, SoulMateGenerationPhase.succeeded);
  });

  test('B transient failure then one retry succeeds', () async {
    final harness = await _Harness.open();
    final result = await harness.start(
      script: [
        SoulMateDrawResult.unavailable(
          'temporary',
          failureKind: SoulMateFailureKind.temporary,
          aiKind: AiFailureKind.providerError,
        ),
        SoulMateDrawResult.success(imageBytes: [9, 9, 9]),
      ],
    );
    expect(result.hasPortrait, isTrue);
    expect(harness.calls, 2);
    expect(harness.ids.toSet(), hasLength(1));
  });

  test('C both attempts fail with an honest final error', () async {
    final harness = await _Harness.open();
    final result = await harness.start(
      script: [
        SoulMateDrawResult.unavailable(
          'openai 500',
          failureKind: SoulMateFailureKind.temporary,
          aiKind: AiFailureKind.providerError,
        ),
        SoulMateDrawResult.unavailable(
          'openai 500',
          failureKind: SoulMateFailureKind.temporary,
          aiKind: AiFailureKind.providerError,
        ),
      ],
    );
    expect(result.hasPortrait, isFalse);
    expect(harness.calls, 2);
    expect(
      SoulMatePaidDraw.messageFor(result),
      SoulMateCopy.failureTemporary,
    );
    expect(SoulMatePaidDraw.messageFor(result), isNot(contains('openai')));
  });

  test('D deterministic failure does not retry', () async {
    final harness = await _Harness.open();
    await harness.start(
      script: [
        SoulMateDrawResult.unavailable(
          'auth',
          failureKind: SoulMateFailureKind.unavailable,
          aiKind: AiFailureKind.unauthorized,
        ),
      ],
    );
    expect(harness.calls, 1);
    expect(
      SoulMateGenerationPolicy.shouldAutoRetry(
        kind: AiFailureKind.unauthorized,
        completedAttempts: 1,
        elapsed: Duration.zero,
      ),
      isFalse,
    );
  });

  test('E rapid double tap is one logical operation', () async {
    final harness = await _Harness.open();
    final gate = Completer<void>();
    final first = harness.start(hold: gate.future);
    final second = harness.start(hold: gate.future);
    expect(identical(first, second), isTrue);
    gate.complete();
    await Future.wait([first, second]);
    expect(harness.calls, 1);
    expect(harness.ids.toSet(), hasLength(1));
  });

  test('F duplicate request id does not start another paid operation', () async {
    final harness = await _Harness.open();
    final failed = await harness.start(
      script: [
        SoulMateDrawResult.unavailable(
          'down',
          failureKind: SoulMateFailureKind.temporary,
          aiKind: AiFailureKind.network,
        ),
        SoulMateDrawResult.unavailable(
          'down',
          failureKind: SoulMateFailureKind.temporary,
          aiKind: AiFailureKind.network,
        ),
      ],
    );
    expect(harness.ids.toSet(), hasLength(1));
    harness.calls = 0;
    harness.ids.clear();
    final again = await harness.start(
      script: [
        SoulMateDrawResult.success(imageBytes: [4, 4, 4]),
      ],
    );
    expect(again.hasPortrait, isTrue);
    expect(again.operationId, failed.operationId);
    expect(harness.calls, 1);
  });

  test('G navigate away and back does not fork the in-flight generation', () async {
    final harness = await _Harness.open();
    final gate = Completer<void>();
    final away = harness.start(hold: gate.future);
    expect(harness.runner.isInFlightFor('owner-a'), isTrue);
    final rejoined = harness.runner.start(
      storage: harness.storage,
      ownerId: 'owner-a',
      fingerprint: harness.fingerprint,
      fresh: true,
      name: 'Ayse',
      birthIso: '1991-04-02',
      drawOnce: harness.draw,
      now: harness.now,
    );
    expect(identical(away, rejoined), isTrue);
    gate.complete();
    await away;
    expect(harness.calls, 1);
  });

  test('H previous success survives a later failed regeneration', () async {
    final harness = await _Harness.open();
    final saved = await harness.save([7, 7, 7], recordId: 'or-soulmate-keep');
    expect(saved, isNotNull);
    await harness.start(
      fresh: true,
      script: [
        SoulMateDrawResult.unavailable(
          'later',
          failureKind: SoulMateFailureKind.temporary,
          aiKind: AiFailureKind.providerError,
        ),
        SoulMateDrawResult.unavailable(
          'later',
          failureKind: SoulMateFailureKind.temporary,
          aiKind: AiFailureKind.providerError,
        ),
      ],
    );
    final loaded = await harness.service.latestWithPortrait();
    expect(loaded?.meta.id, saved!.id);
    expect(loaded?.bytes, [7, 7, 7]);
  });

  test('I account switch cannot see or resume another user operation', () async {
    final harness = await _Harness.open();
    final gate = Completer<void>();
    final inflight = harness.start(hold: gate.future);
    expect(harness.runner.isInFlightFor('owner-a'), isTrue);
    expect(harness.runner.isInFlightFor('owner-b'), isFalse);
    expect(harness.runner.currentFor('owner-b'), isNull);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final other = await SoulMateGenerationSessionStore.readForOwner(
      harness.storage,
      'owner-b',
    );
    expect(other, isNull);
    expect(SoulMateGenerationSessionStore.read(harness.storage), isNull);
    gate.complete();
    await inflight;
  });

  test(
    'I2 session write false stops generation before any provider call',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = FalseReturnLocalStorage(
        await SharedPreferences.getInstance(),
      )..falseReturnKeys.add(SoulMateGenerationSessionStore.key);
      final runner = SoulMateGenerationRunner();
      var calls = 0;

      await expectLater(
        () => runner.start(
          storage: storage,
          ownerId: 'owner-a',
          fingerprint: 'fp-a',
          fresh: false,
          name: 'Ada',
          birthIso: '1995-03-02',
          drawOnce: (id) async {
            calls += 1;
            return SoulMateDrawResult.success(imageBytes: [1, 2, 3]);
          },
        ),
        throwsStateError,
      );

      expect(calls, 0);
      expect(SoulMateGenerationSessionStore.read(storage), isNull);
    },
  );

  test(
    'I3 foreign owner marker cleanup false blocks ownership transfer',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = FalseReturnLocalStorage(
        await SharedPreferences.getInstance(),
      );
      await SoulMateGenerationSessionStore.write(
        storage,
        const SoulMateGenerationRecord(
          ownerId: 'owner-a',
          logicalId: 'logical-a',
          fingerprint: 'fp-a',
          phase: SoulMateGenerationPhase.generating,
        ),
      );
      storage.falseReturnRemoveKeys.add(SoulMateGenerationSessionStore.key);

      await expectLater(
        SoulMateGenerationSessionStore.readForOwner(storage, 'owner-b'),
        throwsStateError,
      );

      expect(
        SoulMateGenerationSessionStore.read(storage)?.ownerId,
        'owner-a',
      );
    },
  );

  test('J rebuild does not lose a successful result', () async {
    final harness = await _Harness.open();
    final result = await harness.succeedOnce();
    final rebuilt = SoulMateGenerationRunner();
    expect(rebuilt.isInFlightFor('owner-a'), isFalse);
    expect(result.hasPortrait, isTrue);
    final saved = await harness.save(
      result.imageBytes!,
      recordId: result.operationId,
    );
    final again = await harness.save(
      result.imageBytes!,
      recordId: result.operationId,
    );
    expect(saved?.id, again?.id);
    final loaded = await harness.service.latestWithPortrait();
    expect(loaded?.bytes, result.imageBytes);
  });

  test('K visible failure hides raw internal errors', () {
    final raw = SoulMateDrawResult.unavailable(
      'HTTP 502 openai provider_error stack trace',
      failureKind: SoulMateFailureKind.temporary,
      aiKind: AiFailureKind.providerError,
    );
    final message = SoulMatePaidDraw.messageFor(raw)!;
    expect(message, SoulMateCopy.failureTemporary);
    expect(message.toLowerCase(), isNot(contains('openai')));
    expect(message, isNot(contains('502')));
    expect(message.toLowerCase(), isNot(contains('stack')));
  });

  test('L bounded retry count is locked at two', () {
    expect(SoulMateGenerationPolicy.maxAttempts, 2);
    expect(
      SoulMateGenerationPolicy.shouldAutoRetry(
        kind: AiFailureKind.timeout,
        completedAttempts: 2,
        elapsed: const Duration(seconds: 1),
      ),
      isFalse,
    );
    expect(
      SoulMateGenerationPolicy.shouldAutoRetry(
        kind: AiFailureKind.timeout,
        completedAttempts: 1,
        elapsed: const Duration(seconds: 31),
      ),
      isFalse,
    );
  });

  test('client wait stays above image abort and under Cloud Run', () {
    expect(
      SoulmateClientTimeout.wait(const Duration(seconds: 120)),
      const Duration(seconds: 135),
    );
    expect(
      SoulMateGenerationPolicy.clientWait(const Duration(seconds: 180))
          .inSeconds,
      lessThanOrEqualTo(175),
    );
  });

  test('empty portrait cannot replace a saved success', () async {
    final harness = await _Harness.open();
    await harness.save([1, 2, 3], recordId: 'keep');
    final wiped = await harness.save(const [], recordId: 'empty');
    expect(wiped, isNull);
    expect((await harness.service.latestWithPortrait())?.bytes, [1, 2, 3]);
  });
}

class _Harness {
  _Harness(this.storage, this.docs);

  final LocalStorage storage;
  final Directory docs;
  final runner = SoulMateGenerationRunner();
  final ids = <String>[];
  var calls = 0;
  var clock = DateTime.utc(2026, 9, 8);

  String get fingerprint => 'soulmate:ayse|1991-04-02||';

  SoulMateDrawRequest get request => SoulMateDrawRequest(
        name: 'Ayse',
        birthDate: DateTime.utc(1991, 4, 2),
      );

  SoulMateResultService get service => SoulMateResultService(storage);

  Future<dynamic> save(List<int> bytes, {String? recordId}) {
    return service.saveSuccessfulDraw(
      request: request,
      imageBytes: bytes,
      recordId: recordId,
      documents: docs,
    );
  }

  DateTime now() {
    final current = clock;
    clock = clock.add(const Duration(milliseconds: 20));
    return current;
  }

  static Future<_Harness> open() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-a');
    final docs = await Directory.systemTemp.createTemp('soulmate-rel');
    return _Harness(storage, docs);
  }

  Future<SoulMateDrawResult> succeedOnce() {
    return start(
      script: [
        SoulMateDrawResult.success(imageBytes: [1, 2, 3]),
      ],
    );
  }

  Future<SoulMateDrawResult> start({
    List<SoulMateDrawResult>? script,
    Future<void>? hold,
    bool fresh = false,
  }) {
    _script = script ??
        [
          SoulMateDrawResult.success(imageBytes: [1, 2, 3]),
        ];
    _hold = hold;
    return runner.start(
      storage: storage,
      ownerId: 'owner-a',
      fingerprint: fingerprint,
      fresh: fresh,
      name: 'Ayse',
      birthIso: '1991-04-02',
      drawOnce: draw,
      now: now,
    );
  }

  List<SoulMateDrawResult> _script = const [];
  Future<void>? _hold;

  Future<SoulMateDrawResult> draw(String logicalId) async {
    calls += 1;
    ids.add(logicalId);
    final hold = _hold;
    if (hold != null) await hold;
    if (_script.isEmpty) {
      return SoulMateDrawResult.unavailable(
        'empty',
        aiKind: AiFailureKind.providerError,
      );
    }
    return _script.removeAt(0);
  }
}
