/// "Şimdi değil" memory for the Home introduction invite — one owner, 7 days.
library;

import 'dart:convert';

import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/data/datasources/local_storage.dart';

class HomeInviteStore {
  const HomeInviteStore(this._storage);

  /// Wiped on account switch; also tagged with the owner so it never leaks.
  static const key = 'home_invite_snooze';
  static const snooze = Duration(days: 7);

  final LocalStorage _storage;

  String get _owner =>
      _storage.getString(UserLocalDataIsolation.ownerKey)?.trim() ?? '';

  /// Snooze end for the current owner, or null when none applies.
  DateTime? until() {
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['owner'] != _owner) return null;
      final millis = json['until'] as int?;
      return millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      return null;
    }
  }

  bool snoozed(DateTime now) {
    final end = until();
    return end != null && now.isBefore(end);
  }

  Future<DateTime> dismiss(DateTime now) async {
    final end = now.add(snooze);
    await _storage.setString(
      key,
      jsonEncode({'owner': _owner, 'until': end.millisecondsSinceEpoch}),
    );
    return end;
  }
}
