/// Recurring-theme sentence templates — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nThemeCopy = <String, L10nTriple>{
  'theme.copy.insufficient': L10nTriple(
    'Henüz yeterli keşif birikmedi.',
    'Not enough discoveries have gathered yet.',
    'Пока недостаточно открытий.',
  ),
  'theme.copy.accumulating': L10nTriple(
    'Keşiflerin biriktikçe sana özel bağlantılar daha görünür olacak.',
    'As discoveries gather, connections unique to you become clearer.',
    'По мере накопления открытий связи, особые для тебя, станут яснее.',
  ),
  'theme.copy.recurring1': L10nTriple(
    'Son keşiflerinde tekrar eden bir iz: {a}.',
    'A mark returning in your recent discoveries: {a}.',
    'След, возвращающийся в недавних открытиях: {a}.',
  ),
  'theme.copy.recurring2': L10nTriple(
    'Son keşiflerinde tekrar eden izler: {a} ve {b}.',
    'Marks returning in your recent discoveries: {a} and {b}.',
    'Следы, возвращающиеся в недавних открытиях: {a} и {b}.',
  ),
  'theme.copy.recurring3': L10nTriple(
    'Son keşiflerinde tekrar eden izler: {a}, {b} ve {c}.',
    'Marks returning in your recent discoveries: {a}, {b} and {c}.',
    'Следы, возвращающиеся в недавних открытиях: {a}, {b} и {c}.',
  ),
  'theme.copy.cross_change': L10nTriple(
    'Son dönemde değişim konusu birkaç farklı keşfinde yeniden karşına çıkıyor. Bunu tek bir sonuca bağlamazdım ama canlı bir mesele olduğu belli.',
    'Lately the theme of change has been meeting you again across a few discoveries. I would not tie it to one conclusion, but it is clearly alive for you.',
    'В последнее время тема перемен снова встречается тебе в разных открытиях. Я бы не сводил это к одному выводу, но ясно, что вопрос живой.',
  ),
  'theme.copy.cross1': L10nTriple(
    'Son dönemde {a} konusu birkaç farklı keşfinde yeniden karşına çıkıyor. Bunu tek bir sonuca bağlamazdım ama şu an hayatında canlı bir mesele olduğu belli.',
    'Lately {a} has been meeting you again across a few discoveries. I would not tie it to one conclusion, but it is clearly alive in your life right now.',
    'В последнее время тема {a} снова встречается тебе в разных открытиях. Я бы не сводил это к одному выводу, но сейчас в твоей жизни это явно живой вопрос.',
  ),
  'theme.copy.cross2': L10nTriple(
    'Son dönemde {a} ve {b} konusu birkaç farklı keşfinde yeniden karşına çıkıyor. Bunu tek bir sonuca bağlamazdım ama şu an hayatında gerçekten canlı bir mesele olduğu belli.',
    'Lately {a} and {b} have been meeting you again across a few discoveries. I would not tie them to one conclusion, but they are clearly alive in your life right now.',
    'В последнее время темы {a} и {b} снова встречаются тебе в разных открытиях. Я бы не сводил это к одному выводу, но сейчас в твоей жизни это явно живой вопрос.',
  ),
  'theme.copy.cross3': L10nTriple(
    'Son dönemde {a}, {b} ve {c} birkaç farklı keşfinde yeniden karşına çıkıyor. Tek sonuca bağlamazdım; yine de birlikte duruyorlar.',
    'Lately {a}, {b} and {c} have been meeting you again across a few discoveries. I would not force one conclusion; still, they sit together.',
    'В последнее время {a}, {b} и {c} снова встречаются тебе в разных открытиях. К одному выводу не сводил бы; всё же они стоят вместе.',
  ),
  'theme.copy.today_change': L10nTriple(
    'Son dönemde değişim konusu birkaç farklı keşfinde yeniden karşına çıkıyor.',
    'Lately the theme of change has been meeting you again across a few discoveries.',
    'В последнее время тема перемен снова встречается тебе в разных открытиях.',
  ),
  'theme.copy.today': L10nTriple(
    'Son keşiflerinde tekrar eden iz {focus}.',
    'The mark returning in recent discoveries is {focus}.',
    'След, возвращающийся в недавних открытиях, — {focus}.',
  ),
  'theme.copy.insight1': L10nTriple(
    'Son dönemde {a} konusu birkaç farklı keşfinde yeniden karşına çıkıyor.',
    'Lately {a} has been meeting you again across a few discoveries.',
    'В последнее время тема {a} снова встречается тебе в разных открытиях.',
  ),
  'theme.copy.insight2': L10nTriple(
    'Son dönemde {focus} birkaç farklı keşfinde yeniden karşına çıkıyor.',
    'Lately {focus} have been meeting you again across a few discoveries.',
    'В последнее время {focus} снова встречаются тебе в разных открытиях.',
  ),
  'theme.copy.insight_direct': L10nTriple(
    'Bugün bu iki konu net biçimde görünüyor.',
    'Today these two subjects are clearly visible.',
    'Сегодня эти две темы видны ясно.',
  ),
  'theme.copy.and': L10nTriple('{a} ve {b}', '{a} and {b}', '{a} и {b}'),
  'theme.copy.line': L10nTriple(
    'Son keşiflerinde {theme} izi {n} alanda yeniden görünüyor. {why}',
    'In recent discoveries the theme {theme} shows again across {n} areas. {why}',
    'В недавних открытиях тема {theme} снова видна в {n} областях. {why}',
  ),
  'theme.copy.divert': L10nTriple(
    'Son keşiflerinde {previous} izi sık göründü. Bu kez {theme} tarafına bakmak daha anlamlı olabilir.',
    'In recent discoveries the theme {previous} appeared often. This time looking toward {theme} may be more meaningful.',
    'В недавних открытиях тема {previous} встречалась часто. Сейчас взгляд в сторону {theme} может быть осмысленнее.',
  ),
  'or.ctx.observed': L10nTriple(
    'Son dönemde birkaç farklı keşfinde yeniden duran izler: {themes}.',
    'Lately these marks have returned across a few discoveries: {themes}.',
    'В последнее время эти следы снова встречались в разных открытиях: {themes}.',
  ),
  'or.ctx.style': L10nTriple(
    'Üslup tercihi: {style}.',
    'Preferred tone: {style}.',
    'Предпочтительный тон: {style}.',
  ),
  'or.ctx.instruction': L10nTriple(
    'Yalnızca keşiflerinde gerçekten görünen izi bağla. Yoksa uydurma; nazikçe açmasını iste. Kullanıcıyı etiketleme. Gözlemi gerçek gibi sunma. Sistem, kayıt veya iç mekanik dilinden bahsetme.',
    'Link only a theme that has truly shown up in their discoveries. If none, do not invent; invite them to share. Do not label them. Never present an observation as hard fact. Do not mention systems, records, or internal mechanics.',
    'Связывай только тему, что правда встречалась в открытиях. Если нет — не выдумывай; мягко пригласи рассказать. Не ставь ярлык. Не подавай наблюдение как твёрдый факт. Не говори о системах, записях или внутренней механике.',
  ),
  'or.ctx.areas': L10nTriple(
    'Gözlenen alanlar: {areas}.',
    'Observed areas: {areas}.',
    'Наблюдаемые области: {areas}.',
  ),
  'or.ctx.chamber.tarot': L10nTriple('Tarot', 'Tarot', 'Таро'),
  'or.ctx.chamber.coffee': L10nTriple('Kahve', 'Coffee', 'Кофе'),
  'or.ctx.chamber.astrology': L10nTriple('Astroloji', 'Astrology', 'Астрология'),
  'or.ctx.chamber.star_map': L10nTriple('Yıldızname', 'Star map', 'Йылдызнаме'),
  'or.ctx.chamber.palm': L10nTriple('El', 'Palm', 'Ладонь'),
  'or.ctx.chamber.daily': L10nTriple(
    'Günlük mesaj',
    'Daily message',
    'Ежедневное сообщение',
  ),
  'or.ctx.chamber.reflection': L10nTriple('OR', 'OR', 'OR'),
};
