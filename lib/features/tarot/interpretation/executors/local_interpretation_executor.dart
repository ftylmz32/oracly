/// OR-1180 — Content-based interpreter (no external API).
library;

import '../../../insights/services/reflective_intelligence.dart';
import '../formatters/interpretation_formatter.dart';
import '../models/interpretation_request.dart';
import '../models/interpretation_result.dart';
import '../models/interpretation_stream_event.dart';
import 'interpretation_executor.dart';

/// Generates structured interpretations from card catalogue content.
/// EPIC-013 — reflective, observational tone (not fortune-telling).
class LocalInterpretationExecutor implements InterpretationExecutor {
  LocalInterpretationExecutor({InterpretationFormatter? formatter})
      : _formatter = formatter ?? const InterpretationFormatter();

  final InterpretationFormatter _formatter;

  @override
  bool get isOnline => true;

  @override
  Future<InterpretationResult> execute(InterpretationRequest request) async {
    final result = ReflectiveIntelligence.guard(
      ReflectiveIntelligence.synthesize(
        context: request.context,
        requestId: request.requestId,
      ),
    );
    final raw = _formatter.toMarkdown(result);
    return result.copyWith(rawText: raw);
  }

  @override
  Stream<InterpretationStreamEvent> executeStream(
    InterpretationRequest request,
  ) async* {
    yield const InterpretationStreamEvent(
      phase: InterpretationStreamPhase.started,
      progress: 0,
    );

    final sections = ReflectiveIntelligence.guard(
      ReflectiveIntelligence.synthesize(
        context: request.context,
        requestId: request.requestId,
      ),
    ).sections;
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final words = section.content.split(' ');
      final buffer = StringBuffer();
      for (var w = 0; w < words.length; w++) {
        buffer.write('${words[w]} ');
        yield InterpretationStreamEvent(
          phase: InterpretationStreamPhase.sectionPartial,
          sectionKey: section.key,
          partialText: buffer.toString().trim(),
          progress: (i + (w + 1) / words.length) / sections.length,
        );
        await Future<void>.delayed(const Duration(milliseconds: 8));
      }
      yield InterpretationStreamEvent(
        phase: InterpretationStreamPhase.sectionComplete,
        sectionKey: section.key,
        progress: (i + 1) / sections.length,
      );
    }

    final finalResult = await execute(request);
    yield InterpretationStreamEvent(
      phase: InterpretationStreamPhase.completed,
      result: finalResult,
      progress: 1,
    );
  }
}
