import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/experience/providers/continue_where_you_left_off_provider.dart';
import 'package:oracly_new/features/home/master/home_master_page.dart';
import 'package:oracly_new/features/home/master/home_master_premium.dart';
import 'package:oracly_new/features/home/theme/home_ritual_atmosphere.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/providers/personal_discovery_providers.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';
import '../personal_discovery/pde_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();

  PersonalDiscoveryProfile evidence() => PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          readings: [
            pdeTarot(
              't1',
              'İlişkilerde yumuşak bir değişim var.',
              at: now.subtract(const Duration(days: 4)),
            ),
          ],
          coffee: [
            pdeCoffee(
              'c1',
              'Fincanda ilişki teması yeniden duruyor.',
              at: now.subtract(const Duration(days: 2)),
            ),
          ],
        ),
        now: now,
      );

  Future<void> pumpCrowded(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          personalDiscoveryProfileProvider.overrideWith((ref) async => evidence()),
          continueWhereYouLeftOffProvider.overrideWith(
            (ref) async => ContinueWhereYouLeftOffTarget(
              kind: ContinueWhereYouLeftOffKind.tarot,
              updatedAt: now,
            ),
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
              padding: const EdgeInsets.only(top: 24, bottom: 34),
            ),
            child: const HomeMasterPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
  }

  for (final size in const <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
  ]) {
    testWidgets(
      'continue and next action stay reachable at ${size.width}x${size.height}',
      (tester) async {
        await pumpCrowded(tester, size);
        expect(tester.takeException(), isNull);
        expect(find.byType(HomeRitualWash), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byType(HomeMasterPremium),
          120,
          scrollable: find.descendant(
            of: find.byType(HomeMasterPage),
            matching: find.byType(Scrollable),
          ).first,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('text scale 1.6 with both optional cards does not overflow', (
    tester,
  ) async {
    await pumpCrowded(tester, const Size(390, 844), textScale: 1.6);
    expect(tester.takeException(), isNull);
  });
}
