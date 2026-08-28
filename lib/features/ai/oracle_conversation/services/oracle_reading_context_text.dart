/// Minimal tarot context for OR'a Sor — question, spread, cards, short summary.
library;

import '../../../../core/l10n/l10n.dart';
import '../../../tarot/domain/models/reading_session.dart';
import '../../../tarot/presentation/widgets/ai_reading/ai_reading_content.dart';

abstract final class OracleReadingContextText {
  OracleReadingContextText._();

  static String cardsSummaryFor(ReadingSession session) =>
      session.drawnCards.map(_cardLine).join('\n');

  static List<int> cardIdsFor(ReadingSession session) =>
      session.drawnCards.map((d) => d.card.id).toList();

  static String shortSummary(String text, {int maxLen = 320}) {
    final trimmed = text.trim();
    if (trimmed.length <= maxLen) return trimmed;
    return '${trimmed.substring(0, maxLen).trimRight()}…';
  }

  static String summaryFromContent(AiReadingContent content) =>
      shortSummary(content.generalMeaning.trim());

  /// Local topic id → short display label for handoff (never a dump).
  static String? topicLabel(String? raw) {
    final key = (raw ?? '').trim().toLowerCase();
    if (key.isEmpty) return null;
    return switch (key) {
      'love' || 'aşk' || 'ask' => OraclyL10n.t('tarot.love'),
      'career' || 'kariyer' || 'work' => OraclyL10n.t('tarot.career'),
      'daily' || 'günlük' || 'gunluk' => OraclyL10n.t('tarot.daily'),
      'general' || 'genel' => OraclyL10n.t('tarot.general'),
      _ => raw!.trim(),
    };
  }

  static String tarotSourceLabel({String? topic}) {
    final label = topicLabel(topic);
    if (label == null || label.isEmpty) return 'Tarot';
    return 'Tarot · $label';
  }

  static String _cardLine(TarotDrawnCard drawn) {
    final orientation = drawn.isReversed
        ? OraclyL10n.t('tarot.reversed')
        : OraclyL10n.t('tarot.upright');
    return '${drawn.localizedPosition} · id:${drawn.card.id} · '
        '${drawn.localizedName} · $orientation';
  }
}
