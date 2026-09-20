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

enum OwnerStartupOutcome {
  /// Gate wasn't clear — no-op, nothing was attempted.
  skippedNotClear,

  /// [AuthService.hasCurrentIdentity] is true after the attempt, whether
  /// that identity already existed or was freshly bootstrapped. Secure
  /// storage bootstrap / Premium warm / push install are best-effort and do
  /// NOT affect this outcome — this is about whether an owner IDENTITY
  /// exists, not whether every network service succeeded.
  ownerIdentityEstablished,

  /// No current identity exists after the attempt — bootstrap failed or
  /// timed out, and none already existed. Callers must NOT treat this as
  /// healthy: do not route Home, do not claim owner readiness.
  ownerIdentityUnavailable,
}

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
  /// full owner pipeline concurrently for the same process. Typed so a
  /// concurrent caller awaits the SAME real outcome instead of a hardcoded
  /// "it worked" — see the P0 fix this replaced.
  static Future<OwnerStartupOutcome>? _inFlight;

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
  ///
  /// The returned outcome is honest about identity, not about every
  /// best-effort step: [OwnerStartupOutcome.ownerIdentityEstablished] means
  /// [AuthService.hasCurrentIdentity] is true after the attempt;
  /// [OwnerStartupOutcome.ownerIdentityUnavailable] means it is not, and
  /// callers that route based on this (the recovery screens) must NOT
  /// proceed to Home for that outcome — see
  /// deletion_gate_recovery_router.dart.
  static Future<OwnerStartupOutcome> runIfClear(
    ProviderContainer container,
  ) async {
    if (!AccountDeletionPendingState.allowsOwnerBoundExperience) {
      return OwnerStartupOutcome.skippedNotClear;
    }
    final existing = _inFlight;
    if (existing != null) {
      return existing;
    }
    final future = _run(container);
    _inFlight = future;
    try {
      return await future;
    } finally {
      _inFlight = null;
    }
  }

  static Future<OwnerStartupOutcome> _run(ProviderContainer container) async {
    try {
      final storage = container.read(localStorageProvider);
      final secure = container.read(secureStorageProvider);
      await SecureStorageBootstrap.run(storage, secure);
      await warmPremiumIfClear(container.read(premiumRepositoryProvider));
    } catch (_) {}

    final auth = container.read(authServiceProvider);
    // Reuses an existing current identity instead of creating another one —
    // AuthService.ensureAnonymousSession (used internally) already does
    // this; only signs in anonymously when no current identity exists.
    await ensureAnonymousIfClear(auth);

    if (!auth.hasCurrentIdentity) {
      return OwnerStartupOutcome.ownerIdentityUnavailable;
    }

    await installReadingPushIfClear(container);
    return OwnerStartupOutcome.ownerIdentityEstablished;
  }
}
