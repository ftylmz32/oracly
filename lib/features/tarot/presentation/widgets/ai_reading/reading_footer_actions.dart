/// OR-301+ — Premium footer: staggered buttons with tactile feedback.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/continuation/models/session_continuation.dart';
import '../../../../../core/continuation/widgets/session_continuation_link.dart';
import '../../../../../core/copy/session_ending_copy.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../features/discovery_share/models/shareable_discovery.dart';
import '../../../../../features/discovery_share/widgets/discovery_share_action.dart';
import '../../../copy/tarot_polish_copy.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../../../core/theme/oracly_quiet_motion.dart';
import 'reading_premium_animations.dart';
import 'reading_premium_tap_button.dart';
import 'reading_sacred_rhythm.dart';
import '../../../../../shared/widgets/oracly_pressable.dart';

export 'reading_premium_animations.dart' show readingPremiumFooterProgress;

double readingFooterProgress(double master) =>
    readingPremiumFooterProgress(master);

class ReadingFooterActions extends StatefulWidget {
  const ReadingFooterActions({
    super.key,
    required this.progress,
    this.exitProgress = 0,
    this.onNewReading,
    this.onSave,
    this.onAskOracle,
    this.onAddReflection,
    this.shareDiscovery,
  });

  final double progress;
  final double exitProgress;
  final VoidCallback? onNewReading;
  final Future<void> Function()? onSave;
  final VoidCallback? onAskOracle;
  final Future<void> Function()? onAddReflection;
  final ShareableDiscovery? shareDiscovery;

  @override
  State<ReadingFooterActions> createState() => _ReadingFooterActionsState();
}

class _ReadingFooterActionsState extends State<ReadingFooterActions>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _saveBusy = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _pulse);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_saveBusy || widget.onSave == null) return;
    setState(() => _saveBusy = true);
    OraclyTouchFeedback.acknowledge();
    await widget.onSave!();
    if (mounted) setState(() => _saveBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final askReveal = readingPremiumFooterPrimaryProgress(widget.progress);
    final saveReveal = readingPremiumFooterSaveProgress(widget.progress);
    final newReveal = readingPremiumFooterNewProgress(widget.progress);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        ReadingSacredRhythm.beforeFooter,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onAskOracle != null)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                children: [
                  _FooterStagger(
                    progress: askReveal,
                    exitProgress: widget.exitProgress,
                    child: _PrimaryAskButton(
                      pulse: _pulse,
                      onPressed: widget.onAskOracle,
                    ),
                  ),
                  _FooterStagger(
                    progress: askReveal,
                    exitProgress: widget.exitProgress,
                    child: Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        TarotPolishCopy.askOracleHint,
                        textAlign: TextAlign.center,
                        style: ReadingTypography.footnote(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (widget.onAskOracle != null)
            SessionContinuationLink(
              source: SessionContinuationSource.tarot,
              orAlreadyOffered: true,
            ),
          if (widget.shareDiscovery != null)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: _FooterStagger(
                progress: askReveal,
                exitProgress: widget.exitProgress,
                child: DiscoveryShareAction(discovery: widget.shareDiscovery!),
              ),
            ),
          if (widget.onSave != null)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: _FooterStagger(
                progress: saveReveal,
                exitProgress: widget.exitProgress,
                child: ReadingPremiumTapButton(
                  enabled: !_saveBusy,
                  glowColor: AppColors.gold,
                  onPressed: _handleSave,
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.lg,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.52),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_rounded,
                          size: AppSpacing.md,
                          color: AppColors.goldLight,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          OraclyL10n.t('tarot.action.save'),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (widget.onAddReflection != null && saveReveal > 0.2)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Opacity(
                opacity: saveReveal.clamp(0.0, 1.0),
                child: TextButton.icon(
                  onPressed: () => widget.onAddReflection?.call(),
                  icon: Icon(
                    Icons.edit_note_rounded,
                    size: 18,
                    color: AppColors.gold.withValues(alpha: 0.78),
                  ),
                  label: Text(
                    OraclyL10n.t('tarot.action.note'),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.goldLight.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          _FooterStagger(
            progress: newReveal,
            exitProgress: widget.exitProgress,
            child: ReadingPremiumTapButton(
              glowColor: AppColors.purple,
              onPressed: widget.onNewReading,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lg,
                  color: AppColors.surface.withValues(alpha: 0.45),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.22),
                  ),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: AppSpacing.md,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      OraclyL10n.t('tarot.action.new'),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (newReveal > 0.5)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: Opacity(
                opacity: (newReveal * (1 - widget.exitProgress)).clamp(0.0, 1.0),
                child: Text(
                  SessionEndingCopy.footerWhisper,
                  textAlign: TextAlign.center,
                  style: ReadingTypography.footnote(
                    color: AppColors.textHint.withValues(alpha: 0.78),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FooterStagger extends StatelessWidget {
  const _FooterStagger({
    required this.progress,
    required this.exitProgress,
    required this.child,
  });

  final double progress;
  final double exitProgress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: (progress * (1 - exitProgress)).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - progress) * 24 + exitProgress * 32),
        child: child,
      ),
    );
  }
}

class _PrimaryAskButton extends StatefulWidget {
  const _PrimaryAskButton({
    required this.pulse,
    this.onPressed,
  });

  final AnimationController pulse;
  final VoidCallback? onPressed;

  @override
  State<_PrimaryAskButton> createState() => _PrimaryAskButtonState();
}

class _PrimaryAskButtonState extends State<_PrimaryAskButton> {
  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: widget.pulse,
        builder: (context, _) {
          final glow = 0.5 + sin(widget.pulse.value * pi) * 0.18;
          final shimmer = widget.pulse.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lg,
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldGlow
                      .withValues(alpha: 0.10 + glow * 0.14),
                  blurRadius: 16 + glow * 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: AppColors.purpleGlow
                      .withValues(alpha: 0.10 + glow * 0.08),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.lg,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(
                            const Color(0xFF9B6DFF),
                            const Color(0xFFB794FF),
                            glow,
                          )!,
                          const Color(0xFF6B3FA0),
                          const Color(0xFF4A2578),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.gold
                            .withValues(alpha: 0.4 + glow * 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: AppColors.goldLight.withValues(alpha: 0.95),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            TarotPolishCopy.orOpen,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: ReadingTypography.cta(
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: FractionallySizedBox(
                        alignment: Alignment(-1 + shimmer * 2.2, 0),
                        widthFactor: 0.4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.12),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
