/// Dream analysis beats — TR / EN / RU. Catalog, not UI.
library;

import '../l10n_triple.dart';

const kL10nDreamRead = <String, L10nTriple>{
  'dream.read.feeling.empty': L10nTriple(
    'Bu anlatıda henüz tutunacak bir his yok; sahne henüz durmuyor.',
    'There is not yet a feeling to hold; the scene has not settled.',
    'Чувства, за которое можно держаться, пока нет; сцена ещё не встала.',
  ),
  'dream.read.feeling.emotion.0': L10nTriple(
    'Bu rüyada {emotion} bir hava duruyor; acele etmeden orada bekliyor.',
    'A {emotion} air sits in this dream; it waits there without hurry.',
    'В этом сне стоит {emotion} воздух; он ждёт там без спешки.',
  ),
  'dream.read.feeling.emotion.1': L10nTriple(
    '{emotion} bir ton, {scene} sahnesinin kenarında duruyor.',
    'A {emotion} tone sits at the edge of {scene}.',
    '{emotion} тон стоит у края сцены: {scene}.',
  ),
  'dream.read.feeling.emotion.2': L10nTriple(
    'İlk duran his {emotion}; sahne kendini ispatlamaya çalışmıyor.',
    'The first feeling is {emotion}; the scene is not trying to prove itself.',
    'Первое чувство — {emotion}; сцена не пытается себя доказать.',
  ),
  'dream.read.feeling.scene.0': L10nTriple(
    'Adlandırılmış bir duygu yok; duran şey {scene} sahnesinin kendisi.',
    'No feeling was named; what sits here is the scene of {scene}.',
    'Названного чувства нет; стоит сама сцена: {scene}.',
  ),
  'dream.read.feeling.scene.1': L10nTriple(
    'His henüz net değil; {scene} yine de yumuşak bir iz bırakıyor.',
    'The feeling is not sharp yet; {scene} still leaves a quiet mark.',
    'Чувство ещё не ясно; {scene} всё же оставляет тихий след.',
  ),
  'dream.read.detail.empty': L10nTriple(
    'Belirgin bir ayrıntı henüz durmuyor; uydurmadan burada kalıyorum.',
    'No sharp detail sits yet; I stay here without inventing one.',
    'Яркой детали пока нет; остаюсь здесь, ничего не выдумывая.',
  ),
  'dream.read.detail.0': L10nTriple(
    'Gözün takıldığı yer: {detail}.',
    'Where the eye catches: {detail}.',
    'Куда цепляется взгляд: {detail}.',
  ),
  'dream.read.detail.1': L10nTriple(
    '{detail} tek başına duruyor; etrafı henüz kalabalık değil.',
    '{detail} sits on its own; the space around it is not crowded yet.',
    '{detail} стоит само по себе; вокруг ещё не тесно.',
  ),
  'dream.read.detail.2': L10nTriple(
    'Sahnenin seçilir yeri {detail}; gerisi daha silik duruyor.',
    'The clearer place in the scene is {detail}; the rest sits more faintly.',
    'Более ясное место сцены — {detail}; остальное стоит бледнее.',
  ),
  'dream.read.symbol.empty': L10nTriple(
    'Burada sembol uydurmam. Anlatım ince duruyor; meraklı bir boşluk bırakıyorum.',
    'I will not invent a symbol here. The telling is thin; I leave a curious gap.',
    'Символ здесь не выдумаю. Рассказ тонкий; оставляю любопытную пустоту.',
  ),
  'dream.read.symbol.image.0': L10nTriple(
    '{image} bu sahnede tek bir anlama kilitlenmiyor. {scene} içinde nasıl durduğuna bakmak daha yakın.',
    '{image} does not lock to one meaning here. It is closer to watch how it sits inside {scene}.',
    '{image} здесь не запирается в одном смысле. Ближе смотреть, как оно стоит внутри {scene}.',
  ),
  'dream.read.symbol.image.1': L10nTriple(
    '{image} imgesi bir cevap değil; {place} ile yan yana gelince tanıdık bir yerde beklenmedik bir kıpırdanma gibi duruyor.',
    '{image} is not an answer; next to {place} it sits like an unexpected stir in a familiar place.',
    '{image} — не ответ; рядом с {place} стоит как неожиданное движение в знакомом месте.',
  ),
  'dream.read.symbol.image.2': L10nTriple(
    '{image} ile {companion} birlikte duruyor. İkisini yan yana okumak, her birini ayrı kilitlemekten daha dürüst duruyor.',
    '{image} and {companion} sit together. Reading them side by side feels more honest than locking each one down.',
    '{image} и {companion} стоят вместе. Читать их рядом честнее, чем запирать каждый отдельно.',
  ),
  'dream.read.symbol.fog.0': L10nTriple(
    'Sahne sisli duruyor. {scene} bir işaret gibi bağırmaz; daha çok yarım kalmış bir iz gibi düşünülebilir.',
    'The scene sits in fog. {scene} does not shout like a sign; it can be thought of as a half-finished trace.',
    'Сцена стоит в тумане. {scene} не кричит как знак; её можно мыслить как недописанный след.',
  ),
  'dream.read.you.pattern': L10nTriple(
    '{date} tarihli rüyanda da {symbols} birlikte duruyordu. Aynı imgelerin dönmesi, zihnin hâlâ o temada dolaştığını düşündürebilir.',
    'In the dream from {date}, {symbols} sat together too. Their return can suggest the mind is still walking that theme.',
    'В сне от {date} тоже стояли вместе {symbols}. Их возвращение может намекать, что ум всё ещё ходит вокруг этой темы.',
  ),
  'dream.read.you.tag': L10nTriple(
    'Bunu {tag} diye işaretledin. Rüyadaki {image} o dosyanın kenarında duruyor; tek başına bir hayat hikâyesi değil.',
    'You marked this as {tag}. {image} in the dream sits at the edge of that file; it is not a life story on its own.',
    'Ты отметил это как {tag}. {image} во сне стоит у края этой папки; само по себе это не история жизни.',
  ),
  'dream.read.ask.image.0': L10nTriple(
    '{image} imgesi gündüzünde nereye denk geliyor?',
    'Where does the image of {image} meet your waking day?',
    'Где образ {image} встречается с твоим дневным днём?',
  ),
  'dream.read.ask.image.1': L10nTriple(
    'Bu sahnede {image} dururken sen neredeydin?',
    'Where were you, while {image} sat in this scene?',
    'Где был ты, пока {image} стояло в этой сцене?',
  ),
  'dream.read.ask.open.0': L10nTriple(
    'Bu rüyada durmak istediğin bir an kaldı mı?',
    'Is there a moment in this dream you still want to stay with?',
    'Остался ли в этом сне миг, с которым ты ещё хочешь побыть?',
  ),
  'dream.read.ask.open.1': L10nTriple(
    'Anlatmak istediğin küçük bir ayrıntı duruyor mu hâlâ?',
    'Is a small detail you wanted to tell still sitting there?',
    'Сидит ли ещё маленькая деталь, которую ты хотел рассказать?',
  ),
};
