/// Renders the real Fincan Haritası widgets (door card, map with pins, a
/// zoomed photo, the note sheet, a 320 px screen) with real fonts and real
/// photos, and — only when CUP_MAP_CAPTURE_DIR is set — writes PNGs there.
/// CUP_MAP_PHOTO_DIR may point at a folder holding v3_cup_view_a.jpg,
/// v3_cup_view_b.jpg and v3_saucer_view.jpg; otherwise the repo cup fixture
/// is used for all three. Pins and notes are placed by this harness (as a
/// user would); nothing here is model output.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/cup_map/copy/coffee_cup_map_copy.dart';
import 'package:oracly_new/features/coffee/cup_map/models/coffee_cup_map_record.dart';
import 'package:oracly_new/features/coffee/cup_map/presentation/coffee_cup_map_entry.dart';
import 'package:oracly_new/features/coffee/cup_map/presentation/coffee_cup_map_screen.dart';
import 'package:oracly_new/features/coffee/cup_map/providers/coffee_cup_map_providers.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_store.dart';
import 'package:oracly_new/features/coffee/cup_map/presentation/coffee_cup_map_consent_tile.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_consent.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_photo_archive.dart';

import '../support/coffee_cup_map_test_support.dart';

final _captureDir = Platform.environment['CUP_MAP_CAPTURE_DIR'];
final _photoDir = Platform.environment['CUP_MAP_PHOTO_DIR'];
final _boundary = GlobalKey();
const _reading = 'coffee-v3-capture';

Future<void> _loadFonts() async {
  final sdk = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  final material = '${sdk.path}/artifacts/material_fonts';
  Future<ByteData> read(String path) async =>
      ByteData.view(File(path).readAsBytesSync().buffer);
  final roboto = FontLoader('Roboto');
  for (final f in ['roboto-regular', 'roboto-medium', 'roboto-bold']) {
    final path = '$material/$f.ttf';
    if (File(path).existsSync()) roboto.addFont(read(path));
  }
  roboto.addFont(read('test/fonts/Roboto-Regular.ttf'));
  await roboto.load();
  // Typography defaults chosen by the host platform (Windows: Segoe UI;
  // Apple: SF) — served by Roboto so dialogs don't render as test boxes.
  for (final family in ['Segoe UI', '.SF UI Text', '.SF UI Display']) {
    await (FontLoader(family)..addFont(read('test/fonts/Roboto-Regular.ttf')))
        .load();
  }
  final iconsPath = '$material/materialicons-regular.otf';
  if (File(iconsPath).existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(read(iconsPath))).load();
  }
}

