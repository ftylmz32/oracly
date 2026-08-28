/// Campaign share card — Story 9:16, antique gold type on canvas only.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../copy/discovery_share_copy.dart';
import '../models/shareable_discovery.dart';
import 'discovery_share_card_atmosphere.dart';
import 'discovery_share_card_layout.dart';
import 'discovery_share_card_mark.dart';
import 'discovery_share_port.dart';

class DiscoveryShareCardPng implements DiscoveryShareCardRenderer {
  const DiscoveryShareCardPng();

  static const _w = DiscoveryShareCardLayout.width;
  static const _h = DiscoveryShareCardLayout.height;

  @override
  Future<Uint8List?> render(ShareableDiscovery discovery) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, _w, _h));
    DiscoveryShareCardAtmosphere.paint(canvas, discovery.kind);
    _paintCopy(canvas, discovery);
    await DiscoveryShareCardMark.paint(canvas, discovery);
    _drawCentered(
      canvas,
      DiscoveryShareCopy.brand,
      DiscoveryShareCardLayout.footerY,
      22,
      OraclyChrome.gold,
      tracking: 3.2,
    );
    final image = await recorder.endRecording().toImage(_w.toInt(), _h.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  void _paintCopy(Canvas canvas, ShareableDiscovery discovery) {
    final cream = OraclyChrome.cream;
    _drawCentered(
      canvas,
      DiscoveryShareCopy.brand,
      DiscoveryShareCardLayout.brandY,
      26,
      OraclyChrome.gold,
      tracking: 4,
    );
    _drawCentered(
      canvas,
      _featureLabel(discovery.kind),
      DiscoveryShareCardLayout.featureY,
      14,
      OraclyChrome.goldLight.withValues(alpha: 0.78),
      tracking: 3.4,
    );
    final subject = discovery.subjectLabel?.trim();
    if (subject != null && subject.isNotEmpty) {
      _drawCentered(
        canvas,
        subject,
        DiscoveryShareCardLayout.subjectY,
        28,
        cream,
        tracking: 1.2,
        maxLines: 2,
      );
    } else {
      _drawCentered(
        canvas,
        discovery.typeLabel,
        DiscoveryShareCardLayout.subjectY,
        18,
        OraclyChrome.goldLight,
        tracking: 2.4,
      );
    }
    _drawCentered(
      canvas,
      discovery.highlight,
      DiscoveryShareCardLayout.insightY,
      28,
      cream,
      tracking: 0.6,
      maxLines: 3,
    );
  }

  String _featureLabel(DiscoveryShareKind kind) => switch (kind) {
        DiscoveryShareKind.coffee => 'COFFEE',
        DiscoveryShareKind.palm => 'PALM',
        DiscoveryShareKind.astrology => 'ASTROLOGY',
        DiscoveryShareKind.starMap => 'YILDIZNAME',
        DiscoveryShareKind.soulMate => 'SOULMATE',
        DiscoveryShareKind.dailyInsight => 'DAILY',
        DiscoveryShareKind.tarot => 'TAROT',
      };

  void _drawCentered(
    Canvas canvas,
    String text,
    double y,
    double size,
    Color color, {
    double tracking = 2,
    int maxLines = 2,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.center, maxLines: maxLines),
    )
      ..pushStyle(
        ui.TextStyle(
          color: color,
          fontSize: size,
          letterSpacing: tracking,
          height: 1.28,
        ),
      )
      ..addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: _w - DiscoveryShareCardLayout.margin * 2));
    canvas.drawParagraph(
      paragraph,
      Offset(DiscoveryShareCardLayout.margin, y),
    );
  }
}
