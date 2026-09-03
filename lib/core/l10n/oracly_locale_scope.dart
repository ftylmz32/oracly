/// Inherited locale so screens rebuild when language changes.
library;

import 'package:flutter/widgets.dart';

class OraclyLocaleScope extends InheritedWidget {
  const OraclyLocaleScope({
    super.key,
    required this.code,
    required super.child,
  });

  final String code;

  static String of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<OraclyLocaleScope>();
    return scope?.code ?? 'tr';
  }

  @override
  bool updateShouldNotify(OraclyLocaleScope oldWidget) =>
      code != oldWidget.code;
}
