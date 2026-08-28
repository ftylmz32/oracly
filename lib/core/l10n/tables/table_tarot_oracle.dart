/// Human-oracle tarot voice — question kind, charged cards, journey, close.
library;

import '../l10n_triple.dart';

const kL10nTarotOracle = <String, L10nTriple>{
  'tarot.ask.lead.decision': L10nTriple(
    'Evet-hayır aramıyorum. Daha çok bu kararın neden bu kadar ağır durduğuna bakıyorum.',
    'I am not hunting yes or no. I am looking at why this choice sits so heavily.',
    'Я не ищу да или нет. Смотрю, почему этот выбор лежит так тяжело.',
  ),
  'tarot.ask.lead.relationship': L10nTriple(
    'Niyet falı değil; bağın şu anki yönünü okuyorum.',
    'This is not a reading of someone\'s hidden plot; I am reading the present direction of the bond.',
    'Это не гадание о тайном умысле; я читаю нынешнее направление связи.',
  ),
  'tarot.ask.lead.guidance': L10nTriple(
    'Takvim değil; önündeki dönemde nereye dikkat etmenin daha doğru durduğuna bakıyorum.',
    'Not a calendar. I am looking at where attention would sit more truly in the stretch ahead.',
    'Это не календарь. Смотрю, куда в ближайшее время вернее обратить внимание.',
  ),
  'tarot.ask.lead.other': L10nTriple(
    'Kartları sözlük gibi değil, birbirine değdikleri yerden okuyorum.',
    'I am not reading a dictionary. I am reading where the cards touch.',
    'Я не читаю словарь. Читаю там, где карты соприкасаются.',
  ),
  'tarot.ask.close.decision': L10nTriple(
    'Bu yüzden acele cevap yerine, hangi kısmı gerçekten değiştirmek istediğine bakmak daha doğru duruyor.',
    'So rather than a hurried answer, it sits better to see which part you actually want to change.',
    'Поэтому вместо скорого ответа вернее посмотреть, какую часть ты правда хочешь изменить.',
  ),
  'tarot.ask.close.relationship': L10nTriple(
    'Asıl işaret, beklemekten çok neyin söylenmediğini netleştirmek gibi duruyor.',
    'The real mark sits less in waiting, more in naming what has not been said.',
    'Настоящий знак — не столько в ожидании, сколько в том, чтобы назвать несказанное.',
  ),
  'tarot.ask.close.guidance': L10nTriple(
    'Bu açılım bir son değil; dikkatini nereye koyacağını seçmek gibi duruyor.',
    'This spread is not an ending; it is a choice of where to put your attention.',
    'Этот расклад не конец; это выбор, куда положить внимание.',
  ),
  'tarot.ask.close.other': L10nTriple(
    'Bu masada kalan şey bir kehanet değil; durduğun yeri sadeleştirmek.',
    'What remains at this table is not a prophecy; it is simplifying where you stand.',
    'За этим столом остаётся не пророчество, а упростить место, где ты стоишь.',
  ),
  'tarot.charge.tower.obstacle': L10nTriple(
    'Engel konumunda bunu yıkım kehaneti olarak okumam; yanlış duran bir yapının sürtünmesi gibi duruyor.',
    'In the obstacle place I do not read this as a prophecy of ruin; it sits more like friction from a structure that no longer holds.',
    'В позиции препятствия я не читаю это как пророчество крушения; больше как трение от конструкции, которая уже не держит.',
  ),
  'tarot.charge.tower.direction': L10nTriple(
    'Yön olarak çöküş takvimi değil; gerçeğin yüzeye çıkması gibi duruyor.',
    'As direction this is not a schedule of collapse; it sits more like truth coming to the surface.',
    'Как путь это не календарь обвала; больше как правда, выходящая на поверхность.',
  ),
  'tarot.charge.tower.here': L10nTriple(
    'İlk bakışta sert duruyor; ben bunu olumsuz gelecek haberi olarak okumam. Daha çok artık taşımayan bir yapının görünür olması.',
    'At first glance it looks harsh; I do not read it as bad news of the future. It sits more like seeing a structure you no longer carry.',
    'Сперва выглядит резко; я не читаю это как дурную весть о будущем. Больше как увидеть конструкцию, которую ты уже не несёшь.',
  ),
  'tarot.charge.death': L10nTriple(
    'Bunu korku kartı olarak okumam. Bitmekte olanın yerini neye bıraktığı daha önemli.',
    'I do not read this as a fear card. What matters more is what the ending is making room for.',
    'Я не читаю это как карту страха. Важнее, чему окончание уступает место.',
  ),
  'tarot.charge.devil': L10nTriple(
    'Korku değil; bağ, alışkanlık veya kontrol — nerede sıkıştığın.',
    'Not fear; attachment, habit, or control — where you are stuck.',
    'Не страх; привязка, привычка или контроль — где ты застрял.',
  ),
  'tarot.charge.star': L10nTriple(
    'Burada umut “her şey güzel olacak” demiyor. Daha çok bu masada neye doğru nefes açıldığını soruyor.',
    'Hope here does not mean everything will be wonderful. It asks what you are being invited to breathe toward at this table.',
    'Надежда здесь не значит, что всё будет прекрасно. Она спрашивает, к чему за этим столом открывается дыхание.',
  ),
  'tarot.charge.sun': L10nTriple(
    'Aydınlık, her şeyin yolunda olduğu anlamına gelmez. Burada neyin netleştiğine bakıyorum.',
    'Brightness does not mean everything is fine. I am looking at what is becoming clear here.',
    'Свет не значит, что всё в порядке. Смотрю, что здесь проясняется.',
  ),
  'tarot.charge.swords10': L10nTriple(
    'Dip noktası bir son kehaneti değil; artık taşınmayan hali adlandırma.',
    'The low point is not a prophecy of the end; it is naming what can no longer be carried.',
    'Нижняя точка — не пророчество конца; это назвать то, что уже нельзя нести.',
  ),
  'tarot.charge.cups5': L10nTriple(
    'Kayıp görünür; hâlâ duran tarafa da bakmak mümkün.',
    'The loss is visible; it is also possible to look at what is still standing.',
    'Потеря видна; можно также смотреть на то, что ещё стоит.',
  ),
  'tarot.journey.themes': L10nTriple(
    'Son dönemde {themes} temasının birkaç farklı keşfinde tekrar ettiğini de düşününce, bu açılımı tek başına okumuyorum.',
    'Seeing {themes} return across a few recent discoveries, I do not read this spread in isolation.',
    'Видя, как тема «{themes}» повторяется в нескольких недавних открытиях, я не читаю этот расклад отдельно.',
  ),
  'tarot.journey.notes': L10nTriple(
    'Kendi yazdığın notlar da bu yolun parçası; uydurma bir geçmiş değil.',
    'Your own notes are part of this path; not an invented history.',
    'Твои собственные заметки — часть этого пути; не выдуманная история.',
  ),
  'tarot.insight.theme.love': L10nTriple('aşk', 'love', 'любовь'),
  'tarot.insight.theme.career': L10nTriple('kariyer', 'work', 'дело'),
  'tarot.insight.theme.growth': L10nTriple(
    'kişisel gelişim',
    'personal growth',
    'личный рост',
  ),
  'tarot.insight.theme.change': L10nTriple('değişim', 'change', 'перемены'),
  'tarot.insight.theme.courage': L10nTriple('cesaret', 'courage', 'смелость'),
  'tarot.insight.theme.patience': L10nTriple('sabır', 'patience', 'терпение'),
  'tarot.insight.theme.beginnings': L10nTriple(
    'yeni başlangıçlar',
    'new beginnings',
    'новые начала',
  ),
  'tarot.insight.theme.reflection': L10nTriple(
    'yansıma',
    'reflection',
    'отражение',
  ),
};
