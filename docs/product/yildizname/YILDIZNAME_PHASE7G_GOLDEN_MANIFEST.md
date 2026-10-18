# Yıldızname Phase 7G — Final Production Golden Manifest

**Phase status:** PASS / FROZEN (remediated by Phase 7G.1)  
**Start HEAD (7G capture):** `1ecc3445c0a2e7a47ae0936dd8c9d8a66c1b74f1`  
**7G.1 remediation HEAD base:** `82b4ce43da49711fa10a2fb8180a2547ffb8e982`  
**Canonical viewport:** 390 × 844  
**DPR:** 1.0  
**Pixel locale:** TR  
**Text scale (canonical):** 1.0  
**Comparator:** Flutter `matchesGoldenFile` (exact)  
**Auto-update in normal runs:** NEVER  
**Master directory:** `test/goldens/yildizname/phase7g/`  
**Font strategy:** `test/fonts/Roboto-*.ttf` → `YildiznameGoldenRoboto`  
**Atmosphere:** `AppAssets.yildiznameArchiveBg` + `yildiznameHero` precached before capture  
**Historical inventories:** Phase 7A root + phase7b–phase7f untouched  

## Historical artifact UI (7G.1)

Artifact reopen masters intentionally differ from live:

- Source rule: `legacyArtifact` / `narrativeArtifact` only
- Live with durable artifact id/time does **not** show historical chrome
- Display: `Kayıtlı yorum · <dateCompact(createdAtUtc)>` (TR/EN/RU)

## Update procedure (intentional only)

```bash
flutter test --update-goldens test/visual/yildizname/yildizname_phase7g_golden_master_test.dart
flutter test --update-goldens test/visual/yildizname/yildizname_phase7g_golden_master_b_test.dart
flutter test --update-goldens test/visual/yildizname/yildizname_phase7g_golden_master_c_test.dart
flutter test test/visual/yildizname/yildizname_phase7g_golden_master_test.dart test/visual/yildizname/yildizname_phase7g_golden_master_b_test.dart test/visual/yildizname/yildizname_phase7g_golden_master_c_test.dart
flutter test test/visual/yildizname/yildizname_phase7g_golden_master_test.dart test/visual/yildizname/yildizname_phase7g_golden_master_b_test.dart test/visual/yildizname/yildizname_phase7g_golden_master_c_test.dart
```

Never use `--update-goldens` to silence a regression. Normal CI never passes `--update-goldens`.

## Masters

