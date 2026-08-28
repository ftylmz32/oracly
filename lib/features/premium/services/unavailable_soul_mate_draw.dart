/// Fail-closed soul-mate draw — no invented image output.
library;

import '../copy/soul_mate_copy.dart';
import 'soul_mate_draw_port.dart';

class UnavailableSoulMateDraw implements SoulMateDrawPort {
  const UnavailableSoulMateDraw();

  @override
  bool get isAvailable => false;

  @override
  Future<SoulMateDrawResult> draw(SoulMateDrawRequest request) async {
    return SoulMateDrawResult.unavailable(SoulMateCopy.unavailable);
  }
}
