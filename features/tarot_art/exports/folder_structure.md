# ORACLY Tarot — Delivery Folder Structure

## Staging (Pre-Integration)

```
exports/delivery/
└── batch_20260805/
    ├── oracly_tarot_back/
    │   ├── oracly_tarot_back.webp
    │   ├── oracly_tarot_back@2x.webp
    │   ├── oracly_tarot_back_thumb.webp
    │   └── manifest.json
    ├── oracly_tarot_major_00/
    │   ├── oracly_tarot_major_00.webp
    │   ├── oracly_tarot_major_00@2x.webp
    │   ├── oracly_tarot_major_00_thumb.webp
    │   ├── oracly_tarot_major_00_shimmer.webp   # optional legendary
    │   └── manifest.json
    └── BATCH_MANIFEST.json
```

## App Integration Path

```
lib/assets/images/cards/tarot/oracly/
├── oracly_tarot_back.webp
├── major/
│   ├── oracly_tarot_major_00.webp
│   └── … (22 files)
├── cups/
│   ├── oracly_tarot_cups_01.webp
│   └── … (14 files)
├── wands/
├── swords/
└── pentacles/
```

**Note:** Flat or suit-subfolder layout is an engineering choice. Naming convention is invariant.

## manifest.json (Per Card)

```json
{
  "card_id": "oracly_tarot_major_17",
  "card_name": "The Star",
  "filename": "oracly_tarot_major_17.webp",
  "width": 512,
  "height": 896,
  "format": "webp",
  "sha256": "<hash>",
  "exported_at": "2026-08-05T14:30:00Z",
  "validator_version": "1.0",
  "qa_report_ref": "briefs/oracly_tarot_major_17/qa_report.yaml",
  "pipeline": "OR-1310"
}
```

## BATCH_MANIFEST.json

```json
{
  "batch_id": "batch_20260805",
  "card_count": 3,
  "cards": ["oracly_tarot_back", "oracly_tarot_major_00", "oracly_tarot_major_01"],
  "art_director_signoff": "Name",
  "exported_at": "2026-08-05T16:00:00Z"
}
```

## Git Policy

| Path | Tracked |
|------|---------|
| `features/tarot_art/` specs | ✅ Yes |
| `exports/delivery/` | ❌ No (gitignore) |
| `briefs/` | ❌ No (gitignore) |
| `lib/assets/.../oracly/*.webp` | ✅ Yes (after approved batch) |

## .gitignore Recommendations

```
features/tarot_art/briefs/
features/tarot_art/exports/delivery/
```
