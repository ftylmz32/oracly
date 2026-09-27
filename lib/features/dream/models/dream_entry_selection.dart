/// Entry context as stable ids + the dreamer's raw guided answers.
///
/// Display/persisted tags are localized strings in the app language at entry
/// time; the provider needs this structure instead, so ORACLY-owned labels
/// can follow the operation language without parsing display text back.
library;

import 'dream_entry_context.dart';

class DreamEntrySelection {
  const DreamEntrySelection({
    this.chips = const [],
    this.guided = const {},
  });

  /// Chips in enum order; guided answers trimmed (as tags always were),
  /// blank answers dropped, questions in enum order.
  factory DreamEntrySelection.of({
    required Set<DreamEntryChipId> chips,
    required Map<DreamGuidedQuestionId, String> guided,
  }) {
    return DreamEntrySelection(
      chips: [
        for (final id in DreamEntryChipId.values)
          if (chips.contains(id)) id,
      ],
      guided: {
        for (final id in DreamGuidedQuestionId.values)
          if ((guided[id] ?? '').trim().isNotEmpty) id: guided[id]!.trim(),
      },
    );
  }

  final List<DreamEntryChipId> chips;
  final Map<DreamGuidedQuestionId, String> guided;

  bool get isEmpty => chips.isEmpty && guided.isEmpty;

  Map<String, dynamic> toJson() => {
        'chips': [for (final c in chips) c.name],
        'guided': {for (final e in guided.entries) e.key.name: e.value},
      };

  /// Unknown ids from a newer schema are skipped, never guessed.
  factory DreamEntrySelection.fromJson(Map<String, dynamic> json) {
    final chips = <DreamEntryChipId>[];
    for (final name in (json['chips'] as List<dynamic>? ?? const [])) {
      final id = DreamEntryChipId.values.asNameMap()[name];
      if (id != null) chips.add(id);
    }
    final guided = <DreamGuidedQuestionId, String>{};
    final raw = json['guided'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        final id = DreamGuidedQuestionId.values.asNameMap()[entry.key];
        if (id != null && entry.value is String) guided[id] = entry.value;
      }
    }
    return DreamEntrySelection(chips: chips, guided: guided);
  }
}
