/// Birth-city catalogue — 81 Turkish provinces. Coordinates for place, not sky math.
library;

import 'birth_chart_city_labels.dart';

class BirthChartCity {
  const BirthChartCity({
    required this.id,
    required this.nameTr,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String nameTr;
  final double latitude;
  final double longitude;

  /// Locale-aware picker / profile label.
  String label({String? languageCode}) =>
      BirthChartCityLabels.of(id, nameTr, languageCode: languageCode);
}

abstract final class BirthChartCities {
  BirthChartCities._();

  static const turkeyProvinceCount = 81;

  /// Turkish provinces in Turkish alphabetical order. Picker uses this.
  static const List<BirthChartCity> all = [
    BirthChartCity(id: 'adana', nameTr: 'Adana', latitude: 37.00, longitude: 35.32),
    BirthChartCity(id: 'adiyaman', nameTr: 'Adıyaman', latitude: 37.76, longitude: 38.28),
    BirthChartCity(id: 'afyonkarahisar', nameTr: 'Afyonkarahisar', latitude: 38.76, longitude: 30.54),
    BirthChartCity(id: 'agri', nameTr: 'Ağrı', latitude: 39.72, longitude: 43.05),
    BirthChartCity(id: 'aksaray', nameTr: 'Aksaray', latitude: 38.37, longitude: 34.03),
    BirthChartCity(id: 'amasya', nameTr: 'Amasya', latitude: 40.65, longitude: 35.83),
    BirthChartCity(id: 'ankara', nameTr: 'Ankara', latitude: 39.93, longitude: 32.85),
    BirthChartCity(id: 'antalya', nameTr: 'Antalya', latitude: 36.90, longitude: 30.70),
    BirthChartCity(id: 'ardahan', nameTr: 'Ardahan', latitude: 41.11, longitude: 42.70),
    BirthChartCity(id: 'artvin', nameTr: 'Artvin', latitude: 41.18, longitude: 41.82),
    BirthChartCity(id: 'aydin', nameTr: 'Aydın', latitude: 37.84, longitude: 27.84),
    BirthChartCity(id: 'balikesir', nameTr: 'Balıkesir', latitude: 39.65, longitude: 27.89),
    BirthChartCity(id: 'bartin', nameTr: 'Bartın', latitude: 41.63, longitude: 32.34),
    BirthChartCity(id: 'batman', nameTr: 'Batman', latitude: 37.89, longitude: 41.13),
    BirthChartCity(id: 'bayburt', nameTr: 'Bayburt', latitude: 40.26, longitude: 40.23),
    BirthChartCity(id: 'bilecik', nameTr: 'Bilecik', latitude: 40.14, longitude: 29.98),
    BirthChartCity(id: 'bingol', nameTr: 'Bingöl', latitude: 38.89, longitude: 40.50),
    BirthChartCity(id: 'bitlis', nameTr: 'Bitlis', latitude: 38.40, longitude: 42.11),
    BirthChartCity(id: 'bolu', nameTr: 'Bolu', latitude: 40.74, longitude: 31.61),
    BirthChartCity(id: 'burdur', nameTr: 'Burdur', latitude: 37.72, longitude: 30.29),
    BirthChartCity(id: 'bursa', nameTr: 'Bursa', latitude: 40.18, longitude: 29.06),
    BirthChartCity(id: 'canakkale', nameTr: 'Çanakkale', latitude: 40.15, longitude: 26.41),
    BirthChartCity(id: 'cankiri', nameTr: 'Çankırı', latitude: 40.60, longitude: 33.62),
    BirthChartCity(id: 'corum', nameTr: 'Çorum', latitude: 40.55, longitude: 34.95),
    BirthChartCity(id: 'denizli', nameTr: 'Denizli', latitude: 37.78, longitude: 29.09),
    BirthChartCity(id: 'diyarbakir', nameTr: 'Diyarbakır', latitude: 37.91, longitude: 40.23),
    BirthChartCity(id: 'duzce', nameTr: 'Düzce', latitude: 40.84, longitude: 31.16),
    BirthChartCity(id: 'edirne', nameTr: 'Edirne', latitude: 41.68, longitude: 26.56),
    BirthChartCity(id: 'elazig', nameTr: 'Elazığ', latitude: 38.68, longitude: 39.23),
    BirthChartCity(id: 'erzincan', nameTr: 'Erzincan', latitude: 39.75, longitude: 39.49),
    BirthChartCity(id: 'erzurum', nameTr: 'Erzurum', latitude: 39.91, longitude: 41.27),
    BirthChartCity(id: 'eskisehir', nameTr: 'Eskişehir', latitude: 39.78, longitude: 30.52),
    BirthChartCity(id: 'gaziantep', nameTr: 'Gaziantep', latitude: 37.07, longitude: 37.38),
    BirthChartCity(id: 'giresun', nameTr: 'Giresun', latitude: 40.91, longitude: 38.39),
    BirthChartCity(id: 'gumushane', nameTr: 'Gümüşhane', latitude: 40.46, longitude: 39.48),
    BirthChartCity(id: 'hakkari', nameTr: 'Hakkari', latitude: 37.57, longitude: 43.74),
    BirthChartCity(id: 'hatay', nameTr: 'Hatay', latitude: 36.20, longitude: 36.16),
    BirthChartCity(id: 'igdir', nameTr: 'Iğdır', latitude: 39.92, longitude: 44.05),
    BirthChartCity(id: 'isparta', nameTr: 'Isparta', latitude: 37.76, longitude: 30.55),
    BirthChartCity(id: 'istanbul', nameTr: 'İstanbul', latitude: 41.01, longitude: 28.98),
    BirthChartCity(id: 'izmir', nameTr: 'İzmir', latitude: 38.42, longitude: 27.14),
    BirthChartCity(id: 'kahramanmaras', nameTr: 'Kahramanmaraş', latitude: 37.59, longitude: 36.94),
    BirthChartCity(id: 'karabuk', nameTr: 'Karabük', latitude: 41.21, longitude: 32.63),
    BirthChartCity(id: 'karaman', nameTr: 'Karaman', latitude: 37.18, longitude: 33.22),
    BirthChartCity(id: 'kars', nameTr: 'Kars', latitude: 40.60, longitude: 43.10),
    BirthChartCity(id: 'kastamonu', nameTr: 'Kastamonu', latitude: 41.38, longitude: 33.78),
    BirthChartCity(id: 'kayseri', nameTr: 'Kayseri', latitude: 38.73, longitude: 35.49),
    BirthChartCity(id: 'kirikkale', nameTr: 'Kırıkkale', latitude: 39.85, longitude: 33.51),
    BirthChartCity(id: 'kirklareli', nameTr: 'Kırklareli', latitude: 41.74, longitude: 27.23),
    BirthChartCity(id: 'kirsehir', nameTr: 'Kırşehir', latitude: 39.15, longitude: 34.16),
    BirthChartCity(id: 'kilis', nameTr: 'Kilis', latitude: 36.72, longitude: 37.12),
    BirthChartCity(id: 'kocaeli', nameTr: 'Kocaeli', latitude: 40.77, longitude: 29.92),
    BirthChartCity(id: 'konya', nameTr: 'Konya', latitude: 37.87, longitude: 32.49),
    BirthChartCity(id: 'kutahya', nameTr: 'Kütahya', latitude: 39.42, longitude: 29.98),
    BirthChartCity(id: 'malatya', nameTr: 'Malatya', latitude: 38.36, longitude: 38.31),
    BirthChartCity(id: 'manisa', nameTr: 'Manisa', latitude: 38.61, longitude: 27.43),
    BirthChartCity(id: 'mardin', nameTr: 'Mardin', latitude: 37.31, longitude: 40.74),
    BirthChartCity(id: 'mersin', nameTr: 'Mersin', latitude: 36.81, longitude: 34.64),
    BirthChartCity(id: 'mugla', nameTr: 'Muğla', latitude: 37.22, longitude: 28.37),
    BirthChartCity(id: 'mus', nameTr: 'Muş', latitude: 38.74, longitude: 41.49),
    BirthChartCity(id: 'nevsehir', nameTr: 'Nevşehir', latitude: 38.62, longitude: 34.71),
    BirthChartCity(id: 'nigde', nameTr: 'Niğde', latitude: 37.97, longitude: 34.68),
    BirthChartCity(id: 'ordu', nameTr: 'Ordu', latitude: 40.98, longitude: 37.88),
    BirthChartCity(id: 'osmaniye', nameTr: 'Osmaniye', latitude: 37.07, longitude: 36.25),
    BirthChartCity(id: 'rize', nameTr: 'Rize', latitude: 41.02, longitude: 40.52),
    BirthChartCity(id: 'sakarya', nameTr: 'Sakarya', latitude: 40.76, longitude: 30.40),
    BirthChartCity(id: 'samsun', nameTr: 'Samsun', latitude: 41.29, longitude: 36.33),
    BirthChartCity(id: 'siirt', nameTr: 'Siirt', latitude: 37.93, longitude: 41.94),
    BirthChartCity(id: 'sinop', nameTr: 'Sinop', latitude: 42.03, longitude: 35.15),
    BirthChartCity(id: 'sivas', nameTr: 'Sivas', latitude: 39.75, longitude: 37.02),
    BirthChartCity(id: 'sanliurfa', nameTr: 'Şanlıurfa', latitude: 37.17, longitude: 38.79),
    BirthChartCity(id: 'sirnak', nameTr: 'Şırnak', latitude: 37.52, longitude: 42.45),
    BirthChartCity(id: 'tekirdag', nameTr: 'Tekirdağ', latitude: 40.98, longitude: 27.51),
    BirthChartCity(id: 'tokat', nameTr: 'Tokat', latitude: 40.32, longitude: 36.55),
    BirthChartCity(id: 'trabzon', nameTr: 'Trabzon', latitude: 41.00, longitude: 39.72),
    BirthChartCity(id: 'tunceli', nameTr: 'Tunceli', latitude: 39.11, longitude: 39.54),
    BirthChartCity(id: 'usak', nameTr: 'Uşak', latitude: 38.68, longitude: 29.40),
    BirthChartCity(id: 'van', nameTr: 'Van', latitude: 38.50, longitude: 43.40),
    BirthChartCity(id: 'yalova', nameTr: 'Yalova', latitude: 40.66, longitude: 29.28),
    BirthChartCity(id: 'yozgat', nameTr: 'Yozgat', latitude: 39.82, longitude: 34.81),
    BirthChartCity(id: 'zonguldak', nameTr: 'Zonguldak', latitude: 41.46, longitude: 31.80),
  ];

  /// Prior international picks — resolve old profiles, not shown in the list.
  static const List<BirthChartCity> _legacy = [
    BirthChartCity(id: 'berlin', nameTr: 'Berlin', latitude: 52.52, longitude: 13.40),
    BirthChartCity(id: 'london', nameTr: 'Londra', latitude: 51.51, longitude: -0.13),
    BirthChartCity(id: 'paris', nameTr: 'Paris', latitude: 48.86, longitude: 2.35),
    BirthChartCity(id: 'vienna', nameTr: 'Viyana', latitude: 48.21, longitude: 16.37),
    BirthChartCity(id: 'newyork', nameTr: 'New York', latitude: 40.71, longitude: -74.01),
  ];

  static BirthChartCity? byName(String? name) {
    final needle = fold(name ?? '');
    if (needle.isEmpty) return null;
    for (final city in [...all, ..._legacy]) {
      if (fold(city.nameTr) == needle || city.id == needle) return city;
    }
    return null;
  }

  static List<BirthChartCity> search(String query) {
    final q = fold(query);
    if (q.isEmpty) return all;
    return all.where((c) {
      if (fold(c.nameTr).contains(q) || c.id.contains(q)) return true;
      final en = BirthChartCityLabels.of(c.id, c.nameTr, languageCode: 'en');
      final ru = BirthChartCityLabels.of(c.id, c.nameTr, languageCode: 'ru');
      return fold(en).contains(q) || fold(ru).contains(q);
    }).toList();
  }

  static String fold(String raw) {
    final buffer = StringBuffer();
    for (final rune in raw.trim().runes) {
      buffer.write(_foldChar(rune));
    }
    return buffer.toString();
  }

  static String _foldChar(int rune) {
    return switch (rune) {
      0x00C7 || 0x00E7 => 'c',
      0x011E || 0x011F => 'g',
      0x0130 || 0x0049 || 0x0131 || 0x0069 => 'i',
      0x00D6 || 0x00F6 => 'o',
      0x015E || 0x015F => 's',
      0x00DC || 0x00FC => 'u',
      _ => String.fromCharCode(rune).toLowerCase(),
    };
  }
}
