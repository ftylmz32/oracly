/// Splash critical boot vs deferred post-Home warm-up.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/data/datasources/local_storage.dart';
import '../../core/data/repositories/local_onboarding_repository.dart';
import '../../core/providers/backend_providers.dart' as backend;
import '../../core/notifications/oracly_notification_providers.dart';
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
void splashScheduleWarmup(WidgetRef ref) {
  unawaited(_runWarmup(ref));
}

Future<void> _runWarmup(WidgetRef ref) async {
  try {
    final settings = await ref.read(settingsProvider.future);
    await ref.read(oraclyNotificationCoordinatorProvider).sync(settings);
  } catch (_) {}
  try {
    ref.read(analyticsServiceProvider).logAppOpen();
  } catch (_) {}
  try {
    await ref.read(backend.remoteConfigServiceProvider).beginSession();
  } catch (_) {}
  try {
    ref.invalidate(experienceOrchestratorServiceProvider);
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
