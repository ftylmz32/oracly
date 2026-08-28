/// OR-402 / OR-407 — Reusable crystal glass shell for Tarot Home sections.
library;

import 'package:flutter/material.dart';

import '../../../../../core/design_system/app_layout.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import 'oracly_sacred_identity.dart';

/// Layered crystal surface — consistent luxury language across home sections.
class TarotHomeSectionShell extends StatelessWidget {
  const TarotHomeSectionShell({
    super.key,
    required this.child,
    this.padding,
    this.showOrnaments = true,
    this.showStars = false,
    this.radius = AppRadius.lg,
    this.lightTier = OraclyLightTier.midChamber,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showOrnaments;
  final bool showStars;
  final BorderRadius radius;
  final OraclyLightTier lightTier;

  @override
  Widget build(BuildContext context) {
    return OraclyCrystalFrame(
      kind: OraclyCrystalFrameKind.chamber,
      radius: radius,
      lightTier: lightTier,
      padding: padding,
      showOrnaments: showOrnaments,
      showStars: showStars,
      child: child,
    );
  }
}

/// Engraved mystical icon badge.
class TarotHomeMysticIcon extends StatelessWidget {
  const TarotHomeMysticIcon({
    super.key,
    required this.icon,
    this.size = 56,
    this.iconSize = 28,
    this.accent = OraclySacredPalette.champagne,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            OraclySacredPalette.crystalVeil.withValues(alpha: 0.82),
            OraclySacredPalette.deepViolet.withValues(alpha: 0.94),
          ],
        ),
        border: Border.all(
          color: OraclySacredPalette.goldEngrave(0.28),
          width: AppBorderWidth.hairline,
        ),
        boxShadow: [
          BoxShadow(
            color: OraclySacredPalette.purpleEnergy.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: iconSize,
          color: accent.withValues(alpha: 0.88),
          shadows: [
            Shadow(
              color: accent.withValues(alpha: 0.18),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

/// Luxury button — crystal surface, gold highlight, no Material ripple.
class TarotHomeLuxuryButton extends StatefulWidget {
  const TarotHomeLuxuryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expanded = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;

  static Duration get pressDuration => OraclyMotion.press;

  @override
  State<TarotHomeLuxuryButton> createState() => _TarotHomeLuxuryButtonState();
}

class _TarotHomeLuxuryButtonState extends State<TarotHomeLuxuryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    final button = OraclyPressable(
      onTap: enabled ? widget.onPressed : null,
      enabled: enabled,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedContainer(
          duration: OraclyMotion.press,
          constraints: BoxConstraints(
            minHeight: AppLayout.referencePrimaryButtonHeight,
          ),
          padding: AppLayout.referencePrimaryButtonPadding,
          decoration: BoxDecoration(
            borderRadius: AppRadius.round,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? _pressed
                      ? [
                          OraclySacredPalette.champagneDeep,
                          OraclySacredPalette.champagneShadow,
                          OraclySacredPalette.champagneShadow
                              .withValues(alpha: 0.92),
                        ]
                      : [
                          OraclySacredPalette.champagne,
                          OraclySacredPalette.champagneDeep,
                          OraclySacredPalette.champagneShadow,
                        ]
                  : [
                      OraclySacredPalette.champagne.withValues(alpha: 0.28),
                      OraclySacredPalette.champagneDeep.withValues(alpha: 0.28),
                    ],
            ),
            border: Border.all(
              color: OraclySacredPalette.champagne
                  .withValues(alpha: enabled ? (_pressed ? 0.48 : 0.42) : 0.16),
              width: AppBorderWidth.hairline + (_pressed ? 0.15 : 0),
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: OraclySacredPalette.champagneShadow.withValues(
                        alpha: _pressed ? 0.22 : 0.26,
                      ),
                      blurRadius: _pressed ? 6 : 16,
                      offset: Offset(0, _pressed ? 1 : 4),
                      spreadRadius: _pressed ? -1 : 0,
                    ),
                    if (_pressed)
                      BoxShadow(
                        color: OraclySacredPalette.champagne
                            .withValues(alpha: 0.14),
                        blurRadius: 12,
                        spreadRadius: -4,
                        offset: const Offset(0, 0),
                      ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                child: Container(
                  height: _pressed ? 1.0 : 0.8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.transparent,
                        Colors.white.withValues(alpha: _pressed ? 0.32 : 0.22),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              if (_pressed)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.round,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.10),
                            Colors.transparent,
                            OraclySacredPalette.champagneDeep
                                .withValues(alpha: 0.06),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Center(
                child: Row(
                  mainAxisSize:
                      widget.expanded ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: AppLayout.referenceIconSize,
                        color: OraclySacredPalette.deepViolet,
                      ),
                      SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: OraclySacredPalette.deepViolet,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.45,
                        fontSize: 15,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );

    return widget.expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Subtle text action — for secondary navigation like "Tümü".
class TarotHomeGhostButton extends StatefulWidget {
  const TarotHomeGhostButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<TarotHomeGhostButton> createState() => _TarotHomeGhostButtonState();
}

class _TarotHomeGhostButtonState extends State<TarotHomeGhostButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: AnimatedOpacity(
          opacity: _pressed ? OraclyMotion.pressOpacity : 1.0,
          duration: _pressed ? OraclyMotion.press : OraclyMotion.pressRelease,
          curve: _pressed ? OraclyMotion.curve : OraclyMotion.releaseCurve,
          child: Text(
            widget.label,
            style: TextStyle(
              color: OraclySacredPalette.champagneDeep.withValues(alpha: 0.58),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.55,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact crystal tile for horizontal carousel items.
class TarotHomeCrystalTile extends StatelessWidget {
  const TarotHomeCrystalTile({
    super.key,
    required this.child,
    this.width = 200,
    this.height = 132,
    this.onTap,
    this.lightTier = OraclyLightTier.midChamber,
  });

  final Widget child;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final OraclyLightTier lightTier;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: OraclyCrystalFrame(
          kind: OraclyCrystalFrameKind.chamber,
          radius: AppRadius.lg,
          lightTier: lightTier,
          showOrnaments: false,
          padding: EdgeInsets.all(OraclyRhythm.tileInset),
          child: child,
        ),
      ),
    );
  }
}
