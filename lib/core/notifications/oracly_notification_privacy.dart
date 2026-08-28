/// Keeps notification preview free of private user content.
library;

import '../../features/personal_discovery/models/discovery_theme.dart';

abstract final class OraclyNotificationPrivacy {
  OraclyNotificationPrivacy._();

  static const maxBody = 90;

  static String? publicThemeLabel(String? raw) {
    final theme = DiscoveryTheme.resolve(raw ?? '');
    if (theme == null) return null;
    final label = theme.localized.trim();
    if (label.isEmpty || label.startsWith('theme.')) return theme.label;
    return label;
  }

  static bool isSafePreview(String body) {
    if (body.trim().isEmpty || body.length > maxBody) return false;
    final lower = body.toLowerCase();
    if (lower.contains('sk-')) return false;
    if (lower.contains('bearer')) return false;
    if (RegExp(r'\d{4}[-/.]\d{1,2}[-/.]\d{1,2}').hasMatch(body)) return false;
    if (RegExp(r'(19|20)\d{2}').hasMatch(body)) return false;
    if (body.contains('@')) return false;
    if (body.contains('/')) return false;
    if (_private.hasMatch(body)) return false;
    return true;
  }

  static final _private = RegExp(
    r'(private dream|rüya kaydı|dream text|rüya günlüğü|'
    r'keşif günlüğü|journal entry|günlük not|'
    r'doğum tarihi|birth ?date|birthDate)',
    caseSensitive: false,
  );
}
