/// Settings ORACLY account shortcuts.
library;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import 'settings_reference_group.dart';

class SettingsReferenceAccount extends StatelessWidget {
  const SettingsReferenceAccount({super.key, required this.languageCode});

  final String languageCode;

  String _t(String key) =>
      OraclyL10n.t(key, languageCode: AppLocale.normalize(languageCode));

  @override
  Widget build(BuildContext context) {
    return SettingsReferenceGroup(
      title: 'ORACLY',
      rows: [
        SettingsReferenceRow(
          icon: Icons.workspace_premium_outlined,
          title: _t(L10nKeys.premiumTitle),
          subtitle: _t(L10nKeys.premiumSubtitle),
          showChevron: true,
          onTap: () => OraclyNavigationService.openPremium(context),
        ),
        SettingsReferenceRow(
          icon: Icons.hexagon_outlined,
          title: _t(L10nKeys.gemsTitle),
          subtitle: _t(L10nKeys.gemsSubtitle),
          showChevron: true,
          onTap: () => OraclyNavigationService.openGems(context),
        ),
        SettingsReferenceRow(
          icon: Icons.wb_twilight_outlined,
          title: _t(L10nKeys.dailyRewardsTitle),
          subtitle: _t(L10nKeys.dailyRewardsSubtitle),
          showChevron: true,
          onTap: () => OraclyNavigationService.openDailyRewards(context),
        ),
      ],
    );
  }
}
