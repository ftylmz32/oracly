/// P0 — live Home greeting and Universe Map stay honest.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_navigation.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/universe/oracly_universe_realm.dart';
import 'package:oracly_new/features/daily_energy/screens/daily_energy_details_screen.dart';
import 'package:oracly_new/features/daily_ritual/widgets/daily_ritual_card.dart';
import 'package:oracly_new/features/home/reference/home_reference_greeting.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/first_session/tarot_first_reading.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Home greeting is reflective, not supernatural or predictive', () {
    final copy = HomeReferenceGreeting.referenceSubtitle;
    final lower = copy.toLowerCase();
    expect(copy, 'Sakin bir yer. Düşünmek için buradasın.');
    expect(lower, isNot(contains('evren seninle')));
    expect(lower, isNot(contains('konuşmak')));
    expect(lower, isNot(contains('yapay zek')));
    expect(lower, isNot(contains('enerji')));
    expect(lower, isNot(contains('tahmin')));
    expect(lower, isNot(contains('kehanet')));
  });

  testWidgets('live greeting widget does not claim universe messages',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeReferenceGreeting(userName: 'Fatih'),
        ),
      ),
    );
    expect(find.textContaining('Hoş geldin, Fatih'), findsOneWidget);
    expect(find.text(HomeReferenceGreeting.referenceSubtitle), findsOneWidget);
    expect(find.textContaining('evren seninle konuşmak'), findsNothing);
  });

  test('Universe Map daily ritual uses Bugünkü Ayin, not fake energy', () {
    final module = OraclyFeatureRegistry.byId(OraclyFeatureId.dailyEnergy)!;
    expect(module.title, DailyRitualCard.title);
    expect(module.title, isNot('Günlük Enerji'));
    expect(module.subtitle, 'Kart ve yansıma');
    expect(module.isLive, isTrue);
    expect(
      OraclyFeatureRegistry.forRealm(OraclyUniverseRealm.explore)
          .map((m) => m.id),
      contains(OraclyFeatureId.dailyEnergy),
    );
    expect(OraclyFeatureNavigation.canOpen(OraclyFeatureId.dailyEnergy), isTrue);
  });

  testWidgets('Universe Map daily ritual does not open fake energy details',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => OraclyFeatureNavigation.open(
                context,
                OraclyFeatureId.dailyEnergy,
              ),
              child: const Text('open-daily'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-daily'));
    await tester.pump();
    expect(find.byType(DailyEnergyDetailsScreen), findsNothing);
  });

  test('first tarot session is Tek Kart, returning is Üç Kart', () {
    expect(TarotFirstReading.spread, TarotSpreadType.single);
    expect(TarotFirstReading.spread.label, 'Tek Kart');
    expect(TarotSpreadType.threeCard.label, 'Üç Kart');
  });
}
