/// Phase 5C — Signature Spread product copy (TR / EN / RU).
library;

import '../l10n_triple.dart';

const kL10nTarotSignature = <String, L10nTriple>{
  // Canonical blurb aliases (legacy three/five.blurb remain in table_tarot).
  'tarot.spread.threeCard.blurb': L10nTriple(
    'Geçmiş · Şimdi · Gelecek',
    'Past · Present · Future',
    'Прошлое · Настоящее · Будущее',
  ),
  'tarot.spread.fiveCard.blurb': L10nTriple(
    'Durum · Zorluk · Güç · Yön',
    'Situation · Challenge · Strength · Direction',
    'Ситуация · Трудность · Сила · Путь',
  ),
  'tarot.spread.single.purpose': L10nTriple(
    'Şu an dikkatini hak eden şeyi tek bir kartla netleştir.',
    'Clarify what deserves your attention right now with a single card.',
    'Одной картой проясни, что сейчас действительно заслуживает твоего внимания.',
  ),
  'tarot.spread.threeCard.purpose': L10nTriple(
    'Konunun geçmişten bugüne nasıl geldiğini ve önünde hangi yönün açıldığını gör.',
    'See how the situation moved from the past into the present and what direction opens next.',
    'Посмотри, как ситуация пришла из прошлого в настоящее и какое направление открывается дальше.',
  ),
  'tarot.spread.fiveCard.purpose': L10nTriple(
    'Durumu; görünmeyen etkiyi, zorluğu, desteği ve önündeki yönü birlikte gör.',
    'See the situation together with its hidden influence, challenge, support, and the direction ahead.',
    'Рассмотри ситуацию вместе со скрытым влиянием, трудностью, поддержкой и направлением впереди.',
  ),
  'tarot.spread.crossroads.purpose': L10nTriple(
    'İki seçeneği, aradaki gerilimi ve sana en dürüst gelen sonraki adımı birlikte gör.',
    'See both options, the tension between them, and the next step that feels most honest to you.',
    'Рассмотри оба варианта, напряжение между ними и следующий шаг, который ощущается для тебя наиболее честным.',
  ),
  'tarot.spread.crossroads': L10nTriple(
    'Yol Ayrımı',
    'Crossroads',
    'Перекрёсток',
  ),
  'tarot.spread.crossroads.banner': L10nTriple(
    'YOL AYRIMI',
    'CROSSROADS',
    'ПЕРЕКРЁСТОК',
  ),
  'tarot.spread.crossroads.blurb': L10nTriple(
    'İki yol · Gerilim · Rehberlik · Yön',
    'Two paths · Tension · Counsel · Direction',
    'Два пути · Напряжение · Подсказка · Направление',
  ),
  'tarot.pos.option_a': L10nTriple('Seçenek A', 'Option A', 'Вариант A'),
  'tarot.pos.option_b': L10nTriple('Seçenek B', 'Option B', 'Вариант B'),
  'tarot.pos.tension': L10nTriple('Gerilim', 'Tension', 'Напряжение'),
  'tarot.pos.counsel': L10nTriple('Rehberlik', 'Counsel', 'Подсказка'),
};
