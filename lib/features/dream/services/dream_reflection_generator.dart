/// SPRINT-001 — Local reflective copy with tone guard.
library;

import '../models/dream.dart';
import '../models/dream_insight.dart';

class DreamReflectionGenerator {
  const DreamReflectionGenerator();

  static const _forbidden = [
    'kesinlikle',
    'mutlaka',
    'kader',
    'felaket',
    'evren seninle',
    'geleceğin',
    'tahmin',
  ];

  List<DreamInsight> generate({
    required Dream dream,
    required DreamUnderstanding understanding,
    String? aiReflectionText,
    DreamInsight? personalConnection,
  }) {
    final symbols = understanding.symbols.map((s) => s.label).take(4).toList();
    final reflectionBody = aiReflectionText?.trim().isNotEmpty == true
        ? _sanitize(aiReflectionText!.trim())
        : _localReflection(dream.narrative, symbols, understanding.emotions);

    final possibilities = _possibilities(symbols, understanding.locations);
    final question = _reflectiveQuestion(symbols);
    final takeaway = _calmingTakeaway();

    return [
      DreamInsight(
        kind: DreamInsightKind.reflection,
        title: 'Düşünmek için alan',
        body: reflectionBody,
      ),
      DreamInsight(
        kind: DreamInsightKind.possibility,
        title: 'Olası okumalar',
        body: possibilities,
      ),
      if (personalConnection != null) personalConnection,
      DreamInsight(
        kind: DreamInsightKind.closingQuestion,
        title: 'Sana bir soru',
        body: question,
      ),
      DreamInsight(
        kind: DreamInsightKind.closingTakeaway,
        title: 'Sakin bir not',
        body: takeaway,
      ),
    ];
  }

  String _localReflection(
    String narrative,
    List<String> symbols,
    List<String> emotions,
  ) {
    if (symbols.isEmpty && emotions.isEmpty) {
      return 'Rüyan kişisel bir dil kullanıyor. '
          'Anlatımın kendi ritmini dinlemek, hazır anlamlara sığdırmaktan '
          'daha faydalı olabilir.';
    }

    final symbolLine = symbols.isEmpty
        ? ''
        : 'Öne çıkan imgeler (${symbols.join(', ')}) ';
    final emotionLine = emotions.isEmpty
        ? ''
        : 'Hissettiğin duygular (${emotions.join(', ')}) ';

    return '${symbolLine}${emotionLine}'
        'birlikte düşünüldüğünde, gündüz yaşadıklarınla sessiz bir '
        'diyalog kuruyor olabilir. Bu yalnızca bir olasılık — '
        'senin bağlamın en doğru rehber.';
  }

  String _possibilities(List<String> symbols, List<String> locations) {
    final lines = <String>[];
    if (symbols.isNotEmpty) {
      lines.add(
        '• ${symbols.first} imgeleri, henüz adlandırmadığın bir duygu '
        'veya kararla ilişkili olabilir.',
      );
    }
    if (locations.isNotEmpty) {
      lines.add(
        '• ${locations.first} mekânı, güven veya değişim temasına '
        'işaret ediyor olabilir.',
      );
    }
    if (lines.isEmpty) {
      lines.add(
        '• Rüya, gün içinde bastırılmış düşüncelerin yumuşak bir '
        'yansıması olabilir.',
      );
    }
    lines.add(
      '• Her imgeler farklı anlamlara açılabilir; en uygun olanı '
      'yalnızca sen seçebilirsin.',
    );
    return lines.join('\n');
  }

  String _reflectiveQuestion(List<String> symbols) {
    if (symbols.isNotEmpty) {
      return '${symbols.first} sana uyandığında ilk hangi anı veya '
          'duygu geliyor?';
    }
    return 'Bu rüyadan sonra bedeninde en çok nerede bir iz kaldı?';
  }

  String _calmingTakeaway() {
    return 'Rüyalar bazen düzenler, bazen karıştırır. '
        'Her ikisi de normal. Bugün kendine biraz yavaşlık tanı.';
  }

  String _sanitize(String text) {
    var out = text;
    for (final phrase in _forbidden) {
      out = out.replaceAll(RegExp(phrase, caseSensitive: false), '…');
    }
    return out;
  }
}
