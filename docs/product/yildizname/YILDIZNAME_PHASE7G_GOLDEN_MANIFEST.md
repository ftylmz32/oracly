# Yıldızname Phase 7G — Final Production Golden Manifest

**Phase status:** PASS / FROZEN  
**Start HEAD:** `1ecc3445c0a2e7a47ae0936dd8c9d8a66c1b74f1`  
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
| `final_hub_empty_390.png` | hub | empty | 390×844 | A1 entry without birth | `d959dfe58b325d4d3bfc48c2b8919f459b5e5329f010cbf820fa320f83a473d9` |
| `final_hub_with_birth_390.png` | hub | birth ready | 390×844 | A2 entry with birth | `848a96083095989f92f80cd46f9cc57a9a0ff0b9b02133c733079d491c582c5d` |
| `final_legacy_live_all_actions_390.png` | legacy live | durable + OR | 390×844 | B1 production actions | `c0b609ea9df081e71d94328c105266ca663eb0543fa6f6615d48588e5b5bc5e6` |
| `final_legacy_live_capture_failure_390.png` | legacy live | soft fail | 390×844 | B2 no Favorite | `2e3229e44388b4041e4b401fa9ebc43c2cb19563d784c93301df20ab81fda003` |
| `final_legacy_artifact_reopen_390.png` | legacy artifact | reopen | 390×844 | B3 typed reopen | `c0b609ea9df081e71d94328c105266ca663eb0543fa6f6615d48588e5b5bc5e6` |
| `final_narrative_reduced_artifact_390.png` | narrative | REDUCED | 390×844 | C1 reduced artifact | `1d35e5125167751ae3990a02720e898a9a7c05adefa2525442954390dda48804` |
| `final_narrative_reduced_continuity_390.png` | narrative | REDUCED + echo | 390×844 | C2 continuity | `bf42f4ae9a1b617ff8efa8bb9e6b81f0e93a6634bd0bb0a4c3254b8df6ede069` |
| `final_narrative_full_rich_390.png` | narrative | FULL rich | 390×844 | D1 primary master | `407c0f136a0d31e28c56f2f666db0d48771c6ea7497429d05077b7a4c3222554` |
| `final_narrative_full_rich_deeper_open_390.png` | narrative | FULL deeper open | 390×844 | D2 fact toggle | `d9b34d145c130167c4ed96c6b828def00b240c8dd1f103d0aafae59d066bbe26` |
| `final_narrative_full_continuity_390.png` | narrative | FULL + echo | 390×844 | D3 continuity reveal | `b98dce34eb70ca60360fdc17a9f4a0294eaf4ba5be376a885ca99205c52746ef` |
| `final_narrative_live_ready_390.png` | narrativeLive | live-ready | 390×844 | E1 live presentation | `407c0f136a0d31e28c56f2f666db0d48771c6ea7497429d05077b7a4c3222554` |
| `final_narrative_artifact_same_evidence_390.png` | narrativeArtifact | same evidence | 390×844 | E2 artifact parity | `407c0f136a0d31e28c56f2f666db0d48771c6ea7497429d05077b7a4c3222554` |
| `final_narrative_full_en_chrome_390.png` | narrative | TR prose / EN chrome | 390×844 | F1 locale control | `2d7858b4b3052be137d9cbbd3d3d3b8ebfb21dd4e901e7bb1251bde0b9c659d2` |
| `final_narrative_full_ru_chrome_390.png` | narrative | TR prose / RU chrome | 390×844 | F2 locale control | `c007c7e165c41fc12fcabbab307b8cdb16cea06e6416daec04afb0e1be1e7918` |
| `final_full_compact_320x568.png` | narrative | FULL | 320×568 | G1 compact | `f952aaf27fe5cb90c8c3003b441b95d5ecf19b86491812fdc333173cb56acdbc` |
| `final_full_textscale20_360x800.png` | narrative | FULL ts2.0 | 360×800 | G2 textScale | `f43d2510f1880e7658de4f5cafc2c86bd0d8021c5190204fcd333748a09a6432` |
| `final_full_tablet_768x1024.png` | narrative | FULL | 768×1024 | G3 tablet | `62beabe7442f48739a6e172d3351946e690c749e2e4b984d7a3d17d215d1274c` |

**PNG count:** 17  
**Hash count:** 17  

## Intentionally identical-hash pairs

| Pair | SHA-256 | Reason |
|---|---|---|
| `final_narrative_full_rich_390` ≡ `final_narrative_live_ready_390` ≡ `final_narrative_artifact_same_evidence_390` | `407c0f13…2554` | Same request/result evidence; live vs artifact UI does not visually distinguish |
| `final_legacy_live_all_actions_390` ≡ `final_legacy_artifact_reopen_390` | `c0b609ea…c5e6` | Durable legacy live and typed reopen share the same above-fold chrome + actions |

## Distinctness checks

- FULL rich ≠ REDUCED artifact  
- REDUCED ≠ LEGACY  
- TR / EN / RU chrome masters differ  
- Stored TR prose remains unchanged across F1/F2  

## Test inventory

- `yildizname_phase7g_golden_master_test.dart` — A/B/C  
- `yildizname_phase7g_golden_master_b_test.dart` — D/E  
- `yildizname_phase7g_golden_master_c_test.dart` — F/G  
- `yildizname_phase7g_golden_hash_test.dart` — inventory + SHA-256 + negative byte-flip  
- `yildizname_phase7g_firewall_test.dart` — no forensic bypass APIs  
