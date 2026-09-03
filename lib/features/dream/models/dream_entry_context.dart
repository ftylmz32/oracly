/// Optional entry context — chips and guided memory prompts.
library;

import 'package:flutter/material.dart';

import '../copy/dream_copy.dart';
import 'dream_emotion.dart';

enum DreamEntryChipId { nightmare, clear, symbols }

enum DreamGuidedQuestionId { who, where, feeling, recurring }

abstract final class DreamEntryContext {
  DreamEntryContext._();

  static const narrativeMaxLength = 1000;

  static String chipLabel(DreamEntryChipId id) => switch (id) {
        DreamEntryChipId.nightmare => DreamCopy.chipNightmare,
        DreamEntryChipId.clear => DreamCopy.chipClear,
        DreamEntryChipId.symbols => DreamCopy.chipSymbols,
      };

  static String guidedLabel(DreamGuidedQuestionId id) => switch (id) {
        DreamGuidedQuestionId.who => DreamCopy.guidedWho,
        DreamGuidedQuestionId.where => DreamCopy.guidedWhere,
        DreamGuidedQuestionId.feeling => DreamCopy.guidedFeeling,
        DreamGuidedQuestionId.recurring => DreamCopy.guidedRecurring,
      };

  static IconData guidedIcon(DreamGuidedQuestionId id) => switch (id) {
        DreamGuidedQuestionId.who => Icons.person_outline_rounded,
        DreamGuidedQuestionId.where => Icons.place_outlined,
        DreamGuidedQuestionId.feeling => Icons.favorite_border_rounded,
        DreamGuidedQuestionId.recurring => Icons.autorenew_rounded,
      };

  static IconData chipIcon(DreamEntryChipId id) => switch (id) {
        DreamEntryChipId.nightmare => Icons.cloud_outlined,
        DreamEntryChipId.clear => Icons.visibility_outlined,
        DreamEntryChipId.symbols => Icons.auto_awesome_outlined,
      };

  static List<DreamEmotion> emotionsFor(Set<DreamEntryChipId> chips) {
    final out = <DreamEmotion>[];
    if (chips.contains(DreamEntryChipId.nightmare)) {
      out.add(const DreamEmotion(id: DreamEmotionId.fearful));
    }
    if (chips.contains(DreamEntryChipId.clear)) {
      out.add(const DreamEmotion(id: DreamEmotionId.vivid));
    }
    return out;
  }

  static List<String> tagsFor({
    required Set<DreamEntryChipId> chips,
    required Map<DreamGuidedQuestionId, String> guided,
  }) {
    final out = <String>[
      for (final chip in chips) chipLabel(chip),
      for (final entry in guided.entries)
        if (entry.value.trim().isNotEmpty)
          '${guidedLabel(entry.key)}: ${entry.value.trim()}',
    ];
    return out;
  }
}
