library;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../modules/oracly_feature_id.dart';
import '../../modules/oracly_feature_navigation.dart';
import '../../navigation/oracly_navigation_service.dart';
import '../../navigation/oracly_page_transitions.dart';
import '../providers/continue_where_you_left_off_provider.dart';
import '../../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../../shared/widgets/oracly_button.dart';

/// Single compact CTA that routes into the correct unfinished experience.
class ContinueWhereYouLeftOffButton extends StatelessWidget {
  const ContinueWhereYouLeftOffButton({
    super.key,
    required this.target,
  });

  final ContinueWhereYouLeftOffTarget target;

  void _open(BuildContext context) {
    switch (target.kind) {
      case ContinueWhereYouLeftOffKind.tarot:
        OraclyFeatureNavigation.open(context, OraclyFeatureId.tarot);
        return;
      case ContinueWhereYouLeftOffKind.orChat:
        OraclyNavigationService.openChat(context);
        return;
      case ContinueWhereYouLeftOffKind.onboardingProfileSetup:
        Navigator.of(context).push(
          OraclyPageTransitions.fade(
            page: const OnboardingScreen(),
          ),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: OraclyL10n.t('tarot.continue'),
      child: OraclyButton(
        text: OraclyL10n.t('tarot.continue'),
        icon: Icons.play_arrow_rounded,
        type: OraclyButtonType.secondary,
        size: OraclyButtonSize.small,
        onPressed: () => _open(context),
        enabled: true,
      ),
    );
  }
}

