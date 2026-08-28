"""Build all 56 minors from unique per-rank copy."""

from oracly_tarot_minors_base import _mean, minor

# Each rank: up, rev, 8 meaning triples, rel_ids, rel_note
# Meanings order: symbolic love career money personal challenge guidance future


def _pack(suit, rows):
    return [minor(suit, n, *row) for n, row in enumerate(rows, start=1)]


def _r(up, rev, meanings, rel, note):
    return (up, rev, _mean(*meanings), rel, note)
