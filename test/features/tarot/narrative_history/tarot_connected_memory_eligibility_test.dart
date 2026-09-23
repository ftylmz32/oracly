import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_connected_memory_eligibility.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_connected_memory_models.dart';

import 'tarot_history_test_support.dart';

void main() {
  group('TarotConnectedMemoryEligibility', () {
    final now = nowFixed;
    final base = baseRequest();

    test('90d / future / empty id / current tarot excluded', () {
      final rows = [
        connectedMemory(
          sourceId: 'ok',
          sourceType: TarotConnectedMemorySourceType.coffee,
          at: now.subtract(const Duration(days: 1)),
        ),
        connectedMemory(
          sourceId: 'exact90',
          sourceType: TarotConnectedMemorySourceType.palm,
          at: now.subtract(const Duration(days: 90)),
        ),
        connectedMemory(
          sourceId: 'old',
          sourceType: TarotConnectedMemorySourceType.dream,
          at: now.subtract(const Duration(days: 90, microseconds: 1)),
        ),
        connectedMemory(
          sourceId: 'fut',
          sourceType: TarotConnectedMemorySourceType.coffee,
          at: now.add(const Duration(seconds: 1)),
        ),
        connectedMemory(
          sourceId: '  ',
          sourceType: TarotConnectedMemorySourceType.coffee,
          at: now.subtract(const Duration(days: 1)),
        ),
        connectedMemory(
          sourceId: base.readingId,
          sourceType: TarotConnectedMemorySourceType.tarot,
          at: now.subtract(const Duration(days: 1)),
        ),
        connectedMemory(
          sourceId: base.sessionId,
          sourceType: TarotConnectedMemorySourceType.tarot,
          at: now.subtract(const Duration(days: 2)),
        ),
      ];
      final out = TarotConnectedMemoryEligibility.eligible(
        records: rows,
        base: base,
        now: now,
      );
      expect(out.map((e) => e.sourceId).toList(), ['ok', 'exact90']);
    });

    test('dedupe (type,id) newest wins; reorder identical', () {
      final t = now.subtract(const Duration(days: 1));
      final rows = [
        connectedMemory(
          sourceId: 'x',
          sourceType: TarotConnectedMemorySourceType.coffee,
          at: t.subtract(const Duration(hours: 1)),
          summary: 'older',
        ),
        connectedMemory(
          sourceId: 'x',
          sourceType: TarotConnectedMemorySourceType.coffee,
          at: t,
          summary: 'newer',
        ),
        connectedMemory(
          sourceId: 'x',
          sourceType: TarotConnectedMemorySourceType.tarot,
          at: t,
          summary: 'cross-type',
        ),
      ];
      List summarize(List input) {
        final out = TarotConnectedMemoryEligibility.eligible(
          records: List.from(input),
          base: base,
          now: now,
        );
        return out
            .map((e) => '${e.sourceType.name}:${e.sourceId}:${e.summary}')
            .toList();
      }

      final forward = summarize(rows);
      expect(forward, ['coffee:x:newer', 'tarot:x:cross-type']);
      expect(summarize(rows.reversed.toList()), forward);
    });
  });
}
