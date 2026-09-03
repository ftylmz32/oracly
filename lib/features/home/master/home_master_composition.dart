/// Home composition — reference preferred sizes; scroll when needed.
library;

import 'package:flutter/foundation.dart';

import '../reference/home_viewport_layout.dart';

/// Resolves layout + scroll policy for the live Home body.
@immutable
final class HomeMasterComposition {
  const HomeMasterComposition({
    required this.layout,
    required this.requiresScroll,
  });

  final HomeViewportLayout layout;
  final bool requiresScroll;

  /// Preferred cinematic sizes always. Scroll only when content exceeds height.
  static HomeMasterComposition resolve({
    required double bodyHeight,
    required double navClearance,
    double screenHeightHint = 800,
    double textScale = 1.0,
  }) {
    final layout = HomeViewportLayout.resolve(screenHeightHint);
    final preferred = layout.preferredContentHeight;
    final available = bodyHeight.isFinite
        ? (bodyHeight - navClearance).clamp(0.0, bodyHeight)
        : preferred;
    final needsScroll = !bodyHeight.isFinite ||
        textScale > 1.12 ||
        preferred > available + 1.0;

    return HomeMasterComposition(
      layout: layout,
      requiresScroll: needsScroll,
    );
  }
}
