/// Cinematic Home hero — greeting over the oracle plate; optional CTA.
library;

// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import 'home_reference_card_shell.dart';
import 'home_reference_hero_copy.dart';
import 'home_reference_hero_plate.dart';
import 'home_reference_tokens.dart';

class HomeReferenceHero extends StatelessWidget {
  const HomeReferenceHero({
    super.key,
    this.height = 156,
    this.hello,
    this.invite,
    this.ctaLabel,
    this.onCta,
  });

  final double height;
  final String? hello;
  final String? invite;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final title = hello ?? OraclyL10n.t('home.hero.hello');
    final body = invite ?? OraclyL10n.t('home.hero.invite');
    final semantics = onCta == null
        ? title + '. ' + body
        : title + '. ' + body + '. ' + (ctaLabel ?? '');

    return Semantics(
      header: true,
      label: semantics,
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
              HomeReferenceHeroCopy(
                hello: title,
                invite: body,
                ctaLabel: ctaLabel,
                onCta: onCta,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
