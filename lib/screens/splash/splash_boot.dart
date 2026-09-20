/// Splash critical boot vs deferred post-Home warm-up.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/auth/account_deletion_pending_state.dart';
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
///
/// Starter grant + wallet reload are owned by [gemWalletProvider] bootstrap
/// once auth/App Check are ready — do not race them here.
///
/// Must not touch the wallet while the account-deletion gate is unresolved
/// or blocked.
Future<void> splashDeferredBoot(WidgetRef ref) async {
  if (!AccountDeletionPendingState.allowsOwnerBoundExperience) return;
  final storage = ref.read(localStorageProvider);
  if (storage.isEphemeral) {
    await storage.tryPromote();
  }
  try {
    await ref.read(paidAiOperationCoordinatorProvider).reconcile();
  } catch (_) {}
  if (!AccountDeletionPendingState.allowsOwnerBoundExperience) return;
  // Touch the wallet so bootstrap/auth listen starts during splash.
  try {
    ref.read(gemWalletProvider);
  } catch (_) {}
}

/// Legacy entry — routing read first, then deferred gem work.
Future<bool> splashCriticalBoot(WidgetRef ref) async {
  final completed = await splashFastOnboarding(ref);
  await splashDeferredBoot(ref);
  return completed;
}

enum DeferredWarmupOutcome { completed, skippedNotClear }

/// Single-flight guard — a normal splash boot and a successful storage- or
/// integrity-recovery retry all call [splashScheduleWarmup]; a concurrent
/// second caller awaits the first's own in-progress run instead of
/// re-triggering paid-operation reconcile, the gem wallet touch, or the
/// notification/analytics/remote-config warm-up a second time.
Future<void>? _inFlightDeferredWarmup;

/// Best-effort, non-blocking, single-flight post-gate warm-up — shared by
/// [splashEntryBootstrap] and every recovery screen's clear-path retry, so
/// neither silently skips paid-operation reconcile / the gem wallet touch /
/// notification-tap / analytics / remote-config warm-up for the whole app
/// session. Never blocks Home; no-ops unless the account-deletion gate is
/// already clear.
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
  unawaited(scheduleDeferredWarmupIfClear(container));
}

Future<DeferredWarmupOutcome> scheduleDeferredWarmupIfClear(
  ProviderContainer container,
) async {
  if (!AccountDeletionPendingState.allowsOwnerBoundExperience) {
    return DeferredWarmupOutcome.skippedNotClear;
  }
  final existing = _inFlightDeferredWarmup;
  if (existing != null) {
    await existing;
    return DeferredWarmupOutcome.completed;
  }
  final future = _runDeferredWarmup(container);
  _inFlightDeferredWarmup = future;
  try {
    await future;
    return DeferredWarmupOutcome.completed;
  } finally {
    _inFlightDeferredWarmup = null;
  }
}

Future<void> _runDeferredWarmup(ProviderContainer container) async {
  final storage = container.read(localStorageProvider);
  if (storage.isEphemeral) {
    await storage.tryPromote();
  }
  try {
    await container.read(paidAiOperationCoordinatorProvider).reconcile();
  } catch (_) {}
  if (AccountDeletionPendingState.allowsOwnerBoundExperience) {
    // Touch the wallet so bootstrap/auth listen starts.
    try {
      container.read(gemWalletProvider);
    } catch (_) {}
  }
  await _runWarmup(container);
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
