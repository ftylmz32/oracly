# ORACLY Tarot Art Pipeline — OR-1310

Official production system for creating all 78 proprietary ORACLY Tarot cards.

**Status:** Production Ready  
**Parent Document:** OR-1300 Art Direction System (approved)  
**Constraint:** No third-party tarot artwork. No Rider-Waite references. No placeholder images in repo.

## Directory Map

| Folder | Purpose |
|--------|---------|
| [`art_direction/`](art_direction/) | Brand palette, identity manifest, **MASTER_STYLE**, OR-1300 summary |
| [`card_templates/`](card_templates/) | Master card template — layers, zones, finish |
| [`prompt_library/`](prompt_library/) | Variable prompt templates for illustration generation |
| [`style_rules/`](style_rules/) | Per-category visual rules (Major + 4 suits) |
| [`validators/`](validators/) | Acceptance checklist, brief schema, QA workflow |
| [`exports/`](exports/) | Resolution, naming, folder, compression rules |
| [`master_card/`](master_card/) | **OR-1320** DNA + **OR-1330** frame lock revision |
| [`art_direction/FLAGSHIP_TRIO.md`](art_direction/FLAGSHIP_TRIO.md) | **Flagship 00–02** — locked reference standard for entire deck |

## Quick Start

1. Pick card from [`card_registry.yaml`](card_registry.yaml)
2. Fill brief using [`validators/card_brief_schema.json`](validators/card_brief_schema.json)
3. Compose prompt from [`prompt_library/master_prompt.template.md`](prompt_library/master_prompt.template.md)
4. Apply category rules from [`style_rules/`](style_rules/)
5. Paint within [`card_templates/master_template.yaml`](card_templates/master_template.yaml)
6. Run [`validators/acceptance_checklist.yaml`](validators/acceptance_checklist.yaml)
7. Export per [`exports/export_spec.yaml`](exports/export_spec.yaml)

## Full Manual

See [`PRODUCTION_MANUAL.md`](PRODUCTION_MANUAL.md) for the complete end-to-end workflow.

## Master Card DNA

Every card is a variant of one blueprint: [`master_card/OR-1320_MASTER_CARD_SPEC.md`](master_card/OR-1320_MASTER_CARD_SPEC.md)

**Frame lock (v1.1):** [`master_card/OR-1330_FRAME_LOCK_REVISION.md`](master_card/OR-1330_FRAME_LOCK_REVISION.md)
