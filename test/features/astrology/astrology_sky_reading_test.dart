/// Personal daily astrology: written from real transits to each person's
/// own chart, honest about what it could not calculate.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/astrology/models/astrology_daily_reading.dart';
import 'package:oracly_new/features/astrology/services/astrology_daily_reading_service.dart';
import 'package:oracly_new/features/astrology/sky/astrology_natal_sky.dart';
import 'package:oracly_new/features/astrology/sky/astrology_sky_copy_tr.dart';
import 'package:oracly_new/features/astrology/sky/astrology_transit_engine.dart';
import 'package:oracly_new/features/birth_chart/astronomy/longitude_math.dart';
import 'package:oracly_new/features/content/astrology/data/astrology_content_catalogue.dart';

import 'sky_fixtures.dart';

AstrologyDailyReading _read(SkyPerson p, DateTime day, {String? signId}) =>
    AstrologyDailyReadingService.build(
      AstrologyContentCatalogue.signById(signId ?? p.sky.sunSign.id)!,
      now: day,
      natalSky: p.sky,
      ephemeris: skyEphemeris,
    );

List<DateTime> _days(int n) =>
    [for (var i = 0; i < n; i++) DateTime(2026, 10, 1).add(Duration(days: i))];

List<String> _lanes(AstrologyDailyReading r) => [
      r.overall,
      r.love,
      r.career,
      r.money,
      r.emotion,
      r.energy,
      r.opportunity,
      r.caution,
      r.advice,
      r.personality,
    ];

