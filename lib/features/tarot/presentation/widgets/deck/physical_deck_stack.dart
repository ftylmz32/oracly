/// Quiet stacked deck — depth without a fan.
library;

import 'package:flutter/material.dart';

import '../shuffle/shuffle_card_face.dart';

/// Several backs offset by a hair — thickness of a real deck at rest.
class PhysicalDeckStack extends StatelessWidget {
  const PhysicalDeckStack({
    super.key,
    this.layers = 6,
    this.width = 72,
    this.height = 118,
    this.opacity = 1,
  });

  final int layers;
  final double width;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final count = layers.clamp(3, 8);
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: SizedBox(
        width: width + 4,
        height: height + count * 1.6,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < count; i++)
              Positioned(
                bottom: i * 1.55,
                child: ShuffleCardFace(
                  width: width,
                  height: height,
                  elevation: 0.28 + i / count * 0.42,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
