/// Root gate while Firebase identity cleanup / anon bootstrap is pending.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/account_deletion_owner_bootstrap.dart';
import '../../../core/auth/account_deletion_pending_state.dart';
import '../../../core/auth/account_deletion_service.dart';
import '../../../core/auth/models/auth_credentials.dart';
import '../../../core/data/repositories/local_onboarding_repository.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/network/api_result.dart';
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
      final deletion = ref.read(accountDeletionServiceProvider);
      final result = await _runRetry(deletion);
      if (!mounted || result == null) return;
      if (result.isFailure) {
        OraclySnackBar.show(
          context,
          message: result.errorOrNull?.message ??
              PrivacyControlCopy.deletePendingBody,
        );
        return;
      }
      await _enterHealthyApp();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<ApiResult<bool>?> _runRetry(AccountDeletionService deletion) async {
    // Neither a pending local wipe nor a pending anonymous bootstrap needs
    // reauth credentials — both are purely local/anonymous retries.
    if (deletion.hasPendingLocalWipe || deletion.hasPendingAnonymousBootstrap) {
      return deletion.retryPendingIdentityCleanup();
    }
    final auth = ref.read(authServiceProvider);
    final AccountReauthCredentials? reauth = auth.isCurrentUserAnonymous
        ? null
        : await AccountDeletionReauthPrompt.collect(context, auth);
    if (!auth.isCurrentUserAnonymous && reauth == null) return null;
    return deletion.retryPendingIdentityCleanup(reauth: reauth);
  }

  Future<void> _enterHealthyApp() async {
    PrivacyDataRefresh.afterAccountSwitch(ref);
    final container = ProviderScope.containerOf(context, listen: false);
    await AccountDeletionOwnerBootstrap.installReadingPushIfClear(container);
    if (!mounted) return;
    final onboardingDone = ref.read(localStorageProvider).getBool(
          LocalOnboardingRepository.completedKey,
        ) ??
        false;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            onboardingDone ? const OraclyAppShell() : const OnboardingScreen(),
      ),
    );
    ShareLinkOpener.openPending();
    OraclyNotificationTapRouter.openPending(context);
  }

  @override
  Widget build(BuildContext context) {
    final finalizing = AccountDeletionPendingState.isFinalizing;
    return OraclyScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                finalizing
                    ? PrivacyControlCopy.deleteFinalizingTitle
                    : PrivacyControlCopy.deletePendingTitle,
                textAlign: TextAlign.center,
                style: ReadingTypography.sectionLabel(
                  color: OraclyChrome.goldLight,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                finalizing
                    ? PrivacyControlCopy.deleteFinalizingBody
                    : PrivacyControlCopy.deletePendingBody,
                textAlign: TextAlign.center,
                style: ReadingTypography.body(
                  color: OraclyChrome.cream.withValues(alpha: 0.86),
                ),
              ),
              const SizedBox(height: 28),
              OraclyGoldButton(
                label: finalizing
                    ? PrivacyControlCopy.deleteFinalizingRetry
                    : PrivacyControlCopy.deletePendingRetry,
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
