/// Dream Phase 2 — scripted AI replies for provenance / language tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';

import 'dream_grounded_reply.dart';
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

/// Configured AI delivery that fails closed: a typed invalid response.
final throwsInvalidDreamResponse = throwsA(isA<AiRequestException>().having(
  (e) => e.failure.kind,
  'kind',
  AiFailureKind.invalidResponse,
));

/// Live-configured AI returning [reply]; records every request context and
/// can run [midFlight] while the request is outstanding.
class ScriptedDreamAi extends LiveDreamAiStub {
  ScriptedDreamAi(DreamAiAnalysis this.reply, {this.midFlight});

  /// Replies with [groundedDreamReply] for whatever the request tells.
  ScriptedDreamAi.grounded({this.midFlight}) : reply = null;

  final DreamAiAnalysis? reply;
  final void Function()? midFlight;
  final contexts = <DreamAiContext>[];

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(
    DreamAiContext context,
  ) async {
    contexts.add(context);
    midFlight?.call();
    return AiOutcome.success(reply ?? groundedDreamReply(context));
  }
}
