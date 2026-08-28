/// Guard: production Home must render once - no capture/share/preview overlay.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/discovery_share/widgets/discovery_share_action.dart';
import 'package:oracly_new/features/home/home_page.dart';
import 'package:oracly_new/features/home/master/home_master_body.dart';
import 'package:oracly_new/features/home/master/home_master_grid.dart';
import 'package:oracly_new/features/home/master/home_master_hero.dart';
import 'package:oracly_new/features/home/master/home_master_or.dart';
import 'package:oracly_new/features/home/master/home_master_page.dart';
import 'package:oracly_new/features/home/master/home_master_premium.dart';
import 'package:oracly_new/features/home/master/home_master_today.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  testWidgets('canonical Home renders exactly once without capture overlay', (
    tester,
  ) async {
    const size = Size(390, 844);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: Scaffold(body: HomePage())),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(HomeMasterPage), findsOneWidget);
    expect(find.byType(HomeMasterBody), findsOneWidget);
    expect(find.byType(HomeMasterHero), findsOneWidget);
    expect(find.byType(HomeMasterOr), findsOneWidget);
    expect(find.byType(HomeMasterToday), findsOneWidget);
    expect(find.byType(HomeMasterGrid), findsOneWidget);
    expect(find.byType(HomeMasterPremium), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byType(ListView), findsNothing);

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(DiscoveryShareAction), findsNothing);
    expect(find.byIcon(Icons.share), findsNothing);
    expect(find.byIcon(Icons.ios_share), findsNothing);
    expect(find.byIcon(Icons.share_outlined), findsNothing);
    expect(find.textContaining('local AI'), findsNothing);
    expect(find.text('Onizleme'), findsNothing);
    expect(find.text('Önizleme'), findsNothing);
    expect(find.textContaining('home_master_reference'), findsNothing);
  });
}
