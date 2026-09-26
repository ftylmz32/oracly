/// Phase 8B.2 — real-route Back harness: counted analytics, push observer,
/// production history hook through Riverpod.
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/star_map/artifacts/local_yildizname_artifact_repository.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator_providers.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_narrative_live_screen.dart';

import '../../../test_helpers/provider_scope_harness.dart';
import 'phase8b1_route_support.dart';
import 'phase8b2_fakes.dart';

export 'phase8b2_fakes.dart';

const phase8b2HubKey = Key('phase8b2-hub');

/// Runs [onPush] synchronously when a route is pushed over the hub, and
/// [afterFirstFrame] at the end of the frame that first builds it.
class Phase8b2PushObserver extends NavigatorObserver {
  void Function()? onPush;
  void Function(NavigatorState navigator)? afterFirstFrame;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null) return;
    final push = onPush;
    final frame = afterFirstFrame;
    onPush = null;
    afterFirstFrame = null;
    push?.call();
    if (frame != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) => frame(navigator!));
    }
  }
}

class Phase8b2Harness {
  Phase8b2Harness(this.storage);

  final LocalStorage storage;
  final nav = Phase8b1Nav();
  final analytics = Phase8b2Analytics();
  final observer = Phase8b2PushObserver();
  int invalidations = 0;
  late BuildContext ctx;

  ProviderContainer get container => ProviderScope.containerOf(ctx);

  /// [build] receives the production history hook, wrapped with a counter.
  Future<void> pump(
    WidgetTester tester,
    YildiznameLiveOrchestrator Function(void Function() onPersisted) build,
  ) async {
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          analyticsServiceProvider.overrideWithValue(analytics),
          yildiznameLiveOrchestratorProvider.overrideWith((ref) {
            final hook = yildiznameArtifactPersistedHook(ref);
            return build(() {
              invalidations++;
              hook();
            });
          }),
        ],
        child: MaterialApp(
          navigatorObservers: [observer],
          home: Builder(builder: (c) {
            ctx = c;
            return const Scaffold(body: SizedBox.shrink(key: phase8b2HubKey));
          }),
        ),
      ),
    );
  }

  void tap() => nav.tap(ctx);

  Future<void> back(WidgetTester tester) async {
    Navigator.of(tester.element(find.byType(StarMapNarrativeLiveScreen)))
        .pop();
    await phase8b1Advance(tester, frames: 6);
  }

  Future<List<YildiznameArtifact>> saved(WidgetTester tester, String owner) =>
      tester
          .runAsync(
            () => LocalYildiznameArtifactRepository(storage, ownerId: owner)
                .getAll(),
          )
          .then((v) => v!);
}
