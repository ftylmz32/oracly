/// EPIC-013 — Observable journey hints for reflective personalization.
library;

import 'package:flutter/foundation.dart';

import '../../../core/domain/models/personal_insight_theme.dart';
import '../../tarot/copy/tarot_l10n.dart';

/// Only data actually present in the user's history — never invented.
@immutable
class JourneyPersonalizationHints {
  const JourneyPersonalizationHints({
    this.recurringThemeLabels = const [],
    this.recentCardNames = const [],
    this.hasPriorNotes = false,
    this.priorReadingCount = 0,
    this.priorOpenings = const [],
    this.revisitPriorExcerpt,
    this.revisitInstruction,
  });

  final List<String> recurringThemeLabels;
  final List<String> recentCardNames;
  final bool hasPriorNotes;
  final int priorReadingCount;
  final List<String> priorOpenings;
  final String? revisitPriorExcerpt;
  final String? revisitInstruction;

  bool get isEmpty =>
      recurringThemeLabels.isEmpty &&
      recentCardNames.isEmpty &&
      !hasPriorNotes &&
      priorReadingCount == 0 &&
      priorOpenings.isEmpty &&
      (revisitPriorExcerpt == null || revisitPriorExcerpt!.isEmpty) &&
      (revisitInstruction == null || revisitInstruction!.isEmpty);

  /// Stable cache identity for the actual continuity evidence.
  ///
  /// Prior reading count alone is not enough: two profiles can have the same
  /// count while carrying different recurring themes, recent cards or revisit
  /// evidence. Keeping all evidence in this token prevents a stale tarot
  /// interpretation from being reused after the user's story changes.
  String get cacheToken {
    final raw = <String>[
      priorReadingCount.toString(),
      hasPriorNotes ? '1' : '0',
      recurringThemeLabels.map((e) => e.trim()).join('|'),
      recentCardNames.map((e) => e.trim()).join('|'),
      priorOpenings.map((e) => e.trim()).join('|'),
      revisitPriorExcerpt?.trim() ?? '',
      revisitInstruction?.trim() ?? '',
    ].join('~');

    // Deterministic FNV-1a 32-bit hash; unlike Object.hash/hashCode this token
    // remains stable for persisted caches across process restarts.
    var hash = 0x811c9dc5;
    for (final unit in raw.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  JourneyPersonalizationHints withRevisit({
    required String priorExcerpt,
    required String instruction,
  }) {
    return JourneyPersonalizationHints(
      recurringThemeLabels: recurringThemeLabels,
      recentCardNames: recentCardNames,
      hasPriorNotes: hasPriorNotes,
      priorReadingCount: priorReadingCount,
      priorOpenings: priorOpenings,
      revisitPriorExcerpt: priorExcerpt,
      revisitInstruction: instruction,
    );
  }

  bool echoes(String text) {
    final fp = fingerprint(text);
    if (fp.length < 24) return false;
    for (final prior in priorOpenings) {
      if (prior == fp || prior.contains(fp) || fp.contains(prior)) return true;
    }
    return false;
  }

  static String fingerprint(String raw) {
    final text = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= 48) return text;
    return text.substring(0, 48);
  }

  /// One observational line for the reading — null when nothing meaningful to cite.
  String? observationalPreface() {
    final hasMeaningfulHistory = recurringThemeLabels.isNotEmpty ||
        hasPriorNotes ||
        priorReadingCount >= 2;
    if (!hasMeaningfulHistory) return null;

    final parts = <String>[];
    if (recurringThemeLabels.isNotEmpty) {
      final themes = recurringThemeLabels
          .take(2)
          .map(_localizeTheme)
          .join(' · ');
      parts.add(TarotL10n.fill('tarot.journey.themes', {'themes': themes}));
    } else if (recentCardNames.isNotEmpty) {
      parts.add(
        TarotL10n.fill('tarot.journey.themes', {
          'themes': recentCardNames.first,
        }),
      );
    }
    if (hasPriorNotes) {
      parts.add(TarotL10n.fill('tarot.journey.notes'));
    }
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  static String _localizeTheme(String label) {
    final raw = label.trim();
    if (raw.isEmpty) return raw;
    for (final theme in PersonalInsightTheme.values) {
      if (theme.label.toLowerCase() == raw.toLowerCase()) {
        return TarotL10n.fill('tarot.insight.theme.${theme.id}');
      }
    }
    return raw;
  }
}
