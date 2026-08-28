# BRAND LAUNCH — Master Checkpoint

**Date:** 2026-08-25 (cinematic logo animation master)

## LOGO ANIMATION STATUS = BLOCKED — DEVICE VERIFICATION

Do **not** treat this as COMPLETE. TECNO KN8 cold-start QA is required and `adb` is unavailable on this machine.

### Launcher icon

| Item | State |
|------|-------|
| Identity | Preserved: crescent · oracle profile · central star · gold · violet · near-black |
| Luminous refine | Applied earlier (backup: `art_masters/brand/oracly_launcher_source_pre_luminous.png`) |
| Device drawer readability | **UNVERIFIED** — blocker |

### Splash cinema (code)

| Item | State |
|------|-------|
| Native Android window | `launch_background` = `#050208` + adaptive foreground |
| Timeline | Void → star ignition → **drawn** ring → emblem + light sweep → convergence → wordmark → final breath → Home |
| Duration | First **2600ms** · return **2000ms** · reduced **400ms** |
| Artificial delay | None beyond cinema; boot parallel; alive hold if boot slow |
| Controllers | Single `AnimationController`; disposed |

### Animation stages (full mode)

1. Void — near-black + violet hush + restrained dust  
2. First star — ignition (scale/glow), not mere fade  
3. Celestial ring — progressive `drawArc` trace (not a spinning full circle)  
4. Emblem — canonical `OraclyBrandMark` + edge light + light sweep (no morph)  
5. Energy convergence — inward sparks + brief star peak + ring response  
6. Wordmark — opacity + micro lift/scale + gold sweep (no typing)  
7. Final brand — calm hold + subtle breath  
8. Home — expanding star glow veil + midnight underlay fade (`820ms`)

Reduced motion: brand fade only; no celestial prelude.

### Transition

| Item | State |
|------|-------|
| Route | `OraclyPageTransitions.fade` · **820ms** handoff |
| Underlay | `ColoredBox(#050208)` wraps destination |
| Veil | Option A — central star bloom expands into chamber ambient |
| Device proof | **UNVERIFIED** |

### Tests / analyze

```text
flutter analyze lib/screens/splash test/screens/splash → No issues found
flutter test test/screens/splash/splash_cinema_flagship_test.dart → passed
```

### TECNO KN8

| Check | Result |
|-------|--------|
| Cold start | **BLOCKED** — no adb |
| Restart / bg→fg | **BLOCKED** |
| Phases visible / continuous | **BLOCKED** |
| No white/black flash / duplicate logo | **BLOCKED** |

### Exact remaining weaknesses / blockers

1. **Device:** Install on TECNO KN8 and run cold-start checklist — without this, status cannot be COMPLETE.  
2. **Visual judgment only on device:** star ignition weight, ring trace readability, convergence subtlety, wordmark–emblem connection.  
3. **Handoff feel:** code uses expand-glow + fade; may still read as soft dissolve rather than true universe→Home continuity until seen on hardware.  
4. Tagline still appears in final brand state (product copy) — confirm it does not dilute the emblem+wordmark hold.

Until device QA passes: **LOGO ANIMATION STATUS = BLOCKED**.

**STOP.**
