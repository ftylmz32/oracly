/// Local tarot story and guidance sentences.
library;

import '../l10n_triple.dart';

const kL10nTarotStory = <String, L10nTriple>{
  'tarot.story.asked.a': L10nTriple(
    '“{asked}” sorusu bu masada {pos} içindeki {name} ile açılıyor. {hedge}: {meaning} Doğrudan emir gibi okumuyorum; sonraki kartlar bu duruşu birlikte kaydırıyor.',
    'The question “{asked}” opens at this table with {name} in {pos}. {hedge}: {meaning} I do not read it as a direct order; later cards shift this stance together.',
    'Вопрос «{asked}» открывается за столом с {name} в «{pos}». {hedge}: {meaning} Не читаю как прямой приказ; следующие карты вместе сдвигают эту позу.',
  ),
  'tarot.story.open.a': L10nTriple(
    'Bu açılım {pos} içindeki {name} tarafına işaret ediyor. {hedge}: {meaning} Tek tanım değil; konumdaki ilişki okunuyor.',
    'This spread points toward {name} in {pos}. {hedge}: {meaning} Not a single definition; the relation in this place is being read.',
    'Этот расклад указывает на {name} в позиции «{pos}». {hedge}: {meaning} Не одно определение; читается связь в этом месте.',
  ),
  'tarot.story.asked.b': L10nTriple(
    '{pos} içindeki {name}, “{asked}” için doğrudan ‘kal’ ya da ‘git’ demiyor. {hedge}: {meaning} Asıl mesele, yanındaki kartlarla birlikte neyin netleşmediği.',
    '{name} in {pos} does not say stay or leave to “{asked}”. {hedge}: {meaning} What matters is what stays unclear with the cards beside it.',
    '{name} в «{pos}» не говорит «останься» или «уйди» на «{asked}». {hedge}: {meaning} Важнее, что остаётся неясным вместе с соседними картами.',
  ),
  'tarot.story.open.b': L10nTriple(
    '{thread} içinde duran {pos}: {name}. {hedge}: {meaning} Bu masada duruş, tek bir cümleden bağımsız okunuyor.',
    '{pos} standing inside {thread}: {name}. {hedge}: {meaning} The stance at this table is read apart from a single line.',
    '{pos} внутри «{thread}»: {name}. {hedge}: {meaning} Поза за столом читается отдельно от одной фразы.',
  ),
  'tarot.rel.after': L10nTriple(
    '{b}, {a} ile yan yana gelince hikâyeyi kaydırıyor {hedge}. {prev} tarafını olduğu gibi tutmak değil; {next} içinde neyin açıldığına bakmak gibi duruyor.',
    '{b}, sitting beside {a}, shifts the story {hedge}. Not keeping the {prev} side as it is; seeing what opens in {next}.',
    '{b} рядом с {a} сдвигает историю {hedge}. Не держать сторону «{prev}» как есть, а увидеть, что открывается в «{next}».',
  ),
  'tarot.rel.shift': L10nTriple(
    'Soru daha az “{from}” tarafını korumak, daha çok {pos} içinde {to} gibi {hedge}.',
    'The question is less about keeping the “{from}” side, more about {to} inside {pos} {hedge}.',
    'Вопрос меньше в том, чтобы беречь сторону «{from}», и больше в {to} внутри «{pos}» {hedge}.',
  ),
  'tarot.guide.close': L10nTriple(
    'Bu açılımın sana bıraktığı yön, {name} ile {meaning} tarafında duruyor {hedge}.',
    'The direction this spread leaves you sits with {name} and {meaning} {hedge}.',
    'Направление, которое оставляет расклад, стоит с {name} и {meaning} {hedge}.',
  ),
  'tarot.guide.close.q': L10nTriple(
    ' “{asked}” için acele bir cevap değil; {pos} içindeki gerilimi net görmek.',
    ' Not a hurried answer to “{asked}”; seeing the tension inside {pos} clearly.',
    ' Не скорый ответ на «{asked}»; ясно увидеть напряжение внутри «{pos}».',
  ),
  'tarot.guide.practical': L10nTriple(
    '{close} {theme} tek net bakış yeterli: net bir gelecek iddiası yok; durduğun yeri sadeleştirmek.',
    '{close} {theme} one clear look is enough: not a grand prophecy — simplifying where you stand.',
    '{close} {theme} достаточно одного ясного взгляда: не большое пророчество, а упростить место, где ты стоишь.',
  ),
  'tarot.guide.theme.love': L10nTriple('Aşk tarafında', 'On the love side', 'Со стороны любви'),
  'tarot.guide.theme.career': L10nTriple('Kariyer tarafında', 'On the work side', 'Со стороны дела'),
  'tarot.guide.theme.daily': L10nTriple('Bugün', 'Today', 'Сегодня'),
  'tarot.guide.theme.general': L10nTriple('Genel bakışta', 'In the wider view', 'В общем взгляде'),
  'tarot.guide.theme.other': L10nTriple('Bu açılımda', 'In this spread', 'В этом раскладе'),
  'tarot.guide.q.asked': L10nTriple(
    '“{asked}” diye sorduğun yerde, {here} ile {aim} arasında asıl durduğun yer daha önemli.\n{name} bir cevap değil; bakılacak yön böyle okunabilir.',
    'Where you asked “{asked}”, where you actually stand between {here} and {aim} matters more.\n{name} is not an answer; a direction to look can be read this way.',
    'Там, где ты спросил «{asked}», важнее место, где ты стоишь между «{here}» и «{aim}».\n{name} — не ответ; так можно прочесть направление взгляда.',
  ),
  'tarot.guide.q.love': L10nTriple(
    'Bu bağda asıl gerilim çoğu zaman mesafe ile açık bir cümle arasında.\nTahmin etmek yerine o cümleyi söylemek daha sağlam durur.',
    'In this bond the real tension often sits between distance and a plainer sentence.\nSaying that sentence is firmer than guessing.',
    'В этой связи настоящее натяжение чаще между дистанцией и более открытой фразой.\nСказать эту фразу крепче, чем гадать.',
  ),
  'tarot.guide.q.career': L10nTriple(
    'Bugün bitirmek istediğin tek iş, dağınık engellerden daha net bir yön verir.\nÇoğu engel aslında tempo sorunudur.',
    'The one piece of work you want to finish today gives a clearer direction than scattered obstacles.\nMost obstacles are really a matter of pace.',
    'Одно дело, которое ты сегодня хочешь закончить, даёт более ясное направление, чем разбросанные препятствия.\nБольшинство препятствий на самом деле вопрос темпа.',
  ),
  'tarot.guide.q.daily': L10nTriple(
    'Bugün tek net adım, ertelemeyi sadeleştirmekten gelir.\nListeyi uzatmak yerine bir şeyi şimdi sadeleştirmek işi kolaylaştırır.',
    'Today’s one clear step comes from simplifying what you put off.\nSimplifying one thing now makes the work easier than lengthening the list.',
    'Сегодня один ясный шаг приходит от упрощения того, что откладываешь.\nУпростить одно сейчас облегчает дело больше, чем удлинять список.',
  ),
  'tarot.rel.pair.fog': L10nTriple(
    '{left} hareket veya geçiş çağırırken {right} duraksamayı hatırlatıyor. İkisi birlikte: adım atmadan önce sisin içindeki tek net seçeneği görmek daha sağlam durur.',
    '{left} calls for movement or passage while {right} reminds you to pause. Together: seeing the one clear choice inside the fog before stepping stands more firmly.',
    '{left} зовёт к движению или переходу, а {right} напоминает остановиться. Вместе: увидеть один ясный выбор в тумане до шага стоит крепче.',
  ),
  'tarot.rel.pair.love': L10nTriple(
    '{left} duygunun sıcaklığını, {right} ise net bir söz ihtiyacını gösteriyor. Bağdaki mesele his değil; söylenmemiş cümle olabilir.',
    '{left} shows the warmth of feeling, {right} the need for a clear word. The matter in the bond may not be the feeling; it may be the unspoken sentence.',
    '{left} показывает тепло чувства, {right} — нужду в ясном слове. Дело в связи может быть не в чувстве, а в несказанной фразе.',
  ),
  'tarot.rel.pair.work': L10nTriple(
    '{left} emek veya düzen isterken {right} bir eşiği gösteriyor. Yeni dağ açmak yerine eldeki işi bitirmek daha doğru durur.',
    '{left} asks for labour or order while {right} shows a threshold. Finishing the work at hand stands truer than opening a new mountain.',
    '{left} просит труда или порядка, а {right} показывает порог. Закончить дело под рукой вернее, чем открывать новую гору.',
  ),
  'tarot.rel.pair.fallback': L10nTriple(
    '{left} ile {right} aynı masada: biri durduğun yeri, diğeri taşıdığın izi görünür kılıyor. Ayrı tanımlar değil; birlikte okunduğunda ritmin nerede takıldığı daha seçilir.',
    '{left} and {right} at the same table: one makes where you stand visible, the other the trace you carry. Not separate definitions; read together, where the rhythm catches is clearer.',
    '{left} и {right} за одним столом: одна делает видимым место, где ты стоишь, другая — след, который несёшь. Не отдельные определения; вместе яснее, где ритм застревает.',
  ),
  'tarot.rel.pair.control': L10nTriple(
    '{left} doğrudan ‘kal’ ya da ‘git’ demiyor; kontrolü yeniden eline alman gereken bir noktayı gösteriyor. {right} yüzünden de kararın kendisinden çok, şu an neyi net göremediğin önemli hale geliyor.',
    '{left} does not say stay or leave; it shows a point where you may need to take control again. Because of {right}, what you cannot see clearly now matters more than the decision itself.',
    '{left} не говорит «останься» или «уйди»; показывает точку, где снова нужно взять контроль. Из‑за {right} важнее не само решение, а то, чего сейчас не видно ясно.',
  ),
  'tarot.guide.q.other': L10nTriple(
    'Bugün hangi yükü bırakmak isterdin?\nDurduğun yerde asıl ihtiyaç ne?',
    'Which load would you like to set down today?\nWhat is actually needed where you stand?',
    'Какую ношу ты хотел бы сегодня оставить?\nЧто на самом деле нужно там, где ты стоишь?',
  ),
};
