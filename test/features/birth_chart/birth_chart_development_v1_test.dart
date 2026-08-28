/// Birth Chart V1 — city catalogue, persistence, honest sun-sign source.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_cities.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_record_mapper.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/birth_chart/services/birth_chart_experience_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('city catalogue can select Istanbul with coordinates', () {
    final city = BirthChartCities.byName('İstanbul');
    expect(city, isNotNull);
    expect(city!.latitude, closeTo(41.01, 0.02));
    expect(city.longitude, closeTo(28.98, 0.02));
    expect(BirthChartCities.search('ank').map((c) => c.id), contains('ankara'));
  });

  test('saved profile reopens with the same sun sign', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final service = BirthChartExperienceService(
      repository: LocalBirthChartRepository(storage),
    );

    final generated = await service.generate(
      BirthProfile(
        birthDate: DateTime(1995, 8, 15),
        birthPlace: 'İstanbul',
        birthTime: DateTime(1995, 8, 15, 14, 30),
        birthTimeKnown: true,
        latitude: 41.01,
        longitude: 28.98,
      ),
    );

    expect(generated.chart.sun.sign, ZodiacSignId.leo);
    expect(generated.chart.hasFullNatal, isFalse);

    final loaded = await service.loadSaved();
    expect(loaded.chart?.profile.birthPlace, 'İstanbul');
    expect(loaded.chart?.sun.sign, ZodiacSignId.leo);
    expect(loaded.chart?.profile.hasKnownTime, isTrue);
    expect(
      BirthChartRecordMapper.fromRecord(
        (await LocalBirthChartRepository(storage).getLatest())!,
      ).sun.sign,
      ZodiacSignId.leo,
    );
  });

  test('date-only profile saves and reopens without birth place', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final service = BirthChartExperienceService(
      repository: LocalBirthChartRepository(storage),
    );

    final generated = await service.generate(
      BirthProfile(
        birthDate: DateTime(1995, 8, 15),
        birthPlace: '',
        birthTimeKnown: false,
      ),
    );

    expect(generated.chart.sun.sign, ZodiacSignId.leo);
    expect(generated.chart.hasFullNatal, isFalse);
    expect(generated.chart.precision.name, 'partialNoTime');

    final loaded = await service.loadSaved();
    expect(loaded.chart?.profile.birthPlace, '');
    expect(loaded.chart?.profile.hasKnownTime, isFalse);
    expect(loaded.chart?.sun.sign, ZodiacSignId.leo);
  });
}