| Filename | Surface | State | Viewport | Purpose | SHA-256 |
|---|---|---|---|---|---|
| `final_hub_empty_390.png` | hub | empty | 390×844 | A1 entry without birth | `0827c91d735181b47fffd3d860f7aefe433b9cba73f4adb24ab4f99b1b0cb1e3` |
| `final_hub_with_birth_390.png` | hub | birth ready | 390×844 | A2 entry with birth | `0d0318f21cb4e48945f7023fe3160d205698bf02259aadccbd6a15232aff34c5` |
| `final_legacy_live_all_actions_390.png` | legacy live | durable + OR | 390×844 | B1 production actions | `8c81f7b7a7c2d2900b2882f91035aa1807b00a55b10d4bbbe2a8189cc5de1d3b` |
| `final_legacy_live_capture_failure_390.png` | legacy live | soft fail | 390×844 | B2 no Favorite | `f0d7d2d20ab9404f5095382ced5c43a052d20437b9f20cd00ea19c7ec2a25289` |
| `final_legacy_artifact_reopen_390.png` | legacy artifact | reopen | 390×844 | B3 historical + reopen | `9b6743aa2bbdd35350d9e0e662d029e24b96eecb6412856ffedf553d0ad345a3` |
| `final_narrative_reduced_artifact_390.png` | narrative | REDUCED | 390×844 | C1 reduced artifact | `b32b9bc2ed1316937d08cccb40b37e740749d312486bd5aaf5010f96dfee5536` |
| `final_narrative_reduced_continuity_390.png` | narrative | REDUCED + echo | 390×844 | C2 continuity | `268320ae3b47abe665493555db5db8bc00a7fa1491fde3e5ad5d6cca4102cd15` |
| `final_narrative_full_rich_390.png` | narrative | FULL rich | 390×844 | D1 primary master | `082808b80a1f99383bf1fb9e881dbc0c90cacefee0359d399865ff1f777ac56d` |
| `final_narrative_full_rich_deeper_open_390.png` | narrative | FULL deeper open | 390×844 | D2 fact toggle | `b422c8e4490fa2a448bcbad0e838a5ec1295b26bb06c0fcaf42e314f176dbbc8` |
| `final_narrative_full_continuity_390.png` | narrative | FULL + echo | 390×844 | D3 continuity + historical | `f74e7033ecd7aca82bc3527954ba9c78fca13a39b100a79b62db50a3570a36c8` |
| `final_narrative_live_ready_390.png` | narrativeLive | live-ready | 390×844 | E1 live presentation | `73602f7d7c26f22308244286391337eefb2ca231f76f02b9062cdc4c2136740f` |
| `final_narrative_artifact_same_evidence_390.png` | narrativeArtifact | same evidence | 390×844 | E2 artifact + history | `dec761a5194e4479bfa1422ef47522b331cb627900d5451f23d18be03dec5b90` |
| `final_narrative_full_en_chrome_390.png` | narrative | TR prose / EN chrome | 390×844 | F1 locale control | `b2ea5ed0d72a5f9138efcc65168d6706383e717d9dc11e525c810a439ed95ba4` |
| `final_narrative_full_ru_chrome_390.png` | narrative | TR prose / RU chrome | 390×844 | F2 locale control | `141e095f49e2a9f3ad6e237ce2ca652c8d2d2bf5a341c40a66c50b28eb28cb5c` |
| `final_full_compact_320x568.png` | narrative | FULL | 320×568 | G1 compact | `4e7bcc3aeb030673bacb01a4ca424471b759e5896c59d787776fc0a68391d58a` |
| `final_full_textscale20_360x800.png` | narrative | FULL ts2.0 | 360×800 | G2 textScale | `f4d7761639b7f084a9a081232965c95e5eb731755a2a740a1dc0467e680c9ff1` |
| `final_full_tablet_768x1024.png` | narrative | FULL | 768×1024 | G3 tablet | `de53ac23652092404b1ad5ed45ce53d0060b5c6215aa3152766c140413ed354b` |

**PNG count:** 17  
**Hash count:** 17  

## Intentionally identical-hash pairs

None after Phase 7G.1. Live and artifact reopen hashes intentionally differ.

## Distinctness checks

- FULL rich ≠ REDUCED artifact  
- REDUCED ≠ LEGACY  
- B1 legacy live ≠ B3 legacy artifact  
- E1 narrative live ≠ E2 narrative artifact  
- TR / EN / RU chrome masters differ  
- Stored TR prose remains unchanged across F1/F2  

## Test inventory

- `yildizname_phase7g_golden_master_test.dart` — A/B/C  
- `yildizname_phase7g_golden_master_b_test.dart` — D/E  
- `yildizname_phase7g_golden_master_c_test.dart` — F/G  
- `yildizname_phase7g_golden_hash_test.dart` — exact filename→SHA-256 + negative controls  
- `yildizname_phase7g_firewall_test.dart` — no forensic bypass APIs

## P4E.4 shared-component delta

P4E.4 intentional post-freeze shared-component visual delta: SaveFavoriteMomentLink production layout changed Row → Wrap during P4C for responsive/large-text behavior.

Historical 7A–7F forensic masters remain unchanged.

Only these two final-production masters were refreshed:

- `final_legacy_live_all_actions_390.png` `c0b609ea9df081e71d94328c105266ca663eb0543fa6f6615d48588e5b5bc5e6` → `3094e678edcc230ae92a408479b4a2a708891d2c5f72015b65b2874ff64fae7f`
- `final_legacy_artifact_reopen_390.png` `1c7a8303b692ac1bceb1d046e35ffd0c7e87be4638e7ae0954027d3b3f472714` → `00515a7479423275e295b40bfcc4822ffd62c34b24106b211e1e504679624ebb`
