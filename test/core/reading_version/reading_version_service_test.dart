/// Reading version chains — original plus meaningful revisions only.

library;



import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/data/datasources/local_storage.dart';

import 'package:oracly_new/core/reading_version/models/reading_version_kind.dart';

import 'package:oracly_new/core/reading_version/services/reading_version_fingerprint.dart';

import 'package:oracly_new/core/reading_version/services/reading_version_service.dart';

import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';

import 'package:shared_preferences/shared_preferences.dart';



void main() {

  test('fingerprint ignores whitespace-only differences', () {

    expect(

      ReadingVersionFingerprint.isMeaningful('Merhaba dünya', '  merhaba   dünya  '),

      isFalse,

    );

  });



  test('append revision only when content changes', () async {

    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();

    final service = ReadingVersionService(ReadingVersionStore(LocalStorage(prefs)));

    const rootId = 'coffee_1';

    const first = {'overall': 'Yol açılıyor'};

    await service.seedOriginal(

      rootId: rootId,

      kind: ReadingVersionKind.coffee,

      data: first,

    );

    final duplicate = await service.tryAppendRevision(

      rootId: rootId,

      kind: ReadingVersionKind.coffee,

      data: first,

    );

    expect(duplicate.added, isFalse);

    expect(duplicate.group.entries.length, 1);



    final changed = await service.tryAppendRevision(

      rootId: rootId,

      kind: ReadingVersionKind.coffee,

      data: {'overall': 'Yeni bir yorum'},

    );

    expect(changed.added, isTrue);

    expect(changed.group.entries.length, 2);

    expect(changed.group.activeNumber, 2);

  });



  test('journal root id stays single chain', () async {

    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();

    final store = ReadingVersionStore(LocalStorage(prefs));

    final service = ReadingVersionService(store);

    const rootId = 'dream_9';

    await service.seedOriginal(

      rootId: rootId,

      kind: ReadingVersionKind.dream,

      data: {'analysis': 'İlk yorum', 'payload': {}},

    );

    await service.tryAppendRevision(

      rootId: rootId,

      kind: ReadingVersionKind.dream,

      data: {'analysis': 'Revizyon 2', 'payload': {}},

    );

    final group = store.byRootId(rootId);

    expect(group?.rootId, rootId);

    expect(group?.entries.length, 2);

  });

}


