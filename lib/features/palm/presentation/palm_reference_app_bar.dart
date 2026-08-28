/// El Falı header — gold hand mark · EL FALI · live gem.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_app_bar.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../gems/widgets/oracly_live_gem_capsule.dart';
import '../copy/palm_copy.dart';

class PalmReferenceAppBar extends StatelessWidget {
  const PalmReferenceAppBar({
    super.key,
    this.onBack,
    this.onPremiumTap,
  });

  final VoidCallback? onBack;
  final VoidCallback? onPremiumTap;

  static String get title => PalmCopy.screenTitle;

  @override
  Widget build(BuildContext context) {
    return OraclyAppBar(
      title: PalmCopy.screenTitle,
      titleIcon: Icons.front_hand_rounded,
      onLeadingTap: onBack ?? () => Navigator.maybePop(context),
      trailing: OraclyLiveGemCapsule(
        onTap: onPremiumTap ??
            () => OraclyNavigationService.openGems(context),
      ),
    );
  }
}
