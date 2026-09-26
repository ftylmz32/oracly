/// Phase 8B.1 — real primary-route host harness (legacy opener counted).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/star_map/models/star_map_reading.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator_providers.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_narrative_live_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_primary_leaf_open.dart';

import '../../../test_helpers/provider_scope_harness.dart';

const phase8b1Reading = StarMapReading(
  overview: StarMapOverview(
    whatItSays: 'Calm sky.',
    dominantEnergy: 'Stillness',
    mainMessage: 'Pause.',
  ),
  skyMessage: StarMapSkyMessage(
    today: 'Breathe.',
    interpretation: 'Quiet.',
    advice: 'One step.',
  ),
  karmic: StarMapKarmicReading(
    theme: 'Rest',
    learning: 'Slow.',
    interpretation: 'Note.',
    takeaway: 'Step.',
    promptQuestion: 'What do you need?',
  ),
  planets: [],
  sunLabel: 'Leo',
);

/// Mirrors `StarMapReferenceRoutes._navigating` + counts legacy opens.
class Phase8b1Nav {
  bool navigating = false;
  int legacy = 0;
  Future<void>? route;
  bool routeDone = false;

  void tap(BuildContext context) {
    routeDone = false;
    route = StarMapPrimaryLeafOpen.open(
      context: context,
      reading: phase8b1Reading,
      isNavigating: () => navigating,
      setNavigating: (v) => navigating = v,
      openLegacySky: (_, _, {profile}) => legacy++,
    );
    unawaited(route!.whenComplete(() => routeDone = true));
  }
}

Future<BuildContext> phase8b1PumpHub(
  WidgetTester tester, {
  required LocalStorage storage,
  required YildiznameLiveOrchestrator orch,
}) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    buildProviderScopeHarness(
      storage: storage,
      overrides: [
        yildiznameLiveOrchestratorProvider.overrideWithValue(orch),
      ],
      child: MaterialApp(
        home: Builder(builder: (c) {
          ctx = c;
          return const Scaffold(body: SizedBox.shrink());
        }),
      ),
    ),
  );
  return ctx;
}

/// Pumps the Narrative live host directly with a route-prepared transaction.
Future<void> phase8b1PumpHost(
  WidgetTester tester, {
  required LocalStorage storage,
  required YildiznameLiveOrchestrator orch,
  required YildiznamePreparedLiveExecution prepared,
}) async {
  await tester.pumpWidget(
    buildProviderScopeHarness(
      storage: storage,
      overrides: [yildiznameLiveOrchestratorProvider.overrideWithValue(orch)],
      child: MaterialApp(home: StarMapNarrativeLiveScreen(prepared: prepared)),
    ),
  );
  await phase8b1Advance(tester, frames: 6);
}

Future<void> phase8b1TapRetry(WidgetTester tester) async {
  await tester.tap(find.text(ResilienceCopy.retryAction));
  await phase8b1Advance(tester, frames: 6);
}

/// The one semantic Retry node exposed by `OraclyErrorState`.
Finder phase8b1RetryNode(String label) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.button == true &&
          w.properties.label == label,
    );

/// Advances route transition + async orchestration without settling loops.
Future<void> phase8b1Advance(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
