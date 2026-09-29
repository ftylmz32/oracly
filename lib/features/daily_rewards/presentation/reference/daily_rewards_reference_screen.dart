/// Günlük Ödüller — day strip · gift card · once-per-day claim.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/auth/user_local_data_isolation.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../gems/copy/gems_copy.dart';
import '../../../gems/providers/gem_providers.dart';
import '../../models/daily_reward_claim_result.dart';
import '../../models/daily_reward_state.dart';
import '../../providers/daily_rewards_providers.dart';
import 'daily_rewards_reference_frame.dart';

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
  int _epoch = UserLocalDataIsolation.accountSwitchEpoch.value;

  @override
  void initState() {
    super.initState();
    UserLocalDataIsolation.accountSwitchEpoch.addListener(_onOwnerEpoch);
    _load();
  }

  @override
  void dispose() {
    UserLocalDataIsolation.accountSwitchEpoch.removeListener(_onOwnerEpoch);
    super.dispose();
  }

  void _onOwnerEpoch() {
    if (!mounted) return;
    _epoch = UserLocalDataIsolation.accountSwitchEpoch.value;
    setState(() {
      _state = null;
      _loading = true;
      _loadFailed = false;
      _busy = false;
    });
    _load();
  }

  Future<void> _load() async {
    final epoch = _epoch;
    if (mounted) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    try {
      final next = await ref.read(dailyRewardsServiceProvider).load();
      if (!mounted || epoch != _epoch) return;
      setState(() {
        _state = next;
        _loading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted || epoch != _epoch) return;
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
    final epoch = _epoch;
    setState(() => _busy = true);
    final result = await ref.read(dailyRewardsServiceProvider).claim();
    if (!mounted || epoch != _epoch) return;
    switch (result) {
      case DailyRewardClaimSuccess(:final state):
        final cached = ref.read(gemWalletServiceProvider).cachedBalance;
        if (cached != null) {
          await ref.read(gemWalletProvider).acceptAuthoritativeBalance(cached);
        } else {
          unawaited(ref.read(gemWalletProvider).reload());
        }
        ref.invalidate(userProfileProvider);
        setState(() {
          _state = state;
          _busy = false;
        });
        if (!mounted) return;
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
        if (!mounted) return;
        OraclySnackBar.show(context, message: message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DailyRewardsReferenceFrame(
      loading: _loading,
      loadFailed: _loadFailed,
      state: _state,
      busy: _busy,
      onRetry: _load,
      onClaim: _claim,
    );
  }
}
