"""Minor Arcana seeds — unique fields per card, observational tone."""

from oracly_tarot_emit import MINOR_STEM, RANK_EN, RANK_RU, RANK_TR, SUIT_EN, SUIT_RU, SUIT_TR


def minor(suit: str, n: int, up, rev, meanings, rel_ids, rel_note):
    return {
        "id": f"{suit}_{n:02d}",
        "number": n,
        "arcana": "minor",
        "suit": suit,
        "name": (
            f"{SUIT_TR[suit]} {RANK_TR[n]}",
            f"{RANK_EN[n]} of {SUIT_EN[suit]}",
            f"{RANK_RU[n]} {SUIT_RU[suit]}",
        ),
        "up": up,
        "rev": rev,
        "meanings": meanings,
        "relations": {"ids": rel_ids, "note": rel_note},
        "visual": f"assets/tarot/cards/{suit}/{MINOR_STEM[n]}.webp",
    }


def _mean(symbolic, love, career, money, personal, challenge, guidance, future):
    return {
        "symbolic": symbolic,
        "love": love,
        "career": career,
        "money": money,
        "personal": personal,
        "challenge": challenge,
        "guidance": guidance,
        "future": future,
    }


def K(tr, en, ru):
    return (tr.split("|"), en.split("|"), ru.split("|"))


def C(suit, n, up, rev, s, l, c, m, p, h, g, f, rel, note):
    return minor(
        suit,
        n,
        K(*up),
        K(*rev),
        _mean(s, l, c, m, p, h, g, f),
        rel,
        note,
    )
