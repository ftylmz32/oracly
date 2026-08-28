/// EPIC-017 / EPIC-022 — Luxury home header (legacy wrapper).
library;

import 'package:flutter/material.dart';

import '../../../core/navigation/oracly_navigation_service.dart';
import '../theme/home_composition.dart';
import 'home_greeting_section.dart';
import 'home_status_header.dart';

/// Premium home header — status bar + greeting (EPIC-022 split layout).
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    this.greeting = '',
    this.userName = '',
    this.subtitle = '',
    this.welcomeDay,
    this.onMenuTap,
    this.onPremiumTap,
  });

  final String greeting;
  final String userName;
  final String subtitle;
  final DateTime? welcomeDay;
  final VoidCallback? onMenuTap;
  final VoidCallback? onPremiumTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeStatusHeader(
          onPremiumTap: onPremiumTap,
          onMenuTap: onMenuTap ??
              () => OraclyNavigationService.openSettings(context),
        ),
        SizedBox(height: HomeComposition.headerToGreeting),
        HomeGreetingSection(
          userName: userName,
          welcomeDay: welcomeDay,
        ),
      ],
    );
  }
}
