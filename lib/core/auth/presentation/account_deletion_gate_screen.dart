/// Renders the fixed screen an [AccountDeletionGateDestination] requires.
///
/// Every route surface (SplashDestination, OraclyRouteGenerator,
/// MaterialApp.onUnknownRoute, the recovery router) calls this — never its
/// own switch — so "which screen for which gate state" has exactly one
/// definition.
library;

import 'package:flutter/widgets.dart';

import '../account_deletion_gate_destination.dart';
import 'account_deletion_pending_screen.dart';
import 'account_integrity_recovery_screen.dart';
import 'gate_unresolved_screen.dart';
import 'secure_startup_recovery_screen.dart';

/// Null for [AccountDeletionGateDestination.normalRoute] — the caller must
/// proceed with whatever route was actually requested. Every other
/// destination has a fixed screen that must override the requested route.
Widget? screenForGateDestination(AccountDeletionGateDestination destination) {
  return switch (destination) {
    AccountDeletionGateDestination.normalRoute => null,
    AccountDeletionGateDestination.pendingDeletion =>
      const AccountDeletionPendingScreen(),
    AccountDeletionGateDestination.integrityRecovery =>
      const AccountIntegrityRecoveryScreen(),
    AccountDeletionGateDestination.storageUnavailable =>
      const SecureStartupRecoveryScreen(),
    AccountDeletionGateDestination.unresolved => const GateUnresolvedScreen(),
  };
}
