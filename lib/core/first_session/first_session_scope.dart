/// RC-012 — Propagates first-session state through the tarot ritual stack.
library;

import 'package:flutter/material.dart';

class FirstSessionScope extends InheritedWidget {
  const FirstSessionScope({
    super.key,
    required this.isFirstSession,
    required super.child,
  });

  final bool isFirstSession;

  static bool of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<FirstSessionScope>()
            ?.isFirstSession ??
        false;
  }

  static bool maybeOf(BuildContext context) {
    return context
            .getInheritedWidgetOfExactType<FirstSessionScope>()
            ?.isFirstSession ??
        false;
  }

  @override
  bool updateShouldNotify(FirstSessionScope oldWidget) =>
      isFirstSession != oldWidget.isFirstSession;
}
