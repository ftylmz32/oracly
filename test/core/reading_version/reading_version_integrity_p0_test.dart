/// P0-3 — version store durability, missing baseline, semantic fingerprints.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading_version/models/reading_version_kind.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_fingerprint.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_payload.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_service.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_analysis_port.dart';
import 'package:oracly_new/features/palm/services/palm_experience_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/false_return_local_storage.dart';
import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late FalseReturnLocalStorage storage;
  late String fixturePath;

  setUp(() async {
    root = await installTestPathProvider('ver-integrity-');
    SharedPreferences.setMockInitialValues({});
    storage = FalseReturnLocalStorage(await SharedPreferences.getInstance());
    fixturePath = '${root.path}/cup.jpg';
    await File('test/features/palm/fixtures/palm_sample.jpg').copy(fixturePath);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  group('3A — ReadingVersionStore.save requires durable success', () {
    test('false write — append does NOT report added=true', () async {
      final versions = ReadingVersionService(ReadingVersionStore(storage));
      await versions.seedOriginal(
        rootId: 'r1',
        kind: ReadingVersionKind.coffee,
        data: {'overall': 'a'},
      );
      storage.falseReturnKeys.add(ReadingVersionStore.key);
      await expectLater(
        versions.tryAppendRevision(
          rootId: 'r1',
          kind: ReadingVersionKind.coffee,
          data: {'overall': 'b'},
        ),
        throwsA(isA<StateError>()),
      );
      storage.falseReturnKeys.clear();
      expect(versions.groupFor('r1')!.entries, hasLength(1));

      final retry = await versions.tryAppendRevision(
        rootId: 'r1',
        kind: ReadingVersionKind.coffee,
        data: {'overall': 'b'},
      );
      expect(retry.added, isTrue);
      expect(retry.group.entries, hasLength(2));
    });

    test('throw on write — append does NOT report added=true', () async {
      final versions = ReadingVersionService(ReadingVersionStore(storage));
      await versions.seedOriginal(
        rootId: 'r2',
        kind: ReadingVersionKind.palm,
        data: {'overall': 'a'},
      );
      storage.throwingKeys.add(ReadingVersionStore.key);
      await expectLater(
        versions.tryAppendRevision(
          rootId: 'r2',
          kind: ReadingVersionKind.palm,
          data: {'overall': 'b'},
        ),
        throwsA(isA<StateError>()),
      );
      storage.throwingKeys.clear();
      expect(versions.groupFor('r2')!.entries, hasLength(1));
    });
  });

  group('3B — missing version group seeds Original from pre-reinterpret', () {
    test('Coffee: Original = old, Revision 2 = new', () async {
      final store = CoffeeReadingStore(storage);
      final versions = ReadingVersionService(ReadingVersionStore(storage));
      final current = CoffeeReading(
        id: 'c-legacy',
        createdAt: DateTime.utc(2026, 1, 1),
        imagePath: fixturePath,
        overall: 'old-o',
        love: 'old-l',
        career: 'old-c',
        money: 'old-m',
        nearFuture: 'old-n',
        takeaway: 'old-t',
        visualObservation: 'old-v',
        symbols: const [
          CoffeeSymbol(name: 'bird', meaning: 'm', interpretation: 'i'),
        ],
      );
      await store.save(current);
      expect(versions.groupFor(current.id), isNull);

      final svc = CoffeeExperienceService(
        store: store,
        analysis: _CoffeeNew(),
        versions: versions,
        persistImage: ({required readingId, required sourcePath}) async =>
            sourcePath,
      );
      final result = await svc.reinterpret(
        current: current,
        image: CoffeeImagePick(path: fixturePath),
      );

      expect(result.reading.overall, 'new-o');
      expect(store.byId('c-legacy')!.overall, 'new-o');
      expect(result.versionAdded, isTrue);
      final group = versions.groupFor(current.id)!;
      expect(group.entries, hasLength(2));
      expect(group.entries.first.data['overall'], 'old-o');
      expect(group.entries.last.data['overall'], 'new-o');
      expect(group.activeNumber, 2);
    });

    test('Palm: Original = old, Revision 2 = new', () async {
      final store = PalmReadingStore(storage);
      final versions = ReadingVersionService(ReadingVersionStore(storage));
      final current = PalmReading(
        id: 'p-legacy',
        createdAt: DateTime.utc(2026, 1, 1),
        hand: PalmHand.right,
        imagePath: fixturePath,
        overall: 'old-o',
        lifeLine: 'old-l',
        headLine: 'old-h',
        heartLine: 'old-he',
        fateLine: 'old-f',
        takeaway: 'old-t',
        symbols: const ['moon'],
        themes: const ['quiet'],
      );
      await store.save(current);
      expect(versions.groupFor(current.id), isNull);

      final svc = PalmExperienceService(
        store: store,
        analysis: _PalmNew(),
        versions: versions,
        persistImage: ({required readingId, required sourcePath}) async =>
            sourcePath,
      );
      final result = await svc.reinterpret(
        current: current,
        image: CoffeeImagePick(path: fixturePath),
        hand: PalmHand.right,
      );

      expect(result.reading.overall, 'new-o');
      expect(store.byId('p-legacy')!.overall, 'new-o');
      expect(result.versionAdded, isTrue);
      final group = versions.groupFor(current.id)!;
      expect(group.entries, hasLength(2));
      expect(group.entries.first.data['overall'], 'old-o');
      expect(group.entries.last.data['overall'], 'new-o');
      expect(group.activeNumber, 2);
    });
  });

  group('3C — semantic fingerprint completeness', () {
    test('Coffee: only takeaway / visualObservation / symbol change = distinct',
        () async {
      final base = CoffeeReading(
        id: 'c-fp',
        createdAt: DateTime.utc(2026, 1, 1),
        overall: 'o',
        love: 'l',
        career: 'c',
        money: 'm',
        nearFuture: 'n',
        takeaway: 't',
        visualObservation: 'v',
        symbols: const [
          CoffeeSymbol(name: 'bird', meaning: 'fly', interpretation: 'hope'),
        ],
      );
      final baseFp = ReadingVersionFingerprint.of(
        ReadingVersionPayload.coffee(base),
        ReadingVersionKind.coffee,
      );

      expect(
        ReadingVersionFingerprint.of(
          ReadingVersionPayload.coffee(base.copyWith(takeaway: 't2')),
          ReadingVersionKind.coffee,
        ),
        isNot(baseFp),
      );
      expect(
        ReadingVersionFingerprint.of(
          ReadingVersionPayload.coffee(
            base.copyWith(visualObservation: 'v2'),
          ),
          ReadingVersionKind.coffee,
        ),
        isNot(baseFp),
      );
      expect(
        ReadingVersionFingerprint.of(
          ReadingVersionPayload.coffee(
            base.copyWith(
              symbols: const [
                CoffeeSymbol(
                  name: 'bird',
                  meaning: 'fly',
                  interpretation: 'changed',
                ),
              ],
            ),
          ),
          ReadingVersionKind.coffee,
        ),
        isNot(baseFp),
      );
      expect(
        ReadingVersionFingerprint.of(
          ReadingVersionPayload.coffee(base.copyWith(takeaway: '  T  ')),
          ReadingVersionKind.coffee,
        ),
        baseFp,
        reason: 'whitespace/case-only remains duplicate after normalize',
      );
    });

    test('Palm: only takeaway / themes / symbols change = distinct', () async {
      final base = PalmReading(
        id: 'p-fp',
        createdAt: DateTime.utc(2026, 1, 1),
        hand: PalmHand.left,
        overall: 'o',
        lifeLine: 'l',
        headLine: 'h',
        heartLine: 'he',
        fateLine: 'f',
        takeaway: 't',
        symbols: const ['star'],
        themes: const ['calm'],
      );
      final baseFp = ReadingVersionFingerprint.of(
        ReadingVersionPayload.palm(base),
        ReadingVersionKind.palm,
      );

      expect(
        ReadingVersionFingerprint.of(
          ReadingVersionPayload.palm(base.copyWith(takeaway: 't2')),
          ReadingVersionKind.palm,
        ),
        isNot(baseFp),
      );
      expect(
        ReadingVersionFingerprint.of(
          ReadingVersionPayload.palm(base.copyWith(themes: const ['growth'])),
          ReadingVersionKind.palm,
        ),
        isNot(baseFp),
      );
      expect(
        ReadingVersionFingerprint.of(
          ReadingVersionPayload.palm(
            base.copyWith(symbols: const ['moon']),
          ),
          ReadingVersionKind.palm,
        ),
        isNot(baseFp),
      );
      expect(
        ReadingVersionFingerprint.of(
          ReadingVersionPayload.palm(base.copyWith(takeaway: '  T  ')),
          ReadingVersionKind.palm,
        ),
        baseFp,
      );
    });

    test('Coffee applyCoffee restores symbols when selecting a version', () {
      final base = CoffeeReading(
        id: 'c-apply',
        createdAt: DateTime.utc(2026, 1, 1),
        overall: 'live',
        love: 'l',
        career: 'c',
        money: 'm',
        nearFuture: 'n',
        takeaway: 'live-t',
        visualObservation: 'live-v',
        symbols: const [
          CoffeeSymbol(name: 'live', meaning: 'm', interpretation: 'i'),
        ],
      );
      final restored = ReadingVersionPayload.applyCoffee(base, {
        'overall': 'orig',
        'love': 'l',
        'career': 'c',
        'money': 'm',
        'nearFuture': 'n',
        'takeaway': 'orig-t',
        'visualObservation': 'orig-v',
        'symbols': [
          {
            'name': 'bird',
            'meaning': 'fly',
            'interpretation': 'hope',
            'trust': 'mid',
          },
        ],
      });
      expect(restored.overall, 'orig');
      expect(restored.takeaway, 'orig-t');
      expect(restored.visualObservation, 'orig-v');
      expect(restored.symbols.single.name, 'bird');
      expect(restored.symbols.single.interpretation, 'hope');
    });

    test('Palm applyPalm restores themes/symbols when selecting a version', () {
      final base = PalmReading(
        id: 'p-apply',
        createdAt: DateTime.utc(2026, 1, 1),
        hand: PalmHand.left,
        overall: 'live',
        takeaway: 'live-t',
        symbols: const ['live'],
        themes: const ['live-theme'],
      );
      final restored = ReadingVersionPayload.applyPalm(base, {
        'overall': 'orig',
        'lifeLine': 'l',
        'headLine': 'h',
        'heartLine': 'he',
        'fateLine': 'f',
        'takeaway': 'orig-t',
        'symbols': ['moon', 'star'],
        'themes': ['quiet', 'depth'],
      });
      expect(restored.overall, 'orig');
      expect(restored.takeaway, 'orig-t');
      expect(restored.symbols, ['moon', 'star']);
      expect(restored.themes, ['quiet', 'depth']);
    });
  });
}

class _CoffeeNew implements CoffeeAnalysisPort {
  @override
  bool get isAvailable => true;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async => CoffeeReading(
        id: 'c-legacy',
        createdAt: DateTime.utc(2026, 1, 1),
        imagePath: image.path,
        overall: 'new-o',
        love: 'new-l',
        career: 'new-c',
        money: 'new-m',
        nearFuture: 'new-n',
        takeaway: 'new-t',
        visualObservation: 'new-v',
      );
}

class _PalmNew implements PalmAnalysisPort {
  @override
  bool get isAvailable => true;

  @override
  Future<PalmReading> analyze(
    CoffeeImagePick image, {
    required PalmHand hand,
  }) async =>
      PalmReading(
        id: 'p-legacy',
        createdAt: DateTime.utc(2026, 1, 1),
        hand: hand,
        imagePath: image.path,
        overall: 'new-o',
        lifeLine: 'new-l',
        headLine: 'new-h',
        heartLine: 'new-he',
        fateLine: 'new-f',
        takeaway: 'new-t',
        symbols: const ['sun'],
        themes: const ['growth'],
      );
}
