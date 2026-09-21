/// OR-1170 — Provider scope for tarot controllers with persistence.
library;

import 'package:flutter/widgets.dart';

import '../controllers/tarot_flow_controller.dart';
import '../controllers/tarot_reading_controller.dart';

export 'tarot_module_root.dart';

/// Inherited controller bundle for the tarot ritual subtree.
class TarotScope extends InheritedWidget {
  const TarotScope({
    super.key,
    required this.flow,
    required this.reading,
    required super.child,
    this.restoreReady,
  });

  final TarotFlowController flow;
  final TarotReadingController reading;

  /// Completes after the first active-session restore attempt finishes.
  final Future<void>? restoreReady;

  static TarotScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TarotScope>();
    assert(scope != null, 'TarotScope not found above context.');
    return scope!;
  }

  static TarotScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TarotScope>();
  }

  @override
  bool updateShouldNotify(TarotScope oldWidget) {
    return flow != oldWidget.flow ||
        reading != oldWidget.reading ||
        restoreReady != oldWidget.restoreReady;
  }
}
