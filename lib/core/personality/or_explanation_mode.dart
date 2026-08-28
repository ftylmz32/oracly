/// How the user wants the last topic explained — not a personality switch.
library;

import '../../features/ai/production/models/conversation_turn.dart';
import '../../features/companion/data/companion_intent.dart';

enum ExplanationShape { detailed, simple, example, stepByStep }

enum ExplanationDomain { technical, life, fortune }

abstract final class OrExplanationMode {
  OrExplanationMode._();

  static ExplanationShape? parseShape(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return null;
    if (_has(t, [
      'detaylı anlat',
      'detayli anlat',
      'daha detaylı',
      'ayrıntılı anlat',
      'explain in detail',
      'more detail',
      'go deeper',
      'подробнее',
      'подробно расскажи',
    ])) {
      return ExplanationShape.detailed;
    }
    if (_has(t, [
      'basit anlat',
      'basitleştir',
      'sade anlat',
      'daha basit',
      'explain simply',
      'in simple terms',
      'keep it simple',
      'проще',
      'попроще',
    ])) {
      return ExplanationShape.simple;
    }
    if (_has(t, [
      'örnek ver',
      'örnekle anlat',
      'örnek olarak',
      'give an example',
      'for example',
      'with an example',
      'пример',
      'приведи пример',
    ])) {
      return ExplanationShape.example;
    }
    if (_has(t, [
      'adım adım',
      'adim adim',
      'step by step',
      'step-by-step',
      'шаг за шагом',
      'по шагам',
    ])) {
      return ExplanationShape.stepByStep;
    }
    return null;
  }

  static ExplanationDomain resolveDomain(
    String message,
    List<ConversationTurn> turns,
  ) {
    if (CompanionIntent.isKnowledge(message) ||
        CompanionIntent.isPythonAsync(message)) {
      return ExplanationDomain.technical;
    }
    if (CompanionIntent.isFortune(message.toLowerCase())) {
      return ExplanationDomain.fortune;
    }
    for (var i = turns.length - 1; i >= 0; i--) {
      final line = turns[i].text;
      if (CompanionIntent.isKnowledge(line) ||
          CompanionIntent.isPythonAsync(line)) {
        return ExplanationDomain.technical;
      }
      if (CompanionIntent.isFortune(line.toLowerCase())) {
        return ExplanationDomain.fortune;
      }
    }
    return ExplanationDomain.life;
  }

  static String? hintFor(String message, List<ConversationTurn> turns) {
    final shape = parseShape(message);
    if (shape == null) return null;
    return _hint(shape, resolveDomain(message, turns));
  }

  static String? mergeHint(
    String? discovery, {
    required String message,
    required List<ConversationTurn> turns,
  }) {
    final explanation = hintFor(message, turns);
    if (explanation == null) return discovery;
    final base = (discovery ?? '').trim();
    return base.isEmpty ? explanation : '$base $explanation';
  }

  static String _hint(ExplanationShape shape, ExplanationDomain domain) {
    final shapeLine = switch (shape) {
      ExplanationShape.detailed => 'Kullanıcı detaylı anlat istedi.',
      ExplanationShape.simple => 'Kullanıcı basit anlat istedi.',
      ExplanationShape.example => 'Kullanıcı örnek istedi.',
      ExplanationShape.stepByStep => 'Kullanıcı adım adım istedi.',
    };
    final domainLine = switch (domain) {
      ExplanationDomain.technical =>
        'Teknik konu: net ve kesin kal; sembolik veya fal dili kullanma.',
      ExplanationDomain.fortune =>
        'Fal/sembol konu: gözlemci sembolik okuma; ansiklopedi veya kesinlik yok.',
      ExplanationDomain.life =>
        'Hayat/duygu konusu: sıcak günlük konuşma; terapist veya teknik jargon yok.',
    };
    final adapt = switch (shape) {
      ExplanationShape.detailed =>
        'Önceki tura bağlanarak derinleştir; yeni konu açma.',
      ExplanationShape.simple =>
        'Aynı özü koru; gereksiz ayrıntı ve süslü dil at.',
      ExplanationShape.example =>
        'Somut, kısa bir örnek ver; uydurma anı yok.',
      ExplanationShape.stepByStep =>
        'Numaralı adımlar; her adım tek net cümle.',
    };
    return '$shapeLine $domainLine $adapt '
        'Kişilik veya üslup ayarı değişmez; yalnızca anlatım şekli.';
  }

  static bool _has(String text, List<String> needles) {
    for (final needle in needles) {
      if (text.contains(needle)) return true;
    }
    return false;
  }
}
