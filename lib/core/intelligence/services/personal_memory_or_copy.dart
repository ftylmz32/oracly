/// Observational OR lines from memory — never identity claims.
library;

import '../domain/models/memory_theme_stat.dart';
import '../domain/models/personal_memory_summary.dart';

abstract final class PersonalMemoryOrCopy {
  PersonalMemoryOrCopy._();

  static const _tensionPairs = [
    ('change', 'rest'),
    ('change', 'inward'),
    ('decision', 'uncertainty'),
    ('newBeginning', 'rest'),
  ];

  static String? observe(PersonalMemorySummary summary, {String lang = 'tr'}) {
    final top = _recurringTop(summary);
    if (top == null) return null;
    final label = top.label;
    return switch (lang) {
      'en' =>
        'Lately $label has been meeting you again across a few discoveries. '
            'I would not tie it to one conclusion, but it is clearly alive right now.',
      'ru' =>
        'В последнее время тема «$label» снова встречается тебе в разных открытиях. '
            'К одному выводу не сводил бы, но сейчас это явно живой вопрос.',
      _ =>
        'Son dönemde $label konusu birkaç farklı keşfinde yeniden karşına çıkıyor. '
            'Bunu tek bir sonuca bağlamazdım ama şu an hayatında canlı bir mesele '
            'olduğu belli.',
    };
  }

  static String? tension(PersonalMemorySummary summary, {String lang = 'tr'}) {
    final ids = summary.themes.map((t) => t.id.toLowerCase()).toSet();
    for (final pair in _tensionPairs) {
      if (!ids.contains(pair.$1) || !ids.contains(pair.$2)) continue;
      return switch (lang) {
        'en' =>
          'One side leans toward change, another toward steadiness — both have '
              'shown up lately. I would not force them into one story.',
        'ru' =>
          'С одной стороны — изменение, с другой — устойчивость; оба мотива '
              'недавно встречались. К одной истории не сводил бы.',
        _ =>
          'Bir tarafta değişme isteği, diğer tarafta düzeni koruma ihtiyacı '
              'yeniden görünüyor. İkisini tek sonuca bağlamazdım.',
      };
    }
    return null;
  }

  /// Soft preference / epistemic rules — never a theme dump.
  static String? instruction(PersonalMemorySummary summary) {
    if (summary.isEmpty) return null;
    final parts = <String>[
      if (summary.preferredName != null)
        'They have asked to be called ${summary.preferredName}.',
      if (summary.orStyle != null)
        'They prefer OR to speak in a ${summary.orStyle} tone.',
      if (summary.sunSign != null)
        'Their sun sign path is ${summary.sunSign} (symbolic only).',
      'Cite a recurring observation only when the user message clearly '
          'touches it. Prefer silence over a memory dump. '
          'If observations conflict, do not invent one resolution — '
          'name the tension briefly or stay quiet. '
          'Keep FACT / OBSERVATION / INTERPRETATION / PREFERENCE distinct. '
          'Themes and discovery marks are OBSERVATION, never FACT about who '
          'they are. Sun sign and readings are INTERPRETATION (symbolic only). '
          'Tone style is PREFERENCE, not a command. '
          'Never turn symbolic interpretation into FACT. '
          'Never invent history. Do not mention memory systems, records, '
          'databases, embeddings, or retrieval to the user.',
    ];
    return parts.join(' ');
  }

  static MemoryThemeStat? _recurringTop(PersonalMemorySummary summary) {
    for (final theme in summary.themes) {
      if (theme.frequency >= 2 || theme.sourceDiversity >= 2) return theme;
    }
    return null;
  }
}
