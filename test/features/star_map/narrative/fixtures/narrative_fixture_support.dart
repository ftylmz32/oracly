/// Shared fake provenance / metadata for narrative evidence fixtures.
library;

import 'package:oracly_new/features/birth_chart/astronomy/astronomical_provenance.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_calculation_metadata.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_house_system.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_placement.dart';
import 'package:oracly_new/features/birth_chart/astronomy/astronomical_fact_certainty.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_body.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';

AstronomicalProvenance get narrativeTestProvenance =>
    const AstronomicalProvenance(
      engineId: 'test',
      engineVersion: '0',
      calculationVersion: 'test-v1',
      evidenceFingerprint: 'test-fp',
      zodiacSystem: 'tropical',
      coordinateConvention: 'ecliptic',
    );

NatalCalculationMetadata get narrativeTestMeta => NatalCalculationMetadata(
      calculationVersion: 'test-v1',
      engineId: 'fake',
      engineVersion: '0',
      evidenceFingerprint: 'test-fp',
      houseSystem: NatalHouseSystem.wholeSign,
      zodiacSystem: 'tropical',
      coordinateConvention: 'ecliptic',
      utcInstantIso: '1990-05-15T12:00:00Z',
    );

NatalPlacement narrativePlacement({
  required NatalBody body,
  required ZodiacSignId? sign,
  required AstronomicalFactCertainty certainty,
  double? degree,
  bool? retro,
  int? house,
  double? lon,
}) =>
    NatalPlacement(
      body: body,
      sign: sign,
      certainty: certainty,
      provenance: narrativeTestProvenance,
      degreeWithinSign: degree,
      retrograde: retro,
      house: house,
      longitude: lon,
    );
