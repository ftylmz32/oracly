/// SPRINT-003 — Companion Riverpod providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/personality/or_personality.dart';
import '../../../core/personality/or_response_depth.dart';
import '../../premium/models/personalization_models.dart';
import 'companion_voice_turn_binding.dart';
import '../../ai/production/oracly_ai_providers.dart';
import '../../personal_discovery/models/surfaced_theme_record.dart';
import '../../personal_discovery/providers/personal_discovery_providers.dart';
import 'companion_or_style_hint.dart';
import '../controllers/companion_controller.dart';
import '../controllers/companion_output_controller.dart';
import '../controllers/companion_voice_controller.dart';
import '../controllers/companion_voice_turn_controller.dart';
import '../models/or_chat_output_mode.dart';
import '../services/companion_experience_service.dart';
import '../services/companion_speech_voice_input.dart';
import '../services/companion_voice_input_port.dart';

final companionVoiceInputProvider = Provider<CompanionVoiceInputPort>(
  (ref) => SpeechCompanionVoiceInput(),
);

final companionVoiceControllerProvider =
    ChangeNotifierProvider.autoDispose<CompanionVoiceController>((ref) {
      return CompanionVoiceController(ref.watch(companionVoiceInputProvider));
    });

final companionVoiceTurnControllerProvider =
    ChangeNotifierProvider.autoDispose<CompanionVoiceTurnController>((ref) {
      final turn = CompanionVoiceTurnController(
        voice: ref.watch(companionVoiceControllerProvider),
        output: ref.watch(companionOutputControllerProvider),
        session: ref.watch(companionControllerProvider),
      );
      bindCompanionVoiceTurnPremium(
        ref: ref,
        turn: turn,
        readOutput: () => ref.read(companionOutputControllerProvider),
        outputListenable: companionOutputControllerProvider,
      );
      return turn;
    });

final companionOutputControllerProvider =
    ChangeNotifierProvider<CompanionOutputController>((ref) {
      final controller = CompanionOutputController(
        persistMode: (mode) async {
          final current =
              ref.read(settingsProvider).valueOrNull ??
              const PersonalizationSettings();
          await ref
              .read(settingsProvider.notifier)
              .saveSettings(current.copyWith(orOutputMode: mode.wire));
        },
        readMode: () {
          final settings = ref.read(settingsProvider).valueOrNull;
          return OrChatOutputMode.fromStorage(settings?.orOutputMode);
        },
        readDepth: () =>
            ref.read(settingsProvider).valueOrNull?.orResponseDepth ??
            OrResponseDepth.fallback,
      );
      ref.listen<AsyncValue<PersonalizationSettings>>(settingsProvider, (
        _,
        next,
      ) {
        next.whenData((_) => controller.syncFromSettings());
      });
      return controller;
    });

final companionExperienceServiceProvider = Provider<CompanionExperienceService>(
  (ref) {
    return CompanionExperienceService(
      conversationRepository: ref.watch(aiConversationRepositoryProvider),
      intelligence: ref.watch(intelligenceLayerServiceProvider),
      dailyRitual: ref.watch(dailyRitualServiceProvider),
      users: ref.watch(userRepositoryProvider),
      personalMemory: ref.watch(personalMemoryServiceProvider),
      ai: ref.watch(oraclyAiServiceProvider),
      observationLine: () async {
        try {
          await ref
              .read(personalDiscoveryProfileProvider.future)
              .timeout(const Duration(seconds: 3));
          final observation = ref.read(oraclyObservationProvider('or'));
          if (observation == null) return null;
          await ref
              .read(discoverySurfaceMemoryProvider)
              .record(
                SurfacedThemeRecord(
                  theme: observation.theme,
                  surface: 'or',
                  at: DateTime.now(),
                ),
              );
          return observation.line;
        } catch (_) {
          return null;
        }
      },
      personality: () async {
        try {
          final settings = await ref
              .read(settingsRepositoryProvider)
              .load()
              .timeout(const Duration(seconds: 2));
          return OrPersonality.chatKey(settings.aiPersonality);
        } catch (_) {
          return null;
        }
      },
      lengthPrefs: () async {
        try {
          final settings = await ref
              .read(settingsRepositoryProvider)
              .load()
              .timeout(const Duration(seconds: 2));
          return (
            depth: settings.orResponseDepth,
            spoken: settings.voiceRepliesEnabled,
          );
        } catch (_) {
          return (depth: OrResponseDepth.fallback, spoken: false);
        }
      },
      styleHint: (message) => companionOrStyleHint(ref, message),
    );
  },
);

final companionControllerProvider = ChangeNotifierProvider<CompanionController>(
  (ref) {
    // read (not watch) for experience/output: a recreate after openChat.take()
    // wipes readingContext and Premium-gates the free deepen turn.
    final controller = CompanionController(
      ref.read(companionExperienceServiceProvider),
      ref.read(companionOutputControllerProvider),
      storage: ref.read(localStorageProvider),
      analytics: ref.read(analyticsServiceProvider),
      crashTelemetry: ref.read(crashTelemetryProvider),
    );
    controller.initialize();
    return controller;
  },
);
