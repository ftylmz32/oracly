/// Dream Phase 2 — scripted AI replies for provenance / language tests.
library;

import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';

import 'dream_honesty_fakes.dart';

const phase2Narrative = 'Rüyamda sessiz bir ev ve açık bir pencere vardı.';

/// Every field grounded in [phase2Narrative] — survives the client guard.
const phase2AllAccepted = DreamAiAnalysis(
  summary: 'Sessiz ev ile açık pencere, sakin bir bekleyişi birlikte taşıyor.',
  symbols: ['Sessiz bir ev', 'Açık bir pencere'],
  emotionalTheme:
      'Sessiz evde açık pencerenin getirdiği dingin bir merak hissediliyor.',
  interpretation: LiveDreamAiStub.interpretation,
  dailyLifeReflection:
      'Bugün evinde sessiz bir köşe bulup pencereyi açmak iyi gelebilir.',
  conclusion: 'Açık pencereden içeri ne girmesini isterdin?',
);

/// Every field fails the guard — unrelated, thin, or not a question.
const phase2AllRejected = DreamAiAnalysis(
  summary: 'Kısa.',
  symbols: [],
  emotionalTheme: '',
  interpretation:
      'Deniz fenerinin ışığı uzaklardaki gemilere yol gösteriyor ve limana dönüşü anlatıyor.',
  dailyLifeReflection: '',
  conclusion: 'Tamam.',
);

/// Live-configured AI returning [reply]; records every request context and
/// can run [midFlight] while the request is outstanding.
class ScriptedDreamAi extends LiveDreamAiStub {
  ScriptedDreamAi(this.reply, {this.midFlight});

  final DreamAiAnalysis reply;
  final void Function()? midFlight;
  final contexts = <DreamAiContext>[];

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(
    DreamAiContext context,
  ) async {
    contexts.add(context);
    midFlight?.call();
    return AiOutcome.success(reply);
  }
}
