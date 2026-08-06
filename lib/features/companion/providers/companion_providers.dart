/// SPRINT-003 — Companion Riverpod providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../controllers/companion_controller.dart';
import '../services/companion_experience_service.dart';
import '../services/companion_voice_input_port.dart';

final companionVoiceInputProvider = Provider<CompanionVoiceInputPort>(
  (ref) => const UnavailableCompanionVoiceInput(),
);

final companionExperienceServiceProvider =
    Provider<CompanionExperienceService>((ref) {
  return CompanionExperienceService(
    conversationRepository: ref.watch(aiConversationRepositoryProvider),
    intelligence: ref.watch(intelligenceLayerServiceProvider),
    dailyRitual: ref.watch(dailyRitualServiceProvider),
  );
});

final companionControllerProvider =
    ChangeNotifierProvider.autoDispose<CompanionController>((ref) {
  final controller = CompanionController(
    ref.watch(companionExperienceServiceProvider),
  );
  controller.initialize();
  return controller;
});
