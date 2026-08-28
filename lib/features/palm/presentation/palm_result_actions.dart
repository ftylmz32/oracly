/// Post-reading palm actions — private close, never pressure.
library;

import 'package:flutter/material.dart';

import '../../../core/continuation/copy/session_continuation_copy.dart';
import '../../../core/continuation/models/session_continuation.dart';
import '../../../core/continuation/widgets/session_continuation_link.dart';
import '../../../core/copy/session_ending_copy.dart';
import '../../../core/insight_copy/widgets/insight_copy_link.dart';
import '../../../core/quality/quality_feature.dart';
import '../../../core/reading_version/models/reading_version_group.dart';
import '../../../core/reading_version/models/reading_version_kind.dart';
import '../../../core/reading_version/widgets/reading_version_host.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import '../../../features/ai/oracle_conversation/widgets/or_ask_button.dart';
import '../../../features/discovery_share/services/discovery_share_builder.dart';
import '../../../features/discovery_share/widgets/discovery_share_action.dart';
import '../../../features/favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import '../../../features/favorite_moments/services/favorite_moment_factory.dart';
import '../../../features/reading_feedback/presentation/widgets/reading_quality_actions.dart';
import '../../../shared/widgets/oracly_button.dart';
import '../copy/palm_copy.dart';
import '../models/palm_reading.dart';
import 'palm_insight_copy.dart';
import 'palm_result_separator.dart';
import 'palm_tokens.dart';

class PalmResultActions extends StatelessWidget {
  const PalmResultActions({
    super.key,
    required this.reading,
    required this.onNewPalm,
    required this.versionReloadToken,
    required this.onVersionSelect,
    this.onReinterpret,
  });

  final PalmReading reading;
  final VoidCallback onNewPalm;
  final int versionReloadToken;
  final ValueChanged<ReadingVersionGroup> onVersionSelect;
  final Future<bool> Function()? onReinterpret;

  @override
  Widget build(BuildContext context) {
    final oracleContext = OracleReadingContextSources.palm(reading);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PalmResultSeparator(),
        Text(
          PalmCopy.sourceNote,
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote(
            color: PalmTokens.cream.withValues(alpha: 0.62),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          PalmCopy.disclaimer,
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote(
            color: PalmTokens.cream.withValues(alpha: 0.62),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          SessionEndingCopy.footerWhisper,
          textAlign: TextAlign.center,
          style: ReadingTypography.micro(
            color: PalmTokens.cream.withValues(alpha: 0.48),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        OrAskButton(readingContext: oracleContext),
        if (SessionContinuationCopy.palmOrWhisperFor(reading.themes)
            case final whisper?)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              whisper,
              textAlign: TextAlign.center,
              style: ReadingTypography.footnote(
                color: PalmTokens.cream.withValues(alpha: 0.72),
              ),
            ),
          ),
        SessionContinuationLink(
          source: SessionContinuationSource.palm,
          sessionThemes: reading.themes,
          orAlreadyOffered: true,
          oracleContext: oracleContext,
        ),
        InsightCopyLink(text: PalmInsightCopy.fromReading(reading)),
        ReadingVersionHost(
          rootId: reading.id,
          kind: ReadingVersionKind.palm,
          reloadToken: versionReloadToken,
          onSelect: onVersionSelect,
        ),
        DiscoveryShareAction(
          discovery: DiscoveryShareBuilder.palm(
            theme: reading.themes.isEmpty ? null : reading.themes.first,
            symbol: reading.symbols.isEmpty ? null : reading.symbols.first,
            overall: reading.overall,
          ),
        ),
        ReadingQualityActions(
          feature: QualityFeature.palm,
          retry: onReinterpret,
        ),
        SaveFavoriteMomentLink(
          draft: FavoriteMomentFactory.palm(reading),
        ),
        SizedBox(height: AppSpacing.sm),
        OraclyButton(
          text: PalmCopy.newPalm,
          type: OraclyButtonType.ghost,
          isExpanded: true,
          onPressed: onNewPalm,
        ),
      ],
    );
  }
}
