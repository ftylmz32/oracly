import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/core/notifications/reading_push_bootstrap.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_entry_gate.dart';
import 'package:oracly_new/features/palm/presentation/palm_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AccountDeletionPendingState.markClear();
    SharedPreferences.setMockInitialValues({});
  });

  test('completion push identifies the exact Coffee operation', () {
    final id = 'a' * 32;
    final destination = readingPushDestination({
      'type': 'reading_completed',
      'readingType': 'coffee',
      'operationId': id,
    });
    expect(destination?.route, OraclyRoutes.coffee);
    expect(destination?.operationId, id);
  });

  test('completion push identifies the exact Palm operation', () {
    final id = 'b' * 32;
    final destination = readingPushDestination({
      'type': 'reading_completed',
      'readingType': 'palm',
      'operationId': id,
    });
    expect(destination?.route, OraclyRoutes.palm);
    expect(destination?.operationId, id);
  });

  test('non-completion and malformed pushes do not navigate', () {
    expect(readingPushDestination({'type': 'marketing'}), isNull);
    expect(
      readingPushDestination({
        'type': 'reading_completed',
        'readingType': 'coffee',
        'operationId': 'wrong',
      }),
      isNull,
    );
    expect(
      readingPushDestination({
        'type': 'reading_completed',
        'readingType': 'coffee',
        'operationId': 'Z' * 32,
      }),
      isNull,
    );
  });

  testWidgets('Coffee push route forwards its exact operation id', (
    tester,
  ) async {
    final id = 'c' * 32;
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).pushNamed(
                OraclyRoutes.coffee,
                arguments: {'operationId': id},
              ),
              child: const Text('open-coffee'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-coffee'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final gate = tester.widget<CoffeeV2EntryGate>(
      find.byType(CoffeeV2EntryGate),
    );
    expect(gate.operationId, id);
  });

  testWidgets('Palm push route forwards its exact operation id', (
    tester,
  ) async {
    final id = 'd' * 32;
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).pushNamed(
                OraclyRoutes.palm,
                arguments: {'operationId': id},
              ),
              child: const Text('open-palm'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-palm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final screen = tester.widget<PalmReferenceScreen>(
      find.byType(PalmReferenceScreen),
    );
    expect(screen.operationId, id);
  });
}
