/// SPRINT-002 — Element distribution across chart.
library;

import 'zodiac_sign_id.dart';

class ElementBalance {
  const ElementBalance({
    required this.fire,
    required this.earth,
    required this.air,
    required this.water,
  });

  final int fire;
  final int earth;
  final int air;
  final int water;

  int get total => fire + earth + air + water;

  ChartElement get dominant {
    final entries = {
      ChartElement.fire: fire,
      ChartElement.earth: earth,
      ChartElement.air: air,
      ChartElement.water: water,
    };
    return entries.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String dominantLabelTr() {
    return switch (dominant) {
      ChartElement.fire => 'Ateş',
      ChartElement.earth => 'Toprak',
      ChartElement.air => 'Hava',
      ChartElement.water => 'Su',
    };
  }

  Map<String, dynamic> toJson() => {
        'fire': fire,
        'earth': earth,
        'air': air,
        'water': water,
      };

  factory ElementBalance.fromJson(Map<String, dynamic> json) {
    return ElementBalance(
      fire: json['fire'] as int,
      earth: json['earth'] as int,
      air: json['air'] as int,
      water: json['water'] as int,
    );
  }
}
