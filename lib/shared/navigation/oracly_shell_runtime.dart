/// Shell atmosphere and voice — bind once, never from feature widgets.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/audio/oracly_feedback_gate.dart';
import '../../core/audio/oracly_sound_hooks.dart';
import '../../core/audio/oracly_sound_service.dart';
import '../../core/experience/living_presence_tracker.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/performance/oracly_performance_gate.dart';
import '../../core/voice/oracly_tts_gate.dart';
import '../../core/voice/oracly_voice_id.dart';
import '../../features/companion/providers/companion_providers.dart';
import '../../features/gems/providers/gem_providers.dart';
import '../../features/premium/models/personalization_models.dart';

abstract final class OraclyShellRuntime {
  OraclyShellRuntime._();

  /// Stops OR listen + conversation turn when leaving its surface.
  static void cancelCompanionVoice(BuildContext context) {
    final container = ProviderScope.containerOf(context, listen: false);
    if (container.exists(companionVoiceTurnControllerProvider)) {
      unawaited(
        container.read(companionVoiceTurnControllerProvider).handleExternalInterrupt(),
      );
    }
    if (container.exists(companionVoiceControllerProvider)) {
      unawaited(container.read(companionVoiceControllerProvider).cancel());
    }
    unawaited(OraclyTtsGate.interrupt());
  }

  static void handleLifecycle(
    AppLifecycleState state,
    OraclySoundService sound, {
    WidgetRef? ref,
  }) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Phone call / background — hard stop voice; never leave playback stuck.
        sound.pauseAmbientForBackground();
        unawaited(OraclyTtsGate.interrupt());
        if (ref != null) {
          if (ref.exists(companionVoiceTurnControllerProvider)) {
            unawaited(
              ref.read(companionVoiceTurnControllerProvider).handleExternalInterrupt(),
            );
          }
          if (ref.exists(companionVoiceControllerProvider)) {
            unawaited(ref.read(companionVoiceControllerProvider).cancel());
          }
        }
      case AppLifecycleState.detached:
        sound.pauseAmbientForBackground();
        unawaited(OraclyTtsGate.interrupt());
      case AppLifecycleState.resumed:
        // Do not resume interrupted OR speech after a call/background.
        sound.resumeAmbientFromBackground();
        if (ref != null) unawaited(reconcilePaidOps(ref));
    }
  }

  /// Settle provider-ok leftovers after resume / failed splash critical boot.
  static Future<void> reconcilePaidOps(WidgetRef ref) async {
    try {
      await ref.read(paidAiOperationCoordinatorProvider).reconcile();
    } catch (_) {}
  }

  static Future<void> bootstrap(WidgetRef ref) async {
    try {
      final sound = ref.read(oraclySoundServiceProvider);
      OraclySoundHooks.bind(sound);
      await LivingPresenceTracker.markPresent(ref.read(localStorageProvider));
      await applyPersonalization(ref);
    } catch (_) {
      // Shell may be mounted in isolated tests without full providers.
    }
  }

  static Future<void> applyPersonalization(WidgetRef ref) async {
    final PersonalizationSettings settings;
    try {
      settings = await ref.read(settingsProvider.future);
    } catch (_) {
      return;
    }
    OraclyPerformanceGate.particleIntensity = settings.particleIntensity;
    OraclyFeedbackGate.bind(
      service: ref.read(oraclySoundServiceProvider),
      haptics: settings.hapticEnabled,
      sounds: settings.soundEnabled,
    );
    OraclyTtsGate.bind(
      service: ref.read(oraclyTtsProvider),
      enabled: settings.voiceRepliesEnabled,
      style: settings.aiPersonality,
      language: AppLocale.normalize(settings.language),
      identity: OraclyVoiceId.parse(settings.orVoiceId),
      speed: settings.orSpeechSpeed,
    );
    final sound = ref.read(oraclySoundServiceProvider);
    await sound.setAtmosphere(settings.atmosphereSign);
    await sound.syncAmbientEnabled(settings.ambientMusicEnabled);
  }
}
