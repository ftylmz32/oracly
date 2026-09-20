/// Root gate while Firebase identity cleanup is still pending.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/data/repositories/local_onboarding_repository.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/notifications/oracly_notification_tap_router.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../../features/privacy/copy/privacy_control_copy.dart';
import '../../../features/privacy/providers/privacy_control_providers.dart';
import '../../../features/privacy/services/account_deletion_reauth_prompt.dart';
import '../../../features/privacy/services/privacy_data_refresh.dart';
import '../../../features/share_reopen/services/share_link_opener.dart';
import '../../../shared/navigation/oracly_navigation.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../../../shared/widgets/oracly_gold_button.dart';
import '../../../shared/widgets/oracly_scaffold.dart';

class AccountDeletionPendingScreen extends ConsumerStatefulWidget {
  const AccountDeletionPendingScreen({super.key});

  @override
  ConsumerState<AccountDeletionPendingScreen> createState() =>
      _AccountDeletionPendingScreenState();
}

class _AccountDeletionPendingScreenState
    extends ConsumerState<AccountDeletionPendingScreen> {
  bool _busy = false;

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final auth = ref.read(authServiceProvider);
      final deletion = ref.read(accountDeletionServiceProvider);
      final reauth = auth.isCurrentUserAnonymous
          ? null
          : await AccountDeletionReauthPrompt.collect(context, auth);
      if (!auth.isCurrentUserAnonymous && reauth == null) return;
      if (!mounted) return;
      final result = await deletion.retryPendingIdentityCleanup(reauth: reauth);
      if (!mounted) return;
      if (result.isFailure) {
        OraclySnackBar.show(
          context,
          message: result.errorOrNull?.message ??
              PrivacyControlCopy.deletePendingBody,
        );
        return;
      }
      // Gate + anonymous session already settled in _finishAfterIdentityDeleted.
      PrivacyDataRefresh.afterAccountSwitch(ref);
      if (!mounted) return;
      final onboardingDone = ref.read(localStorageProvider).getBool(
            LocalOnboardingRepository.completedKey,
          ) ??
          false;
      final next = onboardingDone
          ? const OraclyAppShell()
          : const OnboardingScreen();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => next),
      );
      // Resume queued deep links only after owner-bound destination is live.
      ShareLinkOpener.openPending();
      OraclyNotificationTapRouter.openPending(context);
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
                PrivacyControlCopy.deletePendingTitle,
                textAlign: TextAlign.center,
                style: ReadingTypography.sectionLabel(
                  color: OraclyChrome.goldLight,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                PrivacyControlCopy.deletePendingBody,
                textAlign: TextAlign.center,
                style: ReadingTypography.body(
                  color: OraclyChrome.cream.withValues(alpha: 0.86),
                ),
              ),
              const SizedBox(height: 28),
              OraclyGoldButton(
                label: PrivacyControlCopy.deletePendingRetry,
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
