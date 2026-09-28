/// G1 — Astrology hub: the local sun-sign reading is never hidden by the
/// shared profile, neither by its failure nor by a background refresh.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/astrology/data/astrology_preferences_store.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_hub_body.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_loading_state.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_screen.dart';
import 'package:oracly_new/features/astrology/providers/astrology_providers.dart';
import 'package:oracly_new/features/astrology/services/astrology_sign_resolver.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/providers/personal_discovery_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  Future<void> pumpHub(
    WidgetTester tester,
    Future<PersonalDiscoveryProfile> Function(int build) profile, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final storage = await LocalStorage.open();
    var builds = 0;
    await tester.pumpWidget(buildProviderScopeHarness(
      storage: storage,
      overrides: [
        personalDiscoveryProfileProvider.overrideWith((ref) => profile(++builds)),
      ],
      child: const MaterialApp(home: AstrologyReferenceScreen()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('a background profile refresh keeps the hub on screen',
      (tester) async {
    await pumpHub(
      tester,
      (build) => build == 1
          ? Future.value(PersonalDiscoveryProfile.empty)
          : Completer<PersonalDiscoveryProfile>().future,
    );
    expect(find.byType(AstrologyReferenceHubBody), findsOneWidget);

    // A reading finished elsewhere refreshes every personal-discovery surface.
    ProviderScope.containerOf(tester.element(find.byType(AstrologyReferenceScreen)))
        .invalidate(personalDiscoveryProfileProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AstrologyReferenceHubBody), findsOneWidget);
    expect(find.byType(AstrologyReferenceLoadingState), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a failing profile never blocks the local reading',
      (tester) async {
    await pumpHub(tester, (_) => Future.error(StateError('profile down')));

    expect(find.byType(AstrologyReferenceHubBody), findsOneWidget);
    expect(find.byType(AstrologyReferenceLoadingState), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a corrupt stored sign falls back to the default sign',
      (tester) async {
    await pumpHub(
      tester,
      (_) => Future.value(PersonalDiscoveryProfile.empty),
      prefs: {AstrologyPreferencesStore.signKey: 'not-a-sign'},
    );
    final resolver = ProviderScope.containerOf(
      tester.element(find.byType(AstrologyReferenceScreen)),
    ).read(astrologySignResolverProvider);

    expect(resolver.savedSignId, isNull);
    expect(await resolver.resolve(), AstrologySignResolver.fallbackId);
    expect(find.byType(AstrologyReferenceHubBody), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
