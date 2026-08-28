/// OR-1150 — Mock daily energy content catalogue.
library;

import '../models/daily_energy_content.dart';

abstract final class DailyEnergyContentCatalogue {
  DailyEnergyContentCatalogue._();

  static DailyEnergyContent forDate(DateTime date) {
    final weekday = date.weekday;
    return DailyEnergyContent(
      id: 'energy_${date.toIso8601String().substring(0, 10)}',
      date: date,
      summary:
          'Bugün sezgin biraz daha net. Acele etmeden tek bir adıma bak.',
      vibrationScore: ((date.day + date.month) % 100) / 100.0,
      luckyColor: _colors[weekday % _colors.length],
      luckyNumber: LuckyNumber(
        value: (date.day + date.month) % 9 + 1,
        meaning: 'Sezgi ve uyum sayısı; kararlarında kalbine kulak ver.',
      ),
      luckyCrystal: _crystals[weekday % _crystals.length],
      spiritMessage: _messages[weekday % _messages.length],
      moonInfluence: _moonPhases[date.day % _moonPhases.length],
      elementEnergy: _elements[weekday % _elements.length],
      weekTheme: _weekThemes[((date.day - 1) ~/ 7) % _weekThemes.length],
      loveHint:
          'Kalbin açık ve alıcı; samimi sohbetler ilişkilerini derinleştirebilir.',
      careerHint:
          'Odaklanmış çalışma ve net iletişim profesyonel alanda kapı aralar.',
      moneyHint:
          'Küçük tasarruf adımları uzun vadede güven verir; ani risklerden kaçın.',
      moodHint:
          'Ruhsal denge için kısa meditasyon veya doğada yürüyüş iyi gelir.',
    );
  }

  static const _colors = [
    LuckyColor(name: 'Ametist', hex: '#9966CC', meaning: 'Sezgi ve ruhsal derinlik'),
    LuckyColor(name: 'Altın', hex: '#D4AF37', meaning: 'Bolluk ve ilham'),
    LuckyColor(name: 'Turkuaz', hex: '#40E0D0', meaning: 'İletişim ve şifa'),
    LuckyColor(name: 'Gül Kuvars', hex: '#F7CAC9', meaning: 'Sevgi ve yumuşaklık'),
    LuckyColor(name: 'Lacivert', hex: '#1B2A4E', meaning: 'Derinlik ve bilgelik'),
    LuckyColor(name: 'Zümrüt', hex: '#50C878', meaning: 'Yenilenme ve denge'),
    LuckyColor(name: 'Mercan', hex: '#FF7F50', meaning: 'Canlılık ve cesaret'),
  ];

  static const _crystals = [
    LuckyCrystal(
      name: 'Ay Taşı',
      chakra: 'Taç',
      intention: 'Sezgi ve duygusal denge',
    ),
    LuckyCrystal(
      name: 'Ametist',
      chakra: 'Üçüncü Göz',
      intention: 'Ruhsal koruma ve netlik',
    ),
    LuckyCrystal(
      name: 'Pirit',
      chakra: 'Solar Plexus',
      intention: 'Özgüven ve eylem',
    ),
    LuckyCrystal(
      name: 'Rosenquartz',
      chakra: 'Kalp',
      intention: 'Şefkat ve ilişki uyumu',
    ),
  ];

  static const _messages = [
    SpiritMessage(
      id: 'spirit_1',
      title: 'İç Sesin',
      message: 'Bugün cevaplar dışarıda değil, içinde. Sessizliğe kulak ver.',
      theme: 'sezgi',
    ),
    SpiritMessage(
      id: 'spirit_2',
      title: 'Cesaret',
      message: 'Küçük bir adım büyük bir kapı aralayabilir. Harekete geç.',
      theme: 'eylem',
    ),
    SpiritMessage(
      id: 'spirit_3',
      title: 'Bırakış',
      message: 'Taşıdığın yükün bir kısmını bırakmak için uygun bir gün.',
      theme: 'arınma',
    ),
  ];

  static const _moonPhases = [
    MoonInfluence(
      phase: 'waxing_crescent',
      label: 'Hilal',
      influence: 'Niyetler filizleniyor; yeni başlangıçlara açık ol.',
      ritualHint: 'Kısa bir niyet yaz ve mum yak.',
    ),
    MoonInfluence(
      phase: 'full_moon',
      label: 'Dolunay',
      influence: 'Duygular yoğun; kutlama ve şükran zamanı.',
      ritualHint: 'Minnettar olduğun üç şeyi say.',
    ),
    MoonInfluence(
      phase: 'waning',
      label: 'Azalan Ay',
      influence: 'Bırakış ve sadeleştirme daha doğal durur.',
      ritualHint: 'Kısa bir banyo veya ekranı bir saat kapatmayı dene.',
    ),
  ];

  static const _elements = [
    ElementEnergy(
      element: 'Su',
      quality: 'Akışkan',
      guidance: 'Duygularına alan aç; empati gücün yüksek.',
    ),
    ElementEnergy(
      element: 'Ateş',
      quality: 'Canlı',
      guidance: 'Tutku ve motivasyon yüksek; enerjini odakla.',
    ),
    ElementEnergy(
      element: 'Toprak',
      quality: 'Kararlı',
      guidance: 'Pratik adımlar ve sabır bugün seni taşır.',
    ),
    ElementEnergy(
      element: 'Hava',
      quality: 'Hafif',
      guidance: 'Fikirler ve iletişim ön planda; net konuş.',
    ),
  ];

  static const _weekThemes = [
    'Yenilenme Haftası',
    'Odak Haftası',
    'Bağlantı Haftası',
    'Bolluk Haftası',
  ];
}
