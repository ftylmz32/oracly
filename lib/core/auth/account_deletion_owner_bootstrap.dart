/// Owner-bound bootstrap steps that must wait for a clear deletion gate.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../data/repositories/mock_premium_repository.dart';
import '../domain/repositories/premium_repository.dart';
import '../notifications/reading_push_bootstrap.dart';
import '../storage/secure_storage_bootstrap.dart';
import 'account_deletion_pending_state.dart';
import 'anonymous_auth_bootstrap.dart';
import 'auth_service.dart';

enum OwnerStartupOutcome { completed, skippedNotClear }

abstract final class AccountDeletionOwnerBootstrap {
  AccountDeletionOwnerBootstrap._();

  /// Premium credential hydrate — never while gate ≠ clear.
  static Future<void> warmPremiumIfClear(PremiumRepository premium) async {
    if (!AccountDeletionPendingState.allowsOwnerBoundExperience) return;
    if (premium is MockPremiumRepository) {
      await premium.warmCredentialCache();
    }
  }

  static Future<void> ensureAnonymousIfClear(AuthService auth) async {
    if (!AccountDeletionPendingState.allowsOwnerBoundExperience) return;
    await AnonymousAuthBootstrap.ensure(auth);
  }

  /// Push install / rebind for the current owner — only when gate is clear.
  static Future<void> installReadingPushIfClear(
    ProviderContainer container,
  ) async {
    if (!AccountDeletionPendingState.allowsOwnerBoundExperience) return;
    await ReadingPushBootstrap.install(container);
  }

  /// Single-flight guard — a normal cold start (main._deferredStartup) and a
  /// storage-recovery retry (SecureStartupRecoveryScreen) must never run the
  /// full owner pipeline concurrently for the same process.
  static Future<void>? _inFlight;

  /// THE canonical post-gate owner startup: secure storage bootstrap,
  /// Premium credential warm, anonymous/current owner readiness, then
  /// reading-push install/rebind, in that order — the exact same pipeline a
  /// normal clear cold start runs. Both [main]'s deferred startup and a
  /// successful storage-recovery retry call this instead of duplicating any
  /// of these steps independently, so a recovered session boots exactly as
  /// healthy as a normal one rather than staying half-booted.
  ///
  /// No-ops (returns [OwnerStartupOutcome.skippedNotClear]) unless the gate
  /// is already [AccountDeletionPendingState.allowsOwnerBoundExperience] —
  /// callers are responsible for resolving the gate first.
  static Future<OwnerStartupOutcome> runIfClear(
    ProviderContainer container,
  ) async {
    if (!AccountDeletionPendingState.allowsOwnerBoundExperience) {
      return OwnerStartupOutcome.skippedNotClear;
    }
    final existing = _inFlight;
    if (existing != null) {
      await existing;
      return OwnerStartupOutcome.completed;
    }
    final future = _run(container);
    _inFlight = future;
    try {
      await future;
      return OwnerStartupOutcome.completed;
    } finally {
      _inFlight = null;
    }
  }

  static Future<void> _run(ProviderContainer container) async {
    try {
      final storage = container.read(localStorageProvider);
      final secure = container.read(secureStorageProvider);
      await SecureStorageBootstrap.run(storage, secure);
      await warmPremiumIfClear(container.read(premiumRepositoryProvider));
    } catch (_) {}
    await ensureAnonymousIfClear(container.read(authServiceProvider));
    await installReadingPushIfClear(container);
  }
}
