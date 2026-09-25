/// Phase 4 — structured natal evidence payload.
library;

import '../models/chart_fidelity.dart';
import '../models/element_balance.dart';
import '../models/zodiac_sign_id.dart';
import 'natal_angle.dart';
import 'natal_aspect.dart';
import 'natal_calculation_metadata.dart';
import 'natal_house.dart';
import 'natal_house_system.dart';
import 'natal_placement.dart';

class NatalChartEvidence {
  const NatalChartEvidence({
    required this.fidelity,
    required this.metadata,
    required this.placements,
    required this.houses,
    required this.aspects,
    required this.elementBalance,
    required this.modalityBalance,
    this.ascendant,
    this.midheaven,
    this.houseSystem = NatalHouseSystem.wholeSign,
  });

  final ChartCalculationFidelity fidelity;
  final NatalCalculationMetadata metadata;
  final List<NatalPlacement> placements;
  final NatalAngle? ascendant;
  final NatalAngle? midheaven;
  final List<NatalHouse> houses;
  final NatalHouseSystem houseSystem;
  final List<NatalAspect> aspects;
  final ElementBalance elementBalance;
  final Map<ChartModality, int> modalityBalance;

  Map<String, dynamic> toJson() => {
        'fidelity': fidelity.name,
        'metadata': metadata.toJson(),
        'placements': placements.map((p) => p.toJson()).toList(),
        if (ascendant != null) 'ascendant': ascendant!.toJson(),
        if (midheaven != null) 'midheaven': midheaven!.toJson(),
        'houses': houses.map((h) => h.toJson()).toList(),
        'houseSystem': houseSystem.name,
        'aspects': aspects.map((a) => a.toJson()).toList(),
        'elementBalance': elementBalance.toJson(),
        'modalityBalance': {
          for (final e in modalityBalance.entries) e.key.name: e.value,
        },
      };

  factory NatalChartEvidence.fromJson(Map<String, dynamic> json) {
    final modalityRaw = json['modalityBalance'] as Map<String, dynamic>? ?? {};
    return NatalChartEvidence(
      fidelity: ChartCalculationFidelity.values.byName(
        json['fidelity'] as String,
      ),
      metadata: NatalCalculationMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
      placements: (json['placements'] as List<dynamic>? ?? const [])
          .map((e) => NatalPlacement.fromJson(e as Map<String, dynamic>))
          .toList(),
      ascendant: json['ascendant'] != null
          ? NatalAngle.fromJson(json['ascendant'] as Map<String, dynamic>)
          : null,
      midheaven: json['midheaven'] != null
          ? NatalAngle.fromJson(json['midheaven'] as Map<String, dynamic>)
          : null,
      houses: (json['houses'] as List<dynamic>? ?? const [])
          .map((e) => NatalHouse.fromJson(e as Map<String, dynamic>))
          .toList(),
      houseSystem: NatalHouseSystem.values.byName(
        json['houseSystem'] as String? ?? NatalHouseSystem.wholeSign.name,
      ),
      aspects: (json['aspects'] as List<dynamic>? ?? const [])
          .map((e) => NatalAspect.fromJson(e as Map<String, dynamic>))
          .toList(),
      elementBalance: ElementBalance.fromJson(
        json['elementBalance'] as Map<String, dynamic>,
      ),
      modalityBalance: {
        for (final e in modalityRaw.entries)
          ChartModality.values.byName(e.key): (e.value as num).toInt(),
      },
    );
  }
}
