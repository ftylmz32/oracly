/// Header crystal that always shows the authoritative gem balance.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/oracly_crystal_capsule.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../providers/gem_providers.dart';
import 'oracly_gem_balance_pulse.dart';

class OraclyLiveGemCapsule extends ConsumerWidget {
  const OraclyLiveGemCapsule({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(gemWalletProvider);
    return OraclyGemBalancePulse(
      balance: wallet.balance,
      child: OraclyCrystalCapsule(
        count: wallet.formatted,
        onTap: onTap ?? () => OraclyNavigationService.openGems(context),
      ),
    );
  }
}
