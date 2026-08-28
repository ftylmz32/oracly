# ORACLY Brand Mark

Canonical logo: approved ceremonial emblem — **gold crescent · oracle profile silhouette · central star** (`oracly_logo.png`).

**Not:** crystal-obelisk temporary mark · circular orbit/vesica mark · crystal ball · eye · magic wand · Material sparkle · wordmark baked into icon.

Legacy `oracly_mark_*.png` files were removed from `lib/assets/brand/` — never ship or wire them as identity.

## Sources

| Asset | Path |
|-------|------|
| Official master | `assets/brand/oracly_launcher_source.png` |
| Runtime logo | `lib/assets/brand/oracly_logo.png` |
| Pre-luminous backup | `art_masters/brand/oracly_launcher_source_pre_luminous.png` |
| Widget | `lib/core/brand/oracly_brand_mark.dart` → `OraclyBrandMark` |
| Wordmark | `lib/core/brand/oracly_wordmark.dart` |
| Launcher config | `flutter_launcher_icons.yaml` |
| Refine script | `tool/oracly_brand/refine_logo_luminous.py` |

## System

- **Icon / splash / header / brand moments** → `OraclyBrandMark` (official asset, `BoxFit.contain`)
- **Do not redraw** a competing logo in painters (splash may use procedural *prelude* only)
- **Preserve** aspect ratio and resolution (decode cache only; never stretch)
- **Feature discovery** → photoreal `home_*.webp` portals (not a second glyph pack)
- **Nav** → quiet Material strokes on the same midnight/gold palette

## Regenerate launcher icons

```bash
dart run flutter_launcher_icons
```
