/// Kahve Falı header — gold coffee mark · KAHVE FALI · live gem.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../gems/widgets/oracly_live_gem_capsule.dart';
import '../../copy/coffee_copy.dart';

class CoffeeReferenceAppBar extends StatelessWidget {
  const CoffeeReferenceAppBar({
    super.key,
    this.onBack,
    this.onPremiumTap,
  });

  final VoidCallback? onBack;
  final VoidCallback? onPremiumTap;

  static String get title => CoffeeCopy.screenTitle;

  @override
  Widget build(BuildContext context) {
    return OraclyAppBar(
      title: CoffeeCopy.screenTitle,
      titleChild: Text(
        CoffeeCopy.screenTitle.toUpperCase(),
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
