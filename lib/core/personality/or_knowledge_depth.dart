/// OR knowledge depth — broad domains via the live provider, never topic FAQs.
library;

import '../l10n/l10n.dart';

/// Invites real model knowledge across life domains without scripting answers.
abstract final class OrKnowledgeDepth {
  OrKnowledgeDepth._();

  static String get promptRule => switch (OraclyL10n.code) {
        'en' => promptEn,
        'ru' => promptRu,
        _ => promptTr,
      };

  static const promptTr =
      'Geniş bilgiyle konuş: ilişki, iş, psikoloji, günlük hayat, bilim, '
      'teknoloji, kültür, yaratıcılık, pratik kararlar ve ORACLY keşifleri '
      '(yalnızca verilen bağlamda). Konu-bazlı hazır cevap uydurma. '
      'Sağlayıcının gerçek bilgisini kullan; ansiklopedi dökümü veya '
      'kapsam-dışı ret yok. Bilmiyorsan uydurma; keşfi olgu gibi icat etme.';

  static const promptEn =
      'Speak with broad knowledge across relationships, work, psychology, '
      'everyday life, science, technology, culture, creativity, practical '
      'decisions, and ORACLY discoveries (only when context is provided). '
      'Do not invent topic-scripted answers. Use the provider\'s real '
      'knowledge; no encyclopedia dumps or out-of-scope refusals. '
      'If you do not know, say so; never invent a discovery as fact.';

  static const promptRu =
      'Говори с широким знанием: отношения, работа, психология, '
      'повседневность, наука, технология, культура, творчество, практические '
      'решения и открытия ORACLY (только из данного контекста). '
      'Не выдумывай тематические скрипты. Используй реальное знание модели; '
      'без энциклопедии и отказов «вне темы». Не знаешь — скажи; '
      'не выдумывай открытие как факт.';
}


