/// SPRINT-002 — Natal chart calculator (ephemeris-ready foundation).
library;

import '../models/aspect.dart';
import '../models/birth_chart.dart';
import '../models/birth_profile.dart';
import '../models/dominant_energy.dart';
import '../models/element_balance.dart';
import '../models/house.dart';
import '../models/planet.dart';
import '../models/zodiac_sign_id.dart';
import 'chart_calculation_port.dart';

class NatalChartCalculator implements ChartCalculationPort {
  const NatalChartCalculator();

  static final _moonEpoch = DateTime.utc(2000, 1, 6, 18, 14);

  @override
  BirthChart calculate(BirthProfile profile) {
    final id = 'chart_${profile.birthDate.millisecondsSinceEpoch}';
    final hasTime = profile.hasKnownTime;
    final lat = profile.latitude ?? _approxLatitude(profile.birthPlace);
    final lon = profile.longitude ?? _approxLongitude(profile.birthPlace);

    final sunSign = ZodiacSignId.fromDate(profile.birthDate);
    final sunDegree = _degreeInSign(profile.birthDate, sunSign);
    final moonLong = _moonLongitude(profile.birthDate, profile.birthTime);
    final moonSign = _signFromLongitude(moonLong);
    final moonDegree = moonLong % 30;

    final ascLong = hasTime
        ? _ascendantLongitude(
            profile.birthDate,
            profile.birthTime!,
            lat,
            lon,
          )
        : null;
    final risingSign =
        ascLong != null ? _signFromLongitude(ascLong) : null;
    final risingDegree = ascLong != null ? ascLong % 30 : null;

    final planetLongitudes = _planetLongitudes(profile.birthDate, sunSign);

    final houses = ascLong != null
        ? _buildHouses(ascLong)
        : _buildHousesFromSun(sunSign);

    Planet buildPlanet(PlanetId id, double longitude) {
      final sign = _signFromLongitude(longitude);
      final house = _houseForLongitude(longitude, houses);
      return Planet(
        id: id,
        sign: sign,
        degree: longitude % 30,
        house: house,
      );
    }

    final sun = Planet(
      id: PlanetId.sun,
      sign: sunSign,
      degree: sunDegree,
      house: _houseForSign(sunSign, houses),
    );
    final moon = Planet(
      id: PlanetId.moon,
      sign: moonSign,
      degree: moonDegree,
      house: _houseForSign(moonSign, houses),
    );
    final rising = risingSign != null && risingDegree != null
        ? Planet(
            id: PlanetId.ascendant,
            sign: risingSign,
            degree: risingDegree,
            house: 1,
          )
        : null;

    final planets = <Planet>[
      for (final entry in planetLongitudes.entries)
        buildPlanet(entry.key, entry.value),
    ];

    final aspects = _detectAspects([
      sun,
      moon,
      ...planets,
    ]);

    final elementBalance = _elementBalance([
      sun,
      moon,
      if (rising != null)
        Planet(
          id: PlanetId.ascendant,
          sign: rising.sign,
          degree: rising.degree,
          house: 1,
        ),
      ...planets.take(5),
    ]);

    final dominantEnergy = _dominantEnergy(elementBalance, [
      sun.sign,
      moon.sign,
      if (rising != null) rising.sign,
      ...planets.take(3).map((p) => p.sign),
    ]);

    return BirthChart(
      id: id,
      profile: profile.copyWith(
        latitude: lat,
        longitude: lon,
      ),
      sun: sun,
      moon: moon,
      rising: rising,
      planets: planets,
      houses: houses,
      aspects: aspects,
      elementBalance: elementBalance,
      dominantEnergy: dominantEnergy,
      lifeThemes: const [],
      insights: const [],
      generatedAt: DateTime.now(),
      precision: hasTime ? ChartPrecision.full : ChartPrecision.partialNoTime,
    );
  }

