import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:oracly_new/features/gems/services/rewarded_ad_config.dart';
import 'package:oracly_new/features/gems/services/rewarded_ad_service.dart';

class FakePort implements RewardedAdPort {
  bool loadFails = false, shown = false, disposed = false;
  void Function()? reward, dismissed, failure;
  @override Future<void> load({required String customData, required void Function() onReward, required void Function() onDismissed, required void Function() onFailure}) async { reward = onReward; dismissed = onDismissed; failure = onFailure; if (loadFails) onFailure(); }
  @override Future<bool> show() async { if (shown) return false; shown = true; return true; }
  @override void dispose() { disposed = true; }
}

void main() {
  test('load success becomes ready and concurrent show is prevented', () async {
    final port = FakePort();
    final service = RewardedAdService(port: port, claim: () async => 'opaque', authoritativeBalance: () async => 10, acceptBalance: (_) async {}, pollDelays: const []);
    await service.load(); expect(service.phase, RewardedAdPhase.ready);
    expect(await service.show(), isTrue); expect(await service.show(), isFalse);
  });

  test('client reward never mutates balance and verified server balance replaces it', () async {
    final port = FakePort(); var accepted = <int>[]; var reads = 0;
    final service = RewardedAdService(port: port, claim: () async => 'opaque', authoritativeBalance: () async => reads++ == 0 ? 10 : 15, acceptBalance: (v) async => accepted.add(v), pollDelays: const [Duration.zero]);
    await service.load(); await service.show(); port.reward!(); expect(accepted, isEmpty);
    port.dismissed!(); await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(accepted, [15]); expect(service.phase, RewardedAdPhase.verified);
  });

  test('failed verification gives no fake gems', () async {
    final port = FakePort(); var accepted = <int>[];
    final service = RewardedAdService(port: port, claim: () async => 'opaque', authoritativeBalance: () async => 10, acceptBalance: (v) async => accepted.add(v), pollDelays: const [Duration.zero]);
    await service.load(); await service.show(); port.reward!(); port.dismissed!();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(accepted, isEmpty); expect(service.phase, RewardedAdPhase.unavailable);
  });

  test('stale callbacks after dispose are inert', () async {
    final port = FakePort();
    final service = RewardedAdService(port: port, claim: () async => 'opaque', authoritativeBalance: () async => 0, acceptBalance: (_) async {});
    await service.load(); service.dispose(); port.reward!(); port.dismissed!(); expect(port.disposed, isTrue);
  });

  test('configuration uses official tests only outside release and disables missing release', () {
    expect(RewardedAdConfig.unitId(platform: TargetPlatform.android, releaseMode: false), contains('3940256099942544'));
    expect(RewardedAdConfig.unitId(platform: TargetPlatform.iOS, releaseMode: true), isNull);
  });
}
