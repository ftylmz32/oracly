/// SoulMate failure differentiation — status message reaches the error UI.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_screen.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(PremiumDevOverride.resetDebug);

  // SMD1 — every new submission is server-authoritative: the screen never
  // calls `soulMateDrawPortProvider` (the direct-AI port) at all anymore,
  // so a port-level auth failure can no longer occur on the new path. The
  // new equivalent honesty guarantee is: a server-side terminal failure
  // shows honest failure copy — never a fake portrait — via the durable
  // `failed` outcome.
  testWidgets(
      'a durable operation that the server marks failed shows honest failure copy, not a fake portrait',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    PremiumDevOverride.debugEnvironment = AppEnvironment.development;
    PremiumDevOverride.debugFlag = true;
    await MockPremiumRepository(storage).activatePlan(PremiumPlanKind.yearly);

    final backend = FakeReadingOperationBackend();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          readingFeatureRunnerProvider.overrideWithValue(
            fakeImmediateReadingFeatureRunner(backend: backend),
          ),
          readingOperationInputGatewayProvider.overrideWithValue(
            fakeReadingOperationInputGateway(backend: backend),
          ),
        ],
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();
    final element = tester.element(find.byType(SoulMateDrawScreen));
    await ProviderScope.containerOf(element).read(premiumStatusProvider).load();
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Ayse');
    await tester.tap(find.text(SoulMateCopy.birthHint));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final ok = find.text('OK');
    final tamam = find.text('Tamam');
    await tester.tap(ok.evaluate().isNotEmpty ? ok : tamam);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    final cta = find.text(SoulMateCopy.drawCta);
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.pump();

    final active = await backend.send(
      'GET',
      '/v1/reading-flow/active?readingType=soulmate',
      null,
    );
    final operationId =
        ((active!.json!['data'] as Map)['operation'] as Map)['operationId']
            as String;
    await backend.send(
      'POST',
      '/v1/reading-operations/$operationId/fail',
      const {},
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(find.text(SoulMateCopy.failureTemporary), findsOneWidget);
    expect(find.text(SoulMateCopy.redrawCta), findsNothing);
    expect(find.text(SoulMateCopy.retry), findsOneWidget);
  });
}
