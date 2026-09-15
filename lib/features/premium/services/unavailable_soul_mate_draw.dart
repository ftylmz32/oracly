/// Fail-closed soul-mate draw — no invented image output.
library;

import '../../ai/production/ai_failure.dart';
import '../copy/soul_mate_copy.dart';
import 'soul_mate_draw_port.dart';
import 'soul_mate_generation_policy.dart';

class UnavailableSoulMateDraw implements SoulMateDrawPort {
  const UnavailableSoulMateDraw();

  @override
  bool get isAvailable => false;

  @override
  Future<SoulMateDrawResult> draw(SoulMateDrawRequest request) async {
    return SoulMateDrawResult.unavailable(
      SoulMateCopy.unavailable,
      failureKind: SoulMateFailureKind.unavailable,
      aiKind: AiFailureKind.noConfiguration,
    );
  }
}
