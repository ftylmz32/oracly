/// Günlük Ödüller — day strip · gift card · once-per-day claim.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../features/home/reference/home_reference_background.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../../gems/copy/gems_copy.dart';
import '../../../gems/providers/gem_providers.dart';
import '../../models/daily_reward_claim_result.dart';
import '../../models/daily_reward_state.dart';
import '../../providers/daily_rewards_providers.dart';
import 'daily_rewards_reference_app_bar.dart';
import 'daily_rewards_reference_body.dart';
import 'daily_rewards_reference_tokens.dart';

class DailyRewardsReferenceScreen extends ConsumerStatefulWidget {
  const DailyRewardsReferenceScreen({super.key});

  @override
  ConsumerState<DailyRewardsReferenceScreen> createState() =>
      _DailyRewardsReferenceScreenState();
}

class _DailyRewardsReferenceScreenState
    extends ConsumerState<DailyRewardsReferenceScreen> {
  DailyRewardState? _state;
  bool _loading = true;
  bool _loadFailed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    try {
      final next = await ref.read(dailyRewardsServiceProvider).load();
      if (!mounted) return;
      setState(() {
        _state = next;
        _loading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
        _state = null;
      });
    }
  }

  Future<void> _claim() async {
    final current = _state;
    if (current == null || current.claimedToday || _busy || _loading) return;
    setState(() => _busy = true);
    final result = await ref.read(dailyRewardsServiceProvider).claim();
    if (!mounted) return;
    switch (result) {
      case DailyRewardClaimSuccess(:final state):
        ref.read(gemWalletProvider).reload();
        ref.invalidate(userProfileProvider);
        setState(() {
          _state = state;
          _busy = false;
        });
        if (!current.claimedToday && state.claimedToday) {
          OraclySnackBar.success(
            context,
            GemsCopy.claimReceived(state.rewardAmount),
          );
        }
      case DailyRewardClaimFailure(:final message, :final state):
        setState(() {
          _state = state;
          _busy = false;
        });
        OraclySnackBar.show(context, message: message);
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
              child: DailyRewardsReferenceBody(
                loading: _loading,
                loadFailed: _loadFailed,
                state: _state,
                busy: _busy,
                onRetry: _load,
                onClaim: _claim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
