/// Dream final audit — the real `DreamReferenceScreen` behind a launcher
/// route, over the canonical Phase 1 storage/owner env and a scripted AI.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_screen.dart';
import 'package:oracly_new/features/dream/providers/dream_providers.dart';
import 'package:oracly_new/features/dream/services/dream_voice_input_port.dart';

import '../../test_helpers/provider_scope_harness.dart';
import 'dream_phase1_support.dart';

/// Live AI whose next replies can be scripted as typed failures or as
/// rewritten provider bodies; otherwise a grounded reply.
class FinalAuditAi extends HeldDreamAi {
  final failures = <AiFailure>[];
  final rewrites = <DreamAiAnalysis Function(DreamAiAnalysis)>[];

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) async {
    if (failures.isNotEmpty) {
      calls++;
      narratives.add(context.narrative);
      return AiOutcome.failure(failures.removeAt(0));
    }
    final outcome = await super.analyzeDream(context);
    if (rewrites.isEmpty) return outcome;
    final rewrite = rewrites.removeAt(0);
    return outcome.when(
      success: (analysis) => AiOutcome.success(rewrite(analysis)),
      error: AiOutcome.failure,
    );
  }
}

const openDreamKey = Key('final-audit-open-dream');

/// The launcher's ref — for product calls that take a [WidgetRef].
late WidgetRef launcherRef;

class _Launcher extends ConsumerWidget {
  const _Launcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    launcherRef = ref;
    return _launcherBody(context);
  }

  Widget _launcherBody(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            key: openDreamKey,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DreamReferenceScreen()),
            ),
            child: const Text('open'),
          ),
        ),
      );
}

/// Real provider graph; only the AI and the microphone are replaced.
Future<void> pumpDreamApp(WidgetTester tester, DreamPhase1Env env) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    buildProviderScopeHarness(
      storage: env.storage,
      overrides: [
        oraclyAiServiceProvider.overrideWithValue(env.ai),
        dreamVoiceInputProvider.overrideWithValue(const UnavailableDreamVoiceInput()),
      ],
      child: const MaterialApp(home: _Launcher()),
    ),
  );
  await tester.pump();
}

/// Frames long enough for the organizing pause and async storage.
Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

DreamAnalysisController dreamController(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first))
        .read(dreamAnalysisControllerProvider);

Future<void> openDreamRoute(WidgetTester tester) async {
  await tester.tap(find.byKey(openDreamKey));
  await settle(tester, 6);
}

Future<void> popDreamRoute(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await settle(tester, 6);
}

/// Write → type → submit, through the real widgets.
Future<void> writeAndSubmit(WidgetTester tester, String narrative) async {
  await tester.tap(find.text(DreamCopy.writeDream));
  await settle(tester, 4);
  await tester.enterText(find.byType(TextField).first, narrative);
  await tester.pump();
  final submit = find.text(DreamCopy.submitCta);
  await tester.ensureVisible(submit);
  await tester.pump();
  await tester.tap(submit);
  await settle(tester);
}

Future<void> tapText(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(text),
      240,
      scrollable: find.byType(Scrollable).last,
    );
  }
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await settle(tester);
}
