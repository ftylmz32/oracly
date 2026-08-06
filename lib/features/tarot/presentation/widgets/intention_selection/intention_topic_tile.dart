/// OR-404 — Premium crystal intention tile.
library;

import 'dart:math' show cos, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../tarot_home/oracly_sacred_identity.dart';
import 'intention_selection_data.dart';

class IntentionTopicTile extends StatefulWidget {
  const IntentionTopicTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final IntentionTopicOption option;
  final bool selected;
  final VoidCallback onTap;

  static Duration get pressDuration => OraclySilentMotion.press;

  @override
  State<IntentionTopicTile> createState() => _IntentionTopicTileState();
}

class _IntentionTopicTileState extends State<IntentionTopicTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: OraclySilentMotion.breath,
    );
    if (widget.selected) _breath.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant IntentionTopicTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!widget.selected && _breath.isAnimating) {
      _breath.stop();
      _breath.value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breathT = widget.selected ? _breath.value : 0.0;
    final borderAlpha = _pressed
        ? 0.34
        : widget.selected
            ? 0.28 + breathT * 0.06
            : 0.14;

    return OraclyPressable(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lg,
            boxShadow: [
              BoxShadow(
                color: OraclySacredPalette.obsidian.withValues(alpha: 0.36),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
              if (widget.selected)
                BoxShadow(
                  color: widget.option.glow.withValues(
                    alpha: 0.08 + breathT * 0.04,
                  ),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.lg,
            child: Stack(
              children: [
                Positioned.fill(
                  child: OraclyCrystalBodyLayers(
                    lightTier: widget.selected
                        ? OraclyLightTier.upperChamber
                        : OraclyLightTier.midChamber,
                    borderRadius: AppRadius.lg,
                  ),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: OraclySacredPalette.goldEngrave(borderAlpha),
                        width: widget.selected
                            ? AppBorderWidth.thin
                            : AppBorderWidth.hairline + 0.2,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.lg + AppSpacing.xs,
                        AppSpacing.md,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _MysticIcon(
                            icon: widget.option.icon,
                            accent: widget.option.accent,
                            active: widget.selected,
                            breathPhase: breathT,
                          ),
                          SizedBox(height: AppSpacing.md),
                          Text(
                            widget.option.title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: OraclySacredPalette.champagne.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs + 2),
                          Text(
                            widget.option.subtitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary.withValues(alpha: 0.72),
                              fontSize: 10.5,
                              height: 1.45,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const OraclySacredCornerOrnaments(inset: 8, size: 12),
                OraclyChampagneSpecular(
                  intensity: widget.selected ? 0.58 : 0.40,
                  horizontalInset: AppSpacing.lg,
                ),
                if (widget.selected)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _TileParticlesPainter(phase: breathT),
                      ),
                    ),
                  ),
              ],
          ),
        ),
      ),
    );
  }
}

class _MysticIcon extends StatelessWidget {
  const _MysticIcon({
    required this.icon,
    required this.accent,
    required this.active,
    required this.breathPhase,
  });

  final IconData icon;
  final Color accent;
  final bool active;
  final double breathPhase;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            accent.withValues(alpha: active ? 0.28 + breathPhase * 0.10 : 0.14),
            const Color(0xFF12071F).withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(
          color: OraclySacredPalette.goldEngrave(active ? 0.48 : 0.28),
          width: AppBorderWidth.hairline,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25 + breathPhase * 0.12),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(
          icon,
          size: 24,
          color: accent.withValues(alpha: 0.95),
          shadows: [
            Shadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _TileParticlesPainter extends CustomPainter {
  const _TileParticlesPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.35;
    for (var i = 0; i < 4; i++) {
      final t = phase * 6.28 + i * 1.4;
      canvas.drawCircle(
        Offset(cx + cos(t) * 28, cy + sin(t * 0.9) * 18),
        0.9,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = OraclySacredPalette.champagne.withValues(alpha: 0.08 + phase * 0.04),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TileParticlesPainter old) =>
      old.phase != phase;
}
