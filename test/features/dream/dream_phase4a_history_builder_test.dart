// Dream Phase 4A — deterministic history builder (A B C D G H I O).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/dream/history/dream_history_builder.dart';
import 'package:oracly_new/features/dream/history/dream_history_evidence.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';

import 'dream_phase4a_support.dart';

DreamHistoryContext _build(Dream current, List<Dream> saved,
        [String language = 'tr']) =>
    DreamHistoryBuilder.build(
      current: current,
      saved: saved,
      language: language,
    );

DreamHistoryEvidence? _door(DreamHistoryContext h) {
  for (final e in h.evidence) {
    if (e.canonicalKey == 'symbol:door') return e;
  }
  return null;
}

void main() {
  final current = savedDream('now', doorTr3, day(20));

  test('A: no prior dream → empty history', () {
    expect(_build(current, const []).isEmpty, isTrue);
    expect(_build(current, [current]).isEmpty, isTrue);
  });

  test('B: one prior match is seenBefore, never recurring', () {
    final h = _build(current, [savedDream('p1', doorTr, day(10))]);
    final door = _door(h)!;
    expect(door.level, DreamRecurrenceLevel.seenBefore);
    expect(door.priorDreamCount, 1);
    expect(door.toPayload()['level'], 'seen_before');
  });

  test('C: two distinct prior dreams → recurring, exact counts', () {
    final h = _build(current, [
      savedDream('p1', doorTr, day(10)),
      savedDream('p2', doorTr2, day(12)),
    ]);
    final door = _door(h)!;
    expect(door.level, DreamRecurrenceLevel.recurring);
    expect(door.priorDreamCount, 2);
    expect(door.totalWithCurrent, 3);
    expect(door.priorDreamIds, ['p2', 'p1']);
    expect(door.lastSeenAt, day(12));
    expect(door.firstSeenAt, day(10));
  });

  test('D: unrelated history is never sent (current evidence leads)', () {
    final unrelated = [
      savedDream('c1', catSeaTr, day(9)),
      savedDream('c2', catSeaTr, day(11)),
    ];
    expect(_build(current, unrelated).isEmpty, isTrue);
    final mixed =
        _build(current, [...unrelated, savedDream('p1', doorTr, day(10))]);
    expect([for (final e in mixed.evidence) e.canonicalKey], ['symbol:door']);
    final garden = savedDream('now', gardenTr, day(20));
    expect(_build(garden, [savedDream('p1', doorTr, day(10))]).isEmpty, isTrue);
  });

  test('later, unanalyzed and duplicate records never count', () {
    final h = _build(current, [
      savedDream('later', doorTr, day(25)),
      Dream(id: 'raw', narrative: doorTr, recordedAt: day(5)),
      savedDream('p1', doorTr, day(10)),
      savedDream('p1', doorTr, day(10)),
    ]);
    expect(_door(h)!.priorDreamCount, 1);
  });

  test('G: same emotion id saved under different app languages is one key',
      () {
    Dream felt(String id, int d) => savedDream(id, gardenTr, day(d),
        emotions: const [DreamEmotionId.fearful]);
    for (final language in ['tr', 'en', 'ru']) {
      final h = _build(felt('now', 20), [felt('a', 10), felt('b', 11)],
          language);
      final fear =
          h.evidence.singleWhere((e) => e.canonicalKey == 'emotion:fearful');
      expect(fear.level, DreamRecurrenceLevel.recurring);
      expect(fear.kind, DreamHistoryEvidenceKind.emotion);
    }
  });

  test('TR and EN words of one catalogue entry share one symbol key', () {
    final en = savedDream('now', doorEn, day(20), language: 'en');
    final h = _build(en, [savedDream('p1', doorTr, day(10))], 'en');
    expect(_door(h)!.displayLabel, 'door');
  });

  test('H: legacy localized tags never become recurrence', () {
    Dream tagged(String id, int d) => Dream(
          id: id,
          narrative: gardenTr,
          recordedAt: day(d),
          tags: const ['Kabus gördüm', 'Semboller vardı'],
          understanding: savedDream(id, gardenTr, day(d)).understanding,
        );
    final h = _build(tagged('now', 20), [tagged('a', 10), tagged('b', 11)]);
    expect(h.evidence.where((e) => e.kind == DreamHistoryEvidenceKind.entry),
        isEmpty);
    expect(jsonEncode(h.toPayload()), isNot(contains('Kabus')));
  });

  test('I: a prior dream that would safety-route today is excluded', () {
    final h = _build(current, [
      savedDream('p1', doorTr, day(10)),
      savedDream(
          'sensitive', '$doorTr2 Uyanınca kendimi öldürmek istiyorum.', day(12)),
    ]);
    expect(_door(h)!.priorDreamCount, 1);
    expect(_door(h)!.priorDreamIds, isNot(contains('sensitive')));
  });

  test('O: bounded, deterministic, small — measured with 50 priors', () {
    const rich =
        'Rüyamda kapı, anahtar, kedi, deniz ve dağ vardı; annem evde bekliyordu.';
    final now = savedDream('now', rich, DateTime(2026, 12, 1),
        emotions: const [DreamEmotionId.anxious, DreamEmotionId.curious]);
    final priors = [
      for (var i = 0; i < 50; i++)
        savedDream('p$i', rich, DateTime(2026, 1, 1).add(Duration(days: i)),
            emotions: const [DreamEmotionId.anxious]),
    ];
    final watch = Stopwatch()..start();
    final h = _build(now, priors);
    watch.stop();
    final size = utf8.encode(jsonEncode(h.toPayload())).length;
    // ignore: avoid_print
    print('PHASE4A_PERF build=${watch.elapsedMicroseconds}us bytes=$size');

    expect(h.evidence.length, DreamHistoryBuilder.maxEvidence);
    for (final e in h.evidence) {
      expect(e.priorDreamCount, lessThanOrEqualTo(DreamHistoryBuilder.maxScanned));
      expect(e.priorDreamIds.length, DreamHistoryBuilder.maxPriorIds);
      expect(e.priorDreamIds.first, 'p49');
    }
    expect(size, lessThan(1024));
    expect(jsonEncode(_build(now, priors.reversed.toList()).toPayload()),
        jsonEncode(h.toPayload()));
  });
}
