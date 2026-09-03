/// OR shell-tab stub — Luna opens only via dedicated /chat (never hosted here).
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

/// Inert root for the OR tab index. Tab taps are intercepted in
/// [OraclyAppShell] to push `/chat` without activating this pane.
class CompanionOrTabPlaceholder extends StatelessWidget {
  const CompanionOrTabPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: OraclyChrome.midnight);
  }
}
