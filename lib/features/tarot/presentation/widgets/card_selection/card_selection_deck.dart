/// OR-1040 — Seven-card arc deck with stagger entrance and float.
library;

import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import '../../../motion/tarot_cinematic_motion.dart';
import '../../../../../core/theme/oracly_quiet_motion.dart';
import '../../../../../core/theme/oracly_reduced_motion.dart';
import 'card_selection_ambience.dart';
import 'card_selection_fan_slot.dart';
import 'card_selection_velvet.dart';
import 'sacred_moment.dart';

class CardSelectionDeck extends StatefulWidget {
  const CardSelectionDeck({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.sacred = 0,
    this.sacredLinear = 0,
    this.cardCount = 7,
    this.hideSelectedFace = false,
  });

  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final double sacred;
  final double sacredLinear;
  final int cardCount;
  final bool hideSelectedFace;

  @override
  State<CardSelectionDeck> createState() => _CardSelectionDeckState();
}

class _CardSelectionDeckState extends State<CardSelectionDeck>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _float;
  int? _pressingIndex;

  static const _cardWidth = 72.0;
  static const _cardHeight = 116.0;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _float = AnimationController(
      vsync: this,
      duration: TarotCinematicMotion.ambient,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyReducedMotion.playOnce(context, _entrance);
    OraclyQuietMotion.ambient(context, _float, reverse: true);
  }

  @override
  void didUpdateWidget(CardSelectionDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != null &&
        widget.selectedIndex != oldWidget.selectedIndex) {
      _pressingIndex = null;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _float.dispose();
    super.dispose();
  }

  double _entranceFor(int index) {
    final start = index * 0.11;
    final end = start + 0.38;
    final t = _entrance.value;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return Curves.easeOutCubic.transform(
      ((t - start) / (end - start)).clamp(0.0, 1.0),
    );
  }

  double _nearbyEmphasis(int index) {
    final focusIndex = widget.selectedIndex ?? _pressingIndex;
    if (focusIndex == null) return 1;
    if (index == focusIndex) return 1;
    final distance = (index - focusIndex).abs();
    // Touch: surrounding cards slightly compress.
    if (distance == 1) return 0.86;
    if (distance == 2) return 0.92;
    return 0.97;
  }

  void _handlePressChanged(int index, bool pressed) {
    if (!mounted) return;
    if (!pressed && widget.selectedIndex != null) {
      if (_pressingIndex != null) setState(() => _pressingIndex = null);
      return;
    }
    setState(() => _pressingIndex = pressed ? index : null);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, _float]),
      builder: (context, _) {
        final focus = SacredMoment.deckFocus(widget.sacredLinear);
        final floatBase = (_float.value - 0.5) * 5 * (1 - focus * 0.92);
        return SizedBox(
          width: double.infinity,
          height: 268,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            children: [
              CardSelectionAmbience(
                sacred: widget.sacred,
                sacredLinear: widget.sacredLinear,
              ),
              Positioned(
                bottom: 8,
                child: CardSelectionVelvet(
                  intensity: 1 - SacredMoment.deckFocus(widget.sacredLinear) * 0.35,
                ),
              ),
              for (var i = 0; i < widget.cardCount; i++)
                _slot(i, floatBase),
            ],
          ),
        );
      },
    );
  }

  Widget _slot(int index, double floatBase) {
    final mid = (widget.cardCount - 1) / 2.0;
    final t = mid == 0 ? 0.0 : (index - mid) / mid;
    final angle = t * 0.42;
    final selected = widget.selectedIndex == index;
    final dimmed = widget.selectedIndex != null && !selected;
    final phase = sin(_float.value * pi * 2 + index * 0.7) *
        1.1 *
        (1 - SacredMoment.deckFocus(widget.sacredLinear) * 0.94);
    return Positioned(
      bottom: 28 + cos(angle.abs()) * 14,
      child: CardSelectionFanSlot(
        index: index,
        mid: mid,
        dx: t * 54,
        angle: angle,
        t: t,
        selected: selected,
        dimmed: dimmed,
        recede: dimmed ? 1 - widget.sacred * 0.28 : 1.0,
        entrance: _entranceFor(index),
        floatOffset: floatBase + phase,
        nearbyEmphasis: _nearbyEmphasis(index),
        sacredLinear: widget.sacredLinear,
        onSelect: () => widget.onSelect(index),
        onPressChanged: (p) => _handlePressChanged(index, p),
        cardWidth: _cardWidth,
        cardHeight: _cardHeight,
        hideFace: selected && widget.hideSelectedFace,
      ),
    );
  }
}
