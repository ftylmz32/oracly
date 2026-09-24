/// Phase 6C.2 — theme + memory evidence scalar checks.
library;

import '../evidence/narrative_request.dart';
import 'narrative_tarot_prompt_scalars.dart';

abstract final class NarrativeTarotPromptMemoryThemeChecks {
  NarrativeTarotPromptMemoryThemeChecks._();

  static void themes(
    TarotNarrativeRequest request,
    Set<String> cardIds,
  ) {
    for (final t in request.recurringThemes) {
      NarrativeTarotPromptScalars.requireNonBlank(
        'themeIdOrLabel',
        t.themeIdOrLabel,
      );
      if (t.supportCount < 2) {
        throw ArgumentError('theme supportCount must be >= 2');
      }
      NarrativeTarotPromptScalars.requireUnit(
        'theme.relevanceToCurrentAsk',
        t.relevanceToCurrentAsk,
      );
      final seen = <String>{};
      for (final id in t.relatedCardIds) {
        NarrativeTarotPromptScalars.requireNonBlank('theme.relatedCardId', id);
        if (!seen.add(id)) {
          throw ArgumentError('duplicate theme relatedCardId $id');
        }
        if (!cardIds.contains(id)) {
          throw ArgumentError('theme relatedCardId $id not in current cards');
        }
      }
    }
  }

  static void memory(TarotNarrativeRequest request) {
    final bounds = request.bounds;
    final mem = request.memory;
    if (mem.priorReadingCount < 0 ||
        mem.priorReadingCount > bounds.maxPriorReadingsScanned) {
      throw ArgumentError(
        'priorReadingCount ${mem.priorReadingCount} outside '
        '0..${bounds.maxPriorReadingsScanned}',
      );
    }
    if (!mem.included && mem.entries.isNotEmpty) {
      throw ArgumentError('excluded memory cannot carry entries');
    }
    if (!mem.included) return;
    var chars = 0;
    for (final e in mem.entries) {
      NarrativeTarotPromptScalars.requireNonBlank(
        'memory.contentForModel',
        e.contentForModel,
      );
      NarrativeTarotPromptScalars.requireUnitOpt(
        'memory.confidence',
        e.confidence,
      );
      chars += e.contentForModel.length;
    }
    if (chars > bounds.maxMemoryChars) {
      throw ArgumentError(
        'memory chars $chars > ${bounds.maxMemoryChars}',
      );
    }
  }
}
