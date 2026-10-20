/// Personal daily astrology: real transits → structured findings → written
/// reading, stable for the day, isolated per account, general when offline.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/oracly_astrology_daily_ai_service.dart';
import 'package:oracly_new/features/astrology/models/astrology_daily_reading.dart';
import 'package:oracly_new/features/astrology/sky/astrology_daily_request.dart';
import 'package:oracly_new/features/astrology/sky/astrology_daily_result.dart';
import 'package:oracly_new/features/astrology/sky/astrology_natal_sky.dart';
import 'package:oracly_new/features/astrology/sky/astrology_personal_reading_service.dart';
import 'package:oracly_new/features/astrology/sky/astrology_sky_lanes.dart';
import 'package:oracly_new/features/astrology/sky/astrology_transit_engine.dart';
import 'package:oracly_new/features/birth_chart/astronomy/longitude_math.dart';

import 'sky_fixtures.dart';

TransitSky _sky(SkyPerson p, DateTime day) => AstrologyTransitEngine.compute(
      natal: p.sky,
      day: day,
      ephemeris: skyEphemeris,
    );

List<DateTime> _days(int n) =>
    [for (var i = 0; i < n; i++) DateTime(2026, 10, 1).add(Duration(days: i))];

Map<String, dynamic> _written({String overall = 'Bugün içindeki sabırsızlık biraz daha çabuk yüzeye çıkıyor ve küçük şeyler seni her zamankinden fazla kıpırdatıyor.'}) => {
      'contractVersion': 1,
      'portrait': 'Dışarıya hızla çıkan, içeride sağlam bir zemin arayan birisin.',
      'overall': overall,
      'love': 'Yakınlık tarafında daha yumuşak bir gün; sevgini gösterme biçimin bugün içten.',
      'career': 'İş tarafında belirgin bir dalga yok; düşüncelerini toparlamak kolay.',
      'money': 'Para tarafında ılımlı bir destek var; bir harcamanın gerçekten iyi gelip gelmediği görünüyor.',
      'mood': 'Ruh halin gün içinde birkaç kez yön değiştiriyor.',
      'drive': 'Enerjin dağınık ama tükenmiş değil.',
      'opportunity': 'Bir şeyi sadeleştirmek bugün kolay.',
      'caution': 'Tepkiler olduğundan sert çıkabiliyor.',
      'reflection': 'Seni bugün en çok ne sabırsızlandırıyor?',
    };

class _FakeWriter implements OraclyAstrologyDailyAiService {
  _FakeWriter([this.reply]);
  Map<String, dynamic>? reply;
  final ops = <String>[];
  final payloads = <Map<String, dynamic>>[];

