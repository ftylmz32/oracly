/// Tab identity and a switcher that does not recreate feature routes.
library;

import 'package:flutter/material.dart';

import '../../core/navigation/immersive/chamber_transition_personality.dart';

enum OraclyTab {
  home,
  coffee,
  astrology,
  starMap,
  profile;

  static OraclyTab fromIndex(int index) => OraclyTab.values[index];

  /// Chamber door feel when this tab becomes the active room.
  /// Shell roots: Home · OR · Keşfet(Explore) · Günlük · Profil.
  ChamberTransitionPersonality get chamberPersonality => switch (this) {
        OraclyTab.coffee => ChamberTransitionPersonality.orPresence,
        OraclyTab.astrology => ChamberTransitionPersonality.coffee,
        OraclyTab.starMap => ChamberTransitionPersonality.chamber,
        OraclyTab.home || OraclyTab.profile =>
          ChamberTransitionPersonality.chamber,
      };
}

class OraclyNavigationScope extends InheritedWidget {
  const OraclyNavigationScope({
    super.key,
    required this.currentIndex,
    required this.switchToTab,
    required super.child,
  });

  final int currentIndex;
  final ValueChanged<int> switchToTab;

  static OraclyNavigationScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<OraclyNavigationScope>();
    assert(scope != null, 'OraclyNavigationScope not found in widget tree.');
    return scope!;
  }

  static OraclyNavigationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OraclyNavigationScope>();
  }

  @override
  bool updateShouldNotify(OraclyNavigationScope oldWidget) {
    return currentIndex != oldWidget.currentIndex;
  }
}

abstract final class OraclyNavigation {
  OraclyNavigation._();

  static void switchToTab(BuildContext context, OraclyTab tab) {
    final scope = OraclyNavigationScope.maybeOf(context);
    if (scope == null) return;
    scope.switchToTab(tab.index);
  }
}
