/// Dark cinematic archive atmosphere for Story campaign share cards.
library;

import 'package:flutter/painting.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../models/shareable_discovery.dart';
import 'discovery_share_card_layout.dart';

abstract final class DiscoveryShareCardAtmosphere {
  DiscoveryShareCardAtmosphere._();

  static const width = DiscoveryShareCardLayout.width;
  static const height = DiscoveryShareCardLayout.height;

  static const _stars = [
    Offset(96, 140),
    Offset(960, 190),
    Offset(140, 1640),
    Offset(900, 1580),
    Offset(540, 96),
    Offset(760, 1760),
    Offset(220, 380),
    Offset(820, 640),
    Offset(420, 1720),
  ];

  static void paint(Canvas canvas, DiscoveryShareKind kind) {
    final rect = Rect.fromLTWH(0, 0, width, height);
    final accent = _accent(kind);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _gradient(kind),
        ).createShader(rect),
    );
    canvas.drawCircle(
      _glowCenter(kind),
      320,
      Paint()
        ..color = accent.withValues(alpha: 0.11)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 64),
    );
    canvas.drawCircle(
      const Offset(540, 1480),
      260,
      Paint()
        ..color = OraclyChrome.violet.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 56),
    );
    final star = Paint()..color = accent.withValues(alpha: 0.38);
    for (final origin in _stars) {
      canvas.drawCircle(origin, kind == DiscoveryShareKind.soulMate ? 2.0 : 1.5, star);
    }
    if (kind == DiscoveryShareKind.soulMate ||
        kind == DiscoveryShareKind.starMap ||
        kind == DiscoveryShareKind.astrology) {
      final line = Paint()
        ..color = accent.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      canvas.drawLine(_stars[0], _stars[6], line);
      canvas.drawLine(_stars[6], _stars[4], line);
      canvas.drawLine(_stars[4], _stars[1], line);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        DiscoveryShareCardLayout.frame,
        const Radius.circular(36),
      ),
      Paint()
        ..color = OraclyChrome.gold.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  static List<Color> _gradient(DiscoveryShareKind kind) => switch (kind) {
        DiscoveryShareKind.coffee => const [
            Color(0xFF22150F),
            Color(0xFF120A0A),
            Color(0xFF05030C),
          ],
        DiscoveryShareKind.palm => const [
            Color(0xFF1E1020),
            Color(0xFF0A0714),
            Color(0xFF05030C),
          ],
        DiscoveryShareKind.astrology => const [
            Color(0xFF111B3A),
            Color(0xFF0A0F21),
            Color(0xFF05030C),
          ],
        DiscoveryShareKind.starMap => const [
            Color(0xFF0C122E),
            Color(0xFF070A1A),
            Color(0xFF04020A),
          ],
        DiscoveryShareKind.soulMate => const [
            Color(0xFF2A1222),
            Color(0xFF130815),
            Color(0xFF05030C),
          ],
        DiscoveryShareKind.dailyInsight => const [
            Color(0xFF12182E),
            Color(0xFF0A0D1A),
            Color(0xFF05030C),
          ],
        _ => const [Color(0xFF16102A), Color(0xFF0A0714), Color(0xFF05030C)],
      };

  static Color _accent(DiscoveryShareKind kind) => switch (kind) {
        DiscoveryShareKind.coffee => const Color(0xFFB88358),
        DiscoveryShareKind.palm => const Color(0xFFD29A7A),
        DiscoveryShareKind.astrology => const Color(0xFF7AA8FF),
        DiscoveryShareKind.starMap => const Color(0xFF8E8DFF),
        DiscoveryShareKind.soulMate => const Color(0xFFE0A8C9),
        DiscoveryShareKind.dailyInsight => OraclyChrome.goldLight,
        _ => OraclyChrome.gold,
      };

  static Offset _glowCenter(DiscoveryShareKind kind) => switch (kind) {
        DiscoveryShareKind.coffee => const Offset(540, 380),
        DiscoveryShareKind.soulMate => const Offset(540, 460),
        DiscoveryShareKind.starMap => const Offset(560, 360),
        _ => const Offset(540, 340),
      };
}
