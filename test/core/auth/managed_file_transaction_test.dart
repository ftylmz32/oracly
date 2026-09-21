/// Transactional managed-file saves — never destroy prior committed state.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading_version/models/reading_version_kind.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_payload.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_service.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_analysis_port.dart';
import 'package:oracly_new/features/palm/services/palm_experience_service.dart';
import 'package:oracly_new/features/premium/data/soul_mate_interpretation_catalogue.dart';
import 'package:oracly_new/features/premium/data/soul_mate_result_store.dart';
import 'package:oracly_new/features/premium/models/soul_mate_saved_result.dart';
import 'package:oracly_new/screens/profile/data/profile_photo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/false_return_local_storage.dart';
import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late FalseReturnLocalStorage storage;
  late String fixturePath;

  setUp(() async {
    root = await installTestPathProvider('oracly-file-tx-');
    SharedPreferences.setMockInitialValues({});
    storage = FalseReturnLocalStorage(await SharedPreferences.getInstance());
    fixturePath = '${root.path}/cup.jpg';
    await File('test/features/palm/fixtures/palm_sample.jpg').copy(fixturePath);
  });

  group('SoulMate transactional save', () {
    test('same-id meta failure keeps prior portrait bytes', () async {
      final oldBytes = List<int>.generate(32, (i) => i);
      final first = await SoulMateResultStore.save(
        storage: storage,
        record: _soul('soulmate-1'),
        portraitBytes: oldBytes,
        documents: root,
      );
      expect(first, isNotNull);
      final priorPath = first!.portraitPath;
      expect(File(priorPath).readAsBytesSync(), oldBytes);

      storage.falseReturnKeys.add(SoulMateResultStore.metaKey);
      await expectLater(
        SoulMateResultStore.save(
          storage: storage,
          record: _soul('soulmate-1'),
          portraitBytes: List<int>.filled(32, 9),
          documents: root,
        ),
        throwsA(isA<StateError>()),
      );

      final meta = await SoulMateResultStore.readMeta(storage);
      expect(meta!.portraitPath, priorPath);
      expect(File(priorPath).existsSync(), isTrue);
      expect(File(priorPath).readAsBytesSync(), oldBytes);
      final portraits = root
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('oracly_soulmate_portrait_'))
          .toList();
      expect(portraits, hasLength(1));

      storage.falseReturnKeys.clear();
      final second = await SoulMateResultStore.save(
        storage: storage,
        record: _soul('soulmate-1'),
        portraitBytes: List<int>.filled(32, 7),
        documents: root,
      );
      expect(second!.portraitPath, isNot(priorPath));
      expect(File(priorPath).existsSync(), isFalse);
      expect(File(second.portraitPath).readAsBytesSync(), List.filled(32, 7));
    });
  });

  group('Profile transactional save', () {
    test('same-stamp collision never destroys prior on meta failure', () async {
      final srcOld = File('${root.path}/src_old.jpg')
        ..writeAsBytesSync(const [1, 2, 3]);
      final srcNew = File('${root.path}/src_new.jpg')
        ..writeAsBytesSync(const [9, 9, 9]);
      await ProfilePhotoStore.save(
        storage,
        srcOld.path,
        documents: root,
        stamp: 123,
      );
      final prior = storage.getString(ProfilePhotoStore.key)!;
      expect(File(prior).readAsBytesSync(), const [1, 2, 3]);

      storage.falseReturnKeys.add(ProfilePhotoStore.key);
      await expectLater(
        ProfilePhotoStore.save(
          storage,
          srcNew.path,
          documents: root,
          stamp: 123,
        ),
        throwsA(isA<StateError>()),
      );
      expect(storage.getString(ProfilePhotoStore.key), prior);
      expect(File(prior).readAsBytesSync(), const [1, 2, 3]);
    });
  });

  group('Coffee transactional analyze', () {
    test('new reading meta failure leaves no orphan archive', () async {
      storage.falseReturnKeys.add(CoffeeReadingStore.key);
      final svc = CoffeeExperienceService(
        store: CoffeeReadingStore(storage),
        analysis: _FakeCoffeeAnalysis(),
      );
      await expectLater(
        svc.analyze(CoffeeImagePick(path: fixturePath)),
        throwsA(isA<StateError>()),
      );
      expect(CoffeeReadingStore(storage).all(), isEmpty);
      final archive =
          Directory('${root.path}${Platform.pathSeparator}coffee_images');
      if (archive.existsSync()) {
        expect(archive.listSync().whereType<File>(), isEmpty);
      }
    });

    test('same-id replacement meta failure keeps prior archive', () async {
      final store = CoffeeReadingStore(storage);
      final svc = CoffeeExperienceService(
        store: store,
        analysis: _FakeCoffeeAnalysis(id: 'c-1'),
      );
      final first = await svc.analyze(CoffeeImagePick(path: fixturePath));
      final priorPath = first.imagePath!;
      final priorBytes = File(priorPath).readAsBytesSync();

      storage.falseReturnKeys.add(CoffeeReadingStore.key);
      await expectLater(
        svc.analyze(CoffeeImagePick(path: fixturePath)),
        throwsA(isA<StateError>()),
      );
      final kept = store.byId('c-1')!;
      expect(kept.imagePath, priorPath);
      expect(File(priorPath).readAsBytesSync(), priorBytes);

      storage.falseReturnKeys.clear();
      final second = await svc.analyze(CoffeeImagePick(path: fixturePath));
      expect(second.imagePath, isNot(priorPath));
      expect(File(priorPath).existsSync(), isFalse);
      expect(store.all(), hasLength(1));
    });
  });

  group('Palm transactional analyze', () {
    test('new reading meta failure leaves no orphan archive', () async {
      storage.falseReturnKeys.add(PalmReadingStore.key);
      final svc = PalmExperienceService(
        analysis: _FakePalmAnalysis(),
        store: PalmReadingStore(storage),
      );
      await expectLater(
        svc.analyze(CoffeeImagePick(path: fixturePath), hand: PalmHand.left),
        throwsA(isA<StateError>()),
      );
      expect(PalmReadingStore(storage).all(), isEmpty);
      final archive =
          Directory('${root.path}${Platform.pathSeparator}palm_images');
      if (archive.existsSync()) {
        expect(archive.listSync().whereType<File>(), isEmpty);
      }
    });

    test('same-id replacement meta failure keeps prior archive', () async {
      final store = PalmReadingStore(storage);
      final svc = PalmExperienceService(
        analysis: _FakePalmAnalysis(id: 'p-1'),
        store: store,
      );
      final first = await svc.analyze(
        CoffeeImagePick(path: fixturePath),
        hand: PalmHand.right,
      );
      final priorPath = first.imagePath!;
      storage.falseReturnKeys.add(PalmReadingStore.key);
      await expectLater(
        svc.analyze(CoffeeImagePick(path: fixturePath), hand: PalmHand.right),
        throwsA(isA<StateError>()),
      );
      expect(store.byId('p-1')!.imagePath, priorPath);
      expect(File(priorPath).existsSync(), isTrue);

      storage.falseReturnKeys.clear();
      final second = await svc.analyze(
        CoffeeImagePick(path: fixturePath),
        hand: PalmHand.right,
      );
      expect(second.imagePath, isNot(priorPath));
      expect(File(priorPath).existsSync(), isFalse);
    });
  });

  group('P0-4: Coffee staged/restore — version failure never denies a durable reading', () {
    test('analyzeStaged: version seed throws — reading still returns, history has exactly one entry', () async {
      final store = CoffeeReadingStore(storage);
      final versions = ReadingVersionService(ReadingVersionStore(storage));
      storage.throwingKeys.add(ReadingVersionStore.key);
      final svc = CoffeeExperienceService(
        store: store,
        analysis: _FakeStagedCoffeeAnalysis(id: 'staged-1'),
        versions: versions,
      );

      final reading = await svc.analyzeStaged(
        operationId: 'op-1',
        mimeType: 'image/jpeg',
      );

      expect(reading.id, 'staged-1');
      expect(store.all(), hasLength(1));
      expect(store.byId('staged-1'), isNotNull);
    });

    test('restoreCompleted: version seed throws — reading still returns durably', () async {
      final store = CoffeeReadingStore(storage);
      final versions = ReadingVersionService(ReadingVersionStore(storage));
      storage.throwingKeys.add(ReadingVersionStore.key);
      final svc = CoffeeExperienceService(
        store: store,
        analysis: _FakeStagedCoffeeAnalysis(id: 'restored-1'),
        versions: versions,
      );

      final reading = await svc.restoreCompleted(
        resultId: 'restored-1',
        persistedAt: DateTime.utc(2026, 1, 1),
        result: const {},
      );

      expect(reading.id, 'restored-1');
      expect(store.all(), hasLength(1));
    });
  });

  group('P0-4: Coffee reinterpret — metadata-first commit boundary', () {
    test(
        'current.imagePath null + metadata save fails — the new candidate '
        'is deleted, current reading is unchanged', () async {
      final store = CoffeeReadingStore(storage);
      final current = CoffeeReading(
        id: 'c-noimg',
        createdAt: DateTime.utc(2026, 1, 1),
        overall: 'old-o',
        love: 'old-l',
        career: 'old-c',
        money: 'old-m',
        nearFuture: 'old-n',
        takeaway: 'old-t',
      );
      await store.save(current);

      storage.falseReturnKeys.add(CoffeeReadingStore.key);
      final svc = CoffeeExperienceService(
        store: store,
        analysis: _FakeCoffeeAnalysis(id: 'c-noimg'),
      );

      await expectLater(
        svc.reinterpret(
          current: current,
          image: CoffeeImagePick(path: fixturePath),
        ),
        throwsA(isA<StateError>()),
      );

      final archive =
          Directory('${root.path}${Platform.pathSeparator}coffee_images');
      if (archive.existsSync()) {
        expect(archive.listSync().whereType<File>(), isEmpty);
      }
      storage.falseReturnKeys.clear();
      expect(store.byId('c-noimg')!.overall, 'old-o');
      expect(store.byId('c-noimg')!.imagePath, isNull);
    });

    test(
        'duplicate/no-op reinterpret never creates an image candidate at '
        'all — old reading unchanged, versionAdded false', () async {
      final store = CoffeeReadingStore(storage);
      final versions = ReadingVersionService(ReadingVersionStore(storage));
      final current = CoffeeReading(
        id: 'c-dup',
        createdAt: DateTime.utc(2026, 1, 1),
        overall: 'o',
        love: 'l',
        career: 'c',
        money: 'm',
        nearFuture: 'n',
        takeaway: 't',
      );
      await store.save(current);
      await versions.seedOriginal(
        rootId: 'c-dup',
        kind: ReadingVersionKind.coffee,
        data: ReadingVersionPayload.coffee(current),
      );

      final svc = CoffeeExperienceService(
        store: store,
        // Returns the exact same text as `current` — a genuine duplicate.
        analysis: _FakeCoffeeAnalysis(id: 'c-dup'),
        versions: versions,
      );

      final result = await svc.reinterpret(
        current: current,
        image: CoffeeImagePick(path: fixturePath),
      );

      expect(result.versionAdded, isFalse);
      expect(result.reading, same(current));
      final archive =
          Directory('${root.path}${Platform.pathSeparator}coffee_images');
      expect(
        archive.existsSync(),
        isFalse,
        reason: 'no candidate should ever be created for a duplicate',
      );
    });

    test(
        'version append throwing AFTER a successful metadata save never '
        'turns the durable reading into a failure', () async {
      final store = CoffeeReadingStore(storage);
      final versions = ReadingVersionService(ReadingVersionStore(storage));
      final current = CoffeeReading(
        id: 'c-verfail',
        createdAt: DateTime.utc(2026, 1, 1),
        overall: 'old-o',
        love: 'old-l',
        career: 'old-c',
        money: 'old-m',
        nearFuture: 'old-n',
        takeaway: 'old-t',
      );
      await store.save(current);
      storage.throwingKeys.add(ReadingVersionStore.key);

      final svc = CoffeeExperienceService(
        store: store,
        analysis: _FakeCoffeeAnalysis(id: 'c-verfail'),
        versions: versions,
      );

      final result = await svc.reinterpret(
        current: current,
        image: CoffeeImagePick(path: fixturePath),
      );

      expect(result.versionAdded, isFalse);
      expect(result.reading.overall, 'o');
      expect(store.byId('c-verfail')!.overall, 'o');
    });
  });

  group('P0-4: Palm staged/restore — version failure never denies a durable reading', () {
    test('analyzeStaged: version seed throws — reading still returns, history has exactly one entry', () async {
      final store = PalmReadingStore(storage);
      final versions = ReadingVersionService(ReadingVersionStore(storage));
      storage.throwingKeys.add(ReadingVersionStore.key);
      final svc = PalmExperienceService(
        store: store,
        analysis: _FakeStagedPalmAnalysis(id: 'p-staged-1'),
        versions: versions,
      );

      final reading = await svc.analyzeStaged(
        operationId: 'op-1',
        mimeType: 'image/jpeg',
        hand: PalmHand.left,
      );

      expect(reading.id, 'p-staged-1');
      expect(store.all(), hasLength(1));
    });

    test('restoreCompleted: version seed throws — reading still returns durably', () async {
      final store = PalmReadingStore(storage);
      final versions = ReadingVersionService(ReadingVersionStore(storage));
      storage.throwingKeys.add(ReadingVersionStore.key);
      final svc = PalmExperienceService(
        store: store,
        analysis: _FakeStagedPalmAnalysis(id: 'p-restored-1'),
        versions: versions,
      );

      final reading = await svc.restoreCompleted(
        resultId: 'p-restored-1',
        persistedAt: DateTime.utc(2026, 1, 1),
        hand: PalmHand.right,
        result: const {},
      );

      expect(reading.id, 'p-restored-1');
      expect(store.all(), hasLength(1));
    });
  });

  group('P0-4: Palm reinterpret — metadata-first commit boundary', () {
    test(
        'current.imagePath null + metadata save fails — the new candidate '
        'is deleted, current reading is unchanged', () async {
      final store = PalmReadingStore(storage);
      final current = PalmReading(
        id: 'p-noimg',
        createdAt: DateTime.utc(2026, 1, 1),
        hand: PalmHand.left,
        overall: 'old-o',
        lifeLine: 'old-l',
        headLine: 'old-h',
        heartLine: 'old-he',
        fateLine: 'old-f',
        takeaway: 'old-t',
      );
      await store.save(current);

      storage.falseReturnKeys.add(PalmReadingStore.key);
      final svc = PalmExperienceService(
        store: store,
        analysis: _FakePalmAnalysis(id: 'p-noimg'),
      );

      await expectLater(
        svc.reinterpret(
          current: current,
          image: CoffeeImagePick(path: fixturePath),
          hand: PalmHand.left,
        ),
        throwsA(isA<StateError>()),
      );

      final archive =
          Directory('${root.path}${Platform.pathSeparator}palm_images');
      if (archive.existsSync()) {
        expect(archive.listSync().whereType<File>(), isEmpty);
      }
      storage.falseReturnKeys.clear();
      expect(store.byId('p-noimg')!.overall, 'old-o');
      expect(store.byId('p-noimg')!.imagePath, isNull);
    });

    test(
        'duplicate/no-op reinterpret never creates an image candidate at '
        'all — old reading unchanged, versionAdded false', () async {
      final store = PalmReadingStore(storage);
      final versions = ReadingVersionService(ReadingVersionStore(storage));
      final current = PalmReading(
        id: 'p-dup',
        createdAt: DateTime.utc(2026, 1, 1),
        hand: PalmHand.right,
        overall: 'o',
        lifeLine: 'l',
        headLine: 'd',
        heartLine: 'h',
        takeaway: 't',
      );
      await store.save(current);
      await versions.seedOriginal(
        rootId: 'p-dup',
        kind: ReadingVersionKind.palm,
        data: ReadingVersionPayload.palm(current),
      );

      final svc = PalmExperienceService(
        store: store,
        // Returns the exact same text as `current` — a genuine duplicate.
        analysis: _FakePalmAnalysis(id: 'p-dup'),
        versions: versions,
      );

      final result = await svc.reinterpret(
        current: current,
        image: CoffeeImagePick(path: fixturePath),
        hand: PalmHand.right,
      );

      expect(result.versionAdded, isFalse);
      expect(result.reading, same(current));
      final archive =
          Directory('${root.path}${Platform.pathSeparator}palm_images');
      expect(
        archive.existsSync(),
        isFalse,
        reason: 'no candidate should ever be created for a duplicate',
      );
    });

    test(
        'version append throwing AFTER a successful metadata save never '
        'turns the durable reading into a failure', () async {
      final store = PalmReadingStore(storage);
      final versions = ReadingVersionService(ReadingVersionStore(storage));
      final current = PalmReading(
        id: 'p-verfail',
        createdAt: DateTime.utc(2026, 1, 1),
        hand: PalmHand.right,
        overall: 'old-o',
        lifeLine: 'old-l',
        headLine: 'old-h',
        heartLine: 'old-he',
        fateLine: 'old-f',
        takeaway: 'old-t',
      );
      await store.save(current);
      storage.throwingKeys.add(ReadingVersionStore.key);

      final svc = PalmExperienceService(
        store: store,
        analysis: _FakePalmAnalysis(id: 'p-verfail'),
        versions: versions,
      );

      final result = await svc.reinterpret(
        current: current,
        image: CoffeeImagePick(path: fixturePath),
        hand: PalmHand.right,
      );

      expect(result.versionAdded, isFalse);
      expect(result.reading.overall, 'o');
      expect(store.byId('p-verfail')!.overall, 'o');
    });
  });
}

