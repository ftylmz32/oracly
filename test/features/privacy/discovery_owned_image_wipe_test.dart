/// Coffee/Palm owned image wipe ? privacy regression tests.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/owned_file_cleanup_journal.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/intelligence/data/personal_memory_store.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_service.dart';
import 'package:oracly_new/core/services/history_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_archive.dart';
import 'package:oracly_new/features/favorite_moments/data/local_favorite_moments_repository.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moments_service.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_image_archive.dart';
import 'package:oracly_new/features/premium/data/soul_mate_interpretation_catalogue.dart';
import 'package:oracly_new/features/premium/data/soul_mate_result_store.dart';
import 'package:oracly_new/features/premium/models/soul_mate_saved_result.dart';
import 'package:oracly_new/features/privacy/services/discovery_owned_image_wipe.dart';
import 'package:oracly_new/features/privacy/services/privacy_control_service.dart';
import 'package:oracly_new/features/privacy/services/privacy_discovery_clear.dart';
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
    root = await Directory.systemTemp.createTemp('oracly-image-wipe-');
    PathProviderPlatform.instance = _TempPathProvider(root.path);
    storage = LocalStorage(await SharedPreferences.getInstance());
    secure = InMemorySecureStorage();
  });

  tearDown(() async {
    try {
      if (await root.exists()) await root.delete(recursive: true);
    } catch (_) {
      // Windows may hold a file handle briefly after attrib/delete.
    }
  });

  Future<File> gallerySource() async {
    final file = File('${root.path}${Platform.pathSeparator}gallery_cup.jpg');
    await file.writeAsBytes(const [9, 8, 7]);
    return file;
  }

  Future<String> seedCoffee() async {
    final source = await gallerySource();
    final archived = await CoffeeImageArchive.persist(
      readingId: 'coffee-wipe-1',
      sourcePath: source.path,
    );
    await CoffeeReadingStore(storage).save(
      CoffeeReading(
        id: 'coffee-wipe-1',
        createdAt: DateTime(2026, 1, 1),
        overall: 'Cup',
        love: 'Love',
        career: 'Career',
        money: 'Money',
        nearFuture: 'Near',
        takeaway: 'Take',
        imagePath: archived,
      ),
    );
    return archived;
  }

  Future<String> seedPalm() async {
    final source = await gallerySource();
    final archived = await PalmImageArchive.persist(
      readingId: 'palm-wipe-1',
      sourcePath: source.path,
    );
    await PalmReadingStore(storage).save(
      PalmReading(
        id: 'palm-wipe-1',
        createdAt: DateTime(2026, 1, 1),
        hand: PalmHand.right,
        overall: 'Palm',
        imagePath: archived,
      ),
    );
    return archived;
  }

  PrivacyControlService privacyService() => PrivacyControlService(
        history: HistoryService(MockHistoryRepository(storage)),
        favorites: FavoriteMomentsService(
          LocalFavoriteMomentsRepository(storage),
        ),
        personalMemory: PersonalMemoryService(PersonalMemoryStore(storage)),
        birthCharts: LocalBirthChartRepository(storage),
        storage: storage,
      );

  test('discovery clear deletes coffee metadata and owned archive file', () async {
    final archived = await seedCoffee();
    final gallery = await gallerySource();
    expect(File(archived).existsSync(), isTrue);

    await privacyService().clearDiscoveryHistory();

    expect(CoffeeReadingStore(storage).all(), isEmpty);
    expect(File(archived).existsSync(), isFalse);
    expect(gallery.existsSync(), isTrue);
  });

  test('discovery clear deletes palm metadata and owned archive file', () async {
    final archived = await seedPalm();
    final gallery = await gallerySource();
    expect(File(archived).existsSync(), isTrue);

    await privacyService().clearDiscoveryHistory();

    expect(PalmReadingStore(storage).all(), isEmpty);
    expect(File(archived).existsSync(), isFalse);
    expect(gallery.existsSync(), isTrue);
  });

  test('account switch deletes prior user coffee and palm owned files', () async {
    final coffee = await seedCoffee();
    final palm = await seedPalm();
    final isolation = UserLocalDataIsolation(
      storage,
      secureStorage: secure,
    );
    await isolation.onSignedIn('owner-a');
    await isolation.onSignedIn('owner-b');
    // Image wipe is fire-and-forget inside UserLocalDataWipe; await for assertion.
    await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImages(storage);

    expect(CoffeeReadingStore(storage).all(), isEmpty);
    expect(PalmReadingStore(storage).all(), isEmpty);
    expect(File(coffee).existsSync(), isFalse);
    expect(File(palm).existsSync(), isFalse);
  });

  test('account deletion wipe removes coffee and palm owned files', () async {
    final coffee = await seedCoffee();
    final palm = await seedPalm();

    await UserLocalDataWipe.run(storage, secureStorage: secure);
    await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImages(storage);

    expect(CoffeeReadingStore(storage).all(), isEmpty);
    expect(PalmReadingStore(storage).all(), isEmpty);
    expect(File(coffee).existsSync(), isFalse);
    expect(File(palm).existsSync(), isFalse);
  });

  test('missing owned file and repeated wipe stay safe', () async {
    final archived = await seedCoffee();
    await File(archived).delete();
    await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImages(storage);
    expect(CoffeeReadingStore(storage).all(), isNotEmpty);

    await storage.setStringList(CoffeeReadingStore.key, const []);
    await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImages(storage);
    expect(CoffeeReadingStore(storage).all(), isEmpty);
  });

  test('external non-owned metadata path is never deleted', () async {
    final external = File('${root.path}${Platform.pathSeparator}outside.jpg');
    await external.writeAsBytes(const [1, 2, 3]);
    await CoffeeReadingStore(storage).save(
      CoffeeReading(
        id: 'coffee-external',
        createdAt: DateTime(2026, 1, 1),
        overall: 'Cup',
        love: 'Love',
        career: 'Career',
        money: 'Money',
        nearFuture: 'Near',
        takeaway: 'Take',
        imagePath: external.path,
      ),
    );

    await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImages(storage);

    expect(external.existsSync(), isTrue);
    await storage.setStringList(CoffeeReadingStore.key, const []);
  });

  test('original gallery source is never deleted', () async {
    final gallery = await gallerySource();
    final archived = await CoffeeImageArchive.persist(
      readingId: 'coffee-gallery',
      sourcePath: gallery.path,
    );
    await CoffeeReadingStore(storage).save(
      CoffeeReading(
        id: 'coffee-gallery',
        createdAt: DateTime(2026, 1, 1),
        overall: 'Cup',
        love: 'Love',
        career: 'Career',
        money: 'Money',
        nearFuture: 'Near',
        takeaway: 'Take',
        imagePath: archived,
      ),
    );

    await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImages(storage);

    expect(gallery.existsSync(), isTrue);
    expect(File(archived).existsSync(), isFalse);
  });

  test('discovery wipe leaves profile and soulmate portrait untouched', () async {
    final coffee = await seedCoffee();
    final profileSrc = File('${root.path}${Platform.pathSeparator}profile_src.jpg');
    await profileSrc.writeAsBytes(const [4, 5, 6]);
    await ProfilePhotoStore.save(storage, profileSrc.path, documents: root);
    final profilePath = storage.getString(ProfilePhotoStore.key)!;

    final savedSoulmate = await SoulMateResultStore.save(
      storage: storage,
      record: SoulMateSavedResult(
        id: 'sm1',
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
    final soulmatePortrait = File(savedSoulmate!.portraitPath);

    await privacyService().clearDiscoveryHistory();

    expect(File(coffee).existsSync(), isFalse);
    expect(File(profilePath).existsSync(), isTrue);
    expect(soulmatePortrait.existsSync(), isTrue);
  });

  test('metadata clears even when archive path is malformed', () async {
    await storage.setStringList(CoffeeReadingStore.key, const ['{bad']);
    await storage.setStringList(PalmReadingStore.key, const ['not-json']);

    await PrivacyDiscoveryClear.run(
      storage: storage,
      history: HistoryService(MockHistoryRepository(storage)),
      birthCharts: LocalBirthChartRepository(storage),
    );

    expect(CoffeeReadingStore(storage).all(), isEmpty);
    expect(PalmReadingStore(storage).all(), isEmpty);
  });

  test('palm individual delete still removes owned file only', () async {
    final archived = await seedPalm();
    await PalmReadingStore(storage).delete('palm-wipe-1');
    expect(PalmReadingStore(storage).all(), isEmpty);
    expect(File(archived).existsSync(), isFalse);
  });

  group('P0-4 / 4A — strict account-boundary file cleanup', () {
    test(
        'coffee owned file delete failure blocks an owner switch; the '
        'journal preserves the exact path, and a retry after the file '
        'becomes deletable again completes the switch', () async {
      final archived = await seedCoffee();
      await _makeUndeletable(archived);

      final isolation = UserLocalDataIsolation(storage, secureStorage: secure);
      await isolation.onSignedIn('owner-a-coffee-fail');
      final blocked = await isolation.onSignedIn('owner-b-coffee-fail');

      expect(blocked.success, isFalse);
      expect(isolation.localOwnerId, 'owner-a-coffee-fail');
      expect(File(archived).existsSync(), isTrue);
      expect(OwnedFileCleanupJournal.read(storage), contains(archived));

      await _makeDeletable(archived);
      final recovered = await isolation.onSignedIn('owner-b-coffee-fail');

      expect(recovered.success, isTrue);
      expect(isolation.localOwnerId, 'owner-b-coffee-fail');
      expect(File(archived).existsSync(), isFalse);
      expect(OwnedFileCleanupJournal.read(storage), isEmpty);
    });

    test(
        'palm owned file delete failure blocks an owner switch; retry after '
        'recovery completes it', () async {
      final archived = await seedPalm();
      await _makeUndeletable(archived);

      final isolation = UserLocalDataIsolation(storage, secureStorage: secure);
      await isolation.onSignedIn('owner-a-palm-fail');
      final blocked = await isolation.onSignedIn('owner-b-palm-fail');

      expect(blocked.success, isFalse);
      expect(isolation.localOwnerId, 'owner-a-palm-fail');
      expect(File(archived).existsSync(), isTrue);
      expect(OwnedFileCleanupJournal.read(storage), contains(archived));

      await _makeDeletable(archived);
      final recovered = await isolation.onSignedIn('owner-b-palm-fail');

      expect(recovered.success, isTrue);
      expect(isolation.localOwnerId, 'owner-b-palm-fail');
      expect(File(archived).existsSync(), isFalse);
    });

    test(
        'profile photo delete failure blocks an owner switch; the path stays '
        'in storage for retry instead of being orphaned', () async {
      final profileSrc = File('${root.path}${Platform.pathSeparator}profile_fail.jpg');
      await profileSrc.writeAsBytes(const [4, 5, 6]);
      await ProfilePhotoStore.save(storage, profileSrc.path, documents: root);
      final profilePath = storage.getString(ProfilePhotoStore.key)!;
      await _makeUndeletable(profilePath);

      final isolation = UserLocalDataIsolation(storage, secureStorage: secure);
      await isolation.onSignedIn('owner-a-profile-fail');
      final blocked = await isolation.onSignedIn('owner-b-profile-fail');

      expect(blocked.success, isFalse);
      expect(isolation.localOwnerId, 'owner-a-profile-fail');
      expect(File(profilePath).existsSync(), isTrue);
      expect(
        storage.getString(ProfilePhotoStore.key),
        profilePath,
        reason: 'metadata must not be erased before the physical file is '
            'proven gone — otherwise the path would be lost forever',
      );

      await _makeDeletable(profilePath);
      final recovered = await isolation.onSignedIn('owner-b-profile-fail');

      expect(recovered.success, isTrue);
      expect(File(profilePath).existsSync(), isFalse);
      expect(storage.getString(ProfilePhotoStore.key), isNull);
    });

    test(
        'soulmate portrait delete failure blocks an owner switch; retry '
        'after recovery completes it', () async {
      final savedSoulmate = await SoulMateResultStore.save(
        storage: storage,
        record: SoulMateSavedResult(
          id: 'sm-fail',
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
      final portraitPath = savedSoulmate!.portraitPath;
      await _makeUndeletable(portraitPath);

      final isolation = UserLocalDataIsolation(storage, secureStorage: secure);
      await isolation.onSignedIn('owner-a-soulmate-fail');
      final blocked = await isolation.onSignedIn('owner-b-soulmate-fail');

      expect(blocked.success, isFalse);
      expect(isolation.localOwnerId, 'owner-a-soulmate-fail');
      expect(File(portraitPath).existsSync(), isTrue);
      expect(
        (await SoulMateResultStore.readMeta(storage))?.portraitPath,
        portraitPath,
        reason: 'metadata must not be erased before the physical file is '
            'proven gone',
      );

      await _makeDeletable(portraitPath);
      final recovered = await isolation.onSignedIn('owner-b-soulmate-fail');

      expect(recovered.success, isTrue);
      expect(File(portraitPath).existsSync(), isFalse);
      expect(await SoulMateResultStore.readMeta(storage), isNull);
    });

    test(
        'an external (non-owned) file is never deleted and never counted as '
        'a strict cleanup failure', () async {
      final external = File('${root.path}${Platform.pathSeparator}outside_strict.jpg');
      await external.writeAsBytes(const [1, 2, 3]);
      await CoffeeReadingStore(storage).save(
        CoffeeReading(
          id: 'coffee-external-strict',
          createdAt: DateTime(2026, 1, 1),
          overall: 'Cup',
          love: 'Love',
          career: 'Career',
          money: 'Money',
          nearFuture: 'Near',
          takeaway: 'Take',
          imagePath: external.path,
        ),
      );

      final ok = await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImagesStrict(storage);

      expect(ok.complete, isTrue);
      expect(external.existsSync(), isTrue);
    });

    test(
        'delete fail + journal write fail retains Coffee metadata as the '
        'last durable locator — wipe incomplete, owner transfer blocked',
        () async {
      final archived = await seedCoffee();
      await _makeUndeletable(archived);
      final failing = FalseReturnLocalStorage(
        await SharedPreferences.getInstance(),
      );
      // Copy coffee readings into the failing storage.
      await failing.setStringList(
        CoffeeReadingStore.key,
        storage.getStringList(CoffeeReadingStore.key)!,
      );
      failing.falseReturnKeys.add(OwnedFileCleanupJournal.key);

      final result =
          await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImagesStrict(failing);
      expect(result.complete, isFalse);
      expect(result.metadataMayBeCleared, isFalse);

      final wipe = await UserLocalDataWipe.run(
        failing,
        secureStorage: secure,
      );
      expect(wipe.isComplete, isFalse);
      expect(
        CoffeeReadingStore(failing).all().single.imagePath,
        archived,
        reason: 'metadata must survive when the journal cannot retain the path',
      );
      expect(File(archived).existsSync(), isTrue);

      await _makeDeletable(archived);
      failing.falseReturnKeys.clear();
      final recovered =
          await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImagesStrict(failing);
      expect(recovered.complete, isTrue);
      expect(File(archived).existsSync(), isFalse);
    });

    test(
        'corrupt journal with healthy archive access reconciles and retires '
        'the corrupt ledger', () async {
      final archived = await seedCoffee();
      expect(File(archived).existsSync(), isTrue);
      final ephemeral = LocalStorage.ephemeral({
        OwnedFileCleanupJournal.key: 'not-a-list',
        CoffeeReadingStore.key: storage.getStringList(CoffeeReadingStore.key)!,
      });

      final result =
          await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImagesStrict(
        ephemeral,
      );
      expect(result.complete, isTrue);
      expect(result.metadataMayBeCleared, isTrue);
      expect(
        OwnedFileCleanupJournal.inspect(ephemeral),
        OwnedFileJournalRead.absent,
        reason: 'corrupt journal must be retired after reconciliation',
      );
      expect(File(archived).existsSync(), isFalse);
    });

    test(
        'corrupt journal + path_provider unavailable stays incomplete with '
        'metadata retained', () async {
      await seedCoffee();
      final ephemeral = LocalStorage.ephemeral({
        OwnedFileCleanupJournal.key: 42,
        CoffeeReadingStore.key: storage.getStringList(CoffeeReadingStore.key)!,
      });
      PathProviderPlatform.instance = _ThrowingPathProvider();

      final result =
          await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImagesStrict(
        ephemeral,
      );
      expect(result.complete, isFalse);
      expect(result.metadataMayBeCleared, isFalse);
      expect(
        OwnedFileCleanupJournal.inspect(ephemeral),
        OwnedFileJournalRead.corrupt,
      );
      expect(CoffeeReadingStore(ephemeral).all(), isNotEmpty);

      PathProviderPlatform.instance = _TempPathProvider(root.path);
      final recovered =
          await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImagesStrict(
        ephemeral,
      );
      expect(recovered.complete, isTrue);
      expect(
        OwnedFileCleanupJournal.inspect(ephemeral),
        OwnedFileJournalRead.absent,
      );
    });

    test(
        'empty metadata but orphan owned archive file is still purged by '
        'strict wipe before reporting complete', () async {
      final orphan = File(
        '${root.path}${Platform.pathSeparator}coffee_images'
        '${Platform.pathSeparator}orphan.jpg',
      );
      await orphan.parent.create(recursive: true);
      await orphan.writeAsBytes(const [1, 2, 3]);
      expect(CoffeeReadingStore(storage).all(), isEmpty);

      final result =
          await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImagesStrict(storage);
      expect(result.complete, isTrue);
      expect(orphan.existsSync(), isFalse);
    });

    test(
        'corrupt journal is fail-closed when reconciliation cannot finish',
        () async {
      final archived = await seedCoffee();
      expect(File(archived).existsSync(), isTrue);
      await _makeUndeletable(archived);
      final ephemeral = LocalStorage.ephemeral({
        OwnedFileCleanupJournal.key: 'not-a-list',
        CoffeeReadingStore.key: storage.getStringList(CoffeeReadingStore.key)!,
      });

      final result =
          await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImagesStrict(
        ephemeral,
      );
      expect(result.complete, isFalse);
      expect(result.metadataMayBeCleared, isFalse);
      expect(CoffeeReadingStore(ephemeral).all(), isNotEmpty);
      await _makeDeletable(archived);
    });

    test(
        'path_provider ownership unknown → strict wipe incomplete, '
        'path remains retryable via journal or metadata; after recovery '
        'file deletes', () async {
      final archived = await seedCoffee();
      PathProviderPlatform.instance = _ThrowingPathProvider();

      final result =
          await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImagesStrict(storage);
      expect(result.complete, isFalse);
      expect(File(archived).existsSync(), isTrue);

      final wipe = await UserLocalDataWipe.run(storage, secureStorage: secure);
      expect(wipe.isComplete, isFalse);
      final stillLocatable = CoffeeReadingStore(storage).all().isNotEmpty ||
          OwnedFileCleanupJournal.read(storage).contains(archived);
      expect(stillLocatable, isTrue);
      expect(File(archived).existsSync(), isTrue);

      PathProviderPlatform.instance = _TempPathProvider(root.path);
      final recovered =
          await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImagesStrict(storage);
      expect(recovered.complete, isTrue);
      expect(File(archived).existsSync(), isFalse);
    });

    test(
        'external file in profile metadata is NEVER deleted by strict wipe',
        () async {
      final rogue = File(
        '${root.path}${Platform.pathSeparator}not_oracly_photo.jpg',
      );
      await rogue.writeAsBytes(const [1, 2, 3]);
      await storage.setString(ProfilePhotoStore.key, rogue.path);

      final wipe = await UserLocalDataWipe.run(storage, secureStorage: secure);
      expect(wipe.isComplete, isTrue);
      expect(rogue.existsSync(), isTrue);
      expect(storage.getString(ProfilePhotoStore.key), isNull);
    });

    test(
        'external file in soulmate metadata is NEVER deleted by strict wipe',
        () async {
      final rogue = File(
        '${root.path}${Platform.pathSeparator}gallery_soulmate.jpg',
      );
      await rogue.writeAsBytes(const [4, 5, 6]);
      final escapedPath = rogue.path.replaceAll('\\', '\\\\');
      await storage.setString(
        SoulMateResultStore.metaKey,
        '{"id":"x","createdAt":"2026-01-01T00:00:00.000","name":"A",'
        '"birthDate":"1990-01-01T00:00:00.000","intention":"calm",'
        '"portraitPath":"$escapedPath",'
        '"parts":{"energy":"e","attraction":"a","dynamics":"d",'
        '"feeling":"f","yourSide":"y"}}',
      );

      final wipe = await UserLocalDataWipe.run(storage, secureStorage: secure);
      expect(wipe.isComplete, isTrue);
      expect(rogue.existsSync(), isTrue);
      expect(await SoulMateResultStore.readMeta(storage), isNull);
    });
  });
}

Future<void> _makeUndeletable(String path) async {
  if (Platform.isWindows) {
    await Process.run('attrib', ['+R', path]);
  } else {
    await Process.run('chmod', ['0444', path]);
  }
}

Future<void> _makeDeletable(String path) async {
  if (Platform.isWindows) {
    await Process.run('attrib', ['-R', path]);
  } else {
    await Process.run('chmod', ['0644', path]);
  }
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
