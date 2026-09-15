import 'dart:async';
import 'package:flutter/foundation.dart';

enum RewardedAdPhase { loading, ready, showing, verifying, unavailable, verified }

abstract interface class RewardedAdPort {
  Future<void> load({required String customData, required VoidCallback onReward, required VoidCallback onDismissed, required VoidCallback onFailure});
  Future<bool> show();
  void dispose();
}

class RewardedAdService extends ChangeNotifier {
  RewardedAdService({required RewardedAdPort port, required Future<String?> Function() claim, required Future<int?> Function() authoritativeBalance, required Future<void> Function(int) acceptBalance, this.track, this.pollDelays = const [Duration(seconds: 2), Duration(seconds: 4), Duration(seconds: 8)]})
      : _port = port, _claim = claim, _balance = authoritativeBalance, _accept = acceptBalance;
  final RewardedAdPort _port;
  final Future<String?> Function() _claim;
  final Future<int?> Function() _balance;
  final Future<void> Function(int) _accept;
  final void Function(String event)? track;
  final List<Duration> pollDelays;
  RewardedAdPhase phase = RewardedAdPhase.unavailable;
  bool _disposed = false, _showing = false, _rewardObserved = false;
  int? _baselineBalance;
  int _generation = 0;

  Future<void> load() async {
    track?.call('rewarded_ad_load');
    final generation = ++_generation; _set(RewardedAdPhase.loading);
    final customData = await _claim();
    if (_disposed || generation != _generation) return;
    if (customData == null) { track?.call('rewarded_ad_failed'); _set(RewardedAdPhase.unavailable); return; }
    await _port.load(customData: customData, onReward: () { if (!_disposed && generation == _generation) _rewardObserved = true; }, onDismissed: () { if (!_disposed && generation == _generation) unawaited(_finish(generation)); }, onFailure: () { if (!_disposed && generation == _generation) { _showing = false; track?.call('rewarded_ad_failed'); _set(RewardedAdPhase.unavailable); } });
    if (!_disposed && generation == _generation && phase == RewardedAdPhase.loading) { track?.call('rewarded_ad_ready'); _set(RewardedAdPhase.ready); }
  }

  Future<bool> show() async {
    if (_disposed || phase != RewardedAdPhase.ready || _showing) return false;
    _showing = true; _rewardObserved = false; _baselineBalance = await _balance(); track?.call('rewarded_ad_show'); _set(RewardedAdPhase.showing);
    final shown = await _port.show();
    if (!shown && !_disposed) { _showing = false; _set(RewardedAdPhase.unavailable); }
    return shown;
  }

  Future<void> _finish(int generation) async {
    _showing = false;
    if (!_rewardObserved) { track?.call('rewarded_ad_failed'); _set(RewardedAdPhase.unavailable); return; }
    track?.call('rewarded_ad_completed_client');
    _set(RewardedAdPhase.verifying);
    for (final delay in pollDelays) {
      await Future<void>.delayed(delay);
      if (_disposed || generation != _generation) return;
      final balance = await _balance();
      if (balance != null && (_baselineBalance == null || balance > _baselineBalance!)) { await _accept(balance); track?.call('rewarded_ad_verified'); _set(RewardedAdPhase.verified); return; }
    }
    if (!_disposed) { track?.call('rewarded_ad_reward_timeout'); _set(RewardedAdPhase.unavailable); }
  }

  void _set(RewardedAdPhase value) { if (_disposed) return; phase = value; notifyListeners(); }
  @override void dispose() { _disposed = true; _generation++; _port.dispose(); super.dispose(); }
}
