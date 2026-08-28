import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/core/l10n/oracly_format.dart';
import 'package:oracly_new/features/birth_chart/copy/birth_chart_copy.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_record_mapper.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/presentation/screens/birth_chart_screen.dart';
import 'package:oracly_new/features/birth_chart/presentation/widgets/birth_chart_onboarding_view.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Dates in the identity card need the same locale data main() loads.
  setUpAll(() => OraclyFormat.ensureInitialized());

  Future<void> setPhoneSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('empty birth info shows form and blocks submit', (tester) async {
    await setPhoneSurface(tester);
    var submitted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BirthChartOnboardingView(
            onSubmit: (_) async => submitted = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(BirthChartCopy.personalizeEmpty), findsOneWidget);
    expect(find.text(BirthChartCopy.generateChart), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(BirthChartCopy.generateChart),
      60,
    );
    await tester.tap(find.text(BirthChartCopy.generateChart));
    await tester.pump();

    expect(submitted, isFalse);
    expect(find.text(BirthChartCopy.birthDateRequired), findsOneWidget);
    expect(find.text(BirthChartCopy.birthTimeRequired), findsNothing);
    expect(find.text(BirthChartCopy.birthPlaceRequired), findsNothing);
  });

  testWidgets('date with unknown time can submit after explicit choice',
      (tester) async {
    await setPhoneSurface(tester);
    BirthProfile? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BirthChartOnboardingView(
            initialProfile: BirthProfile(
              birthDate: DateTime(1990, 3, 25),
              birthPlace: '',
              birthTimeKnown: false,
            ),
            onSubmit: (profile) async => submitted = profile,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(BirthChartCopy.trustNote), findsOneWidget);
    expect(find.text(BirthChartCopy.timeUnknownLabel), findsOneWidget);

    await tester.tap(find.text(BirthChartCopy.timeUnknownLabel));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text(BirthChartCopy.generateChart),
      60,
    );
    await tester.tap(find.text(BirthChartCopy.generateChart));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted!.birthDate, DateTime(1990, 3, 25));
    expect(submitted!.hasKnownTime, isFalse);
    expect(submitted!.birthTime, isNull);
    expect(submitted!.birthPlace, isEmpty);
    expect(find.text(BirthChartCopy.birthTimeRequired), findsNothing);
    expect(find.text(BirthChartCopy.birthPlaceRequired), findsNothing);
  });

  testWidgets('saved chart reopens result without asking again', (tester) async {
    await setPhoneSurface(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final incomplete = const NatalChartCalculator().calculate(
      BirthProfile(
        birthDate: DateTime(1990, 3, 25),
        birthPlace: 'Ankara',
        birthTime: DateTime(1990, 3, 25, 9, 15),
        birthTimeKnown: true,
      ),
    );
    await storage.setString(
      'birth_chart_latest',
      jsonEncode(BirthChartRecordMapper.toRecord(incomplete).toJson()),
    );

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: BirthChartScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text(BirthChartCopy.sectionYourChart), findsOneWidget);
    expect(find.text(BirthChartCopy.storedNotUsedNote), findsOneWidget);
    expect(find.text(BirthChartCopy.summaryTitle), findsOneWidget);
    expect(find.text(BirthChartCopy.strongThemesTitle), findsOneWidget);
    expect(find.text(BirthChartCopy.notableThemesTitle), findsOneWidget);
    expect(find.text(BirthChartCopy.resultInterpretation), findsOneWidget);
    expect(find.textContaining('Güneş'), findsWidgets);
    expect(find.text(BirthChartCopy.ephemerisNote), findsWidgets);
    expect(find.text(BirthChartCopy.planetsTitle), findsNothing);
    expect(find.text(BirthChartCopy.housesTitle), findsNothing);
    expect(find.text(BirthChartCopy.updateBirthInfo), findsOneWidget);
    expect(find.text(BirthChartCopy.onboardingHeadline), findsNothing);
  });

  testWidgets('edit birth info opens prefilled form without clearing save',
      (tester) async {
    await setPhoneSurface(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final repository = LocalBirthChartRepository(storage);
    final incomplete = const NatalChartCalculator().calculate(
      BirthProfile(
        birthDate: DateTime(1990, 3, 25),
        birthPlace: 'Ankara',
        birthTime: DateTime(1990, 3, 25, 9, 15),
        birthTimeKnown: true,
      ),
    );
    await repository.save(BirthChartRecordMapper.toRecord(incomplete));

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: BirthChartScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.scrollUntilVisible(
      find.text(BirthChartCopy.updateBirthInfo),
      80,
    );
    await tester.tap(find.text(BirthChartCopy.updateBirthInfo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(BirthChartCopy.updateChart), findsOneWidget);
    expect(find.text('Ankara'), findsWidgets);
    expect(await repository.getLatest(), isNotNull);

    await tester.scrollUntilVisible(find.text(BirthChartCopy.cancelEdit), 60);
    await tester.tap(find.text(BirthChartCopy.cancelEdit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(BirthChartCopy.sectionYourChart), findsOneWidget);
  });
}
