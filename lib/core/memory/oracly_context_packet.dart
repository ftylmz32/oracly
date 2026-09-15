library;

import 'oracly_memory.dart';

class OraclyContextItem {
  const OraclyContextItem({required this.memory, required this.score});
  final OraclyMemory memory;
  final double score;
}

class OraclyContextPacket {
  const OraclyContextPacket({
    required this.currentIntent,
    required this.currentEvidence,
    required this.items,
    required this.recurringThemes,
  });
  final String? currentIntent;
  final List<String> currentEvidence;
  final List<OraclyContextItem> items;
  final List<String> recurringThemes;

  bool get hasHistory => items.isNotEmpty;

  String toPrompt({int maxCharacters = 1200}) {
    if (items.isEmpty) return '';
    final lines = <String>[
      if (currentIntent?.isNotEmpty == true)
        'Şimdiki niyet/soru: $currentIntent',
      if (currentEvidence.isNotEmpty)
        'Şimdiki okumanın birincil kanıtı: ${currentEvidence.join(', ')}.',
      'Yalnızca aşağıdaki gerçek, kaynaklı geçmişi kullan. İlgisizse hiç anma.',
      for (final item in items)
        '[${item.memory.source.type.name} | ${_date(item.memory.source.occurredAt)} | '
            '${item.memory.source.id}] ${item.memory.summary}',
      if (recurringThemes.isNotEmpty)
        'Birden fazla gerçek kaynakta görülen temalar: ${recurringThemes.join(', ')}.',
      'Geçmişle çelişki varsa kesin bağlantı kurma; olasılık dili kullan.',
    ];
    final text = lines.join('\n');
    return text.length <= maxCharacters
        ? text
        : text.substring(0, maxCharacters);
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
