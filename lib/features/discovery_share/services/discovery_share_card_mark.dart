/// Campaign visual — photoreal plate / user photo / card art. Glyphs last resort.
library;

import 'package:flutter/painting.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../models/shareable_discovery.dart';
import 'discovery_share_card_assets.dart';
import 'discovery_share_card_image.dart';
import 'discovery_share_card_layout.dart';

abstract final class DiscoveryShareCardMark {
  DiscoveryShareCardMark._();

  static Future<void> paint(Canvas canvas, ShareableDiscovery discovery) async {
    try {
      if (await _paintVisual(canvas, discovery)) return;
      final plate = await DiscoveryShareCardImage.fromAsset(
        DiscoveryShareCardAssets.plateFor(discovery.kind),
      );
      if (plate != null) {
        final contain = discovery.kind == DiscoveryShareKind.tarot ||
            discovery.kind == DiscoveryShareKind.starMap ||
            discovery.kind == DiscoveryShareKind.astrology ||
            discovery.kind == DiscoveryShareKind.dailyInsight;
        DiscoveryShareCardImage.drawProtected(
          canvas,
          plate,
          contain ? DiscoveryShareCardLayout.hero : DiscoveryShareCardLayout.cup,
          contain: contain,
          focusY: 0.4,
        );
        return;
      }
    } catch (_) {
      // Fall through to glyph — never fail the share card.
    }
    _glyph(canvas, discovery.kind, DiscoveryShareCardLayout.hero.center);
  }

  static Future<bool> _paintVisual(
    Canvas canvas,
    ShareableDiscovery discovery,
  ) async {
    final fromAsset = await DiscoveryShareCardImage.fromAsset(
      discovery.visualAsset,
    );
    final image = fromAsset ??
        await DiscoveryShareCardImage.fromBytes(discovery.visual);
    if (image == null) return false;

    switch (discovery.kind) {
      case DiscoveryShareKind.soulMate:
        DiscoveryShareCardImage.drawProtected(
          canvas,
          image,
          DiscoveryShareCardLayout.portrait,
          contain: false,
          focusY: 0.28,
          radius: 24,
        );
      case DiscoveryShareKind.coffee:
        DiscoveryShareCardImage.drawProtected(
          canvas,
          image,
          DiscoveryShareCardLayout.cup,
          contain: false,
          focusY: 0.4,
        );
      case DiscoveryShareKind.tarot:
        DiscoveryShareCardImage.drawProtected(
          canvas,
          image,
          DiscoveryShareCardLayout.card,
          contain: true,
          radius: 18,
        );
      default:
        DiscoveryShareCardImage.drawProtected(
          canvas,
          image,
          DiscoveryShareCardLayout.hero,
          contain: true,
        );
    }
    return true;
  }

  static void _glyph(Canvas canvas, DiscoveryShareKind kind, Offset c) {
    final paint = Paint()
      ..color = OraclyChrome.gold.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      c,
      64,
      paint..color = OraclyChrome.gold.withValues(alpha: 0.24),
    );
    paint.color = OraclyChrome.gold.withValues(alpha: 0.86);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 40, height: 56),
        const Radius.circular(6),
      ),
      paint,
    );
  }
}
