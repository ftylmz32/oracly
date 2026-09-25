/// Phase 8.1 — ReadingSession interpretation provenance envelope.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_result_mode.dart';
import 'package:oracly_new/features/tarot/services/tarot_session_interpretation_replay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ReadingSession base({
    String? interpretation,
    String? mode,
    String? source,
    String? delivery,
    String? locale,
  }) {
    return ReadingSession(
      id: 'sess_prov',
      deckId: 'rider-waite',
      spread: TarotSpreadType.threeCard,
      intention: const TarotIntention(text: 'clarity'),
      shuffleSeed: 7,
      startedAt: DateTime.utc(2026, 9, 25),
      interpretation: interpretation,
      interpretationResultMode: mode,
      interpretationSource: source,
      interpretationDeliveryKind: delivery,
      interpretationLocale: locale,
    );
  }

  test('provenance JSON roundtrip', () {
    final s = base(
      interpretation: '## Summary\nHello\n',
      mode: 'narrativeV2',
      source: 'ai',
      delivery: 'interpretation',
      locale: 'en',
    );
    final round = ReadingSession.tryFromJson(s.toJson());
    expect(round, isNotNull);
    expect(round!.interpretation, s.interpretation);
    expect(round.interpretationResultMode, 'narrativeV2');
    expect(round.interpretationSource, 'ai');
    expect(round.interpretationDeliveryKind, 'interpretation');
    expect(round.interpretationLocale, 'en');
  });

  test('missing provenance is backward compatible', () {
    final json = base(interpretation: '## Summary\nOld\n').toJson()
      ..remove('interpretationResultMode')
      ..remove('interpretationSource')
      ..remove('interpretationDeliveryKind')
      ..remove('interpretationLocale');
    final round = ReadingSession.tryFromJson(json);
    expect(round, isNotNull);
    expect(round!.interpretation, '## Summary\nOld\n');
    expect(round.interpretationResultMode, isNull);
    expect(
      TarotSessionInterpretationReplay.resultModeOf(round),
      ReadingResultMode.legacy,
    );
  });

  test('copyWith preserves provenance', () {
    final s = base(
      interpretation: 'body',
      mode: 'legacy',
      source: 'local',
      delivery: 'recovery',
      locale: 'tr',
    );
    final next = s.copyWith(flowStep: ReadingFlowStep.reading);
    expect(next.interpretationResultMode, 'legacy');
    expect(next.interpretationSource, 'local');
    expect(next.interpretationDeliveryKind, 'recovery');
    expect(next.interpretationLocale, 'tr');
  });
}
