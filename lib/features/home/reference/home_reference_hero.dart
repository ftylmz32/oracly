/// Cinematic Home hero — fixed greeting over the oracle plate.
library;

// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';

import '../../../core/accessibility/oracly_a11y.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/reading_typography.dart';
import 'home_reference_card_shell.dart';
import 'home_reference_hero_plate.dart';
import 'home_reference_tokens.dart';

class HomeReferenceHero extends StatelessWidget {
  const HomeReferenceHero({super.key, this.height = 156});

  final double height;

  @override
  Widget build(BuildContext context) {
    final hello = OraclyL10n.t('home.hero.hello');
    final invite = OraclyL10n.t('home.hero.invite');

    return Semantics(
      header: true,
      label: hello + '. ' + invite,
      child: HomeReferenceCardShell(
        height: height,
        premium: true,
        glowStrength: 1.16,
        borderRadius: HomeReferenceTokens.heroRadius,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: HomeReferenceTokens.heroRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const HomeReferenceHeroPlate(),
              _HeroCopy(hello: hello, invite: invite),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.hello, required this.invite});

  final String hello;
  final String invite;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
    final titleSize = (24 / scale).clamp(18.0, 24.0);
    final bodySize = (14 / scale).clamp(12.0, 14.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Align(
        alignment: Alignment.centerLeft,
        child: LayoutBuilder(
          builder: (context, box) {
            final maxW = (box.maxWidth * 0.58).clamp(160.0, 240.0);
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hello,
                        maxLines: scale > 1.15 ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: ReadingTypography.title(
                          color: OraclyChrome.cream.withValues(alpha: 0.98),
                        ).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: titleSize,
                          height: 1.14,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              OraclyChrome.gold.withValues(alpha: 0.55),
                              OraclyChrome.gold.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        child: const SizedBox(width: 36, height: 1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        invite,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ReadingTypography.secondary(
                          color: OraclyA11y.creamSecondary(OraclyChrome.cream),
                        ).copyWith(fontSize: bodySize, height: 1.42),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
