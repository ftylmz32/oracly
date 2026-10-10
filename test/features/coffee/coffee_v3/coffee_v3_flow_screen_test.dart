/// Coffee V3 four-view UI through the real providers / controllers: locked
/// Turkish copy, four steps (cup guide on cup views only), preview,
/// exactly four review cards, CTA gating (flag off = disabled with the
/// availability note), and a real create → four namespaced stages →
/// observing on the existing loading view.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_intention.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_flow_screen.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_thumbnail.dart';
import 'package:oracly_new/features/coffee/coffee_v3/copy/coffee_v3_copy.dart';
import 'package:oracly_new/features/coffee/coffee_v3/presentation/coffee_v3_flow_screen.dart';
import 'package:oracly_new/features/coffee/coffee_v3/providers/coffee_v3_providers.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_capture_cup_guide.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_loading_view.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/coffee/services/openai_coffee_analysis.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/coffee_v2_test_support.dart';
import '../../../support/coffee_v3_test_support.dart';
import '../../../support/fake_reading_operation_backend.dart';

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
    FeatureFlagRuntime.refreshFromRemote({'coffee_v3_four_view': true});
    temp = await Directory.systemTemp.createTemp('coffee_v3_screen_');
    PathProviderPlatform.instance = FakePathProvider(temp.path);
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorage.open();
    transport = CoffeeV3TestTransport(
      FakeReadingOperationBackend(immediatelyEligible: false),
    );
    images = _Images();
  });

  tearDown(() async {
    FeatureFlagRuntime.refreshFromRemote(ProductFeatureFlags.defaults());
    try {
      if (await temp.exists()) await temp.delete(recursive: true);
    } on FileSystemException {
      // Windows may still hold decoded thumbnail files; temp dir is fine.
    }
  });

  Widget app() => ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          coffeeV3SubmissionStoreProvider.overrideWithValue(
            CoffeeV3SubmissionStore(storage,
                ownerId: 'coffee-v3-widget-owner', requireOwner: true),
          ),
          readingOperationSenderProvider.overrideWithValue(transport.send),
          coffeeImageInputProvider.overrideWithValue(images),
          coffeeAnalysisProvider.overrideWithValue(
            OpenAiCoffeeAnalysis(ai: NoProviderAi()),
          ),
        ],
        child: const MaterialApp(home: CoffeeV3FlowScreen()),
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

  var size = 20000;
  Future<void> pickAndUse(WidgetTester tester, String name) async {
    final path = '${temp.path}/$name.jpg';
    await tester.runAsync(
      () => File(path).writeAsBytes(plainJpegBytes(totalSize: size += 97)),
    );
    images.nextPath = path;
    await tapAndDrain(tester, find.text(CoffeeV3Copy.actionPickGallery));
    expect(find.text(CoffeeV3Copy.previewUse), findsOneWidget);
    await tapAndDrain(tester, find.text(CoffeeV3Copy.previewUse));
  }

  OraclyGoldButton cta(WidgetTester tester) => tester.widget<OraclyGoldButton>(
        find.widgetWithText(OraclyGoldButton, CoffeeV3Copy.reviewCta),
      );

  Future<void> captureToReview(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app());
    await drain(tester);
    expect(find.text(CoffeeV3Copy.introTitle), findsOneWidget);
    expect(find.text(CoffeeV3Copy.introSummaryHandleFar), findsOneWidget);
    expect(find.text(CoffeeV3Copy.introSummarySaucer), findsOneWidget);
    await tapAndDrain(tester, find.text(CoffeeV3Copy.introCta));
    final steps = [
      (CoffeeV3Copy.stepTitleHandleFar, CoffeeV3Copy.stepInstructionHandleFar, true),
      (CoffeeV3Copy.stepTitleTurnA, CoffeeV3Copy.stepInstructionTurnA, true),
      (CoffeeV3Copy.stepTitleTurnB, CoffeeV3Copy.stepInstructionTurnB, true),
      (CoffeeV3Copy.stepTitleSaucer, CoffeeV3Copy.stepInstructionSaucer, false),
    ];
    for (var i = 0; i < 4; i++) {
      expect(find.text('${i + 1} / 4'), findsOneWidget);
      expect(find.text(steps[i].$1), findsOneWidget);
      expect(find.text(steps[i].$2), findsOneWidget);
      expect(find.byType(CoffeeCaptureCupGuide),
          steps[i].$3 ? findsOneWidget : findsNothing);
      await pickAndUse(tester, 'slot$i');
    }
    expect(find.text(CoffeeV3Copy.reviewTitle), findsOneWidget);
    expect(find.text(CoffeeV3Copy.reviewBody), findsOneWidget);
    expect(find.byType(CoffeeV2Thumbnail), findsNWidgets(4));
    expect(find.text(CoffeeV3Copy.reviewChange), findsNWidgets(4));
  }

  testWidgets('four-step capture → review → create → four stages → observing',
      (tester) async {
    await captureToReview(tester);
    expect(cta(tester).onPressed, isNull); // no intention yet
    await tapAndDrain(
      tester,
      find.text(CoffeeV2IntentionChoice.general.label),
    );
    expect(cta(tester).onPressed, isNotNull);
    await tapAndDrain(tester, find.text(CoffeeV3Copy.reviewCta));
    await drain(tester);
    expect(transport.creates.single.body?['coffeeCaptureContract'], 'four_view_v3');
    expect(transport.stagedSlots, [
      'v3_cup_handle_far',
      'v3_cup_turn_a',
      'v3_cup_turn_b',
      'v3_saucer',
    ]);
    expect(find.byType(CoffeeLoadingView), findsOneWidget);
    // No route back to editing once active.
    expect(find.text(CoffeeV3Copy.reviewChange), findsNothing);
    expect(find.text(CoffeeV3Copy.actionPickGallery), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('flag turned OFF: draft stays reviewable, CTA disabled + note',
      (tester) async {
    await captureToReview(tester);
    await tapAndDrain(tester, find.text(CoffeeV2IntentionChoice.general.label));
    FeatureFlagRuntime.refreshFromRemote({'coffee_v3_four_view': false});
    // Reopen the screen (new provider scope over the same storage).
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    // Draft recovery re-validates all four files (size + streaming sha).
    await drain(tester, iterations: 60);
    expect(find.text(CoffeeV3Copy.reviewTitle), findsOneWidget);
    expect(find.byType(CoffeeV2Thumbnail), findsNWidgets(4));
    expect(cta(tester).onPressed, isNull);
    expect(find.text(CoffeeV3Copy.creationUnavailable), findsOneWidget);
    expect(find.text(CoffeeV3Copy.reviewCancel), findsOneWidget);
    expect(transport.creates, isEmpty);
    // Cancel → nothing V3-owned left → default V2 route.
    await tapAndDrain(tester, find.text(CoffeeV3Copy.reviewCancel));
    expect(find.byType(CoffeeV2FlowScreen), findsOneWidget);
    expect(storage.getString(CoffeeV3SubmissionStore.key), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
