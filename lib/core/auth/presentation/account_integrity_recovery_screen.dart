/// Root recovery when a deletion-gate marker is corrupt (wrong-type).
///
/// A corrupt marker is UNKNOWN state — never evidence a deletion was ever
/// requested or accepted. This screen must NEVER claim a deletion is
/// pending, must NEVER auto-retry, auto-delete, auto-wipe, or silently
/// mutate the corrupt marker. The only destructive path out of here is the
/// user's own explicit tap on [PrivacyControlCopy.integrityRecoveryContinueDeletion],
/// which repeats the full normal confirm/reauth/server-delete-first flow.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/privacy/copy/privacy_control_copy.dart';
import '../../../features/privacy/services/account_deletion_confirm_flow.dart';
import '../../../shared/widgets/oracly_gold_button.dart';
import '../../../shared/widgets/oracly_scaffold.dart';
import 'deletion_gate_recovery_router.dart';

class AccountIntegrityRecoveryScreen extends ConsumerStatefulWidget {
  const AccountIntegrityRecoveryScreen({super.key});

  @override
  ConsumerState<AccountIntegrityRecoveryScreen> createState() =>
      _AccountIntegrityRecoveryScreenState();
}

class _AccountIntegrityRecoveryScreenState
    extends ConsumerState<AccountIntegrityRecoveryScreen> {
  bool _busy = false;

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await resolveDeletionGateAndRoute(
        context: context,
        ref: ref,
        isMounted: () => mounted,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The ONLY destructive path out of integrity recovery — the user's own
  /// explicit choice, gated by the same confirm/reauth/server-delete-first
  /// flow as the normal Settings "delete my account" action. Never reached
  /// automatically from the corrupt marker alone.
  Future<void> _continueDeletion() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AccountDeletionConfirmFlow.confirmAndDelete(context, ref);
      if (!mounted) return;
      // Route based on whatever the deletion flow actually left the gate
      // as (clear/finalizing/blocked/still integrityRecovery) — never
      // assume success just because the dialog was confirmed.
      await resolveDeletionGateAndRoute(
        context: context,
        ref: ref,
        isMounted: () => mounted,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                PrivacyControlCopy.integrityRecoveryTitle,
                textAlign: TextAlign.center,
                style: ReadingTypography.sectionLabel(
                  color: OraclyChrome.goldLight,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                PrivacyControlCopy.integrityRecoveryBody,
                textAlign: TextAlign.center,
                style: ReadingTypography.body(
                  color: OraclyChrome.cream.withValues(alpha: 0.86),
                ),
              ),
              const SizedBox(height: 28),
              OraclyGoldButton(
                label: PrivacyControlCopy.integrityRecoveryRetry,
                onPressed: _busy ? null : _retry,
                expanded: true,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _busy ? null : _continueDeletion,
                child: Text(
                  PrivacyControlCopy.integrityRecoveryContinueDeletion,
                  textAlign: TextAlign.center,
                  style: ReadingTypography.body(
                    color: OraclyChrome.cream.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
