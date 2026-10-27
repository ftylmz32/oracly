/// Fincan Haritası end to end through the REAL Coffee V3 screens, providers
/// and controllers with the shared fake backend (zero provider / network /
/// purchase calls): the keep-photos choice is made on the real review
/// screen, a real create → three stages → server completion restores the
/// reading, and the result screen's door opens the map of exactly those
/// photos; deleting the map removes it and its photos; without the choice
/// the reading completes exactly as before and no door appears.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_intention.dart';
import 'package:oracly_new/features/coffee/coffee_v3/copy/coffee_v3_copy.dart';
import 'package:oracly_new/features/coffee/coffee_v3/presentation/coffee_v3_flow_screen.dart';
import 'package:oracly_new/features/coffee/coffee_v3/providers/coffee_v3_providers.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_store.dart';
import 'package:oracly_new/features/coffee/cup_map/copy/coffee_cup_map_copy.dart';
import 'package:oracly_new/features/coffee/cup_map/presentation/coffee_cup_map_screen.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_consent.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_result_view.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/coffee/services/openai_coffee_analysis.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/coffee_cup_map_test_support.dart';
import '../../../support/coffee_v3_test_support.dart';
import '../../../support/fake_reading_operation_backend.dart';

const _owner = 'cup-map-flow-owner';
// SYNTHETIC narrative (never product copy, never a real reading).
const _overall = 'Fincanda bir konu ön plana çıkabilir; kesin olacak gibi değil.';

/// Only what this flow needs: V3 working copies (support) and kept photos
/// (cache). Like the V3 screen test, every other location stays unbound.
class _SupportAndCache extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _SupportAndCache(this.root);
  final String root;
  @override
  Future<String?> getApplicationSupportPath() async => root;
  @override
  Future<String?> getApplicationCachePath() async => '$root/cache';
}

