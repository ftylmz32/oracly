/// Debug-only developer shortcuts. No entitlement is written or granted.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../features/premium/services/premium_dev_override.dart';
import '../../../features/premium/services/soul_mate_navigation.dart';
import 'settings_reference_group.dart';

class SettingsReferenceDeveloperQa extends StatelessWidget {
  const SettingsReferenceDeveloperQa({super.key});

  /// Impossible in release/profile: requires [kDebugMode] + canonical override.
  static bool get visible {
    if (kReleaseMode || !kDebugMode) return false;
    return PremiumDevOverride.isActive;
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return SettingsReferenceGroup(
      title: 'DEVELOPER QA',
      rows: [
        SettingsReferenceRow(
          icon: Icons.favorite_outline_rounded,
          title: 'Ruh Eşi Önizleme',
          subtitle:
              'Gerçek Soul Mate ekranı. Portre için geliştirme AI proxy / vision gerekir — sahte sonuç yok.',
          showChevron: true,
          onTap: () => SoulMateNavigation.open(context),
        ),
      ],
    );
  }
}
