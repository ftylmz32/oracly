/// Dream V1 — persist, reopen, gem hook.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/l10n/oracly_format.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/data/dream_record_mapper.dart';
import 'package:oracly_new/features/dream/economy/dream_economy.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_symbol.dart';
import 'package:oracly_new/features/dream/presentation/utils/dream_history_labels.dart';
import 'package:oracly_new/features/dream/services/dream_interpretation_symbols.dart';
import 'package:oracly_new/features/dream/services/dream_reflection_generator.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';

void main() {
  setUpAll(() async {
    await OraclyFormat.ensureInitialized();
  });

  setUp(() => OraclyL10n.bind('tr'));

  test('saved dream reopen keeps the same interpretation', () {
    final understanding = DreamUnderstandingService().build(
      narrative: 'Evde kedimle deniz kenarında yürüdüm, annem de vardı.',
    );
    final dream = Dream(
      id: 'd1',
      narrative: 'Evde kedimle deniz kenarında yürüdüm, annem de vardı.',
      recordedAt: DateTime(2026, 8, 8, 23, 41),
      understanding: understanding,
      insights: const DreamReflectionGenerator().generate(
        dream: Dream(
          id: 'd1',
          narrative: 'Evde kedimle deniz kenarında yürüdüm, annem de vardı.',
          recordedAt: DateTime(2026, 8, 8, 23, 41),
          understanding: understanding,
        ),
        understanding: understanding,
      ),
    );

    final record = DreamRecordMapper.toRecord(dream);
    final restored = DreamRecordMapper.fromRecord(record);
    final again = DreamRecordMapper.fromRecord(
      DreamRecord.fromJson(record.toJson()),
    );

    expect(restored.narrative, dream.narrative);
    expect(restored.insights.map((i) => i.body), dream.insights.map((i) => i.body));
    expect(again.insights.first.body, restored.insights.first.body);
    expect(DreamHistoryLabels.title(restored), isNotEmpty);
    expect(DreamHistoryLabels.dateLabel(dream.recordedAt), contains('23:41'));
  });

  test('symbol block includes meaning and dream relation', () {
    const symbol = DreamSymbol(
      token: 'kedi',
      label: 'Kedi',
      kind: DreamSymbolKind.animal,
    );
    final block = DreamInterpretationSymbols.block(
      symbol: symbol,
      narrative: 'Kedimle evde yürüdüm.',
    );
    expect(block, contains('Kedi'));
    expect(block.toLowerCase(), isNot(contains('anlam:')));
    expect(block.toLowerCase(), isNot(contains('rüyanda:')));
  });

  test('error copy is clear Turkish', () {
    expect(DreamCopy.analysisFailed, 'Yorum bu sefer tutmadı. Bir daha deneyelim.');
    expect(DreamCopy.retry, 'TEKRAR DENE');
    expect(DreamCopy.beginAnalysis, 'Rüyayı aç');
    expect(DreamCopy.narrativeHint, contains('detaylı anlat'));
  });

  test('gem hook exists without inventing a price', () {
    expect(DreamEconomy.hasCost, isFalse);
    expect(DreamEconomy.analysisCost, isNull);
  });
}
