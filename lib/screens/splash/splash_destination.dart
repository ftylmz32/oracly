/// Production destination after splash — never a placeholder Home.
library;

import 'package:flutter/material.dart';

import '../../core/auth/account_deletion_pending_state.dart';
import '../../core/auth/presentation/account_deletion_pending_screen.dart';
import '../../core/auth/presentation/account_integrity_recovery_screen.dart';
import '../../core/auth/presentation/secure_startup_recovery_screen.dart';
import '../../core/data/datasources/local_storage.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../shared/navigation/oracly_navigation.dart';

abstract final class SplashDestination {
  SplashDestination._();

  static const midnight = Color(0xFF07050D);

  /// Brand-safe underlay while the deletion gate is still [unresolved].
  static Widget unresolvedUnderlay() =>
      const ColoredBox(color: midnight, child: SizedBox.expand());

  /// Must not be called while the gate is [unresolved].
  static Widget build({
    required bool onboardingCompleted,
    required LocalStorage storage,
  }) {
    assert(
      !AccountDeletionPendingState.isUnresolved,
      'SplashDestination.build requires a resolved deletion gate',
    );
    final Widget page = switch (AccountDeletionPendingState.phase.value) {
      AccountDeletionGatePhase.storageUnavailable =>
        const SecureStartupRecoveryScreen(),
      AccountDeletionGatePhase.integrityRecovery =>
        const AccountIntegrityRecoveryScreen(),
      AccountDeletionGatePhase.blocked ||
      AccountDeletionGatePhase.finalizing =>
        const AccountDeletionPendingScreen(),
      AccountDeletionGatePhase.clear => onboardingCompleted
          ? const OraclyAppShell()
          : const OnboardingScreen(),
      AccountDeletionGatePhase.unresolved =>
        throw StateError('gate unresolved'),
    };
    return ColoredBox(color: midnight, child: page);
  }

  /// Instant commit after in-place bridge — no second animated splash.
  static void commitRoute(BuildContext context, Widget destination) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => destination,
      ),
    );
  }
}
