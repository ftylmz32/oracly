/// Coffee/Palm owned image wipe ? privacy regression tests.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
    if (await root.exists()) await root.delete(recursive: true);
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

    expect(CoffeeReadingStore(storage).all(), isEmpty);
    expect(PalmReadingStore(storage).all(), isEmpty);
    expect(File(coffee).existsSync(), isFalse);
    expect(File(palm).existsSync(), isFalse);
  });

  test('account deletion wipe removes coffee and palm owned files', () async {
    final coffee = await seedCoffee();
    final palm = await seedPalm();

    await UserLocalDataWipe.run(storage, secureStorage: secure);

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
