/// Pads children so last content clears the floating shell bottom nav.
library;

import 'package:flutter/material.dart';

import '../../core/design_system/app_layout.dart';

/// Reusable bottom clearance — never invent 100/120/150 per screen.
class OraclyBottomContentPad extends StatelessWidget {
  const OraclyBottomContentPad({
    super.key,
    required this.child,
    this.scaffoldResizesForKeyboard = true,
  });

  final Widget child;
  final bool scaffoldResizesForKeyboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: AppLayout.scrollBottomInset(
          context,
          scaffoldResizesForKeyboard: scaffoldResizesForKeyboard,
        ),
      ),
      child: child,
    );
  }
}
