/// Owner-bound bootstrap steps that must wait for a clear deletion gate.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/mock_premium_repository.dart';
import '../domain/repositories/premium_repository.dart';
import '../notifications/reading_push_bootstrap.dart';
import 'account_deletion_pending_state.dart';
import 'anonymous_auth_bootstrap.dart';
import 'auth_service.dart';

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
}
