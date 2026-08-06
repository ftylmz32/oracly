/// EPIC-013 — Observable journey hints for reflective personalization.
library;

import 'package:flutter/foundation.dart';

/// Only data actually present in the user's history — never invented.
@immutable
class JourneyPersonalizationHints {
  const JourneyPersonalizationHints({
    this.recurringThemeLabels = const [],
    this.recentCardNames = const [],
    this.hasPriorNotes = false,
    this.priorReadingCount = 0,
  });

  final List<String> recurringThemeLabels;
  final List<String> recentCardNames;
  final bool hasPriorNotes;
  final int priorReadingCount;

  bool get isEmpty =>
      recurringThemeLabels.isEmpty &&
      recentCardNames.isEmpty &&
      !hasPriorNotes &&
      priorReadingCount == 0;

  /// One observational line for the reading — null when nothing meaningful to cite.
  String? observationalPreface() {
    if (isEmpty) return null;

    final hasMeaningfulHistory =
        recurringThemeLabels.isNotEmpty || hasPriorNotes || priorReadingCount >= 2;
    if (!hasMeaningfulHistory) return null;

    final parts = <String>[];
    if (recurringThemeLabels.isNotEmpty) {
      final themes = recurringThemeLabels.take(2).join(' ve ');
      parts.add(
        'Geçmiş açılımlarında $themes teması birkaç kez yankılanmış olabilir',
      );
    } else if (recentCardNames.isNotEmpty) {
      parts.add(
        'Son açılımlarında ${recentCardNames.first} kartı da belirmişti',
      );
    }
    if (hasPriorNotes) {
      parts.add('kendi yazdığın düşünceler yolculuğunun bir parçası');
    }
    if (parts.isEmpty) return null;
    return '${parts.join('; ')}.';
  }
}