SoulMateSavedResult _soul(String id) => SoulMateSavedResult(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      name: 'N',
      birthDate: DateTime.utc(2000, 1, 1),
      portraitPath: '',
      parts: const SoulMateReadingParts(
        energy: 'e',
        attraction: 'a',
        dynamics: 'd',
        feeling: 'f',
        yourSide: 'y',
      ),
    );

class _FakeCoffeeAnalysis implements CoffeeAnalysisPort {
  _FakeCoffeeAnalysis({this.id = 'c-new'});
  final String id;
  @override
  bool get isAvailable => true;
  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async => CoffeeReading(
        id: id,
        createdAt: DateTime.utc(2026, 1, 1),
        imagePath: image.path,
        overall: 'o',
        love: 'l',
        career: 'c',
        money: 'm',
        nearFuture: 'n',
        takeaway: 't',
      );
}

class _FakePalmAnalysis implements PalmAnalysisPort {
  _FakePalmAnalysis({this.id = 'p-new'});
  final String id;
  @override
  bool get isAvailable => true;
  @override
  Future<PalmReading> analyze(
    CoffeeImagePick image, {
    required PalmHand hand,
  }) async =>
      PalmReading(
        id: id,
        createdAt: DateTime.utc(2026, 1, 1),
        hand: hand,
        overall: 'o',
        lifeLine: 'l',
        heartLine: 'h',
        headLine: 'd',
        takeaway: 't',
        imagePath: image.path,
      );
}

