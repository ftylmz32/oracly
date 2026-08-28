/// P0 - Live Home must expose OR entry and open /chat.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/home/master/home_master_or.dart';
import 'package:oracly_new/features/home/master/home_master_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHome(
    WidgetTester tester, {
    Size size = const Size(360, 800),
  }) async {
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
            data: MediaQueryData(size: size),
            child: const HomeMasterPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('Home shows OR entry', (tester) async {
    await pumpHome(tester);
    expect(find.byType(HomeMasterOr), findsOneWidget);
    expect(find.textContaining('OR'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping OR opens CompanionReferenceScreen',
      (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byType(HomeMasterOr));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CompanionReferenceScreen), findsOneWidget);
    expect(OraclyRoutes.chat, '/chat');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home OR entry fits KN8-class short portrait', (tester) async {
    await pumpHome(tester, size: const Size(360, 640));
    expect(find.byType(HomeMasterOr), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
