/// Yıldızname header — back · YILDIZNAME · live gem.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../features/gems/widgets/oracly_live_gem_capsule.dart';

class StarMapReferenceAppBar extends StatelessWidget {
  const StarMapReferenceAppBar({
    super.key,
    this.title,
    this.onBack,
    this.onPremiumTap,
  });

  final String? title;
  final VoidCallback? onBack;
  final VoidCallback? onPremiumTap;

  static String get screenTitle => OraclyL10n.t('star.app_bar');

  @override
  Widget build(BuildContext context) {
    return OraclyAppBar(
      title: title ?? screenTitle,
      titleChild: Text(
        (title ?? screenTitle).toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 1,
        style: OraclyChrome.engravedTitle(size: 13),
      ),
      onLeadingTap: onBack ?? () => Navigator.maybePop(context),
      trailing: OraclyLiveGemCapsule(
        onTap: onPremiumTap ??
            () => OraclyNavigationService.openGems(context),
      ),
    );
  }
}
