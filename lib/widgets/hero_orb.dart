import 'dart:math';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class HeroOrb extends StatefulWidget {
  const HeroOrb({
    super.key,
    this.size = 180,
  });

  final double size;

  @override
  State<HeroOrb> createState() => _HeroOrbState();
}

class _HeroOrbState extends State<HeroOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final scale = 0.96 + (_controller.value * 0.08);

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _Glow(size: widget.size),

                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.orbCore,
                        AppColors.primary,
                        AppColors.background,
                      ],
                      stops: const [
                        0,
                        .55,
                        1,
                      ],
                    ),
                  ),
                ),

                ...List.generate(
                  12,
                  (index) => _Particle(
                    animation: _controller,
                    index: index,
                    radius: widget.size * .55,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 40,
      height: size + 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.orbGlow.withValues(alpha: .35),
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _Particle extends StatelessWidget {
  const _Particle({
    required this.animation,
    required this.index,
    required this.radius,
  });

  final Animation<double> animation;
  final int index;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final angle =
        (index * 30 + animation.value * 360) * pi / 180;

    return Transform.translate(
      offset: Offset(
        cos(angle) * radius,
        sin(angle) * radius,
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .9),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}