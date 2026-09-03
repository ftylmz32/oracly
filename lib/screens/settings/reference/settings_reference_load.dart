/// Settings initial load — success, cached keep, or recoverable failure.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/copy/resilience_copy.dart';
import '../../../core/notifications/oracly_notification_providers.dart';
import '../../../features/premium/models/personalization_models.dart';
import '../../../shared/ui/oracly_snackbar.dart';

typedef SettingsLoaded =
    void Function({
      required PersonalizationSettings settings,
      required String profileName,
    });

Future<void> loadSettingsReference({
  required WidgetRef ref,
  required BuildContext context,
  required bool mounted,
  required bool hasLoadedOnce,
  required SettingsLoaded onLoaded,
  required VoidCallback onFirstFailure,
  required VoidCallback onCachedFailure,
}) async {
  try {
    final s = await ref.read(settingsServiceProvider).load();
    final profile = await ref.read(userRepositoryProvider).getProfile();
    if (!mounted) return;
    onLoaded(settings: s, profileName: profile.name);
    try {
      await ref.read(oraclyNotificationCoordinatorProvider).sync(s);
    } catch (_) {}
  } catch (_) {
    if (!mounted) return;
    if (hasLoadedOnce) {
      onCachedFailure();
      OraclySnackBar.show(context, message: ResilienceCopy.settingsLoadFailed);
    } else {
      onFirstFailure();
    }
  }
}
