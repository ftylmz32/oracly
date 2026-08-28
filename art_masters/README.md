# ORACLY art masters (not shipped)

High-quality sources for the photorealistic image pipeline.

- **Runtime app assets:** `lib/assets/images/`
- **Pipeline docs:** `docs/PHOTOREALISTIC_IMAGE_ASSET_PIPELINE.md`
- **Art standard:** `docs/PHOTOREALISTIC_ART_STANDARD.md`

Place masters as: `art_masters/<feature>/<slug>.png`

Then:

```bash
python tool/oracly_image_pipeline/optimize_asset.py \
  --in art_masters/<feature>/<slug>.png \
  --out lib/assets/images/<path>/<slug>.webp \
  --role hero_tall
```

This folder is gitignored except this README — do not commit multi‑MB masters unless intentionally archived.
