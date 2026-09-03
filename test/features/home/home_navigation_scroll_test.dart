/// HOME 07 — scroll clearance + Home feature destinations (no new routes).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_navigation.dart';
import 'package:oracly_new/core/navigation/oracly_navigation_service.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_screen.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/discovery_journal/presentation/screens/discovery_journal_screen.dart';
import 'package:oracly_new/features/explore/presentation/explore_reference_screen.dart';
import 'package:oracly_new/features/home/master/home_master_page.dart';
import 'package:oracly_new/features/home/master/home_master_premium.dart';
import 'package:oracly_new/features/palm/presentation/palm_reference_screen.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_screen.dart';
import 'package:oracly_new/features/premium/services/soul_mate_navigation.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_screen.dart';
import 'package:oracly_new/features/tarot/navigation/tarot_module_navigator.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_screen.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:oracly_new/shared/widgets/oracly_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHome(WidgetTester tester) async {
    const size = Size(390, 844);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: MediaQuery(
            data: const MediaQueryData(
              size: size,
              padding: EdgeInsets.only(bottom: 34),
            ),
            child: const HomeMasterPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('modern Home keeps Premium reachable without overflow',
      (tester) async {
    await pumpHome(tester);
    expect(find.byType(ListView), findsNothing);
    expect(tester.takeException(), isNull);
    expect(find.byType(HomeMasterPremium), findsOneWidget);
    if (find.byType(SingleChildScrollView).evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        find.byType(HomeMasterPremium),
        80,
        scrollable: find
            .descendant(
              of: find.byType(HomeMasterPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump();
    }
    final premium = tester.getRect(find.byType(HomeMasterPremium));
    final page = tester.getRect(find.byType(HomeMasterPage));
    expect(page.bottom - premium.bottom,
        greaterThanOrEqualTo(AppLayout.navBarHeight));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home → OR reaches canonical /chat only once', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => OraclyFeatureNavigation.open(
                context,
                OraclyFeatureId.aiChat,
              ),
              child: const Text('or'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('or'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CompanionReferenceScreen), findsOneWidget);

    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    OraclyNavigationService.openChat(nav.context);
    await tester.pump();
    expect(find.byType(CompanionReferenceScreen), findsOneWidget);
    expect(OraclyRoutes.chat, '/chat');

    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CompanionReferenceScreen), findsNothing);
  });

  testWidgets('Home feature opens reach correct screens + no duplicate palm',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    late BuildContext navContext;
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: Builder(
            builder: (context) {
              navContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    OraclyFeatureNavigation.open(navContext, OraclyFeatureId.coffee);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CoffeeReferenceScreen), findsOneWidget);
    Navigator.of(navContext).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    OraclyFeatureNavigation.open(navContext, OraclyFeatureId.palm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PalmReferenceScreen), findsOneWidget);
    OraclyNavigationService.openPalm(navContext);
    await tester.pump();
    expect(find.byType(PalmReferenceScreen), findsOneWidget);
    Navigator.of(navContext).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    OraclyFeatureNavigation.open(navContext, OraclyFeatureId.astrology);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AstrologyReferenceScreen), findsOneWidget);
    Navigator.of(navContext).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    OraclyFeatureNavigation.open(navContext, OraclyFeatureId.starMap);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(StarMapReferenceScreen), findsOneWidget);
    Navigator.of(navContext).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    OraclyFeatureNavigation.open(navContext, OraclyFeatureId.tarot);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TarotModuleNavigator), findsOneWidget);
    Navigator.of(navContext).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    OraclyNavigationService.openPremium(navContext);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PremiumReferenceScreen), findsOneWidget);
    OraclyNavigationService.openPremium(navContext);
    await tester.pump();
    expect(find.byType(PremiumReferenceScreen), findsOneWidget);
    Navigator.of(navContext).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    SoulMateNavigation.open(navContext);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SoulMateDrawScreen), findsOneWidget);
    SoulMateNavigation.open(navContext);
    await tester.pump();
    expect(find.byType(SoulMateDrawScreen), findsOneWidget);
  });

  testWidgets('Home shell tabs — OR Keşfet Günlük Profile',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: 34),
          ),
          child: MaterialApp(
            routes: {
              '/': (_) => const OraclyAppShell(),
              OraclyRoutes.chat: (_) => const CompanionReferenceScreen(),
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byType(OraclyBottomBar), findsOneWidget);
    expect(find.byType(HomeMasterPage), findsOneWidget);

    // Scope is below the shell — use a descendant context.
    final homeCtx = tester.element(find.byType(HomeMasterPage));
    OraclyNavigation.switchToTab(homeCtx, OraclyTab.coffee);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CompanionReferenceScreen), findsWidgets);
    // Dedicated /chat sits above the shell — dismiss before other tabs.
    Navigator.of(tester.element(find.byType(CompanionReferenceScreen))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    OraclyNavigation.switchToTab(
      tester.element(find.byType(HomeMasterPage)),
      OraclyTab.astrology,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ExploreReferenceScreen), findsWidgets);

    OraclyNavigation.switchToTab(homeCtx, OraclyTab.starMap);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DiscoveryJournalScreen), findsWidgets);

    OraclyNavigation.switchToTab(homeCtx, OraclyTab.profile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ProfileReferenceScreen), findsWidgets);

    OraclyNavigation.switchToTab(homeCtx, OraclyTab.home);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(HomeMasterPage), findsOneWidget);
  });
}
