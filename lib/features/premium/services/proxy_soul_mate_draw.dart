/// Soul-mate draw via proxy transport — never calls OpenAI from Flutter.
library;

import '../../ai/production/ai_request_abuse_policy.dart';
import '../../ai/production/ai_request_fingerprint.dart';
import '../../ai/production/ai_request_guard.dart';
import '../../ai/production/openai/openai_paid_requests.dart';
import '../../ai/production/openai/openai_service_results.dart';
import '../../ai/production/transport/ai_transport.dart';
import '../copy/soul_mate_copy.dart';
import 'soul_mate_draw_port.dart';

class ProxySoulMateDraw implements SoulMateDrawPort {
  ProxySoulMateDraw({
    required AiTransport transport,
    AiRequestGuard? guard,
  })  : _transport = transport,
        _guard = guard ?? AiRequestGuard.shared;

  final AiTransport _transport;
  final AiRequestGuard _guard;

  @override
  bool get isAvailable => true;

  @override
  Future<SoulMateDrawResult> draw(SoulMateDrawRequest request) {
    final fp = AiRequestFingerprint.soulMate(
      name: request.name,
      birthDate: _isoDate(request.birthDate),
      gender: request.gender?.name,
      intention: request.intention,
    );
    return _guard.run(
      'soulmate',
      kind: AiRequestKind.soulmate,
      fingerprint: fp,
      limited: () => SoulMateDrawResult.unavailable(SoulMateCopy.unavailable),
      succeeded: (r) => r.hasPortrait,
      () async {
        final outcome = OpenAiServiceResults.soulMate(
          await _transport.execute(
            OpenAiPaidRequests.soulMateDraw(
              name: request.name,
              birthDate: _isoDate(request.birthDate),
              gender: switch (request.gender) {
                SoulMateGenderPref.feminine => 'feminine',
                SoulMateGenderPref.masculine => 'masculine',
                null => null,
              },
              intention: request.intention,
            ),
          ),
        );
        return outcome.when(
          success: (portrait) {
            if (!portrait.hasImage) {
              return SoulMateDrawResult.unavailable(SoulMateCopy.unavailable);
            }
            return SoulMateDrawResult.success(imageBytes: portrait.bytes);
          },
          error: (failure) =>
              SoulMateDrawResult.unavailable(failure.userMessage),
        );
      },
    );
  }

  static String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
