/// OR-1100 — Local persistence abstraction.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] for testability.
class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStorage> open() async {
    return LocalStorage(await SharedPreferences.getInstance());
  }

  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  double? getDouble(String key) => _prefs.getDouble(key);
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  bool? getBool(String key) => _prefs.getBool(key);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  List<String>? getStringList(String key) => _prefs.getStringList(key);
  Future<bool> setStringList(String key, List<String> values) =>
      _prefs.setStringList(key, values);

  Future<bool> remove(String key) => _prefs.remove(key);

  /// All persisted keys — used by intelligence layer readers only.
  Set<String> get keys => _prefs.getKeys();
}
