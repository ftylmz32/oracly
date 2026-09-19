/// Production-path route smoke — every live named route builds without throw.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
  });

  Future<void> pumpRoute(WidgetTester tester, String name) async {
    final errors = <Object>[];
    final old = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exception);
    addTearDown(() => FlutterError.onError = old);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
        ],
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).pushNamed(name),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(errors, isEmpty, reason: 'route $name threw $errors');
  }

  testWidgets('live routes build without FlutterError', (tester) async {
    for (final route in const [
      OraclyRoutes.home,
      OraclyRoutes.settings,
      OraclyRoutes.premium,
      OraclyRoutes.gems,
      OraclyRoutes.dailyRewards,
      OraclyRoutes.dream,
      OraclyRoutes.astrology,
      OraclyRoutes.starMap,
      OraclyRoutes.palm,
      OraclyRoutes.coffee,
      OraclyRoutes.chat,
      OraclyRoutes.readingHistory,
      OraclyRoutes.discoveryJournal,
      OraclyRoutes.myStory,
      OraclyRoutes.favoriteMoments,
      OraclyRoutes.personalInsights,
      OraclyRoutes.dailyMessage,
      OraclyRoutes.about,
      OraclyRoutes.help,
      OraclyRoutes.privacy,
      OraclyRoutes.onboarding,
    ]) {
      await pumpRoute(tester, route);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('reserved achievements deep link recovers to shell', (tester) async {
    await pumpRoute(tester, OraclyRoutes.achievements);
    expect(find.byType(OraclyAppShell), findsOneWidget);
  });

  testWidgets('unknown reserved modules recover to shell', (tester) async {
    for (final route in const [
      OraclyRoutes.numerology,
      OraclyRoutes.moonCalendar,
      OraclyRoutes.manifestation,
    ]) {
      await pumpRoute(tester, route);
      expect(find.byType(OraclyAppShell), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