List<String> _sentences(String text) => text
    .split(RegExp(r'(?<=[^0-9][.?!])\s+'))
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('three synthetic people resolve to the expected charts', () {
    expect(ayse.sky.sunSign.id, 'aries');
    expect(ayse.sky.depth, NatalSkyDepth.full);
    expect(mehmet.sky.sunSign.id, 'aries');
    expect(mehmet.sky.depth, NatalSkyDepth.dayOnly);
    expect(zeynep.sky.sunSign.id, 'libra');
    expect(zeynep.sky.depth, NatalSkyDepth.full);
  });

  group('same sign, different people', () {
    test('two Aries readers get different, data-grounded readings', () {
      final day = DateTime(2026, 10, 20);
      final a = _read(ayse, day);
      final m = _read(mehmet, day);
      for (final pair in [
        (a.overall, m.overall),
        (a.love, m.love),
        (a.career, m.career),
        (a.money, m.money),
        (a.personality, m.personality),
      ]) {
        expect(pair.$1, isNot(pair.$2));
      }
      // Not a name swap: the natal facts named in the text differ.
      expect(a.personality, contains('Ay Boğa'));
      expect(m.personality, isNot(contains('Ay ')));
      expect(a.basis, AstrologyReadingBasis.skyFull);
      expect(m.basis, AstrologyReadingBasis.skyDayOnly);
    });

    test('over a month the two Aries readers almost never coincide', () {
      var same = 0;
      for (final day in _days(30)) {
        if (_read(ayse, day).overall == _read(mehmet, day).overall) same++;
      }
      expect(same, 0);
    });
  });

  group('every stated aspect is real', () {
    test('engine hits lie within orb of their aspect angle', () {
      for (final p in skyPeople) {
        for (final day in _days(30)) {
          final sky = AstrologyTransitEngine.compute(
            natal: p.sky,
            day: day,
            ephemeris: skyEphemeris,
          );
          for (final h in sky.hits) {
            final sep = LongitudeMath.absSeparation(
              sky.longitudes[h.transit]!,
              h.natal.longitude,
            );
            final orb = (sep - h.aspect.angle).abs();
            expect(
              orb,
              lessThanOrEqualTo(
                AstrologyTransitEngine.orbs[h.transit]! - h.natal.tolerance,
              ),
            );
          }
        }
      }
    });

    test('a sentence naming an aspect names one the engine found', () {
      final names = AstrologySkyCopyTr.name;
      for (final p in skyPeople) {
        for (final day in _days(20)) {
          final sky = AstrologyTransitEngine.compute(
            natal: p.sky,
            day: day,
            ephemeris: skyEphemeris,
          );
          final reading = _read(p, day);
          final text = _lanes(reading).join(' ');
          final claim = RegExp(
            r'(Güneş|Ay|Merkür|Venüs|Mars|Jüpiter|Satürn)(?: bugün)? doğum '
            r'haritandaki (.+?) ile (kavuşuyor|destekleyici bir açı kuruyor|'
            r'uyumlu bir üçgen açı kuruyor|gergin bir kare açı yapıyor|'
            r'karşıt konuma geliyor)',
          );
          for (final m in claim.allMatches(text)) {
            final found = sky.hits.any((h) =>
                names[h.transit] == m.group(1) &&
                names[h.natal.point] == m.group(2) &&
                AstrologySkyCopyTr.aspectVerb[h.aspect] == m.group(3));
            expect(found, isTrue, reason: '${p.name} $day: ${m.group(0)}');
          }
        }
      }
    });
  });

  group('missing birth time', () {
    test('day-only charts never claim Moon, rising sign, MC or houses', () {
      expect(mehmet.sky.of(SkyPoint.moon), isNull);
      expect(mehmet.sky.of(SkyPoint.ascendant), isNull);
      for (final day in _days(60)) {
        final text = _lanes(_read(mehmet, day)).join(' ');
        expect(text, isNot(contains('yükselen')));
        expect(text, isNot(contains('MC')));
        expect(text, isNot(contains('. evinden')));
        expect(text, isNot(contains('haritandaki Ay ')));
        expect(text, isNot(contains('haritanda Ay ')));
      }
    });

    test('the reader is told what was left out', () {
      final r = _read(mehmet, DateTime(2026, 10, 20));
      expect(r.basisNote, contains('Doğum saatin bilinmediği için'));
    });
  });

  group('honest fallback to general copy', () {
    test('browsing another sign stays general and says so', () {
      final r = _read(ayse, DateTime(2026, 10, 20), signId: 'taurus');
      expect(r.basis, AstrologyReadingBasis.general);
      expect(r.basisNote, isEmpty);
    });

    test('no birth data stays general', () {
      final r = AstrologyDailyReadingService.build(
        AstrologyContentCatalogue.signById('aries')!,
        now: DateTime(2026, 10, 20),
      );
      expect(r.basis, AstrologyReadingBasis.general);
    });
  });

  group('lanes do not repeat each other', () {
    test('no sentence appears in two of overall, love, career and money', () {
      for (final p in skyPeople) {
        for (final day in _days(30)) {
          final r = _read(p, day);
          final seen = <String>{};
          for (final lane in [r.overall, r.love, r.career, r.money]) {
            for (final s in _sentences(lane)) {
              expect(seen.add(s), isTrue, reason: '${p.name} $day: $s');
            }
          }
        }
      }
    });
  });

  group('Turkish prose quality', () {
    final imperative = RegExp(
      r'\b(dene|unutma|dikkat et|kendine izin ver|sakın|yapmalısın|'
      r'etmelisin|gerekiyor)\b',
      caseSensitive: false,
    );

    test('no template residue, no orders, few hedges', () {
      for (final p in skyPeople) {
        for (final day in _days(30)) {
          final r = _read(p, day);
          final text = _lanes(r).join(' ');
          expect(text, isNot(contains('{')));
          expect(text, isNot(contains('null')));
          expect(text, isNot(contains('  ')));
          expect(text, isNot(contains(' .')));
          expect(imperative.hasMatch(text), isFalse, reason: text);
          expect(
            RegExp('olabilir').allMatches(text).length,
            lessThanOrEqualTo(1),
          );
          for (final lane in _lanes(r)) {
            expect(lane.trim(), isNotEmpty);
            expect(RegExp(r'[.?!]$').hasMatch(lane.trim()), isTrue,
                reason: lane);
            expect(lane[0], lane[0].toUpperCase(), reason: lane);
          }
        }
      }
    });

    test('readings change from day to day', () {
      final overalls = {
        for (final day in _days(14)) _read(zeynep, day).overall,
      };
      expect(overalls.length, greaterThanOrEqualTo(7));
    });
  });
}
