/// Compact labels for Son Analizler rows.
library;

import '../../../../core/l10n/l10n.dart';
import '../../models/dream.dart';

abstract final class DreamHistoryLabels {
  DreamHistoryLabels._();

  static String title(Dream dream) {
    final symbol = dream.understanding?.symbols;
    if (symbol != null && symbol.isNotEmpty) return symbol.first.label;
    final text = dream.narrative.trim();
    if (text.isEmpty) return OraclyL10n.t('dream.screen_title');
    if (text.length <= 28) return text;
    return '${text.substring(0, 28).trim()}…';
  }

  static String dateLabel(DateTime date, {DateTime? now}) =>
      OraclyFormat.relativeDayTime(date, now: now);
}
