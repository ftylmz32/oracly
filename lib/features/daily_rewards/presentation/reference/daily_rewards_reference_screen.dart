/// Günlük Ödüller — day strip · gift card · once-per-day claim.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/home/reference/home_reference_background.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../../gems/copy/gems_copy.dart';
import '../../../gems/providers/gem_providers.dart';
import '../../copy/daily_rewards_copy.dart';
import '../../models/daily_reward_state.dart';
import '../../providers/daily_rewards_providers.dart';
import 'daily_rewards_reference_app_bar.dart';
import 'daily_rewards_reference_cards.dart';
import 'daily_rewards_reference_tokens.dart';

class DailyRewardsReferenceScreen extends ConsumerStatefulWidget {
  const DailyRewardsReferenceScreen({super.key});

  @override
  ConsumerState<DailyRewardsReferenceScreen> createState() =>
      _DailyRewardsReferenceScreenState();
}

class _DailyRewardsReferenceScreenState
    extends ConsumerState<DailyRewardsReferenceScreen> {
  DailyRewardState _state = const DailyRewardState(
    streak: 0,
    claimedToday: false,
  );
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final next = await ref.read(dailyRewardsServiceProvider).load();
    if (!mounted) return;
    setState(() => _state = next);
  }

  Future<void> _claim() async {
    if (_state.claimedToday || _busy) return;
    setState(() => _busy = true);
    final beforeClaimed = _state.claimedToday;
    final next = await ref.read(dailyRewardsServiceProvider).claim();
    ref.read(gemWalletProvider).reload();
    ref.invalidate(userProfileProvider);
    if (!mounted) return;
    setState(() {
      _state = next;
      _busy = false;
    });
    if (!beforeClaimed && next.claimedToday) {
      OraclySnackBar.success(
        context,
        GemsCopy.claimReceived(next.rewardAmount),
      );
    }
  }

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
              child: ListView(
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
                    claimed: _state.claimedToday,
                    amount: _state.rewardAmount,
                    busy: _busy,
                    onClaim: _claim,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
