/// Root recovery when durable LocalStorage cannot be opened.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/account_deletion_owner_bootstrap.dart';
import '../../../core/auth/account_deletion_pending_state.dart';
import '../../../core/auth/presentation/account_deletion_pending_screen.dart';
import '../../../core/data/repositories/local_onboarding_repository.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../../features/privacy/copy/privacy_control_copy.dart';
import '../../../shared/navigation/oracly_navigation.dart';
import '../../../shared/widgets/oracly_gold_button.dart';
import '../../../shared/widgets/oracly_scaffold.dart';

class SecureStartupRecoveryScreen extends ConsumerStatefulWidget {
  const SecureStartupRecoveryScreen({super.key});

  @override
  ConsumerState<SecureStartupRecoveryScreen> createState() =>
      _SecureStartupRecoveryScreenState();
}

class _SecureStartupRecoveryScreenState
    extends ConsumerState<SecureStartupRecoveryScreen> {
  bool _busy = false;

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = await AccountDeletionPendingState.resolveFromLocalStorage(
        ref.read(localStorageProvider),
      );
      if (!mounted) return;
      switch (status) {
        case AccountDeletionGateResolveStatus.storageUnavailable:
          return;
        case AccountDeletionGateResolveStatus.blocked:
        case AccountDeletionGateResolveStatus.finalizing:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const AccountDeletionPendingScreen(),
            ),
          );
        case AccountDeletionGateResolveStatus.clear:
          // Resume the SAME canonical owner startup a normal clear cold
          // start runs (secure storage bootstrap, Premium warm, anonymous
          // owner readiness, push install) — never route to Home/Onboarding
          // from a recovered session that skipped all of it.
          await AccountDeletionOwnerBootstrap.runIfClear(
            ProviderScope.containerOf(context, listen: false),
          );
          if (!mounted) return;
          final done = ref.read(localStorageProvider).getBool(
                LocalOnboardingRepository.completedKey,
              ) ??
              false;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) =>
                  done ? const OraclyAppShell() : const OnboardingScreen(),
            ),
          );
      }
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
                PrivacyControlCopy.storageRecoveryTitle,
                textAlign: TextAlign.center,
                style: ReadingTypography.sectionLabel(
                  color: OraclyChrome.goldLight,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                PrivacyControlCopy.storageRecoveryBody,
                textAlign: TextAlign.center,
                style: ReadingTypography.body(
                  color: OraclyChrome.cream.withValues(alpha: 0.86),
                ),
              ),
              const SizedBox(height: 28),
              OraclyGoldButton(
                label: PrivacyControlCopy.storageRecoveryRetry,
                onPressed: _busy ? null : _retry,
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
