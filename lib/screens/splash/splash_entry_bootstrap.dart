/// Splash entry: resolve deletion gate fail-closed, then owner-bound boot.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/auth/account_deletion_pending_state.dart';
import 'splash_boot.dart';

Future<void> splashEntryBootstrap({
  required WidgetRef ref,
  required void Function(bool completed) setOnboardingIfChanged,
  required bool Function() isMounted,
  required VoidCallback tryMountDestination,
  required ProviderContainer Function() containerOf,
  required bool currentOnboarding,
}) async {
  try {
    await AccountDeletionPendingState.resolveFromLocalStorage(
      ref.read(localStorageProvider),
    );
    if (!isMounted()) return;
    tryMountDestination();

    final completed = await splashFastOnboarding(ref);
    if (!isMounted()) return;
    if (completed != currentOnboarding) setOnboardingIfChanged(completed);
    if (AccountDeletionPendingState.allowsOwnerBoundExperience) {
      unawaited(splashDeferredBoot(ref));
      splashScheduleWarmup(containerOf());
    }
  } catch (_) {
    if (!isMounted()) return;
    if (AccountDeletionPendingState.isUnresolved) {
      AccountDeletionPendingState.markStorageUnavailable();
    }
    tryMountDestination();
    if (AccountDeletionPendingState.allowsOwnerBoundExperience) {
      unawaited(splashResilientBoot(ref));
      splashScheduleWarmup(containerOf());
    }
  }
}
