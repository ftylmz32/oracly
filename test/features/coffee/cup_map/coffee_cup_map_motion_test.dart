/// Fincan Haritası motion and rendering contract: with reduced motion
/// everything is shown at once (no reveal, no crossfade); a pin the user
/// places settles in while existing pins stay still; the stage is exactly as
/// tall as the photo on show; decoded photos leave memory with the screen.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

import '../../../support/coffee_cup_map_test_support.dart';

const _reading = 'coffee-v3-motion-r1';
const _owner = 'owner-motion';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late LocalStorage storage;
  late CoffeeCupMapStore store;
  late List<CoffeeCupMapPhoto> photos;

  setUp(() async {
    OraclyL10n.bind('tr');
    temp = await Directory.systemTemp.createTemp('cup_map_motion_');
    await installCupMapPaths(temp);
    storage = await ownedStorage(_owner);
    store = CoffeeCupMapStore(storage);
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

  Future<void> pumpScreen(WidgetTester tester, {bool reduced = false}) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    await tester.runAsync(() async {
      for (final photo in photos) {
        await precacheImage(coffeeCupMapPhotoImage(photo.path), context);
      }
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coffeeCupMapStoreProvider.overrideWithValue(store),
          coffeeCupMapConsentProvider.overrideWithValue(
            CoffeeCupMapConsent(storage),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
          home: const CoffeeCupMapScreen(readingId: _reading),
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Product of every FadeTransition above [finder]: what the user sees.
  double visibility(WidgetTester tester, Finder finder) {
    var opacity = 1.0;
    for (final fade in tester.widgetList<FadeTransition>(
      find.ancestor(of: finder, matching: find.byType(FadeTransition)),
    )) {
      opacity *= fade.opacity.value;
    }
    return opacity;
  }

  testWidgets('reduced motion: the map is fully shown at once and photos '
      'switch without a crossfade', (tester) async {
    await pumpScreen(tester, reduced: true);
    await tester.pump();
    await tester.pump();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(visibility(tester, find.byType(InteractiveViewer)), 1);
    expect(visibility(tester, find.text(CoffeeCupMapCopy.listTitle)), 1);

    await tester.tap(find.text(CoffeeCupMapCopy.photoLabel(CoffeeV3PhotoSlot.saucer)));
    await tester.pump();
    await tester.pump();
    expect(find.byType(InteractiveViewer), findsOneWidget,
        reason: 'no outgoing photo lingers');
  });

  testWidgets('with motion: the map reveals over a fraction of a second',
      (tester) async {
    await pumpScreen(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final early = visibility(tester, find.text(CoffeeCupMapCopy.listTitle));
    expect(early, lessThan(1));
    await settle(tester);
    expect(visibility(tester, find.text(CoffeeCupMapCopy.listTitle)), 1);
  });

  testWidgets('a new pin settles in; pins already there never move',
      (tester) async {
    await store.addPin(
      readingId: _reading,
      slot: CoffeeV3PhotoSlot.cupViewA,
      x: 0.2,
      y: 0.2,
    );
    await pumpScreen(tester);
    await settle(tester);
    final existing = (await store.load(_reading))!.pins.single;
    // The number inside a marker sits below every fade the marker has.
    Finder numberOf(String pinId) => find.descendant(
          of: find.byKey(ValueKey(pinId)),
          matching: find.byType(Text),
        );
    final existingMarker = numberOf(existing.id);
    expect(visibility(tester, existingMarker), 1);

    final rect = tester.getRect(find.byType(InteractiveViewer));
    await tester.tapAt(rect.topLeft + Offset(rect.width * 0.7, rect.height * 0.7));
    await tester.pump();
    await tester.pump();
    final added = (await store.load(_reading))!.pins.last;
    final marker = numberOf(added.id);
    await tester.pump(const Duration(milliseconds: 60));
    expect(visibility(tester, marker), lessThan(1), reason: 'still settling');
    expect(visibility(tester, existingMarker), 1, reason: 'never re-animates');
    await settle(tester);
    expect(visibility(tester, marker), 1);
    // The 44 px target holds after the animation.
    expect(
      tester
          .getSize(find.descendant(
            of: find.byKey(ValueKey(added.id)),
            matching: find.byType(FittedBox),
          ))
          .width,
      moreOrLessEquals(44, epsilon: 0.5),
    );
  });

  testWidgets('the stage is exactly as tall as the photo on show',
      (tester) async {
    await pumpScreen(tester);
    await settle(tester);
    final viewer = tester.getRect(find.byType(InteractiveViewer));
    final stage = tester.getRect(
      find.ancestor(
        of: find.byType(InteractiveViewer),
        matching: find.byType(AnimatedContainer),
      ).first,
    );
    expect(stage.height, moreOrLessEquals(viewer.height, epsilon: 0.5),
        reason: 'no empty bands above or below the photo');
    expect(viewer.width / viewer.height, moreOrLessEquals(1, epsilon: 0.01));
  });

  testWidgets('decoded photos leave the image cache with the screen',
      (tester) async {
    await pumpScreen(tester);
    await settle(tester);
    final keys = [
      for (final photo in photos)
        await coffeeCupMapPhotoImage(photo.path)
            .obtainKey(ImageConfiguration.empty),
    ];
    expect(keys.any(imageCache.containsKey), isTrue);
    await tester.pumpWidget(const SizedBox());
    for (final key in keys) {
      expect(imageCache.containsKey(key), isFalse);
    }
  });
}
