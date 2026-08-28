/// OR-002.3 / EPIC-020 — Premium screen shell for all Oracly features.
library;

import 'package:flutter/material.dart';

import '../../core/design_system/premium_background.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/oracly_visual_rebirth.dart';
import 'oracly_rebirth_atmosphere.dart';

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
    this.ambience,
    this.safeArea = true,
    this.resizeToAvoidBottomInset = true,
    this.usePremiumBackground = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final Widget? backgroundOverlay;

  /// EPIC-020 — unified atmosphere when [backgroundOverlay] is null.
  final OraclyAmbience? ambience;
  final bool safeArea;
  final bool resizeToAvoidBottomInset;

  /// When true and no custom bg, uses [PremiumBackground] from design system.
  final bool usePremiumBackground;

  Widget? get _overlay {
    if (backgroundOverlay != null) return backgroundOverlay;
    if (ambience == null) return null;
    return OraclyRebirthAtmosphere(ambience: ambience!);
  }

  @override
  Widget build(BuildContext context) {
    OraclyL10n.depend(context);
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
        backgroundOverlay: _overlay,
        safeArea: safeArea,
        usePremiumBackground: usePremiumBackground,
        child: child,
      ),
    );
  }

  static Widget _bodyStack({
    required Widget child,
    required bool safeArea,
    required bool usePremiumBackground,
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
          usePremiumBackground: usePremiumBackground,
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
    required bool usePremiumBackground,
  }) {
    if (backgroundColor != null) {
      return ColoredBox(color: backgroundColor);
    }

    if (backgroundGradient != null) {
      return DecoratedBox(
        decoration: BoxDecoration(gradient: backgroundGradient),
      );
    }

    // Theme-aware cosmic / light sanctuary — never a dark-only night fallback.
    if (usePremiumBackground) {
      return const PremiumBackground();
    }

    // Overlay-driven screens: transparent base so brightness follows overlay.
    return const ColoredBox(color: AppColors.transparent);
  }
}
