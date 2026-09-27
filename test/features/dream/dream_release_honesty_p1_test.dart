/// P1 — Dream release wording matches local / fail-closed / live AI.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/data/dream_record_mapper.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/models/dream_provenance.dart';
import 'package:oracly_new/features/dream/services/dream_reading_provenance.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_intro.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';

import 'dream_honesty_fakes.dart';
import 'dream_phase2_support.dart';
import '../../support/dream_test_owner.dart';

const _narrative = 'Rüyamda sessiz bir ev ve açık bir pencere vardı.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('capability notes stay Önizleme and never claim diagnosis', () {
    expect(
      DreamCopy.capabilityNote(
        aiConfigured: false,
        allowsLocalFallback: true,
      ),
      DreamCopy.previewNote,
    );
    expect(DreamCopy.previewNote.toLowerCase(), contains('katalog'));
    expect(
      DreamCopy.capabilityNote(
        aiConfigured: true,
        allowsLocalFallback: false,
      ),
      DreamCopy.previewNoteLive,
    );
    expect(DreamCopy.previewNoteLive.toLowerCase(), isNot(contains('katalog')));
    expect(
      DreamCopy.capabilityNote(
        aiConfigured: false,
        allowsLocalFallback: false,
      ),
      DreamCopy.previewNoteNeedsOr,
    );
    expect(DreamCopy.previewNote, contains('Önizleme'));
    expect(DreamCopy.previewNoteLive.toLowerCase(), isNot(contains('önizleme')));
    expect(DreamCopy.previewNoteLive.toLowerCase(), contains('or'));
    expect(DreamCopy.previewNoteNeedsOr, contains('Önizleme'));
    expect(DreamCopy.previewNoteLive.toLowerCase(), isNot(contains('klinik')));
    expect(DreamCopy.previewNoteNeedsOr.toLowerCase(), isNot(contains('tanı')));
  });

  test('dev local fallback is catalogue, not AI', () async {
    final result = await DreamExperienceService(
      repository: MemDreamRepository(),
      owner: testDreamOwner(),
      ai: const UnconfiguredOraclyAiService(allowsLocalFallback: true),
    ).analyze(narrative: _narrative);
    expect(result.dream.fromAi, isFalse);
    expect(result.dream.insights, isNotEmpty);
    expect(
      result.dream.insights.map((i) => i.source).toSet(),
      {DreamInsightSource.local},
    );
    final footnote = DreamCopy.readingFootnote(
      DreamReadingProvenance.of(result.dream),
    );
    expect(footnote, startsWith(DreamCopy.sourceLocal));
    expect(footnote.toLowerCase(), isNot(contains('yapay zek')));
  });

  test('production without proxy fails closed with no fake result', () async {
    const prod = AiRuntimeConfig(environment: AppEnvironment.production);
    expect(prod.isConfigured, isFalse);
    expect(prod.allowsLocalFallback, isFalse);
    final repo = MemDreamRepository();
    await expectLater(
      DreamExperienceService(
        repository: repo,
        owner: testDreamOwner(),
        ai: const UnconfiguredOraclyAiService(),
      ).analyze(narrative: _narrative),
      throwsA(isA<AiRequestException>()),
    );
    expect(await repo.getAll(), isEmpty);
  });

  test('real AI result is labeled AI and keeps source on reopen', () async {
    const prodProxy = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: 'https://api.oracly.app/v1/ai/complete',
    );
    expect(prodProxy.isConfigured, isTrue);
    expect(prodProxy.allowsLocalFallback, isFalse);
    // Phase 4B: a live reading ships only when every required section is
    // accepted AI, so the honest disclosure is AI — never silently mixed.
    final repo = MemDreamRepository();
    final result = await DreamExperienceService(
      repository: repo,
      owner: testDreamOwner(),
      ai: ScriptedDreamAi(phase2AllAccepted),
    ).analyze(narrative: _narrative);
    expect(result.dream.fromAi, isTrue);
    final interpretation = result.dream.insights.firstWhere(
      (i) => i.kind == DreamInsightKind.mainInterpretation,
    );
    expect(interpretation.body, LiveDreamAiStub.interpretation);
    expect(interpretation.source, DreamInsightSource.ai);
    expect(
      DreamReadingProvenance.of(result.dream),
      DreamProvenance.aiOnly,
    );
    expect(
      DreamCopy.readingFootnote(DreamReadingProvenance.of(result.dream)),
      startsWith(DreamCopy.sourceAi),
    );
    final restored = DreamRecordMapper.fromRecord((await repo.getAll()).single);
    expect(restored.fromAi, isTrue);
    expect(
      DreamReadingProvenance.of(restored),
      DreamProvenance.aiOnly,
    );
    expect(
      restored.insights.map((i) => i.body),
      contains(LiveDreamAiStub.interpretation),
    );
  });

  test('Home → Rüya route stays intact', () {
    expect(OraclyRoutes.dream, '/dream');
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.dream)?.routeName,
      OraclyRoutes.dream,
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.dream)?.title,
      'Rüya',
    );
  });

  testWidgets('live intro follows AI availability', (tester) async {
    Future<void> pump(OraclyAiService ai) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [oraclyAiServiceProvider.overrideWithValue(ai)],
          child: const MaterialApp(home: Scaffold(body: DreamReferenceIntro())),
        ),
      );
      await tester.pump();
    }

    await pump(const UnconfiguredOraclyAiService(allowsLocalFallback: true));
    expect(find.text(DreamCopy.previewNote), findsOneWidget);
    await pump(const UnconfiguredOraclyAiService());
    expect(find.text(DreamCopy.previewNoteNeedsOr), findsOneWidget);
    await pump(const LiveDreamAiStub());
    expect(find.text(DreamCopy.previewNoteLive), findsOneWidget);
  });
}
