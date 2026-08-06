/// EPIC-013 — Reflective reading synthesis and tone guard.
library;

import '../../tarot/interpretation/models/interpretation_result.dart';
import '../../tarot/interpretation/models/reading_context.dart';
import '../models/journey_personalization_hints.dart';

/// Builds EPIC-013 readings: observational, uncertain, invitation to reflect.
abstract final class ReflectiveIntelligence {
  ReflectiveIntelligence._();

  static const _forbiddenPhrases = [
    'kesinlikle',
    'mutlaka',
    'evren seninle konuşuyor',
    'evren bugün',
    'ruhsal seviye',
    'kaçınılması gerek',
    'asla',
    'her zaman',
    'kader',
    'felaket',
    'tehlike',
  ];

  static InterpretationResult synthesize({
    required ReadingContext context,
    required String requestId,
  }) {
    final cards = context.cards;
    final primary = cards.first;
    final last = cards.last;
    final spread = context.spreadLabel;
    final question = context.userQuestion?.trim();
    final hints = context.journeyHints;

    final cardNames = cards.map((c) => c.cardName).toSet().toList();
    final reversedCount = cards.where((c) => c.isReversed).length;

    final standout = _whatStandsOut(
      spread: spread,
      question: question,
      primary: primary,
      cardNames: cardNames,
      reversedCount: reversedCount,
      hints: hints,
    );

    final love = _domainLens(cards, 'Aşk ve bağ', primary);
    final career = _domainLens(cards, 'Kariyer ve hedef', cards.length > 1 ? cards[1] : primary);
    final money = _domainLens(cards, 'Maddi denge', last);
    final health = _domainLens(cards, 'Beden ve zihin dengesi', primary);

    final reflection = _reflectionQuestions(primary, cards);
    final suggestion = _gentleSuggestion(last, primary);
    final closing = _calmClosing(spread, primary);

    final themes = primary.keywords.take(3).join(' · ');
    final element = primary.element ?? 'Evrensel';

    return InterpretationResult(
      requestId: requestId,
      sessionId: context.sessionId,
      summary: standout,
      love: love,
      career: career,
      money: money,
      health: health,
      spiritualGuidance: reflection,
      advice: suggestion,
      warnings: _balancedConsiderations(cards),
      luckyEnergy: themes.isEmpty
          ? '$element teması bugün dikkatini çekebilir.'
          : 'Dikkat edilebilecek temalar: $themes · $element',
      dailyFocus:
          '${context.readingDate.day}/${context.readingDate.month} — '
          '${primary.keywords.firstOrNull ?? "Farkındalık"} temasına nazikçe bakmak '
          'yararlı olabilir.',
      closingMessage: closing,
      generatedAt: DateTime.now(),
      source: InterpretationSource.local,
      rawText: _cardDetails(cards),
    );
  }

  /// Softens certainty in AI-generated text without changing structure.
  static InterpretationResult guard(InterpretationResult result) {
    return InterpretationResult(
      requestId: result.requestId,
      sessionId: result.sessionId,
      summary: soften(result.summary),
      love: soften(result.love),
      career: soften(result.career),
      money: soften(result.money),
      health: soften(result.health),
      spiritualGuidance: soften(result.spiritualGuidance),
      advice: soften(result.advice),
      warnings: soften(result.warnings),
      luckyEnergy: soften(result.luckyEnergy),
      dailyFocus: soften(result.dailyFocus),
      closingMessage: soften(result.closingMessage),
      generatedAt: result.generatedAt,
      source: result.source,
      rawText: result.rawText != null ? soften(result.rawText!) : null,
      fromCache: result.fromCache,
    );
  }

  static String soften(String text) {
    if (text.trim().isEmpty) return text;

    var out = text;
    const replacements = <String, String>{
      'Kesinlikle': 'Belki',
      'kesinlikle': 'belki',
      'Mutlaka': 'Olabilir',
      'mutlaka': 'olabilir',
      'Evren seninle konuşuyor': 'Bu okuma senin için bir davet olabilir',
      'evren seninle konuşuyor': 'bu okuma senin için bir davet olabilir',
      'Evren bugün': 'Bugün kendine',
      'evren bugün': 'bugün kendine',
      'Ruhsal Seviye': 'İç yolculuk',
      'ruhsal seviye': 'iç yolculuk',
      'asla ': 'nadiren ',
      'Asla ': 'Nadiren ',
      'her zaman': 'sık sık',
      'Her zaman': 'Sık sık',
      'kader': 'yön',
      'Kader': 'Yön',
    };

    for (final entry in replacements.entries) {
      out = out.replaceAll(entry.key, entry.value);
    }

    return out;
  }

