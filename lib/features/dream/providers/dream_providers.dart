/// SPRINT-001 — Dream module Riverpod providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../ai/providers/ai_providers.dart';
import '../controllers/dream_analysis_controller.dart';
import '../services/dream_experience_service.dart';
import '../services/dream_voice_input_port.dart';

final dreamVoiceInputProvider = Provider<DreamVoiceInputPort>(
  (ref) => const UnavailableDreamVoiceInput(),
);

final dreamExperienceServiceProvider = Provider<DreamExperienceService>((ref) {
  return DreamExperienceService(
    repository: ref.watch(dreamRepositoryProvider),
    aiRepository: ref.watch(dreamAIRepositoryProvider),
  );
});

final dreamAnalysisControllerProvider =
    ChangeNotifierProvider.autoDispose<DreamAnalysisController>((ref) {
  final controller = DreamAnalysisController(
    ref.watch(dreamExperienceServiceProvider),
  );
  controller.loadHistory();
  return controller;
});
