# Generate ORACLY 78-card Dart catalogues.
# Run from tool/: python generate_oracly_tarot_deck.py
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from oracly_tarot_cups_rest import CUPS_REST
from oracly_tarot_emit import write_catalog
from oracly_tarot_majors import MAJORS
from oracly_tarot_majors_b import MAJORS_REST
from oracly_tarot_majors_c import MAJORS_END
from oracly_tarot_minors_base import C
from oracly_tarot_swords_pentacles import PENTACLES, SWORDS
from oracly_tarot_wands import WANDS
from oracly_tarot_wands_cups import CUPS, WANDS_REST

_FORBIDDEN = (
    "kesinlikle",
    "mutlaka olacak",
    "definitely will",
    "will definitely",
    "this will definitely",
    "обязательно произойдёт",
    "обязательно произойдет",
    "обязательно случится",
    "kesin olacak",
)


def _texts(card: dict) -> list[str]:
    out = [*card["name"], *card["relations"]["note"]]
    for bucket in (card["up"], card["rev"]):
        for loc in bucket:
            out.extend(loc)
    for triple in card["meanings"].values():
        out.extend(triple)
    return out


def _assert_fields(cards: list[dict], known: set[str]) -> None:
    for card in cards:
        for rid in card["relations"]["ids"]:
            if rid not in known:
                raise SystemExit(f"{card['id']} related missing {rid}")
        for key in ("up", "rev"):
            tr, en, ru = card[key]
            if not (len(tr) == len(en) == len(ru) >= 1):
                raise SystemExit(f"{card['id']} {key} locale length mismatch")
        blob = "\n".join(_texts(card)).lower()
        for phrase in _FORBIDDEN:
            if phrase.lower() in blob:
                raise SystemExit(f"{card['id']} certainty phrase: {phrase}")
        if any(not s.strip() for s in _texts(card)):
            raise SystemExit(f"{card['id']} empty locale field")


def wands_mid():
    return [
        C("wands", 3, ("büyüme|ufuk|ilk meyve", "growth|horizon|first fruit", "рост|горизонт|первый плод"),
          ("sabırsızlık|dağılma|övünç", "impatience|scatter|boast", "нетерпение|рассев|похвальба"),
          ("İlk görünür büyüme; henüz hasat değil.", "First visible growth; not yet a harvest.", "Первый видимый рост; ещё не урожай."),
          ("Bağda küçük bir ilerleme hissedilebilir.", "A small advance in a bond may be felt.", "В связи может ощущаться малое продвижение."),
          ("Emeğin ilk işareti işte belirebilir.", "The first sign of effort may appear at work.", "На работе может явиться первый знак усилия."),
          ("Küçük bir kazanç umudu belirebilir; şişirme değildir.", "A small hope of gain may appear; it is not inflation.", "Может явиться малая надежда на прибыль; это не раздувание."),
          ("İçeride bu işliyor diyen sessiz bir ısı olabilir.", "A quiet heat that says this is working may live inside.", "Внутри может жить тихий жар, что это работает."),
          ("Büyüme, acele zafer hikâyesine kayabilir.", "Growth may slide into a hasty victory story.", "Рост может стать историей поспешной победы."),
          ("Ufka bak; henüz taç giyme.", "Look to the horizon; do not crown yourself yet.", "Смотри на горизонт; ещё не коронуй себя."),
          ("Olası iklim: görünür bir genişleme.", "A possible climate: a visible widening.", "Возможный климат: видимое расширение."),
          ["wands_01", "pentacles_03", "major_07"],
          ("As kıvılcım, Tılsım Üçlüsü zanaat, Savaş Arabası yön izidir.", "Ace is spark; Three of Pentacles craft; Chariot heading.", "Туз — искра; Тройка Пентаклей — ремесло; Колесница — курс.")),
        C("wands", 4, ("eşik kutlaması|kök|mola", "threshold feast|root|pause", "праздник порога|корень|пауза"),
          ("erken kutlama|dağılma|yerleşememe", "early feast|scatter|unsettled", "ранний праздник|рассев|неустроенность"),
          ("Ateşin ev eşiğinde durması; bir ara nefes.", "Fire pausing at a household threshold; an interval of breath.", "Огонь у порога дома; промежуток дыхания."),
          ("Bağda sakin bir paylaşım belirebilir.", "A calm sharing may appear in a bond.", "В связи может явиться спокойное разделение."),
          ("Bir aşamanın tanınması mümkün görünür.", "Recognition of a stage may be possible.", "Возможно признание этапа."),
          ("Kaynakları bir masada tutmak sakinleştirir; savurmak değil.", "Holding resources at one table steadies; scattering them does not.", "Держать средства за одним столом спокойнее, чем разбрасывать."),
          ("İçeride burada durabilirim hissi uyanabilir.", "An inner sense of I can rest here may stir.", "Внутри может проснуться чувство, что здесь можно стоять."),
          ("Mola, durağanlığa kayabilir.", "The pause may slide into stagnation.", "Пауза может стать застоем."),
          ("Kutla; henüz yol bitti deme.", "Mark the moment; do not say the road is finished.", "Отметь миг; не говори, что путь кончен."),
          ("Olası iklim: köklenen bir ara.", "A possible climate: a rooted interval.", "Возможный климат: укоренённый промежуток."),
          ["cups_04", "major_21", "pentacles_04"],
          ("Kupa Dördü durgunluk, Dünya tamamlanma, Tılsım Dördü tutma izidir.", "Four of Cups stillness; World completion; Four of Pentacles holding.", "Четвёрка Кубков — застой; Мир — завершение; Четвёрка Пентаклей — удержание.")),
    ]


def main() -> None:
    majors = MAJORS + MAJORS_REST + MAJORS_END
    wands = WANDS + wands_mid() + WANDS_REST
    cups = CUPS + CUPS_REST
    for name, cards, expect in [
        ("majors", majors, 22),
        ("wands", wands, 14),
        ("cups", cups, 14),
        ("swords", SWORDS, 14),
        ("pentacles", PENTACLES, 14),
    ]:
        if len(cards) != expect:
            raise SystemExit(f"{name} count {len(cards)} != {expect}")
        ids = [c["id"] for c in cards]
        if len(set(ids)) != len(ids):
            raise SystemExit(f"duplicate in {name}")

    all_cards = majors + wands + cups + SWORDS + PENTACLES
    known = {c["id"] for c in all_cards}
    if len(all_cards) != 78 or len(known) != 78:
        raise SystemExit(f"deck {len(all_cards)} unique {len(known)}")
    _assert_fields(all_cards, known)

    write_catalog("oracly_tarot_major_00_10.dart", "kOraclyTarotMajor00to10", majors[:11])
    write_catalog("oracly_tarot_major_11_21.dart", "kOraclyTarotMajor11to21", majors[11:])
    write_catalog("oracly_tarot_wands.dart", "kOraclyTarotWands", wands)
    write_catalog("oracly_tarot_cups.dart", "kOraclyTarotCups", cups)
    write_catalog("oracly_tarot_swords.dart", "kOraclyTarotSwords", SWORDS)
    write_catalog("oracly_tarot_pentacles.dart", "kOraclyTarotPentacles", PENTACLES)
    print("wrote 78 cards")


if __name__ == "__main__":
    main()
