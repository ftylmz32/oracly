// Dream Phase 4A — service flow: history reaches the provider only as
// grounded structure, is recomputed on every read, and follows identity.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/dream_request_identity.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/safety/dream_safety_concern.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';

import '../../support/dream_test_owner.dart';
import 'dream_honesty_fakes.dart';
import 'dream_phase2_support.dart';
import 'dream_phase4a_support.dart';

class _CountingRepo extends MemDreamRepository {
  int reads = 0;

  @override
  Future<List<DreamRecord>> getAll() {
    reads++;
    return super.getAll();
  }
}

/// Fails its first [failures] calls, as a timed-out paid attempt would —
/// nothing is saved, so the retry sees the same history.
class _FailingFirstAi extends ScriptedDreamAi {
  _FailingFirstAi({required this.failures}) : super.grounded();

  final int failures;

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) {
    if (contexts.length < failures) {
      contexts.add(context);
      return Future.value(AiOutcome.failure(AiFailure.invalidResponse()));
    }
    return super.analyzeDream(context);
  }
}

DateTime _past(int d) => DateTime(2021, 3, d, 9);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  late _CountingRepo repo;
  late ScriptedDreamAi ai;
  late DreamExperienceService service;

  setUp(() {
    repo = _CountingRepo();
    ai = ScriptedDreamAi.grounded();
    service = DreamExperienceService(
      repository: repo,
      owner: testDreamOwner(),
      ai: ai,
    );
  });

  List<String> kinds(List<DreamInsight> insights) =>
      [for (final i in insights) i.kind.name];

  test('A: no history → empty provider history, no section, reading intact',
      () async {
    final result = await service.analyze(narrative: phase2Narrative);
    expect(ai.contexts.single.history, isEmpty);
    expect(kinds(result.dream.insights), isNot(contains('recurringPattern')));
    expect(result.dream.fromAi, isTrue);
  });

  test('C/D: recurring evidence is sent as structure; unrelated is not',
      () async {
    await seed(repo, [
      savedDream('p1', doorTr, _past(1)),
      savedDream('p2', doorTr2, _past(2)),
      savedDream('p3', catSeaTr, _past(3)),
    ]);
    final result = await service.analyze(narrative: doorTr3);
    final sent = ai.contexts.single.history;
    expect(sent, [
      {
        'kind': 'symbol',
        'key': 'symbol:door',
        'label': 'Kapı',
        'level': 'recurring',
        'priorCount': 2,
      },
    ]);
    final wire = jsonEncode(sent);
    for (final prior in [doorTr, doorTr2, catSeaTr]) {
      expect(wire, isNot(contains(prior)));
    }
    expect(ai.contexts.single.memorySummary, isNull);
    final section = result.dream.insights
        .singleWhere((i) => i.kind == DreamInsightKind.recurringPattern);
    expect(section.source, DreamInsightSource.local);
    expect(section.body, contains('3'));
    final stored = await repo.getById(result.dream.id);
    expect(jsonEncode(stored!.payload), isNot(contains('recurringPattern')));
  });

  test('E/K: deleting a prior removes it everywhere — no ghost recurrence',
      () async {
    await seed(repo, [
      savedDream('p1', doorTr, _past(1)),
      savedDream('p2', doorTr2, _past(2)),
    ]);
    final first = await service.analyze(narrative: doorTr3);
    expect(ai.contexts.last.history.single['level'], 'recurring');

    await repo.delete('p1');
    final reopened = await service.loadOwnedDream(first.dream.id);
    final section = reopened!.insights
        .singleWhere((i) => i.kind == DreamInsightKind.recurringPattern);
    expect(section.title, OraclyL10n.t('dream.history.title.seen'));

    await service.reinterpret(first.dream);
    expect(ai.contexts.last.history.single['level'], 'seen_before');
    expect(ai.contexts.last.history.single['priorCount'], 1);
  });

  test('L/M: exact retry keeps identity; new prior evidence changes it',
      () async {
    final flaky = _FailingFirstAi(failures: 2);
    final retrying = DreamExperienceService(
      repository: repo,
      owner: testDreamOwner(),
      ai: flaky,
    );
    await seed(repo, [savedDream('p1', doorTr, _past(1))]);
    for (var i = 0; i < 2; i++) {
      await expectLater(retrying.analyze(narrative: doorTr3),
          throwsA(isA<AiRequestException>()));
    }
    final ids = flaky.contexts.map(DreamRequestIdentity.fingerprint).toList();
    expect(ids[0], ids[1]);
    expect(flaky.contexts[0].history.single['level'], 'seen_before');

    await seed(repo, [savedDream('p2', doorTr2, _past(2))]);
    await retrying.analyze(narrative: doorTr3);
    expect(flaky.contexts.last.history.single['level'], 'recurring');
    expect(DreamRequestIdentity.fingerprint(flaky.contexts.last),
        isNot(ids[0]));
  });

  test('J: sensitive current dream routes to safety before any history read',
      () async {
    await seed(repo, [savedDream('p1', doorTr, _past(1))]);
    repo.reads = 0;
    await expectLater(
      service.analyze(narrative: '$doorTr3 Uyanınca kendimi öldürmek istiyorum.'),
      throwsA(isA<DreamSafetyException>()),
    );
    expect(repo.reads, 0);
    expect(ai.contexts, isEmpty);
  });

  test('privacy clear: no recurrence survives in history or identity',
      () async {
    await seed(repo, [
      savedDream('p1', doorTr, _past(1)),
      savedDream('p2', doorTr2, _past(2)),
    ]);
    await service.analyze(narrative: doorTr3);
    final withHistory = DreamRequestIdentity.fingerprint(ai.contexts.last);
    for (final record in await repo.getAll()) {
      await repo.delete(record.id);
    }
    await service.analyze(narrative: doorTr3);
    expect(ai.contexts.last.history, isEmpty);
    expect(DreamRequestIdentity.fingerprint(ai.contexts.last),
        isNot(withHistory));
  });
}
