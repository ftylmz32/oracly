/// Slice 3 — the CURRENT Coffee V2 controller's shared READY-result
/// restoration (`experience.restoreCompleted`) can carry an `m2_public_v1`
/// result to CoffeeResultView with the exact authoritative overall. V2
/// capture stays three slots and never sends `coffeeCaptureContract`.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/chamber_narrative_block.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/coffee/coffee_v2/controllers/coffee_v2_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_intention.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_active_observing_view.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_result_contract.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_result_view.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/openai_coffee_analysis.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/coffee_v2_test_support.dart';
import '../../../support/fake_reading_operation_backend.dart';

class _NoProviderAi implements OraclyAiService {
  int calls = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('provider must not be touched: ${invocation.memberName}');
  }
}

// SYNTHETIC (never product copy): short, padded, scrub-sensitive.
const _overall = '  Fincanda bir konu ön plana çıkabilir;  kesin olacak gibi değil.\n';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'V2 ready-result restore carries m2_public_v1 to CoffeeResultView exactly',
    (tester) async {
      OraclyL10n.bind('tr');
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      final readingStore = CoffeeReadingStore(storage);
      final backend = FakeReadingOperationBackend(immediatelyEligible: false)
        ..authoritativeBalance = 95;
      final transport = RecordingStagedTransport(backend);
      final bodies = <Map<String, Object>>[];
      Future<ReadingOperationWire?> send(
        String method,
        String path,
        Map<String, Object>? body,
      ) {
        if (body != null) bodies.add(body);
        return transport.send(method, path, body);
      }

      final ai = _NoProviderAi();
      CoffeeV2FlowController build() {
        final flow = ReadingLiveFlow(
          operations: ReadingOperationGateway(send: send),
          acceleration: ReadingAccelerationClient(send: send),
          send: send,
        );
        return CoffeeV2FlowController(
          submission: CoffeeV2SubmissionController(
            flow: flow,
            stagedImages: ReadingStagedImageGateway(send),
            store: CoffeeV2SubmissionStore(storage, ownerId: 'owner-s3'),
            normalizer: ScriptedCoffeeV2Normalizer((source) async => source),
            messages: coffeeV2TestMessages,
          ),
          flow: flow,
          experience: CoffeeExperienceService(
            store: readingStore,
            analysis: OpenAiCoffeeAnalysis(ai: ai),
          ),
        );
      }

      late CoffeeV2FlowController controller;
      await tester.runAsync(() async {
        final temp = await Directory.systemTemp.createTemp('coffee_v2_s3_');
        addTearDown(() async {
          if (await temp.exists()) await temp.delete(recursive: true);
        });
        final first = build();
        await first.boot();
        first.dismissIntro();
        for (final entry in <CoffeeV2PhotoSlot, int>{
          CoffeeV2PhotoSlot.cupPrimary: 9001,
          CoffeeV2PhotoSlot.cupSecondary: 9101,
          CoffeeV2PhotoSlot.saucer: 9201,
        }.entries) {
          final file = File('${temp.path}/${entry.key.wireValue}.jpg');
          await file.writeAsBytes(plainJpegBytes(totalSize: entry.value));
          await first.submission!.setSlot(
            entry.key,
            CoffeeImagePick(path: file.path, mimeType: 'image/jpeg'),
          );
          await first.submission!.confirmSlot(entry.key);
        }
        await first.selectIntention(CoffeeV2IntentionChoice.general);
        await first.beginSubmission();
        await Future<void>.delayed(const Duration(milliseconds: 30));
        final operationId = first.record.operationId!;
        first.dispose();

        backend.completeServerSide(
          operationId,
          resultId: 'coffee-m2-v2',
          result: {
            'coffeeResultContract': coffeeM2PublicV1ResultContract,
            'visualObservation': '',
            'overall': _overall,
            'love': '',
            'career': '',
            'money': '',
            'nearFuture': '',
            'takeaway': '',
            'symbols': <Object>[],
          },
        );

        controller = build();
        await controller.boot();
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      addTearDown(controller.dispose);

      final reading = controller.reading;
      expect(reading, isNotNull);
      expect(reading!.id, 'coffee-m2-v2');
      expect(reading.coffeeResultContract, coffeeM2PublicV1ResultContract);
      expect(reading.overall, _overall);
      expect(reading.visualObservation, '');
      expect(reading.symbols, isEmpty);
      expect(readingStore.byId('coffee-m2-v2')?.overall, _overall);
      expect(ai.calls, 0);

      // V2 stays a three-slot capture and never claims a V3 capture contract.
      expect(transport.stageCallCountBySlot.keys.toSet(), {
        CoffeeV2PhotoSlot.cupPrimary.wireValue,
        CoffeeV2PhotoSlot.cupSecondary.wireValue,
        CoffeeV2PhotoSlot.saucer.wireValue,
      });
      expect(
        bodies.any((b) => b.containsKey('coffeeCaptureContract')),
        isFalse,
      );

      await tester.binding.setSurfaceSize(const Size(390, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [localStorageProvider.overrideWithValue(storage)],
          child: MaterialApp(
            home: Scaffold(
              body: CoffeeV2ActiveObservingView(
                controller: controller,
                onBack: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(CoffeeResultView), findsOneWidget);
      final hero = tester
          .widgetList<ChamberNarrativeBlock>(find.byType(ChamberNarrativeBlock))
          .firstWhere((b) => b.hero);
      expect(hero.body, _overall);
      expect(find.textContaining('yeniden görünür'), findsNothing);
    },
  );
}
