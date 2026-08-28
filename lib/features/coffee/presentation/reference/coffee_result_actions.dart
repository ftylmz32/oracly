/// Post-story coffee actions — share uses the real cup bytes when available.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/continuation/copy/session_continuation_copy.dart';
import '../../../../core/continuation/models/session_continuation.dart';
import '../../../../core/continuation/widgets/session_continuation_link.dart';
import '../../../../core/copy/session_ending_copy.dart';
import '../../../../core/insight_copy/widgets/insight_copy_link.dart';
import '../../../../core/quality/quality_feature.dart';
import '../../../../core/reading_version/models/reading_version_group.dart';
import '../../../../core/reading_version/models/reading_version_kind.dart';
import '../../../../core/reading_version/widgets/reading_version_host.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import '../../../../features/ai/oracle_conversation/navigation/oracle_conversation_route.dart';
import '../../../../features/discovery_share/services/discovery_share_builder.dart';
import '../../../../features/discovery_share/widgets/discovery_share_action.dart';
import '../../../../features/tarot/presentation/epic031/tarot_epic031_primary_button.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../../favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import '../../../favorite_moments/services/favorite_moment_factory.dart';
import '../../../reading_feedback/presentation/widgets/reading_quality_actions.dart';
import '../../copy/coffee_copy.dart';
import '../../models/coffee_reading.dart';
import 'coffee_insight_copy.dart';

class CoffeeResultActions extends StatelessWidget {
  const CoffeeResultActions({
    super.key,
    required this.reading,
    required this.themes,
    required this.onNewCup,
    required this.versionReloadToken,
    required this.onVersionSelect,
    this.onReinterpret,
    this.cupImage,
  });

  final CoffeeReading reading;
  final List<String> themes;
  final VoidCallback onNewCup;
  final int versionReloadToken;
  final ValueChanged<ReadingVersionGroup> onVersionSelect;
  final Future<bool> Function()? onReinterpret;
  final Uint8List? cupImage;

  @override
  Widget build(BuildContext context) {
    final whisper = SessionContinuationCopy.coffeeOrWhisperFor(themes);
    final oracle = OracleReadingContextSources.coffee(reading);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            CoffeeCopy.sourceNote,
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            CoffeeCopy.disclaimer,
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            SessionEndingCopy.footerWhisper,
            textAlign: TextAlign.center,
            style: ReadingTypography.micro(),
          ),
        ),
        TarotEpic031PrimaryButton(
          label: CoffeeCopy.askOr,
          onPressed: () =>
              openOracleConversation(context, readingContext: oracle),
        ),
        if (whisper != null)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              whisper,
              textAlign: TextAlign.center,
              style: ReadingTypography.footnote(),
            ),
          ),
        SessionContinuationLink(
          source: SessionContinuationSource.coffee,
          sessionThemes: themes,
          orAlreadyOffered: true,
          oracleContext: oracle,
        ),
        ReadingVersionHost(
          rootId: reading.id,
          kind: ReadingVersionKind.coffee,
          reloadToken: versionReloadToken,
          onSelect: onVersionSelect,
        ),
        SaveFavoriteMomentLink(draft: FavoriteMomentFactory.coffee(reading)),
        InsightCopyLink(text: CoffeeInsightCopy.fromReading(reading)),
        ReadingQualityActions(
          feature: QualityFeature.coffee,
          retry: onReinterpret,
        ),
        SizedBox(height: AppSpacing.sm),
        DiscoveryShareAction(
          discovery: DiscoveryShareBuilder.coffee(
            symbolName:
                reading.symbols.isEmpty ? null : reading.symbols.first.name,
            overall: reading.overall,
            cupImage: cupImage,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        OraclyButton(
          text: CoffeeCopy.newCup,
          type: OraclyButtonType.ghost,
          isExpanded: true,
          onPressed: onNewCup,
        ),
      ],
    );
  }
}
