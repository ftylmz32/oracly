# TAROT Phase 7G / 7G.1 — Golden Master Manifest

**Phase status:** PASS (7G.1 remediated Family B art)  
**Canonical viewport:** 390 × 844  
**DPR:** 1.0 (pixel masters) · compact DPR2 control also locked  
**Locale (pixel):** EN  
**Text scale (pixel):** 1.0  
**Comparator:** Flutter `matchesGoldenFile` (exact)  
**Auto-update in normal runs:** NEVER  
**Master directory:** `test/goldens/tarot/`  
**Font strategy:** `test/fonts/Roboto-*.ttf` → `TarotGoldenRoboto`  
**Asset strategy:** local `.webp` + `precacheImage` pre-warm  

## Update procedure (intentional only)

```bash
flutter test --update-goldens test/visual/tarot/tarot_golden_master_test.dart
flutter test --update-goldens test/visual/tarot/tarot_compact_face_test.dart
flutter test test/visual/tarot/
flutter test test/visual/tarot/
```

Never use `--update-goldens` to silence a regression.

## 7G.1 root cause (frozen)

At ~52×87 / DPR1, `TarotMajorCardArt(showChrome: true)` fixed plaques + full
`TarotCardShell` chrome mask scene art. Decode of preview thumbs is fine.

**Fix:** `TarotCardFaceDensity.compact` for settled overview (`RitualSpreadSlotTile`)
— art-dominant, no internal title plaques, proportional radius, restrained shell.
Flight / reveal / hero remain `full`. Geometry unchanged.

## Masters

| Filename | Surface | State | Viewport | DPR | Purpose | SHA-256 |
|---|---|---|---|---|---|---|
| `table_intention.png` | live table | intention | 390×844 | 1.0 | A1 | `1409543224876104b591ec57ad0437fbdb03e7905564b33c7b5389fdc7be3530` |
| `table_spread_picker.png` | live table | spread picker | 390×844 | 1.0 | A2 | `b33bc03cb189eecc456fdde77d5a00e2380e21f1c0286acd36f12ebb9078fa00` |
| `table_draw_ready_three.png` | live table | draw ready | 390×844 | 1.0 | A3 | `ce46edf028aba03c05ba96d6874dea019f42c59345df07b32937413c4ca6ca16` |
| `table_draw_ready_five.png` | live table | draw ready | 390×844 | 1.0 | A4 | `c98c0ff0db2c92e3043f0a47c41d1b1a4d673dc93a8f2b84f9ac4c6b76dfe293` |
| `ritual_three_one_settled.png` | ritual | 1 settled | 390×844 | 1.0 | B1 art | `267b5b8d626e99fc56270d641dcd5f68475f45cff917f3f9dc2f94c863b0923d` |
| `ritual_three_two_settled.png` | ritual | 2 settled | 390×844 | 1.0 | B2 art | `eb9c15de1826aa9829c0857d6dd922b3bdd513dea46a904651bbe6e7e327a0f7` |
| `ritual_five_partial.png` | ritual | 3 settled | 390×844 | 1.0 | B3 art | `49abec58061930c93862897f6c4b7aaef27e94913c8a84f09763969f91d7ec11` |
| `result_single_narrative.png` | result | Narrative | 390×844 | 1.0 | C1 | `e73ef6fb54cd43fbc8f275081ed79027e515279b1b0d41e32e6005540cb8d682` |
| `result_three_narrative.png` | result | Narrative | 390×844 | 1.0 | C2 | `3d4b45a7172bf8efdd141f2969b5d431d09683a6f4f8a0ef92c5c2557d457c06` |
| `result_five_narrative.png` | result | Narrative | 390×844 | 1.0 | C3 | `fa37792302ff54ef09c96bb50e0cc5f53ebc7cb3d561da630cb34afb37e73be3` |
| `result_long_narrative.png` | result | long | 390×844 | 1.0 | C4 | `21916df8de00d745d48e829c93edc8a419e906e02d3dab64ce79a127587ed93c` |
| `result_safety.png` | result | safety | 390×844 | 1.0 | C5 | `01208ec07c3cde118df4958809f0c7b325797ca2777188036b1dbe75aa83c09f` |
| `result_recovery.png` | result | recovery | 390×844 | 1.0 | C6 | `7cbc39ac0315e4203aa9f7f38228cf1207790916e80b6092616b49e73620be25` |
| `history_list_mixed.png` | history | list | 390×844 | 1.0 | D1 | `f2b8ef6442e6d28a24aad2885722865272e89e7301e14ab3d3bf21ac0c8617b3` |
| `history_detail_narrative.png` | history | Narrative | 390×844 | 1.0 | D2 | `591626df500732af543688335ad0b82eae2d8d73e2d09e726f68fc29be378d02` |
| `history_detail_crossroads.png` | history | Crossroads | 390×844 | 1.0 | D3 | `319f4ab0fdb638f7def9132b7d7a1ead9ecaa649266517bdee9a4d9b6555fe91` |
| `compact_major_upright_52.png` | compact | Major up | 52×87 | 1.0 | 7G.1 | `af63841bab688f3be6e66dcc83459e56e7f8a01c29c96504e17f0e16fc014421` |
| `compact_major_reversed_52.png` | compact | Major rev | 52×87 | 1.0 | 7G.1 | `8c200fc5e7003281c29403b69d1559cdf0e57a6b669b4647976102bf3d4df017` |
| `compact_minor_upright_52.png` | compact | Minor up | 52×87 | 1.0 | 7G.1 | `2fc5f41d48f2720933a884a70ed2af61aca2ba15bfda01a673076df22cef65b5` |
| `compact_major_upright_52_dpr2.png` | compact | Major up | 52×87 | 2.0 | 7G.1 | `8bf492fc123ed3fe300d582b227c667b526076637c777dbe70639c06b19d0086` |
| `firewall_ritual_face_90.png` | full | control | 90×150 | 1.0 | firewall | `e89d52a82af2da0653fb49f366f97a0b7569fdef7163581c86644f55b02d45bd` |
| `firewall_ritual_face_132.png` | full | hero | 132×222 | 1.0 | firewall | `1d9c0284da27df8ed087b3c09a61e0bdc0648e4ab80500d9ec4a640256489da5` |

**PNG count:** 22  
**Hash count:** 22  

## Hashes changed in 7G.1

Only Family B ritual masters + new compact/firewall component masters.
A/C/D phone goldens unchanged.
