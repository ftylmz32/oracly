/// One fan slot — lift on choose, neighbors compress, card leaves the fan.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../motion/tarot_cinematic_motion.dart';
import 'card_selection_card.dart';
import 'sacred_moment.dart';

class CardSelectionFanSlot extends StatelessWidget {
  const CardSelectionFanSlot({
    super.key,
    required this.index,
    required this.mid,
    required this.dx,
    required this.angle,
    required this.t,
    required this.selected,
    required this.dimmed,
    required this.recede,
    required this.entrance,
    required this.floatOffset,
    required this.nearbyEmphasis,
    required this.sacredLinear,
    required this.onSelect,
    required this.onPressChanged,
    required this.cardWidth,
    required this.cardHeight,
    this.hideFace = false,
  });

  final int index;
  final double mid;
  final double dx;
  final double angle;
  final double t;
  final bool selected;
  final bool dimmed;
  final double recede;
  final double entrance;
  final double floatOffset;
  final double nearbyEmphasis;
  final double sacredLinear;
  final VoidCallback onSelect;
  final ValueChanged<bool> onPressChanged;
  final double cardWidth;
  final double cardHeight;
  final bool hideFace;

  @override
  Widget build(BuildContext context) {
    final pull = selected || dimmed ? 1.0 : 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: pull),
      duration: TarotCinematicMotion.cardMove,
      curve: TarotCinematicMotion.weight,
      builder: (context, travel, child) {
        if (selected) {
          // Quiet lift out of the fan — separate, not theatrical.
          final arcX = dx * (1 - travel);
          final arcY = -travel * 28 - sin(travel * pi) * 5;
          final grow = 1 + travel * 0.07;
          return Opacity(
            opacity: hideFace ? 0 : 1,
            child: Transform.translate(
              offset: Offset(arcX - dx, arcY),
              child: Transform.scale(scale: grow, child: child),
            ),
          );
        }
        final side = mid == 0 ? 0.0 : (index - mid).sign;
        // Neighbors ease inward so the chosen card can breathe.
        return Transform.translate(
          offset: Offset(side * travel * 10, travel * 6),
          child: Transform.scale(
            scale: 1 - travel * 0.05,
            child: child,
          ),
        );
      },
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.00135)
          ..translateByDouble(dx, 0, index * 0.4, 1)
          ..rotateY(t * 0.28)
          ..rotateZ(angle),
        child: Transform.scale(
          scale: recede,
          child: CardSelectionCard(
            index: index,
            selected: selected,
            dimmed: dimmed,
            entrance: entrance,
            floatOffset: floatOffset,
            nearbyEmphasis: nearbyEmphasis,
            onPressChanged: onPressChanged,
            surfaceLight: selected
                ? SacredMoment.surfaceAcknowledgment(sacredLinear) * 0.72
                : 0,
            onTap: onSelect,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
          ),
        ),
      ),
    );
  }
}
