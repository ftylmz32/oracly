/// Maps OR'a Sor reading blobs into typed AI contexts without mixing kinds.
library;

import '../../oracle_conversation/models/oracle_reading_context.dart';
import 'reading_ai_context.dart';

abstract final class OracleContextMapper {
  OracleContextMapper._();

  static ReadingAiContext fromOracle(OracleReadingContext ctx) {
    return switch (ctx.kind) {
      OracleReadingKind.tarot => TarotAiContext(
          sessionId: ctx.sessionId,
          spreadLabel: ctx.spreadLabel,
          readingTitle: ctx.readingTitle,
          cardsSummary: ctx.cardsSummary,
          interpretationSummary: ctx.interpretationSummary,
          fullInterpretation: ctx.fullInterpretation,
          userQuestion: ctx.userQuestion,
          cardNames: ctx.cardNames,
          cardIds: ctx.cardIds,
        ),
      OracleReadingKind.dream => DreamAiContext(
          narrative: ctx.cardsSummary,
          symbols: ctx.cardNames,
          analysis: ctx.interpretationSummary,
          fullInterpretation: ctx.fullInterpretation,
        ),
      OracleReadingKind.astrology => AstrologyAiContext(
          signLabel: ctx.spreadLabel,
          daily: ctx.interpretationSummary,
          fullInterpretation: ctx.fullInterpretation,
        ),
      OracleReadingKind.birthChart ||
      OracleReadingKind.starMap =>
        BirthChartAiContext(
          sunLabel: ctx.spreadLabel,
          interpretation: ctx.interpretationSummary,
          fullInterpretation: ctx.fullInterpretation,
        ),
      OracleReadingKind.coffee => CoffeeAiContext(
          overall: ctx.interpretationSummary,
          symbolNames: ctx.cardNames,
          fullInterpretation: ctx.fullInterpretation,
        ),
      OracleReadingKind.palm => _palm(ctx),
      OracleReadingKind.dailyMessage ||
      OracleReadingKind.discoveryJournal ||
      OracleReadingKind.soulMate => DreamAiContext(
          narrative: ctx.cardsSummary,
          symbols: ctx.cardNames,
          analysis: ctx.interpretationSummary,
          fullInterpretation: ctx.fullInterpretation,
        ),
    };
  }

  static PalmAiContext _palm(OracleReadingContext ctx) {
    final full = ctx.fullInterpretation ?? '';
    return PalmAiContext(
      sessionId: ctx.sessionId,
      overall: ctx.interpretationSummary,
      handLabel: ctx.spreadLabel.trim().isEmpty ? null : ctx.spreadLabel,
      symbols: ctx.cardNames,
      fullInterpretation: ctx.fullInterpretation,
      takeaway: _after(full, 'En önemli işaret:'),
      heartLine: _after(full, 'Kalp:'),
      headLine: _after(full, 'Zihin:'),
      lifeLine: _after(full, 'Yaşam:'),
      fateLine: _after(full, 'Yön:'),
      themes: _listAfter(full, 'Temalar:'),
    );
  }

  static String? _after(String full, String label) {
    for (final block in full.split('\n\n')) {
      final line = block.trim();
      if (!line.startsWith(label)) continue;
      final value = line.substring(label.length).trim();
      return value.isEmpty ? null : value;
    }
    return null;
  }

  static List<String> _listAfter(String full, String label) {
    final raw = _after(full, label);
    if (raw == null) return const [];
    return [
      for (final part in raw.split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }
}
