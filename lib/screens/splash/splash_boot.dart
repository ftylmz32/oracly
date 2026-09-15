/// Splash critical boot vs deferred post-Home warm-up.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/data/datasources/local_storage.dart';
import '../../core/data/repositories/local_onboarding_repository.dart';
import '../../core/providers/backend_providers.dart' as backend;
import '../../core/notifications/oracly_notification_providers.dart';
import '../../core/notifications/oracly_notification_tap_router.dart';
import '../../core/runtime/oracly_apply_outcome.dart';
import '../../features/gems/providers/gem_providers.dart';

/// Routing-critical: promote ephemeral storage, then read onboarding flag.
///
/// Does not wait on gems, network, notifications, or analytics.
Future<bool> splashResolveOnboardingCompleted(LocalStorage storage) async {
  if (storage.isEphemeral) {
    await storage.tryPromote();
  }
  return LocalOnboardingRepository(storage).isCompleted();
}

/// Fast routing read — durable local storage only, never gems/network.
Future<bool> splashFastOnboarding(WidgetRef ref) async {
  try {
    return await splashResolveOnboardingCompleted(
      ref.read(localStorageProvider),
    );
  } catch (_) {
    return false;
  }
}

/// Work required before honest gem balance — runs while cinema continues.
/// Promote is idempotent if [splashFastOnboarding] already hydrated prefs.
Future<void> splashDeferredBoot(WidgetRef ref) async {
  final storage = ref.read(localStorageProvider);
  if (storage.isEphemeral) {
    await storage.tryPromote();
  }
  try {
    await ref.read(gemStarterGrantProvider).ensureOnce();
  } catch (_) {}
  try {
    await ref.read(paidAiOperationCoordinatorProvider).reconcile();
  } catch (_) {}
  try {
    ref.read(gemWalletProvider).reload();
  } catch (_) {}
}

/// Legacy entry — routing read first, then deferred gem work.
Future<bool> splashCriticalBoot(WidgetRef ref) async {
  final completed = await splashFastOnboarding(ref);
  await splashDeferredBoot(ref);
  return completed;
}

/// Non-blocking warm-up — never holds splash to Home.
///
/// Takes the app-level [ProviderContainer], not a widget-scoped [WidgetRef].
/// This work is fire-and-forget and is expected to keep running well after
/// the splash widget that scheduled it has already been disposed and
/// replaced by Home/Onboarding — reading through a disposed widget's `ref`
/// throws `Bad state: Cannot use "ref" after the widget was disposed`
/// (previously swallowed here as an opaque "sync threw" log line). The
/// container is not tied to any widget's lifecycle, so the same
/// `.read`/`.invalidate` calls stay valid for as long as the app runs.
void splashScheduleWarmup(ProviderContainer container) {
  unawaited(_runWarmup(container));
}

Future<void> _runWarmup(ProviderContainer container) async {
  try {
    await container
        .read(oraclyNotificationPortProvider)
        .captureColdStartLaunch();
  } catch (_) {}
  try {
    final settings = await container.read(settingsProvider.future);
    final outcome = await container
        .read(oraclyNotificationCoordinatorProvider)
        .sync(settings);
    if (outcome.isFailure) {
      // Passive startup degrades safely — never crashes, never shows the
      // toggle as ON if scheduling silently failed to apply — but the
      // failure must still leave a trace instead of vanishing.
      debugPrint('[ORACLY] startup notification sync failed');
    }
  } catch (e) {
    debugPrint('[ORACLY] startup notification sync threw: $e');
  }
  try {
    OraclyNotificationTapRouter.openPending();
  } catch (_) {}
  try {
    container.read(analyticsServiceProvider).logAppOpen();
  } catch (_) {}
  try {
    await container.read(backend.remoteConfigServiceProvider).beginSession();
  } catch (_) {}
  try {
    container.invalidate(experienceOrchestratorServiceProvider);
  } catch (_) {}
}

/// Best-effort boot when critical path throws — still never blocks forever.
Future<bool> splashResilientBoot(WidgetRef ref) async {
  try {
    return await splashFastOnboarding(ref);
  } catch (_) {
    return false;
  } finally {
    unawaited(splashDeferredBoot(ref));
  }
}
