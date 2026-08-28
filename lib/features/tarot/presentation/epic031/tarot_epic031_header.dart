/// EPIC-031 — Tarot header: back · TAROT FALI · gem (OraclyAppBar).
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../features/gems/widgets/oracly_live_gem_capsule.dart';

class TarotEpic031Header extends StatelessWidget {
  const TarotEpic031Header({
    super.key,
    this.onBack,
    this.onPremiumTap,
  });

  final VoidCallback? onBack;
  final VoidCallback? onPremiumTap;

  static const String title = 'TAROT';

  @override
  Widget build(BuildContext context) {
    return OraclyAppBar(
      title: title,
      onLeadingTap: onBack ?? () => Navigator.maybePop(context),
      trailing: OraclyLiveGemCapsule(
        onTap: onPremiumTap ??
            () => OraclyNavigationService.openGems(context),
      ),
    );
  }
}
