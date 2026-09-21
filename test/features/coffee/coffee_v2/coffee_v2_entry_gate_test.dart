import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_entry_gate.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_flow_screen.dart';
import 'package:oracly_new/features/coffee/coffee_v2/providers/coffee_v2_providers.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';

void main() {
  Widget app({required bool v2, required bool legacy, String? savedId}) {
    return ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(LocalStorage.ephemeral()),
        coffeeHasRecoverableV2SessionProvider.overrideWithValue(v2),
        coffeeHasLegacyPendingOperationProvider.overrideWithValue(legacy),
      ],
      child: MaterialApp(home: CoffeeV2EntryGate(savedReadingId: savedId)),
    );
  }

  testWidgets('recoverable V2 session has priority over legacy pending state', (
    tester,
  ) async {
    await tester.pumpWidget(app(v2: true, legacy: true));
    expect(find.byType(CoffeeV2FlowScreen), findsOneWidget);
    expect(find.byType(CoffeeReferenceScreen), findsNothing);
  });

  testWidgets('legacy pending remains supported when no V2 session exists', (
    tester,
  ) async {
    await tester.pumpWidget(app(v2: false, legacy: true));
    expect(find.byType(CoffeeReferenceScreen), findsOneWidget);
  });

  testWidgets('legacy saved Coffee remains the highest explicit route', (
    tester,
  ) async {
    await tester.pumpWidget(app(v2: true, legacy: true, savedId: 'saved-1'));
    expect(find.byType(CoffeeReferenceScreen), findsOneWidget);
  });

  testWidgets(
    'fresh Coffee falls back to legacy when V2 transport is unavailable',
    (tester) async {
      await tester.pumpWidget(app(v2: false, legacy: false));
      expect(find.byType(CoffeeReferenceScreen), findsOneWidget);
      expect(find.byType(CoffeeV2FlowScreen), findsNothing);
    },
  );
}
