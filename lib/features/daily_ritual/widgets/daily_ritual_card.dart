/// EPIC-011 — Home daily ritual card — gentle return, never gamified.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/oracly_pressable.dart';

import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../core/universe/oracly_universe_layer.dart';
import '../../../core/universe/oracly_universe_state.dart';
import '../../../shared/widgets/oracly_card.dart';
import '../../home/theme/home_architecture.dart';
import '../../home/theme/home_focus.dart';
import '../../home/theme/home_reward.dart';
import '../../home/widgets/daily_energy/energy_constants.dart';
import '../../home/widgets/daily_energy/energy_illustration.dart';
import '../models/daily_ritual_day.dart';
import '../services/daily_ritual_reflections.dart';
import '../services/daily_ritual_service.dart';
import 'daily_ritual_thought_sheet.dart';
import '../../../app/providers/app_providers.dart';

/// Replaces static daily energy — one thoughtful ritual per day.
class DailyRitualCard extends ConsumerStatefulWidget {
  const DailyRitualCard({super.key});

  @override
  ConsumerState<DailyRitualCard> createState() => _DailyRitualCardState();
}

class _DailyRitualCardState extends ConsumerState<DailyRitualCard> {
  static const double _illustrationHeight =
      AppSpacing.xxl + AppSpacing.xxl + AppSpacing.xl + AppSpacing.md + 4;

  bool _reflectionExpanded = false;
  DailyRitualDay? _day;

  DailyRitualService get _service => ref.read(dailyRitualServiceProvider);

  DailyRitualDay get _state => _day ?? _service.loadToday();

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() => _day = _service.loadToday());
  }

  Future<void> _readReflection() async {
    OraclyTouchFeedback.acknowledge();
    await _service.markReflectionRead();
    if (!mounted) return;
    setState(() {
      _reflectionExpanded = true;
      _day = _state.copyWith(reflectionRead: true);
    });
  }

  Future<void> _drawCard() async {
    OraclyTouchFeedback.acknowledge();
    await _service.markCardDrawn();
    if (!mounted) return;
    setState(() => _day = _state.copyWith(cardDrawn: true));
    OraclyNavigationService.startDailyCardDraw(context);
  }

  Future<void> _writeThought() async {
    OraclyTouchFeedback.acknowledge();
    final thought = await showDailyRitualThoughtSheet(
      context: context,
      initialThought: _state.personalThought,
    );
    if (thought == null || !mounted) return;
    await _service.saveThought(thought);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final universe =
        OraclyUniverseScope.maybeOf(context) ?? OraclyUniverseState.current();
    final welcome = DailyRitualReflections.welcome(universe);
    final teaser = DailyRitualReflections.teaser(universe);
    final reflection = DailyRitualReflections.reflection(universe);
    final day = _state;
    final showReflection = _reflectionExpanded || day.reflectionRead;
    final closing = day.hasEngaged ? DailyRitualReflections.closing() : null;

    return DecoratedBox(
      decoration: EnergyDecorations.shell,
      child: OraclyCard(
        showBorder: false,
        showShadow: false,
        clipBehavior: Clip.none,
        gradient: EnergyDecorations.cardSurface,
        padding: EdgeInsets.only(
          left: AppSpacing.insetCard + AppSpacing.xs,
          right: 0,
          top: AppSpacing.insetCard,
          bottom: AppSpacing.insetCard + 2,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: HomeArchitectureOverlay(
                borderRadius: AppRadius.lg,
                proximity: HomeOrbProximity.medium,
                detail: HomeSurfaceDetail.standard,
              ),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: AppRadius.lg,
                child: const Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: EnergyDecorations.innerVignette,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: EnergyDecorations.innerEdgeShadow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: EdgeInsets.only(right: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GÜNLÜK AYİN',
                          style: ReadingTypography.sectionLabel(),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          welcome,
                          style: ReadingTypography.body(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: EnergySpacing.titleToBody),
                        AnimatedCrossFade(
                          duration: HomeReward.sweep,
                          crossFadeState: showReflection
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: Text(
                            teaser,
                            style: ReadingTypography.body(),
                          ),
                          secondChild: Text(
                            reflection,
                            style: ReadingTypography.body(),
                          ),
                        ),
                        if (closing != null) ...[
                          SizedBox(height: AppSpacing.md),
                          Text(
                            closing,
                            style: ReadingTypography.closing(
                              color: AppColors.goldLight.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                        SizedBox(height: EnergySpacing.bodyToAction),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _RitualActionChip(
                              label: day.cardDrawn
                                  ? 'Kart çekildi'
                                  : 'Kart çek',
                              icon: Icons.auto_awesome,
                              onPressed: day.cardDrawn ? null : _drawCard,
                              subdued: day.cardDrawn,
                            ),
                            if (!showReflection)
                              _RitualActionChip(
                                label: 'Düşünceyi oku',
                                icon: Icons.menu_book_outlined,
                                onPressed: _readReflection,
                              ),
                            _RitualActionChip(
                              label: day.personalThought != null
                                  ? 'Düşünce kayıtlı'
                                  : 'Düşünce bırak',
                              icon: Icons.edit_outlined,
                              onPressed: _writeThought,
                              subdued: day.personalThought != null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: _illustrationHeight,
                    child: const EnergyIllustration(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RitualActionChip extends StatefulWidget {
  const _RitualActionChip({
    required this.label,
    required this.icon,
    this.onPressed,
    this.subdued = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool subdued;

  @override
  State<_RitualActionChip> createState() => _RitualActionChipState();
}

class _RitualActionChipState extends State<_RitualActionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final scale = HomeReward.pressScale(_pressed && enabled);

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: scale,
        duration: HomeReward.press,
        curve: HomeReward.curve,
        child: AnimatedOpacity(
          opacity: widget.subdued ? 0.72 : 1.0,
          duration: HomeFocus.transition,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 1,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.sm,
              border: Border.all(
                color: AppColors.gold.withValues(
                  alpha: widget.subdued ? 0.16 : 0.28,
                ),
              ),
              color: AppColors.surface.withValues(
                alpha: widget.subdued ? 0.18 : 0.28,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 14,
                  color: AppColors.goldLight.withValues(
                    alpha: widget.subdued ? 0.55 : 0.78,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  widget.label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.goldLight.withValues(
                      alpha: widget.subdued ? 0.58 : 0.82,
                    ),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
