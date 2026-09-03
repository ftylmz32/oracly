/// Coffee landing recovery — reference hierarchy, no empty chapter heading.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_cup_hero.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_landing_header.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_landing_view.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:oracly_new/features/discovery_share/widgets/discovery_share_action.dart';
import 'package:oracly_new/shared/widgets/oracly_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('390x844 landing matches target hierarchy without overlays',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          coffeeAnalysisProvider.overrideWithValue(
            const UnavailableCoffeeAnalysis(),
          ),
        ],
        child: const MaterialApp(home: CoffeeReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byType(CoffeeLandingView), findsOneWidget);
    expect(find.byType(CoffeeLandingHeader), findsOneWidget);
    expect(find.byType(CoffeeCupHero), findsOneWidget);
    expect(find.text(CoffeeCopy.landingTitle), findsOneWidget);
    expect(find.textContaining(CoffeeCopy.hubLead), findsOneWidget);
    expect(find.text(CoffeeCopy.photoCta), findsOneWidget);
    expect(find.text(CoffeeCopy.orChoice), findsOneWidget);
    expect(find.text(CoffeeCopy.galleryLabel), findsOneWidget);
    expect(find.text(CoffeeCopy.overallTitle), findsOneWidget);
    expect(find.text(CoffeeCopy.capabilityNote), findsNothing);
    expect(find.byType(OraclyBottomBar), findsNothing);
    expect(find.byType(DiscoveryShareAction), findsNothing);
    expect(find.byIcon(Icons.ios_share), findsNothing);
    expect(find.byIcon(Icons.share_outlined), findsNothing);
    expect(find.byIcon(Icons.share), findsNothing);
    expect(find.text('Ana Sayfa'), findsNothing);
  });
}
