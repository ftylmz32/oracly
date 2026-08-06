/// SPRINT-001 — Phase 2: organize dream without interpreting.
library;

import '../../../features/content/dream/data/dream_symbol_catalogue.dart';
import '../../../features/content/dream/models/dream_symbol_content.dart'
    as content;
import '../../../features/oracle_engine/calculators/dream_symbol_calculator.dart';
import '../../../features/oracle_engine/core/oracle_engine_type.dart' as oracle;
import '../../../features/oracle_engine/models/dream_reading.dart';
import '../models/dream.dart';
import '../models/dream_emotion.dart';
import '../models/dream_relationship.dart';
import '../models/dream_symbol.dart';

class DreamUnderstandingService {
  DreamUnderstandingService({
    DreamSymbolCalculator? calculator,
  }) : _calculator = calculator ?? LexiconDreamSymbolCalculator();

  final DreamSymbolCalculator _calculator;

  static const _relationshipTokens = {
    'anne': 'Anne',
    'babam': 'Baba',
    'baba': 'Baba',
    'arkadaş': 'Arkadaş',
    'partner': 'Partner',
    'eş': 'Eş',
    'çocuk': 'Çocuk',
    'kardeş': 'Kardeş',
    'dede': 'Dede',
    'nine': 'Nine',
    'öğretmen': 'Öğretmen',
    'patron': 'Patron',
  };

  static const _locationTokens = {
    'ev': 'Ev',
    'okul': 'Okul',
    'iş': 'İş yeri',
    'deniz': 'Deniz',
    'dağ': 'Dağ',
    'orman': 'Orman',
    'şehir': 'Şehir',
    'sokak': 'Sokak',
    'hastane': 'Hastane',
    'cami': 'Cami',
    'kilise': 'Kilise',
    'köprü': 'Köprü',
    'tren': 'Tren',
    'uçak': 'Uçak',
  };

  DreamUnderstanding build({
    required String narrative,
    List<DreamEmotion> selectedEmotions = const [],
  }) {
    final lower = narrative.toLowerCase();
    final lexiconMatches = _calculator.categorize(narrative);
    final catalogueMatches = _matchCatalogue(lower);
    final symbols = _mergeSymbols(lexiconMatches, catalogueMatches);
    final locations = _extractLocations(lower);
    final relationships = _extractRelationships(lower);
    final recurring = _recurringTokens(lower);
    final emotions = _mergeEmotions(selectedEmotions, lexiconMatches);

    final summary = _buildSummary(
      symbolCount: symbols.length,
      locationCount: locations.length,
      relationshipCount: relationships.length,
      emotionCount: emotions.length,
    );

    return DreamUnderstanding(
      symbols: symbols,
      emotions: emotions,
      locations: locations,
      relationships: relationships,
      recurringElements: recurring,
      summary: summary,
    );
  }

  List<content.DreamSymbolContent> _matchCatalogue(String lower) {
    final hits = <content.DreamSymbolContent>[];
    for (final item in DreamSymbolCatalogue.all) {
      if (lower.contains(item.tokenTr.toLowerCase()) ||
          lower.contains(item.token.toLowerCase())) {
        hits.add(item);
      }
    }
    return hits;
  }

  List<DreamSymbol> _mergeSymbols(
    List<DreamSymbolMatch> lexicon,
    List<content.DreamSymbolContent> catalogue,
  ) {
    final byToken = <String, DreamSymbol>{};

    for (final match in lexicon) {
      byToken[match.token] = DreamSymbol(
        token: match.token,
        label: _capitalize(match.token),
        kind: _mapKind(match.category),
        confidence: match.confidence,
      );
    }

    for (final item in catalogue) {
      final key = item.tokenTr.toLowerCase();
      byToken.putIfAbsent(
        key,
        () => DreamSymbol(
          token: item.token,
          label: item.tokenTr,
          kind: _mapContentKind(item.category),
          confidence: 0.9,
        ),
      );
    }

    return byToken.values.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  List<String> _extractLocations(String lower) {
    final found = <String>[];
    for (final entry in _locationTokens.entries) {
      if (lower.contains(entry.key)) found.add(entry.value);
    }
    return found;
  }

  List<DreamRelationship> _extractRelationships(String lower) {
    final found = <DreamRelationship>[];
    for (final entry in _relationshipTokens.entries) {
      if (lower.contains(entry.key)) {
        found.add(DreamRelationship(label: entry.value, role: entry.value));
      }
    }
    return found;
  }

  List<String> _recurringTokens(String lower) {
    final words = lower
        .replaceAll(RegExp(r'[^\wçğıöşü\s]', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 4)
        .toList();

    final counts = <String, int>{};
    for (final word in words) {
      counts[word] = (counts[word] ?? 0) + 1;
    }

    return counts.entries
        .where((e) => e.value >= 2)
        .map((e) => _capitalize(e.key))
        .take(5)
        .toList();
  }

  List<String> _mergeEmotions(
    List<DreamEmotion> selected,
    List<DreamSymbolMatch> lexicon,
  ) {
    final set = <String>{
      ...selected.map((e) => e.label),
      for (final m in lexicon)
        if (m.category == oracle.DreamSymbolCategory.emotions)
          _capitalize(m.token),
    };
    return set.toList();
  }

  String _buildSummary({
    required int symbolCount,
    required int locationCount,
    required int relationshipCount,
    required int emotionCount,
  }) {
    final parts = <String>[];
    if (symbolCount > 0) parts.add('$symbolCount sembol');
    if (locationCount > 0) parts.add('$locationCount mekân');
    if (relationshipCount > 0) parts.add('$relationshipCount ilişki');
    if (emotionCount > 0) parts.add('$emotionCount duygu');
    if (parts.isEmpty) {
      return 'Rüya metni kaydedildi; belirgin imgeler henüz ayrıştırılamadı.';
    }
    return 'Rüyanda ${parts.join(', ')} öne çıkıyor.';
  }

  DreamSymbolKind _mapKind(oracle.DreamSymbolCategory category) {
    return switch (category) {
      oracle.DreamSymbolCategory.animals => DreamSymbolKind.animal,
      oracle.DreamSymbolCategory.objects => DreamSymbolKind.object,
      oracle.DreamSymbolCategory.colors => DreamSymbolKind.color,
      oracle.DreamSymbolCategory.places => DreamSymbolKind.place,
      oracle.DreamSymbolCategory.emotions => DreamSymbolKind.other,
      oracle.DreamSymbolCategory.religious => DreamSymbolKind.other,
      oracle.DreamSymbolCategory.symbols => DreamSymbolKind.other,
      oracle.DreamSymbolCategory.psychological => DreamSymbolKind.action,
    };
  }

  DreamSymbolKind _mapContentKind(content.DreamSymbolCategory category) {
    return switch (category) {
      content.DreamSymbolCategory.animals => DreamSymbolKind.animal,
      content.DreamSymbolCategory.objects => DreamSymbolKind.object,
      content.DreamSymbolCategory.people => DreamSymbolKind.person,
      content.DreamSymbolCategory.colors => DreamSymbolKind.color,
      content.DreamSymbolCategory.places => DreamSymbolKind.place,
      content.DreamSymbolCategory.nature ||
      content.DreamSymbolCategory.weather =>
        DreamSymbolKind.nature,
      content.DreamSymbolCategory.emotions => DreamSymbolKind.other,
      content.DreamSymbolCategory.religious => DreamSymbolKind.other,
      content.DreamSymbolCategory.numbers => DreamSymbolKind.other,
    };
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