  @override
  Future<AiOutcome<Map<String, dynamic>>> generateAstrologyDaily({
    required Map<String, dynamic> payload,
    required String operationId,
  }) async {
    ops.add(operationId);
    payloads.add(payload);
    final r = reply;
    if (r == null) return AiOutcome.failure(AiFailure.network());
    return AiOutcome.success(Map<String, dynamic>.from(r));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('three synthetic people resolve to the expected charts', () {
    expect(ayse.sky.sunSign.id, 'aries');
    expect(ayse.sky.depth, NatalSkyDepth.full);
    expect(mehmet.sky.sunSign.id, 'aries');
    expect(mehmet.sky.depth, NatalSkyDepth.dayOnly);
    expect(zeynep.sky.sunSign.id, 'libra');
  });

  group('calculated evidence', () {
    test('every engine hit lies within orb of its aspect angle', () {
      for (final p in skyPeople) {
        for (final day in _days(30)) {
          final sky = _sky(p, day);
          for (final h in sky.hits) {
            final sep = LongitudeMath.absSeparation(
              sky.longitudes[h.transit]!,
              h.natal.longitude,
            );
            expect(
              (sep - h.aspect.angle).abs(),
              lessThanOrEqualTo(
                AstrologyTransitEngine.orbs[h.transit]! - h.natal.tolerance,
              ),
            );
          }
        }
      }
    });

    test('each lane gets a different finding', () {
      for (final p in skyPeople) {
        for (final day in _days(30)) {
          final lanes = AstrologySkyLanes.assign(_sky(p, day));
          final keys = lanes.values.map((h) => h.key).toList();
          expect(keys.toSet().length, keys.length);
        }
      }
    });

    test('two Aries readers send different calculated facts', () {
      final day = DateTime(2026, 10, 20);
      final a = AstrologyDailyRequest.build(sky: _sky(ayse, day), day: day);
      final m = AstrologyDailyRequest.build(sky: _sky(mehmet, day), day: day);
      final af = (a.payload['sky'] as Map)['findings'] as List;
      final mf = (m.payload['sky'] as Map)['findings'] as List;
      expect(af, isNot(equals(mf)));
      expect(a.operationId, isNot(m.operationId));
    });
  });

  group('wire request', () {
    test('no birth data, degree or orb ever travels', () {
      final day = DateTime(2026, 10, 20);
      final text = AstrologyDailyRequest.build(
        sky: _sky(ayse, day),
        day: day,
        addressName: 'Ayşe',
      ).payload.toString();
      for (final banned in ['birthDate', 'birthTime', 'latitude', 'longitude', 'orb', 'degree', '1992']) {
        expect(text, isNot(contains(banned)));
      }
    });

    test('a day-only chart sends no rising sign, MC or houses', () {
      final day = DateTime(2026, 10, 20);
      final sky = AstrologyDailyRequest.build(sky: _sky(mehmet, day), day: day)
          .payload['sky'] as Map;
      expect(sky['depth'], 'dayOnly');
      final points = [for (final n in sky['natal'] as List) n['point']];
      expect(points, isNot(contains('ascendant')));
      expect(points, isNot(contains('midheaven')));
      expect(sky.toString(), isNot(contains('house')));
    });

    test('same day and facts keep one slot; the name does not change it', () {
      final day = DateTime(2026, 10, 20);
      final a = AstrologyDailyRequest.build(sky: _sky(ayse, day), day: day);
      final b = AstrologyDailyRequest.build(
        sky: _sky(ayse, day),
        day: day,
        addressName: 'Ayşe',
      );
      final next = DateTime(2026, 10, 21);
      final c = AstrologyDailyRequest.build(sky: _sky(ayse, next), day: next);
      expect(a.operationId, b.operationId);
      expect(a.operationId, startsWith('astro.20261020.'));
      expect(c.operationId, isNot(a.operationId));
      expect(((b.payload['sky'] as Map)['addressName']), 'Ayşe');
    });
  });

  group('client refuses texts the reader must not see', () {
    Map<String, dynamic> withField(String f, String v) => {..._written(), f: v};

    test('a grounded reading passes', () {
      expect(
        AstrologyDailyResult.validate(_written(), depth: NatalSkyDepth.full),
        isNotEmpty,
      );
    });

    test('technique, orders, fixed futures, repeats and missing layers fail', () {
      final repeated = 'Bugün sabrın biraz daha çabuk tükeniyor ve küçük şeyler içini kıpırdatıyor.';
      final cases = <(Map<String, dynamic>, NatalSkyDepth)>[
        (withField('love', 'Venüs Mars ile kare açı yapıyor.'), NatalSkyDepth.full),
        (withField('career', 'Bugün yeni bir şey dene.'), NatalSkyDepth.full),
        (withField('money', 'Bugün kesinlikle para gelecek.'), NatalSkyDepth.full),
        (withField('love', 'Bugün yeni biriyle tanışacaksın.'), NatalSkyDepth.full),
        ({..._written(overall: repeated), 'love': repeated}, NatalSkyDepth.full),
        (withField('portrait', 'Yükselen burcun Aslan.'), NatalSkyDepth.dayOnly),
        (withField('reflection', 'Kendine zaman ayır.'), NatalSkyDepth.full),
        (withField('overall', 'Sevgili Ayşe, bugün sakin.'), NatalSkyDepth.full),
        ({..._written(), 'contractVersion': 2}, NatalSkyDepth.full),
      ];
      for (final (raw, depth) in cases) {
        expect(
          () => AstrologyDailyResult.validate(raw, depth: depth),
          throwsA(isA<AstrologyDailyResultException>()),
        );
      }
    });
  });

  group('reading service', () {
    final day = DateTime(2026, 10, 20);

    LocalStorage owned(String owner) {
      final s = LocalStorage.ephemeral();
      s.setString(UserLocalDataIsolation.ownerKey, owner);
      return s;
    }

    test('reopening the same day shows the same text without a new call',
        () async {
      final storage = owned('owner-a');
      final writer = _FakeWriter(_written());
      AstrologyPersonalReadingService service() => AstrologyPersonalReadingService(
            storage: storage,
            ownerId: () => storage.getString(UserLocalDataIsolation.ownerKey),
            ephemeris: skyEphemeris,
            ai: writer,
          );
      final first = await service().load(natal: ayse.sky, day: day);
      writer.reply = _written(overall: 'Bambaşka, farklı ve yeni bir genel yorum metni burada duruyor bugün.');
      final again = await service().load(natal: ayse.sky, day: day);
      expect(first!.overall, again!.overall);
      expect(writer.ops.length, 1);
      expect(first.basis, AstrologyReadingBasis.skyFull);
      expect(first.basisNote, isNotEmpty);
    });

    test('another account never sees the cached reading', () async {
      final storage = owned('owner-a');
      final writer = _FakeWriter(_written());
      final service = AstrologyPersonalReadingService(
        storage: storage,
        ownerId: () => storage.getString(UserLocalDataIsolation.ownerKey),
        ephemeris: skyEphemeris,
        ai: writer,
      );
      await service.load(natal: ayse.sky, day: day);
      await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-b');
      writer.reply = null;
      expect(await service.load(natal: ayse.sky, day: day), isNull);
      expect(writer.ops.length, 2);
    });

    test('offline, refused text or no writer → null (general reading)',
        () async {
      final storage = owned('owner-a');
      AstrologyPersonalReadingService with_(OraclyAstrologyDailyAiService? ai) =>
          AstrologyPersonalReadingService(
            storage: storage,
            ownerId: () => storage.getString(UserLocalDataIsolation.ownerKey),
            ephemeris: skyEphemeris,
            ai: ai,
          );
      expect(await with_(null).load(natal: ayse.sky, day: day), isNull);
      expect(await with_(_FakeWriter()).load(natal: ayse.sky, day: day), isNull);
      final refused = _FakeWriter({..._written(), 'love': 'Venüs kare açı yapıyor.'});
      expect(await with_(refused).load(natal: ayse.sky, day: day), isNull);
    });

    test('no owner → no call', () async {
      final writer = _FakeWriter(_written());
      final service = AstrologyPersonalReadingService(
        storage: LocalStorage.ephemeral(),
        ownerId: () => null,
        ephemeris: skyEphemeris,
        ai: writer,
      );
      expect(await service.load(natal: ayse.sky, day: day), isNull);
      expect(writer.ops, isEmpty);
    });
  });
}
