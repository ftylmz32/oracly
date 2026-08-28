/// Profile photo lives only on device documents — never sent to AI.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/screens/profile/data/profile_photo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late Directory documents;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    documents = Directory.systemTemp.createTempSync('oracly_avatar_');
  });

  tearDown(() {
    if (documents.existsSync()) documents.deleteSync(recursive: true);
  });

  test('save copies into a stable documents file and can be cleared', () async {
    final source = File('${documents.path}/source.jpg')
      ..writeAsBytesSync(const [1, 2, 3, 4]);

    await ProfilePhotoStore.save(
      storage,
      source.path,
      documents: documents,
      stamp: 17,
    );

    final dest = File(
      '${documents.path}/${ProfilePhotoStore.filePrefix}_17.jpg',
    );
    expect(storage.getString(ProfilePhotoStore.key), dest.path);
    expect(dest.existsSync(), isTrue);
    expect(dest.readAsBytesSync(), const [1, 2, 3, 4]);
    expect(ProfilePhotoStore.imageOf(storage), isNotNull);

    await ProfilePhotoStore.clear(storage);
    expect(storage.getString(ProfilePhotoStore.key), isNull);
    expect(dest.existsSync(), isFalse);
    expect(ProfilePhotoStore.imageOf(storage), isNull);
  });

  test('AI sources do not import the profile photo store', () {
    final aiRoot = Directory('lib/features/ai');
    expect(aiRoot.existsSync(), isTrue);
    final hits = <String>[];
    for (final file in aiRoot.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final text = file.readAsStringSync();
      if (text.contains('profile_photo_store') ||
          text.contains('ProfilePhotoStore')) {
        hits.add(file.path);
      }
    }
    expect(hits, isEmpty);
  });
}
