/// OR-050 — Daily Energy Details screen.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/oracly_scaffold.dart';
import '../../home/widgets/hero_orb_v3/hero_orb.dart';
import '../../home/widgets/home_cinematic_background.dart';
import '../daily_energy_constants.dart';
import '../models/daily_energy_reading.dart';
import '../services/daily_energy_service.dart';
import '../widgets/daily_energy_glass_card.dart';
import '../widgets/daily_energy_header.dart';
import '../widgets/daily_energy_moon_hero.dart';

/// Full daily energy breakdown — opened from the Home card.
class DailyEnergyDetailsScreen extends StatelessWidget {
  const DailyEnergyDetailsScreen({
    super.key,
    this.summary,
  });

  final String? summary;

  @override
  Widget build(BuildContext context) {
    final reading = DailyEnergyService.readingFor(summaryOverride: summary);

    return OraclyScaffold(
      backgroundOverlay: const HomeCosmicBackground(),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: AppSpacing.screenHorizontal.copyWith(
          top: AppSpacing.md,
          bottom: AppSpacing.xxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DailyEnergyLayout.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DailyEnergyDetailsHeader(
                  moonPhaseLabel: reading.moonPhaseLabel,
                  dateLabel: reading.dateLabel,
                ),
                SizedBox(height: AppSpacing.lg),
                const _HeroSection(),
                SizedBox(height: AppSpacing.xl),
                _SummarySection(summary: reading.summary),
                SizedBox(height: AppSpacing.lg),
                _InsightGrid(reading: reading),
                SizedBox(height: AppSpacing.lg),
                _LuckyRow(reading: reading),
                SizedBox(height: AppSpacing.lg),
                _CosmicSection(message: reading.cosmicMessage),
                SizedBox(height: AppSpacing.lg),
                _AiSection(interpretation: reading.aiInterpretation),
                SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        children: [
          Align(
            alignment: Alignment.center,
            child: HeroOrb(size: DailyEnergyLayout.detailOrbSize),
          ),
          SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.center,
            child: DailyEnergyMoonHero(
              width: 120,
              height: 148,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.summary});

  final String summary;

  static const String _title = 'GÜNLÜK ÖZET';

  @override
  Widget build(BuildContext context) {
    return DailyEnergyGlassCard(
      title: _title,
      icon: Icons.auto_awesome_rounded,
      child: Text(
        summary,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.55,
        ),
      ),
    );
  }
}

class _InsightGrid extends StatelessWidget {
  const _InsightGrid({required this.reading});

  final DailyEnergyReading reading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DailyEnergyInsightTile(
                icon: DailyEnergyInsight.love.icon,
                label: DailyEnergyInsight.love.label,
                body: reading.love,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: DailyEnergyInsightTile(
                icon: DailyEnergyInsight.career.icon,
                label: DailyEnergyInsight.career.label,
                body: reading.career,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DailyEnergyInsightTile(
                icon: DailyEnergyInsight.money.icon,
                label: DailyEnergyInsight.money.label,
                body: reading.money,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: DailyEnergyInsightTile(
                icon: DailyEnergyInsight.mood.icon,
                label: DailyEnergyInsight.mood.label,
                body: reading.mood,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LuckyRow extends StatelessWidget {
  const _LuckyRow({required this.reading});

  final DailyEnergyReading reading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DailyEnergyLuckyChip(
          label: 'Şanslı Sayı',
          value: '${reading.luckyNumber}',
        ),
        SizedBox(width: AppSpacing.sm),
        DailyEnergyLuckyChip(
          label: 'Şanslı Renk',
          value: reading.luckyColor,
          swatch: reading.luckyColorHex,
        ),
        SizedBox(width: AppSpacing.sm),
        DailyEnergyLuckyChip(
          label: 'Şanslı Kristal',
          value: reading.luckyCrystal,
        ),
      ],
    );
  }
}

class _CosmicSection extends StatelessWidget {
  const _CosmicSection({required this.message});

  final String message;

  static const String _title = 'KOZMİK MESAJ';

  @override
  Widget build(BuildContext context) {
    return DailyEnergyGlassCard(
      title: _title,
      icon: Icons.nightlight_round,
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.goldLight.withValues(alpha: 0.92),
          height: 1.6,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _AiSection extends StatelessWidget {
  const _AiSection({required this.interpretation});

  final String interpretation;

  static const String _title = 'AI YORUMU';

  @override
  Widget build(BuildContext context) {
    return DailyEnergyGlassCard(
      title: _title,
      icon: Icons.psychology_alt_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.smValue),
              gradient: LinearGradient(
                colors: [
                  AppColors.purple.withValues(alpha: 0.18),
                  AppColors.gold.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: AppColors.purpleLight.withValues(alpha: 0.28),
                width: AppBorderWidth.hairline,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: AppSpacing.sm + AppSpacing.xs,
                    color: AppColors.purpleLight,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Oracly AI',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.purpleLight,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            interpretation,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.58,
            ),
          ),
        ],
      ),
    );
  }
}