class _FakeStagedCoffeeAnalysis
    implements
        CoffeeAnalysisPort,
        CoffeeStagedAnalysisPort,
        CoffeeCompletedAnalysisPort {
  _FakeStagedCoffeeAnalysis({this.id = 'c-staged'});
  final String id;

  @override
  bool get isAvailable => true;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async =>
      throw UnsupportedError('not used by this fake');

  @override
  Future<CoffeeReading> analyzeStaged({
    required String operationId,
    required String mimeType,
  }) async =>
      CoffeeReading(
        id: id,
        createdAt: DateTime.utc(2026, 1, 1),
        overall: 'o',
        love: 'l',
        career: 'c',
        money: 'm',
        nearFuture: 'n',
        takeaway: 't',
      );

  @override
  CoffeeReading restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required Map<String, dynamic> result,
  }) =>
      CoffeeReading(
        id: resultId,
        createdAt: persistedAt,
        overall: 'o',
        love: 'l',
        career: 'c',
        money: 'm',
        nearFuture: 'n',
        takeaway: 't',
      );
}

class _FakeStagedPalmAnalysis
    implements PalmAnalysisPort, PalmStagedAnalysisPort, PalmCompletedAnalysisPort {
  _FakeStagedPalmAnalysis({this.id = 'p-staged'});
  final String id;

  @override
  bool get isAvailable => true;

  @override
  Future<PalmReading> analyze(
    CoffeeImagePick image, {
    required PalmHand hand,
  }) async =>
      throw UnsupportedError('not used by this fake');

  @override
  Future<PalmReading> analyzeStaged({
    required String operationId,
    required String mimeType,
    required PalmHand hand,
  }) async =>
      PalmReading(
        id: id,
        createdAt: DateTime.utc(2026, 1, 1),
        hand: hand,
        overall: 'o',
        lifeLine: 'l',
        headLine: 'd',
        heartLine: 'h',
        takeaway: 't',
      );

  @override
  PalmReading restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required PalmHand hand,
    required Map<String, dynamic> result,
  }) =>
      PalmReading(
        id: resultId,
        createdAt: persistedAt,
        hand: hand,
        overall: 'o',
        lifeLine: 'l',
        headLine: 'd',
        heartLine: 'h',
        takeaway: 't',
      );
}
