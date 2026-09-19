/// Observable startup gate for an interrupted account deletion
/// (`AccountDeletionService.hasPendingIdentityCleanup`).
///
/// While [isBlocked] is true, the app must not hydrate or recreate normal
/// owner-bound data — the Firebase identity for the account whose SERVER
/// data was already deleted still exists, and a fresh reauthentication is
/// required to finish removing it. No UI currently reads this signal to
/// prompt that reauthentication (see MAC_HANDOFF-equivalent follow-up); it
/// exists so a future screen has a real, testable value to observe instead
/// of silently letting the app continue as if the account were healthy.
library;

import 'package:flutter/foundation.dart';

abstract final class AccountDeletionPendingState {
  AccountDeletionPendingState._();

  static final ValueNotifier<bool> isBlocked = ValueNotifier<bool>(false);
}
