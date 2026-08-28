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
import '../../../favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import '../../../favorite_moments/services/favorite_moment_factory.dart';
import '../../../reading_feedback/models/reading_feedback_category.dart';
import '../../../reading_feedback/presentation/widgets/reading_quality_actions.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = dream;
    final themes = PersonalThemeExtractor.labelsIn([
      if (current != null) current.narrative,
      analysis,
    ]);
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
        if (current != null && analysis.trim().isNotEmpty)
          SaveFavoriteMomentLink(
            draft: FavoriteMomentFactory.dream(
              id: current.id,
              at: current.recordedAt,
              narrative: current.narrative,
              analysis: analysis,
            ),
          ),
        if (current != null && analysis.trim().isNotEmpty)
          ReadingQualityActions(
            feature: QualityFeature.dream,
            retry: onReinterpret,
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
