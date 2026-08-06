/// OR-1150 — Astrology content catalogue.
library;

import '../models/astrology_content.dart';

abstract final class AstrologyContentCatalogue {
  AstrologyContentCatalogue._();

  static List<ZodiacSignContent> get signs => _signs;
  static List<PlanetContent> get planets => _planets;
  static List<HouseContent> get houses => _houses;
  static List<AspectContent> get aspects => _aspects;
  static List<CompatibilityContent> get compatibility => _compatibility;

  static ZodiacSignContent? signById(String id) {
    for (final s in _signs) {
      if (s.id == id) return s;
    }
    return null;
  }

  static const _signs = [
    ZodiacSignContent(
      id: 'aries', name: 'Aries', nameTr: 'Koç', symbol: '♈',
      element: ZodiacElement.fire, modality: ZodiacModality.cardinal,
      rulingPlanet: 'Mars', dateRange: '21 Mart – 19 Nisan',
      traits: ['Cesur', 'Girişken', 'Hırslı'],
      strengths: ['Liderlik', 'Enerji', 'Kararlılık'],
      weaknesses: ['Sabırsızlık', 'Acelecilik'],
      loveStyle: 'Tutkulu ve doğrudan; heyecan arar.',
      careerStyle: 'Girişimci ve rekabetçi.',
    ),
    ZodiacSignContent(
      id: 'taurus', name: 'Taurus', nameTr: 'Boğa', symbol: '♉',
      element: ZodiacElement.earth, modality: ZodiacModality.fixed,
      rulingPlanet: 'Venüs', dateRange: '20 Nisan – 20 Mayıs',
      traits: ['Kararlı', 'Güvenilir', 'Pratik'],
      strengths: ['Sabır', 'Bolluk bilinci'],
      weaknesses: ['İnat', 'Değişime direnç'],
      loveStyle: 'Sadık ve duyusal; güven arar.',
      careerStyle: 'İstikrarlı ve kalite odaklı.',
    ),
    ZodiacSignContent(
      id: 'gemini', name: 'Gemini', nameTr: 'İkizler', symbol: '♊',
      element: ZodiacElement.air, modality: ZodiacModality.mutable,
      rulingPlanet: 'Merkür', dateRange: '21 Mayıs – 20 Haziran',
      traits: ['Meraklı', 'İletişimci', 'Uyumlu'],
      strengths: ['Zeka', 'Esneklik'],
      weaknesses: ['Kararsızlık', 'Dağınıklık'],
      loveStyle: 'Zihinsel uyum ve sohbet arar.',
      careerStyle: 'Çok yönlü ve hızlı öğrenen.',
    ),
    ZodiacSignContent(
      id: 'cancer', name: 'Cancer', nameTr: 'Yengeç', symbol: '♋',
      element: ZodiacElement.water, modality: ZodiacModality.cardinal,
      rulingPlanet: 'Ay', dateRange: '21 Haziran – 22 Temmuz',
      traits: ['Koruyucu', 'Sezgisel', 'Duygusal'],
      strengths: ['Empati', 'Bağlılık'],
      weaknesses: ['Aşırı hassasiyet'],
      loveStyle: 'Derin duygusal bağ kurar.',
      careerStyle: 'Besleyici ve destekleyici roller.',
    ),
    ZodiacSignContent(
      id: 'leo', name: 'Leo', nameTr: 'Aslan', symbol: '♌',
      element: ZodiacElement.fire, modality: ZodiacModality.fixed,
      rulingPlanet: 'Güneş', dateRange: '23 Temmuz – 22 Ağustos',
      traits: ['Cömert', 'Yaratıcı', 'Gururlu'],
      strengths: ['Liderlik', 'Sıcaklık'],
      weaknesses: ['Ego', 'Dikkat ihtiyacı'],
      loveStyle: 'Tutku ve sadakatle sever.',
      careerStyle: 'Sahne ve yaratıcı alanlar.',
    ),
    ZodiacSignContent(
      id: 'virgo', name: 'Virgo', nameTr: 'Başak', symbol: '♍',
      element: ZodiacElement.earth, modality: ZodiacModality.mutable,
      rulingPlanet: 'Merkür', dateRange: '23 Ağustos – 22 Eylül',
      traits: ['Analitik', 'Düzenli', 'Hizmetkar'],
      strengths: ['Detay', 'Pratiklik'],
      weaknesses: ['Eleştiri', 'Mükemmeliyetçilik'],
      loveStyle: 'Güven ve istikrar arar.',
      careerStyle: 'Organizasyon ve uzmanlık.',
    ),
    ZodiacSignContent(
      id: 'libra', name: 'Libra', nameTr: 'Terazi', symbol: '♎',
      element: ZodiacElement.air, modality: ZodiacModality.cardinal,
      rulingPlanet: 'Venüs', dateRange: '23 Eylül – 22 Ekim',
      traits: ['Diplomatik', 'Adil', 'Estetik'],
      strengths: ['Denge', 'Uyum'],
      weaknesses: ['Kararsızlık'],
      loveStyle: 'Romantik ve eşitlikçi.',
      careerStyle: 'Arabuluculuk ve tasarım.',
    ),
    ZodiacSignContent(
      id: 'scorpio', name: 'Scorpio', nameTr: 'Akrep', symbol: '♏',
      element: ZodiacElement.water, modality: ZodiacModality.fixed,
      rulingPlanet: 'Plüton', dateRange: '23 Ekim – 21 Kasım',
      traits: ['Derin', 'Kararlı', 'Sezgisel'],
      strengths: ['Dönüşüm gücü', 'Sadakat'],
      weaknesses: ['Kıskançlık', 'Gizlilik'],
      loveStyle: 'Yoğun ve dönüştürücü.',
      careerStyle: 'Araştırma ve strateji.',
    ),
    ZodiacSignContent(
      id: 'sagittarius', name: 'Sagittarius', nameTr: 'Yay', symbol: '♐',
      element: ZodiacElement.fire, modality: ZodiacModality.mutable,
      rulingPlanet: 'Jüpiter', dateRange: '22 Kasım – 21 Aralık',
      traits: ['Özgür', 'İyimser', 'Maceracı'],
      strengths: ['Vizyon', 'Dürüstlük'],
      weaknesses: ['Aşırılık'],
      loveStyle: 'Özgürlük ve büyüme arar.',
      careerStyle: 'Eğitim ve keşif.',
    ),
    ZodiacSignContent(
      id: 'capricorn', name: 'Capricorn', nameTr: 'Oğlak', symbol: '♑',
      element: ZodiacElement.earth, modality: ZodiacModality.cardinal,
      rulingPlanet: 'Satürn', dateRange: '22 Aralık – 19 Ocak',
      traits: ['Disiplinli', 'Sorumlu', 'Hırslı'],
      strengths: ['Dayanıklılık', 'Planlama'],
      weaknesses: ['Katılık'],
      loveStyle: 'Ciddi ve uzun vadeli bağ.',
      careerStyle: 'Yönetim ve yapı.',
    ),
    ZodiacSignContent(
      id: 'aquarius', name: 'Aquarius', nameTr: 'Kova', symbol: '♒',
      element: ZodiacElement.air, modality: ZodiacModality.fixed,
      rulingPlanet: 'Uranüs', dateRange: '20 Ocak – 18 Şubat',
      traits: ['Özgün', 'İnsancıl', 'Vizyoner'],
      strengths: ['Yenilik', 'Bağımsızlık'],
      weaknesses: ['Mesafe'],
      loveStyle: 'Zihinsel bağ ve özgürlük.',
      careerStyle: 'Teknoloji ve topluluk.',
    ),
    ZodiacSignContent(
      id: 'pisces', name: 'Pisces', nameTr: 'Balık', symbol: '♓',
      element: ZodiacElement.water, modality: ZodiacModality.mutable,
      rulingPlanet: 'Neptün', dateRange: '19 Şubat – 20 Mart',
      traits: ['Empatik', 'Hayalperest', 'Ruhsal'],
      strengths: ['Sezgi', 'Sanat'],
      weaknesses: ['Kaçış eğilimi'],
      loveStyle: 'Romantik ve birleşici.',
      careerStyle: 'Sanat ve şifa.',
    ),
  ];

