/// Fortune-reader voice strings — TR / EN / RU, never mixed.
library;

import '../l10n_triple.dart';

const kL10nFortune = <String, L10nTriple>{
  'fortune.open.cup.0': L10nTriple(
    'Burada ilk dikkatimi çeken {a}.',
    'What first catches my eye here is {a}.',
    'Первое, что здесь меня останавливает — {a}.',
  ),
  'fortune.open.cup.1': L10nTriple(
    'Fincanın bu tarafı biraz daha ilginç: {a} daha net duruyor.',
    'This side of the cup is more interesting: {a} sits more clearly.',
    'Эта сторона чашки интереснее: {a} читается яснее.',
  ),
  'fortune.open.cup.2': L10nTriple(
    'Şu sembol özellikle ilginç: {a}.',
    'This mark is especially interesting: {a}.',
    'Особенно любопытен этот знак: {a}.',
  ),
  'fortune.open.cup.3': L10nTriple(
    'Şimdi burada biraz durmak gerekiyor — {a} tek başına durmuyor.',
    'It is worth pausing here — {a} does not stand alone.',
    'Здесь стоит немного задержаться — {a} стоит не одно.',
  ),
  'fortune.open.cup.4': L10nTriple(
    'Özellikle fincanın bu izinde {a} görünüyor.',
    'On this trace of the cup, {a} comes into view.',
    'Именно на этом следе чашки видно {a}.',
  ),
  'fortune.open.palm.0': L10nTriple(
    'Burada dikkatimi çeken, elinin nasıl durduğu.',
    'What catches my eye is how this hand is held.',
    'Меня останавливает то, как лежит эта рука.',
  ),
  'fortune.open.palm.1': L10nTriple(
    'Bu avuçta önce çizgilerin ritmi görünüyor.',
    'In this palm the rhythm of the lines appears first.',
    'В этой ладони сначала читается ритм линий.',
  ),
  'fortune.open.palm.2': L10nTriple(
    'Şimdi burada biraz durmak gerekiyor.',
    'It is worth pausing on this hand for a moment.',
    'Здесь стоит немного задержаться на руке.',
  ),
  'fortune.open.palm.3': L10nTriple(
    'Elin bu tarafı biraz daha ilginç.',
    'This side of the hand is more interesting.',
    'Эта сторона руки интереснее.',
  ),
  'fortune.open.palm.4': L10nTriple(
    'Burada özellikle çizgilerin başlangıcı ve yönü duruyor.',
    'Here the start and direction of the lines especially stand out.',
    'Здесь особенно видны начало и направление линий.',
  ),
  'fortune.cup.lane': L10nTriple(
    '{name} gerçekten seçiliyor. Geleneksel okumada daha çok {meaning} gibi duruyor — net bir sonuç iddiası değil.',
    '{name} is genuinely visible. Traditionally it sits more as {meaning} — not a firm outcome claim.',
    '{name} действительно видно. По традиции это скорее {meaning} — не жёсткий исход.',
  ),
  'fortune.astro.personality': L10nTriple(
    '{sign}: bugünkü gökyüzü okuması ritmine bakıyor — acele bir hüküm yok.',
    '{sign}: today\'s sky reading looks at your rhythm — no hurried verdict.',
    '{sign}: сегодняшнее чтение неба смотрит на твой ритм — без спешного приговора.',
  ),
  'fortune.cup.together': L10nTriple(
    'Yan yana gelince {a} ile {b} aynı hikâyenin iki ucu gibi duruyor.',
    'Side by side, {a} and {b} feel like two ends of one story.',
    'Рядом {a} и {b} похожи на два конца одной истории.',
  ),
  'fortune.cup.pair.bird_road': L10nTriple(
    '{a} ile {b} yan yana durunca, bekledikten sonra kıpırdayan bir haber veya iletişim gibi okunabilir — varış iddiası değil.',
    'When {a} and {b} sit together, they can be read as news or contact that begins to move after a wait — not an arrival claim.',
    'Когда {a} и {b} рядом, это можно читать как весть или связь после ожидания — не утверждение прибытия.',
  ),
  'fortune.cup.pair.heart_ring': L10nTriple(
    '{a} ile {b} yan yana gelince bağın tonu daha duygusal duruyor; resmi bir söz iddiası değil, yakınlığın ciddiyetini düşündürüyor.',
    'When {a} and {b} sit together the tone feels more emotional; not a claim of a formal vow, it hints at the seriousness of closeness.',
    'Когда {a} и {b} рядом, тон становится более сердечным; это не обещание клятвы, а намёк на серьёзность близости.',
  ),
  'fortune.cup.pair.road_key': L10nTriple(
    '{a} ve {b} birlikte, kilitli duran bir konuda küçük bir kapının aralanabileceğini düşündürüyor — söz vermeden.',
    '{a} and {b} together suggest a locked matter might open a little — without promising.',
    '{a} и {b} вместе намекают, что в закрытом деле может чуть приоткрыться дверь — без обещания.',
  ),
  'fortune.cup.pair.mountain_star': L10nTriple(
    '{a} sabır isteyen eşiği, {b} ise yol gösteren küçük bir umut izini hatırlatıyor. Acele çözüm değil; beklerken yön.',
    '{a} recalls a threshold that wants patience; {b} a small hope that still orients. Not a quick fix — direction while waiting.',
    '{a} напоминает о пороге, где нужна терпеливость, {b} — о малом следе надежды. Не быстрое решение, а направление в ожидании.',
  ),
  'fortune.cup.third': L10nTriple(
    'Yanındaki {c} bu okumaya daha {tone} bir renk katıyor.',
    'The nearby {c} gives this reading a more {tone} colour.',
    'Рядом {c} придаёт этому чтению более {tone} оттенок.',
  ),
  'fortune.cup.tone.love': L10nTriple(
    'duygusal',
    'emotional',
    'сердечный',
  ),
  'fortune.cup.tone.work': L10nTriple(
    'işe dair',
    'work-related',
    'деловой',
  ),
  'fortune.cup.single': L10nTriple(
    'Geleneksel okumada {meaning} gibi duruyor. Tek başına bundan net bir sonuç çıkarmam; fincanın geri kalanıyla birlikte bakarım.',
    'In a traditional reading it sits as {meaning}. On its own I would not force a firm outcome from this; I read it with the rest of the cup.',
    'В традиционном чтении это стоит как {meaning}. Самим по себе я не выведу из этого жёсткий исход; смотрю вместе с остальной чашкой.',
  ),
  'fortune.cup.theme.change': L10nTriple(
    'Değişim senin tarafında zaten canlıysa, bu yol beklettiğin bir kararın önünde yeni bir seçenek belirmesi ihtimalini daha anlamlı kılıyor — hüküm değil.',
    'If change is already alive on your side, this path makes a new option in front of a postponed decision feel more plausible — as a possibility, not a verdict.',
    'Если перемены уже живы с твоей стороны, этот путь делает более осмысленной возможность нового выбора перед отложенным решением — как вероятность, не приговор.',
  ),
  'fortune.cup.no_love': L10nTriple(
    'Aşka dair ayrı bir işaret yok; yorumu zorlamıyorum. Asıl hareket başka bir alanda duruyor.',
    'No separate love mark is visible; I will not force one. The movement sits elsewhere.',
    'Отдельного знака любви нет; я не буду его выдумывать. Главное движение в другой области.',
  ),
  'fortune.cup.no_work': L10nTriple(
    'İş ve para için ayrı bir sembol görünmüyor. Zorlanmış bir kariyer cümlesi yazmıyorum.',
    'No separate work or money mark is visible. I will not invent a career sentence.',
    'Отдельного знака работы или денег не видно. Карьерную фразу выдумывать не буду.',
  ),
  'fortune.cup.wait': L10nTriple(
    'Biraz beklemekte fayda var. Dağ gibi duran iz, acele bir çözümü değil sabrı hatırlatır.',
    'It may help to wait a little. A mountain-like mark recalls patience, not a rushed solution.',
    'Полезно немного подождать. След вроде горы напоминает о терпении, не о спешном решении.',
  ),
  'fortune.cup.watch': L10nTriple(
    'Özellikle şu konuya dikkat et: görünür olan ile henüz söylenmemiş olan arasındaki boşluk.',
    'Pay attention to this: the space between what is already visible and what is still unsaid.',
    'Обрати внимание вот на что: пустота между уже видимым и ещё не сказанным.',
  ),
  'fortune.cup.bridge.love': L10nTriple(
    'Yakınlığa dair duran iz şöyle okunuyor.',
    'The mark that sits near closeness reads like this.',
    'След, связанный с близостью, читается так.',
  ),
  'fortune.cup.bridge.work': L10nTriple(
    'İş ve yön tarafında fincan bana şunu gösteriyor.',
    'In work and direction, the cup shows me this.',
    'В деле и направлении чашка показывает мне вот что.',
  ),
  'fortune.cup.bridge.near': L10nTriple(
    'İki işaret yan yana gelince, yakın dönemde şunu düşünüyorum.',
    'When these traces sit together, I would look at the near stretch like this.',
    'Когда эти следы рядом, ближайшее время я читаю так.',
  ),
  'fortune.cup.bridge.close': L10nTriple(
    'Ben bunu daha çok şuraya bağlıyorum.',
    'I would rest this more here.',
    'Я скорее связываю это вот с чем.',
  ),
  'fortune.palm.heart': L10nTriple(
    'Kalp çizgisinin bu görünür yapısı, geleneksel el falında duyguları hemen dökmeyen ama bağ kurduğunda kolay vazgeçmeyen bir yapıyla ilişkilendirilir. Bu hastalık veya ömür cümlesi değil.',
    'This visible heart line is traditionally linked with a temperament that does not pour feeling out at once, yet carries a bond for a long time. This is not a medical or lifespan claim.',
    'Эта видимая линия сердца в традиционном чтении связана с нравом, который не выплёскивает чувство сразу, но долго несёт связь. Это не медицинское и не про срок жизни.',
  ),
  'fortune.palm.head': L10nTriple(
    'Zihin çizgisinin görünür temposu, acele karar yerine durduğun yeri bir cümlede netleştirmeyi hatırlatır.',
    'The visible pace of the head line recalls clarifying where you stand in one sentence, rather than rushing a choice.',
    'Видимый ритм линии ума напоминает сначала ясно назвать своё место в одном предложении, а не спешить с выбором.',
  ),
  'fortune.palm.life': L10nTriple(
    'Yaşam çizgisi ömür veya hastalık söylemez; canlılık, tempo ve kendini nasıl taşıdığın hakkında sembolik bir ayna tutar.',
    'The life line does not speak of lifespan or illness; it is a symbolic mirror of vitality, pace, and how you carry yourself.',
    'Линия жизни не говорит о сроке или болезни; это символическое зеркало живости, темпа и того, как ты себя несёшь.',
  ),
  'fortune.palm.fate': L10nTriple(
    'Yön çizgisi kader kehaneti değil; iş, yol ve seçimde nerede takıldığını hatırlatan bir iz.',
    'The fate line is not a destiny prophecy; it is a mark that recalls where work, path, and choice snag.',
    'Линия пути — не пророчество судьбы; это след, напоминающий, где застревают дело, дорога и выбор.',
  ),
  'fortune.palm.shape': L10nTriple(
    'Elin genel duruşu mizaç hükmü değil; nasıl tutunduğun hakkında kısa bir ayna.',
    'The overall hold of the hand is not a character verdict; it is a short mirror of how you hold on.',
    'Общий вид руки — не приговор характеру; короткое зеркало того, как ты держишься.',
  ),
  'fortune.astro.overall': L10nTriple(
    '{sign}, bugün özellikle yarım bıraktığın bir konuşmayı yeniden düşünmen veya ertelediğin bir kararı netleştirmek istemen mümkün. {theme} izi bunu {domain} tarafında daha seçilir kılıyor.',
    '{sign}, today you may want to reopen a conversation you left unfinished, or finally name a postponed choice. The {theme} thread makes this clearer in {domain}.',
    '{sign}, сегодня тебе может захотеться вернуться к оборванному разговору или наконец назвать отложенный выбор. Тема {theme} делает это яснее в области {domain}.',
  ),
  'fortune.astro.love_even': L10nTriple(
    'Yakınlıkta {theme} temasını zorlamadan izlemek yeterli; tek nazik bir cümle çoğu zaman yeter.',
    'In closeness it is enough to watch the {theme} thread without pushing; one gentle sentence is often enough.',
    'В близости достаточно наблюдать тему {theme} без давления; одной мягкой фразы часто хватает.',
  ),
  'fortune.astro.love_odd': L10nTriple(
    'Bağda {theme} görünürse, tahmin oyunu yerine tek bir nazik soru yeter.',
    'If {theme} appears in the bond, one kind question is better than guessing.',
    'Если в связи видна тема {theme}, один мягкий вопрос лучше догадок.',
  ),
  'fortune.astro.career_even': L10nTriple(
    'İş ve yönde {theme} temasını bir görünür adımla taşımak daha sakin durur.',
    'In work and direction, carrying the {theme} thread with one visible step feels calmer.',
    'В деле и направлении спокойнее нести тему {theme} одним видимым шагом.',
  ),
  'fortune.astro.career_odd': L10nTriple(
    'Yön seçerken {theme} temasını aceleye getirmeden oku; listenin ilk maddesini bitirmek yeter.',
    'When choosing a direction, read the {theme} thread without rushing; finishing the first item on the list is enough.',
    'Выбирая направление, читай тему {theme} без спешки; достаточно закончить первый пункт списка.',
  ),
  'fortune.astro.inner_tail': L10nTriple(
    'Bugün bu temayı özellikle {domain} alanında fark edebilirsin.',
    'Today you may notice this thread especially in {domain}.',
    'Сегодня ты можешь заметить эту тему особенно в области {domain}.',
  ),
};
