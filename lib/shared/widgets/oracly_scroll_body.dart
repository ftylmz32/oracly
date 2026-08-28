/// EPIC-014 — Consistent scroll container for premium screens.
library;

import 'package:flutter/material.dart';

import '../../core/design_system/app_layout.dart';
import '../../core/navigation/immersive/immersive_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/craftsmanship_rhythm.dart';
import 'oracly_entrance.dart';

/// Standard padded scroll body with unified physics and safe bottom inset.
class OraclyScrollBody extends StatelessWidget {
  const OraclyScrollBody({
    super.key,
    required this.child,
    this.padding,
    this.controller,
    this.maxWidth,
    this.center = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  /// Soft content cap. Null → [AppLayout.contentMaxWidth].
  final double? maxWidth;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding ??
        EdgeInsets.fromLTRB(
          AppLayout.screenHorizontal,
          AppSpacing.md,
          AppLayout.screenHorizontal,
          AppLayout.scrollBottomInset(context),
        );
    final cap = maxWidth ?? AppLayout.contentMaxWidth(context);

    final content = Padding(
      padding: resolvedPadding,
      child: center
          ? Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cap),
                child: OraclyEntrance(
                  mode: OraclyEntranceMode.fadeUp,
                  offset: ImmersiveMotion.sectionEnterOffsetPx,
                  child: child,
                ),
              ),
            )
          : OraclyEntrance(
              mode: OraclyEntranceMode.fadeUp,
              offset: ImmersiveMotion.sectionEnterOffsetPx,
              child: child,
            ),
    );

    return SingleChildScrollView(
      controller: controller,
      physics: CraftsmanshipRhythm.scrollPhysics,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: content,
    );
  }
}
