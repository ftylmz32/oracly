/// Localized AI insight prose for major-arcana card detail — static catalogue.
library;

import '../../../../../core/l10n/l10n_triple.dart';

/// Per-card localized aiInsight overlays.
abstract final class CardDetailInsights {
  CardDetailInsights._();

  static L10nTriple? of(int cardId) => _byId[cardId];

  static const Map<int, L10nTriple> _byId = {
    0: L10nTriple(
      'Deli kartı, hayatın en saf anını temsil eder: henüz sonuçtan korkmadan adım atılan o eşsiz eşik. Bu kart seni hatırlatır ki bilgelik bazen plan yapmadan güvenmekle gelir. Yolculuğun başında olduğunu kabul et; her düşüş de bir öğretmendir.',
      'The Fool card represents life\'s purest moment: that unique threshold where a step is taken before fearing the outcome. This card reminds you that wisdom sometimes comes from trusting without a plan. Accept that you are at the beginning of the journey; every fall is also a teacher.',
      'Карта Шут представляет самый чистый момент жизни: тот неповторимый порог, где шаг делается ещё до страха перед результатом. Эта карта напоминает, что мудрость иногда приходит через доверие без плана. Прими, что ты в начале пути; каждое падение тоже учитель.',
    ),
    1: L10nTriple(
      'Büyücü, evrenin seninle iş birliği yapmaya hazır olduğunu fısıldar. Potansiyelin zaten içinde; eksik olan yalnızca net niyet ve eylemdir. Bu kart, hayallerini somut gerçekliğe dönüştürme gücünü hatırlatır. Odaklandığında sınırların çoğu yalnızca zihninde vardır.',
      'The Magician whispers that the universe is ready to collaborate with you. Your potential is already within; what is missing is only clear intention and action. This card reminds you of the power to transform your dreams into concrete reality. When you focus, most of your limits exist only in your mind.',
      'Маг шепчет, что вселенная готова сотрудничать с тобой. Твой потенциал уже внутри; недостаёт лишь ясного намерения и действия. Эта карта напоминает о силе превращать мечты в конкретную реальность. Когда ты сосредоточен, большинство границ существует лишь в твоём уме.',
    ),
    2: L10nTriple(
      'Başrahibe, cevapların gürültünün ötesinde olduğunu hatırlatır. Bu kart seni acele etmekten alıkoyar ve içsel rehberliğe davet eder. Görünmeyen dünyanın dili sembollerle konuşur; dinlemeyi öğren. Sessizlik bir boşluk değil, en zengin bilgi kaynağıdır.',
      'The High Priestess reminds you that answers lie beyond the noise. This card holds you back from rushing and invites you toward inner guidance. The language of the unseen world speaks in symbols; learn to listen. Silence is not emptiness but the richest source of knowledge.',
      'Жрица напоминает, что ответы находятся за пределами шума. Эта карта удерживает тебя от спешки и приглашает к внутреннему руководству. Язык невидимого мира говорит символами; учись слушать. Тишина — не пустота, а богатейший источник знания.',
    ),
    3: L10nTriple(
      'İmparatoriçe, hayatın seni desteklediğini ve bolluğun doğal akışının içinde olduğunu hatırlatır. Bu kart kendine şefkat göstermeni ve yaratıcı enerjini serbest bırakmanı ister. Ektiğin her tohum, doğru koşullarda mutlaka filizlenecektir.',
      'The Empress reminds you that life supports you and that you are within the natural flow of abundance. This card asks you to show yourself compassion and to release your creative energy. Every seed you plant will surely sprout under the right conditions.',
      'Императрица напоминает, что жизнь тебя поддерживает и что ты находишься в естественном потоке изобилия. Эта карта просит проявить к себе сострадание и высвободить творческую энергию. Каждое посеянное тобой семя при верных условиях обязательно взойдёт.',
    ),
    4: L10nTriple(
      'İmparator, hayatında düzen kurma ve sorumluluk alma çağrısıdır. Bu kart seni istikrarlı adımlar atmaya ve sınırlarını korumaya davet eder. Gerçek güç baskıdan değil, güven vermekten doğar. Yapı, özgürlüğün düşmanı değil; onu taşıyan iskelettir.',
      'The Emperor is a call to establish order in your life and take responsibility. This card invites you to take steady steps and protect your boundaries. True power is born not from pressure but from giving trust. Structure is not the enemy of freedom; it is the skeleton that carries it.',
      'Император — призыв навести порядок в жизни и принять ответственность. Эта карта приглашает делать устойчивые шаги и защищать свои границы. Истинная сила рождается не из давления, а из того, что даёшь чувство уверенности. Структура — не враг свободы; это скелет, который её несёт.',
    ),
    5: L10nTriple(
      'Aziz, bilgeliğin aktarımının kadim bir gelenek olduğunu hatırlatır. Bu kart seni bir rehber aramaya veya kendi bilgini paylaşmaya davet eder. İnanç sistemleri iskelet gibidir; seni taşır ama nefes almana izin verecek esneklik de gerekir.',
      'The Hierophant reminds you that the transmission of wisdom is an ancient tradition. This card invites you to seek a guide or to share your own knowledge. Belief systems are like a skeleton; they carry you, but flexibility that lets you breathe is also needed.',
      'Иерофант напоминает, что передача мудрости — древняя традиция. Эта карта приглашает искать наставника или делиться собственным знанием. Системы верований подобны скелету; они тебя несут, но нужна и гибкость, позволяющая дышать.',
    ),
    6: L10nTriple(
      'Aşıklar, hayatının en önemli seçimlerinden birinin eşiğinde olduğunu fısıldar. Bu kart seni kalbinle hizalanmaya davet eder. Gerçek aşk özgür iradeyle seçilir; zorunluluktan değil, uyumdan doğar. Değerlerinle uyumlu olan yol seni eve götürür.',
      'The Lovers whisper that you stand at the threshold of one of life\'s most important choices. This card invites you to align with your heart. True love is chosen by free will; it is born not of obligation but of harmony. The path that aligns with your values leads you home.',
      'Влюблённые шепчут, что ты стоишь на пороге одного из самых важных выборов жизни. Эта карта приглашает выровняться с сердцем. Истинная любовь выбирается свободной волей; она рождается не из принуждения, а из гармонии. Путь, согласованный с твоими ценностями, ведёт тебя домой.',
    ),
    7: L10nTriple(
      'Savaş Arabası, iradenin en güçlü silah olduğunu hatırlatır. Bu kart seni hedefe odaklanmaya ve içsel çatışmaları dengelemeye davet eder. Zafer dışarıda değil, önce kendi içinde kazanılır. Yol uzun olsa da her adım seni yaklaştırır.',
      'The Chariot reminds you that will is the strongest weapon. This card invites you to focus on the goal and balance inner conflicts. Victory is not won outside but first within yourself. Even if the road is long, every step brings you closer.',
      'Колесница напоминает, что воля — самое сильное оружие. Эта карта приглашает сосредоточиться на цели и уравновесить внутренние конфликты. Победа одерживается не вовне, а сначала внутри себя. Даже если путь долог, каждый шаг приближает тебя.',
    ),
    8: L10nTriple(
      'Güç kartı, gerçek cesaretin korkusuzluk değil korkuyla yüzleşmek olduğunu hatırlatır. Bu kart seni sabırlı ve merhametli olmaya davet eder. İçindeki aslanı tanı; onu bastırmak yerine sevgiyle yönlendir.',
      'The Strength card reminds you that true courage is not fearlessness but facing fear. This card invites you to be patient and compassionate. Know the lion within; guide it with love instead of suppressing it.',
      'Карта Сила напоминает, что истинная храбрость — не бесстрашие, а встреча со страхом. Эта карта приглашает быть терпеливым и милосердным. Узнай льва внутри; направляй его любовью вместо того, чтобы подавлять.',
    ),
    9: L10nTriple(
      'Ermiş, cevapların dışarıda değil içinde olduğunu fısıldar. Bu kart seni kalabalıktan uzaklaşıp kendi ışığını yakmaya davet eder. Yalnızlık bir eksiklik değil; derin bilgeliğe açılan kutsal bir kapıdır.',
      'The Hermit whispers that answers are not outside but within. This card invites you to step away from the crowd and kindle your own light. Solitude is not a lack; it is a sacred door opening onto deep wisdom.',
      'Отшельник шепчет, что ответы не снаружи, а внутри. Эта карта приглашает отойти от толпы и зажечь собственный свет. Одиночество — не недостаток; это священная дверь, открывающаяся к глубокой мудрости.',
    ),
    10: L10nTriple(
      'Kader Çarkı, hayatın sürekli hareket halinde olduğunu hatırlatır. Bu kart seni değişime teslim olmaya davet eder. Şu an nerede olursan ol, çark dönmeye devam edecek. Direnç yerine akışa güven; her dönüş yeni bir fırsattır.',
      'The Wheel of Fortune reminds you that life is constantly in motion. This card invites you to surrender to change. Wherever you are now, the wheel will keep turning. Trust the flow instead of resistance; every turn is a new opportunity.',
      'Колесо Фортуны напоминает, что жизнь постоянно в движении. Эта карта приглашает сдаться переменам. Где бы ты ни был сейчас, колесо продолжит крутиться. Доверься потоку вместо сопротивления; каждый оборот — новая возможность.',
    ),
    11: L10nTriple(
      'Adalet kartı, evrenin her eylemi kaydettiğini hatırlatır. Bu kart seni dürüstlüğe ve sorumluluğa davet eder. Gerçek her zaman ortaya çıkar; gizlemek yalnızca dengeyi bozar. Merhamet ve adalet bir arada yürür.',
      'The Justice card reminds you that the universe records every action. This card invites you to honesty and responsibility. Truth always comes to light; hiding it only disturbs the balance. Compassion and justice walk together.',
      'Карта Справедливость напоминает, что вселенная записывает каждое действие. Эта карта приглашает к честности и ответственности. Истина всегда проявляется; скрывать её лишь нарушает баланс. Сострадание и справедливость идут вместе.',
    ),
    12: L10nTriple(
      'Asılan Adam, durmanın da bir eylem olduğunu hatırlatır. Bu kart seni acele etmekten alıkoyar ve yeni bir bakış açısına davet eder. Baş aşaşı gördüğünde dünya değişir; teslimiyet bazen en cesur adımdır.',
      'The Hanged Man reminds you that stopping is also an action. This card holds you back from rushing and invites a new perspective. When you see the world upside down, it changes; surrender is sometimes the bravest step.',
      'Повешенный напоминает, что остановка тоже действие. Эта карта удерживает тебя от спешки и приглашает к новому взгляду. Когда видишь мир вверх ногами, он меняется; смирение иногда самый смелый шаг.',
    ),
    13: L10nTriple(
      'Ölüm kartı, en çok korkulan ama en dönüştürücü arkadaşındır. Bu kart seni eskiyi bırakmaya davet eder. Gerçek ölüm değil, ego ve kalıpların ölümü söz konusudur. Her son, daha büyük bir başlangıcın habercisidir.',
      'The Death card is the most feared yet most transformative friend. This card invites you to let go of the old. It is not literal death at stake, but the death of ego and patterns. Every ending heralds a greater beginning.',
      'Карта Смерть — самый пугающий, но и самый преобразующий друг. Эта карта приглашает отпустить старое. Речь не о настоящей смерти, а о смерти эго и шаблонов. Каждый конец — предвестник большего начала.',
    ),
    14: L10nTriple(
      'Denge kartı, hayatın bir alkimya olduğunu hatırlatır. Bu kart seni sabırlı olmaya ve zıt güçleri uyumla birleştirmeye davet eder. Acele etme; en güzel sonuçlar yavaş ve bilinçli ilerlemeyle gelir.',
      'The Temperance card reminds you that life is an alchemy. This card invites you to be patient and to unite opposing forces in harmony. Do not rush; the most beautiful results come through slow and conscious progress.',
      'Карта Умеренность напоминает, что жизнь — алхимия. Эта карта приглашает быть терпеливым и гармонично соединять противоположные силы. Не спеши; самые прекрасные результаты приходят через медленное и осознанное продвижение.',
    ),
    15: L10nTriple(
      'Şeytan kartı, en karanlık zincirlerin bile gevşek olduğunu hatırlatır. Bu kart seni bağımlılıklarınla yüzleşmeye davet eder. Kurtulmak için önce fark etmek gerekir. Gölge senin bir parçan; onu reddetmek güç verir, kabul etmek özgürleştirir.',
      'The Devil card reminds you that even the darkest chains are loose. This card invites you to face your dependencies. To break free, you must first notice. The shadow is part of you; rejecting it gives it power, accepting it liberates.',
      'Карта Дьявол напоминает, что даже самые тёмные цепи ослаблены. Эта карта приглашает встретиться со своими зависимостями. Чтобы освободиться, сначала нужно осознать. Тень — часть тебя; отвергать её даёт ей силу, принимать — освобождает.',
    ),
    16: L10nTriple(
      'Kule kartı, en sarsıcı ama en dürüst arkadaşındır. Bu kart seni sahte temellerin çöküşüne hazırlar. Acı verici olsa da yıkım arınmadır; gerçek her zaman özgürlük getirir. Yeniden inşa etmek için önce eskiyi bırak.',
      'The Tower card is your most jarring yet most honest friend. This card prepares you for the collapse of false foundations. Though painful, destruction is purification; truth always brings freedom. To rebuild, first let go of the old.',
      'Карта Башня — самый сотрясающий, но и самый честный друг. Эта карта готовит тебя к крушению ложных оснований. Хотя и болезненно, разрушение — очищение; истина всегда приносит свободу. Чтобы строить заново, сначала отпусти старое.',
    ),
    17: L10nTriple(
      'Yıldız kartı, en karanlık gecenin ardından parlayan ilk ışıktır. Bu kart seni umut etmeye ve evrene güvenmeye davet eder. Yıkımın ardından gelir; yenilenme ve huzur müjdesi taşır. Sen de bir yıldızsın.',
      'The Star card is the first light shining after the darkest night. This card invites you to hope and to trust the universe. It comes after destruction; it carries the promise of renewal and peace. You too are a star.',
      'Карта Звезда — первый свет, сияющий после самой тёмной ночи. Эта карта приглашает надеяться и доверять вселенной. Она приходит после разрушения; несёт весть об обновлении и покое. Ты тоже звезда.',
    ),
    18: L10nTriple(
      'Ay kartı, görünmeyen dünyanın kapısını aralar. Bu kart seni sezgine güvenmeye davet eder. Her şey göründüğü gibi değil; korkuların seni aldatmasına izin verme. Ay ışığında yürümek cesaret ister.',
      'The Moon card opens the door to the unseen world. This card invites you to trust your intuition. Not everything is as it appears; do not let your fears deceive you. Walking in moonlight takes courage.',
      'Карта Луна приоткрывает дверь в невидимый мир. Эта карта приглашает доверять интуиции. Не всё таково, каким кажется; не позволяй страхам тебя обманывать. Идти в лунном свете требует смелости.',
    ),
    19: L10nTriple(
      'Güneş kartı, tarot destesinin en aydınlık mesajıdır. Bu kart seni neşelenmeye ve başarını kutlamaya davet eder. Karanlık geçti; şimdi parlamanın zamanı. Içindeki çocuk özgürce dans etsin.',
      'The Sun card is the brightest message in the tarot deck. This card invites you to rejoice and celebrate your success. The darkness has passed; now it is time to shine. Let the child within dance freely.',
      'Карта Солнце — самое светлое послание в колоде таро. Эта карта приглашает радоваться и праздновать свой успех. Тьма прошла; теперь время сиять. Пусть ребёнок внутри свободно танцует.',
    ),
    20: L10nTriple(
      'Mahkeme kartı, hayatının en derin çağrısını fısıldar. Bu kart seni geçmişi değerlendirmeye ve yeniden doğuşa davet eder. Affetmek zayıflık değil, en büyük güçtür. Mezarlarından kalk; yeni hayatın seni bekliyor.',
      'The Judgement card whispers life\'s deepest call. This card invites you to evaluate the past and toward rebirth. Forgiving is not weakness but the greatest strength. Rise from your graves; your new life awaits you.',
      'Карта Суд шепчет самый глубокий зов твоей жизни. Эта карта приглашает оценить прошлое и к возрождению. Прощение — не слабость, а величайшая сила. Восстань из могил; новая жизнь тебя ждёт.',
    ),
    21: L10nTriple(
      'Dünya kartı, Major Arcana yolculuğunun muhteşem finalidir. Bu kart seni kutlamaya ve bütünlüğü hissetmeye davet eder. Her döngü bir sonla biter ve yeni bir başlangıçla devam eder. Sen evrenin bir parçasısın.',
      'The World card is the magnificent finale of the Major Arcana journey. This card invites you to celebrate and to feel wholeness. Every cycle ends with a conclusion and continues with a new beginning. You are a part of the universe.',
      'Карта Мир — великолепный финал пути Старших Арканов. Эта карта приглашает праздновать и ощущать целостность. Каждый цикл завершается концом и продолжается новым началом. Ты — часть вселенной.',
    ),
  };
}

