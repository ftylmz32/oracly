/// Loaded / error body for Günlük Ödüller.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/resilience_copy.dart';
import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_error_state.dart';
import '../../../../shared/widgets/oracly_skeleton_loader.dart';
import '../../copy/daily_rewards_copy.dart';
import '../../models/daily_reward_state.dart';
import 'daily_rewards_reference_cards.dart';
import 'daily_rewards_reference_tokens.dart';

class DailyRewardsReferenceBody extends StatelessWidget {
  const DailyRewardsReferenceBody({
    super.key,
    required this.loading,
    required this.loadFailed,
    required this.state,
    required this.busy,
    required this.onRetry,
    required this.onClaim,
  });

  final bool loading;
  final bool loadFailed;
  final DailyRewardState? state;
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return OraclySkeletonLoader(message: ResilienceCopy.genericLoading);
    }
    if (loadFailed || state == null) {
      return OraclyErrorState(
        title: ResilienceCopy.errorTitle,
        message: DailyRewardsCopy.loadFailed,
        onRetry: onRetry,
      );
    }
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        DailyRewardsReferenceTokens.screenHorizontal,
        DailyRewardsReferenceTokens.headerToContent,
        DailyRewardsReferenceTokens.screenHorizontal,
        AppLayout.scrollBottomInset(context),
      ),
      children: [
        Text(
          DailyRewardsCopy.subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: OraclyChrome.goldLight.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          DailyRewardsCopy.streakHint,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: OraclyChrome.cream.withValues(alpha: 0.62),
            height: 1.35,
          ),
        ),
        const SizedBox(height: DailyRewardsReferenceTokens.sectionGap),
        DailyRewardsTodayCard(
          claimed: state!.claimedToday,
          amount: state!.rewardAmount,
          busy: busy,
          onClaim: onClaim,
        ),
      ],
    );
  }
}
