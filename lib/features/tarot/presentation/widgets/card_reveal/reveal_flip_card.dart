/// 3D flip card with perspective, depth shadow, and foil.
library;

import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import 'card_reveal_spread.dart';
import 'reveal_border_energy.dart';
import 'reveal_card_back.dart';
import 'reveal_flip_front.dart';
import 'reveal_flip_sheen.dart';

class RevealFlipCard extends StatelessWidget {
  const RevealFlipCard({
    super.key,
    required this.data,
    required this.flipRotation,
    required this.tilt3D,
    required this.perspectiveTiltY,
    required this.borderEnergy,
    required this.landScale,
    required this.shadowDepth,
    required this.goldOpacity,
    required this.artOpacity,
    required this.particlePhase,
    this.width = 168,
    this.height = 268,
  });

  final RevealCardData data;
  final double flipRotation;
  final double tilt3D;
  final double perspectiveTiltY;
  final double borderEnergy;
  final double landScale;
  final double shadowDepth;
  final double goldOpacity;
  final double artOpacity;
  final double particlePhase;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final showingFront = flipRotation >= pi / 2;
    final edge = sin(flipRotation).abs();
    final facing = cos(flipRotation).abs();
    final depth = edge * 14;
    final sheen = edge * (0.42 + facing * 0.28);
    final shadowBlur = 8 + shadowDepth * 22;
    const pad = 80.0;
    final lightX =
        tilt3D * 0.55 + perspectiveTiltY * 0.35 + sin(flipRotation) * 0.28;
    final lightY = -tilt3D * 0.25 - edge * 0.08;
    final face = showingFront
        ? RevealFlipFront(
            data: data,
            width: width,
            height: height,
            goldOpacity: goldOpacity,
            artOpacity: artOpacity,
            lightBiasX: lightX,
            lightBiasY: lightY,
          )
        : RevealPremiumCardBack(
            width: width,
            height: height,
            elevation: 0.88 + edge * 0.08,
            particlePhase: particlePhase,
            lightBiasX: lightX,
            lightBiasY: lightY,
          );
    final body = Stack(
      alignment: Alignment.center,
      children: [
        face,
        RevealFlipSheen(
          intensity: sheen,
          flipRotation: flipRotation,
          width: width,
          height: height,
        ),
      ],
    );

    return Transform.scale(
      scale: landScale,
      child: SizedBox(
        width: width + pad,
        height: height + pad,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: Offset(
                tilt3D * 12 + sin(flipRotation) * 5,
                height * 0.52 + edge * 2,
              ),
              child: Transform.scale(
                scaleX: (0.72 + shadowDepth * 0.12) * (0.42 + facing * 0.58),
                child: Container(
                  width: width * 0.75,
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: (0.38 + edge * 0.12) * shadowDepth,
                        ),
                        blurRadius: shadowBlur,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.00145)
                ..translateByDouble(0, 0, depth, 1)
                ..rotateX(tilt3D * 0.42 + edge * 0.04)
                ..rotateZ(perspectiveTiltY * 0.55)
                ..rotateY(flipRotation),
              child: showingFront
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(pi),
                      child: body,
                    )
                  : body,
            ),
            RevealBorderEnergy(
              progress: borderEnergy,
              width: width,
              height: height,
            ),
          ],
        ),
      ),
    );
  }
}
