/// Inherited ritual snapshot. Layout stays put; only the hour can notify.
library;

import 'package:flutter/widgets.dart';

import 'oracly_universe_state.dart';

class OraclyUniverseScope extends InheritedWidget {
  const OraclyUniverseScope({
    super.key,
    required this.state,
    required super.child,
  });

  final OraclyUniverseState state;

  static OraclyUniverseState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<OraclyUniverseScope>();
    assert(scope != null, 'OraclyUniverseScope not found');
    return scope!.state;
  }

  static OraclyUniverseState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OraclyUniverseScope>()?.state;

  @override
  bool updateShouldNotify(covariant OraclyUniverseScope oldWidget) =>
      oldWidget.state.moment.day != state.moment.day ||
      oldWidget.state.moment.hour != state.moment.hour ||
      oldWidget.state.ritualTime != state.ritualTime ||
      oldWidget.state.moment.timeZoneOffset != state.moment.timeZoneOffset;
}
