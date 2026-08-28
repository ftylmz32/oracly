/// Günlük Ödüller header — back · title · live gem (OraclyAppBar gold title).
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../gems/widgets/oracly_live_gem_capsule.dart';
import '../../copy/daily_rewards_copy.dart';

class DailyRewardsReferenceAppBar extends StatelessWidget {
  const DailyRewardsReferenceAppBar({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return OraclyAppBar(
      title: DailyRewardsCopy.screenTitle,
      onLeadingTap: onBack ?? () => Navigator.maybePop(context),
      trailing: const OraclyLiveGemCapsule(),
    );
  }
}
