/// OR-1000 — Reusable foundation layout for tarot screens.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../components/tarot_header.dart';
import '../../components/tarot_navigation_bar.dart';
import '../../components/tarot_orb.dart';
import '../../theme/tarot_tokens.dart';
import 'tarot_screen_shell.dart';

/// Standard scaffold for OR-1000 screen shells — header, steps, orb, body.
class TarotFoundationLayout extends StatelessWidget {
  const TarotFoundationLayout({
    super.key,
    required this.title,
    required this.step,
    required this.phaseLabel,
    this.subtitle,
    this.onBack,
    this.showOrb = true,
    this.showSteps = true,
    this.body,
    this.footer,
    this.scrollable = true,
  });

  final String title;
  final String? subtitle;
  final TarotFlowStep step;
  final String phaseLabel;
  final VoidCallback? onBack;
  final bool showOrb;
  final bool showSteps;
  final Widget? body;
  final Widget? footer;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return TarotScreenShell(
      scrollable: scrollable,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TarotHeader(
            title: title,
            subtitle: subtitle,
            onBack: onBack,
          ),
          if (showSteps) ...[
            SizedBox(height: AppSpacing.lg),
            TarotNavigationBar(currentStep: step),
            SizedBox(height: AppSpacing.sm),
            TarotNavigationLabel(label: phaseLabel),
          ],
          if (showOrb) ...[
            SizedBox(height: AppSpacing.lg),
            Align(alignment: Alignment.center, child: TarotOrb()),
          ],
          SizedBox(height: AppSpacing.lg),
          TarotScreenPlaceholder(
            screenName: title,
            phaseLabel: 'OR-1000 foundation — $phaseLabel',
            child: body,
          ),
          if (footer != null) ...[
            SizedBox(height: AppSpacing.lg),
            footer!,
          ],
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