  static const _planets = [
    PlanetContent(id: 'sun', name: 'Sun', nameTr: 'Güneş',
        domain: 'Kimlik', influence: 'Benlik ve yaşam amacı.',
        retrogradeNote: 'Güneş retrograde olmaz.'),
    PlanetContent(id: 'moon', name: 'Moon', nameTr: 'Ay',
        domain: 'Duygular', influence: 'İç dünya ve ihtiyaçlar.',
        retrogradeNote: 'Ay retrograde olmaz.'),
    PlanetContent(id: 'mercury', name: 'Mercury', nameTr: 'Merkür',
        domain: 'İletişim', influence: 'Düşünce ve ifade.',
        retrogradeNote: 'Merkür retrosu iletişimde gecikme getirebilir.'),
    PlanetContent(id: 'venus', name: 'Venus', nameTr: 'Venüs',
        domain: 'Aşk', influence: 'Değerler ve estetik.',
        retrogradeNote: 'Venüs retrosu ilişkilerde yeniden değerlendirme.'),
    PlanetContent(id: 'mars', name: 'Mars', nameTr: 'Mars',
        domain: 'Eylem', influence: 'Cesaret ve enerji.',
        retrogradeNote: 'Mars retrosu eylemi yavaşlatır.'),
    PlanetContent(id: 'jupiter', name: 'Jupiter', nameTr: 'Jüpiter',
        domain: 'Büyüme', influence: 'Genişleme ve şans.',
        retrogradeNote: 'Jüpiter retrosu içsel büyümeye odaklanır.'),
    PlanetContent(id: 'saturn', name: 'Saturn', nameTr: 'Satürn',
        domain: 'Disiplin', influence: 'Sorumluluk ve sınırlar.',
        retrogradeNote: 'Satürn retrosu karmik dersleri vurgular.'),
    PlanetContent(id: 'uranus', name: 'Uranus', nameTr: 'Uranüs',
        domain: 'Değişim', influence: 'Ani dönüşümler.',
        retrogradeNote: 'Uranüs retrosu iç devrim.'),
    PlanetContent(id: 'neptune', name: 'Neptune', nameTr: 'Neptün',
        domain: 'Hayal', influence: 'Sezgi ve ilham.',
        retrogradeNote: 'Neptün retrosu illüzyonları temizler.'),
    PlanetContent(id: 'pluto', name: 'Pluto', nameTr: 'Plüton',
        domain: 'Dönüşüm', influence: 'Derin değişim.',
        retrogradeNote: 'Plüton retrosu gölge çalışması.'),
  ];

