// Dream Phase 4B — backend-accepted premium goldens flow through the client
// parser → mapper → composer → guard → provenance as a complete AI reading.
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/dream/services/dream_premium_delivery_quality.dart';

import '../../support/dream_test_owner.dart';
import 'dream_honesty_fakes.dart';
import 'dream_phase2_support.dart';
import 'dream_phase4b_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final goldens = loadDreamGoldens();

  test('at least three goldens per language', () {
    for (final lang in ['tr', 'en', 'ru']) {
      expect(goldens.where((g) => g.language == lang).length,
          greaterThanOrEqualTo(3));
    }
  });

  for (final g in goldens) {
    test('${g.id}: every required section is accepted AI', () async {
      final ai = ScriptedDreamAi(g.analysis);
      final repo = MemDreamRepository();
      final result = await DreamExperienceService(
        repository: repo,
        owner: testDreamOwner(),
        ai: ai,
      ).analyze(narrative: g.narrative);

      expect(ai.contexts, hasLength(1));
      expect(ai.contexts.single.language, g.language);
      final insights = result.dream.insights;
      for (final kind in DreamPremiumDeliveryQuality.required) {
        final section = insights.where((i) => i.kind == kind).single;
        expect(section.source, DreamInsightSource.ai, reason: '$kind');
        expect(section.body.trim(), isNotEmpty, reason: '$kind');
      }
      expect(DreamPremiumDeliveryQuality.accepts(insights), isTrue);
      expect(result.dream.fromAi, isTrue);
      final themes =
          insights.where((i) => i.kind == DreamInsightKind.themes).single;
      expect(themes.source, DreamInsightSource.local);
      expect(await repo.getAll(), hasLength(1));
    });
  }
}
