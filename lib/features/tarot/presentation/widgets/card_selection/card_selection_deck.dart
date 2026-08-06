/// OR-1040 — Seven-card arc deck with stagger entrance and float.
library;

import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import 'card_selection_ambience.dart';
import 'card_selection_card.dart';
import 'sacred_moment.dart';

class CardSelectionDeck extends StatefulWidget {
  const CardSelectionDeck({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.sacred = 0,
    this.sacredLinear = 0,
    this.cardCount = 7,
  });

  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final double sacred;
  final double sacredLinear;
  final int cardCount;

  @override
  State<CardSelectionDeck> createState() => _CardSelectionDeckState();
}

class _CardSelectionDeckState extends State<CardSelectionDeck>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _float;
  int? _pressingIndex;

  static const _cardWidth = 64.0;
  static const _cardHeight = 104.0;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6800),
    )..repeat(reverse: true);
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
    return Curves.easeOutCubic.transform((t - start) / (end - start));
  }

  double _nearbyEmphasis(int index) {
    final focusIndex = widget.selectedIndex ?? _pressingIndex;
    if (focusIndex == null) return 1;
    if (index == focusIndex) return 1;
    final distance = (index - focusIndex).abs();
    if (distance == 1) return 0.955;
    if (distance == 2) return 0.975;
    return 0.99;
  }

  void _handlePressChanged(int index, bool pressed) {
    if (!mounted) return;
    if (!pressed && widget.selectedIndex != null) {
      if (_pressingIndex != null) {
        setState(() => _pressingIndex = null);
      }
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
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              CardSelectionAmbience(
                sacred: widget.sacred,
                sacredLinear: widget.sacredLinear,
              ),
              for (var i = 0; i < widget.cardCount; i++) _buildCard(i, floatBase),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(int index, double floatBase) {
    final mid = (widget.cardCount - 1) / 2;
    final t = mid == 0 ? 0.0 : (index - mid) / mid;
    final angle = t * 0.32;
    final dx = t * 46;
    final dy = cos(angle.abs()) * 10;
    final floatPhase = sin(_float.value * pi * 2 + index * 0.7) *
        2.5 *
        (1 - SacredMoment.deckFocus(widget.sacredLinear) * 0.94);
    final selected = widget.selectedIndex == index;
    final dimmed = widget.selectedIndex != null && !selected;
    final recede = dimmed ? 1 - widget.sacred * 0.10 : 1.0;
    final neighborScale = _nearbyEmphasis(index);

    return Positioned(
      bottom: 24 + dy,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..translateByDouble(dx, 0, 0, 1)
          ..rotateY(t * 0.22)
          ..rotateZ(angle),
        child: Transform.scale(
          scale: recede,
          child: CardSelectionCard(
            index: index,
            selected: selected,
            dimmed: dimmed,
            entrance: _entranceFor(index),
            floatOffset: floatBase + floatPhase,
            nearbyEmphasis: neighborScale,
            onPressChanged: (pressed) => _handlePressChanged(index, pressed),
            surfaceLight: selected
                ? SacredMoment.surfaceAcknowledgment(widget.sacredLinear)
                : 0,
            onTap: () => widget.onSelect(index),
            cardWidth: _cardWidth,
            cardHeight: _cardHeight,
          ),
        ),
      ),
    );
  }
}
