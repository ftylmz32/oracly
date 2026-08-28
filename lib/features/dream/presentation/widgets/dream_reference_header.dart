/// Reference dream screen — top bar: back · chamber title · crystal capsule.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../features/gems/widgets/oracly_live_gem_capsule.dart';
import '../../copy/dream_copy.dart';

/// Reference-accurate dream analysis header row.
class DreamReferenceHeader extends StatelessWidget {
  const DreamReferenceHeader({
    super.key,
    this.onBack,
    this.onPremiumTap,
  });

  final VoidCallback? onBack;
  final VoidCallback? onPremiumTap;

  static String get title => DreamCopy.screenTitle;

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
