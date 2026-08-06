/// OR-437 — Local enrichment for ritual journal entries (no AI calls).
library;

import '../../../../core/domain/models/ritual_journal_metadata.dart';
import '../../insights/services/personal_insight_engine.dart';

/// Derives mood keywords and excerpts from saved interpretation text.
abstract final class RitualJournalEnricher {
  RitualJournalEnricher._();

  static const _lexicon = <String, String>{
    'umut': 'Umut',
    'huzur': 'Huzur',
    'sakin': 'Sakinlik',
    'sabır': 'Sabır',
    'sabir': 'Sabır',
    'dönüşüm': 'Dönüşüm',
    'donusum': 'Dönüşüm',
    'yenilen': 'Yenilenme',
    'aşk': 'Aşk',
    'ask': 'Aşk',
    'sevgi': 'Sevgi',
    'bağ': 'Bağ',
    'bag': 'Bağ',
    'sezgi': 'Sezgi',
    'iç ses': 'İç Ses',
    'ic ses': 'İç Ses',
    'bilgelik': 'Bilgelik',
    'cesaret': 'Cesaret',
    'korku': 'Korku',
    'endişe': 'Endişe',
    'endise': 'Endişe',
    'belirsiz': 'Belirsizlik',
    'netlik': 'Netlik',
    'aydınlan': 'Aydınlanma',
    'aydinlan': 'Aydınlanma',
    'rehberlik': 'Rehberlik',
    'şifa': 'Şifa',
    'sifa': 'Şifa',
    'güç': 'Güç',
    'guc': 'Güç',
    'denge': 'Denge',
    'bolluk': 'Bolluk',
    'minnet': 'Minnet',
    'yalnız': 'Yalnızlık',
    'yalniz': 'Yalnızlık',
    'neşe': 'Neşe',
    'nese': 'Neşe',
    'kapan': 'Kapanış',
    'başlangıç': 'Başlangıç',
    'baslangic': 'Başlangıç',
    'yolculuk': 'Yolculuk',
    'ruhsal': 'Ruhsal',
    'meditasyon': 'Meditasyon',
    'dinlen': 'Dinlenme',
    'acele': 'Acele',
    'sakinleş': 'Sakinleşme',
    'sakinles': 'Sakinleşme',
  };

  static const _cardMood = <String, List<String>>{
    'star': ['Umut', 'Huzur'],
    'moon': ['Sezgi', 'Belirsizlik'],
    'sun': ['Neşe', 'Aydınlanma'],
    'lovers': ['Aşk', 'Seçim'],
    'hermit': ['Bilgelik', 'Yalnızlık'],
    'death': ['Dönüşüm', 'Kapanış'],
    'tower': ['Değişim', 'Sarsıntı'],
    'world': ['Tamamlanma', 'Bolluk'],
    'fool': ['Başlangıç', 'Cesaret'],
    'empress': ['Bolluk', 'Şefkat'],
    'emperor': ['Düzen', 'Güç'],
    'high priestess': ['Sezgi', 'Sakinlik'],
    'magician': ['Netlik', 'Güç'],
    'judgement': ['Uyanış', 'Yenilenme'],
    'temperance': ['Denge', 'Sabır'],
    'wheel': ['Değişim', 'Döngü'],
    'strength': ['Cesaret', 'Sabır'],
    'chariot': ['İlerleme', 'Karar'],
    'justice': ['Denge', 'Netlik'],
    'hanged': ['Bekleyiş', 'Perspektif'],
    'devil': ['Bağımlılık', 'Farkındalık'],
  };

  static RitualJournalMetadata enrich({
    required String aiSummary,
    required String cardName,
    String? existingNote,
    String? intention,
    bool isFavorite = false,
  }) {
    return RitualJournalMetadata(
      emotionalKeywords: extractKeywords(
        aiSummary: aiSummary,
        cardName: cardName,
      ),
      summaryExcerpt: excerpt(aiSummary),
      personalNote: existingNote,
      isFavorite: isFavorite,
      tags: PersonalInsightEngine.tagsForReading(
        aiSummary: aiSummary,
        cardName: cardName,
        intention: intention,
      ),
    );
  }

  static List<String> extractKeywords({
    required String aiSummary,
    required String cardName,
  }) {
    final normalized = '${aiSummary.toLowerCase()} ${cardName.toLowerCase()}';
    final found = <String>{};

    for (final entry in _lexicon.entries) {
      if (normalized.contains(entry.key)) {
        found.add(entry.value);
      }
    }

    for (final entry in _cardMood.entries) {
      if (normalized.contains(entry.key)) {
        found.addAll(entry.value);
      }
    }

    final list = found.toList();
    if (list.length < 2) {
      list.addAll(['Yansıma', 'Ritüel'].where((t) => !list.contains(t)));
    }
    return list.take(4).toList();
  }

  static String excerpt(String aiSummary, {int maxLength = 140}) {
    final cleaned = aiSummary
        .replaceAll(RegExp(r'##\s*\w+\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length <= maxLength) return cleaned;
    final cut = cleaned.substring(0, maxLength);
    final lastSpace = cut.lastIndexOf(' ');
    final base = lastSpace > 60 ? cut.substring(0, lastSpace) : cut;
    return '$base…';
  }
}
