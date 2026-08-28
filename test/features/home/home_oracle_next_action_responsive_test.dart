/// Home Oracle NextAction — responsive fit with evidence.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/home/master/home_master_body.dart';
import 'package:oracly_new/features/home/master/home_oracle_next_action_card.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/providers/personal_discovery_providers.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';
import '../personal_discovery/pde_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  final now = DateTime(2026, 8, 26, 12);
  final profile = PersonalDiscoveryProfileBuilder.from(
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

  for (final size in const [
    Size(360, 640),
    Size(390, 844),
    Size(430, 932),
  ]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('HomeMasterBody with NextAction fits $label', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          overrides: [
            personalDiscoveryProfileProvider.overrideWith(
              (ref) async => profile,
            ),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: const Scaffold(body: HomeMasterBody()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeOracleNextActionCard), findsOneWidget);
      expect(find.text('OR ile Aç'), findsOneWidget);
    });
  }
}
