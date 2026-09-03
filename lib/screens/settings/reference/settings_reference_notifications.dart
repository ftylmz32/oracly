/// Optional return invitation — one switch, never a coming-soon row.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/notifications/oracly_notification_providers.dart';
import '../../../features/premium/models/personalization_models.dart';
import '../../../shared/ui/oracly_dialog.dart';
import '../../../shared/ui/oracly_permission_dialog.dart';
import 'settings_reference_group.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsReferenceNotifications extends ConsumerWidget {
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

  String _t(String key) =>
      OraclyL10n.t(key, languageCode: AppLocale.normalize(settings.language));

  Future<void> _set(WidgetRef ref, BuildContext context, bool enabled) async {
    if (enabled) {
      final allowed = await OraclyPermissionDialog.notifications(context);
      if (allowed != true || !context.mounted) return;
      final granted = await ref
          .read(oraclyNotificationPortProvider)
          .requestPermission();
      if (!granted || !context.mounted) {
        final status = await Permission.notification.status;
        final permanentlyDenied = status.isPermanentlyDenied;
        final go = await OraclyDialog.confirm(
          context,
          title: _t('settings.notifications'),
          message: _t(
            permanentlyDenied
                ? 'notif.permission_permanent_body'
                : 'notif.permission_denied_body',
          ),
          confirmLabel: _t('notif.permission_settings_label'),
          cancelLabel: _t('notif.permission_later'),
        );
        if (go == true && context.mounted) {
          await openAppSettings();
        }
        // Keep switch OFF if permission was not granted.
        return;
      }
    }
    await onSave((s) => s.copyWith(notificationsEnabled: enabled));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsReferenceGroup(
      title: _t(L10nKeys.sectionNotifications),
      rows: [
        SettingsReferenceRow(
          icon: Icons.notifications_outlined,
          title: _t(L10nKeys.notificationsTitle),
          subtitle: _t(L10nKeys.notificationsSubtitle),
          switchValue: settings.notificationsEnabled,
          onSwitchChanged: (v) => _set(ref, context, v),
        ),
      ],
    );
  }
}
