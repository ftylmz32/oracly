/// OR-301+ — Premium glass section card with unique visual identity.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../../../core/widgets/oracly_signature_motifs.dart';
import 'reading_card_ambience.dart';
import 'reading_flow_text.dart';
import 'reading_premium_animations.dart';
import 'reading_premium_icon_container.dart';
import 'reading_premium_utils.dart';
import 'reading_sacred_rhythm.dart';
import 'reading_section_theme.dart';

class ReadingPremiumSectionCard extends StatelessWidget {
  const ReadingPremiumSectionCard({
    super.key,
    required this.kind,
    required this.title,
    required this.body,
    required this.index,
    required this.master,
    required this.ambientPhase,
    this.exitProgress = 0,
    this.emphasizeBody = false,
    this.preserveFullText = false,
  });

  final ReadingSectionKind kind;
  final String title;
  final String body;
  final int index;
  final double master;
  /// Shared screen ambient phase (0–1) — one breath across all sections.
  final double ambientPhase;
  final double exitProgress;
  final bool emphasizeBody;
  final bool preserveFullText;

  @override
  Widget build(BuildContext context) {
    final theme = ReadingSectionTheme.forKind(kind);
    final progress = readingPremiumSectionProgress(index, master);
    final titleProgress = readingPremiumSectionTitleProgress(index, master);
    final bodyProgress = readingPremiumSectionBodyProgress(index, master);
    final slide = (1 - progress) * 24;
    final scatterX = (index.isEven ? -1 : 1) * exitProgress * 14;
    final scatterY = exitProgress * 18;
    final phase = ambientPhase * pi * 2;

    if (body.trim().isEmpty) return const SizedBox.shrink();

    return Opacity(
      opacity: (progress * (1 - exitProgress)).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(scatterX, slide + scatterY),
        child: Padding(
          padding: EdgeInsets.only(bottom: ReadingSacredRhythm.sectionBottom),
          child: RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.lg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.lg,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ReadingCardAmbience(
                        theme: theme,
                        phase: phase,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.lg,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: theme.gradientColors,
                        ),
                        border: Border.all(
                          color: theme.borderColor,
                          width: AppBorderWidth.hairline,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.lg + AppSpacing.xs,
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Opacity(
                                opacity: titleProgress.clamp(0.0, 1.0),
                                child: Transform.translate(
                                  offset: Offset(0, (1 - titleProgress) * 10),
                                  child: Row(
                                    children: [
                                      ReadingPremiumIconContainer(
                                        theme: theme,
                                        size: 38,
                                      ),
                                      SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: ReadingTypography.sectionLabel(
                                            color: theme.accentColor
                                                .withValues(alpha: 0.88),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: AppSpacing.lg - AppSpacing.xs),
                              Opacity(
                                opacity: bodyProgress.clamp(0.0, 1.0),
                                child: Transform.translate(
                                  offset: Offset(0, (1 - bodyProgress) * 8),
                                  child: ReadingFlowText(
                                    text: preserveFullText
                                        ? body.trim()
                                        : ReadingPremiumUtils.condense(
                                            body,
                                            maxChars: emphasizeBody ? 480 : 320,
                                          ),
                                    emphasizeFirst: emphasizeBody,
                                    style: (emphasizeBody
                                            ? ReadingTypography.bodyCore()
                                            : ReadingTypography.body())
                                        .copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: emphasizeBody
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const OraclySignatureCornerOrnaments(
                            inset: 7,
                            size: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
