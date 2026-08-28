/// Three-card fan — center larger, sides tilted (reference hero).
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'tarot_epic031_fan_cards.dart';
import 'tarot_epic031_spec.dart';

class TarotEpic031Trio extends StatelessWidget {
  const TarotEpic031Trio({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    final base = height ??
        TarotEpic031Spec.trioHeight * TarotEpic031Spec.trioScale(context);
    final scale = base / TarotEpic031Spec.trioHeight;
    final centerW = TarotEpic031Spec.centerCardWidth * scale;
    final centerH = TarotEpic031Spec.centerCardHeight * scale;
    final sideW = TarotEpic031Spec.sideCardWidth * scale;
    final sideH = TarotEpic031Spec.sideCardHeight * scale;
    final ox = TarotEpic031Spec.sideOffsetX * scale;
    final oy = TarotEpic031Spec.sideOffsetY * scale;
    final radius = TarotEpic031Spec.cardRadius;

    return SizedBox(
      height: base,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            width: centerW * 2.6,
            height: centerH * 1.45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purpleGlow.withValues(alpha: 0.28),
                    blurRadius: 48,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: AppColors.goldGlow.withValues(alpha: 0.16),
                    blurRadius: 36,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.40),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-ox, oy),
            child: Transform.rotate(
              angle: -TarotEpic031Spec.sideTiltRadians,
              child: TarotEpic031BackCard(
                width: sideW,
                height: sideH,
                radius: radius,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(ox, oy),
            child: Transform.rotate(
              angle: TarotEpic031Spec.sideTiltRadians,
              child: TarotEpic031BackCard(
                width: sideW,
                height: sideH,
                radius: radius,
              ),
            ),
          ),
          TarotEpic031FaceCard(
            width: centerW,
            height: centerH,
            radius: radius + 2,
          ),
        ],
      ),
    );
  }
}
