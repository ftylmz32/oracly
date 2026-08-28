/// OR-1000 — Shared screen shell for all Tarot presentation screens.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../../../core/theme/oracly_visual_rebirth.dart';
import '../../components/tarot_glass_card.dart';
import '../../theme/tarot_theme.dart';
import '../../theme/tarot_tokens.dart';

/// Base layout wrapper — cinematic background, safe area, max width.
class TarotScreenShell extends StatelessWidget {
  const TarotScreenShell({
    super.key,
    required this.child,
    this.scrollable = true,
    this.padding,
    this.showParticles = true,
  });

  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  final bool showParticles;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? TarotTokens.screenPaddingOf(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: TarotTokens.maxContentWidth),
          child: child,
        ),
      ),
    );

    return OraclyScaffold(
      ambience: OraclyAmbience.tarot,
      child: scrollable
          ? SingleChildScrollView(
              physics: CraftsmanshipRhythm.scrollPhysics,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: content,
            )
          : content,
    );
  }
}

/// Foundation placeholder body — replaced in implementation phase.
class TarotScreenPlaceholder extends StatelessWidget {
  const TarotScreenPlaceholder({
    super.key,
    required this.screenName,
    required this.phaseLabel,
    this.child,
  });

  final String screenName;
  final String phaseLabel;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TarotGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            screenName,
            style: TarotTheme.placeholderTitle,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            phaseLabel,
            style: TarotTheme.placeholderCaption,
          ),
          if (child != null) ...[
            SizedBox(height: AppSpacing.lg),
            child!,
          ],
        ],
      ),
    );
  }
}
