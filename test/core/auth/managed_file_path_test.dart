/// Profile / SoulMate managed-path tri-state + save durability.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/managed_file_path.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/premium/data/soul_mate_interpretation_catalogue.dart';
import 'package:oracly_new/features/premium/data/soul_mate_result_store.dart';
import 'package:oracly_new/features/premium/models/soul_mate_saved_result.dart';
import 'package:oracly_new/screens/profile/data/profile_photo_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/false_return_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late LocalStorage storage;
  late InMemorySecureStorage secure;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('oracly-managed-path-');
    PathProviderPlatform.instance = _TempPathProvider(root.path);
    storage = LocalStorage(await SharedPreferences.getInstance());
    secure = InMemorySecureStorage();
  });

  tearDown(() async {
    try {
      if (await root.exists()) await root.delete(recursive: true);
    } catch (_) {}
  });

  test('traversal path is notManaged — never deletes outside target', () {
    final docs = ManagedFilePath.normalize('${root.path}/docs');
    final escape = ManagedFilePath.normalize('${root.path}/docs/../secret.jpg');
    expect(ManagedFilePath.isStrictlyInside(docs, escape), isFalse);
  });

  test(
      'profile managed path + path_provider throw keeps metadata and file',
      () async {
    final src = File('${root.path}${Platform.pathSeparator}src.jpg');
    await src.writeAsBytes(const [1, 2, 3]);
    await ProfilePhotoStore.save(storage, src.path, documents: root);
    final managed = storage.getString(ProfilePhotoStore.key)!;
    expect(File(managed).existsSync(), isTrue);

    PathProviderPlatform.instance = _ThrowingPathProvider();
    final wipe = await UserLocalDataWipe.run(storage, secureStorage: secure);
    expect(wipe.isComplete, isFalse);
    expect(storage.getString(ProfilePhotoStore.key), managed);
    expect(File(managed).existsSync(), isTrue);

    PathProviderPlatform.instance = _TempPathProvider(root.path);
    final recovered =
        await UserLocalDataWipe.run(storage, secureStorage: secure);
    expect(recovered.isComplete, isTrue);
    expect(storage.getString(ProfilePhotoStore.key), isNull);
    expect(File(managed).existsSync(), isFalse);
  });

  test(
      'soulmate managed path + path_provider throw keeps metadata and file',
      () async {
    final saved = await SoulMateResultStore.save(
      storage: storage,
      record: SoulMateSavedResult(
        id: 'sm-unk',
        createdAt: DateTime(2026, 1, 1),
        name: 'A',
        birthDate: DateTime(1990, 1, 1),
        intention: 'calm',
        portraitPath: '',
        parts: const SoulMateReadingParts(
          energy: 'e',
          attraction: 'a',
          dynamics: 'd',
          feeling: 'f',
          yourSide: 'y',
        ),
      ),
      portraitBytes: const [7, 8, 9],
      documents: root,
    );
    final portrait = saved!.portraitPath;

    PathProviderPlatform.instance = _ThrowingPathProvider();
    final wipe = await UserLocalDataWipe.run(storage, secureStorage: secure);
    expect(wipe.isComplete, isFalse);
    expect(
      (await SoulMateResultStore.readMeta(storage))?.portraitPath,
      portrait,
    );
    expect(File(portrait).existsSync(), isTrue);

    PathProviderPlatform.instance = _TempPathProvider(root.path);
    final recovered =
        await UserLocalDataWipe.run(storage, secureStorage: secure);
    expect(recovered.isComplete, isTrue);
    expect(await SoulMateResultStore.readMeta(storage), isNull);
    expect(File(portrait).existsSync(), isFalse);
  });

  test(
      'profile save: metadata write false deletes new file and keeps prior',
      () async {
    final src1 = File('${root.path}${Platform.pathSeparator}a.jpg');
    final src2 = File('${root.path}${Platform.pathSeparator}b.jpg');
    await src1.writeAsBytes(const [1]);
    await src2.writeAsBytes(const [2]);
    await ProfilePhotoStore.save(storage, src1.path, documents: root);
    final prior = storage.getString(ProfilePhotoStore.key)!;

    final failing = FalseReturnLocalStorage(
      await SharedPreferences.getInstance(),
    );
    await failing.setString(ProfilePhotoStore.key, prior);
    failing.falseReturnKeys.add(ProfilePhotoStore.key);

    await expectLater(
      ProfilePhotoStore.save(failing, src2.path, documents: root),
      throwsA(isA<StateError>()),
    );
    expect(failing.getString(ProfilePhotoStore.key), prior);
    expect(File(prior).existsSync(), isTrue);
    final managed = root
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains(ProfilePhotoStore.filePrefix))
        .toList();
    expect(managed, hasLength(1));
    expect(
      ManagedFilePath.normalize(managed.single.path),
      ManagedFilePath.normalize(prior),
    );
  });

  test(
      'profile external rogue path — file never deleted, metadata removed',
      () async {
    final external = File('${root.path}${Platform.pathSeparator}gallery.jpg')
      ..writeAsBytesSync(const [9, 9, 9]);
    await storage.setString(ProfilePhotoStore.key, external.path);

    await ProfilePhotoStore.clearStrict(storage);

    expect(external.existsSync(), isTrue);
    expect(storage.getString(ProfilePhotoStore.key), isNull);
  });

  test(
      'profile traversal metadata path never deletes the escaped target',
      () async {
    final escape = File(
      '${root.parent.path}${Platform.pathSeparator}'
      '${ProfilePhotoStore.filePrefix}_escape.jpg',
    )..writeAsBytesSync(const [4, 4, 4]);
    final traversal =
        '${root.path}${Platform.pathSeparator}..${Platform.pathSeparator}'
        '${ProfilePhotoStore.filePrefix}_escape.jpg';
    await storage.setString(ProfilePhotoStore.key, traversal);

    await ProfilePhotoStore.clearStrict(storage);

    expect(escape.existsSync(), isTrue);
    expect(storage.getString(ProfilePhotoStore.key), isNull);
  });

  test(
      'soulmate external rogue path — portrait never deleted, meta removed',
      () async {
    final external = File('${root.path}${Platform.pathSeparator}rogue.jpg')
      ..writeAsBytesSync(const [3, 3, 3]);
    await storage.setString(
      SoulMateResultStore.metaKey,
      jsonEncode(
        SoulMateSavedResult(
          id: 'sm-ext',
          createdAt: DateTime(2026, 1, 1),
          name: 'A',
          birthDate: DateTime(1990, 1, 1),
          intention: 'calm',
          portraitPath: external.path,
          parts: const SoulMateReadingParts(
            energy: 'e',
            attraction: 'a',
            dynamics: 'd',
            feeling: 'f',
            yourSide: 'y',
          ),
        ).toJson(),
      ),
    );

    await SoulMateResultStore.clearStrict(storage);

    expect(external.existsSync(), isTrue);
    expect(await SoulMateResultStore.readMeta(storage), isNull);
  });

  test(
      'soulmate traversal metadata path never deletes the escaped portrait',
      () async {
    final escape = File(
      '${root.parent.path}${Platform.pathSeparator}'
      '${SoulMateResultStore.portraitPrefix}_escape.jpg',
    )..writeAsBytesSync(const [5, 5, 5]);
    final traversal =
        '${root.path}${Platform.pathSeparator}..${Platform.pathSeparator}'
        '${SoulMateResultStore.portraitPrefix}_escape.jpg';
    await storage.setString(
      SoulMateResultStore.metaKey,
      jsonEncode(
        SoulMateSavedResult(
          id: 'sm-trav',
          createdAt: DateTime(2026, 1, 1),
          name: 'A',
          birthDate: DateTime(1990, 1, 1),
          intention: 'calm',
          portraitPath: traversal,
          parts: const SoulMateReadingParts(
            energy: 'e',
            attraction: 'a',
            dynamics: 'd',
            feeling: 'f',
            yourSide: 'y',
          ),
        ).toJson(),
      ),
    );

    await SoulMateResultStore.clearStrict(storage);

    expect(escape.existsSync(), isTrue);
    expect(await SoulMateResultStore.readMeta(storage), isNull);
  });
}

class _TempPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _TempPathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getTemporaryPath() async => root;
  @override
  Future<String?> getApplicationCachePath() async => root;
}

class _ThrowingPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async =>
      throw StateError('path_provider unavailable');
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      throw StateError('path_provider unavailable');
  @override
  Future<String?> getTemporaryPath() async =>
      throw StateError('path_provider unavailable');
  @override
  Future<String?> getApplicationCachePath() async =>
      throw StateError('path_provider unavailable');
}
