/// Profile header — back · ALANIN · live gem (OraclyAppBar gold title).
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_app_bar.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../features/gems/widgets/oracly_live_gem_capsule.dart';
import '../copy/profile_copy.dart';

class ProfileReferenceAppBar extends StatelessWidget {
  const ProfileReferenceAppBar({super.key, this.onBack, this.onPremiumTap});

  final VoidCallback? onBack;
  final VoidCallback? onPremiumTap;

  static String get title => ProfileCopy.screenTitle;

  @override
  Widget build(BuildContext context) {
    return OraclyAppBar(
      title: title,
      titleIcon: Icons.nightlight_round,
      onLeadingTap: onBack ?? () => Navigator.maybePop(context),
      trailing: OraclyLiveGemCapsule(
        onTap: onPremiumTap ?? () => OraclyNavigationService.openGems(context),
      ),
    );
  }
}
