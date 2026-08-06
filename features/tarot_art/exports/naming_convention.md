# ORACLY Tarot — Asset Naming Convention

## Pattern

```
{card_id}.{ext}
```

`card_id` comes **exactly** from `card_registry.yaml` — never invent alternate names.

## Card ID Format

| Type | Pattern | Example |
|------|---------|---------|
| Major | `oracly_tarot_major_{NN}` | `oracly_tarot_major_17` |
| Cups | `oracly_tarot_cups_{RR}` | `oracly_tarot_cups_03` |
| Wands | `oracly_tarot_wands_{RR}` | `oracly_tarot_wands_14` |
| Swords | `oracly_tarot_swords_{RR}` | `oracly_tarot_swords_01` |
| Pentacles | `oracly_tarot_pentacles_{RR}` | `oracly_tarot_pentacles_11` |
| Back | `oracly_tarot_back` | `oracly_tarot_back` |

## Rank Encoding (Minors)

| Rank | ID suffix |
|------|-------------|
| Ace | `01` |
| 2–10 | `02`–`10` |
| Page | `11` |
| Knight | `12` |
| Queen | `13` |
| King | `14` |

## Major Numeral Mapping

| Card | ID suffix |
|------|-----------|
| Fool | `00` |
| Magician | `01` |
| … | … |
| World | `21` |

## File Extensions

| Suffix | Purpose |
|--------|---------|
| `.webp` | Production (app) |
| `@2x.webp` | High-DPI optional |
| `_thumb.webp` | 256×448 preview |
| `_shimmer.webp` | Legendary UI channel (optional) |

## Display Name vs File Name

- **File:** `oracly_tarot_major_17.webp`
- **Display:** `The Star` (in card art nameplate + app UI)
- Never encode display name in filename (Turkish/Unicode safe)

## Forbidden

- `TheStar.png`, `major-17-star.webp`, `17-TheStar.png` (legacy paths — deprecated)
- Spaces, uppercase filenames, Rider-Waite naming patterns
