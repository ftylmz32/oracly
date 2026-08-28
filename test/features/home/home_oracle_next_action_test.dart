/// Home Oracle NextAction — evidence-only personalized slot.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/home/master/home_oracle_next_action_card.dart';
import 'package:oracly_new/features/oracle_core/providers/oracle_core_providers.dart';
import 'package:oracly_new/features/oracle_core/services/oracle_next_action_copy.dart';
import 'package:oracly_new/features/oracle_core/services/oracle_next_action_engine.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
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

  PersonalDiscoveryProfile evidenceProfile() =>
      PersonalDiscoveryProfileBuilder.from(
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

  Future<ProviderContainer> pumpCard(
    WidgetTester tester, {
    required PersonalDiscoveryProfile profile,
    Size size = const Size(390, 844),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late ProviderContainer container;
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          personalDiscoveryProfileProvider.overrideWith(
            (ref) async => profile,
          ),
        ],
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: HomeOracleNextActionCard(),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return container;
  }

  test('copy stays calm and evidence-shaped', () {
    final action = OracleNextActionEngine.decide(
      evidenceProfile(),
      now: now,
    );
    expect(action, isNotNull);
    expect(action!.hasEvidence, isTrue);
    final title = OracleNextActionCopy.homeTitle(action);
    final body = OracleNextActionCopy.homeBody(action);
    expect(title, contains('OR'));
    expect(body.toLowerCase(), contains('tema'));
    expect(body.toLowerCase(), isNot(contains('kork')));
    expect(body.toLowerCase(), isNot(contains('tehlike')));
    expect(OracleNextActionCopy.homeCta(action), contains('OR'));
  });

  testWidgets('no evidence hides the personalized Home slot', (tester) async {
    await pumpCard(tester, profile: PersonalDiscoveryProfile.empty);
    expect(find.byType(HomeOracleNextActionCard), findsOneWidget);
    expect(find.text('OR ile Aç'), findsNothing);
    expect(find.textContaining('bağlantı fark etti'), findsNothing);
  });

  testWidgets('evidence shows a single NextAction with dismiss', (tester) async {
    await pumpCard(tester, profile: evidenceProfile());
    expect(find.textContaining('bağlantı fark etti'), findsOneWidget);
    expect(find.text('OR ile Aç'), findsOneWidget);
    expect(find.textContaining('deneyiminde tekrarlandı'), findsOneWidget);
    expect(find.textContaining('Fincanda ilişki'), findsNothing);
    expect(find.textContaining('İlişkilerde yumuşak'), findsNothing);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('OR ile Aç'), findsNothing);
  });

  testWidgets('same suggestion does not return after dismiss', (tester) async {
    final container = await pumpCard(tester, profile: evidenceProfile());
    expect(find.text('OR ile Aç'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('OR ile Aç'), findsNothing);
    expect(container.read(oracleNextActionProvider), isNull);
  });
}
