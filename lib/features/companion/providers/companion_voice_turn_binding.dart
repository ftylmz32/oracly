/// Binds conversation turns only when Premium entitlement is active.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../premium/providers/premium_providers.dart';
import '../controllers/companion_output_controller.dart';
import '../controllers/companion_voice_turn_controller.dart';

void bindCompanionVoiceTurnPremium({
  required Ref ref,
  required CompanionVoiceTurnController turn,
  required CompanionOutputController Function() readOutput,
  required ProviderListenable<CompanionOutputController> outputListenable,
}) {
  // isPremium already includes an active reviewer grant alongside commerce
  // entitlement — never read .entitlement.allowsPremiumFeatures directly
  // here, that would silently exclude review access.
  bool allowed() => ref.read(premiumStatusProvider).isPremium;

  void sync(CompanionOutputController next) {
    if (turn.isDisposed) return;
    turn.setActive(next.isConversation && allowed());
  }

  ref.listen<CompanionOutputController>(
    outputListenable,
    (_, next) => sync(next),
    fireImmediately: true,
  );
  ref.listen(premiumStatusProvider, (_, _) => sync(readOutput()));
}
