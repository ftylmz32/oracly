/// Candle + violet archive depth for Yıldızname only.
library;

import 'package:flutter/material.dart';

import 'star_map_reference_tokens.dart';

class StarMapArchiveHaze extends StatelessWidget {
  const StarMapArchiveHaze({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.18),
                radius: 1.08,
                colors: [
                  StarMapReferenceTokens.candleAmber.withValues(alpha: 0.14),
                  StarMapReferenceTokens.archiveInk.withValues(alpha: 0.32),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.46, 1.0],
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  StarMapReferenceTokens.violetSky.withValues(alpha: 0.08),
                  Colors.transparent,
                  StarMapReferenceTokens.archiveInk.withValues(alpha: 0.46),
                ],
                stops: const [0.0, 0.36, 1.0],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
