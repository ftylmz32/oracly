/// Prints sky readings for the synthetic people (SKY_SAMPLES=1 to show).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/astrology/services/astrology_daily_reading_service.dart';
import 'package:oracly_new/features/content/astrology/data/astrology_content_catalogue.dart';

import 'sky_fixtures.dart';

void main() {
  test('sample sky readings', () {
    if (Platform.environment['SKY_SAMPLES'] != '1') return;
    final days = [DateTime(2026, 10, 20), DateTime(2026, 10, 21)];
    for (final day in days) {
      for (final p in skyPeople) {
        final sign =
            AstrologyContentCatalogue.signById(p.sky.sunSign.id)!;
        final r = AstrologyDailyReadingService.build(
          sign,
          now: day,
          natalSky: p.sky,
          ephemeris: skyEphemeris,
          selectedThemes: p == ayse ? const ['relationship'] : const [],
        );
        // ignore: avoid_print
        print('''
==== ${p.name} · ${sign.id} · ${day.toIso8601String().substring(0, 10)} · ${r.basis.name}
NOT: ${r.basisNote}
KİŞİLİK: ${r.personality}
GENEL: ${r.overall}
AŞK: ${r.love}
KARİYER: ${r.career}
PARA: ${r.money}
DUYGU: ${r.emotion}
ENERJİ: ${r.energy}
FIRSAT: ${r.opportunity}
DİKKAT: ${r.caution}
YANSIMA: ${r.advice}
''');
      }
    }
  });
}
