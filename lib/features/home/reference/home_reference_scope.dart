/// Inherited Home viewport metrics for reference #1 children.
library;

import 'package:flutter/material.dart';

import 'home_reference_tokens.dart';

/// Provides [HomeViewportLayout] to header / hero / grid / premium.
class HomeReferenceScope extends InheritedWidget {
  const HomeReferenceScope({
    super.key,
    required this.layout,
    required super.child,
  });

  final HomeViewportLayout layout;

  static HomeViewportLayout of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<HomeReferenceScope>();
    assert(scope != null, 'HomeReferenceScope missing');
    return scope!.layout;
  }

  static HomeViewportLayout? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<HomeReferenceScope>()
        ?.layout;
  }

  @override
  bool updateShouldNotify(HomeReferenceScope oldWidget) =>
      layout.moduleTileHeight != oldWidget.layout.moduleTileHeight ||
      layout.heroArtSize != oldWidget.layout.heroArtSize ||
      layout.heroSlotHeight != oldWidget.layout.heroSlotHeight ||
      layout.gridSlotHeight != oldWidget.layout.gridSlotHeight ||
      layout.headerHeight != oldWidget.layout.headerHeight;
}