  double _degreeInSign(DateTime date, ZodiacSignId sign) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return (dayOfYear % 30) + (sign.signIndex * 0.7);
  }

  double _moonLongitude(DateTime date, DateTime? time) {
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 12,
      time?.minute ?? 0,
    ).toUtc();
    final days = dt.difference(_moonEpoch).inMinutes / 1440.0;
    return (days * 13.176396472) % 360;
  }

  double _ascendantLongitude(
    DateTime date,
    DateTime time,
    double lat,
    double lon,
  ) {
    final hour = time.hour + time.minute / 60.0;
    final sunSign = ZodiacSignId.fromDate(date);
    final base = sunSign.signIndex * 30.0;
    final offset = (hour - 6) * 15 + lon / 4 + lat / 3;
    return (base + offset) % 360;
  }

  Map<PlanetId, double> _planetLongitudes(
    DateTime date,
    ZodiacSignId sunSign,
  ) {
    final sunBase = sunSign.signIndex * 30.0;
    final y = date.year;
    final m = date.month;
    return {
      PlanetId.mercury: (sunBase + ((m % 3) - 1) * 28 + 360) % 360,
      PlanetId.venus: (sunBase + ((y % 5) - 2) * 22 + 360) % 360,
      PlanetId.mars: ((y - 2000) * 12.0 + m * 2) % 360,
      PlanetId.jupiter: ((y - 2000) * 30.0 + m) % 360,
      PlanetId.saturn: ((y - 2000) * 12.0 + m * 0.5) % 360,
      PlanetId.uranus: ((y - 2010) / 7 * 30 + sunBase * 0.3) % 360,
      PlanetId.neptune: ((y - 2011) / 14 * 30 + sunBase * 0.2) % 360,
      PlanetId.pluto: ((y - 2008) / 20 * 30 + sunBase * 0.15) % 360,
    };
  }

  List<House> _buildHouses(double ascLong) {
    return [
      for (var i = 0; i < 12; i++)
        House(
          number: i + 1,
          sign: _signFromLongitude(ascLong + i * 30),
          cuspDegree: (ascLong + i * 30) % 360,
        ),
    ];
  }

  List<House> _buildHousesFromSun(ZodiacSignId sun) {
    final base = sun.signIndex * 30.0;
    return [
      for (var i = 0; i < 12; i++)
        House(
          number: i + 1,
          sign: _signFromLongitude(base + i * 30),
          cuspDegree: (base + i * 30) % 360,
        ),
    ];
  }

  int _houseForLongitude(double longitude, List<House> houses) {
    for (final house in houses) {
      final next = (house.cuspDegree + 30) % 360;
      if (house.cuspDegree <= next) {
        if (longitude >= house.cuspDegree && longitude < next) {
          return house.number;
        }
      } else if (longitude >= house.cuspDegree || longitude < next) {
        return house.number;
      }
    }
    return 1;
  }

  int _houseForSign(ZodiacSignId sign, List<House> houses) {
    for (final house in houses) {
      if (house.sign == sign) return house.number;
    }
    return sign.signIndex % 12 + 1;
  }

  List<Aspect> _detectAspects(List<Planet> bodies) {
    final aspects = <Aspect>[];
    for (var i = 0; i < bodies.length; i++) {
      for (var j = i + 1; j < bodies.length; j++) {
        final a = bodies[i];
        final b = bodies[j];
        final longA = a.sign.signIndex * 30 + a.degree;
        final longB = b.sign.signIndex * 30 + b.degree;
        var delta = (longA - longB).abs();
        if (delta > 180) delta = 360 - delta;

        for (final type in AspectType.values) {
          final orb = (delta - type.angle).abs();
          if (orb <= type.defaultOrb) {
            aspects.add(
              Aspect(
                planetA: a.id,
                planetB: b.id,
                type: type,
                orb: orb,
              ),
            );
            break;
          }
        }
      }
    }
    return aspects;
  }

  ElementBalance _elementBalance(List<Planet> bodies) {
    var fire = 0, earth = 0, air = 0, water = 0;
    for (final body in bodies) {
      switch (_elementOf(body.sign)) {
        case ChartElement.fire:
          fire++;
        case ChartElement.earth:
          earth++;
        case ChartElement.air:
          air++;
        case ChartElement.water:
          water++;
      }
    }
    return ElementBalance(fire: fire, earth: earth, air: air, water: water);
  }

  DominantEnergy _dominantEnergy(
    ElementBalance balance,
    List<ZodiacSignId> signs,
  ) {
    final modalityCounts = {
      ChartModality.cardinal: 0,
      ChartModality.fixed: 0,
      ChartModality.mutable: 0,
    };
    for (final sign in signs) {
      modalityCounts[_modalityOf(sign)] =
          (modalityCounts[_modalityOf(sign)] ?? 0) + 1;
    }
    final topModality = modalityCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    final elementLabel = balance.dominantLabelTr();
    final modalityLabel = switch (topModality) {
      ChartModality.cardinal => 'Öncü',
      ChartModality.fixed => 'Sabit',
      ChartModality.mutable => 'Değişken',
    };

    return DominantEnergy(
      primaryElement: balance.dominant,
      primaryModality: topModality,
      label: '$elementLabel + $modalityLabel',
      summary:
          'Haritanda $elementLabel elementi ve $modalityLabel enerji öne çıkıyor. '
          'Bu, dünyaya yaklaşımında doğal bir eğilim olabilir — '
          'kesin bir karakter tanımı değil.',
    );
  }

  ZodiacSignId _signFromLongitude(double longitude) {
    return ZodiacSignId.fromIndex((longitude / 30).floor());
  }

  ChartElement _elementOf(ZodiacSignId sign) {
    return switch (sign) {
      ZodiacSignId.aries ||
      ZodiacSignId.leo ||
      ZodiacSignId.sagittarius =>
        ChartElement.fire,
      ZodiacSignId.taurus ||
      ZodiacSignId.virgo ||
      ZodiacSignId.capricorn =>
        ChartElement.earth,
      ZodiacSignId.gemini ||
      ZodiacSignId.libra ||
      ZodiacSignId.aquarius =>
        ChartElement.air,
      ZodiacSignId.cancer ||
      ZodiacSignId.scorpio ||
      ZodiacSignId.pisces =>
        ChartElement.water,
    };
  }

  ChartModality _modalityOf(ZodiacSignId sign) {
    return switch (sign) {
      ZodiacSignId.aries ||
      ZodiacSignId.cancer ||
      ZodiacSignId.libra ||
      ZodiacSignId.capricorn =>
        ChartModality.cardinal,
      ZodiacSignId.taurus ||
      ZodiacSignId.leo ||
      ZodiacSignId.scorpio ||
      ZodiacSignId.aquarius =>
        ChartModality.fixed,
      ZodiacSignId.gemini ||
      ZodiacSignId.virgo ||
      ZodiacSignId.sagittarius ||
      ZodiacSignId.pisces =>
        ChartModality.mutable,
    };
  }

  double _approxLatitude(String place) {
    final hash = place.toLowerCase().codeUnits.fold(0, (a, b) => a + b);
    return 36 + (hash % 600) / 100;
  }

  double _approxLongitude(String place) {
    final hash = place.hashCode.abs();
    return 26 + (hash % 1600) / 100;
  }
}

extension on BirthProfile {
  BirthProfile copyWith({
    double? latitude,
    double? longitude,
  }) {
    return BirthProfile(
      birthDate: birthDate,
      birthPlace: birthPlace,
      birthTime: birthTime,
      birthTimeKnown: birthTimeKnown,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
