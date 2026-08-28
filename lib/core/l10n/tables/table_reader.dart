/// Human-reader sentence banks — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nReader = <String, L10nTriple>{
  'reader.vessel.cup': L10nTriple('bu fincanda', 'in this cup', 'в этой чашке'),
  'reader.vessel.sky':
      L10nTriple('bugünkü duruşunda', "in today's posture", 'в сегодняшней позе'),
  'reader.vessel.chart': L10nTriple('bu izde', 'in this trace', 'в этом следе'),
  'reader.vessel.palm': L10nTriple('bu avuçta', 'on this palm', 'на этой ладони'),
  'reader.vessel.spread':
      L10nTriple('bu açılımda', 'in this spread', 'в этом раскладе'),
  'reader.see.0': L10nTriple(
    '{who}Şu izle duruyorum: {seen}.',
    '{who}I am staying with this mark: {seen}.',
    '{who}Я остаюсь с этим следом: {seen}.',
  ),
  'reader.see.1': L10nTriple(
    '{who}İlk baktığım yerde {seen} duruyor.',
    '{who}Where I look first, {seen} is sitting.',
    '{who}Где я смотрю сначала, стоит {seen}.',
  ),
  'reader.see.2': L10nTriple(
    '{who}Bunu {seen} üzerinden okumaya başlıyorum.',
    '{who}I begin the reading from {seen}.',
    '{who}Я начинаю чтение с {seen}.',
  ),
  'reader.see.3': L10nTriple(
    '{who}Burada seçilir duran şey {seen}.',
    '{who}What sits clearly here is {seen}.',
    '{who}Здесь ясно стоит {seen}.',
  ),
  'reader.see.4': L10nTriple(
    '{who}Asıl durduğum yer {seen}.',
    '{who}The place I actually stop is {seen}.',
    '{who}Место, где я действительно останавливаюсь — {seen}.',
  ),
  'reader.link.0': L10nTriple(
    '{companion} ile yan yana gelince hikâye değişiyor.',
    'When it sits together with {companion}, the story changes.',
    'Когда рядом {companion}, история меняется.',
  ),
  'reader.link.1': L10nTriple(
    '{seen} yanında {companion} durunca bağ kuruluyor.',
    'A bond appears when {seen} sits beside {companion}.',
    'Связь появляется, когда {seen} стоит рядом с {companion}.',
  ),
  'reader.link.2': L10nTriple(
    '{seen} ve {companion} aynı masada; birini yok saymak yapay durur.',
    '{seen} and {companion} share the table; ignoring one feels false.',
    '{seen} и {companion} за одним столом; отрицать одно — фальшь.',
  ),
  'reader.link.3': L10nTriple(
    'Bu iki iz — {seen} ve {companion} — birbirini çekiyor.',
    'These two marks — {seen} and {companion} — pull toward each other.',
    'Эти два следа — {seen} и {companion} — тянутся друг к другу.',
  ),
  'reader.link.4': L10nTriple(
    '{companion} olmasa {seen} daha yalın okunurdu.',
    'Without {companion}, {seen} would read more plainly.',
    'Без {companion} {seen} читался бы проще.',
  ),
  'reader.you.0': L10nTriple(
    'Bunu {vessel}daha çok {life} üzerinden okuyorum.',
    'I read this {vessel}more through {life}.',
    'Я читаю это {vessel}больше через {life}.',
  ),
  'reader.you.1': L10nTriple(
    '{life} konusunda durduğun yer buraya bağlanıyor.',
    'Where you stand on {life} is what this is tying to.',
    'То, где ты стоишь в вопросе {life}, сюда и вяжется.',
  ),
  'reader.you.2': L10nTriple(
    'Asıl mesele {life} gibi duruyor; sonucun kendisi değil, ondan sonra vereceğin karar.',
    'The real matter looks like {life}; not the outcome itself, the choice you make after it.',
    'Главное похоже на {life}; не сам исход, а решение после него.',
  ),
  'reader.you.3': L10nTriple(
    '{vessel}bunu {life} işine çekiyorum — sende görünen iz bu.',
    '{vessel}I pull this toward {life} — the trace that actually shows in you.',
    '{vessel}я тяну это к {life} — след, который в тебе виден.',
  ),
  'reader.you.4': L10nTriple(
    'Sende tekrar eden {life} izi olmasa bu kadar bağlardım.',
    'Without the repeating trace of {life} in you, I would not tie it this far.',
    'Без повторяющегося следа {life} в тебе я бы так не связал.',
  ),
  'reader.hedge.0': L10nTriple(
    'Hâlâ biraz bulanık; net olan, duruşun kayması.',
    'It is still a little cloudy; what is clear is a shift of stance.',
    'Всё ещё немного мутно; ясно одно — сдвиг стойки.',
  ),
  'reader.hedge.1': L10nTriple(
    'Bunu acele bir sonuca bağlamıyorum.',
    'I am not binding this to a rushed conclusion.',
    'Я не привязываю это к поспешному выводу.',
  ),
  'reader.hedge.2': L10nTriple(
    'Cümlenin gerisi henüz durmuyor.',
    'The rest of the sentence is not sitting here yet.',
    'Остаток фразы здесь ещё не стоит.',
  ),
  'reader.hedge.3': L10nTriple(
    'Burada temkin daha doğru duruyor.',
    'Caution sits more honestly here.',
    'Здесь честнее выглядит осторожность.',
  ),
  'reader.hedge.4': L10nTriple(
    'Acele etmektense beklemeyi daha dürüst buluyorum.',
    'Waiting looks more honest than rushing.',
    'Честнее ждать, чем спешить.',
  ),
};
