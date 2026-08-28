"""Major Arcana 0–21 seed — observational, never certain."""

from oracly_tarot_emit import MAJOR_FILES


def M(n, name, up, rev, meanings, rel_ids, rel_note):
    return {
        "id": f"major_{n:02d}",
        "number": n,
        "arcana": "major",
        "suit": "none",
        "name": name,
        "up": up,
        "rev": rev,
        "meanings": meanings,
        "relations": {"ids": rel_ids, "note": rel_note},
        "visual": f"assets/tarot/cards/major/{MAJOR_FILES[n]}",
    }


MAJORS = [
    M(
        0,
        ("Deli", "The Fool", "Шут"),
        (["eşik", "merak", "izin"], ["threshold", "curiosity", "permission"], ["порог", "любопытство", "разрешение"]),
        (["acele", "dağılma", "kaçış"], ["haste", "scatter", "avoidance"], ["спешка", "рассеянность", "избегание"]),
        {
            "symbolic": ("Henüz bağlanmamış bir adım; eşikte duran merak.", "A step not yet claimed; curiosity at a threshold.", "Шаг, который ещё не выбран; любопытство на пороге."),
            "love": ("Bağda taze bir açıklık belirebilir; acele bir sözden önce durmak değerli olabilir.", "A fresh openness may appear in a bond; pausing before a hasty vow can matter.", "В связи может появиться свежая открытость; пауза перед поспешным словом бывает важна."),
            "career": ("Yeni bir iş hareketi mümkün görünür; deneyimden önce niyeti netleştirmek sakinleştirir.", "A new work movement may be possible; clarifying intent before experience steadies the step.", "Возможно новое движение в деле; ясность намерения до опыта успокаивает шаг."),
            "money": ("Kaynaklar henüz şekil almamış olabilir; ilk harcamayı bir soru gibi tutmak yardımcı olabilir.", "Resources may still be unformed; holding the first spend as a question can help.", "Средства могут быть ещё бесформенными; первый расход стоит держать как вопрос."),
            "personal": ("İçeride bir izin hissi uyanabilir: henüz kimse olmadan yola bakmak.", "An inner permission may stir: looking at the road before becoming anyone.", "Внутри может проснуться разрешение: смотреть на путь, ещё ни кем не став."),
            "challenge": ("Merak, hazır olmadan atlamaya dönüşebilir.", "Curiosity may tilt into leaping before one is ready.", "Любопытство может стать прыжком без готовности."),
            "guidance": ("Kapıya yaklaş; henüz bütün cevapları taşımak zorunda değilsin.", "Approach the door; you do not have to carry every answer yet.", "Подойди к двери; не обязательно нести все ответы сразу."),
            "future": ("Olası iklim: daha açık bir başlangıç — vaat değil, davet.", "A possible climate: a more open beginning — an invitation, not a promise.", "Возможный климат: более открытое начало — приглашение, не обещание."),
        },
        ["major_17", "major_21", "wands_01"],
        ("Yıldız ve Dünya ile eşik ailesinde konuşabilir; Değnek Ası ilk kıvılcımı taşır.", "May converse with the Star and World as a threshold family; Ace of Wands carries the first spark.", "Может говорить со Звездой и Миром как семейство порога; Туз Жезлов несёт первую искру."),
    ),
    M(
        1,
        ("Büyücü", "The Magician", "Маг"),
        (["dikkat", "zanaat", "yön"], ["attention", "craft", "direction"], ["внимание", "ремесло", "направление"]),
        (["dağınık irade", "gösteriş", "savurganlık"], ["scattered will", "display", "waste"], ["рассеянная воля", "показ", "трата"]),
        {
            "symbolic": ("Elin, bakışın ve niyetin aynı masada buluşması.", "Hand, gaze, and intent meeting at the same table.", "Рука, взгляд и намерение встречаются за одним столом."),
            "love": ("İlişkide net bir jest mümkün olabilir; sözün davranışla uyumu önem kazanabilir.", "A clear gesture in relating may be possible; speech matching action may matter more.", "Возможен ясный жест в близости; согласие слова и поступка может стать важнее."),
            "career": ("Yeteneği görünür kılmak bir seçenek olabilir; araçları abartmadan kullanmak sakin duruştur.", "Making a skill visible may be an option; using tools without display is the calmer stance.", "Сделать умение видимым может быть выбором; пользоваться средствами без показухи — более спокойная поза."),
            "money": ("Kaynakları bir araya getirmek mümkün görünür; hepsini bir anda harcamak gerekmez.", "Gathering means may be possible; they need not all be spent at once.", "Собрать средства, возможно, уместно; не обязательно тратить всё сразу."),
            "personal": ("Odak, dağınık bir gücü sade bir işe çevirebilir.", "Focus may turn scattered force into a simple task.", "Фокус может превратить рассеянную силу в простое дело."),
            "challenge": ("Yetenek, başkalarını etkilemek için kullanılabilir.", "Skill may be used to impress rather than to make.", "Умение может служить впечатлению, а не делу."),
            "guidance": ("Bir aracı seç ve onu sonuna kadar kullan; hepsini birden savurma.", "Choose one tool and use it through; do not scatter them all.", "Выбери один инструмент и доведи его; не разбрасывай все сразу."),
            "future": ("Olası iklim: daha bilinçli bir yön — sonuç garantisi değil.", "A possible climate: more conscious direction — not a guaranteed outcome.", "Возможный климат: более сознательное направление — не гарантия итога."),
        },
        ["major_02", "wands_01", "pentacles_01"],
        ("Başrahibe iç sesi tutar; Asa ve Tılsım Ası el ile maddeyi hatırlatır.", "The Priestess holds inner hearing; Aces of Wands and Pentacles recall hand and matter.", "Жрица держит внутренний слух; Тузы Жезлов и Пентаклей напоминают о руке и материи."),
    ),
    M(2, ("Başrahibe", "The High Priestess", "Верховная Жрица"),
        (["sessizlik", "sezgi", "giz"], ["silence", "sensing", "withholding"], ["тишина", "чутьё", "удержание"]),
        (["inkâr", "kapalı sır", "kopukluk"], ["denial", "closed secret", "disconnect"], ["отрицание", "закрытая тайна", "разрыв"]),
        {
            "symbolic": ("Henüz söze dökülmemiş bir bilgi; perde arkasındaki duruş.", "Knowing not yet spoken; a stance behind the veil.", "Знание, ещё не сказанное; поза за завесой."),
            "love": ("Bağda söylenmeyen bir katman olabilir; zorlamak yerine beklemek daha nazik olabilir.", "A bond may hold an unspoken layer; waiting may be kinder than forcing.", "В связи может быть несказанный слой; ждать бывает мягче, чем давить."),
            "career": ("Görünmeyen bilgi işe yön verebilir; her şeyi hemen açıklamak gerekmez.", "Unseen knowledge may guide work; not everything needs to be declared at once.", "Невидимое знание может вести дело; не всё нужно сразу объявлять."),
            "money": ("Gizli bir maliyet veya saklı bir kaynak fark edilebilir; acele spekülasyon sakin değildir.", "A hidden cost or a held resource may be noticed; hasty speculation is not calm.", "Может открыться скрытый расход или удержанный ресурс; спешная игра не спокойна."),
            "personal": ("İç ses, gürültüden çekildiğinde daha net duyulabilir.", "The inner voice may be clearer when noise recedes.", "Внутренний голос яснее, когда шум отступает."),
            "challenge": ("Sessizlik, kaçış veya başkalarını dışarıda bırakmak olabilir.", "Silence may become avoidance or shutting others out.", "Тишина может стать избеганием или отсечением других."),
            "guidance": ("Cevabı biraz daha içerde tut; henüz sahneye çıkarmak zorunda değilsin.", "Keep the answer a little longer inside; it does not have to take the stage yet.", "Подержи ответ ещё внутри; ему не обязательно выходить на сцену."),
            "future": ("Olası iklim: daha içsel bir dinleme dönemi.", "A possible climate: a period of more inward listening.", "Возможный климат: время более внутреннего слушания."),
        },
        ["major_18", "cups_01", "major_09"],
        ("Ay belirsiz görmeyi, Kupa Ası duyguyu, Ermiş yalnız ışığı taşır.", "The Moon holds unclear seeing; Ace of Cups feeling; the Hermit solitary light.", "Луна — неясное зрение; Туз Кубков — чувство; Отшельник — одинокий свет."),
    ),
]

