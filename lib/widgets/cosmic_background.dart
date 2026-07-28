import 'dart:math';

import 'package:flutter/material.dart';

class CosmicBackground extends StatelessWidget {
  final Widget child;

  const CosmicBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [
                Color(0xFF31205F),
                Color(0xFF1A1338),
                Color(0xFF0D0B18),
                Color(0xFF06060B),
              ],
            ),
          ),
        ),

        CustomPaint(
          painter: StarPainter(),
          size: Size.infinite,
        ),

        child,
      ],
    );
  }
}

class StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);

    final smallStar = Paint()
      ..color = Colors.white.withOpacity(.55);

    final brightStar = Paint()
      ..color = const Color(0xFFFFF6D5);

    for (int i = 0; i < 140; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;

      final radius = random.nextDouble() * 1.7;

      canvas.drawCircle(
        Offset(dx, dy),
        radius,
        smallStar,
      );
    }

    for (int i = 0; i < 20; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;

      canvas.drawCircle(
        Offset(dx, dy),
        2.2,
        brightStar,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}