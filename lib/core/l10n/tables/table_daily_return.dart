/// Daily return empty-pool + soft theme lines - TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nDailyReturn = <String, L10nTriple>{
  'daily.empty.0': L10nTriple(
    'Bugün aklında en çok ne kaldı?',
    'What has stayed with you most today?',
    'Что сегодня больше всего осталось в мыслях?',
  ),
  'daily.empty.1': L10nTriple(
    'Bugün değiştirebileceğin küçük bir şey var mı?',
    'Is there one small thing you could change today?',
    'Есть ли сегодня что-то небольшое, что можно изменить?',
  ),
  'daily.empty.2': L10nTriple(
    'Şu an vereceğin en sade karar ne olurdu?',
    'What would be the simplest decision you could make now?',
    'Какое самое простое решение ты мог бы принять сейчас?',
  ),
  'daily.empty.3': L10nTriple(
    'Cevabı hemen bulmak zorunda değilsin. Soruyu netleştirmek de başlangıçtır.',
    'You do not need the answer right away. Clarifying the question is a start.',
    'Необязательно сразу знать ответ. Прояснить вопрос — уже начало.',
  ),
  'daily.empty.4': L10nTriple(
    'Zihninde kalan düşünceyi taşımak şart değil; birini seçip bırakmak da olur.',
    'You do not have to carry every leftover thought; choosing one and setting one down also works.',
    'Не обязательно носить каждую оставшуюся мысль; выбрать одну и отпустить другую тоже можно.',
  ),
  'daily.empty.5': L10nTriple(
    'Bugün her şeyi çözmek değil; bir engeli adlandırmak yeter.',
    'Today is not for solving everything; naming one obstacle is enough.',
    'Сегодня не решать всё; достаточно назвать одно препятствие.',
  ),
  'daily.empty.6': L10nTriple(
    '{weekday} içinde küçük ve bitmiş bir iş, büyük yarım işten daha sağlam.',
    'On {weekday}, one small finished piece sits firmer than a large half-done task.',
    'В {weekday} маленькое законченное дело крепче большого недоделанного.',
  ),
  'daily.empty.7': L10nTriple(
    'Bugün bir şeyi bitirmek zorunda değilsin; ona yer açmak da ilerleme.',
    'You need not finish something today; making room for it is also progress.',
    'Сегодня не обязательно что-то завершить; оставить для этого место тоже движение.',
  ),
  'daily.empty.8': L10nTriple(
    'Bugün seni şaşırtan küçük bir an oldu mu?',
    'Was there a small moment that surprised you today?',
    'Был ли сегодня небольшой момент, который тебя удивил?',
  ),
  'daily.empty.9': L10nTriple(
    'Küçük bir boşluk bırakmak, acele bir cevaptan daha dürüst durabilir.',
    'Leaving a small gap can sit more honestly than a rushed answer.',
    'Оставить маленький промежуток может быть честнее поспешного ответа.',
  ),
  'daily.empty.10': L10nTriple(
    'Bugünün geri kalanında neye yer açmak istersin?',
    'What would you like to make room for in the rest of your day?',
    'Для чего ты хотел бы оставить место в оставшейся части дня?',
  ),
  'daily.empty.11': L10nTriple(
    '{month} temposunda her şeyi netleştirmek şart değil; bir sınırı korumak yeter.',
    'In the tempo of {month}, you need not clarify everything; keeping one boundary is enough.',
    'В темпе {month} не обязательно всё прояснять; достаточно держать одну границу.',
  ),
  'daily.empty.12': L10nTriple(
    'Bir düşünceyi adlandırmak, onu hemen çözmekten daha sakin ve daha net.',
    'Naming a thought is calmer and clearer than solving it at once.',
    'Назвать мысль спокойнее и яснее, чем сразу её решать.',
  ),
  'daily.empty.13': L10nTriple(
    'Gürültüyü azaltmak, yeni bir karar zorlamaktan daha doğru olabilir.',
    'Quieting the noise may be truer than forcing a new decision.',
    'Уменьшить шум может быть вернее, чем навязывать новое решение.',
  ),
  'daily.empty.14': L10nTriple(
    '{weekday} akşamında tek dürüst bakış: bugün neyi taşıdığını görmek.',
    'One honest look on a {weekday} evening: seeing what you carried today.',
    'Один честный взгляд вечером {weekday}: увидеть, что ты нёс сегодня.',
  ),
  'daily.empty.15': L10nTriple(
    'Yarın yanında götürmek istediğin tek düşünce hangisi?',
    'What is the one thought you would like to carry into tomorrow?',
    'Какую одну мысль ты хотел бы взять с собой в завтра?',
  ),
  'daily.theme.soft.0': L10nTriple(
    '{theme} konusu zihninde duruyor; acele bir yorumdan daha dürüst bakmak yeter.',
    '{theme} is still on your mind; an honest look beats a rushed take.',
    'Тема {theme} всё ещё в уме; честный взгляд лучше поспешного вывода.',
  ),
  'daily.theme.soft.1': L10nTriple(
    'Bir {theme} sorusunu çözmek değil, onu görmek daha doğru durabilir.',
    'Seeing a {theme} question may be truer than solving it.',
    'Увидеть вопрос {theme} может быть вернее, чем его решить.',
  ),
  'daily.theme.soft.2': L10nTriple(
    'Küçük bir sonraki adım: {theme} konusunda yeni anlam aramadan durmak yeter.',
    'A small next step: pause on {theme} without hunting new meaning.',
    'Маленький следующий шаг: остановиться на {theme} без поиска нового смысла.',
  ),
  'daily.theme.soft.3': L10nTriple(
    '{theme} için bugün ayrılmış yer, onu zorla netleştirmekten daha sakin.',
    'Room held for {theme} today is calmer than forcing clarity.',
    'Место, оставленное для {theme} сегодня, спокойнее насильственной ясности.',
  ),
  'daily.theme.backed.0': L10nTriple(
    'Son birkaç keşfinde aynı noktaya dönüyorsun: {theme} meselesi hâlâ açık duruyor gibi.',
    'In recent discoveries you return to the same place: {theme} still feels open.',
    'В недавних открытиях ты возвращаешься к одному: тема {theme} всё ещё открыта.',
  ),
  'daily.theme.backed.1': L10nTriple(
    'Keşiflerinde {theme} izi yeniden görünüyor. Acele bir sonuç değil, nerede takıldığını görmek daha doğru.',
    'The trace of {theme} appears again in your discoveries. Seeing where you stick beats a rushed conclusion.',
    'След {theme} снова виден в открытиях. Увидеть, где ты застрял, вернее поспешного вывода.',
  ),
  'daily.theme.backed.2': L10nTriple(
    '{theme} teması tekrar ediyor. Tek bir net seçimi kendine adlandırmak yeter.',
    'The theme of {theme} is repeating. Naming one clear choice to yourself is enough.',
    'Тема {theme} повторяется. Достаточно назвать себе один ясный выбор.',
  ),
  'daily.theme.backed.3': L10nTriple(
    'Geri dönüp bakınca {theme} hâlâ yerinde duruyor — bunu fark etmek, onu çözmekten ayrı bir şey.',
    'Looking back, {theme} is still there — noticing that is separate from solving it.',
    'Оглянувшись, {theme} всё ещё на месте — заметить это отдельно от решения.',
  ),
  'daily.evidence.sharp': L10nTriple(
    '{note} {theme} izi burada yeniden duruyor — tek sonuca işaret etmiyor.',
    '{note} The trace of {theme} rests here again — it does not point to one outcome.',
    '{note} След {theme} снова здесь — он не указывает на один исход.',
  ),
  'daily.evidence.directed': L10nTriple(
    '{note} Bu yüzden {theme} konusunda acele bir sonuç değil, nerede takıldığını net görmek daha doğru.',
    '{note} So with {theme}, seeing clearly where you stick beats a rushed conclusion.',
    '{note} Поэтому с {theme} яснее увидеть, где ты застрял, чем спешить к выводу.',
  ),
  'daily.evidence.next': L10nTriple(
    '{note} Küçük bir sonraki adım: {theme} içinde tek bir net seçimi kendine adlandırmak yeter.',
    '{note} A small next step: name one clear choice within {theme} to yourself.',
    '{note} Маленький следующий шаг: назвать себе один ясный выбор в теме {theme}.',
  ),
  'daily.evidence.pause': L10nTriple(
    '{note} {theme} için bugün ayrılmış yer: çözmek değil, fark etmek.',
    "{note} Today's room for {theme}: noticing, not solving.",
    '{note} Место для {theme} сегодня: заметить, а не решить.',
  ),
};
