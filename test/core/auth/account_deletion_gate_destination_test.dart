/// The single canonical phase → destination mapping. Every route surface
/// (SplashDestination, OraclyRouteGenerator, MaterialApp.onUnknownRoute,
/// the recovery router) must resolve through this — these tests pin the
/// exhaustive mapping itself so a future edit cannot silently misroute one
/// phase without a test noticing.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_gate_destination.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';

void main() {
  group('AccountDeletionGateDestinations.forPhase', () {
    test('clear → normalRoute', () {
      expect(
        AccountDeletionGateDestinations.forPhase(
          AccountDeletionGatePhase.clear,
        ),
        AccountDeletionGateDestination.normalRoute,
      );
    });

    test('blocked → pendingDeletion', () {
      expect(
        AccountDeletionGateDestinations.forPhase(
          AccountDeletionGatePhase.blocked,
        ),
        AccountDeletionGateDestination.pendingDeletion,
      );
    });

    test('finalizing → pendingDeletion', () {
      expect(
        AccountDeletionGateDestinations.forPhase(
          AccountDeletionGatePhase.finalizing,
        ),
        AccountDeletionGateDestination.pendingDeletion,
      );
    });

    test('integrityRecovery → integrityRecovery (never pendingDeletion)', () {
      expect(
        AccountDeletionGateDestinations.forPhase(
          AccountDeletionGatePhase.integrityRecovery,
        ),
        AccountDeletionGateDestination.integrityRecovery,
      );
    });

    test(
        'storageUnavailable → storageUnavailable (never pendingDeletion) — '
        'this exact phase was the P0 bug: it used to fall through to the '
        'pending-deletion claim screen', () {
      expect(
        AccountDeletionGateDestinations.forPhase(
          AccountDeletionGatePhase.storageUnavailable,
        ),
        AccountDeletionGateDestination.storageUnavailable,
      );
    });

    test(
        'unresolved → unresolved (never pendingDeletion, never normalRoute) '
        '— this exact phase was the other half of the P0 bug', () {
      expect(
        AccountDeletionGateDestinations.forPhase(
          AccountDeletionGatePhase.unresolved,
        ),
        AccountDeletionGateDestination.unresolved,
      );
    });

    test('every AccountDeletionGatePhase value is mapped (exhaustive)', () {
      for (final phase in AccountDeletionGatePhase.values) {
        expect(
          () => AccountDeletionGateDestinations.forPhase(phase),
          returnsNormally,
          reason: '$phase must be mapped',
        );
      }
    });
  });

  group('AccountDeletionGateDestinations.forResolveStatus', () {
    test('clear → normalRoute', () {
      expect(
        AccountDeletionGateDestinations.forResolveStatus(
          AccountDeletionGateResolveStatus.clear,
        ),
        AccountDeletionGateDestination.normalRoute,
      );
    });

    test('blocked → pendingDeletion', () {
      expect(
        AccountDeletionGateDestinations.forResolveStatus(
          AccountDeletionGateResolveStatus.blocked,
        ),
        AccountDeletionGateDestination.pendingDeletion,
      );
    });

    test('finalizing → pendingDeletion', () {
      expect(
        AccountDeletionGateDestinations.forResolveStatus(
          AccountDeletionGateResolveStatus.finalizing,
        ),
        AccountDeletionGateDestination.pendingDeletion,
      );
    });

    test('integrityRecovery → integrityRecovery', () {
      expect(
        AccountDeletionGateDestinations.forResolveStatus(
          AccountDeletionGateResolveStatus.integrityRecovery,
        ),
        AccountDeletionGateDestination.integrityRecovery,
      );
    });

    test('storageUnavailable → storageUnavailable (never pendingDeletion)', () {
      expect(
        AccountDeletionGateDestinations.forResolveStatus(
          AccountDeletionGateResolveStatus.storageUnavailable,
        ),
        AccountDeletionGateDestination.storageUnavailable,
      );
    });

    test('every AccountDeletionGateResolveStatus value is mapped', () {
      for (final status in AccountDeletionGateResolveStatus.values) {
        expect(
          () => AccountDeletionGateDestinations.forResolveStatus(status),
          returnsNormally,
          reason: '$status must be mapped',
        );
      }
    });
  });

  test('AccountDeletionGateDestinations.current follows the live phase', () {
    AccountDeletionPendingState.markClear();
    expect(
      AccountDeletionGateDestinations.current,
      AccountDeletionGateDestination.normalRoute,
    );
    AccountDeletionPendingState.markIntegrityRecovery();
    expect(
      AccountDeletionGateDestinations.current,
      AccountDeletionGateDestination.integrityRecovery,
    );
    AccountDeletionPendingState.markClear();
  });
}
