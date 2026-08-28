/// Local persistence abstraction.
library;

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] for testability.
class LocalStorage {
  LocalStorage(SharedPreferences prefs)
      : _prefs = prefs,
        _memory = null;

  LocalStorage.ephemeral([Map<String, Object>? seed])
      : _prefs = null,
        _memory = Map<String, Object>.from(seed ?? const {});

  SharedPreferences? _prefs;
  Map<String, Object>? _memory;

  bool get isEphemeral => _memory != null;

  static Future<LocalStorage> open() async {
    try {
      return LocalStorage(await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 4)));
    } catch (_) {
      try {
        return LocalStorage(await SharedPreferences.getInstance()
            .timeout(const Duration(seconds: 2)));
      } catch (_) {
        return LocalStorage.ephemeral();
      }
    }
  }

  /// Flush ephemeral writes into prefs when they become available.
  Future<bool> tryPromote() async {
    final memory = _memory;
    if (memory == null) return true;
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      for (final e in memory.entries) {
        final v = e.value;
        if (v is String) await prefs.setString(e.key, v);
        else if (v is int) await prefs.setInt(e.key, v);
        else if (v is double) await prefs.setDouble(e.key, v);
        else if (v is bool) await prefs.setBool(e.key, v);
        else if (v is List<String>) await prefs.setStringList(e.key, v);
        else if (v is List) await prefs.setStringList(e.key, v.cast<String>());
      }
      _prefs = prefs;
      _memory = null;
      return true;
    } catch (_) {
      return false;
    }
  }

  String? getString(String key) {
    final m = _memory;
    return m != null ? m[key] as String? : _prefs!.getString(key);
  }

  Future<bool> setString(String key, String value) async {
    final m = _memory;
    if (m != null) { m[key] = value; return true; }
    return _prefs!.setString(key, value);
  }

  int? getInt(String key) {
    final m = _memory;
    return m != null ? m[key] as int? : _prefs!.getInt(key);
  }

  Future<bool> setInt(String key, int value) async {
    final m = _memory;
    if (m != null) { m[key] = value; return true; }
    return _prefs!.setInt(key, value);
  }

  double? getDouble(String key) {
    final m = _memory;
    return m != null ? m[key] as double? : _prefs!.getDouble(key);
  }

  Future<bool> setDouble(String key, double value) async {
    final m = _memory;
    if (m != null) { m[key] = value; return true; }
    return _prefs!.setDouble(key, value);
  }

  bool? getBool(String key) {
    final m = _memory;
    return m != null ? m[key] as bool? : _prefs!.getBool(key);
  }

  Future<bool> setBool(String key, bool value) async {
    final m = _memory;
    if (m != null) { m[key] = value; return true; }
    return _prefs!.setBool(key, value);
  }

  List<String>? getStringList(String key) {
    final m = _memory;
    if (m != null) {
      final value = m[key];
      if (value is List<String>) return value;
      if (value is List) return value.cast<String>();
      return null;
    }
    return _prefs!.getStringList(key);
  }

  Future<bool> setStringList(String key, List<String> values) async {
    final m = _memory;
    if (m != null) { m[key] = List<String>.from(values); return true; }
    return _prefs!.setStringList(key, values);
  }

  Future<bool> remove(String key) async {
    final m = _memory;
    if (m != null) { m.remove(key); return true; }
    return _prefs!.remove(key);
  }

  Set<String> get keys =>
      _memory != null ? _memory!.keys.toSet() : _prefs!.getKeys();
}
