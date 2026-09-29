/// Maps OR'a Sor reading blobs into typed AI contexts without mixing kinds.
library;

import '../../../../core/l10n/l10n.dart';
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
      OracleReadingKind.starMap => BirthChartAiContext(
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

  /// Same `palm.*_title` keys the Palm source writes into fullInterpretation.
  /// All three locales are accepted so a later language bind does not drop fields.
  static const _palmLocales = ['tr', 'en', 'ru'];

  static PalmAiContext _palm(OracleReadingContext ctx) {
    final full = ctx.fullInterpretation ?? '';
    return PalmAiContext(
      sessionId: ctx.sessionId,
      overall: ctx.interpretationSummary,
      handLabel: ctx.spreadLabel.trim().isEmpty ? null : ctx.spreadLabel,
      symbols: ctx.cardNames,
      fullInterpretation: ctx.fullInterpretation,
      takeaway: _palmField(full, 'palm.takeaway_title'),
      heartLine: _palmField(full, 'palm.heart_title'),
      headLine: _palmField(full, 'palm.head_title'),
      lifeLine: _palmField(full, 'palm.life_title'),
      fateLine: _palmField(full, 'palm.fate_title'),
      themes: _palmList(full, 'palm.themes_title'),
    );
  }

  static String? _palmField(String full, String key) {
    for (final code in _palmLocales) {
      final title = OraclyL10n.t(key, languageCode: code).trim();
      if (title.isEmpty || title == key) continue;
      final value = _after(full, '$title:');
      if (value != null) return value;
    }
    return null;
  }

  static List<String> _palmList(String full, String key) {
    final raw = _palmField(full, key);
    if (raw == null) return const [];
    return [
      for (final part in raw.split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ];
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
}
