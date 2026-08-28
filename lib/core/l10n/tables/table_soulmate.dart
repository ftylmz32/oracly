/// SoulMate form and result chrome — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nSoulMate = <String, L10nTriple>{
  'soulmate.list_title': L10nTriple('Ruh Eşi', 'Soulmate', 'Родственная душа'),
  'soulmate.list_description': L10nTriple(
    'Henüz senin için bir portre oluşturmadık.',
    'We have not created a portrait for you yet.',
    'Мы ещё не создали для тебя портрет.',
  ),
  'soulmate.list_description_saved': L10nTriple(
    'Kayıtlı portren ve yorumun seni bekliyor.',
    'Your saved portrait and reading are waiting.',
    'Сохранённый портрет и толкование ждут тебя.',
  ),
  'soulmate.empty_portrait': L10nTriple(
    'Henüz senin için bir portre oluşturmadık.',
    'We have not created a portrait for you yet.',
    'Мы ещё не создали для тебя портрет.',
  ),
  'soulmate.screen_title': L10nTriple('RUH EŞİ', 'SOULMATE', 'РОДСТВЕННАЯ ДУША'),
  'soulmate.screen_lead': L10nTriple(
    'Birkaç sakin bilgi yeter. Portre, senin paylaştıklarından doğan sembolik bir hayal.',
    'A few calm details are enough. The portrait is a symbolic imagining born from what you share.',
    'Достаточно нескольких спокойных деталей. Портрет — символический образ из того, чем ты делишься.',
  ),
  'soulmate.honesty': L10nTriple(
    'Bu sembolik bir portre — gerçek bir kişi, kesin ruh eşi veya gelecek buluşma iddiası değil.',
    'This is a symbolic portrait — not a real person, a guaranteed soulmate, or a future meeting.',
    'Это символический портрет — не реальный человек, не гарантированная родственная душа и не встреча в будущем.',
  ),
  'soulmate.interpretation': L10nTriple('Sezgisel yansıma', 'Intuitive reflection', 'Интуитивное отражение'),
  'soulmate.energy': L10nTriple(
    'BU PORTREDE İLK DİKKATİMİ ÇEKEN',
    'WHAT FIRST DRAWS MY EYE IN THIS PORTRAIT',
    'ЧТО ПЕРВЫМ БРОСАЕТСЯ В ГЛАЗА В ЭТОМ ПОРТРЕТЕ',
  ),
  'soulmate.attraction': L10nTriple(
    'SENİ NEDEN ÇEKEBİLİR?',
    'WHY IT MIGHT DRAW YOU',
    'ПОЧЕМУ ЭТО МОЖЕТ ПРИТЯГИВАТЬ',
  ),
  'soulmate.dynamics': L10nTriple('YANINDA NASIL DURABİLİR', 'HOW IT MIGHT SIT BESIDE YOU', 'КАК ЭТО МОЖЕТ БЫТЬ РЯДОМ'),
  'soulmate.feeling': L10nTriple(
    'SANA NASIL BİR HİSSETTİREBİLİR?',
    'HOW IT MIGHT FEEL TO YOU',
    'КАКОЕ ЧУВСТВО ЭТО МОЖЕТ ПРИНЕСТИ',
  ),
  'soulmate.your_side': L10nTriple(
    'SENİN TARAFINDA ÖNE ÇIKAN',
    'WHAT STANDS OUT ON YOUR SIDE',
    'ЧТО ВЫДЕЛЯЕТСЯ НА ТВОЕЙ СТОРОНЕ',
  ),
  'soulmate.symbolic': L10nTriple('SEMBOLİK MESAJ', 'SYMBOLIC MESSAGE', 'СИМВОЛИЧЕСКОЕ ПОСЛАНИЕ'),
  'soulmate.you': L10nTriple('sen', 'you', 'ты'),
  'soulmate.season.winter': L10nTriple('kış', 'winter', 'зимнем'),
  'soulmate.season.spring': L10nTriple('ilkbahar', 'spring', 'весеннем'),
  'soulmate.season.summer': L10nTriple('yaz', 'summer', 'летнем'),
  'soulmate.season.autumn': L10nTriple('sonbahar', 'autumn', 'осеннем'),
  'soulmate.copy.character_calm': L10nTriple(
    'Bu portrede ilk dikkatimi çeken şey, {season} ışığındaki sakin duruş. Bakış kanıt aramaz; yanında nefes alacak yer bırakır.',
    'What first draws my eye here is the calm poise in {season} light. The gaze does not hunt for proof; it leaves room to breathe beside it.',
    'Первым здесь бросается в глаза спокойная осанка в {season} свете. Взгляд не ищет доказательств — он оставляет место дышать рядом.',
  ),
  'soulmate.copy.character_near': L10nTriple(
    'Bu portrede ilk dikkatimi çeken şey, yakın duran ama acele etmeyen bir bakış. {season} ışığında net kalır.',
    'What first draws my eye is a gaze that stays close without rushing. In {season} light it stays clear.',
    'Первым бросается в глаза взгляд, который держится близко, но не спешит. В {season} свете он остаётся ясным.',
  ),
  'soulmate.copy.attraction_plain': L10nTriple(
    '{who}, bu yüz seni “tamamlanmış hikâye” olduğu için değil; yanında kendin kalabildiğin alanı çağırdığı için çekebilir.',
    '{who}, this face may draw you not because the story is finished, but because it calls a space where you can stay yourself.',
    '{who}, это лицо может притягивать не потому, что история завершена, а потому что зовёт пространство, где ты можешь остаться собой.',
  ),
  'soulmate.copy.attraction_intent': L10nTriple(
    '{who}, niyetin (“{intention}”) yüzde yumuşak bir iz bırakıyor. Seni çeken kanıt değil; o niyetin yanında nefes alıp alamamak.',
    '{who}, your intention (“{intention}”) leaves a soft trace in the face. What draws you is not proof; it is whether you can breathe beside that intention.',
    '{who}, твоё намерение (“{intention}”) оставляет на лице мягкий след. Притягивает не доказательство, а то, можно ли дышать рядом с этим намерением.',
  ),
  'soulmate.copy.dynamics_free': L10nTriple(
    '{who} için dinamiği zorlamak değil izin vermek: paylaşılmış sessizlik de bağ olabilir.',
    'For {who}, the dynamic is permission, not force: shared quiet can also be a bond.',
    'Для {who} динамика — не давление, а позволение: общая тишина тоже может быть связью.',
  ),
  'soulmate.copy.dynamics_pref': L10nTriple(
    '{who}, verdiğin yönelim ({pref}) yüzdeki ritmi yumuşak tutuyor. Zorlamak değil, yanında durabilmek.',
    '{who}, the preference you named ({pref}) keeps the rhythm in the face soft. Not forcing it — staying beside it.',
    '{who}, названное тобой предпочтение ({pref}) держит ритм на лице мягким. Не давить — уметь быть рядом.',
  ),
  'soulmate.copy.feeling.0': L10nTriple(
    '{who}, bu yüz sana acele ettiren değil; yavaşlayıp kalabildiğin bir yakınlık hissi verebilir.',
    '{who}, this face may not rush you; it can feel like closeness where you are allowed to slow down.',
    '{who}, это лицо может не торопить тебя — близость, где можно замедлиться.',
  ),
  'soulmate.copy.feeling.1': L10nTriple(
    '{who}, portredeki ışık sert değil; yanında hafifleyebileceğin bir sıcaklık taşıyor.',
    '{who}, the light in the portrait is not harsh; it carries a warmth where you might soften.',
    '{who}, свет в портрете не резкий — в нём тепло, рядом с которым можно смягчиться.',
  ),
  'soulmate.copy.feeling.2': L10nTriple(
    '{who}, bu karakter sana baskı değil; güvenle durabildiğin bir eşlik hissi bırakabilir.',
    '{who}, this character may leave not pressure, but a sense of company you can stand in with trust.',
    '{who}, этот образ может оставить не давление, а чувство присутствия, в котором можно стоять с доверием.',
  ),
  'soulmate.copy.your_side.0': L10nTriple(
    '{who}, senin tarafında öne çıkan şey, kendini kaybetmeden açılabilme ihtiyacın olabilir.',
    '{who}, what may stand out on your side is the need to open without losing yourself.',
    '{who}, на твоей стороне может выделяться потребность открыться, не теряя себя.',
  ),
  'soulmate.copy.your_side.1': L10nTriple(
    '{who}, portre senin yumuşak sınırlarını hatırlatıyor: yakınlık, kendini küçültmek zorunda değil.',
    '{who}, the portrait recalls your soft boundaries: closeness does not have to shrink you.',
    '{who}, портрет напоминает о мягких границах: близость не обязана уменьшать тебя.',
  ),
  'soulmate.copy.your_side.2': L10nTriple(
    '{who}, senin tarafında öne çıkan, acele etmeden seçebilme hakkın.',
    '{who}, what stands out on your side is the right to choose without rushing.',
    '{who}, на твоей стороне выделяется право выбирать без спешки.',
  ),
  'soulmate.brand': L10nTriple('ORACLY', 'ORACLY', 'ORACLY'),
  'soulmate.name_label': L10nTriple('İsim veya hitap adı', 'Name or how you are addressed', 'Имя или обращение'),
  'soulmate.name_hint': L10nTriple('Adın veya hitabın', 'Your name or address', 'Твоё имя или обращение'),
  'soulmate.form_why': L10nTriple(
    'İsim yoruma, doğum ışığa, duruş yüze, tercih portreye iz bırakır.',
    'Name shapes the reading, birth the light, presence the face, preference the portrait.',
    'Имя формирует текст, дата — свет, присутствие — лицо, предпочтение — портрет.',
  ),
  'soulmate.birth_label': L10nTriple('Doğum tarihi', 'Birth date', 'Дата рождения'),
  'soulmate.birth_hint': L10nTriple('Gün / Ay / Yıl', 'Day / Month / Year', 'День / месяц / год'),
  'soulmate.gender_label': L10nTriple(
    'Portredeki duruş (isteğe bağlı)',
    'Presence in the portrait (optional)',
    'Присутствие в портрете (необязательно)',
  ),
  'soulmate.gender_hint': L10nTriple('Fark etmez', 'Either', 'Не важно'),
  'soulmate.gender_feminine': L10nTriple('Kadın', 'Feminine', 'Женский'),
  'soulmate.gender_masculine': L10nTriple('Erkek', 'Masculine', 'Мужской'),
  'soulmate.intention_label': L10nTriple(
    'Bir tercih (isteğe bağlı)',
    'A preference (optional)',
    'Предпочтение (необязательно)',
  ),
  'soulmate.intention_hint':
      L10nTriple('Kısa bir tercih veya niyet', 'A short preference or intention', 'Краткое предпочтение или намерение'),
  'soulmate.draw_cta': L10nTriple('PORTREYİ OLUŞTUR', 'CREATE PORTRAIT', 'СОЗДАТЬ ПОРТРЕТ'),
  'soulmate.redraw_cta': L10nTriple('Yeniden Oluştur', 'Create again', 'Создать снова'),
  'soulmate.drawing': L10nTriple(
    'Portrede öne çıkan detayları hazırlıyorum...',
    'Preparing the details that stand out in the portrait...',
    'Готовлю детали, которые выделяются в портрете...',
  ),
  'soulmate.drawing_2': L10nTriple(
    'Senden aldığım ipuçlarını bir araya getiriyorum...',
    'Bringing together the hints you gave me...',
    'Собираю воедино подсказки, которые ты дал...',
  ),
  'soulmate.drawing_3': L10nTriple(
    'Işık yavaşça yerleşiyor…',
    'Light is settling gently…',
    'Свет мягко укладывается…',
  ),
  'soulmate.unavailable': L10nTriple(
    'Portreyi şu an oluşturamadım. Bir daha deneyelim.',
    'I could not create the portrait right now. Let us try again.',
    'Сейчас не удалось создать портрет. Давай попробуем ещё раз.',
  ),
  'soulmate.retry': L10nTriple('TEKRAR DENE', 'TRY AGAIN', 'ЕЩЁ РАЗ'),
  'soulmate.name_required': L10nTriple(
    'Devam etmek için bir isim veya hitap yaz.',
    'Write a name or address to continue.',
    'Чтобы продолжить, напиши имя или обращение.',
  ),
  'soulmate.birth_required': L10nTriple('Doğum tarihini seç.', 'Choose a birth date.', 'Выбери дату рождения.'),
  'soulmate.premium_required': L10nTriple(
    'Bu özellik Premium üyelik gerektirir.',
    'This feature requires Premium membership.',
    'Эта возможность требует Премиум-подписку.',
  ),
  'soulmate.portrait_semantics': L10nTriple(
    'Oluşturulan sembolik portre',
    'Generated symbolic portrait',
    'Созданный символический портрет',
  ),
};
