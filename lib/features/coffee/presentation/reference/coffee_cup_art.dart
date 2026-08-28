/// Ritual table: photoreal cup on warm wood, then a decorative gold orbit.
library;

import 'package:flutter/material.dart';

import 'coffee_atmosphere_painter.dart';
import 'coffee_cup_painter.dart';
import 'coffee_symbol_orbit.dart';
import 'coffee_table_painter.dart';

class CoffeeCupArt extends StatelessWidget {
  const CoffeeCupArt({
    super.key,
    this.size = 168,
    this.width,
    this.height,
    this.phase = 0,
    this.photo,
  });

  final double size;
  final double? width;
  final double? height;
  final double phase;
  final Widget? photo;

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF05030A)),
          RepaintBoundary(
            child: CustomPaint(painter: CoffeeAtmospherePainter(phase: phase)),
          ),
          ?photo,
          RepaintBoundary(
            child: CustomPaint(painter: CoffeeSymbolOrbitPainter(phase: phase)),
          ),
        ],
      ),
    );
  }
}

class CoffeeCupFallback extends CustomPainter {
  const CoffeeCupFallback({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    CoffeeTablePainter(phase: phase).paint(canvas, size);
    CoffeeCupPainter(phase: phase).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CoffeeCupFallback oldDelegate) =>
      oldDelegate.phase != phase;
}
