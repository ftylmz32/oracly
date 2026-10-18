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
| `table_intention.png` | live table | intention | 390×844 | 1.0 | A1 | `83ce9d3f49e76830d33d971b8dd0a00394554d5ec455634b0120b39593d735ba` |
| `table_spread_picker.png` | live table | spread picker | 390×844 | 1.0 | A2 | `b33bc03cb189eecc456fdde77d5a00e2380e21f1c0286acd36f12ebb9078fa00` |
| `table_draw_ready_three.png` | live table | draw ready | 390×844 | 1.0 | A3 | `22c04fa2b7c2a6f61990662183950e68023748687bff474b87e9bdfe93ca357b` |
| `table_draw_ready_five.png` | live table | draw ready | 390×844 | 1.0 | A4 | `6c59660b30608b06b98ecf07f20712d515d7bb063a4c7fba1282b0bd15937e72` |
| `ritual_three_one_settled.png` | ritual | 1 settled | 390×844 | 1.0 | B1 art | `f38d49f63595d90180c441addbe1601f4eba70575c5fe730017accbfec5c9dba` |
| `ritual_three_two_settled.png` | ritual | 2 settled | 390×844 | 1.0 | B2 art | `e6fb89a95e80169a4a9cf5c61b718b66a85513beb074f4a19bb06564691a57b8` |
| `ritual_five_partial.png` | ritual | 3 settled | 390×844 | 1.0 | B3 art | `8c54ee2e83f8434ac9f4ce0b8ce273774f7fd960bdf10d27972057d2a05a0b29` |
| `result_single_narrative.png` | result | Narrative | 390×844 | 1.0 | C1 | `1b67c58c9eceea7fb923402eee1410cd19b9cfe373f273445af34b20279c2a25` |
| `result_three_narrative.png` | result | Narrative | 390×844 | 1.0 | C2 | `8f03548bca02968f2f29908ef3921ed3c09a2f47b7df6283e79a14fa9c259399` |
| `result_five_narrative.png` | result | Narrative | 390×844 | 1.0 | C3 | `5f9eaa786ddcaacef48767839364ccb6cf215c502280e3db98f3cc12134a5c19` |
| `result_long_narrative.png` | result | long | 390×844 | 1.0 | C4 | `c597b791be8eccf27ed73e3f4ad959709ef95fd54a5af7f0fee6af6f6ec0bfb3` |
| `result_safety.png` | result | safety | 390×844 | 1.0 | C5 | `01208ec07c3cde118df4958809f0c7b325797ca2777188036b1dbe75aa83c09f` |
| `result_recovery.png` | result | recovery | 390×844 | 1.0 | C6 | `7cbc39ac0315e4203aa9f7f38228cf1207790916e80b6092616b49e73620be25` |
| `history_list_mixed.png` | history | list | 390×844 | 1.0 | D1 | `f2b8ef6442e6d28a24aad2885722865272e89e7301e14ab3d3bf21ac0c8617b3` |
| `history_detail_narrative.png` | history | Narrative | 390×844 | 1.0 | D2 | `36fb406a4a4bb52b41001a2e17485df03039a47e2e03874ccecd3cccbcb16c09` |
| `history_detail_crossroads.png` | history | Crossroads | 390×844 | 1.0 | D3 | `e26d4ea32a88b4f00e4820bb1c548a8a221ce01adced60c1442b95f6210e9a99` |
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
