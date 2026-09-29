/// Daily Rewards frame — app bar and body, no claim logic.
library;

import 'package:flutter/material.dart';

import '../../../../features/home/reference/home_reference_background.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../models/daily_reward_state.dart';
import 'daily_rewards_reference_app_bar.dart';
import 'daily_rewards_reference_body.dart';
import 'daily_rewards_reference_tokens.dart';

class DailyRewardsReferenceFrame extends StatelessWidget {
  const DailyRewardsReferenceFrame({
    super.key,
    required this.loading,
    required this.loadFailed,
    required this.busy,
    required this.state,
    required this.onRetry,
    required this.onClaim,
  });

  final bool loading;
  final bool loadFailed;
  final bool busy;
  final DailyRewardState? state;
  final VoidCallback onRetry;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      usePremiumBackground: false,
      backgroundOverlay: const HomeReferenceBackground(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                DailyRewardsReferenceTokens.screenHorizontal,
                DailyRewardsReferenceTokens.screenTop,
                DailyRewardsReferenceTokens.screenHorizontal,
                0,
              ),
              child: DailyRewardsReferenceAppBar(
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: DailyRewardsReferenceBody(
                loading: loading,
                loadFailed: loadFailed,
                state: state,
                busy: busy,
                onRetry: onRetry,
                onClaim: onClaim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
