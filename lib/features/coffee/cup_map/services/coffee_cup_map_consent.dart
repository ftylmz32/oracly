/// The user's explicit choice to keep a Coffee V3 reading's photos on this
/// device for Fincan Haritası. Off unless this owner turned it on: no
/// choice, another owner's choice or unreadable data all mean "do not
/// keep", and the reading then runs exactly as before.
library;

import 'dart:convert';

import '../../../../core/auth/user_local_data_isolation.dart';
import '../../../../core/data/datasources/local_storage.dart';

class CoffeeCupMapConsent {
  CoffeeCupMapConsent(this._storage);

  static const key = 'coffee_cup_map_consent_v1';

  final LocalStorage _storage;

  String get _owner =>
      _storage.getString(UserLocalDataIsolation.ownerKey)?.trim() ?? '';

  bool get keepPhotos {
    final owner = _owner;
    if (owner.isEmpty) return false;
    try {
      final json = jsonDecode(_storage.getString(key) ?? 'null');
      return json is Map &&
          json['ownerId'] == owner &&
          json['keepPhotos'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Returns whether the choice was stored; without an owner it is not.
  Future<bool> setKeepPhotos(bool keep) async {
    final owner = _owner;
    if (owner.isEmpty) return false;
    return _storage.setString(
      key,
      jsonEncode({'ownerId': owner, 'keepPhotos': keep}),
    );
  }
}
