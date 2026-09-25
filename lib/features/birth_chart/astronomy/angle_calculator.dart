/// Phase 4 — tropical Ascendant / Midheaven (Meeus AA Ch.13).
///
/// θ = local apparent sidereal time
/// ε = true obliquity
/// φ = geographic latitude
///
/// λ_MC = atan2(sin θ, cos θ · cos ε)
/// λ_Asc = atan2(cos θ, −(sin θ · cos ε + tan φ · sin ε))
library;

import 'dart:math' as math;

import 'astronomical_ephemeris_port.dart';
import 'longitude_math.dart';

class AngleLongitudes {
  const AngleLongitudes({required this.ascendant, required this.midheaven});
  final double ascendant;
  final double midheaven;
}

abstract final class AngleCalculator {
  AngleCalculator._();

  static AngleLongitudes compute({
    required AstronomicalEphemerisPort ephemeris,
    required DateTime utc,
    required double latitudeDeg,
    required double longitudeDeg,
  }) {
    final gst = ephemeris.apparentSiderealTime(utc);
    final lst = gst + longitudeDeg * math.pi / 180;
    final theta = _mod2pi(lst);
    final eps = ephemeris.trueObliquity(utc);
    final phi = latitudeDeg * math.pi / 180;

    final sinT = math.sin(theta);
    final cosT = math.cos(theta);
    final sinE = math.sin(eps);
    final cosE = math.cos(eps);
    final tanP = math.tan(phi);

    final mc = math.atan2(sinT, cosT * cosE);
    final asc = math.atan2(cosT, -(sinT * cosE + tanP * sinE));

    return AngleLongitudes(
      ascendant: LongitudeMath.normalize(asc * 180 / math.pi),
      midheaven: LongitudeMath.normalize(mc * 180 / math.pi),
    );
  }

  static double _mod2pi(double r) {
    var x = r % (2 * math.pi);
    if (x < 0) x += 2 * math.pi;
    return x;
  }
}
