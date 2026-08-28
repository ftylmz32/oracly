"""Emit ORACLY 78-card Dart catalogues. Run from repo root: python tool/generate_oracly_tarot_deck.py"""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "lib" / "features" / "tarot" / "deck" / "catalog"

MAJOR_FILES = [
    "00_fool.webp",
    "01_magician.webp",
    "02_high_priestess.webp",
    "03_empress.webp",
    "04_emperor.webp",
    "05_hierophant.webp",
    "06_lovers.webp",
    "07_chariot.webp",
    "08_strength.webp",
    "09_hermit.webp",
    "10_wheel.webp",
    "11_justice.webp",
    "12_hanged_man.webp",
    "13_death.webp",
    "14_temperance.webp",
    "15_devil.webp",
    "16_tower.webp",
    "17_star.webp",
    "18_moon.webp",
    "19_sun.webp",
    "20_judgement.webp",
    "21_world.webp",
]

MINOR_STEM = {
    1: "01_ace",
    2: "02_two",
    3: "03_three",
    4: "04_four",
    5: "05_five",
    6: "06_six",
    7: "07_seven",
    8: "08_eight",
    9: "09_nine",
    10: "10_ten",
    11: "11_page",
    12: "12_knight",
    13: "13_queen",
    14: "14_king",
}

RANK_TR = {
    1: "Ası",
    2: "İkilisi",
    3: "Üçlüsü",
    4: "Dörtlüsü",
    5: "Beşlisi",
    6: "Altılısı",
    7: "Yedilisi",
    8: "Sekizlisi",
    9: "Dokuzlusu",
    10: "Onlusu",
    11: "Habercisi",
    12: "Şövalyesi",
    13: "Kraliçesi",
    14: "Kralı",
}
RANK_EN = {
    1: "Ace",
    2: "Two",
    3: "Three",
    4: "Four",
    5: "Five",
    6: "Six",
    7: "Seven",
    8: "Eight",
    9: "Nine",
    10: "Ten",
    11: "Page",
    12: "Knight",
    13: "Queen",
    14: "King",
}
RANK_RU = {
    1: "Туз",
    2: "Двойка",
    3: "Тройка",
    4: "Четвёрка",
    5: "Пятёрка",
    6: "Шестёрка",
    7: "Семёрка",
    8: "Восьмёрка",
    9: "Девятка",
    10: "Десятка",
    11: "Паж",
    12: "Рыцарь",
    13: "Королева",
    14: "Король",
}

SUIT_TR = {"wands": "Değnek", "cups": "Kupa", "swords": "Kılıç", "pentacles": "Tılsım"}
SUIT_EN = {"wands": "Wands", "cups": "Cups", "swords": "Swords", "pentacles": "Pentacles"}
SUIT_RU = {"wands": "Жезлов", "cups": "Кубков", "swords": "Мечей", "pentacles": "Пентаклей"}

HEADER = """/// ORACLY Tarot catalogue — structured meanings, TR/EN/RU. No UI.
library;

import '../../../../core/l10n/l10n_triple.dart';
import '../oracly_tarot_card.dart';
import '../oracly_tarot_enums.dart';
import '../oracly_tarot_keywords.dart';
import '../oracly_tarot_meanings.dart';
import '../oracly_tarot_relations.dart';
"""


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def l10n(tr: str, en: str, ru: str) -> str:
    return f"L10nTriple('{esc(tr)}', '{esc(en)}', '{esc(ru)}')"


def keywords(tr: list[str], en: list[str], ru: list[str]) -> str:
    def lst(xs: list[str]) -> str:
        return ", ".join(f"'{esc(x)}'" for x in xs)

    return (
        "OraclyTarotKeywords(\n"
        f"      tr: [{lst(tr)}],\n"
        f"      en: [{lst(en)}],\n"
        f"      ru: [{lst(ru)}],\n"
        "    )"
    )


def emit_card(c: dict) -> str:
    m = c["meanings"]
    rel = c["relations"]
    return f"""  OraclyTarotCard(
    id: '{c["id"]}',
    number: {c["number"]},
    arcana: OraclyTarotArcana.{c["arcana"]},
    suit: OraclyTarotSuit.{c["suit"]},
    name: {l10n(*c["name"])},
    uprightKeywords: {keywords(*c["up"])},
    reversedKeywords: {keywords(*c["rev"])},
    meanings: OraclyTarotMeanings(
      symbolicMeaning: {l10n(*m["symbolic"])},
      loveMeaning: {l10n(*m["love"])},
      careerMeaning: {l10n(*m["career"])},
      moneyMeaning: {l10n(*m["money"])},
      personalMeaning: {l10n(*m["personal"])},
      challengeMeaning: {l10n(*m["challenge"])},
      guidanceMeaning: {l10n(*m["guidance"])},
      futureDirectionMeaning: {l10n(*m["future"])},
    ),
    relationshipWithOtherCards: OraclyTarotRelations(
      relatedIds: [{", ".join(f"'{x}'" for x in rel["ids"])}],
      note: {l10n(*rel["note"])},
    ),
    visualAsset: '{c["visual"]}',
    cardBackAsset: 'assets/tarot/card_back/oracly_tarot_back_portrait.svg',
  )"""


def write_catalog(name: str, list_name: str, cards: list[dict]) -> None:
    body = ",\n".join(emit_card(c) for c in cards)
    text = (
        f"{HEADER}\n"
        f"const {list_name} = <OraclyTarotCard>[\n"
        f"{body},\n"
        "];\n"
    )
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / name).write_text(text, encoding="utf-8")
