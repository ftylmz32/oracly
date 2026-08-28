/// Daily sun-sign story beats. Never natal, moon, or houses.
library;

import '../l10n_triple.dart';

const kL10nSkyRead = <String, L10nTriple>{
  'sky.read.start.0': L10nTriple(
    'Bugünün gökyüzünde asıl duran yer: {matter}.',
    "In today's sky, what actually sits is {matter}.",
    'В сегодняшнем небе главное место: {matter}.',
  ),
  'sky.read.start.1': L10nTriple(
    '{sign} gökyüzünde {matter} daha net; bunu kesin sonuç diye bağlamıyorum.',
    'In the {sign} sky, {matter} is clearer; I am not binding it as a certain outcome.',
    'В небе {sign} {matter} яснее; я не связываю это с верным исходом.',
  ),
  'sky.read.start.2': L10nTriple(
    'Gökyüzüne bakınca ilk durduğum yer {matter}.',
    'Looking at the sky, the first place I stop is {matter}.',
    'Глядя на небо, первым останавливаюсь на {matter}.',
  ),
  'sky.read.start.3': L10nTriple(
    '{sign} gökyüzünde bugün baskın duruş {matter}.',
    'In the {sign} sky, today’s dominant stance is {matter}.',
    'В небе {sign} сегодня доминирует стойка — {matter}.',
  ),
  'sky.read.start.4': L10nTriple(
    'Bugünün gökyüzünü hüküm gibi okumam; daha çok {matter} gibi duruyor.',
    "I would not read today's sky as a verdict; it sits more as {matter}.",
    'Сегодняшнее небо не читаю как приговор; скорее это стоит как {matter}.',
  ),
  'sky.read.why.sun': L10nTriple(
    '{sign} gökyüzünde bu tempo daha net duruyor.',
    'In the {sign} sky this tempo sits more clearly.',
    'В небе {sign} этот темп стоит яснее.',
  ),
  'sky.read.why.life': L10nTriple(
    '{life} tarafında gökyüzü bugün yakından bakmayı istiyor.',
    'On the {life} side, the sky wants a closer look today.',
    'Со стороны {life} небо сегодня просит смотреть ближе.',
  ),
  'sky.read.why.domain': L10nTriple(
    'Bu okuma bugün {domain} tarafında; abartmaya gerek yok.',
    'This reading sits on the {domain} side today; no need to inflate it.',
    'Это чтение сегодня со стороны {domain}; раздувать не нужно.',
  ),
  'sky.read.feel': L10nTriple(
    'İçeride şu his daha yakın: {feel}',
    'Inside, this feeling sits closer: {feel}',
    'Внутри ближе такое чувство: {feel}',
  ),
  'sky.read.watch': L10nTriple(
    'Bugün dikkat edilecek yer: {watch}',
    'The place to watch today: {watch}',
    'Место, на которое смотреть сегодня: {watch}',
  ),
  'sky.read.ask.bind': L10nTriple(
    'Bu bağda çoğu zaman zor olan, konuşmak ile karşılığı duymak arasındaki boşluk.',
    'In this bond the hard part is often the gap between speaking and hearing the reply.',
    'В этой связи труднее всего часто промежуток между сказать и услышать ответ.',
  ),
  'sky.read.ask.work': L10nTriple(
    'Burada asıl ayrım dağınıklık ile tek görünür teslim arasında.',
    'The real split here is between scatter and one visible delivery.',
    'Здесь настоящее различие — между рассеянностью и одной видимой сдачей.',
  ),
  'sky.read.ask.sun': L10nTriple(
    'Bugün hızdan çok, durup bir adımı bitirmek daha temiz duruyor.',
    'Today, finishing one step sits cleaner than speed.',
    'Сегодня чище закончить один шаг, чем гнаться за скоростью.',
  ),
  'sky.read.ask.sun.1': L10nTriple(
    'Bu tempo seni ileri götürmüyorsa, çoğu zaman yalnızca gürültüdür.',
    'If this tempo is not carrying you forward, it is often only noise.',
    'Если этот темп не несёт вперёд, чаще всего это только шум.',
  ),
  'sky.read.ask.sun.2': L10nTriple(
    'Tek görünür işi bir kez adlandırmak, listeyi uzatmaktan daha ileri götürür.',
    'Naming the one visible task once carries further than lengthening the list.',
    'Назвать одно видимое дело один раз продвигает дальше, чем удлинять список.',
  ),
};
