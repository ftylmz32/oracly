# FINAL RELEASE Master Checkpoint

**ORACLY = RELEASE BLOCKED — EXTERNAL**

**Date:** 2026-08-25  
**Gate:** RELEASE 25

## CURRENT STATUS

| Lens | Status |
|------|--------|
| Code / unit tests | DONE (`flutter test` **1863 passed · 14 skipped · 0 failed**) |
| Analyze errors | DONE (**0 errors**) |
| Product surfaces live | DONE |
| Feature masters “COMPLETE” | NOT COMPLETE (honesty/device gaps remain) |
| Play Billing | EXTERNAL BLOCKED — PLAY CONSOLE |
| Production AI host | EXTERNAL BLOCKED — PRODUCTION HOST |
| Release signing keystore | EXTERNAL / MANUAL (`android/key.properties` absent) |
| Production dart-defines file | EXTERNAL (`tool/dart_defines.production.json` absent; example only) |
| TECNO full matrix | MANUAL / partial |
| Store screenshots | MANUAL |
| Legal policy URLs | EXTERNAL (in-app Privacy Control Center exists; no hardcoded fake policy URLs) |

**Not a store-ready RELEASE CANDIDATE** while Play + production host + signing remain unverified.

---

## DONE this final-release pass

- Triaged prior **P0-TEST** (12 failures): aligned stale assertions to current Title Case / compact OR honesty; restored coffee OR `Kariyer`/`Para` domains; dialog dispose post-frame  
- `pubspec` description set to product identity (was “A new Flutter project”)  
- Full suite green: **+1863 ~14**  
- Analyze: **0 errors**  
- Confirmed: `applicationId`/`namespace` = `app.oracly`; version `1.0.0+1`; brand via `OraclyBrandMark` → `AppAssets.brandLogo`  
- Confirmed: cleartext only in debug/profile manifests; release main manifest has no cleartext flag  
- Confirmed: production dart-defines **example** uses HTTPS placeholder only  

---

## P0

| ID | Description | Owner | Closes when |
|----|-------------|-------|-------------|
| — | None open in code/tests after this pass | — | — |

*(Prior P0-TEST closed.)*

---

## P1

| ID | Description | Owner | Closes when |
|----|-------------|-------|-------------|
| P1-FEATURE-MASTERS | Home/OR/Tarot/Coffee/Palm/Astro/Yıldızname/SoulMate/Profile masters still NOT COMPLETE | code + device | Each master checkpoint = COMPLETE |
| P1-JOURNAL-DELETE | No in-journal delete UI | code | Delete wired without ghost entries |
| P1-HOME-SHELL | `/home` named route can stack second `OraclyAppShell` | code | Deep-link safe home entry |
| P1-DEVICE-MATRIX | TECNO full open→action→back matrix incomplete on current APK | manual + redeploy | HARDENING44-style matrix all PASS |

---

## P2

| ID | Description |
|----|-------------|
| P2-ANALYZE-INFOS | ~93 analyzer infos/warnings (style/deprecations); 0 errors |
| P2-FIREBASE-BOOT | Firebase init before `runApp` may delay first frame |
| P2-A11Y | Full accessibility matrix partial |

---

## EXTERNAL

| ID | Description | Closes when |
|----|-------------|-------------|
| EXT-PLAY | Play products for `app.oracly.premium.*` not loading on device | Console products + internal test account + verified purchase |
| EXT-PROXY | `ORACLY_AI_PROXY_URL` production host not configured (`REPLACE_WITH_PRODUCTION_HOST`) | Real HTTPS `/health` `/ready` `/v1/ai/complete` |
| EXT-SIGNING | No `android/key.properties` / upload keystore in workspace | Store signing configured locally (secrets never committed) |
| EXT-DEFINES | No `tool/dart_defines.production.json` (only `.example.json`) | Real production defines file (not committed secrets) |
| EXT-LEGAL-URL | External Privacy Policy / Terms web URLs not set | Final domains + in-app links |

---

## MANUAL

| ID | Description |
|----|-------------|
| MANUAL-SCREENSHOTS | Store screenshots with official emblem; no debug overlays — checklist below |
| MANUAL-PERMISSIONS | Camera/mic/photos/notifications on TECNO denied/recovery paths |
| MANUAL-UPGRADE | Fresh install → restart persistence → upgrade-like reopen |
| MANUAL-VOICE-E2E | OR voice with real mic + TTS on release APK |

### Screenshot checklist (capture when APK matches source)

1. Splash / emblem  
2. Home (single shell, no overlay)  
3. OR chamber (honest free/premium)  
4. Tarot reveal/reading  
5. Coffee result  
6. Astrology preview honesty  
7. SoulMate gate or result (no fake portrait)  
8. Premium unavailable or real store prices  
9. Profile / Journal  

Do not capture: debug banners, localhost, visual reference overlays, test accounts.

---

## BUILD

| Item | Status |
|------|--------|
| Version | `1.0.0+1` (pubspec → Android versionName/versionCode) |
| App ID | `app.oracly` |
| `flutter build appbundle --release --dart-define-from-file=…` | **NOT RUN** — production defines file absent |
| Artifact sanity | N/A this pass |

---

## TEST

| Check | Result |
|-------|--------|
| Targeted former failures | **49 passed · 2 skipped** |
| `flutter test` full | **1863 passed · 14 skipped · 0 failed** |
| `flutter analyze` | **0 errors** |
| backend `tsc` | Previously pass (unchanged this pass) |

Intentional skips: existing suite skips (E2E/local proxy) — 14 documented by framework; not weakened.

---

## DEVICE

| Check | Result |
|-------|--------|
| TECNO KN8 attached | Yes |
| Full release matrix | NOT COMPLETE this pass |
| Prior smoke | Home open; OR/Premium seek incomplete on installed APK |

---

## Gate verdict

Achievable code gates improved (tests green, analyze clean).

**Store readiness requires EXTERNAL hosts + Play + signing + device matrix.**

**ORACLY = RELEASE BLOCKED — EXTERNAL**

STOP.
