/// Profile logout — awaits ApiResult; never fake success.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/auth_copy.dart';
import '../../../shared/navigation/oracly_navigation.dart';
import '../../../shared/ui/oracly_snackbar.dart';

Future<bool> profileSignOut({
  required WidgetRef ref,
  required BuildContext context,
}) async {
  final result = await ref.read(authServiceProvider).signOut();
  if (!context.mounted) return false;
  if (result.isFailure) {
    OraclySnackBar.show(context, message: AuthCopy.signOutFailed);
    return false;
  }
  OraclySnackBar.show(context, message: AuthCopy.signedOut);
  OraclyNavigation.switchToTab(context, OraclyTab.home);
  return true;
}
