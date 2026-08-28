/// Premium header — back · PREMİUM · live gem.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../features/gems/widgets/oracly_live_gem_capsule.dart';

class PremiumReferenceAppBar extends StatelessWidget {
  const PremiumReferenceAppBar({
    super.key,
    this.onBack,
    this.onGemTap,
  });

  final VoidCallback? onBack;
  final VoidCallback? onGemTap;

  static String get title => OraclyL10n.t('premium.app_bar_title');

  @override
  Widget build(BuildContext context) {
    return OraclyAppBar(
      title: title,
      onLeadingTap: onBack ?? () => Navigator.maybePop(context),
      trailing: OraclyLiveGemCapsule(
        onTap: onGemTap ??
            () => OraclyNavigationService.openGems(context),
      ),
    );
  }
}