ThemeData _darkRoboto() {
  final base = AppTheme.dark;
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Roboto'),
    // The app's dialog theme carries its own text styles (system font on a
    // device); give them the loaded test font too.
    dialogTheme: base.dialogTheme.copyWith(
      titleTextStyle: (base.dialogTheme.titleTextStyle ?? const TextStyle())
          .copyWith(fontFamily: 'Roboto'),
      contentTextStyle: (base.dialogTheme.contentTextStyle ?? const TextStyle())
          .copyWith(fontFamily: 'Roboto'),
    ),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  final dir = _captureDir;
  if (dir == null) return;
  await tester.runAsync(() async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(dir).createSync(recursive: true);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

String _sourceFor(CoffeeV3PhotoSlot slot) {
  final dir = _photoDir;
  if (dir != null) {
    final path = '$dir/${slot.wireValue}.jpg';
    if (File(path).existsSync()) return path;
  }
  return cupMapFixturePhoto;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late LocalStorage storage;
  late CoffeeCupMapStore store;
  late List<CoffeeCupMapPhoto> photos;

  setUpAll(_loadFonts);

  setUp(() async {
    OraclyL10n.bind('tr');
    temp = await Directory.systemTemp.createTemp('cup_map_capture_');
    await installCupMapPaths(temp);
    storage = await ownedStorage('owner-capture');
    store = CoffeeCupMapStore(storage);
    photos = [
      for (final slot in coffeeV3CanonicalSlotOrder)
        CoffeeCupMapPhoto(
          slot: slot,
          path: await CoffeeCupMapPhotoArchive.persist(
            readingId: '${_reading}_cupmap_${slot.wireValue}',
            sourcePath: _sourceFor(slot),
          ),
          sha256: 'capture',
        ),
    ];
    await store.createIfAbsent(
      ownerId: 'owner-capture',
      readingId: _reading,
      photos: photos,
    );
  });

  tearDown(() async {
    imageCache.clear();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Future<void> precache(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    await tester.runAsync(() async {
      for (final photo in photos) {
        await precacheImage(FileImage(File(photo.path)), context);
        await precacheImage(
          ResizeImage(FileImage(File(photo.path)), width: 240),
          context,
        );
      }
    });
  }

  Future<void> pump(WidgetTester tester, Widget home, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await precache(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coffeeCupMapStoreProvider.overrideWithValue(store),
          coffeeCupMapConsentProvider.overrideWithValue(
            CoffeeCupMapConsent(storage),
          ),
        ],
        child: RepaintBoundary(
          key: _boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _darkRoboto(),
            home: home,
          ),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> addUserPins() async {
    await store.addPin(
      readingId: _reading,
      slot: CoffeeV3PhotoSlot.cupViewA,
      x: 0.36,
      y: 0.42,
      note: 'Sapın karşısındaki koyu kıvrım',
    );
    await store.addPin(
      readingId: _reading,
      slot: CoffeeV3PhotoSlot.cupViewA,
      x: 0.62,
      y: 0.58,
    );
    await store.addPin(
      readingId: _reading,
      slot: CoffeeV3PhotoSlot.saucer,
      x: 0.5,
      y: 0.3,
      note: 'Tabağın kenarına akan ince çizgi',
    );
  }

  testWidgets('door card on the result screen', (tester) async {
    await addUserPins();
    await pump(
      tester,
      const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CoffeeCupMapEntry(readingId: _reading),
          ),
        ),
      ),
      const Size(390, 520),
    );
    expect(find.text(CoffeeCupMapCopy.entryOpen), findsOneWidget);
    expect(find.text(CoffeeCupMapCopy.entryCount(3)), findsOneWidget);
    await _capture(tester, '01_door_card');
  });

  testWidgets('map with the user pins and notes', (tester) async {
    await addUserPins();
    await pump(
      tester,
      const CoffeeCupMapScreen(readingId: _reading),
      const Size(390, 844),
    );
    expect(find.text('Sapın karşısındaki koyu kıvrım'), findsOneWidget);
    await _capture(tester, '02_map_cup_1');

    final viewer =
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    final rect = tester.getRect(find.byType(InteractiveViewer));
    viewer.transformationController!.value = Matrix4.identity()
      ..translateByDouble(-rect.width * 0.55, -rect.height * 0.6, 0, 1)
      ..scaleByDouble(2.5, 2.5, 1, 1);
    await tester.pump();
    await _capture(tester, '03_map_zoomed');

    viewer.transformationController!.value = Matrix4.identity();
    await tester.tap(find.text('Tabak · 1'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await _capture(tester, '04_map_saucer');

    await tester.ensureVisible(find.text('Tabağın kenarına akan ince çizgi'));
    await tester.pump();
    await tester.tap(find.text('Tabağın kenarına akan ince çizgi'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text(CoffeeCupMapCopy.noteSave), findsOneWidget);
    await _capture(tester, '05_note_sheet');
  });

  testWidgets('keep-photos choice as shown before a reading is sent',
      (tester) async {
    await pump(
      tester,
      const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.topCenter,
              child: CoffeeCupMapConsentTile(),
            ),
          ),
        ),
      ),
      const Size(390, 420),
    );
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    await _capture(tester, '07_consent_off');
    await tester.tap(find.byType(Switch));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await _capture(tester, '08_consent_on');
  });

  testWidgets('map footer: choice and per-reading delete', (tester) async {
    await addUserPins();
    await CoffeeCupMapConsent(storage).setKeepPhotos(true);
    await pump(
      tester,
      const CoffeeCupMapScreen(readingId: _reading),
      const Size(390, 844),
    );
    await tester.ensureVisible(find.text(CoffeeCupMapCopy.deleteMap));
    await tester.pump();
    await _capture(tester, '09_map_footer');
    await tester.tap(find.text(CoffeeCupMapCopy.deleteMap));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text(CoffeeCupMapCopy.deleteConfirmBody), findsOneWidget);
    await _capture(tester, '10_delete_confirm');
  });

  testWidgets('320 px screen', (tester) async {
    await addUserPins();
    await pump(
      tester,
      const CoffeeCupMapScreen(readingId: _reading),
      const Size(320, 568),
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, '06_map_320');
  });
}
