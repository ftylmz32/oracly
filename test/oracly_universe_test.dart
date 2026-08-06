import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/universe/oracly_living_event.dart';
import 'package:oracly_new/core/universe/oracly_moon_phase.dart';
import 'package:oracly_new/core/universe/oracly_ritual_time.dart';
import 'package:oracly_new/core/universe/oracly_season.dart';
import 'package:oracly_new/core/universe/oracly_universe_state.dart';

void main() {
  group('OraclyRitualTime', () {
    test('maps hours to four ritual windows', () {
      expect(OraclyRitualAtmosphere.fromHour(6), OraclyRitualTime.morning);
      expect(OraclyRitualAtmosphere.fromHour(14), OraclyRitualTime.afternoon);
      expect(OraclyRitualAtmosphere.fromHour(19), OraclyRitualTime.evening);
      expect(OraclyRitualAtmosphere.fromHour(23), OraclyRitualTime.night);
    });

    test('atmospheric values stay within subtle bounds', () {
      for (final time in OraclyRitualTime.values) {
        expect(
          OraclyRitualAtmosphere.atmosphericIntensity(time),
          inInclusiveRange(0.90, 1.06),
        );
        expect(
          OraclyRitualAtmosphere.particleDensity(time),
          inInclusiveRange(0.86, 1.08),
        );
      }
    });
  });

  group('OraclyMoonLighting', () {
    test('illumination cycles between dark and full', () {
      var minIllumination = 1.0;
      var maxIllumination = 0.0;
      for (var day = 0; day < 30; day++) {
        final value = OraclyMoonLighting.illumination(
          DateTime.utc(2000, 1, 6).add(Duration(days: day)),
        );
        minIllumination = value < minIllumination ? value : minIllumination;
        maxIllumination = value > maxIllumination ? value : maxIllumination;
      }
      expect(minIllumination, lessThan(0.08));
      expect(maxIllumination, greaterThan(0.92));
    });
  });

  group('OraclySeasonalPalette', () {
    test('maps months to seasons', () {
      expect(OraclySeasonalPalette.fromMonth(4), OraclySeason.spring);
      expect(OraclySeasonalPalette.fromMonth(7), OraclySeason.summer);
      expect(OraclySeasonalPalette.fromMonth(10), OraclySeason.autumn);
      expect(OraclySeasonalPalette.fromMonth(1), OraclySeason.winter);
    });
  });

  group('OraclyLivingEvent', () {
    test('roughly one in seven days carries a rare event', () {
      var eventDays = 0;
      for (var day = 1; day <= 365; day++) {
        final event = OraclyLivingEvent.resolve(
          DateTime(2026, 1, 1).add(Duration(days: day - 1)),
        );
        if (event != null) eventDays++;
      }
      expect(eventDays, inInclusiveRange(40, 70));
    });

    test('shooting star only appears in evening or night windows', () {
      for (var day = 1; day <= 60; day++) {
        final morning = OraclyLivingEvent.resolve(DateTime(2026, 1, day, 8));
        final afternoon = OraclyLivingEvent.resolve(DateTime(2026, 1, day, 14));
        final evening = OraclyLivingEvent.resolve(DateTime(2026, 1, day, 20));
        final night = OraclyLivingEvent.resolve(DateTime(2026, 1, day, 23));

        for (final event in [morning, afternoon]) {
          expect(event?.kind, isNot(OraclyLivingEventKind.shootingStar));
        }
        for (final event in [evening, night]) {
          if (event?.kind == OraclyLivingEventKind.shootingStar) {
            expect(event, isNotNull);
          }
        }
      }
    });
  });

  group('OraclyUniverseModulation', () {
    test('never pushes opacity beyond readable bounds', () {
      final state = OraclyUniverseState.current(DateTime(2026, 8, 2, 20, 30));
      final env = state.modulation;

      expect(env.veilOpacity(0.9), inInclusiveRange(0.0, 1.0));
      expect(env.particleOpacity(0.7), inInclusiveRange(0.0, 1.0));
      expect(env.crystalOpacity(0.5), inInclusiveRange(0.0, 1.0));
      expect(env.atmosphericOpacity(0.8), inInclusiveRange(0.0, 1.0));
      expect(env.warmthBlendFactor(), inInclusiveRange(0.42, 0.58));
    });
  });
}
