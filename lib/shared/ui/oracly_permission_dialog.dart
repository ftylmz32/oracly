/// OR-1120 — Permission rationale dialogs.
library;

import 'package:flutter/material.dart';

import 'oracly_dialog.dart';

abstract final class OraclyPermissionDialog {
  OraclyPermissionDialog._();

  static Future<bool?> notifications(BuildContext context) {
    return OraclyDialog.confirm(
      context,
      title: 'Bildirimler',
      message:
          'İsteğe bağlı hatırlatmalar için bildirim izni gerekiyor. '
          'Ayarlardan istediğin zaman kapatabilirsin.',
      confirmLabel: 'İzin Ver',
      cancelLabel: 'Şimdi değil',
    );
  }

  static Future<bool?> microphone(BuildContext context) {
    return OraclyDialog.confirm(
      context,
      title: 'Mikrofon',
      message:
          'Sesli rüya kaydı ve AI sohbet için mikrofon erişimi gerekiyor.',
      confirmLabel: 'İzin Ver',
      cancelLabel: 'Vazgeç',
    );
  }
}
