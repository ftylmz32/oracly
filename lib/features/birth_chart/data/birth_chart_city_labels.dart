/// Locale display names for birth cities — Turkish provinces + legacy places.
library;

import '../../../core/l10n/l10n.dart';

abstract final class BirthChartCityLabels {
  BirthChartCityLabels._();

  /// Natural EN / RU labels where they differ from Turkish orthography.
  static const _en = <String, String>{
    'istanbul': 'Istanbul',
    'izmir': 'Izmir',
    'sanliurfa': 'Sanliurfa',
    'kahramanmaras': 'Kahramanmaras',
    'afyonkarahisar': 'Afyonkarahisar',
    'london': 'London',
    'vienna': 'Vienna',
    'berlin': 'Berlin',
    'paris': 'Paris',
    'newyork': 'New York',
  };

  static const _ru = <String, String>{
    'istanbul': 'Стамбул',
    'ankara': 'Анкара',
    'izmir': 'Измир',
    'antalya': 'Анталья',
    'bursa': 'Бурса',
    'adana': 'Адана',
    'gaziantep': 'Газиантеп',
    'konya': 'Конья',
    'mersin': 'Мерсин',
    'diyarbakir': 'Диярбакыр',
    'kayseri': 'Кайсери',
    'eskisehir': 'Эскишехир',
    'samsun': 'Самсун',
    'trabzon': 'Трабзон',
    'sanliurfa': 'Шанлыурфа',
    'london': 'Лондон',
    'vienna': 'Вена',
    'berlin': 'Берлин',
    'paris': 'Париж',
    'newyork': 'Нью-Йорк',
  };

  static String of(String id, String nameTr, {String? languageCode}) {
    final lang = AppLocale.normalize(languageCode ?? OraclyL10n.code);
    return switch (lang) {
      AppLocale.en => _en[id] ?? nameTr,
      AppLocale.ru => _ru[id] ?? nameTr,
      _ => nameTr,
    };
  }
}
