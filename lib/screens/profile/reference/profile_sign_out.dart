/// Profile logout — awaits ApiResult; never fake success.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/auth_copy.dart';
import '../../../core/auth/sign_out_local_cleanup.dart';
import '../../../core/notifications/push_token_cleanup.dart';
import '../../../features/reading_operation/providers/reading_live_provider.dart';
import '../../../shared/navigation/oracly_navigation.dart';
import '../../../shared/ui/oracly_snackbar.dart';

Future<bool> profileSignOut({
  required WidgetRef ref,
  required BuildContext context,
}) async {
  // Push-token cleanup happens WHILE the old identity's auth is still
  // valid — both steps are best-effort and must never block sign-out.
  await PushTokenCleanup.unregisterServerToken(
    ref.read(readingOperationSenderProvider),
  );
  await PushTokenCleanup.deleteLocalToken();

  final result = await ref.read(authServiceProvider).signOut();
  if (!context.mounted) return false;
  if (result.isFailure) {
    OraclySnackBar.show(context, message: AuthCopy.signOutFailed);
    return false;
  }

  // R5 — wipe account-scoped local state only after successful sign-out.
  // Capture messenger before provider refresh: invalidation rebuilds Profile
  // into loading and can drop a post-refresh context-based snackbar.
  final messenger = ScaffoldMessenger.maybeOf(context);

  // Firebase sign-out already succeeded above (that's this function's own
  // precondition) — a still-incomplete LOCAL wipe never turns that into a
  // reported sign-out failure; it only leaves the owner marker in place so
  // the next distinct sign-in safely retries cleanup before being treated
  // as isolated.
  await SignOutLocalCleanup.wipeDiskOnly(
    storage: ref.read(localStorageProvider),
    secureStorage: ref.read(secureStorageProvider),
  );

  if (messenger != null) {
    OraclySnackBar.showOnMessenger(messenger, message: AuthCopy.signedOut);
  } else if (context.mounted) {
    OraclySnackBar.show(context, message: AuthCopy.signedOut);
  }

  if (context.mounted) {
    OraclyNavigation.switchToTab(context, OraclyTab.home);
  }

  SignOutLocalCleanup.refreshProviders(ref);
  return true;
}
