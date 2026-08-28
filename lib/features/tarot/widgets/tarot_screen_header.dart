/// OR-030 — Premium tarot screen header.
library;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/oracly_app_bar.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../features/gems/widgets/oracly_live_gem_capsule.dart';

/// Tarot home header — menu, title, premium gem counter.
class TarotSelectHeader extends StatelessWidget {
  const TarotSelectHeader({super.key});

  static String get _title => OraclyL10n.t('tarot.home.title');

  @override
  Widget build(BuildContext context) {
    return OraclyAppBar(
      title: _title,
      leadingIcon: Icons.menu_rounded,
      leadingLabel: OraclyL10n.t('tarot.home.menu'),
      onLeadingTap: () => OraclyNavigationService.openSettings(context),
      trailing: OraclyLiveGemCapsule(
        onTap: () => OraclyNavigationService.openGems(context),
      ),
    );
  }
}

/// Reading screen header — preserved for tarot reading flow.
class TarotReadingHeader extends StatelessWidget {
  const TarotReadingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return OraclyAppBar(
      title: OraclyL10n.t('tarot.reading.title'),
      leadingIcon: AppIcons.back,
      onLeadingTap: () => Navigator.maybePop(context),
      trailing: OraclyLiveGemCapsule(
        onTap: () => OraclyNavigationService.openGems(context),
      ),
    );
  }
}
