/// Local persistence abstraction.
library;

import 'package:flutter/foundation.dart';
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
  /// Raw value without typed casts — used for legacy migration.
  Object? peek(String key) =>
      _memory != null ? _memory![key] : _prefs!.get(key);

  void _badType(String key, String expected, Object actual) => debugPrint(
        '[LocalStorage] $key expected $expected, got ${actual.runtimeType}',
      );

  String? getString(String key) {
    final v = peek(key);
    if (v == null) return null;
    if (v is String) return v;
    _badType(key, 'String', v);
    return null;
  }

  Future<bool> setString(String key, String value) async {
    final m = _memory;
    if (m != null) { m[key] = value; return true; }
    return _prefs!.setString(key, value);
  }

  int? getInt(String key) {
    final v = peek(key);
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    _badType(key, 'int', v);
    return null;
  }

  Future<bool> setInt(String key, int value) async {
    final m = _memory;
    if (m != null) { m[key] = value; return true; }
    return _prefs!.setInt(key, value);
  }

  double? getDouble(String key) {
    final v = peek(key);
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    _badType(key, 'double', v);
    return null;
  }

  Future<bool> setDouble(String key, double value) async {
    final m = _memory;
    if (m != null) { m[key] = value; return true; }
    return _prefs!.setDouble(key, value);
  }

  bool? getBool(String key) {
    final v = peek(key);
    if (v == null) return null;
    if (v is bool) return v;
    _badType(key, 'bool', v);
    return null;
  }

  Future<bool> setBool(String key, bool value) async {
    final m = _memory;
    if (m != null) { m[key] = value; return true; }
    return _prefs!.setBool(key, value);
  }

  List<String>? getStringList(String key) {
    final v = peek(key);
    if (v == null) return null;
    if (v is List<String>) return List<String>.from(v);
    if (v is List && v.every((e) => e is String)) {
      return v.cast<String>().toList();
    }
    _badType(key, 'List<String>', v);
    return null;
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
