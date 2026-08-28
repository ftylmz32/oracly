/// Local tarot reading sentences — TR kept, EN/RU written to sound spoken.
library;

import '../l10n_triple.dart';

const kL10nTarotRead = <String, L10nTriple>{
  'tarot.read.hedge.0': L10nTriple(
    'işaret ediyor olabilir',
    'may be pointing here',
    'может указывать на это',
  ),
  'tarot.read.hedge.1': L10nTriple(
    'böyle okunabilir',
    'can be read this way',
    'так можно прочесть',
  ),
  'tarot.read.hedge.2': L10nTriple(
    'burada daha güçlü görünen taraf',
    'the stronger current at this table',
    'здесь сильнее звучит',
  ),
  'tarot.read.hedge.3': L10nTriple(
    'şimdilik böyle duruyor',
    'this is how it sits for now',
    'пока лежит так',
  ),
  'tarot.read.hedge.4': L10nTriple(
    'bu masada daha çok böyle hissediliyor',
    'this is how it feels on this table',
    'за этим столом так ощущается',
  ),
  'tarot.read.slot.past': L10nTriple(
    'Geride kalan etkiyi taşıyor:',
    'It carries what is left behind:',
    'Несёт оставшееся влияние:',
  ),
  'tarot.read.slot.present': L10nTriple(
    'Şu anki duruşu görünür kılıyor:',
    'It makes the present stance visible:',
    'Делает нынешнюю позу видимой:',
  ),
  'tarot.read.slot.obstacle': L10nTriple(
    'Bu konum açılımı değiştirir — sürtünme noktası:',
    'This place changes the spread — a point of friction:',
    'Это место меняет расклад — точка трения:',
  ),
  'tarot.read.slot.hidden': L10nTriple(
    'Yüzeyde durmayanı işaret ediyor:',
    'It points to what is not sitting on the surface:',
    'Указывает на то, что не лежит на поверхности:',
  ),
  'tarot.read.slot.strength': L10nTriple(
    'Eldeki desteği görünür kılıyor:',
    'It makes the support at hand visible:',
    'Делает видимой опору под рукой:',
  ),
  'tarot.read.slot.avoid': L10nTriple(
    'Uzak durmanın yardımcı olabileceği yeri gösteriyor:',
    'It shows where stepping back may help:',
    'Показывает, где может помочь отойти:',
  ),
  'tarot.read.slot.question': L10nTriple(
    'Meselenin kalbini tutuyor:',
    'It holds the heart of the matter:',
    'Держит сердце вопроса:',
  ),
  'tarot.read.slot.direction': L10nTriple(
    'Sembolik yön — kesin bir gelecek değil, izlenebilecek bir eğilim:',
    'A symbolic direction — not a fixed future, a trend that can be followed:',
    'Символический путь — не твёрдое будущее, а тенденция:',
  ),
  'tarot.read.slot.fallback': L10nTriple(
    '{pos} basamağında duruyor:',
    'It stands on the {pos} step:',
    'Стоит на ступени «{pos}»:',
  ),
  'tarot.read.theme.love': L10nTriple('aşk', 'love', 'любовь'),
  'tarot.read.theme.career': L10nTriple('kariyer', 'work', 'дело'),
  'tarot.read.theme.daily': L10nTriple('günlük ritim', 'the day\'s rhythm', 'ритм дня'),
  'tarot.read.theme.general': L10nTriple('genel duruş', 'the wider stance', 'общий стан'),
  'tarot.read.theme.money': L10nTriple('kaynak', 'means', 'средства'),
  'tarot.read.theme.other': L10nTriple('bu açılım', 'this spread', 'этот расклад'),
  'tarot.read.walk': L10nTriple(
    '{name} {pos} konumunda ({hedge}).',
    '{name} in the {pos} place ({hedge}).',
    '{name} в позиции «{pos}» ({hedge}).',
  ),
  'tarot.read.compose.asked': L10nTriple(
    '“{asked}” sorusu kartların birbirine değdiği yerden okunuyor.',
    'The question “{asked}” is read where the cards touch.',
    'Вопрос «{asked}» читается там, где карты соприкасаются.',
  ),
  'tarot.read.compose.asked.wide': L10nTriple(
    '“{asked}” sorusu bu açılımda tek kartla değil; gerilim ve bağlarla birlikte okunuyor.',
    '“{asked}” is read across this spread — not one card alone, but the tensions and links between them.',
    'Вопрос «{asked}» читается по всему раскладу — не одной картой, а напряжениями и связями.',
  ),
  'tarot.read.compose.tension': L10nTriple(
    '“{asked}” için acele bir son yok; masadaki gerilim hâlâ canlı duruyor.',
    'No hurried ending for “{asked}”; the tension on the table is still alive.',
    'Для «{asked}» нет спешного финала; напряжение за столом ещё живо.',
  ),
  'tarot.read.beat.head': L10nTriple(
    '{name}, {pos} konumunda ({ori}) açılımı {hedge}.',
    '{name}, in the {pos} place ({ori}), {hedge} the spread.',
    '{name} в позиции «{pos}» ({ori}) {hedge} расклад.',
  ),
  'tarot.read.beat.body': L10nTriple(
    'Tek başına bir tanım değil; bu konumdaki işi, masadaki duruşu kaydırmak.',
    'Not a definition on its own; it shifts the work of this place, the stance on the table.',
    'Это не словарная статья; она сдвигает работу этой позиции, позу за столом.',
  ),
  'tarot.read.beat.reversed': L10nTriple(
    'Ters duruş, aynı temanın içe dönük veya baskı altındaki halini daha net gösteriyor olabilir.',
    'The reversed stance may show the same theme turned inward or under pressure.',
    'Перевёрнутая поза может яснее показать ту же тему, обращённую внутрь или под давлением.',
  ),
  'tarot.read.beat.asked': L10nTriple(
    '“{asked}” sorusu burada {pos} üzerinden okunuyor.',
    'The question “{asked}” is read here through {pos}.',
    'Вопрос «{asked}» здесь читается через «{pos}».',
  ),
  'tarot.read.beat.next': L10nTriple(
    'Sonraki kart {name}, bu duruşu olduğu gibi bırakmıyor.',
    'The next card, {name}, does not leave this stance as it is.',
    'Следующая карта, {name}, не оставляет эту позу как есть.',
  ),
  'tarot.read.need': L10nTriple(
    'Durduğun yerde asıl ihtiyaç ne?',
    'What is actually needed where you are standing?',
    'Что на самом деле нужно там, где ты стоишь?',
  ),
};
