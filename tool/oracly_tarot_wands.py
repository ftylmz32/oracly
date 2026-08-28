"""Wands — will, spark, direction."""

from oracly_tarot_minors_base import _mean, minor

WANDS = [
    minor("wands", 1,
        (["kıvılcım", "niyet", "hareket"], ["spark", "intent", "motion"], ["искра", "намерение", "движение"]),
        (["sönme", "dağılma", "erte"], ["dulling", "scatter", "defer"], ["угасание", "рассев", "откладывание"]),
        _mean(
            ("İlk kıvılcım; henüz biçim almamış irade.", "A first spark; will not yet shaped.", "Первая искра; воля ещё без формы."),
            ("Bağda taze bir cesaret belirebilir; alevi dayatmak gerekmez.", "Fresh courage may appear in a bond; the flame need not be forced.", "В связи может явиться свежая смелость; пламя не нужно навязывать."),
            ("Yeni bir iş kıvılcımı mümkün görünür.", "A new spark of work may be possible.", "Возможна новая искра дела."),
            ("Küçük bir yatırım niyeti uyanabilir; tüm kaynağı yakmak değildir.", "A small intent to invest may stir; this is not burning the whole store.", "Может проснуться малое намерение вложить; это не сжечь весь запас."),
            ("İçeride 'şimdi' diyen bir ısı hissedilebilir.", "An inner heat that says 'now' may be felt.", "Внутри может ощущаться жар, говорящий «сейчас»."),
            ("Kıvılcım, plansız yangına kayabilir.", "The spark may slide into a fire without a plan.", "Искра может стать пожаром без плана."),
            ("Küçük tut; söndürme, savurma.", "Keep it small; do not snuff it, do not fling it.", "Держи малым; не гаси и не разбрасывай."),
            ("Olası iklim: bir başlangıç ısısı.", "A possible climate: the heat of a beginning.", "Возможный климат: тепло начала."),
        ),
        ["major_00", "major_01", "cups_01"],
        ("Deli eşik, Büyücü el, Kupa Ası duygu kıvılcımıdır.", "Fool is threshold; Magician the hand; Ace of Cups a spark of feeling.", "Шут — порог; Маг — рука; Туз Кубков — искра чувства."),
    ),
    minor("wands", 2,
        (["iki yol", "bekleme", "ufuk"], ["two paths", "waiting", "horizon"], ["два пути", "ожидание", "горизонт"]),
        (["kararsızlık", "acele seçim", "kayıtsızlık"], ["indecision", "hasty pick", "apathy"], ["нерешительность", "поспешный выбор", "апатия"]),
        _mean(
            ("İki ufuk arasında duran ateş; henüz adım değil.", "Fire standing between two horizons; not yet a step.", "Огонь между двумя горизонтами; ещё не шаг."),
            ("İlişkide iki tempo çatışabilir; birini ezmek gerekmez.", "Two tempos may clash in a bond; one need not crush the other.", "В связи могут столкнуться два темпа; один не обязан давить другой."),
            ("İki iş yolu görünüyor olabilir; seçim henüz zorunlu değildir.", "Two work paths may be in view; a choice is not yet required.", "Могут быть видны два пути дела; выбор ещё не обязателен."),
            ("İki harcama yönü belirebilir; ikisini birden kovalamak yorucu olabilir.", "Two spending headings may appear; chasing both can tire.", "Могут явиться два курса трат; гнаться за обоими утомляет."),
            ("İçeride bekleyen bir irade, manzarayı izliyor olabilir.", "A waiting will inside may be watching the view.", "Внутри ждущая воля может смотреть на вид."),
            ("Bekleyiş, kaçış gibi giyinebilir.", "Waiting may dress as escape.", "Ожидание может одеться бегством."),
            ("Ufka bak; henüz atlama.", "Look at the horizon; do not leap yet.", "Смотри на горизонт; ещё не прыгай."),
            ("Olası iklim: seçimden önceki duruş.", "A possible climate: a stance before choosing.", "Возможный климат: поза до выбора."),
        ),
        ["major_06", "swords_02", "pentacles_02"],
        ("Aşıklar değer seçer; Kılıç ve Tılsım ikilileri mesafe ve denge izidir.", "Lovers choose value; Twos of Swords and Pentacles hold distance and balance.", "Влюблённые выбирают ценность; Двойки Мечей и Пентаклей — дистанция и равновесие."),
    ),
]

