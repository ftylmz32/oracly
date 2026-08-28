/// Dream as story + titled editorial sections.
library;

import '../models/dream.dart';
import '../models/dream_insight.dart';

class DreamReadingSection {
  const DreamReadingSection({
    required this.kind,
    required this.title,
    required this.body,
    this.emphasized = false,
  });

  final DreamInsightKind kind;
  final String title;
  final String body;
  final bool emphasized;
}

abstract final class DreamReadingPresentation {
  DreamReadingPresentation._();

  static const _order = [
    DreamInsightKind.summary,
    DreamInsightKind.symbols,
    DreamInsightKind.emotionalMeaning,
    DreamInsightKind.mainInterpretation,
    DreamInsightKind.personalConnection,
    DreamInsightKind.themes,
    DreamInsightKind.closingTakeaway,
  ];

  static String story(Dream? dream) {
    final narrative = dream?.narrative.trim() ?? '';
    if (narrative.isNotEmpty) return narrative;
    return _bodyOf(dream, DreamInsightKind.summary) ??
        dream?.understanding?.summary.trim() ??
        '';
  }

  /// Flat text for favorites / OR handoff payload.
  static String interpretation(Dream? dream) {
    return sections(dream)
        .map((s) => '${s.title}\n\n${s.body}')
        .join('\n\n');
  }

  static List<DreamReadingSection> sections(Dream? dream) {
    if (dream == null) return const [];
    final told = story(dream);
    final out = <DreamReadingSection>[];
    for (final kind in _order) {
      for (final insight in dream.insights) {
        if (insight.kind != kind) continue;
        final text = insight.body.trim();
        if (text.isEmpty || text == told) continue;
        if (told.isNotEmpty && told.contains(text) && text.length > 40) {
          continue;
        }
        if (out.any((s) => s.body.contains(text))) continue;
        final title = insight.title?.trim() ?? '';
        if (title.isEmpty) continue;
        out.add(
          DreamReadingSection(
            kind: kind,
            title: title,
            body: text,
            emphasized: kind == DreamInsightKind.themes,
          ),
        );
      }
    }
    return out;
  }

  static String? _bodyOf(Dream? dream, DreamInsightKind kind) {
    if (dream == null) return null;
    for (final insight in dream.insights) {
      if (insight.kind == kind && insight.body.trim().isNotEmpty) {
        return insight.body.trim();
      }
    }
    return null;
  }
}
