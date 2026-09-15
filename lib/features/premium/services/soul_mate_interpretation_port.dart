/// Text-only Soulmate reading. Never starts an image generation.
library;

import '../../ai/production/ai_failure.dart';
import '../data/soul_mate_interpretation_catalogue.dart';
import 'soul_mate_interpretation_context.dart';

class SoulMateInterpretationOutcome {
  const SoulMateInterpretationOutcome._({
    this.parts,
    this.failureKind,
    this.aiKind,
  });

  const SoulMateInterpretationOutcome.success(SoulMateReadingParts parts)
      : this._(parts: parts);

  const SoulMateInterpretationOutcome.failed({
    AiFailureKind? aiKind,
  }) : this._(aiKind: aiKind, failureKind: 'text');

  final SoulMateReadingParts? parts;
  final String? failureKind;
  final AiFailureKind? aiKind;

  bool get hasText =>
      parts != null && parts!.energy.trim().isNotEmpty && parts!.feeling.trim().isNotEmpty;
}

abstract class SoulMateInterpretationPort {
  Future<SoulMateInterpretationOutcome> interpret(SoulMateInterpretationContext context);
}

class UnavailableSoulMateInterpretation implements SoulMateInterpretationPort {
  const UnavailableSoulMateInterpretation();

  @override
  Future<SoulMateInterpretationOutcome> interpret(
    SoulMateInterpretationContext context,
  ) async {
    return const SoulMateInterpretationOutcome.failed(
      aiKind: AiFailureKind.noConfiguration,
    );
  }
}