  static bool containsForbiddenTone(String text) {
    final lower = text.toLowerCase();
    return _forbiddenPhrases.any(lower.contains);
  }

  static String _whatStandsOut({
    required String spread,
    required String? question,
    required ReadingCardContext primary,
    required List<String> cardNames,
    required int reversedCount,
    JourneyPersonalizationHints? hints,
  }) {
    final buffer = StringBuffer();

    final preface = hints?.observationalPreface();
    if (preface != null) {
      buffer.writeln(preface);
      buffer.writeln();
    }

    if (question != null && question.isNotEmpty) {
      buffer.write(
        '$spread açılımında "$question" niyetin etrafında kartlar belirdi. ',
      );
    } else {
      buffer.write('$spread açılımında kartlar bir araya geldi. ');
    }

    if (cardNames.length == 1) {
      buffer.write(
        '${primary.cardName} (${primary.orientationLabel}) öne çıkıyor — '
        '${_firstSentence(primary.effectiveMeaning)}',
      );
    } else {
      buffer.write(
        'Öne çıkan kart ${primary.cardName} (${primary.orientationLabel}); '
        'açılımdaki diğer kartlar ${cardNames.skip(1).take(2).join(", ")} '
        'ile birlikte bir tablo oluşturuyor olabilir.',
      );
    }

    if (reversedCount > 0) {
      buffer.write(
        ' $reversedCount ters kart, içe dönük veya henüz netleşmemiş '
        'bir enerjiyi hatırlatıyor olabilir.',
      );
    }

    return buffer.toString().trim();
  }

  static String _domainLens(
    List<ReadingCardContext> cards,
    String domain,
    ReadingCardContext anchor,
  ) {
    final meaning = _firstSentence(anchor.effectiveMeaning);
    return '$domain açısından ${anchor.cardName} (${anchor.orientationLabel}) '
        'kartı, $meaning '
        'Bu yorum bir olasılık — kendi deneyiminle karşılaştırmak yararlı olabilir.';
  }

  static String _reflectionQuestions(
    ReadingCardContext primary,
    List<ReadingCardContext> cards,
  ) {
    final questions = <String>[
      '${primary.cardName} sana ne hatırlatıyor?',
      'Bu kartın mesajı günlük hayatında nerede yankılanıyor olabilir?',
    ];

    if (cards.length > 1) {
      final secondary = cards[cards.length ~/ 2];
      questions.add(
        '${secondary.positionLabel} konumundaki ${secondary.cardName} '
        'sana hangi soruyu sormayı davet ediyor?',
      );
    }

    questions.add(
      'Bugün kendine sormak isteyeceğin nazik bir soru ne olabilir?',
    );

    return questions.map((q) => '• $q').join('\n');
  }

  static String _gentleSuggestion(
    ReadingCardContext last,
    ReadingCardContext primary,
  ) {
    final seed = _firstSentence(last.effectiveMeaning);
    return 'Küçük bir adım olarak: ${seed.toLowerCase()} '
        'Bugün niyetini zorlamadan, kendi ritmine saygı duyarak ilerlemek '
        'yeterli olabilir.';
  }

  static String _balancedConsiderations(List<ReadingCardContext> cards) {
    if (cards.any((c) => c.isReversed)) {
      return 'Ters kartlar bazen yavaşlama veya içe dönüşü işaret edebilir — '
          'acele etmek yerine kendine biraz alan tanımak düşünülebilir.';
    }
    return 'Hızlı kararlar yerine bir an durup ne hissettiğine bakmak, '
        'okumayı daha kişisel kılabilir.';
  }

  static String _calmClosing(String spread, ReadingCardContext primary) {
    return '${primary.cardName} bugün seninle kalsın — bir cevap değil, '
        'sessiz bir yankı. Bu birkaç dakika kendi iç sesine alan açtıysa, '
        'ne hissediyorsan o yeterli.';
  }

  static String _cardDetails(List<ReadingCardContext> cards) {
    return cards
        .map(
          (c) =>
              '${c.positionLabel}: ${c.cardName} (${c.orientationLabel}) — ${c.effectiveMeaning}',
        )
        .join('\n');
  }

  static String _firstSentence(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'içsel bir tema taşıyor olabilir.';
    final dot = trimmed.indexOf('.');
    if (dot > 0 && dot < trimmed.length - 1) {
      return trimmed.substring(0, dot + 1);
    }
    return trimmed.endsWith('.') ? trimmed : '$trimmed.';
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
