/// Lets overlays reach the live shell without pushing a second AppShell.
library;

import 'oracly_navigation_scope.dart';

typedef OraclyShellTabSwitcher = void Function(OraclyTab tab);

/// Bound while [OraclyAppShell] is mounted.
abstract final class OraclyShellBridge {
  OraclyShellBridge._();

  static OraclyShellTabSwitcher? _switchTab;

  /// True while the live [OraclyAppShell] is mounted.
  static bool get isActive => _switchTab != null;

  static void bind(OraclyShellTabSwitcher switchTab) {
    _switchTab = switchTab;
  }

  static void unbind(OraclyShellTabSwitcher switchTab) {
    if (identical(_switchTab, switchTab)) _switchTab = null;
  }

  /// Returns true when an existing shell accepted the tab change.
  static bool requestTab(OraclyTab tab) {
    final switchTab = _switchTab;
    if (switchTab == null) return false;
    switchTab(tab);
    return true;
  }
}
