/// Public share card payload — highlight only, never private history.
library;

import 'dart:typed_data';

import '../copy/discovery_share_copy.dart';

enum DiscoveryShareKind {
  coffee,
  palm,
  tarot,
  astrology,
  starMap,
  soulMate,
  dailyInsight;

  String get wire => name;

  static DiscoveryShareKind? fromWire(String? raw) {
    for (final value in values) {
      if (value.wire == raw) return value;
    }
    return null;
  }
}

class ShareableDiscovery {
  const ShareableDiscovery({
    required this.kind,
    required this.typeLabel,
    required this.highlight,
    this.visual,
    this.visualAsset,
    this.subjectLabel,
    this.visualIsReversed = false,
  });

  final DiscoveryShareKind kind;
  final String typeLabel;
  final String highlight;
  final Uint8List? visual;

  /// Photoreal card / celestial plate path — text never baked into the asset.
  final String? visualAsset;

  /// Card name, zodiac sign, or symbolic title drawn on canvas.
  final String? subjectLabel;

  /// When [visualAsset] reproduces a user's drawn Tarot card, preserve
  /// orientation. Decorative / catalogue / plate fallbacks stay upright.
  final bool visualIsReversed;

  String get caption =>
      '${DiscoveryShareCopy.themeLabel}:\n$highlight\n\n${DiscoveryShareCopy.brand}';
}

class DiscoveryShareRequest {
  const DiscoveryShareRequest({
    required this.caption,
    this.imageBytes,
  });

  final String caption;
  final Uint8List? imageBytes;
}