  static final _houses = List.generate(12, (i) {
    final n = i + 1;
    const names = [
      'Benlik', 'Kaynaklar', 'İletişim', 'Yuva', 'Yaratıcılık', 'Sağlık',
      'İlişkiler', 'Dönüşüm', 'Felsefe', 'Kariyer', 'Topluluk', 'Ruhsallık',
    ];
    const themes = [
      'kimlik', 'değer', 'zihin', 'aile', 'neşe', 'hizmet',
      'ortaklık', 'paylaşım', 'bilgelik', 'statü', 'umut', 'bilinçaltı',
    ];
    return HouseContent(
      number: n,
      nameTr: names[i],
      theme: themes[i],
      lifeArea: names[i],
    );
  });

  static const _aspects = [
    AspectContent(name: 'Conjunction', nameTr: 'Kavuşum', degrees: 0,
        nature: 'Güçlü', meaning: 'Energiler birleşir ve yoğunlaşır.'),
    AspectContent(name: 'Sextile', nameTr: 'Sekstil', degrees: 60,
        nature: 'Uyumlu', meaning: 'Fırsatlar ve kolay akış.'),
    AspectContent(name: 'Square', nameTr: 'Kare', degrees: 90,
        nature: 'Gerilim', meaning: 'Büyüme için zorlu dersler.'),
    AspectContent(name: 'Trine', nameTr: 'Trin', degrees: 120,
        nature: 'Uyumlu', meaning: 'Doğal yetenek ve akış.'),
    AspectContent(name: 'Opposition', nameTr: 'Karşıt', degrees: 180,
        nature: 'Gerilim', meaning: 'Denge ve farkındalık ihtiyacı.'),
  ];

  static const _compatibility = [
    CompatibilityContent(
      id: 'compat_aries_leo',
      signA: 'Koç', signB: 'Aslan', score: 88,
      summary: 'Ateş elementi uyumu; tutku ve enerji paylaşırsınız.',
      strengths: ['Heyecan', 'Cesaret', 'Sadakat'],
      challenges: ['Ego çatışmaları'],
    ),
    CompatibilityContent(
      id: 'compat_taurus_virgo',
      signA: 'Boğa', signB: 'Başak', score: 85,
      summary: 'Toprak elementi uyumu; istikrar ve pratiklik.',
      strengths: ['Güven', 'Sabır'],
      challenges: ['Aşırı eleştiri'],
    ),
    CompatibilityContent(
      id: 'compat_cancer_pisces',
      signA: 'Yengeç', signB: 'Balık', score: 90,
      summary: 'Su elementi uyumu; derin duygusal bağ.',
      strengths: ['Empati', 'Sezgi'],
      challenges: ['Aşırı duygusallık'],
    ),
  ];
}
