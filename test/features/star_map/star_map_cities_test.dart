/// Yıldızname city picker — 81 Turkish provinces, search, persistence.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_cities.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/presentation/widgets/birth_chart_city_picker.dart';
import 'package:oracly_new/features/birth_chart/services/birth_chart_experience_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalogue has 81 unique Turkish provinces', () {
    final names = BirthChartCities.all.map((c) => c.nameTr).toList();
    final ids = BirthChartCities.all.map((c) => c.id).toList();
    expect(names.length, BirthChartCities.turkeyProvinceCount);
    expect(names.toSet().length, 81);
    expect(ids.toSet().length, 81);
    expect(names, containsAll(_expected));
    expect(names.first, 'Adana');
    expect(names.last, 'Zonguldak');
  });

  test('search finds Turkish-named provinces', () {
    expect(_one('Şanlıurfa'), 'Şanlıurfa');
    expect(_one('sanliurfa'), 'Şanlıurfa');
    expect(_one('Kahramanmaraş'), 'Kahramanmaraş');
    expect(_one('Iğdır'), 'Iğdır');
    expect(_one('igdir'), 'Iğdır');
    expect(_one('İstanbul'), 'İstanbul');
    expect(_one('istanbul'), 'İstanbul');
    expect(_one('Çanakkale'), 'Çanakkale');
    expect(_one('canakkale'), 'Çanakkale');
    expect(BirthChartCities.search('ank').map((c) => c.id), contains('ankara'));
  });

  test('every province can be resolved and selected', () {
    for (final name in _expected) {
      final city = BirthChartCities.byName(name);
      expect(city, isNotNull, reason: name);
      expect(city!.nameTr, name);
      expect(BirthChartCities.search(name).any((c) => c.nameTr == name), isTrue);
    }
  });

  test('saved province reopens with the same nameTr', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final service = BirthChartExperienceService(
      repository: LocalBirthChartRepository(storage),
    );
    final city = BirthChartCities.byName('Kahramanmaraş')!;
    await service.generate(
      BirthProfile(
        birthDate: DateTime(1995, 8, 15),
        birthPlace: city.nameTr,
        birthTimeKnown: false,
        latitude: city.latitude,
        longitude: city.longitude,
      ),
    );
    final loaded = await service.loadSaved();
    expect(loaded.chart?.profile.birthPlace, 'Kahramanmaraş');
    expect(BirthChartCities.byName(loaded.chart!.profile.birthPlace)?.id,
        'kahramanmaras');
    expect(BirthChartCities.byName('İstanbul')?.nameTr, 'İstanbul');
    expect(BirthChartCities.byName('Berlin')?.nameTr, 'Berlin');
  });

  testWidgets('picker lists and returns a province', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showBirthChartCityPicker(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Adana'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Şanlıurfa');
    await tester.pump();
    expect(find.widgetWithText(ListTile, 'Şanlıurfa'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Şanlıurfa'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Şanlıurfa'), findsNothing);
  });
}

String _one(String q) => BirthChartCities.search(q).single.nameTr;

const _expected = [
  'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya', 'Ankara',
  'Antalya', 'Ardahan', 'Artvin', 'Aydın', 'Balıkesir', 'Bartın', 'Batman',
  'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa',
  'Çanakkale', 'Çankırı', 'Çorum', 'Denizli', 'Diyarbakır', 'Düzce', 'Edirne',
  'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun',
  'Gümüşhane', 'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul', 'İzmir',
  'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars', 'Kastamonu', 'Kayseri',
  'Kilis', 'Kırıkkale', 'Kırklareli', 'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya',
  'Malatya', 'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde',
  'Ordu', 'Osmaniye', 'Rize', 'Sakarya', 'Samsun', 'Şanlıurfa', 'Siirt',
  'Sinop', 'Sivas', 'Şırnak', 'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Uşak',
  'Van', 'Yalova', 'Yozgat', 'Zonguldak',
];
