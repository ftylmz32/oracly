import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/star_map/services/star_map_reading_service.dart';

void main() {
  test('palm handoff passes this reading only', () {
    final ctx = OracleReadingContextSources.palm(
      PalmReading(
        id: 'p1',
        createdAt: DateTime(2026, 8, 9),
        hand: PalmHand.right,
        overall: 'Avucta sakin bir hat duruyor.',
        heartLine: 'Kalp hatti yumusak.',
        themes: const ['yakinlik'],
        symbols: const ['yildiz'],
      ),
    );
    expect(ctx.kind, OracleReadingKind.palm);
    expect(ctx.sourceLabel, contains('El'));
    expect(ctx.interpretationSummary, contains('sakin'));
    expect(ctx.fullInterpretation, contains('Kalp:'));
    expect(ctx.fullInterpretation, contains('yildiz'));
  });

  test('daily message handoff cites the day text and theme', () {
    final ctx = OracleReadingContextSources.dailyMessage(
      text: 'Bugun bir cumleyi yavas soyle.',
      dayKey: '2026-08-09',
      theme: 'sakinlik',
      sunSign: 'Aslan',
    );
    expect(ctx.kind, OracleReadingKind.dailyMessage);
    expect(ctx.fullInterpretation, contains('Bugun bir cumleyi'));
    expect(ctx.fullInterpretation, contains('sakinlik'));
    expect(ctx.fullInterpretation, contains('Aslan'));
  });

  test('discovery journal handoff stays compact', () {
    final ctx = OracleReadingContextSources.discoveryJournal(
      id: 'j1',
      title: 'OR yansimasi',
      preview: 'Kisa bir hatirlatma.',
      themes: const ['duruluk'],
      kindLabel: 'OR',
    );
    expect(ctx.kind, OracleReadingKind.discoveryJournal);
    expect(ctx.fullInterpretation, contains('OR yansimasi'));
    expect(ctx.cardNames, ['duruluk']);
  });

  test('coffee handoff keeps labeled domains', () {
    final ctx = OracleReadingContextSources.coffee(
      CoffeeReading(
        id: 'c1',
        createdAt: DateTime(2026, 8, 9),
        overall: 'Duruluk var.',
        love: 'Yakinlik.',
        career: 'Tek is.',
        money: 'Denge.',
        nearFuture: 'Yavasla.',
        takeaway: 'Sakin kal.',
        symbols: const [],
      ),
    );
    expect(ctx.fullInterpretation, contains('Aşk:'));
    expect(ctx.fullInterpretation, contains('Kariyer:'));
    expect(ctx.fullInterpretation, contains('Genel:'));
  });

  test('star map prefers opened section lines over full archive', () {
    final reading = StarMapReadingService.build(now: DateTime(2026, 8, 9));
    final ctx = OracleReadingContextSources.starMap(
      sectionLabel: 'Gokyuzu',
      reading: reading,
      sectionLines: const ['Bolum: sadece bu satir'],
    );
    expect(ctx.fullInterpretation, contains('sadece bu satir'));
    expect(ctx.fullInterpretation, contains('Kaynak: yerel yıldızname arşivi'));
    expect(
      ctx.fullInterpretation,
      isNot(contains(reading.overview.mainMessage)),
    );
  });
}
