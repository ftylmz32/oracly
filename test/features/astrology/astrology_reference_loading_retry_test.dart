import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_screen.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/providers/personal_discovery_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  testWidgets(
    'Astrology hub offers a retry once the shared profile provider stalls '
    'past the failsafe window',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();

      var buildCount = 0;
      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          overrides: [
            // Simulate a shared personalDiscoveryProfileProvider that never
            // resolves (and never errors) — the exact stall scenario this
            // test guards against.
            personalDiscoveryProfileProvider.overrideWith((ref) {
              buildCount++;
              return Completer<PersonalDiscoveryProfile>().future;
            }),
          ],
          child: const MaterialApp(home: AstrologyReferenceScreen()),
        ),
      );
      await tester.pump();

      // Before the failsafe window: honest loading stage, no retry yet.
      expect(find.text(ResilienceCopy.slowResponse), findsNothing);

      // Advance past OraclyLoadingCinema's slowAfter (28s) failsafe window.
      await tester.pump(const Duration(seconds: 29));

      expect(find.text(ResilienceCopy.slowResponse), findsOneWidget);
      final retryButton = find.text(ResilienceCopy.retryAction);
      expect(
        retryButton,
        findsOneWidget,
        reason: 'A stalled shared profile provider must not leave the user '
            'with a silent, un-escapable spinner — a retry action must be '
            'offered once the failsafe window elapses.',
      );

      final buildsBeforeRetry = buildCount;
      await tester.tap(retryButton);
      await tester.pump();

      // Tapping retry must invalidate/recreate the stalled provider.
      expect(buildCount, greaterThan(buildsBeforeRetry));
    },
  );
}
