/// OR-1120 — Permission rationale dialogs.
library;

import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import 'oracly_dialog.dart';

abstract final class OraclyPermissionDialog {
  OraclyPermissionDialog._();

  static Future<bool?> notifications(BuildContext context) {
    OraclyL10n.depend(context);
    return OraclyDialog.confirm(
      context,
      title: OraclyL10n.t('settings.notifications'),
      message: OraclyL10n.t('notif.permission'),
      confirmLabel: OraclyL10n.t('notif.permission_yes'),
      cancelLabel: OraclyL10n.t('notif.permission_later'),
    );
  }

  static Future<bool?> cameraCoffee(BuildContext context) {
    OraclyL10n.depend(context);
    return OraclyDialog.confirm(
      context,
      title: OraclyL10n.t('profile.photo_camera'),
      message: OraclyL10n.t('coffee.camera_permission_rationale'),
      confirmLabel: OraclyL10n.t('notif.permission_yes'),
      cancelLabel: OraclyL10n.t('notif.permission_later'),
    );
  }

  static Future<bool?> cameraPalm(BuildContext context) {
    OraclyL10n.depend(context);
    return OraclyDialog.confirm(
      context,
      title: OraclyL10n.t('profile.photo_camera'),
      message: OraclyL10n.t('palm.camera_permission_rationale'),
      confirmLabel: OraclyL10n.t('notif.permission_yes'),
      cancelLabel: OraclyL10n.t('notif.permission_later'),
    );
  }

  static Future<bool?> microphone(BuildContext context) {
    OraclyL10n.depend(context);
    return OraclyDialog.confirm(
      context,
      title: OraclyL10n.t('or.mic_permission_title'),
      message: OraclyL10n.t('or.mic_permission_message'),
      confirmLabel: OraclyL10n.t('notif.permission_yes'),
      cancelLabel: OraclyL10n.t('notif.permission_later'),
    );
  }
}
