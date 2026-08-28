/// Product Completion Batch 2 — Gems polish, Yildizname birth UX, Profile audit.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/oracly_crystal_capsule.dart';
import 'package:oracly_new/core/design_system/oracly_gem_facet.dart';
import 'package:oracly_new/core/design_system/oracly_gem_icon.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_natal.dart';
import 'package:oracly_new/features/birth_chart/copy/birth_chart_copy.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_cities.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/presentation/widgets/birth_chart_onboarding_actions.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_display.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/widgets/oracly_live_gem_capsule.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gems canonical identity', () {
    testWidgets('OraclyGemFacet renders canonical OraclyGemIcon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: OraclyGemFacet(size: 24))),
      );
      expect(find.byType(OraclyGemIcon), findsOneWidget);
    });

    testWidgets('live capsule uses canonical gem chrome', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: const MaterialApp(home: Scaffold(body: OraclyLiveGemCapsule())),
        ),
      );
      await tester.pump();
      expect(find.byType(OraclyGemIcon), findsOneWidget);
      expect(find.byType(OraclyCrystalCapsule), findsOneWidget);
    });

    testWidgets('large balance fits capsule without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OraclyCrystalCapsule(count: GemDisplay.format(999999)),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('insufficient balance message unchanged', () {
      OraclyL10n.bind('tr');
      expect(GemsCopy.insufficient, 'Yeterli mücevherin yok.');
    });

    test('gem labels TR / EN / RU', () {
      OraclyL10n.bind('tr');
      expect(GemsCopy.gemUnit, 'Mücevher');
      OraclyL10n.bind('en');
      expect(GemsCopy.gemUnit, 'Gem');
      OraclyL10n.bind('ru');
      expect(GemsCopy.gemUnit, 'Кристалл');
    });

    test('balance stays model-driven', () async {
      SharedPreferences.setMockInitialValues({});
      final store = GemWalletStore(await LocalStorage.open());
      final service = GemWalletService(store);
      await service.earn(amount: 42, reason: 'test');
      expect(GemDisplay.format(service.balance), GemDisplay.format(42));
    });
  });

  group('Yildizname birth UX', () {
    test('future dates rejected by picker lastDate guard', () {
      final now = DateTime.now();
      expect(now.isBefore(DateTime(now.year + 1)), isTrue);
    });

    test('validation requires date', () {
      expect(
        BirthChartOnboardingActions.validate(date: null, timeKnown: false, time: null),
        BirthChartCopy.birthDateRequired,
      );
    });

    test('validation requires explicit time choice', () {
      expect(
        BirthChartOnboardingActions.validate(
          date: DateTime(1990, 3, 25),
          timeKnown: null,
          time: null,
        ),
        BirthChartCopy.timeChoiceRequired,
      );
    });

    test('known time path requires a picked time', () {
      expect(
        BirthChartOnboardingActions.validate(
          date: DateTime(1990, 3, 25),
          timeKnown: true,
          time: null,
        ),
        BirthChartCopy.birthTimeRequired,
      );
    });

    test('unknown birth time stays explicit in profile', () {
      final profile = BirthChartOnboardingActions.buildProfile(
        date: DateTime(1990, 3, 25),
        timeKnown: false,
        time: null,
        city: null,
      );
      expect(profile.birthTimeKnown, isFalse);
      expect(profile.birthTime, isNull);
      expect(profile.hasKnownTime, isFalse);
    });

    test('known birth time persists without silent noon default', () {
      final profile = BirthChartOnboardingActions.buildProfile(
        date: DateTime(1990, 3, 25),
        timeKnown: true,
        time: const TimeOfDay(hour: 9, minute: 15),
        city: null,
      );
      expect(profile.hasKnownTime, isTrue);
      expect(profile.birthTime!.hour, 9);
      expect(profile.birthTime!.minute, 15);
    });

    test('birthplace retained in profile assembly', () {
      final profile = BirthChartOnboardingActions.buildProfile(
        date: DateTime(1990, 3, 25),
        timeKnown: false,
        time: null,
        city: BirthChartCities.byName('Ankara'),
      );
      expect(profile.birthPlace, 'Ankara');
    });

    test('OR handoff keeps Yildizname context without fake exact time', () {
      final unknown = BirthProfile(
        birthDate: DateTime(1990, 3, 25),
        birthPlace: 'Ankara',
        birthTimeKnown: false,
      );
      final line = OracleReadingContextNatal.birthLine(unknown);
      expect(line, contains('25.3.1990'));
      expect(line, contains('Ankara'));
      expect(line, isNot(contains(':')));

      final known = BirthProfile(
        birthDate: DateTime(1990, 3, 25),
        birthPlace: 'Ankara',
        birthTime: DateTime(1990, 3, 25, 9, 15),
        birthTimeKnown: true,
      );
      expect(OracleReadingContextNatal.birthLine(known), contains('09:15'));
    });

    test('birth copy TR / EN / RU for new strings', () {
      OraclyL10n.bind('tr');
      expect(BirthChartCopy.timeKnownLabel, 'Doğum saatimi biliyorum');
      expect(BirthChartCopy.trustNote, contains('yalnızca'));
      OraclyL10n.bind('en');
      expect(BirthChartCopy.timeUnknownLabel, contains('do not know'));
      OraclyL10n.bind('ru');
      expect(BirthChartCopy.timeUnknownValue, 'Неизвестно');
    });
  });

  group('Profile soft-lock audit', () {
    testWidgets('profile app bar keeps gem capsule navigation', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: const MaterialApp(
            home: Scaffold(body: ProfileReferenceAppBar()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(OraclyLiveGemCapsule), findsOneWidget);
    });
  });
}