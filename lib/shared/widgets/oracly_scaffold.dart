/// OR-002.3 — Premium screen shell for all Oracly features.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';

/// Unified screen frame with cosmic gradient background and extensible body stack.
class OraclyScaffold extends StatelessWidget {
  const OraclyScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
    this.backgroundColor,
    this.backgroundGradient,
    this.backgroundOverlay,
    this.safeArea = true,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final Widget? backgroundOverlay;
  final bool safeArea;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      appBar: appBar,
      drawer: drawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: _bodyStack(
        backgroundColor: backgroundColor,
        backgroundGradient: backgroundGradient,
        backgroundOverlay: backgroundOverlay,
        safeArea: safeArea,
        child: child,
      ),
    );
  }

  static Widget _bodyStack({
    required Widget child,
    required bool safeArea,
    Color? backgroundColor,
    Gradient? backgroundGradient,
    Widget? backgroundOverlay,
  }) {
    final content = safeArea ? SafeArea(child: child) : child;

    return Stack(
      fit: StackFit.expand,
      children: [
        _backgroundLayer(
          backgroundColor: backgroundColor,
          backgroundGradient: backgroundGradient,
        ),
        if (backgroundOverlay != null)
          Positioned.fill(
            child: IgnorePointer(
              child: backgroundOverlay,
            ),
          ),
        content,
      ],
    );
  }

  static Widget _backgroundLayer({
    Color? backgroundColor,
    Gradient? backgroundGradient,
  }) {
    if (backgroundColor != null) {
      return ColoredBox(color: backgroundColor);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: backgroundGradient ?? AppGradients.background,
      ),
    );
  }
}
