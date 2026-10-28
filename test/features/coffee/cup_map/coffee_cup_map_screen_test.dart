/// Fincan Haritası UI on a REAL cup photo: a tap stores the exact normalized
/// point (also while zoomed and panned), the same place is edited instead of
/// duplicated, notes are optional and come back on reopen, photos switch,
/// a missing photo or a map-less / other-owner reading degrades calmly, tap
/// targets and labels meet the guidelines, a 320 px screen at 2x text does
/// not overflow, and the result screen shows the door only when a map
/// exists.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/cup_map/copy/coffee_cup_map_copy.dart';
import 'package:oracly_new/features/coffee/cup_map/models/coffee_cup_map_record.dart';
import 'package:oracly_new/features/coffee/cup_map/presentation/coffee_cup_map_canvas.dart';
import 'package:oracly_new/features/coffee/cup_map/presentation/coffee_cup_map_screen.dart';
import 'package:oracly_new/features/coffee/cup_map/providers/coffee_cup_map_providers.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_consent.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_result_contract.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_result_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/coffee_cup_map_test_support.dart';

const _reading = 'coffee-v3-ui-r1';
const _owner = 'owner-ui';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late LocalStorage storage;
  late CoffeeCupMapStore store;
  late List<CoffeeCupMapPhoto> photos;
  late Size imageSize;

  setUp(() async {
    OraclyL10n.bind('tr');
    temp = await Directory.systemTemp.createTemp('cup_map_ui_');
    await installCupMapPaths(temp);
    storage = await ownedStorage(_owner);
    store = CoffeeCupMapStore(storage);
    final decoded = img.decodeJpg(await File(cupMapFixturePhoto).readAsBytes())!;
    imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
    photos = [
      for (final slot in coffeeV3CanonicalSlotOrder)
        CoffeeCupMapPhoto(
          slot: slot,
          path: await keptCupMapPhoto(_reading, slot),
          sha256: 'fixture',
        ),
    ];
    await store.createIfAbsent(
      ownerId: _owner,
      readingId: _reading,
      photos: photos,
    );
  });

  tearDown(() async {
    imageCache.clear();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  /// Decodes the real photos outside the fake clock so the canvas has them.
  Future<void> precache(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    await tester.runAsync(() async {
      for (final photo in photos) {
        if (File(photo.path).existsSync()) {
          await precacheImage(coffeeCupMapPhotoImage(photo.path), context);
        }
      }
    });
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    CoffeeCupMapStore? using,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await precache(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coffeeCupMapStoreProvider.overrideWithValue(using ?? store),
          coffeeCupMapConsentProvider.overrideWithValue(
            CoffeeCupMapConsent(storage),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: const CoffeeCupMapScreen(readingId: _reading),
        ),
      ),
    );
    // The map reveals itself (~0.6 s); let it finish on the test clock.
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Several frames: a sheet opened after an awaited write animates in.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Rect viewport(WidgetTester tester) =>
      tester.getRect(find.byType(InteractiveViewer));

  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tap(find.text(CoffeeCupMapCopy.noteClose));
    await settle(tester);
  }

  testWidgets('the canvas keeps the real photo aspect ratio', (tester) async {
    await pumpScreen(tester);
    final rect = viewport(tester);
    expect(
      rect.width / rect.height,
      moreOrLessEquals(imageSize.width / imageSize.height, epsilon: 0.01),
    );
  });

  testWidgets('a tap stores the exact point; the note is optional and saved',
      (tester) async {
    await pumpScreen(tester);
    final rect = viewport(tester);
    await tester.tapAt(rect.topLeft + Offset(rect.width * 0.25, rect.height * 0.6));
    await settle(tester);
    expect(find.text(CoffeeCupMapCopy.noteHint), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Sapın altındaki koyu çizgi');
    await tester.tap(find.text(CoffeeCupMapCopy.noteSave));
    await settle(tester);

    final pin = (await store.load(_reading))!.pins.single;
    expect(pin.slot, CoffeeV3PhotoSlot.cupViewA);
    expect(pin.x, moreOrLessEquals(0.25, epsilon: 0.003));
    expect(pin.y, moreOrLessEquals(0.6, epsilon: 0.003));
    expect(pin.note, 'Sapın altındaki koyu çizgi');
    expect(find.text('Sapın altındaki koyu çizgi'), findsOneWidget);
  });

  testWidgets('tapping a marked place again edits it, never duplicates',
      (tester) async {
    await pumpScreen(tester);
    final rect = viewport(tester);
    final at = rect.topLeft + Offset(rect.width * 0.5, rect.height * 0.5);
    await tester.tapAt(at);
    await settle(tester);
    await closeSheet(tester);
    await tester.tapAt(at + const Offset(3, 3));
    await settle(tester);
    expect(find.text(CoffeeCupMapCopy.noteHint), findsOneWidget);
    await closeSheet(tester);
    expect((await store.load(_reading))!.pins, hasLength(1));
  });

  testWidgets('zoomed and panned, a tap still lands on the right image point',
      (tester) async {
    await pumpScreen(tester);
    final rect = viewport(tester);
    final viewer =
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    // 2x, showing the middle of the photo.
    viewer.transformationController!.value = Matrix4.identity()
      ..translateByDouble(-rect.width * 0.5, -rect.height * 0.5, 0, 1)
      ..scaleByDouble(2.0, 2.0, 1, 1);
    await tester.pump();
    await tester.tapAt(
      rect.topLeft + Offset(rect.width * 0.25, rect.height * 0.25),
    );
    await settle(tester);
    await closeSheet(tester);
    final pin = (await store.load(_reading))!.pins.single;
    expect(pin.x, moreOrLessEquals(0.375, epsilon: 0.003));
    expect(pin.y, moreOrLessEquals(0.375, epsilon: 0.003));
    // The marker keeps a 44 px target at 2x.
    final marker = tester.getRect(
      find.descendant(
        of: find.byType(CoffeeCupMapCanvas),
        matching: find.byType(FittedBox),
      ),
    );
    expect(marker.width, moreOrLessEquals(44, epsilon: 0.5));
  });

  testWidgets('"Ortaya işaret koy" marks the visible center', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text(CoffeeCupMapCopy.pinAtCenter));
    await settle(tester);
    await closeSheet(tester);
    final pin = (await store.load(_reading))!.pins.single;
    expect(pin.x, moreOrLessEquals(0.5, epsilon: 0.001));
    expect(pin.y, moreOrLessEquals(0.5, epsilon: 0.001));
  });

  testWidgets('reopening shows the same pins and notes; photos switch',
      (tester) async {
    await store.addPin(
      readingId: _reading,
      slot: CoffeeV3PhotoSlot.saucer,
      x: 0.7,
      y: 0.3,
      note: 'Kenara doğru akan iz',
    );
    await pumpScreen(tester, using: CoffeeCupMapStore(storage));
    expect(find.text(CoffeeCupMapCopy.listEmpty), findsOneWidget);
    // Short visual label; the count is a badge, the full text a label.
    expect(find.text('Tabak'), findsOneWidget);
    expect(find.bySemanticsLabel('Tabak, 1 işaret'), findsOneWidget);

    await tester.tap(find.text('Tabak'));
    // The photos crossfade; afterwards only the saucer's canvas remains.
    await settle(tester);
    expect(find.text('Kenara doğru akan iz'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('İşaret 1, not: Kenara doğru akan iz')),
      findsWidgets,
    );
    final rect = viewport(tester);
    final marker = tester.getCenter(
      find.descendant(
        of: find.byType(CoffeeCupMapCanvas),
        matching: find.byType(FittedBox),
      ),
    );
    expect(marker.dx, moreOrLessEquals(rect.left + rect.width * 0.7, epsilon: 0.5));
    expect(marker.dy, moreOrLessEquals(rect.top + rect.height * 0.3, epsilon: 0.5));
  });

  testWidgets('deleting a pin from its sheet removes it', (tester) async {
    await store.addPin(
      readingId: _reading,
      slot: CoffeeV3PhotoSlot.cupViewA,
      x: 0.2,
      y: 0.2,
    );
    await pumpScreen(tester);
    await tester.ensureVisible(find.text(CoffeeCupMapCopy.noNote));
    await tester.pump();
    await tester.tap(find.text(CoffeeCupMapCopy.noNote));
    await settle(tester);
    await tester.tap(find.text(CoffeeCupMapCopy.noteDelete));
    await settle(tester);
    expect((await store.load(_reading))!.pins, isEmpty);
    expect(find.text(CoffeeCupMapCopy.listEmpty), findsOneWidget);
  });

  testWidgets('deleting this reading\'s map removes photos, pins and notes',
      (tester) async {
    await store.addPin(
      readingId: _reading,
      slot: CoffeeV3PhotoSlot.cupViewB,
      x: 0.3,
      y: 0.3,
      note: 'Silinecek not',
    );
    await pumpScreen(tester);
    await tester.ensureVisible(find.text(CoffeeCupMapCopy.deleteMap));
    await tester.pump();
    await tester.tap(find.text(CoffeeCupMapCopy.deleteMap));
    await settle(tester);
    expect(find.text(CoffeeCupMapCopy.deleteConfirmBody), findsOneWidget);

    // "Vazgeç" deletes nothing.
    await tester.tap(find.text(CoffeeCupMapCopy.deleteCancel));
    await settle(tester);
    expect((await store.load(_reading)), isNotNull);

    await tester.tap(find.text(CoffeeCupMapCopy.deleteMap));
    await settle(tester);
    await tester.tap(find.text(CoffeeCupMapCopy.deleteConfirm));
    await settle(tester);
    expect((await store.load(_reading)), isNull);
    for (final photo in photos) {
      expect(File(photo.path).existsSync(), isFalse);
    }
    expect(cupMapFileText(), isNot(contains('Silinecek')));
  });

  testWidgets('if a photo cannot be deleted the map stays and says so',
      (tester) async {
    await pumpScreen(
      tester,
      using: CoffeeCupMapStore(storage, deletePhoto: (_) async => false),
    );
    await tester.ensureVisible(find.text(CoffeeCupMapCopy.deleteMap));
    await tester.pump();
    await tester.tap(find.text(CoffeeCupMapCopy.deleteMap));
    await settle(tester);
    await tester.tap(find.text(CoffeeCupMapCopy.deleteConfirm));
    await settle(tester);
    expect(find.text(CoffeeCupMapCopy.deleteFailed), findsOneWidget);
    expect(find.byType(CoffeeCupMapScreen), findsOneWidget);
    expect((await store.load(_reading)), isNotNull);
  });

  testWidgets('the keep-photos choice is reachable here and turns off',
      (tester) async {
    await CoffeeCupMapConsent(storage).setKeepPhotos(true);
    await pumpScreen(tester);
    await tester.ensureVisible(find.byType(Switch));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text(CoffeeCupMapCopy.consentFuture), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(CoffeeCupMapConsent(storage).keepPhotos, isFalse);
    // Turning it off never deletes an existing map.
    expect((await store.load(_reading)), isNotNull);
  });

  testWidgets('a photo no longer on the device degrades, pins stay listed',
      (tester) async {
    await store.addPin(
      readingId: _reading,
      slot: CoffeeV3PhotoSlot.cupViewA,
      x: 0.4,
      y: 0.4,
      note: 'Silinmeden önceki notum',
    );
    // Sync: real async IO never completes inside the widget-test clock.
    File(photos.first.path).deleteSync();
    await pumpScreen(tester);
    expect(find.text(CoffeeCupMapCopy.photoMissing), findsOneWidget);
    expect(find.text('Silinmeden önceki notum'), findsOneWidget);
    // Nothing to mark on a photo that is gone; the tab says so.
    expect(find.text(CoffeeCupMapCopy.pinAtCenter), findsNothing);
    expect(find.text(CoffeeCupMapCopy.gestureHint), findsNothing);
    expect(
      find.bySemanticsLabel('Fincan 1, fotoğraf cihazda yok, 1 işaret'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('no map, or another owner: a calm explanation, no photo',
      (tester) async {
    await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-other');
    await pumpScreen(tester, using: CoffeeCupMapStore(storage));
    expect(find.text(CoffeeCupMapCopy.mapUnavailable), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('tap targets and labels meet the guidelines', (tester) async {
    final semantics = tester.ensureSemantics();
    await store.addPin(
      readingId: _reading,
      slot: CoffeeV3PhotoSlot.cupViewA,
      x: 0.5,
      y: 0.5,
    );
    await pumpScreen(tester);
    // The shared OraclyAppBar back control is the app-wide 44 px; every
    // control this screen adds is ≥ 44 (markers) or ≥ 48 (tabs, rows).
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(
      find.bySemanticsLabel(RegExp('Fincan 1 fotoğrafı, 1 işaret')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('320 px wide at 2x text: no overflow, still usable',
      (tester) async {
    await pumpScreen(tester, size: const Size(320, 568), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(CoffeeCupMapCopy.listEmpty),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('one short line on the map; the full explanation is one tap '
      'away in help', (tester) async {
    await pumpScreen(tester);
    expect(find.text(CoffeeCupMapCopy.intro), findsOneWidget);
    expect(find.text(CoffeeCupMapCopy.helpBody), findsNothing);
    await tester.tap(find.byTooltip(CoffeeCupMapCopy.helpOpen));
    await settle(tester);
    expect(find.text(CoffeeCupMapCopy.helpBody), findsOneWidget);
    expect(CoffeeCupMapCopy.helpBody, contains('ORACLY fotoğrafa sembol yerleştirmez'));
    await tester.tap(find.text(CoffeeCupMapCopy.helpClose));
    await settle(tester);
    expect(find.text(CoffeeCupMapCopy.helpBody), findsNothing);
  });

  for (final width in [320.0, 360.0, 390.0]) {
    testWidgets('${width.toInt()} px at 2x text: strip labels stay one line, '
        'counts are badges, nothing overflows', (tester) async {
      await store.addPin(
        readingId: _reading,
        slot: CoffeeV3PhotoSlot.saucer,
        x: 0.5,
        y: 0.5,
      );
      await pumpScreen(tester, size: Size(width, 640), textScale: 2);
      expect(tester.takeException(), isNull);
      for (final label in ['Fincan 1', 'Fincan 2', 'Tabak']) {
        final text = find.text(label);
        expect(text, findsOneWidget);
        // One line, drawn inside its third of the strip.
        expect(tester.renderObject<RenderParagraph>(text).didExceedMaxLines, isFalse);
        expect(tester.getRect(text).width, lessThanOrEqualTo(width / 3));
      }
      expect(find.bySemanticsLabel('Tabak, 1 işaret'), findsOneWidget);
    });
  }

  group('result screen door', () {
    CoffeeReading v3Reading(String id) => CoffeeReading(
          id: id,
          createdAt: DateTime.utc(2026, 10, 27, 12),
          coffeeResultContract: coffeeV3NarrativeV1ResultContract,
          overall: 'Fincanda bir konu ön plana çıkabilir.',
          love: '',
          career: '',
          money: '',
          nearFuture: '',
          takeaway: '',
          visualObservation: '',
          symbols: const [],
        );

    Future<void> pumpResult(WidgetTester tester, String id) async {
      await tester.binding.setSurfaceSize(const Size(390, 3200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await precache(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(LocalStorage(prefs)),
            coffeeCupMapStoreProvider.overrideWithValue(store),
            coffeeCupMapConsentProvider.overrideWithValue(
              CoffeeCupMapConsent(storage),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CoffeeResultView(reading: v3Reading(id), onNewCup: () {}),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      // The door unfolds into the result once its photos are known.
      await settle(tester);
    }

    testWidgets('a reading with a map shows the door and opens the map',
        (tester) async {
      await pumpResult(tester, _reading);
      expect(find.text(CoffeeCupMapCopy.entryOpen), findsOneWidget);
      expect(find.text(CoffeeCupMapCopy.entryCount(0)), findsOneWidget);
      await tester.ensureVisible(find.text(CoffeeCupMapCopy.entryOpen));
      await tester.pump();
      await tester.tap(find.text(CoffeeCupMapCopy.entryOpen));
      await settle(tester);
      expect(find.byType(CoffeeCupMapScreen), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('a reading without a map (V2, older V3) shows nothing new',
        (tester) async {
      await pumpResult(tester, 'coffee-v2-older');
      expect(find.text(CoffeeCupMapCopy.title), findsNothing);
      expect(find.text(CoffeeCupMapCopy.entryOpen), findsNothing);
    });
  });
}
