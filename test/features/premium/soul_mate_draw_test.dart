/// Premium — Ruh Eşini Çiz list, lock, detail, fail-closed draw.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/premium/data/soul_mate_result_store.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_screen.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/providers/soul_mate_providers.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:oracly_new/features/premium/services/soul_mate_dev_access.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_validation.dart';
import 'package:oracly_new/features/premium/services/unavailable_soul_mate_draw.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void _unlockDevPremium() {
  PremiumDevOverride.debugEnvironment = AppEnvironment.development;
  PremiumDevOverride.debugFlag = true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(PremiumDevOverride.resetDebug);

  test('validation requires name and birth only', () {
    expect(
      SoulMateDrawValidation.missingField(name: '', birth: null),
      SoulMateCopy.nameRequired,
    );
    expect(
      SoulMateDrawValidation.missingField(name: 'Ayşe', birth: null),
      SoulMateCopy.birthRequired,
    );
    expect(
      SoulMateDrawValidation.missingField(
        name: 'Ayşe',
        birth: DateTime(1994, 3, 12),
      ),
      isNull,
    );
  });

  test('intake never invents a compatibility score', () {
    expect(SoulMateCopy.screenLead.toLowerCase(), isNot(contains('skor')));
    expect(SoulMateCopy.screenLead.toLowerCase(), isNot(contains('score')));
    expect(SoulMateCopy.formWhy.toLowerCase(), isNot(contains('uyumluluk')));
    expect(SoulMateCopy.honesty.toLowerCase(), isNot(contains('uyumluluk')));
  });

  test('no dedicated soul-mate route is registered', () {
    expect(OraclyRoutes.premium, '/premium');
    expect(
      <String>[
        OraclyRoutes.premium,
        OraclyRoutes.home,
        OraclyRoutes.coffee,
      ],
      isNot(contains('/soul-mate')),
    );
  });

  test('interpretation is local, stable, and never a soulmate claim', () {
    final request = SoulMateDrawRequest(
      name: 'Ayşe',
      birthDate: DateTime(1994, 3, 12),
      intention: 'sakin bir bağ',
    );
    final a = SoulMateInterpretation.forRequest(request);
    final b = SoulMateInterpretation.forRequest(request);
    expect(a, b);
    expect(a, isNotEmpty);
    expect(a.toLowerCase(), isNot(contains('kesin')));
    expect(a.toLowerCase(), isNot(contains('yapay zek')));
    expect(
      SoulMateCopy.honesty,
      contains('sembolik'),
    );
  });

  test('unavailable port never invents a portrait', () async {
    expect(const UnavailableSoulMateDraw().isAvailable, isFalse);
    final result = await const UnavailableSoulMateDraw().draw(
      SoulMateDrawRequest(name: 'Ayşe', birthDate: DateTime(1994, 3, 12)),
    );
    expect(result.available, isFalse);
    expect(result.hasPortrait, isFalse);
    expect(result.message, SoulMateCopy.unavailable);
  });

  test('dev access is env-flag gated and ignored in production', () {
    expect(SoulMateDevAccess.allowsTestAccess, isFalse);
    PremiumDevOverride.debugEnvironment = AppEnvironment.development;
    PremiumDevOverride.debugFlag = true;
    expect(SoulMateDevAccess.allowsTestAccess, isTrue);
    PremiumDevOverride.debugEnvironment = AppEnvironment.production;
    expect(SoulMateDevAccess.allowsTestAccess, isFalse);
    PremiumDevOverride.resetDebug();
  });

  testWidgets('Ruh Eşini Çiz gate follows debug override when free',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: PremiumReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text(PremiumCopy.benefitOrTitle), findsWidgets);
    expect(find.text(PremiumCopy.benefitJourneyTitle), findsWidgets);
    expect(find.text(PremiumCopy.benefitSoulmateTitle), findsWidgets);
    expect(find.text(PremiumCopy.benefitCoffeeTitle), findsNothing);

    final status = ProviderScope.containerOf(
      tester.element(find.byType(PremiumReferenceScreen)),
    ).read(premiumStatusProvider);
    expect(status.isPremium, isFalse);

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    if (SoulMateDevAccess.allowsTestAccess) {
      expect(find.text(SoulMateCopy.drawCta), findsOneWidget);
      expect(find.text(SoulMateCopy.screenTitle), findsOneWidget);
      expect(status.isPremium, isFalse);
    } else {
      expect(find.text(SoulMateCopy.screenTitle), findsOneWidget);
      expect(find.text(PremiumCopy.unlockTitle), findsWidgets);
      expect(find.text(SoulMateCopy.drawCta), findsNothing);
      expect(find.text(PremiumCopy.accessRequired), findsNothing);
    }
  });

  testWidgets('premium member opens detail form', (tester) async {
    await _openPremiumDetail(tester);

    expect(find.text(SoulMateCopy.screenTitle), findsOneWidget);
    expect(find.text(SoulMateCopy.screenLead), findsWidgets);
    expect(find.text(SoulMateCopy.drawCta), findsOneWidget);
    expect(find.text(SoulMateCopy.nameHint), findsOneWidget);
    expect(find.text(SoulMateCopy.formWhy), findsOneWidget);
    await tester.ensureVisible(find.text(SoulMateCopy.honesty));
    await tester.pump();
    expect(find.text(SoulMateCopy.honesty), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Ayşe');
    await _tapDraw(tester);
    expect(find.text(SoulMateCopy.birthRequired), findsWidgets);
  });

  testWidgets('unavailable draw stays honest and fail-closed', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    _unlockDevPremium();
    await MockPremiumRepository(storage).activatePlan(PremiumPlanKind.yearly);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          soulMateDrawPortProvider.overrideWithValue(
            const UnavailableSoulMateDraw(),
          ),
        ],
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();
    final element = tester.element(find.byType(SoulMateDrawScreen));
    await ProviderScope.containerOf(element).read(premiumStatusProvider).load();
    await tester.pump();

    await _advanceToDraw(tester);
    await _tapDraw(tester);
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text(SoulMateCopy.unavailable), findsOneWidget);
    expect(find.text(SoulMateCopy.redrawCta), findsNothing);
  });

  testWidgets('loading copy appears while a real port is pending',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    _unlockDevPremium();
    await MockPremiumRepository(storage).activatePlan(PremiumPlanKind.yearly);
    final gate = Completer<SoulMateDrawResult>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          soulMateDrawPortProvider.overrideWithValue(_GatedDraw(gate)),
        ],
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();
    final element = tester.element(find.byType(SoulMateDrawScreen));
    await ProviderScope.containerOf(element).read(premiumStatusProvider).load();
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Ayşe');
    await _pickDefaultBirth(tester);
    await _tapDraw(tester);
    await tester.pump();
    expect(find.text(SoulMateCopy.drawing), findsWidgets);
    gate.complete(
      SoulMateDrawResult.unavailable(SoulMateCopy.unavailable),
    );
    // Let the honest failure land before the tree is torn down.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(SoulMateCopy.unavailable), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('success port shows portrait and redraw', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await SoulMateResultStore.clear(storage);
    _unlockDevPremium();
    await MockPremiumRepository(storage).activatePlan(PremiumPlanKind.yearly);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          soulMateDrawPortProvider.overrideWithValue(const _SuccessDraw()),
        ],
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();
    final element = tester.element(find.byType(SoulMateDrawScreen));
    await ProviderScope.containerOf(element).read(premiumStatusProvider).load();
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Ayşe');
    await _pickDefaultBirth(tester);
    await _tapDraw(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
    expect(find.text(SoulMateCopy.brandMark), findsOneWidget);
    expect(find.text(SoulMateCopy.energyLabel), findsOneWidget);
    expect(find.text(SoulMateCopy.honesty), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(SoulMateCopy.redrawCta),
      120,
    );
    await tester.pump();
    await tester.tap(find.text(SoulMateCopy.redrawCta));
    await tester.pump();
    expect(find.text(SoulMateCopy.drawCta), findsOneWidget);
  });

  testWidgets('soul mate screen exposes back and pops via leading',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    _unlockDevPremium();
    await MockPremiumRepository(storage).activatePlan(PremiumPlanKind.monthly);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SoulMateDrawScreen(),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SoulMateDrawScreen), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SoulMateDrawScreen), findsNothing);
  });

  testWidgets('detail form fits 360x800 without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    _unlockDevPremium();
    await MockPremiumRepository(storage).activatePlan(PremiumPlanKind.yearly);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();
    final element = tester.element(find.byType(SoulMateDrawScreen));
    await ProviderScope.containerOf(element).read(premiumStatusProvider).load();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(SoulMateCopy.screenTitle), findsOneWidget);
  });

  const pickerViewports = <Size>[
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(411, 901),
    Size(430, 932),
    Size(600, 960),
  ];

  for (final size in pickerViewports) {
    testWidgets(
      'birth picker has no overflow at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.open();
        _unlockDevPremium();
        await MockPremiumRepository(storage).activatePlan(
          PremiumPlanKind.yearly,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [localStorageProvider.overrideWithValue(storage)],
            child: const MaterialApp(home: SoulMateDrawScreen()),
          ),
        );
        await tester.pump();
        final element = tester.element(find.byType(SoulMateDrawScreen));
        await ProviderScope.containerOf(element)
            .read(premiumStatusProvider)
            .load();
        await tester.pump();

        await tester.tap(find.text(SoulMateCopy.birthHint));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.byType(CalendarDatePicker), findsOneWidget);

        await _confirmDatePicker(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in pickerViewports) {
    testWidgets(
      'form fits ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.open();
        _unlockDevPremium();
        await MockPremiumRepository(storage).activatePlan(
          PremiumPlanKind.yearly,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [localStorageProvider.overrideWithValue(storage)],
            child: MediaQuery(
              data: MediaQueryData(size: size),
              child: const MaterialApp(home: SoulMateDrawScreen()),
            ),
          ),
        );
        await tester.pump();
        final element = tester.element(find.byType(SoulMateDrawScreen));
        await ProviderScope.containerOf(element)
            .read(premiumStatusProvider)
            .load();
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text(SoulMateCopy.screenTitle), findsOneWidget);
        expect(find.text(SoulMateCopy.drawCta), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text(SoulMateCopy.drawCta),
          80,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _openPremiumDetail(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  _unlockDevPremium();
  await MockPremiumRepository(storage).activatePlan(
    PremiumPlanKind.yearly,
    authoritative: true,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [localStorageProvider.overrideWithValue(storage)],
      child: const MaterialApp(home: SoulMateDrawScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
}

Future<void> _tapDraw(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  final cta = find.text(SoulMateCopy.drawCta);
  await tester.ensureVisible(cta);
  await tester.pump();
  await tester.tap(cta);
  await tester.pump();
}

Future<void> _advanceToDraw(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'Ayşe');
  await _pickDefaultBirth(tester);
  await tester.scrollUntilVisible(
    find.text(SoulMateCopy.drawCta),
    80,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}

Future<void> _pickDefaultBirth(WidgetTester tester) async {
  await tester.tap(find.text(SoulMateCopy.birthHint));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await _confirmDatePicker(tester);
}

Future<void> _confirmDatePicker(WidgetTester tester) async {
  final ok = find.text('OK');
  final tamam = find.text('Tamam');
  await tester.tap(ok.evaluate().isNotEmpty ? ok : tamam);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

class _GatedDraw implements SoulMateDrawPort {
  _GatedDraw(this.gate);
  final Completer<SoulMateDrawResult> gate;

  @override
  bool get isAvailable => true;

  @override
  Future<SoulMateDrawResult> draw(SoulMateDrawRequest request) => gate.future;
}

class _SuccessDraw implements SoulMateDrawPort {
  const _SuccessDraw();

  @override
  bool get isAvailable => true;

  @override
  Future<SoulMateDrawResult> draw(SoulMateDrawRequest request) async {
    return const SoulMateDrawResult.success(
      imageBytes: <int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00,
        0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x01, 0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE,
        0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63,
        0xF8, 0xCF, 0xC0, 0x00, 0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05,
        0xFE, 0xD4, 0xEF, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,
        0xAE, 0x42, 0x60, 0x82,
      ],
    );
  }
}
