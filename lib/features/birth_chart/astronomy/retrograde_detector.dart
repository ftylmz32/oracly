/// Phase 4 — apparent geocentric retrograde via finite difference.
library;

import 'astronomical_ephemeris_port.dart';
import 'longitude_math.dart';
import 'natal_body.dart';

abstract final class RetrogradeDetector {
  RetrogradeDetector._();

  /// Δ = 12 hours — balances Moon/Mercury motion vs numerical noise.
  static const delta = Duration(hours: 12);

  /// Sun/Moon never labelled retrograde.
  static bool? isRetrograde({
    required AstronomicalEphemerisPort ephemeris,
    required NatalBody body,
    required DateTime utc,
  }) {
    if (body == NatalBody.sun || body == NatalBody.moon) return null;
    final before = ephemeris.longitude(body, utc.subtract(delta));
    final after = ephemeris.longitude(body, utc.add(delta));
    final motion = LongitudeMath.shortestSeparation(after, before);
    return motion < 0;
  }
}
