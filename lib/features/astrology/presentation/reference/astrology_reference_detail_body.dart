/// Full-day reading as a premium celestial report.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/continuation/models/session_continuation.dart';
import '../../../../core/continuation/widgets/session_continuation_link.dart';
import '../../../../core/copy/session_ending_copy.dart';
import '../../../../core/design_system/chamber_ornament_heading.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../core/quality/quality_feature.dart';
import '../../../favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import '../../../favorite_moments/services/favorite_moment_factory.dart';
import '../../../reading_feedback/presentation/widgets/reading_quality_actions.dart';
import '../../../../features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import '../../../../features/ai/oracle_conversation/widgets/or_ask_button.dart';
import '../../../../features/discovery_share/services/discovery_share_builder.dart';
import '../../../../features/discovery_share/widgets/discovery_share_action.dart';
import '../../../content/astrology/models/astrology_content.dart';
import '../../copy/astrology_presentation_copy.dart';
import '../../models/astrology_daily_reading.dart';
import 'astrology_content_card.dart';
import 'astrology_content_lane_meta.dart';
import 'astrology_reading_presentation.dart';
import 'astrology_reference_kind_note.dart';
import 'astrology_reference_sign_card.dart';
import 'astrology_reference_tokens.dart';
import 'astrology_result_report.dart';

class AstrologyReferenceDetailBody extends ConsumerWidget {
  const AstrologyReferenceDetailBody({
    super.key,
    required this.sign,
    required this.reading,
    this.themeLabels = const [],
  });

  final ZodiacSignContent sign;
  final AstrologyDailyReading reading;
  final List<String> themeLabels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signName = OraclyL10n.t('zodiac.${sign.id}');
    final now = DateTime.now();
    final oracleCtx = OracleReadingContextSources.astrology(
      id: 'astrology-${sign.id}',
      signLabel: signName,
      daily: reading.overall,
      personality: reading.personality,
      love: reading.love,
      career: reading.career,
      money: reading.money,
      energy: reading.energy,
      emotion: reading.emotion,
      advice: reading.advice,
      opportunity: reading.opportunity,
      caution: reading.caution,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AstrologyReferenceKindNote(),
        SizedBox(height: AstrologyReferenceTokens.tabsToSignCard),
        AstrologyReferenceSignCard(
          sign: sign,
          height: AstrologyReferenceTokens.detailSignCardHeight,
        ),
        SizedBox(height: AstrologyReferenceTokens.statsToDaily),
        AstrologyResultReport(
          reading: reading,
          themeLabels: themeLabels,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          SessionEndingCopy.footerWhisper,
          textAlign: TextAlign.center,
          style: ReadingTypography.micro(),
        ),
        SizedBox(height: AppSpacing.sm),
        OrAskButton(readingContext: oracleCtx),
        SessionContinuationLink(
          source: SessionContinuationSource.astrology,
          sessionThemes: themeLabels,
          orAlreadyOffered: true,
          oracleContext: oracleCtx,
        ),
        SizedBox(height: CraftsmanshipRhythm.betweenSections),
        ..._depthSection(reading),
        SizedBox(height: AppSpacing.md),
        DiscoveryShareAction(
          discovery: DiscoveryShareBuilder.astrology(
            innerTheme: themeLabels.isNotEmpty
                ? themeLabels.first
                : AstrologyReadingPresentation.laneLine(reading.innerTheme),
            signName: signName,
          ),
        ),
        SaveFavoriteMomentLink(
          draft: FavoriteMomentFactory.astrology(
            signId: sign.id,
            at: now,
            signLabel: signName,
            reading: reading,
          ),
        ),
        ReadingQualityActions(feature: QualityFeature.astrology),
      ],
    );
  }
}

List<Widget> _depthSection(AstrologyDailyReading reading) {
  final love = reading.love.trim();
  final career = reading.career.trim();
  final inner = AstrologyReadingPresentation.detailInnerBody(reading).trim();
  if (love.isEmpty && career.isEmpty && inner.isEmpty) {
    return const <Widget>[];
  }
  return [
    ChamberOrnamentHeading(label: AstrologyPresentationCopy.reportDepths),
    SizedBox(height: CraftsmanshipRhythm.afterTitle),
    AstrologyContentCard(
      kind: AstrologyContentLaneKind.love,
      body: love,
      index: 0,
    ),
    AstrologyContentCard(
      kind: AstrologyContentLaneKind.work,
      body: career,
      index: 1,
    ),
    AstrologyContentCard(
      kind: AstrologyContentLaneKind.inner,
      body: inner,
      index: 2,
    ),
  ];
}

