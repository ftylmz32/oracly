/// Shared resolve-then-route logic for every deletion-gate recovery screen
/// (durable-storage-unavailable, corrupt-marker integrity recovery, and the
/// pending-deletion screen's own retry) — one definition of "what a
/// successful retry does next" so these screens cannot silently drift out
/// of sync the way main.dart and the recovery screen once did for owner
/// bootstrap.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../../screens/splash/splash_boot.dart';
import '../../data/repositories/local_onboarding_repository.dart';
import '../../../shared/navigation/oracly_navigation.dart';
import '../account_deletion_owner_bootstrap.dart';
import '../account_deletion_pending_state.dart';
import 'account_deletion_pending_screen.dart';
import 'account_integrity_recovery_screen.dart';
import 'secure_startup_recovery_screen.dart';

/// Re-resolves the durable-storage/deletion gate and routes to whichever
/// screen the FRESH result calls for — never assumes the result matches
/// whatever screen is currently showing. Safe to call from any of the
/// recovery screens' retry actions, or after a destructive flow completes.
Future<void> resolveDeletionGateAndRoute({
  required BuildContext context,
  required WidgetRef ref,
  required bool Function() isMounted,
}) async {
  final status = await AccountDeletionPendingState.resolveFromLocalStorage(
    ref.read(localStorageProvider),
  );
  if (!isMounted()) return;

  switch (status) {
    case AccountDeletionGateResolveStatus.storageUnavailable:
      _replace(context, isMounted, const SecureStartupRecoveryScreen());
    case AccountDeletionGateResolveStatus.integrityRecovery:
      _replace(context, isMounted, const AccountIntegrityRecoveryScreen());
    case AccountDeletionGateResolveStatus.blocked:
    case AccountDeletionGateResolveStatus.finalizing:
      _replace(context, isMounted, const AccountDeletionPendingScreen());
    case AccountDeletionGateResolveStatus.clear:
      final container = ProviderScope.containerOf(context, listen: false);
      // REQUIRED: secure storage bootstrap, Premium warm, anonymous owner
      // readiness, push install — resume the SAME pipeline a normal clear
      // cold start runs, awaited before Home is shown.
      await AccountDeletionOwnerBootstrap.runIfClear(container);
      // BEST-EFFORT, non-blocking: paid-op reconcile, gem wallet touch,
      // notification/analytics/remote-config warm-up — the same deferred
      // work a normal splash boot schedules, so a recovered session never
      // silently skips it for the whole app session.
      splashScheduleWarmup(container);
      if (!isMounted()) return;
      final done = ref.read(localStorageProvider).getBool(
            LocalOnboardingRepository.completedKey,
          ) ??
          false;
      _replace(
        context,
        isMounted,
        done ? const OraclyAppShell() : const OnboardingScreen(),
      );
  }
}

void _replace(BuildContext context, bool Function() isMounted, Widget page) {
  if (!isMounted()) return;
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}