class _Images implements CoffeeImageInputPort {
  String? nextPath;
  @override
  bool get cameraAvailable => true;
  @override
  bool get galleryAvailable => true;
  @override
  Future<CoffeeImagePick?> pickFromCamera() => pickFromGallery();
  @override
  Future<CoffeeImagePick?> pickFromGallery() async {
    final p = nextPath;
    nextPath = null;
    return p == null ? null : CoffeeImagePick(path: p, mimeType: 'image/jpeg');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late LocalStorage storage;
  late CoffeeV3TestTransport transport;
  late _Images images;

  setUp(() async {
    OraclyL10n.bind('tr');
    FeatureFlagRuntime.refreshFromRemote({'coffee_v3_three_view': true});
    temp = await Directory.systemTemp.createTemp('cup_map_flow_');
    PathProviderPlatform.instance = _SupportAndCache(temp.path);
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorage.open();
    await storage.setString(UserLocalDataIsolation.ownerKey, _owner);
    transport = CoffeeV3TestTransport(
      FakeReadingOperationBackend(immediatelyEligible: false),
    );
    images = _Images();
  });

  tearDown(() async {
    FeatureFlagRuntime.refreshFromRemote(ProductFeatureFlags.defaults());
    imageCache.clear();
    try {
      if (await temp.exists()) await temp.delete(recursive: true);
    } on FileSystemException {
      // Windows may still hold decoded image files; the temp dir is fine.
    }
  });

  Widget app() => ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          coffeeV3SubmissionStoreProvider.overrideWithValue(
            CoffeeV3SubmissionStore(storage, ownerId: _owner, requireOwner: true),
          ),
          readingOperationSenderProvider.overrideWithValue(transport.send),
          coffeeImageInputProvider.overrideWithValue(images),
          coffeeAnalysisProvider.overrideWithValue(
            OpenAiCoffeeAnalysis(ai: NoProviderAi()),
          ),
        ],
        child: const MaterialApp(
          home: CoffeeV3FlowScreen(bypassPaidEntryForTest: true),
        ),
      );

  Future<void> drain(WidgetTester tester, {int iterations = 20}) async {
    await tester.runAsync(() async {
      for (var i = 0; i < iterations; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        await tester.pump();
      }
    });
  }

  Future<void> tapAndDrain(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.runAsync(() async {
      await tester.tap(finder);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        await tester.pump();
      }
    });
  }

  /// Advances the fake clock so route / sheet / dialog animations finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Captures three distinct real cup photos and submits; optionally turns
  /// on the keep-photos switch on the review screen first.
  Future<String> captureAndSubmit(
    WidgetTester tester, {
    required bool keepPhotos,
  }) async {
    await tester.binding.setSurfaceSize(const Size(430, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app());
    await drain(tester);
    await tapAndDrain(tester, find.text(CoffeeV3Copy.introCta));
    // Sync: async IO never completes on the widget-test clock.
    final base = File(cupMapFixturePhoto).readAsBytesSync();
    for (var i = 0; i < 3; i++) {
      final path = '${temp.path}/source_$i.jpg';
      await tester.runAsync(
        () => File(path).writeAsBytes(Uint8List.fromList([...base, i + 1])),
      );
      images.nextPath = path;
      await tapAndDrain(tester, find.text(CoffeeV3Copy.actionPickGallery));
      await tapAndDrain(tester, find.text(CoffeeV3Copy.previewUse));
    }
    expect(find.text(CoffeeV3Copy.reviewTitle), findsOneWidget);
    // The choice is visible before sending, and off until the user acts.
    expect(find.text(CoffeeCupMapCopy.consentTitle), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    if (keepPhotos) {
      await tapAndDrain(tester, find.byType(Switch));
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(CoffeeCupMapConsent(storage).keepPhotos, isTrue);
    }
    await tapAndDrain(tester, find.text(CoffeeV2IntentionChoice.general.label));
    await tapAndDrain(tester, find.text(CoffeeV3Copy.reviewCta));
    await drain(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CoffeeV3FlowScreen)),
    );
    return container.read(coffeeV3FlowControllerProvider).operationId!;
  }

  Future<void> completeOnServer(
    WidgetTester tester,
    String operationId,
    String resultId,
  ) async {
    transport.backend.completeServerSide(
      operationId,
      resultId: resultId,
      result: v3NarrativeV1Result(_overall),
    );
    for (var i = 0; i < 12 && find.byType(CoffeeResultView).evaluate().isEmpty; i++) {
      await drain(tester, iterations: 25);
    }
    expect(find.byType(CoffeeResultView), findsOneWidget);
    expect(find.text(_overall), findsWidgets);
  }

  testWidgets('opted in: result door → real photos → pin → reopen → delete',
      (tester) async {
    final opId = await captureAndSubmit(tester, keepPhotos: true);
    // Exactly the locked contract: 2 cup views + 1 saucer.
    expect(transport.stagedSlots,
        ['v3_cup_view_a', 'v3_cup_view_b', 'v3_saucer_view']);
    await completeOnServer(tester, opId, 'coffee-v3-flow-r1');

    final map = CoffeeCupMapStore(storage).load('coffee-v3-flow-r1')!;
    expect(map.photos, hasLength(3));
    // Sync: async IO never completes on the widget-test clock.
    final base = File(cupMapFixturePhoto).readAsBytesSync();
    for (var i = 0; i < 3; i++) {
      expect(
        File(map.photos[i].path).readAsBytesSync(),
        [...base, i + 1],
      );
    }
    await tester.runAsync(() async {
      final context = tester.element(find.byType(CoffeeResultView));
      for (final photo in map.photos) {
        await precacheImage(FileImage(File(photo.path)), context);
      }
    });
    await drain(tester, iterations: 4);
    expect(find.text(CoffeeCupMapCopy.entryOpen), findsOneWidget);

    await tapAndDrain(tester, find.text(CoffeeCupMapCopy.entryOpen));
    expect(find.byType(CoffeeCupMapScreen), findsOneWidget);
    final rect = tester.getRect(find.byType(InteractiveViewer));
    await tester.runAsync(() async {
      await tester.tapAt(rect.center);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        await tester.pump();
      }
    });
    await settle(tester);
    await tester.tap(find.text(CoffeeCupMapCopy.noteClose));
    await settle(tester);
    expect(CoffeeCupMapStore(storage).load('coffee-v3-flow-r1')!.pins, hasLength(1));

    await tester.runAsync(() async {
      Navigator.of(tester.element(find.byType(CoffeeCupMapScreen))).pop();
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        await tester.pump();
      }
    });
    await settle(tester);
    expect(find.text(CoffeeCupMapCopy.entryCount(1)), findsOneWidget);

    await tapAndDrain(tester, find.text(CoffeeCupMapCopy.entryOpen));
    await settle(tester);
    await tapAndDrain(tester, find.text(CoffeeCupMapCopy.deleteMap));
    await settle(tester);
    expect(find.text(CoffeeCupMapCopy.deleteConfirmBody), findsOneWidget);
    await tapAndDrain(tester, find.text(CoffeeCupMapCopy.deleteConfirm));
    await settle(tester);
    expect(find.byType(CoffeeCupMapScreen), findsNothing);
    expect(find.text(CoffeeCupMapCopy.entryOpen), findsNothing);
    expect(CoffeeCupMapStore(storage).load('coffee-v3-flow-r1'), isNull);
    for (final photo in map.photos) {
      expect(File(photo.path).existsSync(), isFalse);
    }
    // The reading itself stays.
    expect(find.text(_overall), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('not opted in: the same reading, no photos kept, no door',
      (tester) async {
    final opId = await captureAndSubmit(tester, keepPhotos: false);
    await completeOnServer(tester, opId, 'coffee-v3-flow-r2');
    expect(storage.getString(CoffeeCupMapStore.key), isNull);
    expect(find.text(CoffeeCupMapCopy.title), findsNothing);
    expect(find.text(CoffeeCupMapCopy.entryOpen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
