/// Seeded violet nebula — same person, same wash.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import 'profile_avatar_seed.dart';

class ProfileAvatarNebula extends StatelessWidget {
  const ProfileAvatarNebula({super.key, required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ProfileAvatarNebulaPainter(seed),
      child: const SizedBox.expand(),
    );
  }
}

class ProfileAvatarNebulaPainter extends CustomPainter {
  const ProfileAvatarNebulaPainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0B0718));

    _blob(
      canvas,
      center:
          c +
          Offset(
            r * (-0.34 + 0.28 * ProfileAvatarSeed.unit(seed, 3)),
            r * (-0.40 + 0.24 * ProfileAvatarSeed.unit(seed, 8)),
          ),
      radius: r * (0.82 + 0.14 * ProfileAvatarSeed.unit(seed, 12)),
      colors: const [Color(0x884E3A9E), Color(0x000B0718)],
    );
    _blob(
      canvas,
      center:
          c +
          Offset(
            r * (0.18 + 0.28 * ProfileAvatarSeed.unit(seed, 5)),
            r * (0.08 + 0.26 * ProfileAvatarSeed.unit(seed, 14)),
          ),
      radius: r * 0.78,
      colors: const [Color(0x66301A68), Color(0x000B0718)],
    );
    _blob(
      canvas,
      center: c + Offset(-r * 0.08, r * 0.42),
      radius: r * 0.55,
      colors: [
        OraclyChrome.violet.withValues(alpha: 0.28),
        const Color(0x000B0718),
      ],
    );
  }

  void _blob(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required List<Color> colors,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: colors,
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant ProfileAvatarNebulaPainter old) =>
      old.seed != seed;
}
