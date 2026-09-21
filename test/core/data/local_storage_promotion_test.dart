/// P0-1 / 1C — LocalStorage.tryPromote must treat a `false` (non-throwing)
/// durable write exactly like a thrown one: never swap the ephemeral map
/// out, never lose data, and let a retry converge once storage recovers.
///
/// [_SelectivelyFailingPrefsStore] installs itself as the actual
/// `SharedPreferencesStorePlatform` backing `SharedPreferences.getInstance()`
/// — this is a genuine platform-level failure injection, not a wrapper
/// around `LocalStorage` itself (tryPromote constructs its own
/// `SharedPreferences` instance internally, so a `LocalStorage`-level fake
/// could never reach it).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  late _SelectivelyFailingPrefsStore fakeStore;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeStore = _SelectivelyFailingPrefsStore();
    SharedPreferencesStorePlatform.instance = fakeStore;
  });

  test('ephemeral storage with no entries promotes trivially', () async {
    final storage = LocalStorage.ephemeral();
    expect(await storage.tryPromote(), isTrue);
    expect(storage.isEphemeral, isFalse);
  });

  test('a healthy promotion swaps every entry over and stays durable', () async {
    final storage = LocalStorage.ephemeral({
      'a': 'x',
      'b': 2,
      'c': true,
      'd': const ['one', 'two'],
    });
    expect(await storage.tryPromote(), isTrue);
    expect(storage.isEphemeral, isFalse);
    expect(storage.getString('a'), 'x');
    expect(storage.getInt('b'), 2);
    expect(storage.getBool('c'), isTrue);
    expect(storage.getStringList('d'), const ['one', 'two']);
  });

  test(
      'one promoted entry returning false keeps storage ephemeral and '
      'loses nothing — every entry is still readable for retry', () async {
    fakeStore.failingKeys.add('pending_marker');
    final storage = LocalStorage.ephemeral({
      'pending_marker': true,
      'other_key': 'value',
    });

    final promoted = await storage.tryPromote();

    expect(promoted, isFalse);
    expect(
      storage.isEphemeral,
      isTrue,
      reason: 'must never swap _prefs in / clear _memory on ANY promotion '
          'failure, not just when the whole call throws',
    );
    expect(storage.getBool('pending_marker'), isTrue);
    expect(storage.getString('other_key'), 'value');
  });

  test(
      'some entries durably succeed, a LATER one returns false — the whole '
      'promotion still fails closed; retry with healthy storage converges '
      'without losing the entries that already succeeded', () async {
    fakeStore.failingKeys.add('later_key');
    final storage = LocalStorage.ephemeral({
      'early_key': 'ok',
      'later_key': 'blocked',
    });

    expect(await storage.tryPromote(), isFalse);
    expect(storage.isEphemeral, isTrue);
    // Still readable from the untouched ephemeral map.
    expect(storage.getString('early_key'), 'ok');
    expect(storage.getString('later_key'), 'blocked');

    fakeStore.failingKeys.clear();
    expect(await storage.tryPromote(), isTrue);
    expect(storage.isEphemeral, isFalse);
    // No data lost across the retry — including the entry that already
    // durably succeeded on the failed attempt (rewritten idempotently).
    expect(storage.getString('early_key'), 'ok');
    expect(storage.getString('later_key'), 'blocked');
  });

  test(
      'a false-returning promotion never lets AccountDeletionPendingState '
      'treat storage as available — the gate must stay storageUnavailable '
      'until promotion truly succeeds', () async {
    fakeStore.failingKeys.add('flag');
    final storage = LocalStorage.ephemeral({'flag': true});

    expect(await storage.tryPromote(), isFalse);
    expect(
      storage.isEphemeral,
      isTrue,
      reason: 'this is exactly the condition '
          'AccountDeletionPendingState._resolveFromLocalStorage checks '
          '(promoted == false || storage.isEphemeral) to fail closed to '
          'storageUnavailable rather than silently deriving clear',
    );
  });
}

/// Installs itself as the real backing store for `SharedPreferences`, so
/// `tryPromote()`'s own internal `prefs.setString/setBool/...` calls
/// genuinely resolve to `false` for configured keys — not merely a
/// same-process double that tryPromote never actually talks to.
class _SelectivelyFailingPrefsStore extends InMemorySharedPreferencesStore {
  _SelectivelyFailingPrefsStore() : super.empty();

  /// Raw (unprefixed) keys whose next setValue/remove call resolves
  /// `false`. Mutate mid-test to simulate storage "recovering".
  final Set<String> failingKeys = {};

  bool _shouldFail(String prefixedKey) =>
      failingKeys.any((k) => prefixedKey == 'flutter.$k' || prefixedKey == k);

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (_shouldFail(key)) return false;
    return super.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) async {
    if (_shouldFail(key)) return false;
    return super.remove(key);
  }
}
