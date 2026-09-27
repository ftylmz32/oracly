/// Dream Phase 1 — Tests G/H: attempt row stores a digest, never narrative.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/dream/services/dream_attempt_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _narrative =
    '  Rüyamda Kırmızı Bir Fener Tutarak Eski Taş Köprünün Altından '
    'Sessizce Yürüyordum  ';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late DreamAttemptStore attempts;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorage.open();
    attempts = DreamAttemptStore(storage);
  });

  Map<String, dynamic> row() =>
      jsonDecode(storage.getString(DreamAttemptStore.key)!)
          as Map<String, dynamic>;

  test('G: stored attempt JSON holds a SHA-256 digest and id only', () async {
    final id = await attempts.resolveId(_narrative);
    final raw = storage.getString(DreamAttemptStore.key)!;
    final normalized = _narrative.trim().toLowerCase();

    expect(raw, isNot(contains(_narrative.trim())));
    expect(raw, isNot(contains(normalized)));
    expect(raw, isNot(contains('Fener')));
    expect(raw.toLowerCase(), isNot(contains('fener')));
    expect(row()['fp'], matches(RegExp(r'^sha256:[0-9a-f]{64}$')));
    expect(row()['id'], id);
    expect(row().keys.toSet(), {'fp', 'id'});
  });

  test('G: same normalized narrative keeps the attempt; a change mints new',
      () async {
    final first = await attempts.resolveId(_narrative);
    final same = await attempts.resolveId(' ${_narrative.toLowerCase()}\n');
    expect(same, first);
    expect(
      DreamAttemptStore.fingerprint(_narrative),
      DreamAttemptStore.fingerprint(_narrative.toLowerCase()),
    );

    final changed = await attempts.resolveId('$_narrative ve uyandım');
    expect(changed, isNot(first));
    expect(
      DreamAttemptStore.fingerprint('$_narrative ve uyandım'),
      isNot(DreamAttemptStore.fingerprint(_narrative)),
    );
  });

  test('G: digest is domain-separated, not a bare hash of the narrative', () {
    expect(
      DreamAttemptStore.fingerprint('a'),
      isNot(DreamAttemptStore.fingerprint('b')),
    );
    expect(DreamAttemptStore.fingerprint(_narrative), isNot(contains('dream:')));
  });

  test('H: legacy plaintext row is dropped and replaced by a digest row',
      () async {
    final normalized = _narrative.trim().toLowerCase();
    await storage.setString(
      DreamAttemptStore.key,
      jsonEncode({'fp': 'dream:$normalized', 'id': 'or-dream-legacy'}),
    );

    final id = await attempts.resolveId(_narrative);
    final raw = storage.getString(DreamAttemptStore.key)!;

    expect(id, isNot('or-dream-legacy'));
    expect(raw, isNot(contains(normalized)));
    expect(raw, isNot(contains('or-dream-legacy')));
    expect(row()['fp'], matches(RegExp(r'^sha256:[0-9a-f]{64}$')));
    expect(await attempts.resolveId(_narrative), id);
  });

  test('H: malformed legacy row never crashes and is replaced', () async {
    await storage.setString(DreamAttemptStore.key, '{not json');
    final id = await attempts.resolveId(_narrative);
    expect(row()['id'], id);
    expect(row()['fp'], startsWith('sha256:'));
  });
}
