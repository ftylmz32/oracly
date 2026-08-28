/// Continuous palm reading beats — TR / EN / RU. Catalog, not UI.
library;

import '../l10n_triple.dart';

const kL10nPalmRead = <String, L10nTriple>{
  'palm.read.line.heart': L10nTriple(
    'kalp çizgisi',
    'the heart line',
    'линия сердца',
  ),
  'palm.read.line.head': L10nTriple(
    'zihin çizgisi',
    'the head line',
    'линия ума',
  ),
  'palm.read.line.life': L10nTriple(
    'yaşam çizgisi',
    'the life line',
    'линия жизни',
  ),
  'palm.read.line.fate': L10nTriple(
    'yön çizgisi',
    'the path line',
    'линия пути',
  ),
  'palm.read.look.0': L10nTriple(
    'Burada ilk dikkatimi çeken, bu avuçta {seen}.',
    'What first catches my eye on this palm is {seen}.',
    'Первое, что меня останавливает на этой ладони — {seen}.',
  ),
  'palm.read.look.1': L10nTriple(
    'Bu avuçta okumaya {seen} ile başlıyorum.',
    'On this palm I begin from {seen}.',
    'На этой ладони я начинаю с {seen}.',
  ),
  'palm.read.look.2': L10nTriple(
    'Avucu çevirirken {seen} karşıma çıkıyor.',
    'Turning the palm, {seen} meets me.',
    'Поворачивая ладонь, я встречаю {seen}.',
  ),
  'palm.read.look.3': L10nTriple(
    'Bu elde seçilir duran yer {seen}.',
    'The place that sits clearly on this hand is {seen}.',
    'Что ясно стоит на этой руке — {seen}.',
  ),
  'palm.read.look.4': L10nTriple(
    'Bu avuçta asıl durduğum yer {seen}.',
    'The place I actually stop on this palm is {seen}.',
    'Где я действительно останавливаюсь на этой ладони — {seen}.',
  ),
  'palm.read.together.0': L10nTriple(
    '{a} ile hemen yanındaki {b} birlikte duruyor.',
    '{a} sits together with {b} right beside it.',
    '{a} стоит вместе с {b} рядом.',
  ),
  'palm.read.together.1': L10nTriple(
    '{a} duruyor; yanında {b} onu yalnız bırakmıyor.',
    '{a} is here; beside it, {b} does not leave it alone.',
    '{a} здесь; рядом {b} не оставляет её одну.',
  ),
  'palm.read.together.2': L10nTriple(
    '{a} ile {b} yan yana; birini yok saymak yapay durur.',
    '{a} and {b} sit side by side; ignoring one would feel false.',
    '{a} и {b} рядом; отрицать одно было бы фальшью.',
  ),
  'palm.read.together.3': L10nTriple(
    'Aynı avuçta {a} yanında {b} duruyor.',
    'On the same palm, {a} sits beside {b}.',
    'На одной ладони {a} стоит рядом с {b}.',
  ),
  'palm.read.together.4': L10nTriple(
    '{a} yanında {b} görünüyor; hikâye buradan bağlanıyor.',
    '{b} appears beside {a}; the story joins here.',
    'Рядом с {a} виден {b}; история связывается здесь.',
  ),
  'palm.read.heart.0': L10nTriple(
    '{seen}. Bu taraf bence daha çok bağ kurulunca acele kopmayan bir duruşa değiyor.',
    '{seen}. This side, to me, speaks more to a stance in closeness that does not break in a hurry.',
    '{seen}. Эта сторона, по-моему, больше о стойке в близости, которая не рвётся спешно.',
  ),
  'palm.read.heart.1': L10nTriple(
    '{seen}. Burada duyguyu hemen dökmekten çok, bağda nasıl durduğunu okuyorum.',
    '{seen}. Here I read less pouring feeling out, more how you stand in a bond.',
    '{seen}. Здесь я читаю не столько выплёскивание чувства, сколько то, как ты стоишь в связи.',
  ),
  'palm.read.heart.2': L10nTriple(
    '{seen}. Bu taraf bence yakınlıkta acele etmeden durmaya daha çok değiyor.',
    '{seen}. This side, to me, leans more toward standing in closeness without hurry.',
    '{seen}. Эта сторона, по-моему, больше к тому, чтобы стоять в близости без спешки.',
  ),
  'palm.read.head.0': L10nTriple(
    '{seen}. Bu taraf bence daha çok kararı bir cümlede, acele etmeden netleştirmeye değiyor.',
    '{seen}. This side, to me, speaks more to naming a choice in one sentence, without hurry.',
    '{seen}. Эта сторона, по-моему, больше о том, чтобы назвать решение одним предложением, без спешки.',
  ),
  'palm.read.head.1': L10nTriple(
    '{seen}. Acele bir hükümden çok, durduğun yeri seçmeyi hatırlatıyor.',
    '{seen}. More than a rushed verdict, it recalls choosing where you stand.',
    '{seen}. Больше, чем скорый приговор, напоминает выбрать, где ты стоишь.',
  ),
  'palm.read.head.2': L10nTriple(
    '{seen}. Bu taraf bence dağılmadan tek bir meseleye bakmaya daha çok değiyor.',
    '{seen}. This side, to me, leans more toward looking at one matter without scattering.',
    '{seen}. Эта сторона, по-моему, больше к тому, чтобы смотреть на одно дело, не рассеиваясь.',
  ),
  'palm.read.life.0': L10nTriple(
    '{seen}. Bu taraf bence daha çok tempo ve kendini nasıl taşıdığına değiyor — süre hesabı değil.',
    '{seen}. This side, to me, speaks more to pace and how you carry yourself — not a span tally.',
    '{seen}. Эта сторона, по-моему, больше о темпе и том, как ты себя несёшь — не подсчёт срока.',
  ),
  'palm.read.life.1': L10nTriple(
    '{seen}. Burada nasıl durduğunun ritmini taşıyor gibi; teşhis değil, bir duruş.',
    '{seen}. It seems to carry the rhythm of how you stand; not a diagnosis, a stance.',
    '{seen}. Как будто несёт ритм того, как ты стоишь; не диагноз, а стойка.',
  ),
  'palm.read.life.2': L10nTriple(
    '{seen}. Bu taraf bence acele bir tempo yerine, kendini koruduğun ritme daha çok değiyor.',
    '{seen}. This side, to me, leans more toward the rhythm you keep than a rushed tempo.',
    '{seen}. Эта сторона, по-моему, больше к ритму, который ты хранишь, чем к спешному темпу.',
  ),
  'palm.read.fate.0': L10nTriple(
    '{seen}. Bu taraf bence işte ve seçimde nerede takıldığına daha çok değiyor.',
    '{seen}. This side, to me, speaks more to where work and choice snag.',
    '{seen}. Эта сторона, по-моему, больше о том, где застревают дело и выбор.',
  ),
  'palm.read.fate.1': L10nTriple(
    '{seen}. Yönünü biraz daha seçilir kılan bir iz gibi duruyor — kesin yol haritası değil.',
    '{seen}. It sits as a mark that makes your direction a little clearer — not a fixed map.',
    '{seen}. Стоит как след, чуть яснее делающий твоё направление — не готовая карта.',
  ),
  'palm.read.fate.2': L10nTriple(
    '{seen}. Bu taraf bence yolda bekleyen bir seçimi zorlamadan durmaya daha çok değiyor.',
    '{seen}. This side, to me, leans more toward pausing with a waiting choice, without forcing it.',
    '{seen}. Эта сторона, по-моему, больше к тому, чтобы остановиться с ждущим выбором, не торопя его.',
  ),
  'palm.read.you.theme': L10nTriple(
    'Bu kısmı son dönemde tekrar eden {life} temasıyla birlikte okuyunca, bu avuçtaki iz aynı yere bağlanıyor.',
    'Read with the recurring {life} theme of late, this mark on the palm binds to the same place.',
    'Читая это вместе с повторяющейся темой {life} в последнее время, след на ладони связывается с тем же местом.',
  ),
  'palm.read.you.0': L10nTriple(
    '{life} burada bu avuca bağlanıyor gibi.',
    '{life} seems to be tying itself to this palm here.',
    '{life} как будто вяжется с этой ладонью здесь.',
  ),
  'palm.read.you.1': L10nTriple(
    'Durduğun yer, {life} konusunda buraya değiyor.',
    'Where you stand on {life} is touching this place.',
    'То, где ты стоишь в вопросе {life}, касается этого места.',
  ),
  'palm.read.you.2': L10nTriple(
    'Bunu daha çok {life} üzerinden okuyorum.',
    'I would read this more through {life}.',
    'Я читаю это скорее через {life}.',
  ),
  'palm.read.mark.0': L10nTriple(
    '{mark} burada duruyor — küçük bir işaret, tek başına bir hikâye değil.',
    '{mark} sits here — a small mark, not a story on its own.',
    '{mark} стоит здесь — маленький знак, не история сама по себе.',
  ),
  'palm.read.mark.1': L10nTriple(
    'Duran iz {mark}; avuçta biraz daha net görünüyor.',
    'The mark that stands is {mark}; it shows a little more clearly.',
    'Стоящий след — {mark}; на ладони виден чуть яснее.',
  ),
  'palm.read.mark.2': L10nTriple(
    '{mark} avuçta net duruyor; etrafındaki çizgilerle birlikte bakıyorum.',
    '{mark} sits clearly on the palm; I look at it with the lines around it.',
    '{mark} ясно стоит на ладони; смотрю на него вместе с линиями вокруг.',
  ),
  'palm.read.ask.heart': L10nTriple(
    'Bir an için şunu düşünmek yeter: yakınlıkta durduğun yer gerçekten senin mi.',
    'A moment with this is enough: is where you stand in closeness actually yours.',
    'Достаточно на миг подумать: то, где ты стоишь в близости, правда твоё ли.',
  ),
  'palm.read.ask.heart.1': L10nTriple(
    'Kalbin durduğu yerde yumuşak bir cümle mi bekliyor, yoksa henüz tutulmuş bir söz mü.',
    'Where the heart sits, is a gentle sentence waiting, or a word still held back.',
    'Там, где стоит сердце, ждёт ли мягкая фраза или ещё удерживаемое слово.',
  ),
  'palm.read.ask.head': L10nTriple(
    'Netleşmeyen kararın kendisi mi duruyor, yoksa onu erteleyen küçük bir korku mu.',
    'Is it the unnamed choice that sits here, or a small fear that keeps postponing it.',
    'Стоит ли здесь само неназванное решение или маленький страх, что его откладывает.',
  ),
  'palm.read.ask.head.1': L10nTriple(
    'Zihnin durduğu yerde bir cümlede durmak mı, yoksa biraz daha düşünmek mi daha dürüst.',
    'Where the mind sits, is one sentence more honest, or thinking a little longer.',
    'Там, где стоит ум, честнее одно предложение или ещё немного думать.',
  ),
  'palm.read.ask.life': L10nTriple(
    'Ritmini korumak mı duruyor, yoksa biraz daha yavaş taşımak mı.',
    'Is it holding your rhythm that sits here, or carrying yourself a little more slowly.',
    'Стоит ли здесь держать свой ритм или нести себя чуть медленнее.',
  ),
  'palm.read.ask.life.1': L10nTriple(
    'Bu tempoda itmek mi duruyor, yoksa nefes payı bırakmak mı.',
    'At this pace, is pushing what sits here, or leaving a little breath.',
    'В этом темпе стоит ли толкать или оставить чуть дыхания.',
  ),
  'palm.read.ask.fate': L10nTriple(
    'Beklettiğin yönü zorlamak mı, yoksa durup bakmak mı daha doğru.',
    'Is forcing the waiting direction more true, or stopping to look.',
    'Вернее торопить ждущее направление или остановиться и посмотреть.',
  ),
  'palm.read.ask.fate.1': L10nTriple(
    'Yön izinde küçük görünür bir adım mı duruyor, yoksa henüz eşiği beklemek mi.',
    'On this path-mark, is a small visible step sitting here, or still waiting at the threshold.',
    'На следе пути стоит ли маленький видимый шаг или ещё ждать у порога.',
  ),
  'palm.read.ask.open': L10nTriple(
    'Bu avuçta duran şey, henüz adını koymadığın bir mesele olabilir.',
    'What sits on this palm may be a matter you have not named yet.',
    'То, что стоит на этой ладони, может быть делом, которому ты ещё не дал имя.',
  ),
  'palm.read.ask.open.1': L10nTriple(
    'Burada savunduğun tempo mu duruyor, yoksa biraz daha yumuşak durmak mı.',
    'Is it the pace you defend that sits here, or standing a little more softly.',
    'Стоит ли здесь тот темп, который ты защищаешь, или встать чуть мягче.',
  ),
  'palm.read.hedge': L10nTriple(
    'Bu avuçta hikâye henüz net değil; gördüğüm kadarıyla duruyorum.',
    'The story on this palm is not sharp yet; I stay with what I can see.',
    'История на этой ладони ещё не ясна; остаюсь при том, что вижу.',
  ),
  'palm.read.close.0': L10nTriple(
    'Gördüğüm kadarıyla burada duruyorum; fazlasını uydurmuyorum.',
    'I stay with what I can see here; I will not invent more.',
    'Остаюсь при том, что вижу; большего не выдумываю.',
  ),
  'palm.read.close.1': L10nTriple(
    'Bu avuçta net olan bu kadar; gerisini zorlamıyorum.',
    'What is clear on this palm is this much; I will not force the rest.',
    'На этой ладони ясно вот столько; остальное не тороплю.',
  ),
  'palm.read.close.2': L10nTriple(
    'Şimdilik gördüğüm izlerle yetiniyorum.',
    'For now I stay with the marks I can see.',
    'Пока довольствуюсь следами, которые вижу.',
  ),
};
