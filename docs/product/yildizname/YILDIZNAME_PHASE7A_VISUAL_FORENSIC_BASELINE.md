# YILDIZNAME Phase 7A — Visual Forensic Baseline

**Status:** PASS candidate  
**Branch:** `fix/final-product-remediation-20260922`  
**START HEAD:** `3fe41e75e2e61eccf66687b1a7f84a3b6ef6a9a3`  
**Production UI change:** 0  
**Real provider calls:** 0

Contracts: `YILDIZNAME_PHASE7_VISUAL_CONTRACT.md` · `YILDIZNAME_PHASE7_RESULT_ARCHITECTURE.md`

---

## 1 — Purpose

Audit current Yıldızname visuals; freeze result architecture; create deterministic golden harness — **without** redesigning live UI.

---

## 2 — Surface inventory

| Surface | Path | Class |
|---------|------|-------|
| Hub | `StarMapReferenceScreen` | CANONICAL |
| Hub chart | `StarMapReferenceChart` | CANONICAL (hub-only) |
| Result | `StarMapReferenceResultScreen` | CANONICAL |
| Artifact reopen | `StarMapArtifactReopenScreen` | CANONICAL |
| Presentation adapter | `YildiznameArtifactPresentation` | CANONICAL (title debt) |
| Legacy leaf open | `StarMapResultOpen` | CANONICAL today |
| Birth subjourney | `BirthChartScreen` | CANONICAL sibling |
| Favorite / Journal open | `favorite_moment_star_map_open` / `discovery_journal_star_map_open` | CANONICAL |
| Loading cinema | `StarMapLoadingCinema` | DEAD (unused) |
| Error state | `StarMapErrorState` | DEAD (unused) |
| Intro / Journey / Story leftovers | `StarMapReferenceIntro` etc. | DEAD / LEGACY |

No parallel result screen.

---

## 3 — Visual DNA (current)

Tokens: `archiveInk` `#07040F` · `violetSky` · `candleAmber` · `brassGlow`  
Assets: `AppAssets.yildiznameHero` · `yildiznameArchiveBg`  
Atmosphere: cosmic BG + chamber veil + dark-only archive plate  
Result body: `ChamberNarrativeBlock` / `ChamberReadingLane` (not GlassCard)

Light mode: reduced atmosphere (skips archive BG overlays) — not a second brand.

---

## 4 — Current blockers (document only)

| ID | Finding |
|----|---------|
| B1 | Narrative titles leak `summary` / enum `.name` / `reflection` / `closing` |
| B2 | Scope/fidelity stored on artifact but never disclosed on result UI |
| B3 | Flat section stack — summary not visually distinct beyond first-hero |
| B4 | No artifact “Kayıtlı yorum” status chrome |
| B5 | Footer: share → OR → favorite (target OR → share → favorite) |
| B6 | Hub status binary only — no reduced/full readiness |
| B7 | Loading/error cinema unused |
| B8 | Dense chapter potential (10 kinds + summary/reflection/closing) |

---

## 5 — Scope data availability

Artifact top-level `scope` / `fidelity` + payload `request` / `result` snapshots exist.  
**Schema change not required.** Presentation adapter must surface them in 7B.

---

## 6 — Golden harness

| Item | Path |
|------|------|
| Visual harness | `test/visual/yildizname/yildizname_visual_harness.dart` |
| Fixtures | `test/visual/yildizname/yildizname_visual_fixtures.dart` |
| Golden harness | `test/visual/yildizname/yildizname_golden_harness.dart` |
| Baseline tests | `yildizname_visual_baseline_test.dart` |
| Structural | `yildizname_golden_structural_test.dart` |
| Masters | `yildizname_golden_master_test.dart` |
| Hash / negative | `yildizname_golden_hash_test.dart` |
| PNG masters | `test/goldens/yildizname/` |

Canonical viewport: **390×844** · DPR 1.0 · settled pumps · Roboto golden font  
Settle: short pumps only — no open-ended ambient.  
Provider: 0 · Astronomy for narrative goldens: fixture request/result only.

### Baseline masters

| Filename | Surface |
|----------|---------|
| `hub_empty_390` | Hub without birth |
| `hub_with_birth_390` | Hub with saved birth |
| `legacy_result_390` | Legacy leaf-style result |
| `artifact_legacy_reopen_390` | Legacy artifact reopen |
| `artifact_narrative_reduced_current_390` | Current Narrative reduced presentation |
| `artifact_narrative_full_current_390` | Current Narrative full presentation |
| `firewall_result_chrome_control_390` | Negative-control twin (same chrome path) |

### SHA-256 inventory

Filled after `--update-goldens` by hash test parity. See table below.

| Filename | SHA-256 |
|----------|---------|
| hub_empty_390.png | `9b06b29755caca3d76f29132f0870c8dc2942655488813eb5aaf5f75633f6e80` |
| hub_with_birth_390.png | `848a96083095989f92f80cd46f9cc57a9a0ff0b9b02133c733079d491c582c5d` |
| legacy_result_390.png | `5c3663faac8820fc091d828a5b1909a8823feaacf3d67a6209c96045f55092d5` |
| artifact_legacy_reopen_390.png | `fccf7a8344fcb8463252aca8caa9ab6e6701609e1678c8c37af8db89af09096a` |
| artifact_narrative_reduced_current_390.png | `cd414771c47f12ccc937c1e20e727d0436a5f5ace16d36fe22edfbbb22138444` |
| artifact_narrative_full_current_390.png | `2e04c4a38ba55b844e61c91dd585363456e94479ae5cdd740ef31b83432c27b2` |
| firewall_result_chrome_control_390.png | `5c3663faac8820fc091d828a5b1909a8823feaacf3d67a6209c96045f55092d5` |

Note: `firewall_result_chrome_control_390` intentionally matches `legacy_result_390` (same chrome path) — negative control for silent chrome rewrites.

---

## 7 — Negative control

`firewall_result_chrome_control_390` locks the current result chrome path.  
Hash test also proves a deliberate byte flip fails parity without updating masters.

---

## 8 — Phase 7 plan

7A baseline → 7B disclosure/titles → 7C facts → 7D chapters/memory → 7E parity/footer → 7F a11y → 7G masters → 7H freeze

---

## 9 — Pass criteria checklist

- [x] Surfaces mapped  
- [x] Canonical result owner frozen  
- [x] Hierarchy / scope / live-artifact / facts / memory frozen in docs  
- [x] Blockers documented  
- [x] Harness + fixtures + goldens + hash + negative control  
- [x] Production UI untouched  
- [x] Firewalls / analyze / full flutter (gate run)
