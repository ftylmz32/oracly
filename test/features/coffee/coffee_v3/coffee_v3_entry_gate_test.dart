/// Slice 4 entry routing: recovery ownership first, fresh V3 only with the
/// client rollout flag ON + Turkish UI, the existing V2 route otherwise.
/// Fresh-Coffee cases use the REAL flag runtime + language binding.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/coffee_v2/controllers/coffee_v2_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_entry_gate.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_flow_screen.dart';
import 'package:oracly_new/features/coffee/coffee_v2/providers/coffee_v2_providers.dart';
import 'package:oracly_new/features/coffee/coffee_v3/controllers/coffee_v3_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v3/presentation/coffee_v3_flow_screen.dart';
import 'package:oracly_new/features/coffee/coffee_v3/providers/coffee_v3_providers.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_store.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';

import '../../../support/fake_reading_operation_backend.dart';

void main() {
  setUp(() {
    OraclyL10n.bind('tr');
    FeatureFlagRuntime.refreshFromRemote(ProductFeatureFlags.defaults());
  });
  tearDown(() {
    OraclyL10n.bind('tr');
    FeatureFlagRuntime.refreshFromRemote(ProductFeatureFlags.defaults());
  });

  CoffeeExperienceService experience() => CoffeeExperienceService(
        store: CoffeeReadingStore(LocalStorage.ephemeral()),
        analysis: const UnavailableCoffeeAnalysis(),
      );

  Widget app({
    CoffeeV3StoredState v3 = CoffeeV3StoredState.none,
    bool v2Active = false,
    bool v2DraftPhotos = false,
    bool legacy = false,
    bool transport = true,
    String? savedId,
    String? operationId,
  }) {
    return ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(LocalStorage.ephemeral()),
        coffeeV3StoredStateProvider.overrideWithValue(v3),
        coffeeHasRecoverableV2SessionProvider.overrideWithValue(v2Active),
        coffeeHasV2DraftPhotosProvider.overrideWithValue(v2DraftPhotos),
        coffeeHasLegacyPendingOperationProvider.overrideWithValue(legacy),
        readingOperationSenderProvider.overrideWithValue(
          transport ? FakeReadingOperationBackend().send : null,
        ),
        // Light stand-ins: these tests assert ROUTING only.
        coffeeV3FlowControllerProvider.overrideWith(
          (ref) => CoffeeV3FlowController(
            submission: null,
            flow: null,
            experience: experience(),
          ),
        ),
        coffeeV2FlowControllerProvider.overrideWith(
          (ref) => CoffeeV2FlowController(
            submission: null,
            flow: null,
            experience: experience(),
          ),
        ),
      ],
      child: MaterialApp(
        home: CoffeeV2EntryGate(
          savedReadingId: savedId,
          operationId: operationId,
        ),
      ),
    );
  }

  void flagOn() =>
      FeatureFlagRuntime.refreshFromRemote({'coffee_v3_four_view': true});

  testWidgets('B flag OFF (default) fresh Coffee → existing V2 flow',
      (tester) async {
    await tester.pumpWidget(app());
    expect(find.byType(CoffeeV2FlowScreen), findsOneWidget);
    expect(find.byType(CoffeeV3FlowScreen), findsNothing);
  });

  testWidgets('C flag ON + tr fresh Coffee → V3 flow', (tester) async {
    flagOn();
    await tester.pumpWidget(app());
    expect(find.byType(CoffeeV3FlowScreen), findsOneWidget);
  });

  testWidgets('D flag ON + en/ru fresh Coffee → V2 flow', (tester) async {
    flagOn();
    for (final lang in ['en', 'ru']) {
      OraclyL10n.bind(lang);
      await tester.pumpWidget(app());
      expect(find.byType(CoffeeV2FlowScreen), findsOneWidget, reason: lang);
      expect(find.byType(CoffeeV3FlowScreen), findsNothing, reason: lang);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('E active V3 + flag OFF (or non-tr) → V3 recovery', (tester) async {
    OraclyL10n.bind('en');
    await tester.pumpWidget(app(v3: CoffeeV3StoredState.active, v2Active: true,
        legacy: true));
    expect(find.byType(CoffeeV3FlowScreen), findsOneWidget);
  });

  testWidgets('F V3 draft + flag OFF → V3 (draft never silently lost)',
      (tester) async {
    await tester.pumpWidget(app(v3: CoffeeV3StoredState.draft));
    expect(find.byType(CoffeeV3FlowScreen), findsOneWidget);
  });

  testWidgets('G saved reading route unaffected', (tester) async {
    flagOn();
    await tester.pumpWidget(app(v3: CoffeeV3StoredState.active, savedId: 's1'));
    expect(find.byType(CoffeeReferenceScreen), findsOneWidget);
    expect(find.byType(CoffeeV3FlowScreen), findsNothing);
  });

  testWidgets('H explicit operationId route unaffected', (tester) async {
    flagOn();
    await tester.pumpWidget(
      app(v3: CoffeeV3StoredState.active, operationId: 'a' * 32),
    );
    expect(find.byType(CoffeeReferenceScreen), findsOneWidget);
    expect(find.byType(CoffeeV3FlowScreen), findsNothing);
  });

  testWidgets('I V2 recoverable session wins over starting a NEW V3 session',
      (tester) async {
    flagOn();
    await tester.pumpWidget(app(v2Active: true));
    expect(find.byType(CoffeeV2FlowScreen), findsOneWidget);
    expect(find.byType(CoffeeV3FlowScreen), findsNothing);
    // A V2 draft that already holds photos is not stranded either.
    await tester.pumpWidget(app(v2DraftPhotos: true));
    expect(find.byType(CoffeeV2FlowScreen), findsOneWidget);
    expect(find.byType(CoffeeV3FlowScreen), findsNothing);
  });

  testWidgets('J legacy pending stays legacy (flag ON)', (tester) async {
    flagOn();
    await tester.pumpWidget(app(legacy: true));
    expect(find.byType(CoffeeReferenceScreen), findsOneWidget);
    expect(find.byType(CoffeeV3FlowScreen), findsNothing);
  });

  testWidgets('blocked (foreign / unknown) V3 record never enters V3',
      (tester) async {
    flagOn();
    await tester.pumpWidget(app(v3: CoffeeV3StoredState.blocked));
    expect(find.byType(CoffeeV2FlowScreen), findsOneWidget);
    expect(find.byType(CoffeeV3FlowScreen), findsNothing);
  });

  testWidgets('no transport: flag ON still falls back exactly as before',
      (tester) async {
    flagOn();
    await tester.pumpWidget(app(transport: false));
    expect(find.byType(CoffeeReferenceScreen), findsOneWidget);
    expect(find.byType(CoffeeV3FlowScreen), findsNothing);
  });
}
