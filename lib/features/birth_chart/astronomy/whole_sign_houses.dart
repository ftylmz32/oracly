/// Phase 4 — Whole Sign houses (≠ Equal House).
library;

import '../models/zodiac_sign_id.dart';
import 'astronomical_fact_certainty.dart';
import 'astronomical_provenance.dart';
import 'longitude_math.dart';
import 'natal_house.dart';
import 'natal_house_system.dart';

abstract final class WholeSignHouses {
  WholeSignHouses._();

  /// Ascendant sign = House 1. Following signs = 2..12. Cusp = 0° of sign.
  static List<NatalHouse> build({
    required ZodiacSignId ascendantSign,
    required AstronomicalProvenance provenance,
  }) {
    final start = ascendantSign.signIndex;
    return List.generate(12, (i) {
      final sign = ZodiacSignId.fromIndex(start + i);
      return NatalHouse(
        number: i + 1,
        sign: sign,
        cuspLongitude: sign.signIndex * 30.0,
        system: NatalHouseSystem.wholeSign,
        certainty: AstronomicalFactCertainty.exact,
        provenance: provenance,
      );
    });
  }

  /// Whole Sign house from planet/angle sign relative to Asc sign.
  static int houseOf({
    required ZodiacSignId bodySign,
    required ZodiacSignId ascendantSign,
  }) {
    final offset = (bodySign.signIndex - ascendantSign.signIndex) % 12;
    return offset + 1;
  }

  /// Equal House would use Asc degree as cusp 1 — wrong for Whole Sign.
  static bool isEqualHouseConfused({
    required double ascLongitude,
    required ZodiacSignId ascSign,
  }) {
    final equalCusp1 = LongitudeMath.normalize(ascLongitude);
    final wholeCusp1 = ascSign.signIndex * 30.0;
    return (equalCusp1 - wholeCusp1).abs() > 0.001;
  }
}
