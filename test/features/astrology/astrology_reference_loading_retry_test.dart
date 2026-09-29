import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/astrology/copy/astrology_presentation_copy.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_screen.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/providers/personal_discovery_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  testWidgets(
    'a stalled optional profile does not hide the local sun-sign hub',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          overrides: [
            personalDiscoveryProfileProvider.overrideWith((ref) {
              return Completer<PersonalDiscoveryProfile>().future;
            }),
          ],
          child: const MaterialApp(home: AstrologyReferenceScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(AstrologyPresentationCopy.detailCta), findsOneWidget);
      expect(find.text(ResilienceCopy.slowResponse), findsNothing);

      await tester.pump(const Duration(seconds: 29));

      expect(find.text(AstrologyPresentationCopy.detailCta), findsOneWidget);
      expect(find.text(ResilienceCopy.slowResponse), findsNothing);
      expect(find.text(ResilienceCopy.retryAction), findsNothing);
    },
  );
}
