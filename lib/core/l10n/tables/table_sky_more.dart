/// Lane, inner, and theme-matter turns. Never natal invention.
library;

import '../l10n_triple.dart';

const kL10nSkyMore = <String, L10nTriple>{
  'sky.read.lane.0': L10nTriple(
    '{life} tarafında işin kolayını söylemeyeceğim. {body}',
    'On the {life} side I will not make it sound easy. {body}',
    'Со стороны {life} я не стану упрощать. {body}',
  ),
  'sky.read.lane.1': L10nTriple(
    '{life} meselesi burada biraz daha zor görünüyor. {body}',
    'The {life} matter looks a little harder here. {body}',
    'Дело {life} здесь выглядит чуть труднее. {body}',
  ),
  'sky.read.lane.2': L10nTriple(
    '{body} {life} izi bunu daha net kılıyor.',
    '{body} The mark of {life} makes this clearer.',
    '{body} След {life} делает это яснее.',
  ),
  'sky.read.inner.0': L10nTriple(
    'İçeride tekrar eden iz {observed}.',
    'Inside, the repeating mark is {observed}.',
    'Внутри повторяющийся след — {observed}.',
  ),
  'sky.read.inner.1': L10nTriple(
    'Sende duran tema {observed}. Bir etiket değil; bakılacak bir iz.',
    'The theme sitting in you is {observed}. Not a label; a mark to look at.',
    'Тема, что стоит в тебе, — {observed}. Не ярлык; след, на который стоит смотреть.',
  ),
  'sky.read.inner.2': L10nTriple(
    '{observed} Bu, içeride biriken iz — kehanet değil.',
    '{observed} This is the mark gathering inside — not a prophecy.',
    '{observed} Это след, что собирается внутри — не пророчество.',
  ),
  'sky.matter.bind.0': L10nTriple(
    'bağda söylenmeden duran şeyi adlandırmak',
    'naming what sits unsaid in the bond',
    'назвать то, что в связи остаётся несказанным',
  ),
  'sky.matter.bind.1': L10nTriple(
    'yarım bıraktığın cümleyi tamamlamak',
    'finishing the sentence you left half-said',
    'закончить фразу, которую ты оставил недосказанной',
  ),
  'sky.matter.bind.2': L10nTriple(
    'yakınlıkta netleşmeyen yeri görmek',
    'seeing the place in closeness that will not clarify',
    'увидеть в близости место, которое не проясняется',
  ),
  'sky.matter.work.0': L10nTriple(
    'masadaki işi bitirmeden yeni kapı açmamak',
    'not opening a new door before finishing the work on the table',
    'не открывать новую дверь, пока дело на столе не закончено',
  ),
  'sky.matter.work.1': L10nTriple(
    'tek görünür teslimi seçmek',
    'choosing one visible delivery',
    'выбрать одну видимую сдачу',
  ),
  'sky.matter.work.2': L10nTriple(
    'dağıtmak ile bir adımı bitirmek arasındaki farkı görmek',
    'seeing the difference between scattering and finishing one step',
    'увидеть разницу между рассеять и закончить один шаг',
  ),
  'sky.matter.inner.0': L10nTriple(
    'içeride toplanmadan acele etmemek',
    'not rushing before you gather yourself',
    'не спешить, пока не соберёшься внутри',
  ),
  'sky.matter.inner.1': L10nTriple(
    'kendine yer bırakmak',
    'leaving yourself some room',
    'оставить себе место',
  ),
  'sky.matter.inner.2': L10nTriple(
    'hangi sınırın gerildiğini görmek',
    'seeing which boundary is drawn taut',
    'увидеть, какая граница натянута',
  ),
  'sky.matter.spark.0': L10nTriple(
    'bir fikri uygulamadan onunu hayal etmemek',
    'not dreaming ten ideas before living one',
    'не мечтать о десяти идеях, пока не прожил одну',
  ),
  'sky.matter.spark.1': L10nTriple(
    'cesareti dağınık savaşmaya harcamamak',
    'not spending courage on a scattered fight',
    'не тратить смелость на разбросанную борьбу',
  ),
  'sky.matter.spark.2': L10nTriple(
    'yeni bir başlangıcı tek net adımla tutmak',
    'holding a new beginning with one clear step',
    'удержать новое начало одним ясным шагом',
  ),
  // Yıldızname chart portrait chrome (hub).
  'star.portrait.heading': L10nTriple(
    'HARİTANIN ANLATTIĞI',
    'WHAT YOUR CHART SAYS',
    'ЧТО ГОВОРИТ ТВОЯ КАРТА',
  ),
  'star.portrait.core': L10nTriple(
    'HARİTANIN ANA ÇİZGİSİ',
    'THE MAIN LINE OF YOUR CHART',
    'ГЛАВНАЯ ЛИНИЯ КАРТЫ',
  ),
  'star.portrait.bond': L10nTriple(
    'SEVME VE HAREKETE GEÇME BİÇİMİN',
    'HOW YOU LOVE AND HOW YOU ACT',
    'КАК ТЫ ЛЮБИШЬ И ДЕЙСТВУЕШЬ',
  ),
  'star.portrait.tension': L10nTriple(
    'GÜCÜN VE GERİLİMİN',
    'YOUR STRENGTH AND TENSION',
    'ТВОЯ СИЛА И НАПРЯЖЕНИЕ',
  ),
  'star.portrait.ai': L10nTriple(
    'KİŞİSEL YORUMUNDAN',
    'FROM YOUR PERSONAL READING',
    'ИЗ ТВОЕГО ЛИЧНОГО ЧТЕНИЯ',
  ),
  // Astrology personal bridges: one whole sentence appended after the sign
  // reading. {theme} is a real observed theme label, never a sky claim.
  'astro.bridge.overall.0': L10nTriple(
    'Son keşiflerinde {theme} konusu tekrar tekrar karşına çıkıyor; bugünkü yorumu en çok o alanda denemek sana daha çok şey söyleyebilir.',
    'Your recent discoveries keep returning to {theme}; today\'s reading may say the most when you try it there.',
    'В твоих недавних открытиях снова и снова звучит тема {theme}; сегодняшнее чтение больше всего скажет, если приложить его именно к ней.',
  ),
  'astro.bridge.overall.1': L10nTriple(
    'Yakın zamandaki okumalarında {theme} teması öne çıkıyor; yukarıdaki satırları bir de bu konuya uygulayarak oku.',
    'Your recent readings bring {theme} forward; read the lines above once more with that subject in mind.',
    'В недавних чтениях выходит вперёд тема {theme}; перечитай строки выше, держа её в уме.',
  ),
  'astro.bridge.overall.2': L10nTriple(
    'Kendi keşiflerinde {theme} meselesi hâlâ canlı; burç yorumunu bu konuyla yan yana koymak onu sana daha yakın kılar.',
    'In your own discoveries {theme} is still alive; setting the sign reading beside it brings it closer to you.',
    'В твоих открытиях тема {theme} всё ещё жива; если поставить чтение знака рядом с ней, оно станет ближе.',
  ),
  'astro.bridge.lane.0': L10nTriple(
    'Son keşiflerinde {theme} teması birkaç kez karşına çıktığı için bu satırlar sana özellikle denk düşebilir.',
    'Because {theme} has come up in several of your discoveries, these lines may land especially close.',
    'Поскольку тема {theme} не раз встречалась в твоих открытиях, эти строки могут оказаться особенно точными.',
  ),
  'astro.bridge.lane.1': L10nTriple(
    'Bu konu senin için yeni değil; {theme} teması son okumalarında da kendini gösterdi.',
    'This is not new for you; {theme} has shown up in your recent readings too.',
    'Для тебя это не ново; тема {theme} проявлялась и в недавних чтениях.',
  ),
  'astro.bridge.lane.2': L10nTriple(
    'Keşiflerinde {theme} sıkça geçtiği için bu alanı bugün biraz daha dikkatle düşünmeye değer.',
    'Since {theme} appears often in your discoveries, this area is worth a little more thought today.',
    'Так как тема {theme} часто встречается в твоих открытиях, об этой сфере сегодня стоит подумать внимательнее.',
  ),
  'astro.inner.close.0': L10nTriple(
    'Bugün bu konunun hangi küçük anda kendini gösterdiğine dikkat et; asıl ipucu çoğu zaman orada.',
    'Notice the small moment where this subject shows itself today; the real clue is often there.',
    'Обрати внимание, в какой маленький момент эта тема проявится сегодня; главная подсказка часто там.',
  ),
  'astro.inner.close.1': L10nTriple(
    'Burç yorumunu bu izle birlikte okumak, genel satırları senin hikâyene yaklaştırır.',
    'Reading the sign text alongside this trace brings the general lines closer to your own story.',
    'Если читать текст знака вместе с этим следом, общие строки становятся ближе к твоей истории.',
  ),
  'astro.inner.close.2': L10nTriple(
    'Bu örüntüyü birkaç gün daha izlemek, neyin gerçekten tekrar ettiğini gösterecek.',
    'Following this pattern for a few more days will show what truly keeps returning.',
    'Если понаблюдать за этим узором ещё несколько дней, станет видно, что действительно повторяется.',
  ),
};
