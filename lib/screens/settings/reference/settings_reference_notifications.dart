/// Optional return invitation — one switch, never a coming-soon row.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

import '../../../core/l10n/l10n.dart';
import '../../../core/notifications/notification_permission.dart';
import '../../../core/notifications/oracly_notification_copy.dart';
import '../../../core/notifications/oracly_notification_providers.dart';
import '../../../core/notifications/oracly_notification_test_sender.dart';
import '../../../features/premium/models/personalization_models.dart';
import '../../../shared/ui/oracly_dialog.dart';
import '../../../shared/ui/oracly_permission_dialog.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import 'settings_reference_group.dart';

class SettingsReferenceNotifications extends ConsumerStatefulWidget {
  const SettingsReferenceNotifications({
    super.key,
    required this.settings,
    required this.onSave,
  });

  final PersonalizationSettings settings;
  final Future<void> Function(
    PersonalizationSettings Function(PersonalizationSettings),
  )
  onSave;

  @override
  ConsumerState<SettingsReferenceNotifications> createState() =>
      _SettingsReferenceNotificationsState();
}

class _SettingsReferenceNotificationsState
    extends ConsumerState<SettingsReferenceNotifications> {
  bool _testing = false;

  String _t(String key) => OraclyL10n.t(
    key,
    languageCode: AppLocale.normalize(widget.settings.language),
  );

  Future<void> _set(bool enabled) async {
    if (enabled) {
      final allowed = await OraclyPermissionDialog.notifications(context);
      if (allowed != true || !mounted) return;
      // The only user-facing notification permission request in the app.
      // The OS answer is authoritative (see notification_permission.dart).
      final status = await ref
          .read(oraclyNotificationPortProvider)
          .requestPermission();
      if (!mounted) return;
      if (!status.canDeliver) {
        // Keep switch OFF if permission was not granted.
        await _explainBlocked(status);
        return;
      }
    }
    await widget.onSave((s) => s.copyWith(notificationsEnabled: enabled));
  }

  Future<void> _explainBlocked(NotificationPermissionStatus status) async {
    if (status == NotificationPermissionStatus.unavailable) {
      OraclySnackBar.show(
        context,
        message: _t('notif.permission_unavailable_body'),
      );
      return;
    }
    final go = await OraclyDialog.confirm(
      context,
      title: _t('settings.notifications'),
      message: _t(
        status.needsOsSettings
            ? 'notif.permission_permanent_body'
            : 'notif.permission_denied_body',
      ),
      confirmLabel: _t('notif.permission_settings_label'),
      cancelLabel: _t('notif.permission_later'),
    );
    if (go == true && mounted) {
      await openAppSettings();
    }
  }

  /// Explicit user tap only — never scheduled or sent automatically.
  Future<void> _sendTest() async {
    if (_testing) return;
    setState(() => _testing = true);
    try {
      final result = await OraclyNotificationTestSender(
        ref.read(oraclyNotificationPortProvider),
      ).send(title: OraclyNotificationCopy.title, body: _t('notif.test_body'));
      if (!mounted) return;
      switch (result) {
        case NotificationTestResult.sent:
          OraclySnackBar.show(context, message: _t('notif.test_sent'));
        case NotificationTestResult.deliveryFailed:
          OraclySnackBar.show(context, message: _t('notif.test_failed'));
        case NotificationTestResult.permissionUnavailable:
          await _explainBlocked(NotificationPermissionStatus.unavailable);
        case NotificationTestResult.permissionPermanentlyDenied:
          await _explainBlocked(NotificationPermissionStatus.permanentlyDenied);
        case NotificationTestResult.permissionDenied:
          await _explainBlocked(NotificationPermissionStatus.denied);
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsReferenceGroup(
      title: _t(L10nKeys.sectionNotifications),
      rows: [
        SettingsReferenceRow(
          icon: Icons.notifications_outlined,
          title: _t(L10nKeys.notificationsTitle),
          subtitle: _t(L10nKeys.notificationsSubtitle),
          switchValue: widget.settings.notificationsEnabled,
          onSwitchChanged: _set,
        ),
        if (widget.settings.notificationsEnabled)
          SettingsReferenceRow(
            icon: Icons.notifications_active_outlined,
            title: _t('notif.test_title'),
            subtitle: _t('notif.test_subtitle'),
            onTap: _testing ? null : _sendTest,
          ),
      ],
    );
  }
}
