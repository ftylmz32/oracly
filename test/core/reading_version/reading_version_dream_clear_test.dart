/// Dream Phase 1 — narrow version removal keeps every other feature's chain.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/reading_version/models/reading_version_kind.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_service.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late ReadingVersionStore store;
  late ReadingVersionService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorage.open();
    store = ReadingVersionStore(storage);
    service = ReadingVersionService(store);
    for (final kind in ReadingVersionKind.values) {
      await service.seedOriginal(
        rootId: '${kind.name}_1',
        kind: kind,
        data: {'analysis': '${kind.name} text'},
      );
    }
    await service.seedOriginal(
      rootId: 'dream_2',
      kind: ReadingVersionKind.dream,
      data: const {'analysis': 'second dream'},
    );
  });

  Map<String, dynamic> raw() => Map<String, dynamic>.from(
        jsonDecode(storage.getString(ReadingVersionStore.key)!) as Map,
      );

  test('removeKind(dream) drops only dream chains', () async {
    await store.removeKind(ReadingVersionKind.dream);

    expect(store.byRootId('dream_1'), isNull);
    expect(store.byRootId('dream_2'), isNull);
    expect(store.byRootId('tarot_1'), isNotNull);
    expect(store.byRootId('coffee_1'), isNotNull);
    expect(store.byRootId('palm_1'), isNotNull);
  });

  test('malformed rows keyed by a dream id are removed; others survive',
      () async {
    final map = raw()
      ..['dream_corrupt'] = 'garbage'
      ..['coffee_corrupt'] = 42;
    await storage.setString(ReadingVersionStore.key, jsonEncode(map));

    await store.removeKind(
      ReadingVersionKind.dream,
      rootIds: {'dream_corrupt'},
    );

    final after = raw();
    expect(after.containsKey('dream_corrupt'), isFalse);
    expect(after.containsKey('dream_1'), isFalse);
    expect(after['coffee_corrupt'], 42);
    expect(after.keys, containsAll(['tarot_1', 'coffee_1', 'palm_1']));
  });

  test('an unparseable blob (unreadable for every kind) is removed', () async {
    await storage.setString(ReadingVersionStore.key, '{broken');
    await store.removeKind(ReadingVersionKind.dream);
    expect(storage.getString(ReadingVersionStore.key), isNull);
  });

  test('removeRoot removes exactly one chain', () async {
    await service.removeRoot('dream_2');
    expect(store.byRootId('dream_2'), isNull);
    expect(store.byRootId('dream_1'), isNotNull);
    expect(store.byRootId('tarot_1'), isNotNull);
  });
}
