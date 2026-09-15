/// Dream result footer — OR'a Sor + close + new dream.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/continuation/models/session_continuation.dart';
import '../../../../core/continuation/widgets/session_continuation_link.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import '../../../../features/ai/oracle_conversation/widgets/or_ask_button.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream.dart';
import '../../models/dream_insight.dart';
import '../../../personal_discovery/services/personal_theme_extractor.dart';

class DreamReferenceResultActions extends ConsumerWidget {
  const DreamReferenceResultActions({
    super.key,
    required this.dream,
    required this.analysis,
    required this.onNewDream,
    this.onReinterpret,
    this.versionReloadToken = 0,
  });

  final Dream? dream;
  final String analysis;
  final VoidCallback onNewDream;
  final Future<bool> Function()? onReinterpret;
  final int versionReloadToken;

  /// Themes come only from what the user actually wrote in this dream, not
  /// from the AI-generated interpretation text: that prose can carry a theme
  /// word (e.g. "ilişki"/"bağlantı" used to mean "connection between
  /// symbols", or memory-influenced phrasing) that has nothing to do with
  /// the current dream, and there is no way to tell that apart from a
  /// genuine theme once it is mixed into the analysis text.
  static List<String> themesFor(Dream? current) {
    if (current == null) return const [];
    return PersonalThemeExtractor.themesIn(current.narrative)
        .map((t) => t.label)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = dream;
    final themes = themesFor(current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (current != null && analysis.trim().isNotEmpty) ...[
          OrAskButton(
            label: DreamCopy.deepenWithOr,
            readingContext: OracleReadingContextSources.dream(
              id: current.id,
              narrative: current.narrative,
              analysis: analysis,
              symbols: current.understanding?.symbols
                      .map((s) => s.label)
                      .toList() ??
                  const [],
              emotionalTheme: _body(current, DreamInsightKind.summary) ??
                  _body(current, DreamInsightKind.emotionalMeaning),
              fullInterpretation: analysis,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
        ],
        SessionContinuationLink(
          source: SessionContinuationSource.dream,
          sessionThemes: themes,
          orAlreadyOffered: current != null && analysis.trim().isNotEmpty,
        ),
        OraclyButton(
          text: DreamCopy.saveAndClose,
          isExpanded: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SizedBox(height: AppSpacing.sm),
        OraclyButton(
          text: DreamCopy.newDream,
          type: OraclyButtonType.ghost,
          isExpanded: true,
          onPressed: onNewDream,
        ),
      ],
    );
  }

  String? _body(Dream dream, DreamInsightKind kind) {
    for (final insight in dream.insights) {
      if (insight.kind == kind && insight.body.trim().isNotEmpty) {
        return insight.body;
      }
    }
    return null;
  }
}
