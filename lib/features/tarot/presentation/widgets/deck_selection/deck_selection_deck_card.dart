/// OR-1020 / OR-420 — Cinematic sacred deck selection card.
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'deck_selection_cinematic.dart';
import 'deck_selection_data.dart';
import 'deck_visual_style.dart';

class DeckSelectionDeckCard extends StatefulWidget {
  const DeckSelectionDeckCard({
    super.key,
    required this.deck,
    required this.selected,
    required this.onTap,
    this.onPreview,
    this.restIndex = 0,
  });

  final TarotDeckOption deck;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onPreview;
  /// Handcrafted variation index — visual only.
  final int restIndex;

  @override
  State<DeckSelectionDeckCard> createState() => _DeckSelectionDeckCardState();
}

class _DeckSelectionDeckCardState extends State<DeckSelectionDeckCard>
    with TickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _pressT;
  bool _pressing = false;
  Timer? _pressDelay;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: DeckCinematic.pressDuration,
    );
    _pressT = CurvedAnimation(
      parent: _press,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _pressDelay?.cancel();
    _press.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _pressing = true;
    _pressDelay?.cancel();
    _pressDelay = Timer(DeckCinematic.pressDelay, () {
      if (mounted && _pressing) _press.forward();
    });
  }

  void _releasePress() {
    _pressing = false;
    _pressDelay?.cancel();
    _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final pose = DeckCinematic.restPose(
      widget.restIndex,
      selected: widget.selected,
    );
    final style = widget.deck.visualStyle;
    final isGolden = style == DeckVisualStyle.golden;

    return AnimatedBuilder(
      animation: _pressT,
      builder: (context, child) {
        final pressT = _pressT.value;
        final lift = pose.offset.dy +
            (widget.selected ? 0 : 0) +
            pressT * DeckCinematic.pressLift;
        final glow = (widget.selected ? 0.35 : 0) + pressT * 0.25;

        return AnimatedOpacity(
          duration: DeckCinematic.pressDuration,
          opacity: pose.opacity + pressT * 0.04,
          child: Transform.translate(
            offset: Offset(pose.offset.dx, lift),
            child: Transform.rotate(
              angle: pose.rotation,
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: (_) => _releasePress(),
                onTapCancel: _releasePress,
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: DeckCinematic.pressDuration,
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.lg,
                    boxShadow: DeckCinematic.cardShadows(
                      selected: widget.selected,
                      accent: widget.deck.accent,
                      depth: pose.depth,
                      glow: glow,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.lg,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: widget.selected ? 20 : 22 + pose.depth * 0.5,
                        sigmaY: widget.selected ? 20 : 22 + pose.depth * 0.5,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.surfaceElevated.withValues(
                                alpha: widget.selected ? 0.96 : 0.90,
                              ),
                              AppColors.surface.withValues(
                                alpha: widget.selected ? 0.92 : 0.84,
                              ),
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.gold.withValues(
                              alpha: widget.selected
                                  ? (isGolden ? 0.72 : 0.50)
                                  : 0.20 + pressT * 0.12,
                            ),
                            width: widget.selected
                                ? AppBorderWidth.thin
                                : AppBorderWidth.hairline,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.insetCard,
                            AppSpacing.insetCard + AppSpacing.xs,
                            AppSpacing.insetCard,
                            AppSpacing.insetCard,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DeckArtwork(
                                deck: widget.deck,
                                selected: widget.selected,
                                restIndex: widget.restIndex,
                                pressT: pressT,
                              ),
                              SizedBox(width: AppSpacing.md + AppSpacing.xs),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.deck.name,
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: AppColors.goldLight.withValues(
                                          alpha: widget.selected ? 0.98 : 0.88,
                                        ),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing:
                                            style == DeckVisualStyle.classic
                                                ? 0.15
                                                : 0.35,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: AppSpacing.sm),
                                    Text(
                                      widget.deck.description,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary.withValues(
                                          alpha: widget.selected ? 0.92 : 0.78,
                                        ),
                                        height: 1.5,
                                        fontSize: 12,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: AppSpacing.md),
                                    Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.xs,
                                      children: [
                                        _MetaChip(
                                          label: '${widget.deck.cardCount} kart',
                                          icon: Icons.layers_rounded,
                                        ),
                                        _MetaChip(
                                          label: widget.deck.energyTag,
                                          icon: Icons.bolt_rounded,
                                          accent: widget.deck.accent,
                                        ),
                                      ],
                                    ),
                                    if (widget.onPreview != null) ...[
                                      SizedBox(height: AppSpacing.sm),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: _PreviewButton(
                                          onPressed: widget.onPreview!,
                                        ),
                                      ),
                                    ],
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
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DeckArtwork extends StatefulWidget {
  const _DeckArtwork({
    required this.deck,
    required this.selected,
    required this.restIndex,
    required this.pressT,
  });

  final TarotDeckOption deck;
  final bool selected;
  final int restIndex;
  final double pressT;

  static const double _width = 102;
  static const double _height = 136;

  @override
  State<_DeckArtwork> createState() => _DeckArtworkState();
}

class _DeckArtworkState extends State<_DeckArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _light;

  @override
  void initState() {
    super.initState();
    _light = AnimationController(
      vsync: this,
      duration: DeckCinematic.lightTravelDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.deck.visualStyle;
    final cardRotations = <double>[0.014, -0.010, 0.008, -0.012, 0.011, -0.007];
    final cardOffsets = <Offset>[
      const Offset(2, 1),
      const Offset(-1, 2),
      const Offset(1, 0),
      const Offset(-2, 1),
      const Offset(0, 2),
      const Offset(1, 1),
    ];
    final ri = widget.restIndex.clamp(0, cardRotations.length - 1);
    final stackLift = widget.selected ? -2.0 - widget.pressT * 2 : widget.pressT * -1.5;

    return AnimatedBuilder(
      animation: _light,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, stackLift),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.md,
              boxShadow: [
                BoxShadow(
                  color: widget.deck.accent.withValues(
                    alpha: widget.selected ? 0.38 : 0.16,
                  ),
                  blurRadius: widget.selected ? 16 : 10,
                  offset: Offset(0, widget.selected ? 4 : 6),
                  spreadRadius: widget.selected ? -1 : -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.md,
              child: SizedBox(
                width: _DeckArtwork._width,
                height: _DeckArtwork._height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var layer = 2; layer >= 0; layer--)
                      Positioned(
                        left: layer * 1.5 + cardOffsets[ri].dx,
                        top: layer * 2.0 + cardOffsets[ri].dy,
                        child: Transform.rotate(
                          angle: cardRotations[ri] * (layer + 1) * 0.85,
                          child: _SingleCardBack(
                            deck: widget.deck,
                            style: style,
                            lightPhase: _light.value + layer * 0.08,
                            selected: widget.selected && layer == 0,
                            width: _DeckArtwork._width - layer * 3,
                            height: _DeckArtwork._height - layer * 4,
                            opacity: layer == 0 ? 1.0 : 0.35 - layer * 0.08,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SingleCardBack extends StatelessWidget {
  const _SingleCardBack({
    required this.deck,
    required this.style,
    required this.lightPhase,
    required this.selected,
    required this.width,
    required this.height,
    this.opacity = 1,
  });

  final TarotDeckOption deck;
  final DeckVisualStyle style;
  final double lightPhase;
  final bool selected;
  final double width;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: deck.artGradient,
          ),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: selected ? 0.55 : 0.30),
            width: selected ? AppBorderWidth.thin : AppBorderWidth.hairline,
          ),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.md,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DeckArtworkAtmosphere(style: style),
                CustomPaint(
                  painter: DeckSelectionCardBackPainter(
                    deck: deck,
                    lightPhase: lightPhase,
                    selected: selected,
                  ),
                ),
                CustomPaint(
                  painter: DeckArtworkReflectionPainter(phase: lightPhase),
                ),
                Center(
                  child: Icon(
                    deck.icon,
                    size: AppSpacing.xxl,
                    color: AppColors.white.withValues(
                      alpha: style == DeckVisualStyle.golden ? 0.88 : 0.72,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.sm,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.round,
                        color: AppColors.background.withValues(alpha: 0.55),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.28),
                          width: AppBorderWidth.hairline,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs / 2,
                        ),
                        child: Text(
                          '${deck.cardCount}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.icon,
    this.accent,
  });

  final String label;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.round,
        color: AppColors.surface.withValues(alpha: 0.65),
        border: Border.all(
          color: (accent ?? AppColors.gold).withValues(alpha: 0.32),
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
              icon,
              size: AppSpacing.sm + 2,
              color: accent ?? AppColors.goldLight,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewButton extends StatefulWidget {
  const _PreviewButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_PreviewButton> createState() => _PreviewButtonState();
}

class _PreviewButtonState extends State<_PreviewButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Önizle',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.88 : 1,
          duration: const Duration(milliseconds: 220),
          child: AnimatedScale(
            scale: _pressed ? 0.982 : 1,
            duration: const Duration(milliseconds: 220),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: AppSpacing.sm + 2,
                    color: AppColors.gold.withValues(alpha: 0.55),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Önizle',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
