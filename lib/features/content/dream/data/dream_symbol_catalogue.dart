/// OR-1150 — Dream symbol sample database.
library;

import '../models/dream_symbol_content.dart';

abstract final class DreamSymbolCatalogue {
  DreamSymbolCatalogue._();

  static List<DreamSymbolContent> get all => _symbols;

  static DreamSymbolContent? byId(String id) {
    for (final s in _symbols) {
      if (s.id == id) return s;
    }
    return null;
  }

  static DreamSymbolContent? byToken(String token) {
    final lower = token.toLowerCase();
    for (final s in _symbols) {
      if (s.token.toLowerCase() == lower ||
          s.tokenTr.toLowerCase() == lower) {
        return s;
      }
    }
    return null;
  }

  static List<DreamSymbolContent> byCategory(DreamSymbolCategory category) {
    return _symbols.where((s) => s.category == category).toList();
  }

  static const _symbols = [
    DreamSymbolContent(
      id: 'dream_cat',
      token: 'cat',
      tokenTr: 'Kedi',
      category: DreamSymbolCategory.animals,
      meaning: 'Bağımsızlık, sezgi ve gizemli rehberlik.',
      psychologicalNote: 'Kedi genellikle özerk yönünü ve iç sesini temsil eder.',
      relatedSymbols: ['kadın enerjisi', 'gece', 'gizem'],
      tagList: ['hayvan', 'sezgi', 'bağımsızlık'],
    ),
    DreamSymbolContent(
      id: 'dream_snake',
      token: 'snake',
      tokenTr: 'Yılan',
      category: DreamSymbolCategory.animals,
      meaning: 'Dönüşüm, şifa ve bilinçaltı gücü.',
      psychologicalNote: 'Yılan korkuların ve yenilenmenin sembolüdür.',
      relatedSymbols: ['kundalini', 'değişim'],
      tagList: ['hayvan', 'dönüşüm', 'şifa'],
    ),
    DreamSymbolContent(
      id: 'dream_door',
      token: 'door',
      tokenTr: 'Kapı',
      category: DreamSymbolCategory.objects,
      meaning: 'Yeni fırsatlar ve geçiş dönemleri.',
      psychologicalNote: 'Açık kapı seçim, kapalı kapı engel veya koruma gösterebilir.',
      relatedSymbols: ['eşik', 'yol'],
      tagList: ['nesne', 'geçiş', 'fırsat'],
    ),
    DreamSymbolContent(
      id: 'dream_water',
      token: 'water',
      tokenTr: 'Su',
      category: DreamSymbolCategory.nature,
      meaning: 'Duygusal akış, arınma ve bilinçaltı derinliği.',
      psychologicalNote: 'Berrak su netlik, dalgalı su duygusal karmaşa anlatır.',
      relatedSymbols: ['deniz', 'nehir', 'yağmur'],
      tagList: ['doğa', 'duygu', 'arınma'],
    ),
    DreamSymbolContent(
      id: 'dream_red',
      token: 'red',
      tokenTr: 'Kırmızı',
      category: DreamSymbolCategory.colors,
      meaning: 'Tutku, canlılık ve güçlü duygular.',
      psychologicalNote: 'Kırmızı genellikle bastırılmış enerjinin yüzeye çıkışını gösterir.',
      relatedSymbols: ['ateş', 'kan'],
      tagList: ['renk', 'tutku', 'enerji'],
    ),
    DreamSymbolContent(
      id: 'dream_mosque',
      token: 'mosque',
      tokenTr: 'Cami',
      category: DreamSymbolCategory.religious,
      meaning: 'Manevi arayış, huzur ve topluluk duygusu.',
      psychologicalNote: 'Kutsal mekanlar iç rehberlik ve bağlılık ihtiyacını yansıtır.',
      relatedSymbols: ['dua', 'ibadet'],
      tagList: ['din', 'huzur', 'manevi'],
    ),
    DreamSymbolContent(
      id: 'dream_fear',
      token: 'fear',
      tokenTr: 'Korku',
      category: DreamSymbolCategory.emotions,
      meaning: 'Bastırılmış endişe veya korunma ihtiyacı.',
      psychologicalNote: 'Rüyadaki korku genellikle gündüz bastırılan duyguların mesajıdır.',
      relatedSymbols: ['kaçış', 'karanlık'],
      tagList: ['duygu', 'korku', 'korunma'],
    ),
    DreamSymbolContent(
      id: 'dream_sea',
      token: 'sea',
      tokenTr: 'Deniz',
      category: DreamSymbolCategory.places,
      meaning: 'Bilinçaltının sınırsız derinliği.',
      psychologicalNote: 'Deniz hem özgürlük hem bilinmeyen korkuları simgeler.',
      relatedSymbols: ['su', 'ufuk'],
      tagList: ['mekan', 'derinlik', 'bilinçaltı'],
    ),
    DreamSymbolContent(
      id: 'dream_rain',
      token: 'rain',
      tokenTr: 'Yağmur',
      category: DreamSymbolCategory.weather,
      meaning: 'Arınma, duygusal boşalma ve yenilenme.',
      psychologicalNote: 'Yağmur sonrası berraklık metaforu sık görülür.',
      relatedSymbols: ['su', 'bulut'],
      tagList: ['hava', 'arınma', 'yenilenme'],
    ),
    DreamSymbolContent(
      id: 'dream_seven',
      token: 'seven',
      tokenTr: 'Yedi',
      category: DreamSymbolCategory.numbers,
      meaning: 'Ruhsal arayış ve içsel bilgelik.',
      psychologicalNote: 'Yedi sayısı sezgi ve mistik döngülerle ilişkilidir.',
      relatedSymbols: ['chakra', 'hafta'],
      tagList: ['sayı', 'ruhsal', 'bilgelik'],
    ),
    DreamSymbolContent(
      id: 'dream_mother',
      token: 'mother',
      tokenTr: 'Anne',
      category: DreamSymbolCategory.people,
      meaning: 'Besleyicilik, kökler ve koruma.',
      psychologicalNote: 'Anne figürü iç child ve güven ihtiyacını temsil eder.',
      relatedSymbols: ['aile', 'ev'],
      tagList: ['kişi', 'aile', 'koruma'],
    ),
  ];
}
