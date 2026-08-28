/// Share-card cup photo — real user image, protected elegant crop.
library;

import 'dart:typed_data';

import 'package:flutter/painting.dart';

import 'discovery_share_card_image.dart';
import 'discovery_share_card_layout.dart';

abstract final class DiscoveryShareCardCup {
  DiscoveryShareCardCup._();

  static Future<bool> paint(Canvas canvas, Uint8List? bytes) async {
    final image = await DiscoveryShareCardImage.fromBytes(bytes);
    if (image == null) return false;
    DiscoveryShareCardImage.drawProtected(
      canvas,
      image,
      DiscoveryShareCardLayout.cup,
      contain: false,
      focusY: 0.4,
    );
    return true;
  }
}
