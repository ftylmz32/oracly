/// Dream Phase 1.1 — Dream-scope clear reports success only when records
/// (malformed included), memory, version chains and the attempt row were all
/// durably removed. A false write or a throw is never success.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/core/memory/oracly_memory_store.dart';
import 'package:oracly_new/core/reading_version/models/reading_version_kind.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';
import 'package:oracly_new/core/services/history_service.dart';
import 'package:oracly_new/features/dream/services/dream_attempt_store.dart';
import 'package:oracly_new/features/privacy/services/privacy_discovery_clear.dart';
import 'package:oracly_new/features/privacy/services/privacy_dream_clear.dart';

import '../birth_chart/evidence/test_birth_owner.dart';
import 'dream_phase1_support.dart';

const _keptKinds = [
  ReadingVersionKind.coffee,
  ReadingVersionKind.tarot,
  ReadingVersionKind.palm,
];

OraclyMemory _memory(String id, OraclyReadingType type) => OraclyMemory(
      id: 'reading:${type.name}:$id',
      kind: OraclyMemoryKind.reading,
      source: OraclyMemorySource(id: id, type: type, occurredAt: DateTime(2025)),
      summary: '${type.name} memory survives',
    );

Future<DreamPhase1Env> _seeded() async {
  final env = await DreamPhase1Env.open(faultable: true);
  await env.service().analyze(narrative: phase1NarrativeA);
  for (final kind in _keptKinds) {
    await env.versions.seedOriginal(
      rootId: '${kind.name}_keep',
      kind: kind,
      data: {'overall': '${kind.name} chain survives'},
    );
  }
  await env.memory.upsert(_memory('soul_keep', OraclyReadingType.soulmate));
  await env.memory.upsert(_memory('coffee_keep', OraclyReadingType.coffee));
  await DreamAttemptStore(env.storage).resolveId(phase1NarrativeA2);
  final rows = env.storage.getStringList(PrivacyDreamClear.recordsKey)!;
  await env.storage.setStringList(
    PrivacyDreamClear.recordsKey,
    [...rows, '{"malformed": "$phase1NarrativeA2"'],
  );
  expect(env.recordCount, 2);
  expect(env.dreamMemoryCount, 1);
  expect(env.versionsRaw, contains('"kind":"dream"'));
  return env;
}

bool _recordsGone(DreamPhase1Env env) => env.recordCount == 0;
bool _memoryGone(DreamPhase1Env env) => env.dreamMemoryCount == 0;
bool _versionsGone(DreamPhase1Env env) =>
    !(env.versionsRaw ?? '').contains('"kind":"dream"');
bool _attemptGone(DreamPhase1Env env) =>
    env.storage.getString(DreamAttemptStore.key) == null;

void _expectNonDreamKept(DreamPhase1Env env, {bool discovery = false}) {
  final store = ReadingVersionStore(env.storage);
  for (final kind in _keptKinds) {
    expect(store.byRootId('${kind.name}_keep'), isNotNull, reason: kind.name);
  }
  final types = env.memory.all().map((m) => m.source.type).toSet();
  expect(types, contains(OraclyReadingType.soulmate));
  if (!discovery) expect(types, contains(OraclyReadingType.coffee));
}

Future<bool> _clear(DreamPhase1Env env) =>
    PrivacyDreamClear.run(env.storage, env.memory);

void main() {
  final faults = <String, (String, bool Function(DreamPhase1Env))>{
    'records': (PrivacyDreamClear.recordsKey, _recordsGone),
    'memory': (OraclyMemoryStore.key, _memoryGone),
    'versions': (ReadingVersionStore.key, _versionsGone),
  };
  for (final MapEntry(key: name, value: (key, gone)) in faults.entries) {
    for (final throwing in [false, true]) {
      final mode = throwing ? 'throws' : 'returns false';
      test('$name write $mode → incomplete, other steps still run', () async {
        final env = await _seeded();
        (throwing ? env.faults.throwingKeys : env.faults.falseReturnKeys)
            .add(key);

        expect(await _clear(env), isFalse);
        expect(gone(env), isFalse, reason: 'fault must have fired');
        final others = [_recordsGone, _memoryGone, _versionsGone, _attemptGone]
          ..remove(gone);
        for (final check in others) {
          expect(check(env), isTrue);
        }
        _expectNonDreamKept(env);
      });
    }
  }

  for (final throwing in [false, true]) {
    test('attempt removal ${throwing ? 'throws' : 'returns false'} → '
        'incomplete', () async {
      final env = await _seeded();
      (throwing
              ? env.faults.throwingRemoveKeys
              : env.faults.falseReturnRemoveKeys)
          .add(DreamAttemptStore.key);

      expect(await _clear(env), isFalse);
      expect(_attemptGone(env), isFalse);
      expect(_recordsGone(env) && _memoryGone(env) && _versionsGone(env),
          isTrue);
    });
  }

  test('success removes records (malformed too), memory, versions, attempt',
      () async {
    final env = await _seeded();
    expect(await _clear(env), isTrue);

    expect(env.storage.getStringList(PrivacyDreamClear.recordsKey), isEmpty);
    expect(_memoryGone(env) && _versionsGone(env) && _attemptGone(env), isTrue);
    expect(env.versionsRaw ?? '', isNot(contains(phase1NarrativeA)));
    _expectNonDreamKept(env);
  });

  test('Discovery clear: Dream memory failure is reported, SoulMate kept',
      () async {
    final env = await _seeded();
    env.faults.falseReturnKeys.add(OraclyMemoryStore.key);
    Future<void> discovery() => PrivacyDiscoveryClear.run(
          storage: env.storage,
          history: HistoryService(MockHistoryRepository(env.storage)),
          birthCharts: testBirthChartRepo(env.storage, ownerId: 'owner-a'),
        );

    await expectLater(discovery(), throwsStateError);
    expect(_memoryGone(env), isFalse);

    env.faults.falseReturnKeys.clear();
    await discovery();
    expect(_recordsGone(env) && _memoryGone(env), isTrue);
    expect(_versionsGone(env) && _attemptGone(env), isTrue);
    _expectNonDreamKept(env, discovery: true);
  });
}
