/// Palm JSON → symbolic fields. Rejects medical / fatal certainty.
library;

class PalmVisionParser {
  PalmVisionParser._();

  static const forbidden = [
    'ömrün',
    'hastalığ',
    'hastalik',
    'kesin olacak',
    'kesin hayatına',
  ];

  static Map<String, dynamic>? fromMap(Map<String, dynamic> json) {
    if (json['usable'] == false || json['okunabilir'] == false) return null;
    final visual = _pick(json, const [
      'visualObservation',
      'gorselTespit',
      'görselTespit',
      'observation',
      'detectedVisual',
    ]);
    final overall = _pick(json, const [
      'overall',
      'genelYapi',
      'genelYapı',
      'genel',
    ]);
    final takeaway = _pick(json, const ['takeaway', 'sonuc', 'sonuç']);
    if (overall.isEmpty && takeaway.isEmpty) return null;
    if (visual.trim().length < 12) return null;
    final parsed = <String, dynamic>{
      'visualObservation': visual,
      'overall': overall,
      'lifeLine': _pick(json, const ['lifeLine', 'yasamCizgisi', 'yaşamÇizgisi']),
      'headLine': _pick(json, const ['headLine', 'zihinCizgisi', 'zihinÇizgisi']),
      'heartLine': _pick(json, const ['heartLine', 'kalpCizgisi', 'kalpÇizgisi']),
      'fateLine': _pick(json, const ['fateLine', 'kaderYon', 'kaderYön']),
      'takeaway': takeaway,
      'symbols': _list(json['symbols'] ?? json['semboller']),
      'themes': _list(json['themes'] ?? json['temalar']),
    };
    final blob = parsed.values.join(' ').toLowerCase();
    for (final word in forbidden) {
      if (blob.contains(word)) return null;
    }
    return parsed;
  }

  static String _pick(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static List<String> _list(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ].take(8).toList();
  }
}
