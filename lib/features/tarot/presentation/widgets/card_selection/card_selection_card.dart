/// OR-1040 / OR-428 — Selectable face-down tarot card with sacred touch.
library;

import 'package:flutter/material.dart';

import '../../../../../core/audio/oracly_feedback_gate.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../../../shared/widgets/oracly_pressable.dart';
import '../../../motion/tarot_cinematic_motion.dart';
import '../../../theme/tarot_tokens.dart';
import '../shuffle/shuffle_card_face.dart';
import 'card_selection_shadows.dart';

class CardSelectionCard extends StatefulWidget {
  const CardSelectionCard({
    super.key,
    required this.index,
    required this.selected,
    required this.dimmed,
    required this.entrance,
    required this.floatOffset,
    required this.onTap,
    this.onPressChanged,
    this.nearbyEmphasis = 1,
    this.surfaceLight = 0,
    this.cardWidth = 64,
    this.cardHeight = 104,
  });

  final int index;
  final bool selected;
  final bool dimmed;
  final double entrance;
  final double floatOffset;
  final VoidCallback onTap;
  final ValueChanged<bool>? onPressChanged;
  final double nearbyEmphasis;
  final double surfaceLight;
  final double cardWidth;
  final double cardHeight;

  @override
  State<CardSelectionCard> createState() => _CardSelectionCardState();
}

class _CardSelectionCardState extends State<CardSelectionCard>
    with TickerProviderStateMixin {
  late final AnimationController _press;
  late final AnimationController _ripple;

  Offset _contact = Offset.zero;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: OraclySignatureMaterials.pressDuration,
    );
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(CardSelectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _holding = false;
      _press.reverse();
    }
  }

  @override
  void dispose() {
    _press.dispose();
    _ripple.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.dimmed || widget.selected) return;
    _contact = details.localPosition;
    setState(() => _holding = true);
    _press.forward();
    _ripple.forward(from: 0);
    widget.onPressChanged?.call(true);
  }

  void _releasePress() {
    if (!_holding) return;
    setState(() => _holding = false);
    _press.reverse();
    widget.onPressChanged?.call(false);
  }

  void _handleTap() {
    OraclyTouchFeedback.selection();
    OraclyFeedbackGate.cardMove();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    // Fan slot owns the main rise; this is a quiet local acknowledgment.
    final lift = widget.selected ? -8.0 : 0.0;
    final dimOpacity = widget.dimmed ? 0.52 : 1.0;
    final emphasis = widget.nearbyEmphasis.clamp(0.82, 1.0);
    final slideY = (1 - widget.entrance) * 72;
    final selectedGrow = widget.selected ? 1.045 : 1.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_press, _ripple]),
      builder: (context, _) {
        final touch = TarotCinematicMotion.curve(
          Curves.easeOutCubic,
          _press.value,
        );
        final rippleT = TarotCinematicMotion.curve(
          Curves.easeOutCubic,
          _ripple.value,
        );

        final cx = widget.cardWidth / 2;
        final cy = widget.cardHeight / 2;
        final nx = ((_contact.dx - cx) / cx).clamp(-1.0, 1.0);
        final ny = ((_contact.dy - cy) / cy).clamp(-1.0, 1.0);
        final tiltX = ny * 0.03 * touch;
        final tiltY = -nx * 0.024 * touch;
        // Touch lifts the card forward off the velvet.
        final liftTouch = -touch * 12;
        final grow = 1.0 + touch * 0.045;

        return Opacity(
          opacity: (dimOpacity * emphasis * widget.entrance.clamp(0.0, 1.0))
              .clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, slideY + widget.floatOffset + lift + liftTouch),
            child: Transform.scale(
              scale: emphasis * grow * selectedGrow,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0014)
                  ..rotateX(tiltX)
                  ..rotateY(tiltY),
                child: GestureDetector(
                  onTapDown: _handleTapDown,
                  onTapUp: (_) => _releasePress(),
                  onTapCancel: _releasePress,
                  onTap: widget.dimmed || widget.selected ? null : _handleTap,
                  child: AnimatedContainer(
                    duration: widget.selected
                        ? TarotCinematicMotion.cardMove
                        : OraclySignatureMaterials.pressDuration,
                    curve: widget.selected
                        ? TarotCinematicMotion.weight
                        : OraclySignatureMaterials.curve,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(TarotTokens.cardCornerRadius),
                      border: Border.all(
                        color: AppColors.goldLight.withValues(
                          alpha: widget.selected
                              ? 0.28
                              : 0.08 + touch * 0.28,
                        ),
                        width: widget.selected ? 0.8 : 0.7,
                      ),
                      boxShadow: cardSelectionShadows(
                        touch: _press.value,
                        selected: widget.selected,
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ShuffleCardFace(
                          width: widget.cardWidth,
                          height: widget.cardHeight,
                          elevation: widget.selected
                              ? 0.82
                              : 0.52 + touch * 0.38,
                          lightBiasX:
                              (widget.floatOffset / 24).clamp(-0.18, 0.18) +
                                  (_contact.dx / widget.cardWidth - 0.5) *
                                      touch *
                                      0.1,
                          lightBiasY:
                              (widget.floatOffset / 32).clamp(-0.12, 0.12) +
                                  (_contact.dy / widget.cardHeight - 0.5) *
                                      touch *
                                      0.08,
                          touchDepth: touch,
                        ),
                        if (touch > 0.02)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    TarotTokens.cardCornerRadius,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      OraclySignaturePalette.champagne
                                          .withValues(alpha: touch * 0.14),
                                      Colors.transparent,
                                      OraclySignaturePalette.champagneDeep
                                          .withValues(alpha: touch * 0.07),
                                    ],
                                    stops: const [0.0, 0.45, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (_ripple.value > 0 && _ripple.value < 1)
                          Positioned(
                            left: _contact.dx - 28 - rippleT * 18,
                            top: _contact.dy - 28 - rippleT * 18,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: (1 - rippleT) * 0.28,
                                child: Container(
                                  width: 56 + rippleT * 36,
                                  height: 56 + rippleT * 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        OraclySignaturePalette.champagne
                                            .withValues(alpha: 0.16),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (widget.surfaceLight > 0.02)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    TarotTokens.cardCornerRadius,
                                  ),
                                  gradient: RadialGradient(
                                    center: const Alignment(0, -0.35),
                                    radius: 1.1,
                                    colors: [
                                      AppColors.goldLight.withValues(
                                        alpha: widget.surfaceLight * 0.14,
                                      ),
                                      AppColors.transparent,
                                    ],
                                  ),
                                ),
                              ),
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
}
