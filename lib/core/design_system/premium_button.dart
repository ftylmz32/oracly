/// EPIC-021 / EPIC-026 — Reusable premium button with cinematic glow.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_gradients.dart';
import 'app_glows.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'micro_details/micro_detail_painters.dart';
import 'micro_details/micro_detail_tokens.dart';
import '../../shared/widgets/chamber_waiting_orb.dart';

/// Visual emphasis for [PremiumButton].
enum PremiumButtonVariant {
  primary,
  secondary,
  ghost,
  outline,
  premium,
}

/// Layout density for [PremiumButton].
enum PremiumButtonSize {
  small,
  medium,
  large,
}

/// Centralized CTA — primary glow expands on press, contracts on release.
class PremiumButton extends StatefulWidget {
  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.enabled = true,
    this.variant = PremiumButtonVariant.primary,
    this.size = PremiumButtonSize.medium,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final bool enabled;
  final PremiumButtonVariant variant;
  final PremiumButtonSize size;

  bool get _interactive => enabled && !isLoading && onPressed != null;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with TickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _glowBreath;
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    final seed = Object.hash(widget.variant, widget.key);
    _glowBreath = AnimationController(
      vsync: this,
      duration: MicroDetailTokens.buttonGlowCycle,
    )..repeat(reverse: true);
    _sweep = AnimationController(
      vsync: this,
      duration: MicroDetailTokens.sweepDurationFor(seed),
    )..repeat();
  }

  @override
  void dispose() {
    _glowBreath.dispose();
    _sweep.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _PremiumButtonMetrics._for(widget.size);
    final foreground = _PremiumButtonMetrics._foregroundFor(
      widget.variant,
      widget._interactive,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_glowBreath, _sweep]),
      builder: (context, _) {
        final breath = Curves.easeInOut.transform(_glowBreath.value);
        final glowStrength = _pressed ? 0.55 : 0.85 + breath * 0.15;
        final shadowLift = math.sin(breath * math.pi * 2) * 1.2;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: AppRadius.s20,
            boxShadow: widget._interactive && _emitsLight(widget.variant)
                ? _glowFor(widget.variant, glowStrength, shadowLift)
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              enableFeedback: false,
              onTap: widget._interactive ? widget.onPressed : null,
              onTapDown: widget._interactive ? (_) => _setPressed(true) : null,
              onTapUp: widget._interactive ? (_) => _setPressed(false) : null,
              onTapCancel: widget._interactive ? () => _setPressed(false) : null,
              borderRadius: AppRadius.s20,
              child: AnimatedOpacity(
                opacity: widget._interactive ? 1 : 0.55,
                duration: const Duration(milliseconds: 180),
                child: AnimatedScale(
                  scale: _pressed ? 0.97 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: widget.isExpanded ? double.infinity : null,
                    decoration: _decorationFor(
                      widget.variant,
                      widget._interactive,
                      _pressed,
                    ),
                    padding: metrics.padding,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_emitsLight(widget.variant) && widget._interactive)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: AppRadius.s20,
                                child: CustomPaint(
                                  painter: ButtonHighlightSweepPainter(
                                    sweepPhase: _sweep.value,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Center(
                          child: widget.isLoading
                              ? ChamberWaitingOrb(size: metrics.iconSize)
                              : _ButtonRow(
                                  label: widget.label,
                                  icon: widget.icon,
                                  foreground: foreground,
                                  iconSize: metrics.iconSize,
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
      },
    );
  }

  static bool _emitsLight(PremiumButtonVariant variant) =>
      variant == PremiumButtonVariant.primary ||
      variant == PremiumButtonVariant.premium;

  static List<BoxShadow> _glowFor(
    PremiumButtonVariant variant,
    double strength,
    double shadowLift,
  ) {
    return switch (variant) {
      PremiumButtonVariant.primary => AppShadows.goldGlow
          .map(
            (s) => BoxShadow(
              color: AppColors.goldGlow.withValues(
                alpha: 0.28 * strength,
              ),
              blurRadius: s.blurRadius * (0.8 + strength * 0.2),
              spreadRadius: s.spreadRadius * strength,
              offset: Offset(s.offset.dx, s.offset.dy + shadowLift),
            ),
          )
          .toList(),
      PremiumButtonVariant.premium => AppGlows.large(strength: strength),
      _ => const [],
    };
  }

  static BoxDecoration _decorationFor(
    PremiumButtonVariant variant,
    bool interactive,
    bool pressed,
  ) {
    return switch (variant) {
      PremiumButtonVariant.primary => BoxDecoration(
          gradient: AppGradients.gold,
          borderRadius: AppRadius.s24,
          border: Border.all(
            color: AppColors.goldLight.withValues(alpha: 0.35),
            width: AppBorderWidth.hairline,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldLight.withValues(
                alpha: pressed ? 0.18 : 0.10,
              ),
              blurRadius: pressed ? 6 : 12,
              spreadRadius: pressed ? -2 : -1,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      PremiumButtonVariant.secondary => BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.55),
          borderRadius: AppRadius.s24,
          border: Border.all(
            color: AppColors.goldDeep.withValues(alpha: 0.42),
            width: AppBorderWidth.hairline,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldGlow.withValues(alpha: 0.06),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
      PremiumButtonVariant.ghost => BoxDecoration(
          color: AppColors.transparent,
          borderRadius: AppRadius.s24,
        ),
      PremiumButtonVariant.outline => BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.28),
          borderRadius: AppRadius.s24,
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.40),
            width: AppBorderWidth.hairline,
          ),
        ),
      PremiumButtonVariant.premium => BoxDecoration(
          gradient: AppGradients.gold,
          borderRadius: AppRadius.s24,
          border: Border.all(
            color: AppColors.goldLight.withValues(alpha: pressed ? 0.48 : 0.32),
            width: AppBorderWidth.hairline,
          ),
        ),
    };
  }
}

abstract final class _PremiumButtonMetrics {
  static _Metrics _for(PremiumButtonSize size) {
    return switch (size) {
      PremiumButtonSize.small => _Metrics(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s8,
          ),
          iconSize: AppSpacing.s16,
        ),
      PremiumButtonSize.medium => _Metrics(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s24,
            vertical: AppSpacing.s12,
          ),
          iconSize: AppSpacing.s20,
        ),
      PremiumButtonSize.large => _Metrics(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s32,
            vertical: AppSpacing.s16,
          ),
          iconSize: AppSpacing.s24,
        ),
    };
  }

  static Color _foregroundFor(PremiumButtonVariant variant, bool interactive) {
    final color = switch (variant) {
      PremiumButtonVariant.primary => AppColors.background,
      PremiumButtonVariant.secondary => AppColors.goldLight,
      PremiumButtonVariant.ghost => AppColors.goldLight,
      PremiumButtonVariant.outline => AppColors.goldLight,
      PremiumButtonVariant.premium => AppColors.textPrimary,
    };
    return interactive ? color : AppColors.textHint;
  }
}

@immutable
class _Metrics {
  const _Metrics({
    required this.padding,
    required this.iconSize,
  });

  final EdgeInsets padding;
  final double iconSize;
}

class _ButtonRow extends StatelessWidget {
  const _ButtonRow({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.iconSize,
  });

  final String label;
  final IconData? icon;
  final Color foreground;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: AppTypography.button.copyWith(color: foreground),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (icon == null) return text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize, color: foreground),
        SizedBox(width: AppSpacing.s8),
        Flexible(child: text),
      ],
    );
  }
}
