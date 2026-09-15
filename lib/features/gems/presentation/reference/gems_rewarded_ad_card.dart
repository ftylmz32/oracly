import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../premium/providers/premium_providers.dart';
import '../../providers/gem_providers.dart';
import '../../services/rewarded_ad_service.dart';
import 'gems_reference_cards.dart';

class GemsRewardedAdCard extends ConsumerWidget {
  const GemsRewardedAdCard({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(premiumStatusProvider).isPremium) return const SizedBox.shrink();
    final service = ref.watch(rewardedAdProvider);
    if (service == null) return const SizedBox.shrink();
    final phase = service.phase;
    final actionable = phase == RewardedAdPhase.ready || phase == RewardedAdPhase.unavailable;
    final text = switch (phase) {
      RewardedAdPhase.loading => 'Reklam hazırlanıyor…',
      RewardedAdPhase.ready => 'Reklam izle, Elmas kazan',
      RewardedAdPhase.showing => 'Reklam gösteriliyor…',
      RewardedAdPhase.verifying => 'Ödül doğrulanıyor…',
      RewardedAdPhase.verified => 'Ödül doğrulandı',
      RewardedAdPhase.unavailable => 'Reklam şu anda kullanılamıyor',
    };
    return GemsInfoCard(
      icon: Icons.ondemand_video_rounded,
      title: 'İsteğe bağlı ödül',
      body: text,
      trailing: actionable
          ? FilledButton(
              onPressed: phase == RewardedAdPhase.ready ? service.show : service.load,
              child: Text(phase == RewardedAdPhase.ready ? 'İzle' : 'Yenile'),
            )
          : null,
    );
  }
}
