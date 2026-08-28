/// Dialog action row — wraps on narrow / large-text canvases.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// End-aligned actions that wrap instead of overflowing on KN8-class widths.
class OraclyDialogActions extends StatelessWidget {
  const OraclyDialogActions({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: children,
    );
  }
}
