/// Soulmate text via the authenticated proxy. Never an image call.
library;

import '../../ai/production/ai_request_abuse_policy.dart';
import '../../ai/production/ai_request_guard.dart';
import '../../ai/production/openai/openai_paid_requests.dart';
import '../../ai/production/transport/ai_transport.dart';
import '../data/soul_mate_interpretation_catalogue.dart';
import 'soul_mate_interpretation_context.dart';
import 'soul_mate_interpretation_gate.dart';
import 'soul_mate_interpretation_port.dart';

class ProxySoulMateInterpretation implements SoulMateInterpretationPort {
  ProxySoulMateInterpretation({required this._transport, AiRequestGuard? guard})
    : _guard = guard ?? AiRequestGuard.shared;

  final AiTransport _transport;
  final AiRequestGuard _guard;

  @override
  Future<SoulMateInterpretationOutcome> interpret(
    SoulMateInterpretationContext context,
  ) {
    return _guard.run(
      'soulmate-text',
      kind: AiRequestKind.soulmateText,
      fingerprint: context.signature(),
      limited: () => const SoulMateInterpretationOutcome.failed(),
      succeeded: (r) => r.hasText,
      () async {
        final outcome = await _transport.execute(
          OpenAiPaidRequests.soulMateInterpretation(
            name: context.name,
            birthDate: context.birthDate,
            gender: context.gender,
            intention: context.intention,
            identity: context.identity?.toJson(),
            memorySummary: context.memorySummary,
          ),
        );
        return outcome.when(
          success: (data) => _accept(data, context),
          error: (failure) =>
              SoulMateInterpretationOutcome.failed(aiKind: failure.kind),
        );
      },
    );
  }

  SoulMateInterpretationOutcome _accept(
    Map<String, dynamic> data,
    SoulMateInterpretationContext context,
  ) {
    if (data['operation'] == 'soulmate_draw') {
      return const SoulMateInterpretationOutcome.failed();
    }
    final draft = SoulMateInterpretationDraft(
      personality: _text(data['personality']),
      dynamic: _text(data['dynamic']),
      attraction: _text(data['attraction']),
      challenge: _text(data['challenge']),
      meeting: _text(data['meeting']),
      feeling: _text(data['feeling']),
    );
    if (draft.values.any((v) => v.isEmpty)) {
      return const SoulMateInterpretationOutcome.failed();
    }
    final rejected = SoulMateInterpretationGate.assess(
      draft,
      name: context.name,
      presence: context.identity?.presence,
    );
    if (rejected != null) return const SoulMateInterpretationOutcome.failed();
    return SoulMateInterpretationOutcome.success(
      SoulMateReadingParts(
        energy: draft.personality,
        attraction: draft.attraction,
        dynamics: draft.dynamic,
        feeling: draft.feeling,
        yourSide: draft.challenge,
        meeting: draft.meeting,
        authoritative: true,
      ),
    );
  }

  static String _text(Object? value) => value is String ? value.trim() : '';
}
