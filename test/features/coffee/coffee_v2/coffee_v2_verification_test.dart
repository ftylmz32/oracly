library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/coffee/coffee_v2/controllers/coffee_v2_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_active_staging_view.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_final_review_view.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_intro_view.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_preview_view.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_step_view.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';

import '../../../support/coffee_v2_test_support.dart';

const _fixturePaths = <String>[
  'lib/assets/images/coffee_ritual_hero.webp',
  'lib/assets/images/home/home_coffee.webp',
  'lib/assets/images/thumbs/coffee_ritual_hero.webp',
];

void _trace(String message) {
  final file = File('tool/qa/coffee_v2/verification_trace.txt');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('$message\n', mode: FileMode.append, flush: true);
}

Future<ReadingOperationWire?> _offlineSend(
  String method,
  String path,
  Map<String, Object>? body,
) async => null;

class _OfflineAnalysis implements CoffeeAnalysisPort {
  const _OfflineAnalysis();
  @override
  bool get isAvailable => true;
  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) =>
      throw StateError('Verification never analyzes');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Coffee V2 required viewports and QA screenshots', (tester) async {
    final trace = File('tool/qa/coffee_v2/verification_trace.txt');
    trace.parent.createSync(recursive: true);
    trace.writeAsStringSync('start\n');
    final storage = LocalStorage.ephemeral();
    final operations = ReadingOperationGateway(send: _offlineSend);
    final flow = ReadingLiveFlow(
      operations: operations,
      acceleration: ReadingAccelerationClient(send: _offlineSend),
      send: _offlineSend,
    );
    final submission = CoffeeV2SubmissionController(
      flow: flow,
      stagedImages: ReadingStagedImageGateway(_offlineSend),
      store: CoffeeV2SubmissionStore(storage),
      normalizer: ScriptedCoffeeV2Normalizer((source) async => source),
    );
    for (var i = 0; i < coffeeV2CanonicalSlotOrder.length; i++) {
      final slot = coffeeV2CanonicalSlotOrder[i];
      await tester.runAsync(() async {
        await submission.setSlot(
          slot,
          CoffeeImagePick(path: _fixturePaths[i], mimeType: 'image/webp'),
        );
        await submission.confirmSlot(slot);
      });
    }
    // ignore: avoid_print
    _trace('fixtures ready');
    final controller = CoffeeV2FlowController(
      submission: submission,
      flow: flow,
      experience: CoffeeExperienceService(
        store: CoffeeReadingStore(storage),
        analysis: const _OfflineAnalysis(),
      ),
    );
    addTearDown(controller.dispose);

    final views = <String, Widget>{
      '01_intro': CoffeeV2IntroView(onStart: () {}),
      '02_step1_cup_primary': CoffeeV2StepView(
        controller: controller,
        slot: CoffeeV2PhotoSlot.cupPrimary,
      ),
      '03_preview': (() {
        controller.setPreviewCandidate(
          CoffeeV2PhotoSlot.cupPrimary,
          CoffeeImagePick(path: _fixturePaths[0], mimeType: 'image/webp'),
        );
        return CoffeeV2PreviewView(controller: controller);
      })(),
      '04_step2_cup_secondary': CoffeeV2StepView(
        controller: controller,
        slot: CoffeeV2PhotoSlot.cupSecondary,
      ),
      '05_step3_saucer': CoffeeV2StepView(
        controller: controller,
        slot: CoffeeV2PhotoSlot.saucer,
      ),
      '06_final_review': CoffeeV2FinalReviewView(controller: controller),
      '07_retryable_active': (() {
        controller.stagingRetryable = true;
        return CoffeeV2ActiveStagingView(controller: controller);
      })(),
    };

    for (final size in const [Size(320, 568), Size(390, 844)]) {
      for (final entry in views.entries) {
        // ignore: avoid_print
        _trace('layout ${entry.key} $size');
        await _render(tester, size, entry.value);
        expect(tester.takeException(), isNull, reason: '${entry.key} at $size');
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -300));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: '${entry.key} scroll at $size');
        }
      }
    }

    final output = Directory('tool/qa/coffee_v2');
    await tester.runAsync(() => output.create(recursive: true));
    for (final entry in views.entries) {
      // ignore: avoid_print
      _trace('screenshot ${entry.key}');
      final key = GlobalKey();
      await _render(tester, const Size(390, 844), entry.value,
          boundaryKey: key);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${output.path}/${entry.key}.png')
            .writeAsBytes(data!.buffer.asUint8List());
      });
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Future<void> _render(
  WidgetTester tester,
  Size size,
  Widget view, {
  GlobalKey? boundaryKey,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: RepaintBoundary(
        key: boundaryKey,
        child: Scaffold(
          backgroundColor: const Color(0xFF050308),
          body: SafeArea(child: view),
        ),
      ),
    ),
  ));
  await tester.pump();
}
