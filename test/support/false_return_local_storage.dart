/// Reusable LocalStorage test double covering BOTH failure modes a real
/// `Future<bool>` SharedPreferences mutation can hit: resolving `false`
/// without throwing, or throwing outright. Configure [falseReturnKeys]
/// and/or [throwingKeys] for set* calls, [falseReturnRemoveKeys] and/or
/// [throwingRemoveKeys] for remove calls (independently — a key can be
/// made to fail on establishment but succeed on removal, or vice versa),
/// mutate them mid-test to simulate storage "recovering", and read
/// [attempts] to assert exactly how many times a given key was mutated.
library;

import 'package:oracly_new/core/data/datasources/local_storage.dart';

class FalseReturnLocalStorage extends LocalStorage {
  FalseReturnLocalStorage(super.prefs);

  /// Keys whose next set* call resolves `false` without throwing.
  final Set<String> falseReturnKeys = {};

  /// Keys whose next set* call throws instead.
  final Set<String> throwingKeys = {};

  /// Keys whose next remove call resolves `false` without throwing.
  final Set<String> falseReturnRemoveKeys = {};

  /// Keys whose next remove call throws instead.
  final Set<String> throwingRemoveKeys = {};

  /// Every set*/remove attempt, by key, regardless of outcome.
  final Map<String, int> attempts = {};

  void _record(String key) => attempts[key] = (attempts[key] ?? 0) + 1;

  Future<bool> _guardSet(String key, Future<bool> Function() op) async {
    _record(key);
    if (throwingKeys.contains(key)) {
      throw StateError('simulated LocalStorage set failure for $key');
    }
    if (falseReturnKeys.contains(key)) return false;
    return op();
  }

  @override
  Future<bool> setString(String key, String value) =>
      _guardSet(key, () => super.setString(key, value));

  @override
  Future<bool> setInt(String key, int value) =>
      _guardSet(key, () => super.setInt(key, value));

  @override
  Future<bool> setDouble(String key, double value) =>
      _guardSet(key, () => super.setDouble(key, value));

  @override
  Future<bool> setBool(String key, bool value) =>
      _guardSet(key, () => super.setBool(key, value));

  @override
  Future<bool> setStringList(String key, List<String> values) =>
      _guardSet(key, () => super.setStringList(key, values));

  @override
  Future<bool> remove(String key) async {
    _record(key);
    if (throwingRemoveKeys.contains(key)) {
      throw StateError('simulated LocalStorage remove failure for $key');
    }
    if (falseReturnRemoveKeys.contains(key)) return false;
    return super.remove(key);
  }
}
