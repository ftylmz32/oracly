/// Dream module Riverpod providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers/backend_providers.dart'
    show localDataOwnerEpochProvider;
import '../../ai/production/oracly_ai_providers.dart';
import '../../../core/reading_version/providers/reading_version_providers.dart';
import '../controllers/dream_analysis_controller.dart';
import '../controllers/dream_voice_controller.dart';
import '../services/dream_experience_service.dart';
import '../services/dream_owner_guard.dart';
import '../services/dream_voice_input_port.dart';
import '../services/speech_dream_voice_input.dart';

final dreamVoiceInputProvider = Provider<DreamVoiceInputPort>((ref) {
  return SpeechDreamVoiceInput(languageCode: () => OraclyL10n.code);
});

final dreamVoiceControllerProvider =
    ChangeNotifierProvider.autoDispose<DreamVoiceController>((ref) {
      return DreamVoiceController(ref.watch(dreamVoiceInputProvider));
    });

final dreamExperienceServiceProvider = Provider<DreamExperienceService>((ref) {
  return DreamExperienceService(
    repository: ref.watch(dreamRepositoryProvider),
    ai: ref.watch(oraclyAiServiceProvider),
    owner: DreamOwnerGuard.fromStorage(ref.watch(localStorageProvider)),
    versions: ref.watch(readingVersionServiceProvider),
    memory: ref.watch(oraclyMemoryRetrieverProvider),
  );
});

/// Rebuilt on every owner switch / sign-out / deletion (epoch) and on
/// privacy refresh — the prior controller is disposed, so its late futures
/// can never repaint, and history reloads from current storage.
final dreamAnalysisControllerProvider =
    ChangeNotifierProvider<DreamAnalysisController>((ref) {
      ref.watch(localDataOwnerEpochProvider);
      final controller = DreamAnalysisController(
        ref.watch(dreamExperienceServiceProvider),
      );
      controller.loadHistory();
      return controller;
    });
