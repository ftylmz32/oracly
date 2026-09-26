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
| `final_hub_empty_390.png` | hub | empty | 390×844 | A1 entry without birth | `d959dfe58b325d4d3bfc48c2b8919f459b5e5329f010cbf820fa320f83a473d9` |
| `final_hub_with_birth_390.png` | hub | birth ready | 390×844 | A2 entry with birth | `848a96083095989f92f80cd46f9cc57a9a0ff0b9b02133c733079d491c582c5d` |
| `final_legacy_live_all_actions_390.png` | legacy live | durable + OR | 390×844 | B1 production actions | `c0b609ea9df081e71d94328c105266ca663eb0543fa6f6615d48588e5b5bc5e6` |
| `final_legacy_live_capture_failure_390.png` | legacy live | soft fail | 390×844 | B2 no Favorite | `2e3229e44388b4041e4b401fa9ebc43c2cb19563d784c93301df20ab81fda003` |
| `final_legacy_artifact_reopen_390.png` | legacy artifact | reopen | 390×844 | B3 historical + reopen | `1c7a8303b692ac1bceb1d046e35ffd0c7e87be4638e7ae0954027d3b3f472714` |
| `final_narrative_reduced_artifact_390.png` | narrative | REDUCED | 390×844 | C1 reduced artifact | `1649942aa3844459be87032ca75826420bb3d679c54a4d987c8fa4337f8182e3` |
| `final_narrative_reduced_continuity_390.png` | narrative | REDUCED + echo | 390×844 | C2 continuity | `80085dbaaa4d00ce362d2284c5dd222d66cd9b820e056b7905e8ca6bf52530cb` |
| `final_narrative_full_rich_390.png` | narrative | FULL rich | 390×844 | D1 primary master | `f58b793569b2a06bbfa494fdbdeead9791cef30c67b06dafaca512f6778c6314` |
| `final_narrative_full_rich_deeper_open_390.png` | narrative | FULL deeper open | 390×844 | D2 fact toggle | `f0fadce367063ea85d74bec21e5022db00f0c0496ea678db267432ed4de30fde` |
| `final_narrative_full_continuity_390.png` | narrative | FULL + echo | 390×844 | D3 continuity + historical | `9adc33a5c742e67f3e12052cf6fbcc93dcae3eeb36a83359cec90c0a11b04687` |
| `final_narrative_live_ready_390.png` | narrativeLive | live-ready | 390×844 | E1 live presentation | `407c0f136a0d31e28c56f2f666db0d48771c6ea7497429d05077b7a4c3222554` |
| `final_narrative_artifact_same_evidence_390.png` | narrativeArtifact | same evidence | 390×844 | E2 artifact + history | `6eb16289347db998326c7a67f6555f27fe4cf5a140b74dca1f13c06946546694` |
| `final_narrative_full_en_chrome_390.png` | narrative | TR prose / EN chrome | 390×844 | F1 locale control | `d40b7eb8b17ed2d3130ad4d513a9a62c1d2ee9207ccefba3ec4078557d62df01` |
| `final_narrative_full_ru_chrome_390.png` | narrative | TR prose / RU chrome | 390×844 | F2 locale control | `235c141fe24066828846dd6b4a9fb94daaa1edf72e278c54a42d3e38a42ffeca` |
| `final_full_compact_320x568.png` | narrative | FULL | 320×568 | G1 compact | `fa88dae1d0cffb625f6410f388962f6acf2ba0d3bcc9e6f2328e16c6164ea88c` |
| `final_full_textscale20_360x800.png` | narrative | FULL ts2.0 | 360×800 | G2 textScale | `9b5ed3e98b8b0bb3dbfdef4906fb67f0c727467c04b022af8508f687242a9b49` |
| `final_full_tablet_768x1024.png` | narrative | FULL | 768×1024 | G3 tablet | `79a689ba4d6ad4812587c942c06331b8bb2f2c1a72ed688a05b8288a38854489` |

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
